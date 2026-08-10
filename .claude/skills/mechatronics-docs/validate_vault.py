#!/usr/bin/env python3
"""Vault validator for mechatronics baseproject documentation vaults.

Mechanical enforcement layer for the SSOT vault conventions (see
DECISIONS.md). Prompt rules measurably decay over long sessions; this
validator makes the mechanically checkable subset of the vault rules
deterministic. Required sections are derived at runtime from the
project's own 00_*file_template* files, so the validator never drifts
from the templates a project actually ships.

Modes:
  validate_vault.py <vault_root>              full audit (file-local + vault-wide)
  validate_vault.py --file <path>             file-local checks only (root auto-detected)
  validate_vault.py --hook post               PostToolUse hook (JSON on stdin)
  validate_vault.py --hook stop               Stop hook (JSON on stdin)
  validate_vault.py --check-install           does the personal skill entry
                                              reach this copy of the skill,
                                              and which revision is it?

Exit codes: 0 = no errors (warnings allowed), 1 = at least one error,
2 = validator crash (hooks fail open on 2).

Severities: ERROR blocks (via the stop gate, ratcheted against the git
HEAD baseline of pre-existing files), WARN reports. status: draft does
NOT relax any check.
"""

import codecs
import json
import os
import re
import subprocess
import sys
import time
import unicodedata
from collections import Counter
from pathlib import Path

STATE_DIR = Path("/tmp/claude-mechdocs")
STATE_MAX_AGE_S = 7 * 24 * 3600
MAX_STOP_BLOCKS = 2

LENGTH_WARN = 150
LENGTH_ERROR = 400
STRUCTURE_WARN = 100
LINK_BUDGET = 20
LINK_BUDGET_HUB = 50
LINK_REPEAT_WARN = 3
STUB_MIN_LINES = 5
INB_MAX_AGE_DAYS = 7

DOMAIN_DIR_RE = re.compile(r"^\d\d_.+_\(([A-Z]{2,4})\)$")
# Domain-template file names, matched case-insensitively. The shared Latin
# root covers English (00_REQ_file_template.md) and German
# (00_ANF_Dateitemplate.md) alike, and no README carries it. A language
# that spells it differently adds a marker HERE and nowhere else: this one
# pattern gates vault-root detection, required-section derivation and
# template-file classification.
TEMPLATE_MARKERS = ("template",)
TEMPLATE_NAME_RE = re.compile(
    r"^00_.*(?:" + "|".join(re.escape(m) for m in TEMPLATE_MARKERS) + r")", re.I)
# One internal link, split into embed marker, target, anchor and alias.
# Every quantifier below is load-bearing, and NO vault on this machine can
# catch its removal - the shapes they exist for occur zero times in nine
# vaults (issue #23), so the parser assertions in tests/run.sh are the only
# guard there is:
#   '*' on the target, not '+': an empty target is a link into the file
#     itself, '[[#Heading]]' and '[[#^blockid]]', both documented Obsidian
#     syntax (obsidian.md/help/links).
#   LAZY target and anchor: inside a table Obsidian requires the alias pipe
#     to be escaped, '[[Note\|alias]]' (obsidian.md/help/advanced-syntax).
#     A greedy group swallows that backslash and yields the target 'Note\',
#     which resolves against nothing and was reported as link-unresolved on
#     a link that works. Lazy, the backslash stays with the alias where it
#     belongs. The two only ever differ there: the target class excludes
#     '|' and '#', so it can give back nothing else.
#   '\\?' before the alias pipe: the escape itself. The same applies to an
#     embed size, '![[Engelbart.jpg\|200]]'.
# A legal target can carry no escape at all - Obsidian forbids [ ] # ^ | in
# file names outright and \ on Linux and macOS - so the escape is handled
# where it occurs, at the alias boundary, and nowhere else.
WIKILINK_RE = re.compile(r"(!?)\[\[([^\]|#\n]*?)(#[^\]|\n]*?)?(\\?\|[^\]\n]*)?\]\]")
# A heading of any level, and a block identifier at the end of a line.
# Obsidian links headings H1-H6, not just the H2s the section checks care
# about, and states the block-id vocabulary as "Latin letters, numbers, and
# dashes".
HEADING_RE = re.compile(r"^#{1,6}\s+(.*)$")
BLOCK_ID_RE = re.compile(r"(?:^|\s)\^([A-Za-z0-9-]+)\s*$")
# One item of a YAML block sequence: '-' followed by whitespace or by
# nothing at all. Deliberately not '-' followed by anything, so '-- a'
# stays malformed instead of quietly becoming the item 'a'.
SEQ_ITEM_RE = re.compile(r"^-(?:\s+(.*))?$")
# A mapping inside a sequence item ('- key: value'). YAML reads that as a
# list of mappings; this reader models no nested structure, and folding it
# into the string 'key: value' would be the silent misreading this project
# refuses everywhere else. '- foo:bar' carries no space after the colon,
# is a plain scalar in YAML too, and is not matched here.
SEQ_NESTED_RE = re.compile(r"^[A-Za-z][\w-]*:(\s|$)")
REQ_ID_RE = re.compile(r"REQ-[A-Z]{2,4}-\d{3}")
# The number of the requirement row a table's second cell carries. One
# constant for the three places that ask the question - check_req_table,
# Vault.req_index and the global duplicate scan - because the unrecognised-
# table WARN states that the index reads a row no check reads, and that
# claim is only true while both sides ask it the same way. The exception
# is a vault whose requirements role is aliased (ANF): the index and the
# duplicate scan follow the role map since issue #66, while check_req_table
# stays on the literal REQ folder - extending four blocking row codes to
# translated vaults is a rollout, not a fix - so there the index reads
# rows no row check reads, and the WARN stays dark on purpose.
ROW_NNN_RE = re.compile(r"\d{3}")
# Columns a requirement table carries. A table may be wider - a project that
# appends a column keeps the five positional roles the row checks read - and
# a narrower one is not a requirement table. Python rather than the schema,
# for ID_RE's reason: it decides what is checked at all, and the schema's own
# domains.REQ.rows entry states that the row grammar stays here.
REQ_ROW_COLUMNS = 5
DOM_IN_NAME_RE = re.compile(r"\(([A-Z]{2,4})\)")
# Object identifiers (vault_schema.json, "identifier"): DOMAIN-SCOPE-NNN in
# frontmatter. Identity lives in the file, not in its name, so a rename does
# not change what an object is.
ID_RE = re.compile(r"^(?:REQ|DEC|ARC|CMP|IFC|IMP|TAE|OAU|REF)-[A-Z]{2,4}-\d{3}$")
# The same shape without the English domain vocabulary, for a field that
# names OTHER objects rather than the file itself. A vault spelling its
# domains KMP/SST would have every value rejected by ID_RE, and the
# exporter's own key check (object_key) accepts exactly this shape.
OBJECT_ID_RE = re.compile(r"^[A-Z]{2,4}-[A-Z]{2,4}-\d{3}$")
REQ_FILE_ID_RE = re.compile(r"^REQ-([A-Z]{2,4})-\d{3}$")
# Excluded from the scheme: SKILL.md classifies both as not engineering
# documentation (DECISIONS.md, amendment 2026-07-28b).
ID_EXCLUDED_DOMAINS = ("ADM", "INB")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
PATH_TOKEN_RE = re.compile(r"(?<![\w(])((?:[\w.-]+/)+[\w.-]+\.\w{1,12})\b")
PIN_RE = re.compile(r"\b(?:GPIO\d+|P[A-K]\d{1,2}|0x[0-9A-Fa-f]{2,})\b")
# Fenced blocks, CommonMark 0.31.2: at least three consecutive backticks or
# tildes, indented by up to three spaces, closed only by the same character,
# at least as long, and carrying no info string of its own. Recognising only
# backticks made '~~~' the cheaper way out of every rule that keys on fences
# (amendment 2026-07-28, two WRONG findings). Tracking neither character nor
# length made the next two: a four-backtick block - the ordinary way to quote
# a fenced example - and a '```' inside a '~~~' block both moved the boundary,
# which is also what kept the validator disagreeing with the exporter about
# how many requirement rows a vault has (amendment 2026-07-31b, residual 1).
# This is export_traceability.fenced_mask's rule verbatim: one definition for
# both tools, asserted against it in tests/run.sh.
FENCE_RE = re.compile(r"^( {0,3})(`{3,}|~{3,})(.*)$")
# The machine a block is true on, declared in the info string at ANY token
# position. CommonMark: the first word is typically the language, but "this
# spec does not mandate any particular treatment of the info string". Position
# is not fixed because 23 of 127 blocks in one production vault and 14 of 17
# in the other carry no language at all - "language first, host second" would
# have had no spelling for them.
FENCE_HOST_RE = re.compile(r"(?:^|\s)host=(\S*)")
# Content lines above which a block is too long to be a single observation.
# Measured, not chosen: the smallest genuine script excerpt in the two German
# production vaults has 16 content lines, so 15 is the largest value that
# still catches every measured copy (DECISIONS.md, amendment 2026-07-28f).
FENCE_RECORD_MAX = 15
FENCE_BANNED_DOMAINS = ("IMP", "ARC")
FENCE_EXEMPT_DOMAINS = ("IMP",)
# Project-artifact path shape (NN_folder/... per the vault conventions);
# gates the dead-path scan in BOTH zones so ratio notation (3.3V/1.8V),
# bare domains (heise.de/...) and foreign paths (/etc/..., ~/.config/...)
# are never reported as stale pointers - this project cannot own them.
ARTIFACT_SEG_RE = re.compile(r"^\d{2}_")
# Explicit open-item markers suppress the body-wide dead-path WARN only -
# never the References/Sources ERROR (silent-bypass prevention).
PENDING_RE = re.compile(r"\b(pending|planned|tbd|not\s+yet)\b", re.I)

# Findings about a section the author DID write, under a title the template
# does not carry. Counted separately in the run summary, because formatting
# drift across a domain must not read as a batch of unwritten sections.
NEAR_MISS_CODES = ("section-near-miss", "section-mismatch")
# Characters that render as nothing and would otherwise make two identical
# headings compare unequal.
ZERO_WIDTH = dict.fromkeys(map(ord, "​‌‍⁠﻿"), None)
# What may follow a required heading inside a longer one for the two to be
# the same subject at a different scope: anything that is not a word
# character. 'Ablauf (monatlich)' qualifies, 'Kontexte' does not.
BOUNDARY_RE = re.compile(r"\W")

# Byte-order marks that are a SIGNATURE of another encoding rather than a
# character, LONGEST FIRST. FF FE 00 00 begins with the UTF-16LE mark, so a
# table tested in any other order reports every UTF-32LE file as UTF-16LE.
# The sequences and their byte orders are Microsoft's table
# (learn.microsoft.com/globalization/encoding/byte-order-mark), which states
# the Unicode standard's: FE FF and 00 00 FE FF are big-endian, FF FE and
# FF FE 00 00 little-endian. The UTF-8 mark is deliberately NOT in here - it
# is stripped and the file read on, which is what issue #21 settled.
BOM_SIGNATURES = (
    ("UTF-32LE", codecs.BOM_UTF32_LE),
    ("UTF-32BE", codecs.BOM_UTF32_BE),
    ("UTF-16LE", codecs.BOM_UTF16_LE),
    ("UTF-16BE", codecs.BOM_UTF16_BE),
)

_UNITS = (
    "mV|kV|V|mA|µA|uA|kΩ|MΩ|Ω|kOhm|MOhm|Ohm|mW|kW|W|kHz|MHz|GHz|Hz|Nm|mN|"
    "kg|mg|µm|um|nm|mm|cm|ms|µs|us|ns|°C|dB|bit|Byte|kB|MB|GB|mbar|bar|kPa|MPa|Pa|"
    "A|N|g|m|s|K"
)
NUM_UNIT_RE = re.compile(r"(?<![\w.,:-])\d+(?:[.,]\d+)?\s?(?:" + _UNITS + r")(?![\w°])")
# Tokens stripped from a line before leak matching (legitimate numerics).
STRIP_RES = [
    re.compile(r"`[^`]*`"),
    re.compile(r"!?\[\[[^\]]*\]\]"),
    re.compile(r"\d{4}-\d{2}-\d{2}"),
    re.compile(r"REQ-[A-Z]{2,4}-\d{3}"),
    re.compile(r"\brev-[\w.]+"),
    re.compile(r"\bv\d[\d.]*\b"),
    re.compile(r"\bed-\d+\b"),
]

# --------------------------------------------------------------------------
# Schema (vault_schema.json)
# --------------------------------------------------------------------------
# The field vocabulary, the permitted values and the required keys are DATA,
# read from the packaged schema beside this file. One packaged schema, no
# per-project override: the ERRORs that reach the stop gate's blocking set
# come from the checks below, so a project-local override would be an
# uncommitted off-switch for the gate (DECISIONS.md, amendment 2026-07-28d).
SCHEMA_PATH = Path(__file__).resolve().with_name("vault_schema.json")
SCHEMA_MAX_BYTES = 1 << 20

# Used ONLY when the packaged schema cannot be read. Deliberately minimal -
# it is not a second copy of the schema, it is the answer to "check nothing
# or check the essentials", and validating nothing silently is the failure
# mode this project has already been bitten by.
FALLBACK_SCHEMA = {
    "domain_defaults": {"fields": {
        "domain": {"type": "folder-abbreviation", "required": True,
                   "code": "frontmatter-domain", "enforced": "schema-driven"},
        "status": {"type": "enum", "required": True, "code": "frontmatter-status",
                   "values": ["draft", "active", "superseded", "deprecated"],
                   "enforced": "schema-driven"},
        "created": {"type": "date", "required": True, "code": "frontmatter-date",
                    "enforced": "schema-driven"},
        "last-verified": {"type": "date", "required": True, "code": "frontmatter-date",
                          "enforced": "schema-driven"},
        "id": {"type": "identifier", "required": False, "enforced": "declared-only"},
        "verifies": {"type": "list", "item": "req-row-identifier", "required": False,
                     "code": "verifies-format", "empty_code": "verifies-empty",
                     "enforced": "declared-only"},
        "test-object": {"type": "list", "item": "object-identifier",
                        "required": False, "code": "test-object-format",
                        "enforced": "schema-driven"},
    }},
    "domains": {
        "DEC": {"fields": {"status": {"required": False}},
                "body_fields": {"Status": {
                    "type": "enum", "code": "dec-status", "enforced": "schema-driven",
                    "values": ["Draft", "Accepted", "Superseded", "Deprecated"]}}},
        "TAE": {"fields": {"verifies": {"required": True, "hint": "verifies: [REQ-...]",
                                        "enforced": "schema-driven"}}},
        "REQ": {"rows": {"class_values": ["M", "S", "O"]}},
    },
    # In the essentials since issue #66: the role map feeds the coverage
    # checks, and without it every translated vault's requirement index
    # would switch off silently behind the single schema-unreadable WARN -
    # the exact path this fallback exists to keep honest. Asserted against
    # the packaged schema in tests/run.sh like the field profiles above.
    "domain_aliases": {
        "map": {"ANF": "REQ", "ENT": "DEC", "KMP": "CMP",
                "SST": "IFC", "TUE": "TAE", "BUN": "OAU"},
        "identity": ["REQ", "DEC", "ARC", "CMP", "IFC", "IMP", "TAE", "OAU", "REF"],
    },
    "editor_fields": {
        "values": ["tags", "aliases", "cssclasses", "publish", "permalink",
                   "description", "image", "cover"],
        "prefixes": ["excalidraw-"],
    },
}

_SCHEMA_CACHE = {}


def _dict(node, key):
    """node[key] if it is a dict, else {} - never raises, never propagates junk.

    Every schema read goes through this. A schema that parses but declares
    nonsense (`"body_fields": 5`) must not reach a nested subscript: that
    raises TypeError, which exits 2, which both hooks swallow.
    """
    v = node.get(key) if isinstance(node, dict) else None
    return v if isinstance(v, dict) else {}


def _strlist(node, key):
    """node[key] as a list of strings, else [] - never raises."""
    v = node.get(key) if isinstance(node, dict) else None
    return [x for x in v if isinstance(x, str)] if isinstance(v, list) else []


def load_schema(path=SCHEMA_PATH):
    """-> (schema_dict, error_message|None). Cached per path. Never raises."""
    key = str(path)
    if key not in _SCHEMA_CACHE:
        _SCHEMA_CACHE[key] = _read_schema(path)
    return _SCHEMA_CACHE[key]


def _read_schema(path):
    try:
        raw = path.read_bytes()
    except OSError as e:
        return FALLBACK_SCHEMA, f"cannot read {path.name} ({type(e).__name__})"
    if len(raw) > SCHEMA_MAX_BYTES:
        return FALLBACK_SCHEMA, f"{path.name} exceeds {SCHEMA_MAX_BYTES} bytes"
    try:
        # RecursionError, not ValueError, is what deeply nested JSON raises.
        # utf-8-sig for the same reason read_text uses it: json.loads
        # rejects a leading BOM outright, and the schema would fall back
        # to the built-in field set behind a single WARN - declared
        # values and editor fields silently out of force (issue #21).
        data = json.loads(raw.decode("utf-8-sig", "replace"))
    except (ValueError, RecursionError):
        return FALLBACK_SCHEMA, f"{path.name} is not valid JSON"
    if not isinstance(data, dict):
        return FALLBACK_SCHEMA, f"{path.name} is not a JSON object"
    return data, None


class Finding:
    __slots__ = ("sev", "code", "path", "line", "msg")

    def __init__(self, sev, code, path, line, msg):
        self.sev, self.code, self.path, self.line, self.msg = sev, code, path, line, msg

    def render(self, rel_to=None):
        p = self.path
        if rel_to:
            try:
                p = str(Path(self.path).relative_to(rel_to))
            except ValueError:
                pass
        loc = f"{p}:{self.line}" if self.line else p
        return f"{self.sev} {loc} [{self.code}] {self.msg}"


# --------------------------------------------------------------------------
# Vault discovery and indexing
# --------------------------------------------------------------------------

def template_files(domain_dir: Path):
    """Template files of one domain dir, in any of the supported languages."""
    try:
        return sorted(p for p in domain_dir.iterdir()
                      if p.is_file() and p.suffix == ".md"
                      and TEMPLATE_NAME_RE.match(p.name))
    except OSError:
        return []


def dir_sort_key(p: Path):
    """A total order over folder names that two machines agree on.

    Sorting by the raw name is not enough: macOS stores 'Prüfung'
    decomposed and Linux composed (Apple's APFS FAQ; HFS+ normalised to
    NFD outright), so the same folder can carry different bytes on two
    hosts and sort into a different place. The raw name stays as the
    tie-break, because two names CAN normalise equal while differing on
    disk and the order must still be total.
    """
    return (unicodedata.normalize("NFC", p.name), p.name)


def has_domain_files(ddir: Path, abbr: str) -> bool:
    """Does this folder carry a file of its own domain?

    build_graph's ingestion predicate - a name starting with the folder's
    abbreviation, which no '00_' template does - asked as a yes/no. A
    count would make the answer flip on any ordinary edit; whether a
    folder holds the domain at all flips twice over a whole translation.
    """
    try:
        return any(f.name.startswith(f"{abbr}_") for f in ddir.rglob("*.md"))
    except OSError:
        return False


def pick_domain_dir(abbr, dirs):
    """The one folder of an abbreviation every check of this vault reads.

    German and English spell ARC, IMP and REF identically, so a vault
    mid-translation carries two folders under one abbreviation and
    something has to choose. Left to iterdir the choice is the file
    system's, and two machines holding the same content index different
    folders (issue #42).

    The rule is the first in sorted order AMONG THE FOLDERS CARRYING
    FILES OF THE DOMAIN, and the qualifier is what the measurement
    bought: a capital letter sorts first, so plain sorted-first hands
    'Architektur' the domain over 'architecture' - including when the
    German folder is a leftover holding nothing but templates. Measured
    on the shipped template vault with such a folder beside the real one,
    the export drops from 3 requirements proven and 14 relations to 0 and
    6. Choosing the empty folder deterministically is worse than choosing
    arbitrarily (DECISIONS.md, amendment 2026-08-04g).

    Every folder empty falls back to sorted-first: there is nothing to
    prefer, and the answer still has to be the same on both machines.
    """
    if len(dirs) == 1:
        return dirs[0]
    return next((d for d in dirs if has_domain_files(d, abbr)), dirs[0])


def resolve_role_map(vault, schema):
    """-> ({canonical role token: folder abbreviation}, dropped abbreviations).

    The ONE derivation of which folder holds which domain role, shared by
    both tools (issue #66): export_traceability.resolve_roles renders its
    findings from it, and Vault.roles() feeds the validator's coverage
    path - req_index, check_tae_verifies and the global duplicate scan.
    Two resolvers would disagree exactly where it costs the most, a vault
    mid-translation.

    An abbreviation is its own role when the schema's identity list names
    it, and is translated through domain_aliases.map otherwise (ANF ->
    REQ). The first in sorted order wins a contested role - the exporter's
    rule, unchanged. 'dropped' lists every non-excluded abbreviation that
    took no role: (abbr, None) for a token the schema does not know,
    (abbr, role) for a role another folder already holds. The exporter
    turns those into export-unknown-domain and export-duplicate-role; the
    validator reports nothing for them and simply follows the same choice
    the graph makes.

    Never raises - this feeds both hook paths, where an exception exits 2
    and fails the gates open.
    """
    aliases = _dict(schema, "domain_aliases")
    amap = _dict(aliases, "map")
    identity = _strlist(aliases, "identity") or [
        "REQ", "DEC", "ARC", "CMP", "IFC", "IMP", "TAE", "OAU", "REF"]
    roles, dropped = {}, []
    for abbr in sorted(vault.domain_dirs):
        if abbr in ID_EXCLUDED_DOMAINS:
            continue
        role = abbr if abbr in identity else amap.get(abbr)
        if role is None:
            dropped.append((abbr, None))
        elif role in roles:
            dropped.append((abbr, role))
        else:
            roles[role] = abbr
    return roles, dropped


def is_vault_root(d: Path) -> bool:
    """A vault root has >=3 domain dirs AND template files below them.

    The template-file requirement distinguishes 01_projectvault from
    02_documents, which mirrors the same (ABBR) folder names.
    """
    try:
        subs = [s for s in d.iterdir() if s.is_dir() and DOMAIN_DIR_RE.match(s.name)]
    except OSError:
        return False
    if len(subs) < 3:
        return False
    return any(template_files(s) for s in subs)


def find_vault_root(start: Path):
    """Walk upward from a file/dir to the nearest enclosing vault root."""
    cur = start if start.is_dir() else start.parent
    for d in [cur, *cur.parents]:
        if is_vault_root(d):
            return d
    return None


class Vault:
    def __init__(self, root: Path):
        self.root = root.resolve()
        self.doc_root = self.root.parent
        self.project_root = self.doc_root.parent
        # ABBR -> every folder of that abbreviation, in one sorted order on
        # every machine. Keeping them all is what lets the choice below be a
        # rule instead of readdir's, and what lets check_domain_folders name
        # the pair; the exporter reads this index rather than the root a
        # second time (DECISIONS.md, amendment 2026-08-04g).
        self.domain_dirs = {}
        seen = {}
        for s in sorted(self.root.iterdir(), key=dir_sort_key):
            m = DOMAIN_DIR_RE.match(s.name) if s.is_dir() else None
            if not m:
                continue
            abbr = m.group(1)
            # is_dir() follows a symlink, so a compatibility link left behind
            # by a rename - '03_Architektur_(ARC)' -> '03_architecture_(ARC)' -
            # would otherwise be indexed as a second folder and reported as a
            # pair the author cannot resolve: there is only one directory, and
            # rglob does not descend into the link either. Deduped per
            # abbreviation, because two abbreviations sharing one directory
            # are two domain names for one folder, which is the exporter's
            # export-duplicate-role and stays visible.
            try:
                real = s.resolve()
            except OSError:
                real = s
            if real in seen.setdefault(abbr, set()):
                continue
            seen[abbr].add(real)
            self.domain_dirs.setdefault(abbr, []).append(s)
        # ABBR -> the one folder every check reads
        self.domains = {abbr: pick_domain_dir(abbr, dirs)
                        for abbr, dirs in self.domain_dirs.items()}
        self._templates = None
        self._md_names = None
        self._all_names = None
        self._req_index = None
        self._roles = None
        self._git_root = None
        self._index_root = None
        self._schema = None
        self._schema_error = None
        self._schema_reported = False
        self._fields = {}

    def schema(self):
        if self._schema is None:
            self._schema, self._schema_error = load_schema()
        return self._schema

    def schema_error(self):
        self.schema()
        return self._schema_error

    def fields_for(self, abbr):
        """Field descriptors of a domain: the defaults, then the domain's deltas.

        The merge is attribute-wise, so a domain entry that only says
        {"required": false} keeps the type, the values and the finding code
        declared once in domain_defaults. A domain this schema does not name -
        every domain of a vault written in another language - gets the defaults
        alone, which is exactly the contract those vaults are held to today.
        """
        if abbr not in self._fields:
            s = self.schema()
            merged = {}
            for name, desc in _dict(_dict(s, "domain_defaults"), "fields").items():
                if isinstance(desc, dict):
                    merged[name] = dict(desc)
            for name, desc in _dict(_dict(_dict(s, "domains"), abbr), "fields").items():
                if isinstance(desc, dict):
                    merged[name] = {**merged.get(name, {}), **desc}
            self._fields[abbr] = merged
        return self._fields[abbr]

    def editor_fields(self):
        """(names, prefixes) of keys the editor and its plugins own."""
        ef = _dict(self.schema(), "editor_fields")
        return set(_strlist(ef, "values")), tuple(_strlist(ef, "prefixes"))

    def roles(self):
        """{canonical role token: folder abbreviation} of this vault.

        The exporter's role resolution, cached per vault: one shared
        derivation (resolve_role_map), so the folder the coverage checks
        read is the folder the graph is built from - never two answers
        (issue #66).
        """
        if self._roles is None:
            self._roles = resolve_role_map(self, self.schema())[0]
        return self._roles

    def git_root(self):
        """Repo root enclosing the vault, or None outside version control.

        Not always project_root: derived projects sometimes version the
        vault alone (both German vaults do), and then project_root is not
        a repo at all - which would silently empty the HEAD baseline and
        make every pre-existing ERROR count as introduced this session.
        """
        if self._git_root is None:
            try:
                r = subprocess.run(
                    ["git", "-C", str(self.root), "rev-parse", "--show-toplevel"],
                    capture_output=True, text=True, timeout=10)
                self._git_root = (Path(r.stdout.strip())
                                  if r.returncode == 0 and r.stdout.strip() else False)
            except (OSError, subprocess.TimeoutExpired):
                self._git_root = False
        return self._git_root or None

    def index_root(self):
        """The directory the name index is built over.

        doc_root while the repository contains it. That is the canonical
        layout, where the index deliberately reaches past the vault into
        02_documents: two files of one name, one of them not linkable, is
        the collision duplicate-basename exists for.

        Once the repository does NOT contain doc_root, the vault root IS
        the repository root - both are ancestors of it, so they lie on one
        chain and no third case exists. Walking doc_root then leaves the
        working tree: measured 53 of 378 indexed files outside the
        repository on a vault of that shape, and a different index for the
        same commit in an isolated checkout.

        The fallback is self.root rather than the path git printed. In the
        honest case those are the same directory; where GIT_DIR or
        GIT_WORK_TREE is set in the environment, or git spells the path
        differently from the resolved one this class holds, it lands on the
        vault instead of on a foreign tree. Subprocess output decides the
        branch here, it never becomes the search root. Without a repository
        the boundary stays doc_root: there is nothing to clamp to, and
        inferring one from directory names would undo the language
        independence of amendment 2026-07-28 (01_methodvault, DEC-MTH-044).
        """
        if self._index_root is None:
            repo = self.git_root()
            repo = repo.resolve() if repo else None
            inside = repo is not None and (repo == self.doc_root
                                           or repo in self.doc_root.parents)
            self._index_root = self.doc_root if repo is None or inside else self.root
        return self._index_root

    def index_root_label(self):
        """The boundary as the two findings name it, relative to project_root.

        '00_documentation' in the canonical layout - the same words the
        shipped documentation quotes - and the vault's own path where the
        vault is the repository and no such folder exists.
        """
        try:
            return str(self.index_root().relative_to(self.project_root))
        except ValueError:
            return str(self.index_root())

    def templates_for(self, abbr):
        """H2 heading sets of each template of a domain (empty sets excluded).

        Every folder of the abbreviation contributes, not just the one
        pick_domain_dir chose. A vault mid-translation has its German
        templates in one folder and its English files below the other,
        and the German folder wins the index whenever both carry content
        - a capital letter sorts first. Reading only its templates makes
        template-sections fire on files whose sections are correct:
        measured as 0 errors becoming 1 on the shipped template vault,
        which would fail the CI audit and block the stop gate on a
        correct file (DECISIONS.md, amendment 2026-08-04g).

        The union cannot make the check stricter. check_sections already
        scores a file against every template of its domain and keeps the
        best, so one more candidate can only be met or ignored. The
        folder name is carried into the template's label where an
        abbreviation has more than one folder, because 'closest template:
        00_ARC_file_template.md' names two files there.
        """
        if self._templates is None:
            self._templates = {}
            for dom, ddirs in self.domain_dirs.items():
                sets = []
                for ddir in ddirs:
                    for tf in template_files(ddir):
                        try:
                            h2s = extract_h2(read_text(tf))
                        except OSError:
                            continue
                        if h2s:
                            label = (tf.name if len(ddirs) == 1
                                     else f"{ddir.name}/{tf.name}")
                            sets.append((label, h2s))
                self._templates[dom] = sets
        return self._templates.get(abbr, [])

    def _build_name_index(self):
        # sorted, for validate_vault_wide's reason one level down: the
        # duplicate-basename finding names paths[0], and rglob's order is
        # the file system's. Two machines - or one machine and a vault
        # whose folders were created in the other order - otherwise report
        # the same collision on different files, which is the very
        # non-determinism issue #42 is about, one index further out.
        self._md_names, self._all_names = {}, {}
        for p in sorted(self.index_root().rglob("*")):
            if any(part in (".obsidian", ".git") for part in p.parts):
                continue
            if p.is_file():
                self._all_names.setdefault(p.name, []).append(p)
                if p.suffix == ".md":
                    self._md_names.setdefault(p.stem, []).append(p)

    def md_names(self):
        if self._md_names is None:
            self._build_name_index()
        return self._md_names

    def all_names(self):
        if self._all_names is None:
            self._build_name_index()
        return self._all_names

    def req_index(self):
        """All requirement row IDs of the requirements domain: id -> (path, line).

        The domain is resolved through the role map, and the keys carry
        THIS vault's requirements abbreviation - ANF-BAK-001 in a German
        vault - per domain_aliases.requirement_id_prefix. That is the
        exporter's spelling, so 'verifies' entries and the graph's
        requirements meet this index under one vocabulary (issue #66).
        """
        if self._req_index is None:
            self._req_index = {}
            abbr = self.roles().get("REQ")
            reqdir = self.domains.get(abbr) if abbr else None
            if reqdir:
                for f in sorted(reqdir.rglob("*.md")):
                    if f.name.startswith("00_"):
                        continue
                    try:
                        lines = read_lines(f)
                    except OSError:
                        continue
                    dom = req_scope(f, lines, abbr)
                    if not dom:
                        continue
                    for i, row in req_rows(lines):
                        if len(row) >= 2 and ROW_NNN_RE.fullmatch(row[1]):
                            self._req_index.setdefault(f"{abbr}-{dom}-{row[1]}", (f, i))
        return self._req_index

    def classify(self, path: Path):
        """-> ('outside'|'root'|'infra'|'domain'|'inbox'|'skip', abbr|None)"""
        p = path.resolve()
        try:
            rel = p.relative_to(self.root)
        except ValueError:
            return ("outside", None)
        if rel.parts and rel.parts[0] in (".obsidian", ".git"):
            return ("skip", None)
        if len(rel.parts) == 1:
            return ("root", None)  # root files: link checks only
        m = DOMAIN_DIR_RE.match(rel.parts[0])
        if not m:
            return ("skip", None)
        abbr = m.group(1)
        if p.name.startswith("00_"):
            return ("infra", abbr)
        if abbr == "INB":
            return ("inbox", abbr)
        return ("domain", abbr)


# --------------------------------------------------------------------------
# Parsing helpers
# --------------------------------------------------------------------------

def _universal_newlines(s: str):
    """'\\r\\n' and a lone '\\r' become '\\n', the way read_text did it.

    Path.read_text opens in text mode, where the translation happens
    inside the decoder; decoding bytes does not translate, and 16 of the
    1091 files in the nine vaults on this machine carry CRLF. Every
    consumer splits with splitlines(), which hides the difference - but
    read_text is this module's public reader and its output must not
    change under a fix that is about encodings.

    The membership test is not premature: two rewrites of every string
    the validator reads cost 20 percent of a full audit's runtime, and
    1075 of the 1091 files skip them.
    """
    if "\r" not in s:
        return s
    return s.replace("\r\n", "\n").replace("\r", "\n")


def decode_source(raw):
    """-> (text, problem|None). The one place bytes become vault content.

    'problem' names an encoding the vault is not written in, and it is a
    fact rather than a guess: a byte-order mark IS that encoding's own
    signature, and none of the four can open a valid UTF-8 file, because
    FF and FE are not legal UTF-8 bytes anywhere. Without a mark the only
    honest statement left is that the bytes are not UTF-8 - a Latin-1
    file and a corrupted UTF-8 file cannot be told apart, and this reader
    does not pretend otherwise; it names the byte instead of the
    encoding.

    The text comes back decoded exactly as before, utf-8-sig with
    replacement characters, because the encoding is named and not
    honoured. Decoding a UTF-16 file correctly here would make the
    validator understand a file Obsidian does not open, and would let the
    exporter carry its rows into the traceability graph. The vault is
    UTF-8; a file that is not gets a finding, not a second reader.

    Never raises. This runs in both hook paths, where an exception exits
    2 and fails the gate open, so a str - which has one producer today
    and none tomorrow - is handed back unchanged rather than compared
    against bytes.
    """
    if isinstance(raw, str):
        return raw, None
    for name, bom in BOM_SIGNATURES:
        if raw.startswith(bom):
            return (_universal_newlines(raw.decode("utf-8", "replace")),
                    f"the file is {name}, not UTF-8")
    if raw.startswith(codecs.BOM_UTF8):
        raw = raw[len(codecs.BOM_UTF8):]     # what utf-8-sig does, done once
    try:
        return _universal_newlines(raw.decode("utf-8")), None
    except UnicodeDecodeError as e:
        return (_universal_newlines(raw.decode("utf-8", "replace")),
                f"the file is not valid UTF-8 ({e.reason} at byte {e.start})")


def read_source(path: Path):
    """(text, problem) of a file on disk. Raises OSError, as read_text did."""
    return decode_source(path.read_bytes())


def read_text(path: Path):
    """Text of a file, BOM-safe. Every read of vault content goes here.

    utf-8-sig strips a leading byte-order mark and is byte-identical to
    utf-8 without one, so the option costs nothing where no mark exists.
    With utf-8 the first line of a BOM-carrying file compares unequal to
    '---', parse_frontmatter returns (None, 0, None) - the malformed slot
    empty, so nothing is reported anywhere - and the file is handed
    frontmatter-missing, an ERROR naming the wrong cause, while
    frontmatter_id drops it out of the identifier checks entirely
    (issue #21). A BOM is never typed on purpose: it arrives from an
    editor, a redirect or an export tool.

    The exporter has read this way since amendment 2026-07-31b. One rule
    for both tools, asserted per fixture file in tests/run.sh.

    A caller that has to know WHY a file reads like nonsense calls
    read_source instead; this one keeps the text-only contract every
    consumer of it was written against (issue #31).
    """
    return read_source(path)[0]


def read_lines(path: Path):
    return read_text(path).splitlines()


def extract_h2(text: str):
    return {l[3:].strip() for l in text.splitlines() if l.startswith("## ")}


def h2_index(lines):
    """H2 headings of a file -> the first line each sits on, in document order.

    The set extract_h2 returns cannot say WHERE a heading is, and a finding
    about a heading the author actually wrote is only usable if it names the
    line. A heading written twice keeps its first occurrence: that is the one
    the reader reaches first.
    """
    idx = {}
    for i, line in enumerate(lines, 1):
        if line.startswith("## "):
            idx.setdefault(line[3:].strip(), i)
    return idx


def strict_key(s: str):
    """Heading identity, ignoring what the author cannot see.

    NFC/NFD spelling of an umlaut differs between macOS and Linux, a
    zero-width character renders as nothing, and doubled or exotic
    whitespace collapses in every Markdown renderer. Two headings differing
    only there ARE the same heading, and reporting that difference would be
    a finding nobody can act on.
    """
    s = unicodedata.normalize("NFC", s).translate(ZERO_WIDTH)
    return unicodedata.normalize("NFC", " ".join(s.split()))


def fold_key(s: str):
    """Heading identity for caseless matching (Unicode 15.0 §3.13, D144).

    str.casefold implements toCasefold, and normalising AFTER folding is
    what D145 asks for: casefold('İ') yields 'i' plus a combining dot.
    Folding is not lowercasing - it also maps 'ß' to 'ss', so a near-miss
    message quotes both spellings verbatim rather than claiming that only
    the case differs.
    """
    return unicodedata.normalize("NFC", strict_key(s).casefold())


def prefix_related(a: str, b: str):
    """True when one folded heading extends the other at a word boundary.

    'Ablauf' vs 'Ablauf (monatlich)' and 'Zuordnung' vs 'Zuordnung und
    Verifikation' - the same subject at a different scope, in either
    direction. 'Kontext' vs 'Kontexte' is a different word and must not
    qualify, which is what the boundary test buys. Equal length is never
    related: that case is equality, and it is handled before this is asked.
    """
    short, long = (a, b) if len(a) < len(b) else (b, a)
    return (len(short) < len(long) and long.startswith(short)
            and bool(BOUNDARY_RE.match(long[len(short):])))


def fence_blocks(lines):
    """Fenced blocks of a file: (open_line, info, body_lines, close_line|None).

    One definition of a fence for every check that tracks fence state, so
    check_leaks, check_links, check_paths and req_rows can never disagree
    about where a block starts - and, because this is the rule the exporter
    applies, neither can the two tools.

    A block still open at EOF is returned with close_line None and a body
    running to the end of the file. Dropping it instead would let one
    unclosed marker switch a rule off for everything below it, which is the
    cheapest bypass a fence rule can have; what that means is each caller's
    decision, so the fact is reported rather than resolved here.
    """
    blocks = []
    open_line, char, length, info = None, "", 0, ""
    for i, line in enumerate(lines, 1):
        m = FENCE_RE.match(line)
        if not m:
            continue
        marker, rest = m.group(2), m.group(3)
        if open_line is None:
            open_line, char, length, info = i, marker[0], len(marker), rest.strip()
        elif marker[0] == char and len(marker) >= length and not rest.strip():
            blocks.append((open_line, info, i - open_line - 1, i))
            open_line = None
    if open_line is not None:
        blocks.append((open_line, info, len(lines) - open_line, None))
    return blocks


def fence_mask(lines, blocks=None):
    """1-based flags: True for every line inside or delimiting a fenced block."""
    mask = [False] * (len(lines) + 1)
    for open_line, _, _, close_line in (blocks if blocks is not None
                                        else fence_blocks(lines)):
        for i in range(open_line, (close_line or len(lines)) + 1):
            mask[i] = True
    return mask


def req_tables(lines):
    """Tables OUTSIDE a fenced block: (header cells|None, header line|None, rows).

    One reader for every place a requirement row is counted - check_req_table,
    Vault.req_index and the global duplicate scan, the latter two through the
    req_rows view below - so the validator cannot disagree with itself about
    how many requirements a file has, and, since fence_blocks is the
    exporter's rule, neither can the two tools (amendment 2026-07-31b,
    residual 1).

    Structure is the GFM tables extension's, not this project's: a table is a
    delimiter row with a header row of the same cell count directly above it,
    and "if the header row does not match the delimiter row in the number of
    cells ... a table will not be recognized". That is what makes the header
    identifiable WITHOUT reading its words - the recognition issue #25 is
    about. A group of rows carrying no delimiter row is returned with header
    None: it is no table, and saying so is what lets the caller report it
    instead of quietly reading its first row as data.

    A fenced line ENDS the current group rather than being skipped over. Two
    tables separated by a quoted example are two tables; merging them makes
    the second one's header a body row, which is a blocking finding on a line
    the author wrote correctly.

    Only the row directly after a group's first row can become the delimiter,
    which is what keeps the empty placeholder rows of this project's own REQ
    template - '|   |   |   |   |   |', which is_separator accepts - from
    promoting a later row to a header.

    A file left inside an open fence is read as if it carried no fence at
    all. Here the stakes are higher than in check_leaks, which evaluates such
    a block to EOF for the same reason: the rows below would not be reported
    wrongly, they would silently stop existing - and req-class, req-nnn and
    req-criterion all reach the stop gate's blocking set.
    """
    blocks = fence_blocks(lines)
    mask = ([False] * (len(lines) + 1) if any(c is None for _, _, _, c in blocks)
            else fence_mask(lines, blocks))
    tables, cur = [], None
    for i, line in enumerate(lines, 1):
        if mask[i]:
            cur = None
            continue
        cells = split_cells(line)
        if cells is None or len(cells) < 2:
            cur = None
            continue
        if is_separator(cells):
            if (cur is not None and cur[0] is None and len(cur[2]) == 1
                    and len(cells) == len(cur[2][0][1])):
                cur[0], cur[1] = cur[2][0][1], cur[2][0][0]
                cur[2].clear()
            continue
        if cur is None:
            cur = [None, None, []]
            tables.append(cur)
        cur[2].append((i, cells))
    return [(header, line, rows) for header, line, rows in tables]


def req_rows(lines):
    """(line number, cells) of every table body row OUTSIDE a fenced block.

    The flat view of req_tables, for the two consumers that ask about rows
    and not about tables: the requirement index and the global duplicate
    scan. Both stay deliberately more tolerant than check_req_table - they
    answer "does this identifier exist anywhere", and a row they stop seeing
    turns into verifies-unknown-req on some evidence note, which is a
    blocking finding on the wrong file.
    """
    for _, _, rows in req_tables(lines):
        yield from rows


def fence_host(info: str):
    """Declared machine of a fence, or None when it declares none.

    '' means the author wrote host= and named nothing - a declaration that
    names no machine, which is a finding rather than an exemption.
    """
    m = FENCE_HOST_RE.search(info)
    return m.group(1).strip("\"'") if m else None


def split_cells(line, ncols=None):
    """Cells of one Markdown table row, or None when the line is not one.

    GFM tables extension: "Include a pipe in a cell's content by escaping
    it, including inside other inline spans." Both halves of that sentence
    carry weight and a plain split("|") gets both wrong - an escaped pipe
    must NOT divide, and an unescaped one must divide even inside a code
    span. The scan therefore consumes a backslash together with whatever
    follows it before looking for a delimiter. That also makes '\\\\|'
    divide: the backslash is itself escaped and no longer escapes the pipe.
    cmark-gfm renders that one the other way (github/cmark-gfm#277, reported
    and unanswered); the spec is followed rather than the implementation,
    and no vault on this machine contains the shape either way.

    The closing delimiter is recognised during the scan instead of being
    cut off the raw text first. 's.endswith("|")' is also true of a row
    ending in a deliberate '\\|', and removing that would delete the
    author's pipe and leave a stray backslash nothing can undo.

    A leading pipe stays mandatory, unlike in GFM, where it is optional:
    without it every prose line containing a pipe would be a table row.

    With ncols the row is padded with empty cells and truncated to that
    width - what GFM prescribes for a body row narrower or wider than its
    header (example 204). A line that is no table row stays None; ncols
    never fabricates one.

    Cells come back verbatim, escapes intact. Resolving them here would
    unescape twice in every consumer that already calls unescape() on the
    text it carries forward.
    """
    s = line.strip()
    if not s.startswith("|"):
        return None
    body = s[1:]
    cells, buf, i, closed = [], [], 0, False
    while i < len(body):
        c = body[i]
        if c == "\\" and i + 1 < len(body):
            buf.append(body[i:i + 2])
            i += 2
            closed = False
            continue
        if c == "|":
            cells.append("".join(buf).strip())
            buf = []
            closed = i == len(body) - 1
            i += 1
            continue
        buf.append(c)
        i += 1
        closed = False
    cells.append("".join(buf).strip())
    if closed and len(cells) > 1:
        cells.pop()     # the closing delimiter, not an empty last column
    if ncols:
        cells = (cells + [""] * ncols)[:ncols]
    return cells


def is_separator(cells):
    """True for the '| --- | :--: |' row that declares a table's alignment."""
    return bool(cells) and all(re.fullmatch(r":?-{2,}:?", c) for c in cells if c)


def parse_table_row(line: str):
    """One table row of two or more cells, or None.

    The predicate is the exporter's rather than a stricter local one. GFM
    makes the trailing pipe optional, and while this validator demanded it,
    a row written without it was a requirement row for the exporter and not
    for the validator - the disagreement amendment 2026-08-01 removed for
    fences, one layer further down. Measured across all seven vaults on
    this machine: not one line is classified differently by the two
    predicates, so sharing one costs nothing and leaves nothing to drift.

    Two cells minimum: a single-column table is legal GFM, and neither tool
    has ever read one - the exporter's section scan requires two as well.
    """
    cells = split_cells(line)
    if cells is None or len(cells) < 2 or is_separator(cells):
        return None
    return cells


def parse_frontmatter(lines):
    """Minimal flat YAML parser. Returns (dict|None, end_line, malformed_msg).

    Two spellings of a list are accepted and fold into the same Python
    list: the inline 'tags: [a, b]' and the block sequence Obsidian's own
    properties editor writes -

        tags:
        - hardware

    The block form is not a nicety: it is what the editor produces the
    moment a property is edited through the UI rather than in the raw
    text, and rejecting it made a file the editor had just written an
    ERROR in the stop gate's blocking set (issue #24; residual 3 and
    follow-up 7 of amendment 2026-07-28d).

    Items may be indented or not. YAML 1.2 (8.2.1) permits a block
    sequence at the indentation of its parent mapping key, and the
    Obsidian documentation spells it without indentation - reading only
    the indented form would have left the editor's own output rejected.
    All items of one sequence must share the indentation of the first,
    so a deeper '-' is reported instead of silently becoming a sibling:
    PyYAML reads that shape as one continued scalar, and being stricter
    than the reference is honest where agreeing with it is not cheap.

    The closing '---' is located BEFORE anything is parsed, so the reader
    can never walk past the frontmatter into the body. This matters more
    now than it did: with block sequences accepted, a file missing its
    closing marker would swallow the body's bullet lists into a value and
    push end_line to EOF - which is exactly where check_leaks and
    check_paths stop looking. Such a file is therefore reported AND given
    end_line 0, so it is read as if it carried no frontmatter at all and
    the body checks still run. That is req_rows' rule for an unclosed
    fence one layer up: one stray marker must not switch a check off.
    """
    if not lines or lines[0].strip() != "---":
        return None, 0, None
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        return None, 0, "frontmatter never closed with ---"
    data = {}
    # The key a block sequence would belong to, and the indentation its
    # items agreed on. Both are cleared by the next key line.
    open_key, indent = None, None
    for i in range(1, end):
        line = lines[i]
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue        # neither closes an open sequence, as in YAML
        m = SEQ_ITEM_RE.match(stripped)
        if m:
            if open_key is None:
                return None, i + 1, (f"list item {stripped!r} belongs to no key - "
                                     "frontmatter is a mapping, not a sequence")
            if "\t" in line:
                return None, i + 1, (f"tab in list item {stripped!r} - YAML forbids "
                                     "tabs here; use spaces")
            ind = len(line) - len(line.lstrip())
            if indent is None:
                indent = ind
            elif ind != indent:
                return None, i + 1, (f"list item {stripped!r} is indented differently "
                                     f"than the first item of '{open_key}'")
            item = (m.group(1) or "").strip()
            if SEQ_NESTED_RE.match(item):
                return None, i + 1, (f"list item {stripped!r} carries a nested mapping - "
                                     "this frontmatter reader is flat")
            if not isinstance(data.get(open_key), list):
                data[open_key] = []
            if item:
                data[open_key].append(item.strip("'\""))
            continue
        m = re.match(r"^([A-Za-z][\w-]*):\s*(.*)$", stripped)
        if not m:
            return None, i + 1, f"unparseable frontmatter line: {stripped!r}"
        if line[:len(line) - len(line.lstrip())]:
            return None, i + 1, (f"indented key {stripped!r} - a nested mapping is not "
                                 "read by this frontmatter reader")
        key, val = m.group(1), m.group(2).strip()
        open_key, indent = None, None
        if val.startswith("[") and val.endswith("]"):
            inner = val[1:-1].strip()
            data[key] = [v.strip().strip("'\"") for v in inner.split(",") if v.strip()]
        elif not val:
            # Provisional. A following '- item' turns it into a list; a key
            # with nothing under it keeps the empty string it has always
            # had, because '[]' here would newly fire verifies-empty on
            # files nobody changed.
            data[key] = ""
            open_key = key
        else:
            data[key] = val.strip("'\"")
    return data, end + 1, None


def section_of(lines, idx, fm_end):
    """Lowercased H2 heading governing line idx (0-based)."""
    for j in range(idx, fm_end - 1, -1):
        if j < len(lines) and lines[j].startswith("## "):
            return lines[j][3:].strip().lower()
    return ""


def frontmatter_id(lines):
    """The object identifier of a file, or None. Never raises.

    Only a pattern-conforming identifier counts as an identity. An unfilled
    template placeholder (ARC-DOM-NNN), an empty 'id:', a trailing comment
    and a YAML list ('id: [X]', which parse_frontmatter returns as a list)
    are all NOT identities and must never collide with anything - two files
    copied from the same template are not two objects claiming one identity.
    Malformed frontmatter yields None rather than an exception: this runs in
    the per-file path too, and a crash exits 2, which both hooks swallow.
    """
    fm, _, bad = parse_frontmatter(lines)
    if bad or not fm:
        return None
    v = fm.get("id")
    if not isinstance(v, str):
        return None
    v = v.strip()
    return v if ID_RE.match(v) else None


def frontmatter_required_message(vault: Vault, abbr: str) -> str:
    """List the fields this domain requires in YAML frontmatter."""
    fields = vault.fields_for(abbr)
    required = [name for name, desc in fields.items() if desc.get("required")]
    return "domain files need YAML frontmatter (" + ", ".join(required) + ")"


def req_scope(path: Path, lines, abbr="REQ"):
    """Scope token of a requirements file: its own id first, its filename second.

    Identity lives in the frontmatter (DECISIONS.md, amendment 2026-07-28b),
    so a renamed REQ file keeps the identity of its rows. The filename
    fallback keeps every vault that predates the identifier rollout working
    unchanged - which is every vault except this template today.

    'abbr' is the abbreviation of the vault's own requirements domain (the
    role map), so a German vault's 'id: ANF-BAK-000' resolves the same way
    - the exporter's req_scope_of rule since issue #66. For abbr='REQ' the
    accepted set is exactly what frontmatter_id + REQ_FILE_ID_RE accepted
    before: every REQ_FILE_ID_RE match is an ID_RE match, so the old
    intersection IS REQ_FILE_ID_RE, which is this pattern.
    """
    fm, _, bad = parse_frontmatter(lines)
    if not bad and fm:
        v = fm.get("id")
        if isinstance(v, str):
            m = re.match(rf"^{re.escape(abbr)}-([A-Z]{{2,4}})-\d{{3}}$", v.strip())
            if m:
                return m.group(1)
    m = DOM_IN_NAME_RE.search(path.stem)
    return m.group(1) if m else None


# --------------------------------------------------------------------------
# File-local checks
# --------------------------------------------------------------------------

def validate_file(vault: Vault, path: Path, content=None, strict_links=False):
    """File-local checks. 'content' is the raw BYTES of another revision of
    this file - git_head_content's blob, for the per-file baseline - and
    None for the file as it lies on disk. Bytes rather than text because
    the encoding of a revision is part of what the baseline has to know.
    """
    findings = []
    kind, abbr = vault.classify(path)
    if kind in ("outside", "skip"):
        return findings
    text, encoding_problem = (decode_source(content) if content is not None
                              else read_source(path))
    lines = text.splitlines()

    # Reported once per vault, and never on a git-HEAD baseline pass (whose
    # WARNs are discarded, which would swallow this one silently).
    if content is None and vault.schema_error() and not vault._schema_reported:
        vault._schema_reported = True
        findings.append(Finding("WARN", "schema-unreadable", str(SCHEMA_PATH), None,
                                vault.schema_error() + " - falling back to the built-in "
                                "field set; declared values and editor fields are not "
                                "in effect"))

    # Reported for every kind that is read at all, templates included: a
    # template nobody can decode empties the required-section set of its
    # whole domain. The finding is added to the others rather than
    # replacing them - a check that stops reporting is what this layer
    # exists to prevent, and the per-file ratchet compares codes against
    # the same file at HEAD, so a run that suddenly reports one code where
    # it used to report three would block the very session that repaired
    # the file (issue #31, adversarial review).
    if encoding_problem:
        findings.append(Finding("ERROR", "encoding-not-utf8", str(path), 1,
                                f"{encoding_problem} - this vault is UTF-8. Every "
                                "check below read replacement characters, so its "
                                "findings are consequences of the encoding rather "
                                "than defects of their own; re-save the file as "
                                "UTF-8 and read them again."))

    if kind == "inbox":
        check_links(vault, path, lines, findings, strict_links, hub=False)
        if content is None:
            check_inb_age(path, findings)
        return findings

    if kind in ("root", "infra"):
        if kind == "infra":
            fm, _, bad = parse_frontmatter(lines)
            if bad and TEMPLATE_NAME_RE.match(path.name):
                findings.append(Finding("ERROR", "template-unreadable", str(path), 1, bad))
            elif fm:
                # Vocabulary only. A template's VALUES are placeholders
                # (created: YYYY-MM-DD, id: ARC-DOM-NNN) and cannot be
                # checked - but a key nobody declared propagates silently
                # into every file copied from it, so the template is the one
                # place where catching it is worth the most.
                check_undeclared(vault, fm, abbr, path, findings)
        # infra/root files carry placeholder example links - never strict
        check_links(vault, path, lines, findings, strict=False,
                    hub=path.name == "system_overview.md")
        return findings

    # ---- full domain-file checks ----
    if not path.name.startswith(f"{abbr}_"):
        findings.append(Finding("ERROR", "filename-prefix", str(path), None,
                                f"file in {abbr} domain folder must be named {abbr}_*"))

    fm, fm_end, bad = parse_frontmatter(lines)
    if bad:
        findings.append(Finding("ERROR", "frontmatter-malformed", str(path), 1, bad))
        fm = {}
    elif fm is None:
        findings.append(Finding("ERROR", "frontmatter-missing", str(path), 1,
                                frontmatter_required_message(vault, abbr)))
        fm, fm_end = {}, 0
    else:
        check_frontmatter(vault, fm, abbr, path, findings)

    check_sections(vault, abbr, path, lines, findings)
    check_length(path, lines, findings)
    check_links(vault, path, lines, findings, strict_links, hub=abbr == "ARC")
    check_leaks(abbr, path, lines, fm_end, findings)
    check_paths(vault, path, lines, fm_end, findings)
    if abbr == "REQ":
        check_req_table(vault, path, lines, findings)
    # The evidence trigger follows the role map (issue #66): a German
    # vault's TUE notes carry 'verifies' too, and a dangling entry there is
    # the same defect. The REQ trigger above stays literal on purpose -
    # four blocking row-grammar codes on translated files would be a
    # convention rollout, not a fix.
    if abbr == (vault.roles().get("TAE") or "TAE"):
        check_tae_verifies(vault, fm, path, findings)
    if abbr == "DEC":
        check_dec_status(vault, path, lines, findings)

    body = [l for l in lines[fm_end:] if l.strip()]
    if len(body) < STUB_MIN_LINES:
        findings.append(Finding("WARN", "stub", str(path), None,
                                f"only {len(body)} content lines - stub file? "
                                "Fill it or do not create it yet."))
    return findings


def check_frontmatter(vault, fm, abbr, path, findings):
    """Frontmatter rules, read from vault_schema.json rather than from Python.

    Only fields flagged 'schema-driven' are enforced. A 'declared-only' field
    is part of the vocabulary - so it is never reported as undeclared - but
    its value is not checked: that is how 'id' keeps its unfilled template
    placeholder befinding-free, and how 'verifies' stays enforced in TAE
    alone while a German evidence domain carrying it costs nothing.
    """
    fields = vault.fields_for(abbr)
    for key in sorted(fields):
        desc = fields[key]
        if desc.get("enforced") != "schema-driven":
            continue
        if key not in fm:
            if desc.get("required"):
                hint = desc.get("hint")
                msg = f"frontmatter missing required key '{key}'"
                if isinstance(hint, str) and hint:
                    msg += f" ({hint})"
                findings.append(Finding("ERROR", "frontmatter-key", str(path), 1, msg))
            continue
        check_field_value(key, fm[key], desc, abbr, path, findings)
    check_undeclared(vault, fm, abbr, path, findings)


def check_field_value(key, value, desc, abbr, path, findings):
    """One frontmatter value against its declared type. Never raises.

    str() before every comparison: parse_frontmatter returns a list for
    'status: [active]', and an unhashable operand in a membership test raises
    TypeError - which exits 2, which both hooks swallow.
    """
    kind = desc.get("type")
    code = desc.get("code") or "frontmatter-value"

    if kind == "list":
        if not isinstance(value, list):
            return          # a scalar where a list belongs: unreported, as before
        if not value:
            empty_code = desc.get("empty_code")
            if empty_code and desc.get("required"):
                findings.append(Finding("WARN", empty_code, str(path), 1,
                                        f"'{key}' names no requirement - "
                                        "what does this file prove?"))
        elif desc.get("item") == "req-row-identifier":
            for item in value:
                if not (isinstance(item, str) and REQ_ID_RE.fullmatch(item)):
                    findings.append(Finding("ERROR", code, str(path), 1,
                                            f"'{item}' is not a REQ-DOM-NNN id"))
        elif desc.get("item") == "object-identifier":
            for item in value:
                if not (isinstance(item, str) and OBJECT_ID_RE.fullmatch(item)):
                    findings.append(Finding("ERROR", code, str(path), 1,
                                            f"'{item}' is not a DOMAIN-SCOPE-NNN id"))
        return

    # An empty scalar is a missing scalar; the required-key check owns it.
    if not value:
        return
    text = str(value)

    if kind == "folder-abbreviation":
        if text != abbr:
            findings.append(Finding("ERROR", code, str(path), 1,
                                    f"frontmatter {key} '{text}' != "
                                    f"folder domain '{abbr}'"))
    elif kind == "enum":
        values = _strlist(desc, "values")
        if values and text not in values:
            findings.append(Finding("ERROR", code, str(path), 1,
                                    f"{key} '{text}' not in {sorted(values)}"))
    elif kind == "date":
        if not DATE_RE.match(text):
            findings.append(Finding("ERROR", code, str(path), 1,
                                    f"'{key}' must be YYYY-MM-DD, got '{text}'"))


def check_undeclared(vault, fm, abbr, path, findings):
    """Frontmatter keys nobody declared - the silent defect class.

    A mistyped key ('crated') is the only frontmatter mistake that fails
    completely quietly: the field looks present and takes effect nowhere.

    WARN, not ERROR. The check cannot tell a typo from a deliberate plugin
    field, which is Clippy's stated disqualification for a deny-by-default
    lint and Tricorder's for a blocking one. One grouped finding per file:
    a file with five stray keys must not produce five lines, the lesson of
    the aggregated link feedback in amendment 2026-07-27.
    """
    known = set(vault.fields_for(abbr))
    editor_names, editor_prefixes = vault.editor_fields()
    unknown = sorted(k for k in fm
                     if k not in known and k not in editor_names
                     and not k.startswith(editor_prefixes))
    if unknown:
        findings.append(Finding("WARN", "frontmatter-undeclared", str(path), 1,
                                f"frontmatter key(s) {unknown} are declared neither "
                                f"for domain {abbr} nor as editor fields - a typo "
                                "takes effect nowhere; declare the field in "
                                "vault_schema.json if it is intended"))


def classify_sections(template_h2, file_h2):
    """One template's required H2s against one file's H2s.

    -> (absent, mismatch, near_miss). Three outcomes rather than two,
    because a heading the author wrote and a heading nobody wrote are
    different defects and only one of them is fixable by writing a section:

    - written identically up to invisible differences: met, reported nowhere
    - written case-folding-equal ('allgemeine Übersicht'): met, near miss
    - written as a longer or shorter variant sharing a prefix at a word
      boundary ('Ablauf (monatlich)', 'Zuordnung'): NOT met, mismatch - a
      differently scoped section is a different section, and the template's
      title is the anchor the schema binds relations to
    - anything else: absent

    Iteration is sorted and the file side keeps first occurrences, so which
    spelling and which line a finding names never depends on set order.
    """
    strict, folded = {}, {}
    for h, line in file_h2.items():
        strict.setdefault(strict_key(h), (h, line))
        folded.setdefault(fold_key(h), (h, line))
    absent, mismatch, near = [], [], []
    for req in sorted(template_h2):
        if not req.strip():
            continue        # a bare '## ' in a template requires nothing
        if strict_key(req) in strict:
            continue
        fold = fold_key(req)
        if fold in folded:
            h, line = folded[fold]
            near.append((req, h, line))
            continue
        related = sorted((line, h) for k, (h, line) in folded.items()
                         if prefix_related(fold, k))
        if related:
            line, h = related[0]
            mismatch.append((req, h, line))
        else:
            absent.append(req)
    return absent, mismatch, near


def render_headings(pairs):
    return "; ".join(f"template '{req}' vs '{h}' (line {line})"
                     for req, h, line in pairs)


def check_sections(vault, abbr, path, lines, findings):
    templates = vault.templates_for(abbr)
    if not templates:
        return  # domain without templates (e.g. ADM): nothing to enforce
    file_h2 = h2_index(lines)
    best = None
    for tname, th2 in templates:
        absent, mismatch, near = classify_sections(th2, file_h2)
        # Unmet promises decide which template a file was written from;
        # near misses only break a tie, so a file matching one template
        # loosely never outranks one it satisfies.
        score = (len(absent) + len(mismatch), len(near))
        if best is None or score < best[0]:
            best = (score, tname, absent, mismatch, near)
        if score == (0, 0):
            return
    _, tname, absent, mismatch, near = best
    if absent:
        findings.append(Finding("ERROR", "template-sections", str(path), None,
                                f"missing required sections {sorted(absent)} "
                                f"(closest template: {tname})"))
    if mismatch:
        findings.append(Finding("ERROR", "section-mismatch", str(path),
                                min(e[2] for e in mismatch),
                                "required section(s) written under a different title: "
                                + render_headings(mismatch)
                                + " - a qualifier makes it a differently scoped "
                                  "section; keep the template's title and put the "
                                  "qualifier in a '###' below it"))
    if near:
        findings.append(Finding("WARN", "section-near-miss", str(path),
                                min(e[2] for e in near),
                                "required section(s) spelled differently: "
                                + render_headings(near)
                                + " - counted as present; the template's spelling "
                                  "is what a reader and a search look for"))


def check_length(path, lines, findings):
    n = len(lines)
    if n > LENGTH_ERROR:
        findings.append(Finding("ERROR", "length", str(path), None,
                                f"{n} lines > {LENGTH_ERROR}. One file answers ONE question - split it."))
    elif n > LENGTH_WARN:
        findings.append(Finding("WARN", "length", str(path), None,
                                f"{n} lines > {LENGTH_WARN}. Apply the 4-question rule: "
                                "does the filename still fully describe the content? Consider splitting."))
    if n > STRUCTURE_WARN and not any(l.startswith(("## ", "### ")) for l in lines):
        findings.append(Finding("WARN", "structure", str(path), None,
                                f"{n} lines without any subheading - add structure."))


def anchor_index(lines, mask):
    """(folded headings, block identifiers) of one file, outside fenced blocks.

    The mask is what keeps a shell comment from becoming a heading: a
    '```bash' block full of '# rebuild the image' lines would otherwise
    resolve every anchor anyone cares to write.
    """
    heads, blocks = set(), set()
    for i, line in enumerate(lines, 1):
        if mask[i]:
            continue
        m = HEADING_RE.match(line)
        if m:
            heads.add(fold_key(m.group(1)))
            continue
        m = BLOCK_ID_RE.search(line)
        if m:
            blocks.add(m.group(1))
    return heads, blocks


def anchor_resolves(anchor, heads, blocks):
    """Does '#Heading', '#A#B' or '#^blockid' name something in this file?

    Headings compare folded, which is the tolerance classify_sections
    already grants: a heading differing only in case or in an invisible
    character IS that heading, and reporting the difference as a broken
    link would be a finding nobody can act on. Obsidian chains subheadings
    with further hashes ('[[Note#Chapter#Section]]'), and every segment of
    such a chain has to name a heading; the order between them is not
    checked, which is stated as a residual rather than implied.
    """
    body = anchor.lstrip("#")
    if body.startswith("^"):
        return body[1:] in blocks
    segs = [s.strip() for s in anchor.split("#") if s.strip()]
    return bool(segs) and all(fold_key(s) in heads for s in segs)


def check_links(vault, path, lines, findings, strict, hub=False):
    md_names, all_names = vault.md_names(), vault.all_names()
    targets = Counter()
    total = 0
    mask = fence_mask(lines)
    anchors = None      # built on the first same-file link, never for a file without one
    for i, line in enumerate(lines, 1):
        if mask[i]:
            continue
        # Obsidian does not resolve links inside code spans
        line = re.sub(r"`[^`]*`", " ", line)
        for m in WIKILINK_RE.finditer(line):
            target = m.group(2).strip()
            anchor = (m.group(3) or "").strip()
            if not target:
                # A link into this file. It names no other file, so it is
                # resolved against this one - and it is deliberately kept
                # out of the budget and the repeat counter below, both of
                # which are about OUTGOING links: "link the responsible
                # file once" has no addressee when the target is the file
                # the reader is already in.
                if not anchor.strip("#^"):
                    # '[[]]', '[[#]]', '[[|alias]]' - a link naming nothing
                    # at all. Skipped rather than reported, which is what
                    # the old regex did by not matching it; a finding for
                    # the empty placeholder is a rollout of its own.
                    continue
                if anchors is None:
                    anchors = anchor_index(lines, mask)
                if not anchor_resolves(anchor, *anchors):
                    sev = "ERROR" if strict else "WARN"
                    findings.append(Finding(sev, "link-unresolved", str(path), i,
                                            f"[[{anchor}]] names no heading and no "
                                            "block identifier in this file"))
                continue
            total += 1
            targets[target] += 1
            resolved = (target in md_names or target in all_names
                        or f"{target}.md" in all_names)
            if not resolved:
                sev = "ERROR" if strict else "WARN"
                findings.append(Finding(sev, "link-unresolved", str(path), i,
                                        f"[[{target}]] does not resolve to any file "
                                        f"under {vault.index_root_label()}"))
    budget = LINK_BUDGET_HUB if (hub or path.name == "system_overview.md") else LINK_BUDGET
    if total > budget:
        findings.append(Finding("WARN", "link-budget", str(path), None,
                                f"{total} outgoing links > {budget}. Link the responsible "
                                "file once - do not link every mention."))
    for t, c in targets.items():
        if c > LINK_REPEAT_WARN:
            findings.append(Finding("WARN", "link-repeat", str(path), None,
                                    f"[[{t}]] linked {c}x in one file."))


def check_fence(abbr, path, line, info, body_lines, findings):
    """One fenced block in a domain where fences are restricted.

    The rule is about drift against a named source, not about the three
    backticks (DECISIONS.md, amendment 2026-07-28f). A copy of a file this
    repository owns drifts against its original and must be replaced by the
    path. A block recording the state of, or a command against, a machine
    this project does not own has no path to point at: it is not a copy but a
    record - ISO 9000:2015 3.8.10, "document stating results achieved or
    providing evidence of activities performed", which "need not be under
    revision control". Its currency is carried by last-verified.

    Length is what decides whether the question is even asked, because it is
    the only signal that correlates with drift risk and needs nothing from
    the author. Up to FENCE_RECORD_MAX content lines a block is a single
    observation and is silent. Above it, the block must either go (ERROR) or
    name the machine it is true on (WARN - visible, greppable and countable,
    because nothing here can prove that no source file exists).
    """
    if abbr not in FENCE_BANNED_DOMAINS:
        return
    if abbr not in FENCE_EXEMPT_DOMAINS:
        findings.append(Finding("ERROR", "code-fence", str(path), line,
                                f"code blocks are banned in {abbr} - {abbr} is a map and "
                                "stores nothing; link the file or the IMP note instead "
                                "(a host declaration does not lift this)"))
        return
    host = fence_host(info)
    if host == "":
        findings.append(Finding("ERROR", "fence-host", str(path), line,
                                "'host=' names no machine - a declaration that names "
                                "nothing is not a declaration; write host=<machine>"))
        return
    if body_lines <= FENCE_RECORD_MAX:
        return
    if host:
        findings.append(Finding("WARN", "fence-record", str(path), line,
                                f"{body_lines} content lines declared as a record of "
                                f"'{host}' - nothing verifies that no source file "
                                "exists; keep it only while it is the only record"))
        return
    findings.append(Finding("ERROR", "code-fence", str(path), line,
                            f"{body_lines} content lines > {FENCE_RECORD_MAX} in {abbr} - "
                            "too long to be one observation. Reference the artifact path "
                            "(pointers, not copies), or, if the block records a machine "
                            "this project does not own, declare it: ```lang host=<machine>"))


def check_leaks(abbr, path, lines, fm_end, findings):
    """Implementation-detail leak detector.

    Precision over recall: only ARC (whole body, ERROR - the README bans
    concrete values outright) and DEC Context (WARN) are scanned; the
    value-bearing domains (REQ tables, CMP specs, IFC specs, TAE evidence,
    IMP, OAU) are legitimate homes for numbers and are never flagged.
    Fenced blocks are restricted in IMP and ARC - see check_fence.
    """
    blocks = fence_blocks(lines)
    mask = fence_mask(lines, blocks)
    # A block opened and never closed is judged on its body to EOF rather
    # than dropped: one unclosed marker would otherwise switch the rule off
    # for everything below it, which is the cheapest bypass a fence rule can
    # have. fence_blocks reports it that way, so both cases land here.
    for open_line, info, body_lines, _ in blocks:
        check_fence(abbr, path, open_line, info, body_lines, findings)
    for i, line in enumerate(lines, 1):
        if mask[i] or abbr not in ("ARC", "DEC") or i <= fm_end:
            continue
        sec = section_of(lines, i - 1, fm_end)
        if abbr == "DEC" and "context" not in sec:
            continue
        if "reference" in sec or "source" in sec:
            continue
        stripped = line
        for r in STRIP_RES:
            stripped = r.sub(" ", stripped)
        hits = [m.group(0) for m in NUM_UNIT_RE.finditer(stripped)]
        hits += [m.group(0) for m in PIN_RE.finditer(stripped)]
        if hits:
            sev = "ERROR" if abbr == "ARC" else "WARN"
            findings.append(Finding(sev, "impl-leak", str(path), i,
                                    f"concrete value(s) {hits} in {abbr}"
                                    + (" - ARC stores no values; move to IMP/CMP/IFC and link"
                                       if abbr == "ARC" else
                                       " - Context frames the problem; concrete numbers "
                                       "belong in Options or in IMP/CMP")))

def check_paths(vault, path, lines, fm_end, findings):
    """Dead-pointer check over the whole body.

    What counts as a project artifact is one rule in both zones: a token
    is checked only where it is shaped like one (ARTIFACT_SEG_RE, an NN_
    first or second segment). Everything else names something this
    project cannot own - a host path (/etc/..., ~/.config/...), the
    remainder of a URL after '://', a git remote, a fragment cut out of a
    quoted path containing a space - and resolving it against
    project_root could only ever report it as dead (DECISIONS.md,
    amendment 2026-07-28e).

    The zones still differ where that was decided on purpose. Under an H2
    naming references or sources, dead pointers are ERROR, fenced and
    backticked content is scanned, and no pending/planned/TBD marker
    suppresses anything (silent-bypass prevention). In the rest of the
    body the same finding is a WARN, inline code and fenced blocks are
    skipped, and an explicit marker on the line or its governing heading
    suppresses it. Fence state is tracked first so fenced '## ' lines
    never switch zones. A fence declaring a machine (```lang host=<name>)
    is skipped even in the strict zone: its content is true elsewhere and
    this project cannot resolve it - the same ownership rule, now reachable
    because the block says so instead of the validator guessing.
    """
    blocks = fence_blocks(lines)
    mask = fence_mask(lines, blocks)
    delims = {b[0] for b in blocks} | {b[3] for b in blocks if b[3]}
    host_at = [None] * (len(lines) + 1)
    for open_line, info, _, close_line in blocks:
        h = fence_host(info)
        for i in range(open_line, (close_line or len(lines)) + 1):
            host_at[i] = h
    in_ref = False
    pending_scope = False
    for i, line in enumerate(lines, 1):
        in_fence = mask[i]
        if i in delims:
            continue        # the markers themselves carry no pointer
        if not in_fence:
            if line.startswith("## "):
                h = line[3:].strip().lower()
                in_ref = "reference" in h or "source" in h
                pending_scope = bool(PENDING_RE.search(h))
                continue
            if line.startswith("### "):
                pending_scope = bool(PENDING_RE.search(line))
                continue
        if i <= fm_end:
            continue
        if in_ref:
            if host_at[i]:
                # The block states which machine its content is true on, so its
                # paths are not this project's to resolve - the same ownership
                # rule the shape gate applies (amendment 2026-07-28e).
                continue
            scan = line
        elif in_fence:
            continue
        else:
            scan = re.sub(r"`[^`]*`", " ", line)
            if pending_scope or PENDING_RE.search(scan):
                continue
        for m in PATH_TOKEN_RE.finditer(scan):
            token = m.group(1)
            if token.startswith(("http", "Projectname/", "www.")):
                continue
            segs = token.split("/")
            if not (ARTIFACT_SEG_RE.match(segs[0])
                    or (len(segs) > 2 and ARTIFACT_SEG_RE.match(segs[1]))):
                continue
            candidates = [
                vault.project_root / token,
                vault.project_root.parent / token,
            ]
            if len(segs) > 1:
                candidates.append(vault.project_root / "/".join(segs[1:]))
            if not any(c.exists() for c in candidates):
                sev = "ERROR" if in_ref else "WARN"
                msg = (f"referenced artifact '{token}' does not exist - "
                       "stale pointer (docs say A, disk says B)")
                if not in_ref:
                    msg += " - mark it pending/planned/TBD if intentionally not created yet"
                findings.append(Finding(sev, "path-missing", str(path), i, msg))


def canonical_req_header(cells):
    """The header row this project's own REQ template writes.

    One of two signals that a table is a requirement table, and the weaker
    one: nothing enforces a header row's wording, and a translated or
    reworded header is not a defect. It is kept because it recognises a
    table whose rows are ALL malformed, where the second signal - a row
    carrying a requirement number - has nothing left to read.
    """
    return "Class" in cells[0] or "NNN" in " ".join(cells[:2])


def check_req_table(vault, path, lines, findings):
    """Requirement rows, in every table of a REQ file that is one.

    A requirement table is recognised by its shape rather than by the words
    in its header (issue #25): a GFM table of at least REQ_ROW_COLUMNS
    columns whose header carries the template's tokens OR whose rows carry a
    requirement number in the second cell - the very predicate Vault.req_index
    uses to decide that a row DEFINES a requirement. The two signals are a
    union with the rule this check used before, so no row that was checked
    stops being checked, and neither the header's wording nor a section title
    has to survive translation for the check to stay on.

    What the header latch cost is measured: a REQ file whose real table
    header drifted and whose only canonical header sat inside a quoted
    example was read and then not checked at all, silently, on four codes
    that all reach the stop gate's blocking set.

    Width is a floor, not an equality. A project that appends a column keeps
    the five positional roles the row checks read, and treating that table as
    unrecognised would sell an exemption from four blocking codes for one
    '| Comment |' in the header.
    """
    # The class vocabulary is data; the table structure below is not - it is
    # row grammar rather than a value list (vault_schema.json, domains.REQ.rows).
    classes = _strlist(_dict(_dict(_dict(vault.schema(), "domains"), "REQ"), "rows"),
                       "class_values") or ["M", "S", "O"]
    seen = {}
    recognized, unread = False, []
    for header, header_line, rows in req_tables(lines):
        width = len(header) if header else (len(rows[0][1]) if rows else 0)
        indexed = any(len(r) >= 2 and ROW_NNN_RE.fullmatch(r[1]) for _, r in rows)
        if (header is None or width < REQ_ROW_COLUMNS
                or not (canonical_req_header(header) or indexed)):
            unread.append((header_line or rows[0][0], width, indexed))
            continue
        recognized = True
        for i, row in rows:
            if len(row) < REQ_ROW_COLUMNS:
                continue
            cls, nnn, content, crit = row[0], row[1], row[2], row[3]
            if not (cls or nnn or content):
                continue  # empty template row
            if cls not in classes:
                findings.append(Finding("ERROR", "req-class", str(path), i,
                                        f"class '{cls}' must be one of {', '.join(classes)}"))
            if not ROW_NNN_RE.fullmatch(nnn):
                findings.append(Finding("ERROR", "req-nnn", str(path), i,
                                        f"NNN '{nnn}' must be 3 digits"))
            elif nnn in seen:
                findings.append(Finding("ERROR", "req-duplicate", str(path), i,
                                        f"NNN {nnn} already used in line {seen[nnn]} - "
                                        "IDs are never reused"))
            else:
                seen[nnn] = i
            if not crit:
                findings.append(Finding("ERROR", "req-criterion", str(path), i,
                                        "empty acceptance criterion - untestable "
                                        "requirement"))
    check_req_table_silence(path, unread, recognized, findings)


def check_req_table_silence(path, unread, recognized, findings):
    """The rows no row check reads - the second half of issue #25.

    A check that stops checking without saying so is the failure mode this
    layer exists to prevent, so the two cases the validator can prove from
    its own state are reported rather than guessed at:

    - a table the requirement index reads rows out of while no row check
      reads them. That is the validator disagreeing with itself, and it is
      the shape a drifted table has when only some of its rows are broken.
    - a REQ file carrying a table wide enough to be a requirement table and
      not one readable table. The file looks like it defines requirements
      and defines none any check can see.

    Neither fires on a table that is simply something else - a source map, a
    rubric, a revision history - which is why a REQ file may carry those
    without a word. WARN, not ERROR: the check cannot tell a table nobody
    meant as a requirement table from one that drifted into being unreadable,
    and that is this project's line for anything that blocks. One grouped
    finding per file, as every per-file class here is aggregated.

    Both cases are asked in REQ domain files only. A vault whose
    requirements role is aliased (ANF) has the first shape everywhere by
    construction - the index follows the role map since issue #66, the row
    checks stay on the literal REQ folder - and this WARN deliberately
    stays dark there: firing on every translated file would be a
    convention rollout, not a defect report.
    """
    hits = [(line, width) for line, width, indexed in unread
            if indexed or (width >= REQ_ROW_COLUMNS and not recognized)]
    if not hits:
        return
    where = ", ".join(f"line {line} ({width} columns)" for line, width in hits)
    findings.append(Finding(
        "WARN", "req-table-unrecognized", str(path), min(line for line, _ in hits),
        f"{where}: not readable as a requirement table, so no row check reads "
        f"it - one is a GFM table (a header row above a delimiter row of the "
        f"same width) of at least {REQ_ROW_COLUMNS} columns whose header "
        "carries the template's tokens or whose rows carry a three-digit "
        "number in the second cell. Rows here are addressed as requirements "
        "elsewhere in the vault, or this file carries no readable requirement "
        "table at all"))


def check_tae_verifies(vault, fm, path, findings):
    ver = fm.get("verifies") if fm else None
    if not isinstance(ver, list):
        return
    index = vault.req_index()
    # What counts as a requirement id here is spelled with the vault's own
    # requirements abbreviation (issue #66) - homelab's evidence notes
    # write ANF-BAK-001, and the index is keyed that way. Without a
    # requirements domain the English prefix keeps today's contract: a
    # REQ-shaped entry in a vault that defines no requirement anywhere is
    # a dangling reference either way.
    abbr = vault.roles().get("REQ") or "REQ"
    rid_re = re.compile(rf"{re.escape(abbr)}-[A-Z]{{2,4}}-\d{{3}}")
    for rid in ver:
        if rid_re.fullmatch(rid) and rid not in index:
            findings.append(Finding("ERROR", "verifies-unknown-req", str(path), 1,
                                    f"{rid} is not defined in any {abbr} file"))


def check_dec_status(vault, path, lines, findings):
    # The value list is data. The companion rule below - Superseded needs a
    # successor link - stays here: it is a cross-reference requirement, not a
    # vocabulary (vault_schema.json, domains.DEC.body_fields.Status).
    desc = _dict(_dict(_dict(_dict(vault.schema(), "domains"), "DEC"),
                       "body_fields"), "Status")
    allowed = _strlist(desc, "values") if desc.get("enforced") == "schema-driven" else []
    status = None
    for i, line in enumerate(lines, 1):
        m = re.match(r"^Status:\s*(.+)$", line.strip())
        if m:
            status = m.group(1).strip()
            if allowed and status not in allowed:
                findings.append(Finding("ERROR", "dec-status", str(path), i,
                                        f"Status '{status}' not in {sorted(allowed)}"))
            if status == "Superseded":
                joined = "\n".join(lines)
                if not re.search(r"Superseded by.*\[\[", joined):
                    findings.append(Finding("ERROR", "dec-superseded", str(path), i,
                                            "Status Superseded requires a "
                                            "'Superseded by: [[DEC_...]]' link"))
            break
    if status is None:
        findings.append(Finding("ERROR", "dec-status", str(path), 1,
                                "DEC file has no 'Status:' line"))


def check_inb_age(path, findings):
    try:
        age_days = (time.time() - path.stat().st_mtime) / 86400
    except OSError:
        return
    if age_days > INB_MAX_AGE_DAYS:
        findings.append(Finding("WARN", "inb-age", str(path), None,
                                f"in inbox for {age_days:.0f} days (max {INB_MAX_AGE_DAYS}) - "
                                "sort it into a domain or delete it"))


# --------------------------------------------------------------------------
# Vault-wide checks (full audit only)
# --------------------------------------------------------------------------

def head_identifiers(vault: Vault):
    """{identifier: path} as of git HEAD, or None when HEAD is not readable.

    None ("cannot compare") stays deliberately distinguishable from {} ("HEAD
    carries no identifier"): a vault folder renamed since HEAD would otherwise
    look like a vault that lost every identifier at once.

    Nothing here may raise. A crash exits 2, and both hooks swallow exit 2 -
    a hard failure would silently switch off the whole enforcement layer.
    """
    repo = vault.git_root()
    if repo is None:
        return None
    try:
        rel = vault.root.relative_to(repo)
    except ValueError:
        return None
    # A vault that IS its own repo (both German production vaults are)
    # yields '.', which is a valid pathspec; '' would be a fatal error.
    pathspec = str(rel) or "."
    base = ["git", "--no-pager", "-C", str(repo)]
    try:
        # Does the vault path exist at HEAD at all? Without this probe a
        # renamed vault root makes the grep below return "no match", which
        # is indistinguishable from "no identifiers".
        probe = subprocess.run(base + ["ls-tree", "-z", "HEAD", "--", pathspec],
                               capture_output=True, timeout=10)
        if probe.returncode != 0 or not probe.stdout.strip():
            return None
        # Candidate prefilter. One process spares a vault without identifiers
        # every per-file read: both German vaults drop to zero git show calls.
        # Bytes, not text=True: -z keeps paths raw and a non-UTF-8 byte would
        # otherwise raise UnicodeDecodeError inside subprocess itself.
        grep = subprocess.run(
            base + ["grep", "-l", "-z", "-I", "-E", r"^[[:space:]]*id:",
                    "HEAD", "--", pathspec],
            capture_output=True, timeout=30)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if grep.returncode == 1:
        return {}      # no candidate at HEAD - nothing can have vanished
    if grep.returncode != 0:
        return None
    out = {}
    for raw in grep.stdout.split(b"\0"):
        if not raw:
            continue
        # Records are "HEAD:<path>"; the rev prefix is fixed, so one split is
        # unambiguous even for a path containing a colon.
        name = raw.split(b":", 1)[-1].decode("utf-8", "replace")
        if not name.endswith(".md"):
            continue
        p = repo / name
        kind, abbr = vault.classify(p)
        if kind != "domain" or abbr in ID_EXCLUDED_DOMAINS:
            continue
        raw = git_head_content(vault, p)
        if raw is None:
            continue
        fid = frontmatter_id(decode_source(raw)[0].splitlines())
        if fid:
            out.setdefault(fid, p)
    return out


def check_identifiers(vault: Vault, all_md, corpus, findings):
    """Vault-wide identifier checks (advisory-only at the stop gate).

    Only identifiers that are actually PRESENT are compared. Requiring an id
    would turn every file of a vault predating the scheme into a finding -
    a convention rollout disguised as a defect report, and both German
    production vaults carry no identifier at all.

    Severities follow the established split for checks that cannot tell a
    mistake from an intention: a collision is never legitimate (ERROR), a
    disappearance can be a retirement, a rename or a loss (WARN).
    """
    worktree = {}
    for p in all_md:
        kind, abbr = vault.classify(p)
        if kind != "domain" or abbr in ID_EXCLUDED_DOMAINS:
            continue
        fid = frontmatter_id(corpus.get(p, "").splitlines())
        if not fid:
            continue
        if fid in worktree:
            findings.append(Finding("ERROR", "id-duplicate", str(p), 1,
                                    f"identifier {fid} is already declared in "
                                    f"{worktree[fid].name} - an identifier "
                                    "addresses exactly one object"))
        else:
            worktree[fid] = p

    # A REQ file whose own id disagrees with the scope token in its filename
    # rekeys every one of its rows. Reported here, at the file that causes it,
    # rather than left to surface as verifies-unknown-req on some TAE file -
    # which is a per-file ERROR and can block the stop gate on the wrong note.
    reqdir = vault.domains.get("REQ")
    if reqdir:
        for f in sorted(reqdir.rglob("*.md")):
            if f.name.startswith("00_"):
                continue
            fid = frontmatter_id(corpus.get(f, "").splitlines())
            m = REQ_FILE_ID_RE.match(fid) if fid else None
            n = DOM_IN_NAME_RE.search(f.stem)
            if m and n and m.group(1) != n.group(1):
                findings.append(Finding("WARN", "id-scope-mismatch", str(f), 1,
                                        f"id scope '{m.group(1)}' differs from the "
                                        f"filename token '{n.group(1)}' - the id wins, "
                                        f"so every row of this file is addressed as "
                                        f"REQ-{m.group(1)}-NNN"))

    head = head_identifiers(vault)
    if not head:
        return
    for fid in sorted(set(head) - set(worktree)):
        findings.append(Finding("WARN", "id-vanished", str(head[fid]), None,
                                f"identifier {fid} existed at git HEAD and is no "
                                "longer present in the vault - retired, renamed or "
                                "lost; identifiers are never reused"))


def check_domain_folders(vault: Vault, findings):
    """Two folders of one vault carrying one domain abbreviation.

    The index picks one by rule since amendment 2026-08-04g, and this is
    the other half of that: a rule that is applied silently is a rule
    nobody can act on, and the folder that lost still holds files the
    author believes are being read as that domain.

    WARN, not ERROR. A translation legitimately produces two folders for
    a while - the conventions say so - and this check cannot tell that
    state from a mistake, which is this project's line for anything that
    blocks. It also runs vault-wide, so it never reaches the stop gate's
    blocking set at all.

    One finding per folder that is not the vault's, at that folder, so a
    vault carrying three of them says so three times rather than once.
    """
    for abbr in sorted(vault.domain_dirs):
        dirs = vault.domain_dirs[abbr]
        if len(dirs) < 2:
            continue
        kept = vault.domains[abbr]
        for d in dirs:
            if d == kept:
                continue
            same_look = ("" if strict_key(d.name) != strict_key(kept.name) else
                         " The two names differ only in characters that render "
                         "identically, so the pair is invisible in a file listing.")
            findings.append(Finding(
                "WARN", "domain-duplicate-folder", str(d), None,
                f"'{d.name}' and '{kept.name}' both carry the {abbr} domain of "
                f"this vault. '{kept.name}' is the one this vault reads: the "
                f"first in sorted order among the folders holding {abbr}_* "
                "files. The files here are still checked file by file, but "
                "every check that reads the domain FOLDER - the requirement "
                "index, the architecture overview, the traceability export - "
                f"reads only '{kept.name}'.{same_look} One domain, one folder: "
                "finish the translation, or remove the folder this vault no "
                "longer writes to"))


def evidence_index(vault: Vault, corpus):
    """{REQ id: [TAE path, ...]} from the 'verifies' field of every TAE file.

    The half of the coverage rule this file can answer on its own, out of
    the corpus it has already read. Only DOMAIN files of the evidence role
    contribute - resolved through the role map, so a German vault's TUE
    notes count (issue #66) - because a '00_' template carries the field
    as a placeholder, and a placeholder is not evidence.

    Malformed frontmatter yields nothing rather than an exception - this
    runs on the hook path, where a crash exits 2 and both hooks swallow it.
    The file-local checks report that file for what is wrong with it.
    """
    out = {}
    tae_abbr = vault.roles().get("TAE") or "TAE"
    for p, text in corpus.items():
        if vault.classify(p) != ("domain", tae_abbr):
            continue
        fm, _, bad = parse_frontmatter(text.splitlines())
        if bad or not fm:
            continue
        ver = fm.get("verifies")
        if not isinstance(ver, list):
            continue
        for rid in ver:
            if isinstance(rid, str) and rid.strip():
                out.setdefault(rid.strip(), []).append(p)
    return out


def allocation_index(vault: Vault):
    """{REQ id: does an allocation row name it} - or None for "cannot say".

    The other half of the coverage rule, and the one this file cannot
    answer alone: an allocation row lives in the section the PROJECT'S OWN
    ARC template declares, and discovering that section is the exporter's
    job. Reusing its graph rather than re-reading the table here is what
    keeps one definition of an allocation instead of a second one that
    drifts (issue #50).

    None is a deliberate third answer, distinct from "no allocation". The
    graph carries a requirement row only when it sits in the bound section
    of a file the graph reads, so a row under a heading of the author's own
    making, or every row of a project whose templates declare no allocation
    table, is invisible HERE and perfectly fine in the vault. Treating that
    as "not allocated" would report a closed loop as a gap - measured on
    the shipped template vault: three such findings on three correct
    requirements. The exporter names those cases itself
    (export-unbound-table, export-no-binding). A vault mid-translation is
    no longer on this list: since issue #66 the requirement index follows
    the same role map the graph is built from, so both tools read one
    requirements folder and the ids agree by construction
    (export-duplicate-role still names the folder that lost).

    Never raises, and never lets the exporter's exit path become this
    process's: SystemExit is not an Exception, and exit 2 releases both
    hooks. Where the graph cannot be built the verification half of the
    rule still runs - the check loses reach, not its voice.
    """
    try:
        # One module, not two. Run as a script this file lives in
        # sys.modules as '__main__', so the exporter's own
        # 'from validate_vault import ...' loads a SECOND copy of it - two
        # Vault classes, two schema caches, and the identity the test suite
        # asserts between the two tools silently false. Registering this
        # module under its import name first is what makes the pair one.
        here = Path(__file__).resolve()
        sys.modules.setdefault(here.stem, sys.modules[__name__])
        if str(here.parent) not in sys.path:
            sys.path.insert(0, str(here.parent))
        import export_traceability

        _roles, bindings, _graph, _back, coverage = export_traceability.analyse(
            vault, vault.schema())
        if not (bindings.get("arc_allocation_table") or {}).get("section"):
            return None     # no template declares one - no row to read
        return {rid: "not-allocated" not in c["gaps"] for rid, c in coverage.items()}
    except (Exception, SystemExit):
        return None


def validate_vault_wide(vault: Vault):
    # First, so it survives hook_stop's 15-line cut of the advisory block:
    # this finding is the explanation for the duplicate-basename and
    # orphan findings a second domain folder produces around it.
    findings = []
    check_domain_folders(vault, findings)
    # sorted: which of two colliding files is reported and which is named as
    # the other one must not depend on filesystem iteration order.
    all_md = sorted(p for p in vault.root.rglob("*.md")
                    if ".obsidian" not in p.parts and ".git" not in p.parts)
    domain_files = [p for p in all_md if vault.classify(p)[0] == "domain"]

    # duplicate requirement ids across files. Folder and id prefix follow
    # the role map - the same choice req_index makes (issue #66).
    req_abbr = vault.roles().get("REQ")
    reqdir = vault.domains.get(req_abbr) if req_abbr else None
    if reqdir:
        ids = {}
        for f in sorted(reqdir.rglob("*.md")):
            if f.name.startswith("00_"):
                continue
            try:
                lines = read_lines(f)
            except OSError:
                continue
            dom = req_scope(f, lines, req_abbr)
            if not dom:
                continue
            for i, row in req_rows(lines):
                if len(row) >= 2 and ROW_NNN_RE.fullmatch(row[1]):
                    rid = f"{req_abbr}-{dom}-{row[1]}"
                    if rid in ids and ids[rid][0] != f:
                        findings.append(Finding("ERROR", "req-duplicate-global", str(f), i,
                                                f"{rid} already defined in "
                                                f"{ids[rid][0].name}:{ids[rid][1]}"))
                    else:
                        ids.setdefault(rid, (f, i))

    corpus = {}
    for p in all_md:
        try:
            corpus[p] = read_text(p)
        except OSError:
            corpus[p] = ""

    check_identifiers(vault, all_md, corpus, findings)

    # REQ coverage. Until issue #50 this was 'rid in text' over whole ARC and
    # TAE files: a requirement counted as covered because its identifier
    # appeared somewhere - in a heading, in a list of open points, in a
    # sentence explaining why it was dropped. The closed loop the method
    # promises is two relations, and both are read as relations now: an
    # allocation row that names the requirement, and a TAE that names it in
    # 'verifies'. A mention proves neither.
    #
    # The two halves come from two places, and only one of them can be
    # unknown: 'verifies' is frontmatter this validator parses itself, an
    # allocation row is a table only the exporter's binding discovery can
    # find. Where the graph cannot see a requirement at all, the allocation
    # half is not held against it (allocation_index, None) - that is the
    # precision-over-recall line this project takes everywhere something
    # cannot tell a mistake from an intention.
    idx = vault.req_index()
    if idx:
        evidence = evidence_index(vault, corpus)
        allocated = allocation_index(vault)
        tail = ("coverage is decided on the allocation table and on "
                "'verifies', never on a mention in prose")
        for rid, (f, i) in idx.items():
            notes = evidence.get(rid)
            alloc = allocated.get(rid) if allocated is not None else None
            if notes and alloc is not False:
                continue
            if notes:
                by = ", ".join(sorted(p.stem for p in notes))
                msg = (f"{rid} is verified by {by} but no allocation row "
                       "allocates it - nothing states which part of the "
                       f"system owes it; {tail}")
            elif alloc is False:
                msg = (f"{rid} has no allocation row naming it and no TAE "
                       "naming it in 'verifies' - an unverified REQ is "
                       f"indistinguishable from an unmet one; {tail}")
            else:
                msg = (f"{rid} is named by no TAE in 'verifies' - an "
                       "unverified REQ is indistinguishable from an unmet "
                       f"one; {tail}")
            findings.append(Finding("WARN", "req-uncovered", str(f), i, msg))

    # system_overview lists every ARC module
    so = vault.root / "system_overview.md"
    so_text = corpus.get(so, "")
    arcdir = vault.domains.get("ARC")
    if arcdir and so.exists():
        for f in arcdir.rglob("*.md"):
            if f.name.startswith("00_"):
                continue
            if f.stem not in so_text:
                findings.append(Finding("WARN", "arc-not-in-overview", str(f), None,
                                        f"ARC module {f.stem} missing from system_overview.md - "
                                        "documentation island"))

    # orphans: domain files nobody links to
    for f in domain_files:
        inbound = any(f"[[{f.stem}" in text for p, text in corpus.items() if p != f)
        if not inbound:
            findings.append(Finding("WARN", "orphan", str(f), None,
                                    "no inbound links - unreachable except by search"))

    # ambiguous wikilink targets
    for name, paths in vault.md_names().items():
        if len(paths) > 1:
            findings.append(Finding("WARN", "duplicate-basename", str(paths[0]), None,
                                    f"'{name}' exists {len(paths)}x under "
                                    f"{vault.index_root_label()} - "
                                    "wikilinks to it are ambiguous"))
    return findings


def run_full(vault: Vault):
    findings = []
    for p in sorted(vault.root.rglob("*.md")):
        if ".obsidian" in p.parts or ".git" in p.parts:
            continue
        findings.extend(validate_file(vault, p, strict_links=True))
    findings.extend(validate_vault_wide(vault))
    return findings


# --------------------------------------------------------------------------
# Hook plumbing
# --------------------------------------------------------------------------

def state_cleanup():
    STATE_DIR.mkdir(mode=0o700, exist_ok=True)
    now = time.time()
    for f in STATE_DIR.iterdir():
        try:
            if now - f.stat().st_mtime > STATE_MAX_AGE_S:
                f.unlink()
        except OSError:
            pass


def state_path(kind, session):
    return STATE_DIR / f"{kind}-{session}"


def load_json(path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return default


def git_head_content(vault: Vault, path: Path):
    """The committed BYTES of a file at HEAD, or None when it has none.

    Bytes, not text: decoded here, a file committed as UTF-16 would carry
    encoding-not-utf8 in the current run and not in its own baseline, and
    the stop gate would block a session on a file nobody touched - the
    failure mode amendment 2026-07-31 named when section-mismatch became
    the first ERROR to enter the blocking set. git show hands out the
    stored blob unfiltered, so what arrives here is what was committed;
    decode_source applies the BOM rule and the newline translation the
    working tree gets, so both sides are still read under one rule.
    """
    repo = vault.git_root() or vault.project_root
    try:
        rel = path.resolve().relative_to(repo)
    except ValueError:
        return None
    try:
        # No encoding= and no text=True: both would decode, and a non-UTF-8
        # byte would raise UnicodeDecodeError inside subprocess.run itself.
        r = subprocess.run(["git", "-C", str(repo), "show", f"HEAD:{rel}"],
                           capture_output=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout if r.returncode == 0 else None


def error_counts(findings):
    return dict(Counter(f.code for f in findings if f.sev == "ERROR"))


REPORT_LINE_CAP = 15


def cap_report_lines(lines, cap=REPORT_LINE_CAP):
    """At most `cap` rendered lines, ERROR-severity ones never dropped.

    Every section of the stop report shares one hard budget: the whole
    report travels as a single `systemMessage`, and Claude Code replaces
    any hook output string above 10000 characters with a file path and a
    2 KB preview (measured on 2.1.220, see the 2026-08-05 amendment).
    Capping each section at its source is what keeps the report under
    that ceiling; truncating the assembled text would cut whatever
    happens to be last, and the last section is the vault-wide one whose
    ERRORs are exempt on purpose.
    """
    errs = [l for l in lines if l.startswith("ERROR")]
    rest = [l for l in lines if not l.startswith("ERROR")]
    shown = errs + rest[:max(0, cap - len(errs))]
    if len(shown) < len(lines):
        shown.append(f"... +{len(lines) - len(shown)} more")
    return shown


def hook_post(payload):
    fp = (payload.get("tool_input") or {}).get("file_path")
    session = payload.get("session_id", "nosession")
    if not fp:
        return 0
    path = Path(fp)
    if path.suffix != ".md" or not path.exists():
        return 0
    root = find_vault_root(path)
    if root is None:
        return 0
    vault = Vault(root)
    if vault.classify(path)[0] in ("outside", "skip"):
        return 0
    state_cleanup()

    touched_f = state_path("touched", session)
    touched = load_json(touched_f, [])
    baseline_f = state_path("baseline", session)
    baseline = load_json(baseline_f, {})
    key = str(path.resolve())
    if key not in touched:
        touched.append(key)
        touched_f.write_text(json.dumps(touched))
        head = git_head_content(vault, path)
        if head is not None:
            base = validate_file(vault, path, content=head, strict_links=True)
            baseline[key] = {"codes": error_counts(base), "new": False}
        else:
            baseline[key] = {"codes": {}, "new": True}
        baseline_f.write_text(json.dumps(baseline))

    findings = validate_file(vault, path, strict_links=False)
    if not findings:
        return 0
    base_codes = baseline.get(key, {}).get("codes", {})
    # Aggregate unresolved-link WARNs into one line: mid-pass forward
    # references are expected under the phased creation order, and dozens
    # of identical per-line WARNs train the reader to ignore the channel.
    link_warns = [f for f in findings
                  if f.code == "link-unresolved" and f.sev == "WARN"]
    lines_out = []
    for f in findings:
        if f in link_warns:
            continue
        tag = ""
        if f.sev == "ERROR" and base_codes.get(f.code, 0) > 0:
            tag = " (pre-existing before this session; non-blocking, fix if cheap)"
        lines_out.append(f.render(rel_to=vault.project_root) + tag)
    if link_warns:
        targets = []
        for f in link_warns:
            m = re.search(r"\[\[([^\]]+)\]\]", f.msg)
            t = m.group(1) if m else "?"
            if t not in targets:
                targets.append(t)
        shown = ", ".join(f"[[{t}]]" for t in targets[:8])
        if len(targets) > 8:
            shown += f", +{len(targets) - 8} more"
        base_n = base_codes.get("link-unresolved", 0)
        note = ((f" ({base_n} unresolved already at HEAD are non-blocking; "
                 "only net-new missing targets block)") if base_n else
                " (net-new missing targets block as ERROR at turn end)")
        try:
            rel = str(path.resolve().relative_to(vault.project_root))
        except ValueError:
            rel = str(path)
        lines_out.append(
            f"WARN {rel} [link-unresolved] {len(targets)} unresolved link "
            f"target(s): {shown} - tolerated mid-pass; every target must "
            "exist by turn end" + note)
    msg = ("vault validator findings for the file just written "
           "(fix ERRORs now while context is fresh; WARNs are advisory):\n"
           + "\n".join(lines_out))
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PostToolUse", "additionalContext": msg}}))
    return 0


def hook_stop(payload):
    session = payload.get("session_id", "nosession")
    state_cleanup()
    touched = load_json(state_path("touched", session), [])
    if not touched:
        return 0
    baseline = load_json(state_path("baseline", session), {})
    reports, new_errors, created, inb_added, resolved = [], [], [], [], []
    roots = []
    for key in touched:
        path = Path(key)
        if not path.exists():
            continue
        root = find_vault_root(path)
        if root is None:
            continue
        if root not in roots:
            roots.append(root)
        vault = Vault(root)
        findings = validate_file(vault, path, strict_links=True)
        info = baseline.get(key, {"codes": {}, "new": True})
        if info.get("new"):
            created.append(key)
            if "(INB)" in key:
                inb_added.append(key)
        base = info.get("codes", {})
        cur = Counter(f.code for f in findings if f.sev == "ERROR")
        seen_over = set()
        for f in findings:
            if f.sev == "ERROR" and cur[f.code] > base.get(f.code, 0):
                new_errors.append(f.render(rel_to=vault.project_root))
                seen_over.add(f.code)
            elif f.sev == "ERROR":
                reports.append(f.render(rel_to=vault.project_root)
                               + " (pre-existing, non-blocking)")
            else:
                reports.append(f.render(rel_to=vault.project_root))

        # Codes this file carried at HEAD that produce no finding at all
        # now. The comparison above iterates the CURRENT findings, so a
        # code that stopped firing is never reached by it: the session
        # ends green and says nothing about a check that may simply have
        # become unreachable. That blind spot is what made issue #20's
        # instance invisible rather than merely wrong (issue #26).
        #
        # Full disappearance only, never a decrease. A count moves at any
        # unrelated edit - a link target created elsewhere in the session
        # lowers link-unresolved in a file nobody touched, which under the
        # phased creation order is the rule and not the exception. "Does
        # this code still fire" is the yes/no the session can answer, the
        # same reason has_domain_files asks one instead of counting.
        gone = sorted(c for c, n in base.items() if n > 0 and cur[c] == 0)
        if gone:
            try:
                rel = str(path.resolve().relative_to(vault.project_root))
            except ValueError:
                rel = str(path)
            resolved.append(f"{rel} [{', '.join(gone)}]")

    summary = []
    if created:
        summary.append("files created this session: "
                       + ", ".join(Path(c).name for c in created))
    if inb_added:
        summary.append("NOTE: new inbox files while documenting - the inbox is not an "
                       "escape hatch for validation: "
                       + ", ".join(Path(c).name for c in inb_added))
    if reports:
        summary.append("advisory findings:\n"
                       + "\n".join(cap_report_lines(sorted(set(reports)))))

    if new_errors:
        blocks_f = state_path("blocks", session)
        blocks = load_json(blocks_f, 0)
        if blocks < MAX_STOP_BLOCKS:
            blocks_f.write_text(json.dumps(blocks + 1))
            # Two channels, two audiences. `reason` reaches Claude - it
            # arrives as a synthetic user message "Stop hook feedback:" -
            # and carries the one obligation the block exists to impose,
            # nothing else. The advisory summary rides `systemMessage`
            # beside it, which reaches the user and not the model: an
            # advisory inside the reason buries the obligation under
            # legacy drift, which is the same ground on which amendment
            # 2026-07-28f kept vault-wide ERRORs out of the block reason.
            #
            # Top-level `decision`/`reason`, NOT hookSpecificOutput. Stop
            # and SubagentStop are the events that read the decision from
            # the top level; the nested form measured as silently ignored
            # on Claude Code 2.1.220 - the turn simply ends and this gate
            # is off. Do not "harmonise" this with hook_post below.
            reason = ("vault validator: ERRORs introduced this session must be fixed "
                      f"before finishing (attempt {blocks + 1}/{MAX_STOP_BLOCKS}):\n"
                      + "\n".join(sorted(set(new_errors))))
            note = ("vault validator blocked the turn end (attempt "
                    f"{blocks + 1}/{MAX_STOP_BLOCKS}): ERRORs introduced this session")
            print(json.dumps({
                "decision": "block", "reason": reason,
                "systemMessage": note + ("\n" + "\n".join(summary) if summary else "")}))
            return 0
        summary.insert(0, "UNRESOLVED vault ERRORs (gate released after "
                       f"{MAX_STOP_BLOCKS} attempts - surface these to the user):\n"
                       + "\n".join(sorted(set(new_errors))))

    # Reported, never blocking. A repaired defect and a check that stopped
    # reaching the file produce the same absence, and where this layer
    # cannot tell a mistake from an intention it says so rather than
    # stopping the session - the rule the vault-wide advisory below
    # follows for the same reason. Emitted after the blocking branch on
    # purpose: a block reason carries one obligation, and a second,
    # non-blocking observation inside it spends a block attempt on legacy
    # drift. Neither line starts with ERROR or WARN, so a rendered finding
    # stays distinguishable from a code being reported as gone.
    if resolved:
        shown = cap_report_lines(sorted(set(resolved)))
        summary.append("codes that stood at HEAD and did not fire this session "
                       "(say which of them you fixed; a check that became "
                       "unreachable looks exactly the same):\n" + "\n".join(shown))

    # Vault-wide checks (req-uncovered, orphan, ...) run advisory-only:
    # they have no per-file HEAD baseline, so they never enter new_errors
    # and never block - the ratchet stays strictly per-file. This point is
    # reached only when the gate is not blocking, so the advisory can
    # never end up in a block reason; the try/except keeps an advisory
    # bug from ever crashing the gate (exit 2 would release it).
    wide = []
    try:
        for root in roots:
            v = Vault(root)
            wide.extend(f.render(rel_to=v.project_root)
                        for f in validate_vault_wide(v))
    except Exception:
        wide = []
    if wide:
        # ERROR-severity vault-wide findings must survive the cap: this
        # report is their only automatic channel, because hook_post never
        # shows vault-wide findings at all.
        summary.append("vault-wide findings (advisory - not blocking, may "
                       "include legacy state):\n"
                       + "\n".join(cap_report_lines(wide)))

    if summary:
        # `systemMessage`, not a bare print. Plain stdout of a Stop hook
        # that exits 0 goes to the debug log and is shown to nobody -
        # measured on Claude Code 2.1.220 against a live session, in
        # settings scope and in skill-frontmatter scope, which is how
        # this hook is registered (issue #44; amendment 2026-07-28f
        # recorded the opposite and was wrong). systemMessage renders in
        # the transcript as "Stop says: ...", multi-line intact.
        #
        # Not additionalContext: that reaches the model but continues the
        # turn, spending a model turn on legacy drift nobody asked about.
        # The fail-open ERROR report below rides this channel too, and
        # deliberately does not reach the model: the gate has already
        # demanded those fixes twice: whether to spend a third attempt on
        # them is the user's call, not the session's.
        #
        # ensure_ascii stays at its default. A path that arrived through
        # surrogateescape carries lone surrogates, which print() cannot
        # encode - it raises and exits 2, and exit 2 releases the gate.
        print(json.dumps({"systemMessage": "vault validator session report:\n"
                          + "\n".join(summary)}))
    return 0


# --------------------------------------------------------------------------
# Installation check
# --------------------------------------------------------------------------

SKILL_NAME = "mechatronics-docs"

# Identifies this copy of the skill in one line, so "which copy just
# enforced?" can be answered without diffing two directory trees. A tree
# comparison cannot answer it: a derived project legitimately ships fewer
# files than the template (tools/new_project.py strips tests/), so content
# equality is the wrong question. Bump on every release that changes what
# the validator or the hooks do; the release checklist in CONTRIBUTING.md
# owns the bump.
SKILL_REVISION = "2026-08-10.1"


def check_install():
    """Report whether the personal skill entry reaches this copy of the skill.

    A `~/.claude/skills/<name>` entry may be a symlink, and a symlink stores
    a path string rather than an identity. Replicate that entry across
    machines - a synced dotfile directory does exactly that - and the stored
    path stays valid only on the host that wrote it. Nothing announces the
    break: the entry keeps appearing in the skill listing and only the
    invocation fails, which is what let issue #40 run unnoticed for a week.

    Readability alone is not the check. An entry that resolves to a second
    clone of the template, or to a synced copy of the skill directory, is
    just as wrong and just as quiet - it serves a version nobody is editing.
    So the resolved target is compared against this file's own directory.
    """
    own = Path(__file__).resolve().parent
    entry = Path.home() / ".claude" / "skills" / SKILL_NAME
    print(f"this copy:      {own} (rev {SKILL_REVISION})")
    print(f"personal entry: {entry}")

    # is_symlink() before exists(): exists() follows the link and is False
    # for a dangling one, which is the very state this check exists for.
    if not entry.is_symlink() and not entry.exists():
        print("  absent - the skill is reachable only in projects that carry "
              "it themselves, which is a legitimate setup. Expected a global "
              "entry? Recreate the link; a Claude Code update can remove it.")
        return 0

    if entry.is_symlink():
        print(f"  link target:    {os.readlink(entry)}")
        if not entry.exists():
            print("  DANGLING - that path does not exist on this host. A "
                  "symlink carries a path, not an identity, so a replicated "
                  "one is only valid where it was created. Point it at the "
                  "path this host uses, and keep the entry out of the sync.")
            return 1

    try:
        resolved = entry.resolve()
    except OSError as e:
        print(f"  UNREADABLE - {e}")
        return 1

    if resolved != own:
        kind = ("link" if entry.is_symlink()
                else "directory" if entry.is_dir() else "path")
        print(f"  MISMATCH - that {kind} reaches {resolved}, which is not this "
              "copy of the skill. Two copies drift against each other; make "
              "the entry reach this one.")
        return 1

    if not os.access(entry / "SKILL.md", os.R_OK):
        print("  UNREADABLE - the entry is correct but SKILL.md cannot be "
              "read; check permissions.")
        return 1

    print("  OK - the entry reaches this copy")
    return 0


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def main(argv):
    import argparse
    ap = argparse.ArgumentParser(description="SSOT vault validator")
    ap.add_argument("vault_root", nargs="?", help="path to the project vault root")
    ap.add_argument("--file", help="validate a single file (file-local checks only)")
    ap.add_argument("--hook", choices=["post", "stop"], help="run as Claude Code hook")
    ap.add_argument("--check-install", action="store_true",
                    help="report whether the personal skill entry reaches this copy")
    args = ap.parse_args(argv)

    if args.hook:
        payload = json.load(sys.stdin)
        return hook_post(payload) if args.hook == "post" else hook_stop(payload)

    if args.check_install:
        return check_install()

    if args.file:
        path = Path(args.file).resolve()
        root = Path(args.vault_root).resolve() if args.vault_root else find_vault_root(path)
        if root is None or not is_vault_root(root):
            print(f"ERROR - no vault root found for {path}", file=sys.stderr)
            return 2
        findings = validate_file(Vault(root), path, strict_links=False)
    else:
        if not args.vault_root:
            ap.error("vault_root or --file required")
        root = Path(args.vault_root).resolve()
        if not is_vault_root(root):
            names = "/".join(f"00_*{m}*" for m in TEMPLATE_MARKERS)
            print(f"ERROR - {root} is not a vault root (needs >=3 NN_name_(ABBR) "
                  f"domain folders containing {names} files)", file=sys.stderr)
            return 2
        findings = run_full(Vault(root))

    errors = [f for f in findings if f.sev == "ERROR"]
    warns = [f for f in findings if f.sev == "WARN"]
    # Counted separately, not subtracted: a near miss is still an ERROR or a
    # WARN in its own right. The number answers "how much of this is drift
    # against my own templates rather than unwritten sections?"
    near = [f for f in findings if f.code in NEAR_MISS_CODES]
    for f in findings:
        print(f.render())
    print(f"-- {len(errors)} error(s), {len(warns)} warning(s), "
          f"{len(near)} near miss(es)")
    return 1 if errors else 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except SystemExit:
        raise
    except Exception as e:  # crash -> exit 2, hooks fail open
        print(f"validator crash: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(2)
