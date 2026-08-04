#!/usr/bin/env python3
"""Traceability exporter for SSOT mechatronics vaults.

Reads a vault into a graph and writes it back out as three artifacts a
reviewer, an examiner or an auditor can be handed without being taught
the method first: a JSON graph, two CSV views and a self-contained HTML
report (DECISIONS.md, amendment 2026-07-31b; issue #2).

    export_traceability.py <vault_root> --output-dir DIR [--formats ...]

Three properties are load-bearing and every design choice below serves
one of them.

Nothing is authored twice. Every reverse edge is computed from the
forward edges in one pass, so no file ever stores a back-link and
nothing can drift - the pattern StrictDoc, Doorstop and Sphinx-Needs all
use. Derived fields are marked as derived in the JSON, following
Sphinx-Needs' field_type, so a consumer can tell what was written down
from what was worked out.

Nothing the export can prove it lost is lost silently. A vault in another
language, a second folder meaning a domain already taken, an architecture
table in no recognised section, a requirement row the graph does not
contain, a requirement reference that resolves to nothing, a status
nobody declared: each is a row in the export, never an absence from it. The domains this project declares no table binding for
are the one documented exception, and vault_schema.json says why
(table_bindings.binding_discovery.unbound_table). An empty graph without
an explanation is the one output this tool must not produce.

Nothing is guessed. A range is expanded only when every identifier it
yields exists; a status counts as proven only on an exact match. Where
the vault is ambiguous the export says so and carries the author's own
words forward.

Exit codes: 0 = artifacts written, 2 = not a vault, or output refused.
Coverage gaps are data and never change the exit code - this tool
reports, it does not block.
"""

import argparse
import csv
import hashlib
import html
import json
import os
import re
import sys
import unicodedata
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from validate_vault import (  # noqa: E402
    Vault, _dict, _strlist, fold_key, is_separator,
    is_vault_root, load_schema, parse_frontmatter, req_tables, split_cells,
    template_files,
)

EXPORT_SCHEMA_VERSION = "1.0"
ID_EXCLUDED_DOMAINS = ("ADM", "INB")
ROW_NNN_RE = re.compile(r"^\d{3}$")
FULL_ID_RE = re.compile(r"\b([A-Z]{2,4})-([A-Z]{2,4})-(\d{3})\b")
# A continuation inherits the prefix and scope of the last full identifier in
# the same cell: "ANF-BAK-008, 027, 028" and "ANF-CPL-001, -003" are both
# real homelab spellings and both mean three requirements, not one.
CONTINUATION_RE = re.compile(r"(?<![\w-])-?(\d{3})(?![\w-])")
RANGE_SEPARATORS = ("bis", "to", "–", "—")
# Fences: CommonMark 0.31.2 - at least three backticks or tildes, closed only
# by the same character and at least the same length. Tracking neither is how
# check_req_table reads example tables out of documentation blocks and reports
# them as defects; the exporter would ingest them as relations.
FENCE_RE = re.compile(r"^( {0,3})(`{3,}|~{3,})(.*)$")
WIKILINK_RE = re.compile(r"!?\[\[([^\]\n]+)\]\]")
SLUG_STRIP_RE = re.compile(r"[^a-z0-9]+")
# URL schemes that may appear in an href. Everything else is rendered as
# text: html.escape does not touch "javascript:", and a data: URL is a
# document of its own (OWASP XSS Prevention, rule 5).
SAFE_SCHEMES = ("http", "https", "mailto")
CONTROL_RE = re.compile(r"[\x00-\x20\x7f]+")

# Weakest-first. A requirement allocated in several rows takes the weakest
# state any of them is in: one row reaching Verified must never hide another
# that is still open. homelab has ANF-BAK-032 in three rows for this reason.
STATUS_RANK = {"unknown": 0, "qualified": 1, "declared": 2}


# --------------------------------------------------------------------------
# Reading and parsing
# --------------------------------------------------------------------------

def read_lines(path):
    """Lines of a file, BOM-safe and without splitlines' extra breaks.

    utf-8-sig because a BOM makes the first line compare unequal to '---'
    and the frontmatter of the whole file disappears without a message.
    split('\\n') rather than splitlines() because splitlines also breaks on
    \\v, \\f and U+2028, any of which inside a table cell would silently
    split one row into two.
    """
    try:
        text = path.read_text(encoding="utf-8-sig", errors="replace")
    except OSError:
        return []
    return text.split("\n")


def fenced_mask(lines):
    """True for every line inside (or opening/closing) a fenced code block.

    A fence closes only on the same character and at least the same length,
    so a ``` inside a ~~~ block does not end it, and an indented four-space
    line is not a fence at all.
    """
    mask = [False] * len(lines)
    open_char, open_len = None, 0
    for i, line in enumerate(lines):
        m = FENCE_RE.match(line)
        if m and open_char is None:
            open_char, open_len = m.group(2)[0], len(m.group(2))
            mask[i] = True
        elif m and m.group(2)[0] == open_char and len(m.group(2)) >= open_len \
                and not m.group(3).strip():
            open_char, open_len = None, 0
            mask[i] = True
        elif open_char is not None:
            mask[i] = True
    return mask


def unescape(cell):
    """Resolve the backslash escapes the table syntax and the templates use."""
    return re.sub(r"\\([|\\\[\]])", r"\1", cell)


def links_in(cell):
    """Wikilink targets of one cell, in order, without aliases or anchors."""
    out = []
    for m in WIKILINK_RE.finditer(unescape(cell)):
        target = m.group(1).split("|")[0].split("#")[0].strip()
        if target and target not in out:
            out.append(target)
    return out


def nfc(s):
    return unicodedata.normalize("NFC", s)


def slug(text, taken):
    """A stable, collision-free HTML anchor for an arbitrary vault name."""
    base = SLUG_STRIP_RE.sub("-", nfc(text).lower()).strip("-") or "item"
    candidate, n = base, 2
    while candidate in taken:
        candidate, n = f"{base}-{n}", n + 1
    taken.add(candidate)
    return candidate


# --------------------------------------------------------------------------
# Roles, sections and table bindings
# --------------------------------------------------------------------------

class Finding:
    __slots__ = ("code", "path", "line", "msg")

    def __init__(self, code, path, line, msg):
        self.code, self.path, self.line, self.msg = code, path, line, msg

    def as_dict(self, root):
        return {"code": self.code, "file": rel(self.path, root),
                "line": self.line, "message": self.msg}


def rel(path, root):
    if path is None:
        return None
    try:
        return str(Path(path).relative_to(root))
    except ValueError:
        return str(path)


def domain_dirs(vault):
    """-> {abbreviation: [directory, ...]}, sorted, duplicates included.

    The Vault's own index since amendment 2026-08-04g, where it keeps
    every folder of an abbreviation and picks the vault's by rule. Until
    then it kept one directory per abbreviation in readdir order, and
    reading the root a second time here was the only way to see the
    second folder of a vault mid-translation at all - which also meant
    the two tools could disagree about what the vault contains between
    the two reads. One index, read twice, cannot.

    The dict is the Vault's, not a copy: nothing here writes to it.
    """
    return vault.domain_dirs


def ingestible_count(ddir, abbr):
    """How many files of this folder build_graph would put in the graph.

    Its predicate, not a file count: a name starting with the folder's own
    abbreviation, which no '00_' template does. None when the folder
    cannot be read - a finding without a number beats a crash that looks
    like an export.
    """
    try:
        return sum(1 for f in ddir.rglob("*.md") if f.name.startswith(f"{abbr}_"))
    except OSError:
        return None


def _files(n):
    if n is None:
        return "an unreadable number of files"
    return "1 file" if n == 1 else f"{n} files"


def duplicate_role_finding(role, kept_abbr, kept_dir, dropped_abbr, dropped_dir):
    """The finding for a second folder that means a role already taken.

    One code for both spellings of the same defect, because a consumer
    reads one situation: a vault carrying two folders for one domain. They
    differ in what the reader can do about it, so only the closing clause
    does. Two abbreviations - '01_requirements_(REQ)' beside
    '01_Anforderungen_(ANF)' - move every identifier of the graph to the
    kept prefix. One abbreviation twice leaves the identifiers alone, and
    which of the two folders the graph reads is Vault's rule since
    amendment 2026-08-04g - it was the order readdir returned them in
    until then, and the tail below said so.
    """
    if dropped_abbr == kept_abbr:
        tail = ("which of the two the graph reads follows a rule rather than the "
                "file system: the first in sorted order among the folders holding "
                f"{kept_abbr}_* files, which validate_vault reports as "
                "domain-duplicate-folder")
    else:
        tail = (f"an identifier spelled {dropped_abbr}-* therefore resolves to "
                f"nothing, because the graph is written with {kept_abbr}-*")
    return Finding(
        "export-duplicate-role", dropped_dir, None,
        f"'{dropped_dir.name}' ({_files(ingestible_count(dropped_dir, dropped_abbr))}) "
        f"and '{kept_dir.name}' ({_files(ingestible_count(kept_dir, kept_abbr))}) are "
        f"both the {role} domain of this vault - only '{kept_dir.name}' is in the "
        f"graph; {tail}. One role, one folder: finish the translation, or remove "
        "the folder this vault no longer writes to")


def resolve_roles(vault, schema, findings):
    """-> {canonical role token: folder abbreviation present in this vault}.

    The alias map is the reason a German vault yields a graph at all. An
    abbreviation the map does not know is reported and excluded rather than
    guessed at, and so is a folder whose role another folder already holds.

    The kept one is the first in sorted order - among two abbreviations
    here, and among the folders of one abbreviation in pick_domain_dir,
    where the folders holding files of the domain come first. It is a
    rule and not a judgement: the alternatives - the fuller folder, or
    both - each decide something only the author knows. Counting files
    moves every identifier
    of the export a second time, at whatever unrelated edit tips the count;
    ingesting both writes every already-translated requirement into the
    graph twice and reports its untranslated twin as unallocated. What the
    export owes the reader is that the choice is visible, which is the
    finding below.
    """
    aliases = _dict(schema, "domain_aliases")
    amap = _dict(aliases, "map")
    identity = _strlist(aliases, "identity") or [
        "REQ", "DEC", "ARC", "CMP", "IFC", "IMP", "TAE", "OAU", "REF"]
    roles = {}
    for abbr, dirs in sorted(domain_dirs(vault).items()):
        if abbr in ID_EXCLUDED_DOMAINS:
            continue
        role = abbr if abbr in identity else amap.get(abbr)
        if role is None:
            findings.append(Finding(
                "export-unknown-domain", dirs[0], None,
                f"domain folder '{abbr}' is neither an English domain token nor "
                "listed in domain_aliases - its files are not part of the graph; "
                "add the alias to vault_schema.json"))
            continue
        if role in roles:
            kept = roles[role]
            for d in dirs:
                findings.append(duplicate_role_finding(
                    role, kept, vault.domains[kept], abbr, d))
            continue
        roles[role] = abbr
        # The one Vault indexed is the one build_graph reads; its namesakes
        # are excluded by that indexing, which is pick_domain_dir's rule and
        # no longer readdir's (amendment 2026-08-04g).
        used = vault.domains.get(abbr, dirs[0])
        for d in dirs:
            if d != used:
                findings.append(duplicate_role_finding(
                    role, abbr, used, abbr, d))
    return roles


def sections_with_tables(lines):
    """-> [(section_title, header_cells, header_line)] for one file.

    Fence state is tracked first, so a table quoted inside a documentation
    block belongs to no section and is never seen.
    """
    mask = fenced_mask(lines)
    out, current = [], ""
    for i, line in enumerate(lines):
        if mask[i]:
            continue
        if line.startswith("## "):
            current = line[3:].strip()
            continue
        cells = split_cells(line)
        if cells is None or is_separator(cells) or len(cells) < 2:
            continue
        if out and out[-1][0] == current and out[-1][2] < i:
            continue  # only the first table of a section binds
        out.append((current, cells, i + 1))
    return out


def discover_bindings(vault, schema, findings):
    """Which section of this project's own templates carries which table.

    The header row is read once, here, to tell the two four-column ARC
    tables apart; it never decides whether a real file's table is ingested.
    That is what the section title does, and check_sections keeps it honest.
    """
    tb = _dict(schema, "table_bindings")
    status_token = tb.get("status_token") if isinstance(tb.get("status_token"), str) else "status"
    bindings = {}
    for name in ("arc_allocation_table", "arc_interface_table",
                 "arc_main_module_table", "req_table"):
        spec = _dict(tb, name)
        role = spec.get("domain")
        abbr = None
        if isinstance(role, str):
            abbr = role if role in vault.domains else None
        bindings[name] = {"spec": spec, "abbr": abbr, "section": None,
                          "header": _strlist(spec, "header_signature")}

    for name, b in bindings.items():
        role = b["spec"].get("domain")
        if not isinstance(role, str):
            continue
        b["role"] = role

    for role_token in ("ARC", "REQ"):
        abbr = ROLE_CACHE.get(role_token)
        if not abbr:
            continue
        candidates = []
        for tf in template_files(vault.domains[abbr]):
            for title, header, line in sections_with_tables(read_lines(tf)):
                candidates.append((tf.name, title, header, line))
        for tname, title, header, line in candidates:
            n = len(header)
            last = fold_key(header[-1]) if header else ""
            if role_token == "ARC" and n == 4 and last == status_token:
                target = "arc_allocation_table"
            elif role_token == "ARC" and n == 4:
                target = "arc_interface_table"
            elif role_token == "ARC" and n == 2:
                target = "arc_main_module_table"
            elif role_token == "REQ" and n == 5:
                target = "req_table"
            else:
                continue
            if bindings[target]["section"] is None:
                bindings[target]["section"] = title
                bindings[target]["template"] = tname
                bindings[target]["template_header"] = header

    for name, b in bindings.items():
        if b.get("role") in ROLE_CACHE and b["section"] is None:
            findings.append(Finding(
                "export-no-binding", None, None,
                f"no section of this project's own templates carries the "
                f"{name.replace('_', ' ')} - nothing of that kind is exported; "
                "the template must declare the table the files are expected to "
                "carry"))
    return bindings


ROLE_CACHE = {}


def bound_tables(lines, section_title, ncols):
    """Rows of the table under this section whose header has ncols columns.

    Matching folds case and invisible differences, the same rule
    check_sections uses to decide a section is present, so a file whose
    heading differs only in case still contributes its rows.

    The column count is part of the match, not a formality. PMDE's
    main-module template heads its two-column submodule table with the same
    title its file template gives the four-column allocation table, so two
    bindings resolve to one section name; reading the first table in the
    section would then feed a submodule row to the allocation parser and
    invent an allocation with no requirement.
    """
    if not section_title:
        return []
    want = fold_key(section_title)
    mask = fenced_mask(lines)
    rows, current, taking = [], "", False
    for i, line in enumerate(lines):
        if mask[i]:
            continue
        if line.startswith("## "):
            if rows:
                break
            current = fold_key(line[3:].strip())
            taking = False
            continue
        if current != want:
            continue
        cells = split_cells(line)
        if cells is None:
            if taking:
                break  # a blank line or prose ends the table
            continue
        if is_separator(cells):
            continue
        if not taking:
            if ncols and len(cells) != ncols:
                continue  # a table of another shape in the same section
            taking = True
            rows.append(("header", cells, i + 1))
            continue
        # Body rows are read to the header's width: GFM inserts empty cells
        # for a short row and drops the excess of a long one (example 204).
        # The header above is matched unpadded on purpose - its raw column
        # count is what tells two same-titled tables apart.
        rows.append(("row", split_cells(line, ncols), i + 1))
    return rows


# --------------------------------------------------------------------------
# Requirement identifiers
# --------------------------------------------------------------------------

def req_scope_of(path, lines, req_abbr):
    """Scope token of a requirements file: its own id first, its name second."""
    fm, _, bad = parse_frontmatter(lines)
    if not bad and fm:
        v = fm.get("id")
        if isinstance(v, str):
            m = re.match(rf"^{re.escape(req_abbr)}-([A-Z]{{2,4}})-\d{{3}}$", v.strip())
            if m:
                return m.group(1)
    m = re.search(r"\(([A-Z]{2,4})\)", path.stem)
    return m.group(1) if m else None


def expand_requirement_cell(cell, index, req_abbr):
    """-> (resolved ids, unresolved fragments).

    Handles the three spellings the corpus actually contains: full
    identifiers, a range ('ANF-NAV-001 bis ANF-NAV-009'), and a
    continuation that inherits prefix and scope ('ANF-BAK-008, 027, 028',
    'ANF-CPL-001, -003'). Expansion is offered, never asserted: an
    identifier that does not exist in the vault is returned as unresolved
    instead of being invented.
    """
    text = unescape(cell)
    if not FULL_ID_RE.search(text):
        return [], []
    resolved, unresolved = [], []
    full = list(FULL_ID_RE.finditer(text))

    for sep in RANGE_SEPARATORS:
        pattern = re.compile(
            rf"([A-Z]{{2,4}})-([A-Z]{{2,4}})-(\d{{3}})\s*{re.escape(sep)}\s*"
            rf"([A-Z]{{2,4}})-([A-Z]{{2,4}})-(\d{{3}})")
        m = pattern.search(text)
        if not m or m.group(1) != m.group(4) or m.group(2) != m.group(5):
            continue
        lo, hi = int(m.group(3)), int(m.group(6))
        if lo > hi:
            continue
        span = [f"{m.group(1)}-{m.group(2)}-{n:03d}" for n in range(lo, hi + 1)]
        missing = [r for r in span if r not in index]
        if missing:
            unresolved.append(f"{m.group(0)} ({len(missing)} of {len(span)} "
                              "identifiers in the range do not exist)")
        else:
            resolved.extend(span)
        return sorted(set(resolved)), unresolved

    last_prefix, last_scope = None, None
    consumed = set()
    for m in full:
        rid = f"{m.group(1)}-{m.group(2)}-{m.group(3)}"
        last_prefix, last_scope = m.group(1), m.group(2)
        consumed.update(range(m.start(), m.end()))
        (resolved if rid in index else unresolved).append(rid)
    for m in CONTINUATION_RE.finditer(text):
        if m.start() in consumed or last_prefix is None:
            continue
        rid = f"{last_prefix}-{last_scope}-{m.group(1)}"
        (resolved if rid in index else unresolved).append(rid)
    return sorted(set(resolved)), sorted(set(unresolved))


# --------------------------------------------------------------------------
# Graph construction
# --------------------------------------------------------------------------

class Graph:
    def __init__(self):
        self.nodes = {}
        self.requirements = {}
        self.edges = []
        self.findings = []

    def add_edge(self, kind, src, dst, path, line, qualifier=None):
        self.edges.append({"kind": kind, "source": src, "target": dst,
                           "qualifier": qualifier, "file": path, "line": line})


def object_key(vault, path, lines, role):
    """Identity of a file object, and where that identity came from.

    Three sources, not two: a conforming frontmatter id, else the file's
    own name. No production vault carries a single id today, so the second
    is the normal case and the JSON says which one was used.
    """
    fm, _, bad = parse_frontmatter(lines)
    if not bad and fm:
        v = fm.get("id")
        if isinstance(v, str) and re.fullmatch(
                r"[A-Z]{2,4}-[A-Z]{2,4}-\d{3}", v.strip()):
            return v.strip(), "frontmatter"
    return f"{role}:{path.stem}", "filename"


def build_graph(vault, schema, roles, bindings):
    g = Graph()
    root = vault.root
    tb = _dict(schema, "table_bindings")
    alloc_spec = _dict(tb, "arc_allocation_table")
    declared_status = _strlist(alloc_spec, "qualifier_values")
    proven_value = alloc_spec.get("qualifier_proven_value")
    if not isinstance(proven_value, str):
        proven_value = "Verified"

    by_name = {}
    files_by_role = {}
    for abbr, ddir in sorted(vault.domains.items()):
        if abbr in ID_EXCLUDED_DOMAINS:
            continue
        role = next((r for r, a in roles.items() if a == abbr), None)
        if role is None:
            continue
        for f in sorted(ddir.rglob("*.md")):
            if f.name.startswith("00_"):
                continue
            if not f.name.startswith(f"{abbr}_"):
                g.findings.append(Finding(
                    "export-domain-mismatch", f, None,
                    f"file sits in the {abbr} folder but is not named {abbr}_* - "
                    "excluded from the graph (validate_vault reports the same "
                    "file as filename-prefix)"))
                continue
            lines = read_lines(f)
            key, source = object_key(vault, f, lines, role)
            fm, _, bad = parse_frontmatter(lines)
            fm = {} if bad or not fm else fm
            if key in g.nodes:
                g.findings.append(Finding(
                    "export-duplicate-key", f, None,
                    f"identity '{key}' is already used by "
                    f"{g.nodes[key]['file']} - the later file is excluded"))
                continue
            g.nodes[key] = {
                "key": key, "role": role, "domain": abbr, "name": f.stem,
                "file": rel(f, root), "id_source": source,
                "status": fm.get("status") if isinstance(fm.get("status"), str) else None,
                "last_verified": fm.get("last-verified")
                if isinstance(fm.get("last-verified"), str) else None,
            }
            by_name.setdefault(f.stem, []).append(key)
            files_by_role.setdefault(role, []).append((f, lines, key))

    for name, keys in sorted(by_name.items()):
        if len(keys) > 1:
            g.findings.append(Finding(
                "export-ambiguous-name", None, None,
                f"'{name}' names {len(keys)} objects - a wikilink to it is "
                "ambiguous and resolves to the first in sorted order"))

    def resolve(target):
        keys = by_name.get(target)
        return sorted(keys)[0] if keys else None

    # ---- requirement rows -------------------------------------------------
    req_abbr = roles.get("REQ")
    req_binding = bindings.get("req_table", {})
    if req_abbr:
        for f, lines, _key in files_by_role.get("REQ", []):
            scope = req_scope_of(f, lines, req_abbr)
            rows = bound_tables(lines, req_binding.get("section"), 5)
            # Before the scope check, not after: every REQ file of the
            # nativclaw vault returns there, so an unexported row in the one
            # corpus that has them would go unmentioned either way.
            _report_unexported_rows(g, f, lines, {ln for _k, _c, ln in rows})
            if not scope:
                g.findings.append(Finding(
                    "export-no-scope", f, None,
                    "requirements file carries neither a conforming id nor a "
                    "(SCOPE) token in its name - its rows cannot be addressed"))
                continue
            for kind, cells, line in rows:
                if kind != "row" or len(cells) < 5:
                    continue
                cls, nnn, content, criterion, source = cells[:5]
                if not ROW_NNN_RE.match(nnn):
                    continue
                rid = f"{req_abbr}-{scope}-{nnn}"
                if rid in g.requirements:
                    g.findings.append(Finding(
                        "export-duplicate-requirement", f, line,
                        f"{rid} is already defined in "
                        f"{g.requirements[rid]['file']}"))
                    continue
                g.requirements[rid] = {
                    "id": rid, "class": cls, "text": unescape(content),
                    "acceptance_criterion": unescape(criterion),
                    "file": rel(f, root), "line": line,
                }
                for target in links_in(source):
                    dst = resolve(target)
                    if dst:
                        g.add_edge("justified-by", rid, dst, rel(f, root), line)
                    else:
                        g.findings.append(Finding(
                            "export-unresolved-link", f, line,
                            f"[[{target}]] in the justification of {rid} "
                            "resolves to no file"))

    # ---- architecture tables ---------------------------------------------
    arc_abbr = roles.get("ARC")
    alloc_section = bindings.get("arc_allocation_table", {}).get("section")
    iface_section = bindings.get("arc_interface_table", {}).get("section")
    sub_section = bindings.get("arc_main_module_table", {}).get("section")
    template_header = bindings.get("arc_allocation_table", {}).get("template_header")

    if arc_abbr:
        for f, lines, key in files_by_role.get("ARC", []):
            bound_lines = set()
            for section, ncols, handler in (
                    (alloc_section, 4, "alloc"),
                    (iface_section, 4, "iface"),
                    (sub_section, 2, "sub")):
                for kind, cells, line in bound_tables(lines, section, ncols):
                    bound_lines.add(line)
                    if kind == "header":
                        if handler == "alloc" and template_header and \
                                [fold_key(c) for c in cells] != \
                                [fold_key(c) for c in template_header]:
                            g.findings.append(Finding(
                                "export-header-drift", f, line,
                                "allocation table header differs from the "
                                f"template's ({' | '.join(cells)}) - rows are "
                                "still exported; tidy the header when convenient"))
                        continue
                    if handler == "alloc":
                        _alloc_row(g, f, root, key, cells, line, req_abbr,
                                   declared_status, proven_value, resolve)
                    elif handler == "iface":
                        subj = links_in(cells[0])
                        subj_key = resolve(subj[0]) if subj else None
                        for col in (1, 2):
                            for target in links_in(cells[col]):
                                dst = resolve(target)
                                if subj_key and dst:
                                    g.add_edge("connects", subj_key, dst,
                                               rel(f, root), line)
                    else:
                        for target in links_in(cells[0]):
                            dst = resolve(target)
                            if dst:
                                g.add_edge("contains", key, dst, rel(f, root), line)
            _report_unbound(g, f, lines, bound_lines)

    # ---- evidence frontmatter --------------------------------------------
    tae_abbr = roles.get("TAE")
    if tae_abbr:
        for f, lines, key in files_by_role.get("TAE", []):
            fm, _, bad = parse_frontmatter(lines)
            if bad or not fm:
                continue
            ver = fm.get("verifies")
            if not isinstance(ver, list):
                continue
            for rid in ver:
                if not isinstance(rid, str) or not rid.strip():
                    continue
                rid = rid.strip()
                if rid in g.requirements:
                    g.add_edge("verifies", key, rid, rel(f, root), 1)
                else:
                    g.findings.append(Finding(
                        "export-unknown-requirement", f, 1,
                        f"'verifies' names {rid}, which is defined in no "
                        "requirements file"))
    return g, proven_value


def _alloc_row(g, f, root, arc_key, cells, line, req_abbr, declared, proven, resolve):
    subject_cell, req_cell, ev_cell, status_cell = cells[:4]
    subject_links = links_in(subject_cell)
    subject_key = resolve(subject_links[0]) if subject_links else None
    subject_text = unescape(subject_cell)

    status_value = unescape(status_cell).strip()
    kind, reason = _classify_status(status_value, declared)

    resolved, unresolved = ([], [])
    if req_abbr:
        resolved, unresolved = expand_requirement_cell(
            req_cell, g.requirements, req_abbr)
    for frag in unresolved:
        g.findings.append(Finding(
            "export-unresolved-requirement", f, line,
            f"'{frag}' in an allocation row names no requirement that exists"))
    if not resolved and not unresolved:
        g.findings.append(Finding(
            "export-allocation-without-requirement", f, line,
            f"allocation row '{subject_text[:60]}' names no requirement - "
            "exported as an allocation without coverage meaning"))

    evidence_keys, evidence_missing = [], []
    for target in links_in(ev_cell):
        dst = resolve(target)
        (evidence_keys if dst else evidence_missing).append(dst or target)
    for target in evidence_missing:
        g.findings.append(Finding(
            "export-unresolved-link", f, line,
            f"[[{target}]] in a verification column resolves to no file"))

    owner = subject_key or arc_key
    for rid in resolved:
        g.add_edge("allocates", owner, rid, rel(f, root), line, qualifier=status_value)
        g.requirements[rid].setdefault("allocations", []).append({
            "owner": owner, "owner_text": subject_text,
            "status": status_value, "status_kind": kind, "status_reason": reason,
            "proven": kind == "declared" and status_value == proven,
            "evidence": sorted(evidence_keys),
            "evidence_is_prose": not evidence_keys and bool(unescape(ev_cell).strip()),
            "evidence_text": unescape(ev_cell),
            "file": rel(f, root), "line": line,
        })
    for ev in evidence_keys:
        g.add_edge("evidence", owner, ev, rel(f, root), line, qualifier=status_value)


def _classify_status(value, declared):
    """-> ('declared'|'qualified'|'unknown', reason).

    Exact match is the only thing that counts. A cell that starts with a
    declared value and carries more - 'Verified (Rebuild: Draft)' - is
    qualified, is not proven, and keeps its own words as the reason.
    """
    if value in declared:
        return "declared", None
    for d in declared:
        if value.startswith(d) and (len(value) == len(d) or not value[len(d)].isalnum()):
            return "qualified", value
    return "unknown", value or "(empty)"


def _report_unexported_rows(g, f, lines, bound_lines):
    """Requirement rows of a REQ file that the graph does not contain.

    The ARC counterpart below asks whether a table sits in a bound section.
    That question is the wrong one here, and measurably so: of the 112
    requirement rows this exporter drops across the nine vault roots
    measured, 78 sit INSIDE the bound section, in its second to tenth
    table, which bound_tables stops before and sections_with_tables cannot
    see. A section title cannot report them; a row can report itself.

    Asked a row at a time it also cannot lie. 'Sits in no declared section'
    is false whenever the section is declared and merely holds another
    table first - a two-column glossary above the requirement table is
    enough - and a REQ file's bound section is '## Context' in all nine
    vaults, the one section most likely to carry incidental tables.

    The width floor sits on the header, not on the row: GFM pads a short
    body row to the header's width, so a four-cell row of a five-column
    table is a requirement row that would have been ingested had its table
    been read (example 204, the rule split_cells already implements).
    """
    for header, _hline, body in req_tables(lines):
        if not header or len(header) < 5:
            continue
        lost = [ln for ln, cells in body
                if len(cells) >= 2 and ROW_NNN_RE.match(cells[1])
                and ln not in bound_lines]
        if lost:
            g.findings.append(Finding(
                "export-unbound-table", f, lost[0],
                f"{len(lost)} requirement rows of this table are not in the "
                "graph - the export reads the first five-column table of the "
                "bound section and no other"))


def _report_unbound(g, f, lines, bound_lines):
    for title, header, line in sections_with_tables(lines):
        if line in bound_lines or len(header) < 2:
            continue
        g.findings.append(Finding(
            "export-unbound-table", f, line,
            f"table under '## {title}' sits in no section this project's "
            "templates declare as a relation table - its rows are not in the "
            "graph"))


def reverse_index(graph, schema):
    """Every reverse edge, computed. Nothing here is ever read from a file."""
    rels = _dict(schema, "relations")
    back = {}
    for e in graph.edges:
        spec = _dict(rels, e["kind"])
        key = spec.get("reverse_key") or f"{e['kind']}_back"
        back.setdefault(e["target"], {}).setdefault(key, [])
        if e["source"] not in back[e["target"]][key]:
            back[e["target"]][key].append(e["source"])
    for node in back.values():
        for key in node:
            node[key] = sorted(node[key])
    return back


# --------------------------------------------------------------------------
# Assessment
# --------------------------------------------------------------------------

GAP_CLASSES = {
    "not-allocated": "no allocation row names this requirement",
    "not-proven": "allocated, but not every allocation reached the proven status",
    "evidence-is-prose": "the allocation says proven, but its verification column "
                         "holds prose instead of a link",
    "no-evidence-note": "no evidence note names this requirement in 'verifies'",
    "evidence-disagrees": "an evidence note is linked in the allocation row but "
                          "does not name this requirement in 'verifies'",
}
# The vault's own rule decides whether a requirement is proven: the ARC README
# says an allocation may reach Verified only once a verification link exists and
# its evidence is written down. The two relation-level disagreements below are
# real and reported, but they are not that rule - making them decide would
# report every homelab requirement as unproven because that vault's evidence
# notes carry an empty 'verifies' list, which is a convention it never adopted.
OPEN_QUESTION_CLASSES = ("no-evidence-note", "evidence-disagrees")


def assess(graph, back):
    """Coverage per requirement, in this project's own vocabulary."""
    out = {}
    for rid in sorted(graph.requirements):
        req = graph.requirements[rid]
        allocs = req.get("allocations", [])
        verified_by = back.get(rid, {}).get("verifies_back", [])
        gaps = []
        all_verified = bool(allocs) and all(a["proven"] for a in allocs)
        all_linked = bool(allocs) and all(a["evidence"] for a in allocs)
        if not allocs:
            gaps.append("not-allocated")
        elif not all_verified:
            gaps.append("not-proven")
        elif not all_linked:
            gaps.append("evidence-is-prose")
        if not verified_by:
            gaps.append("no-evidence-note")
        linked = {e for a in allocs for e in a["evidence"]}
        if linked and not linked & set(verified_by):
            gaps.append("evidence-disagrees")
        weakest = min((STATUS_RANK[a["status_kind"]] for a in allocs), default=None)
        open_q = [g for g in gaps if g in OPEN_QUESTION_CLASSES]
        out[rid] = {
            "proven": all_verified and all_linked,
            "open_questions": open_q,
            "gaps": gaps,
            "status_kind": None if weakest is None else
            [k for k, v in STATUS_RANK.items() if v == weakest][0],
            "allocations": allocs,
            "evidence_notes": verified_by,
        }
    return out


# --------------------------------------------------------------------------
# Writers
# --------------------------------------------------------------------------

def provenance(vault, schema, args, inputs, stamp):
    digest = hashlib.sha256()
    for path, h in inputs:
        digest.update(path.encode("utf-8"))
        digest.update(h.encode("ascii"))
    prov = {
        "vault": str(vault.root),
        "generator": "export_traceability.py",
        "export_schema_version": EXPORT_SCHEMA_VERSION,
        "vault_schema_version": schema.get("schema_version"),
        "input_files": len(inputs),
        "input_digest": digest.hexdigest(),
        "command": "export_traceability.py " + " ".join(args),
        "csv_values": "written verbatim; no formula-injection prefix is applied, "
                      "because OWASP records that such prefixes may not survive a "
                      "spreadsheet round-trip and a mutated value is no longer a "
                      "record. Open the CSV as text, not by double-click.",
    }
    if stamp is not None:
        prov["generated_at"] = stamp
    return prov


def write_json(path, graph, back, coverage, prov, roles, bindings):
    doc = {
        "export_schema_version": EXPORT_SCHEMA_VERSION,
        "provenance": prov,
        "field_types": {
            "authored": ["nodes", "requirements", "edges"],
            "derived": ["reverse", "coverage"],
            "note": "Every key under 'reverse' is computed from 'edges' in one "
                    "pass. No file in the vault stores a back-link.",
        },
        "roles": roles,
        "bindings": {k: {"section": v.get("section"), "template": v.get("template")}
                     for k, v in sorted(bindings.items())},
        "nodes": {k: graph.nodes[k] for k in sorted(graph.nodes)},
        "requirements": {k: graph.requirements[k] for k in sorted(graph.requirements)},
        "edges": sorted(graph.edges, key=lambda e: (
            e["kind"], e["source"], e["target"], e["file"] or "", e["line"] or 0)),
        "reverse": {k: back[k] for k in sorted(back)},
        "coverage": coverage,
        "gap_classes": GAP_CLASSES,
        "findings": sorted((f.as_dict(Path(prov["vault"])) for f in graph.findings),
                           key=lambda d: (d["code"], d["file"] or "", d["line"] or 0)),
    }
    path.write_text(json.dumps(doc, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
                    encoding="utf-8")
    return doc


def owner_label(graph, alloc):
    """What to show as the owner of an allocation.

    The object's name when the subject cell resolved to one, and otherwise
    the author's own words: 115 of homelab's 148 subject cells are prose
    like 'Tailnet-DNS-Resolver Port 53', and dropping those would lose the
    'owning component or interface' column for a fifth of the vault.
    """
    node = graph.nodes.get(alloc["owner"])
    if node and alloc["owner_text"] and "[[" in alloc["owner_text"]:
        return node["name"]
    return alloc["owner_text"] or (node["name"] if node else alloc["owner"])


def compliance(cov):
    """ECSS-shaped: a compliance state, and never a blank cell for a gap."""
    if not cov["allocations"]:
        return "no"
    if not cov["proven"]:
        return "partial"
    return "yes-with-open-questions" if cov["open_questions"] else "yes"


def write_csv_matrix(path, graph, coverage):
    """Requirement-centric view: one row per requirement, never duplicated."""
    with open(path, "w", newline="", encoding="utf-8-sig") as fh:
        w = csv.writer(fh, dialect="excel", quoting=csv.QUOTE_ALL)
        w.writerow(["requirement", "class", "content", "acceptance_criterion",
                    "allocated_to", "verification_notes", "allocation_status",
                    "compliance", "open_reason", "source_file", "source_line"])
        for rid in sorted(graph.requirements):
            req, cov = graph.requirements[rid], coverage[rid]
            allocs = cov["allocations"]
            reasons = [a["status_reason"] for a in allocs if a["status_reason"]]
            reasons += [GAP_CLASSES[g] for g in cov["gaps"]]
            w.writerow([
                rid, req.get("class", ""), req["text"], req["acceptance_criterion"],
                " ; ".join(sorted({owner_label(graph, a) for a in allocs})),
                " ; ".join(sorted(cov["evidence_notes"])),
                " ; ".join(sorted({a["status"] for a in allocs})),
                compliance(cov),
                " ; ".join(dict.fromkeys(reasons)),
                req["file"], req["line"],
            ])


def write_csv_edges(path, graph):
    """One row per edge. Both matrix directions pivot out of this file."""
    with open(path, "w", newline="", encoding="utf-8-sig") as fh:
        w = csv.writer(fh, dialect="excel", quoting=csv.QUOTE_ALL)
        w.writerow(["relation", "source", "target", "qualifier",
                    "authored_in_file", "authored_in_line"])
        for e in sorted(graph.edges, key=lambda e: (
                e["kind"], e["source"], e["target"], e["file"] or "", e["line"] or 0)):
            w.writerow([e["kind"], e["source"], e["target"], e["qualifier"] or "",
                        e["file"] or "", e["line"] or ""])


CSS = """
:root { color-scheme: light dark; }
* { box-sizing: border-box; }
body { font-family: ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto,
       sans-serif; margin: 0 auto; max-width: 72rem; padding: 2rem 1rem;
       line-height: 1.5; }
h1 { font-size: 1.6rem; margin-bottom: .25rem; }
h2 { font-size: 1.2rem; margin-top: 2.5rem; border-bottom: 1px solid;
     padding-bottom: .25rem; }
.sub { opacity: .75; margin-top: 0; }
dl.prov { display: grid; grid-template-columns: max-content 1fr; gap: .15rem .75rem;
          font-size: .85rem; opacity: .85; }
dl.prov dt { font-weight: 600; }
dl.prov dd { margin: 0; word-break: break-all; }
.counts { display: flex; flex-wrap: wrap; gap: 1.5rem; margin: 1rem 0; }
.counts div { border: 1px solid; border-radius: .4rem; padding: .5rem .9rem; }
.counts b { display: block; font-size: 1.4rem; }
.wrap { overflow: auto; max-height: 80vh; border: 1px solid; border-radius: .4rem; }
table { border-collapse: collapse; width: 100%; font-size: .87rem;
        table-layout: fixed; }
caption { text-align: left; padding: .5rem .6rem; font-weight: 600; }
th, td { text-align: left; padding: .35rem .6rem; vertical-align: top;
         overflow-wrap: anywhere; box-shadow: inset 0 -1px 0 rgba(128,128,128,.4); }
thead th { position: sticky; top: 0; z-index: 2; background: Canvas; }
tbody th[scope="row"] { position: sticky; left: 0; z-index: 1; background: Canvas;
                        font-weight: 600; white-space: nowrap; }
thead th:first-child { z-index: 3; }
tbody tr:nth-child(even) td { background: rgba(128,128,128,.07); }
.flag { font-weight: 600; white-space: nowrap; }
.ok::before { content: "\\2713 "; }
.gap::before { content: "\\2717 "; }
ul.gaps { margin: .2rem 0; padding-left: 1.1rem; }
code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
footer { margin-top: 3rem; font-size: .8rem; opacity: .7; }
@media print {
  @page { size: A4 landscape; margin: 14mm; }
  body { max-width: none; padding: 0; }
  .wrap { max-height: none; overflow: visible; border: 0; }
  thead { display: table-header-group; }
  thead th, tbody th[scope="row"] { position: static; }
  tr { break-inside: avoid; }
}
"""


def esc(value):
    return html.escape("" if value is None else str(value), quote=True)


def safe_href(url):
    """A URL only when its scheme is one we allow, after decoding tricks.

    html.escape leaves 'javascript:' untouched, and control characters and
    entities let 'java&#9;script:' reach the parser as the same scheme.
    """
    if not isinstance(url, str):
        return None
    candidate = CONTROL_RE.sub("", html.unescape(url)).strip()
    scheme = candidate.split(":", 1)[0].lower() if ":" in candidate else ""
    return url if scheme in SAFE_SCHEMES else None


def write_html(path, graph, back, coverage, prov, findings):
    taken = set()
    anchors = {rid: slug(rid, taken) for rid in sorted(graph.requirements)}
    proven = sum(1 for c in coverage.values() if c["proven"])
    total = len(coverage)
    parts = []
    a = parts.append

    a('<meta charset="utf-8">')
    a('<meta name="viewport" content="width=device-width, initial-scale=1">')
    a('<meta http-equiv="Content-Security-Policy" '
      'content="default-src \'none\'; style-src \'unsafe-inline\'">')
    a(f"<title>Traceability report - {esc(Path(prov['vault']).name)}</title>")
    a(f"<style>{CSS}</style>")
    a(f"<h1>Traceability report</h1>")
    a(f'<p class="sub">{esc(prov["vault"])}</p>')

    open_q = sum(1 for c in coverage.values() if c["proven"] and c["open_questions"])
    a('<div class="counts">')
    a(f"<div><b>{total}</b>requirements</div>")
    a(f"<div><b>{proven}</b>proven</div>")
    a(f"<div><b>{open_q}</b>proven, open questions</div>")
    a(f"<div><b>{total - proven}</b>not proven</div>")
    a(f"<div><b>{len(graph.edges)}</b>relations</div>")
    a(f"<div><b>{len(findings)}</b>findings</div>")
    a("</div>")
    a("<p>Proven means what this vault's own rule means: every allocation of "
      "the requirement reached the declared proven status and carries a link "
      "to its verification. An open question is a disagreement between two "
      "relations that were authored separately - it does not undo the "
      "allocation, and it is not hidden either.</p>")

    a("<h2>What is unproven</h2>")
    gaps = [rid for rid in sorted(coverage) if not coverage[rid]["proven"]]
    if not gaps:
        a("<p>Every requirement is allocated, every allocation reached the "
          "declared proven status, and every requirement is named by an "
          "evidence note.</p>")
    else:
        a('<div class="wrap"><table>')
        a(f"<caption>{len(gaps)} of {total} requirements are not proven</caption>")
        a("<thead><tr><th scope=\"col\">Requirement</th>"
          "<th scope=\"col\">Content</th><th scope=\"col\">Why it is not proven</th>"
          "</tr></thead><tbody>")
        for rid in gaps:
            cov = coverage[rid]
            items = "".join(f"<li>{esc(GAP_CLASSES[g])}</li>" for g in cov["gaps"])
            items += "".join(
                f"<li>allocation in <code>{esc(al['file'])}</code> line "
                f"{esc(al['line'])} carries status "
                f"<b>{esc(al['status'])}</b></li>"
                for al in cov["allocations"] if not al["proven"])
            a(f'<tr><th scope="row" id="{esc(anchors[rid])}">{esc(rid)}</th>'
              f"<td>{esc(graph.requirements[rid]['text'])}</td>"
              f'<td><ul class="gaps">{items}</ul></td></tr>')
        a("</tbody></table></div>")

    a("<h2>Requirement to evidence</h2>")
    a('<div class="wrap"><table>')
    a(f"<caption>{total} requirements, their allocation and their evidence"
      "</caption>")
    a('<thead><tr><th scope="col">Requirement</th><th scope="col">Content</th>'
      '<th scope="col">Allocated to</th><th scope="col">Evidence notes</th>'
      '<th scope="col">Status</th><th scope="col">Proven</th></tr></thead><tbody>')
    for rid in sorted(graph.requirements):
        req, cov = graph.requirements[rid], coverage[rid]
        owners = sorted({owner_label(graph, al) for al in cov["allocations"]})
        status = sorted({al["status"] for al in cov["allocations"]})
        if not cov["proven"]:
            flag = '<span class="flag gap">not proven</span>'
        elif cov["open_questions"]:
            flag = '<span class="flag ok">proven, open questions</span>'
        else:
            flag = '<span class="flag ok">proven</span>'
        a(f'<tr><th scope="row">{esc(rid)}</th>'
          f"<td>{esc(req['text'])}</td>"
          f"<td>{esc(' ; '.join(owners)) or '&mdash;'}</td>"
          f"<td>{esc(' ; '.join(sorted(cov['evidence_notes']))) or '&mdash;'}</td>"
          f"<td>{esc(' ; '.join(status)) or '&mdash;'}</td>"
          f"<td>{flag}</td></tr>")
    a("</tbody></table></div>")

    a("<h2>Evidence to requirement</h2>")
    a("<p>Computed from the same edges, read the other way. Nothing below is "
      "written down anywhere in the vault.</p>")
    ev_nodes = sorted(k for k, v in graph.nodes.items() if v["role"] == "TAE")
    a('<div class="wrap"><table>')
    a(f"<caption>{len(ev_nodes)} evidence notes and what they prove</caption>")
    a('<thead><tr><th scope="col">Evidence note</th><th scope="col">File</th>'
      '<th scope="col">Requirements it verifies</th></tr></thead><tbody>')
    for key in ev_nodes:
        node = graph.nodes[key]
        verifies = sorted(e["target"] for e in graph.edges
                          if e["kind"] == "verifies" and e["source"] == key)
        a(f'<tr><th scope="row">{esc(node["name"])}</th>'
          f"<td><code>{esc(node['file'])}</code></td>"
          f"<td>{esc(' ; '.join(verifies)) or '&mdash; (names no requirement)'}</td></tr>")
    a("</tbody></table></div>")

    if findings:
        a("<h2>Findings</h2>")
        a('<div class="wrap"><table>')
        a(f"<caption>{len(findings)} things this export could not resolve"
          "</caption>")
        a('<thead><tr><th scope="col">Code</th><th scope="col">File</th>'
          '<th scope="col">Line</th><th scope="col">Message</th></tr></thead><tbody>')
        for f in findings:
            a(f'<tr><th scope="row">{esc(f["code"])}</th>'
              f"<td><code>{esc(f['file'] or '')}</code></td>"
              f"<td>{esc(f['line'] or '')}</td><td>{esc(f['message'])}</td></tr>")
        a("</tbody></table></div>")

    a("<h2>Provenance</h2><dl class=\"prov\">")
    for k in sorted(prov):
        a(f"<dt>{esc(k)}</dt><dd>{esc(prov[k])}</dd>")
    a("</dl>")
    a("<footer>Generated by export_traceability.py. Every reverse relation in "
      "this report is computed from the forward relations; the vault stores "
      "none of them.</footer>")
    path.write_text("\n".join(parts) + "\n", encoding="utf-8")


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def timestamp(no_timestamp):
    if no_timestamp:
        return None
    epoch = os.environ.get("SOURCE_DATE_EPOCH")
    if epoch and epoch.isdigit():
        return datetime.fromtimestamp(int(epoch), timezone.utc).isoformat()
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def main(argv):
    ap = argparse.ArgumentParser(
        description="Export a vault as a traceability artifact")
    ap.add_argument("vault_root")
    ap.add_argument("--output-dir", required=True,
                    help="directory for the artifacts; must be outside any vault")
    ap.add_argument("--formats", default="json,csv,html")
    ap.add_argument("--no-timestamp", action="store_true",
                    help="omit the generation time so two runs compare equal")
    args = ap.parse_args(argv)

    root = Path(args.vault_root).resolve()
    if not is_vault_root(root):
        print(f"ERROR - {root} is not a vault root", file=sys.stderr)
        return 2
    out = Path(args.output_dir).resolve()
    # The vault is Markdown only (STRUCTURE.md). A mandatory flag does not
    # enforce that on its own; refusing does.
    from validate_vault import find_vault_root
    if find_vault_root(out) is not None:
        print(f"ERROR - {out} lies inside a vault; the vault holds Markdown "
              "only. Write the export to 00_documentation/02_documents/ or "
              "outside the project.", file=sys.stderr)
        return 2
    try:
        out.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        print(f"ERROR - cannot create {out}: {e}", file=sys.stderr)
        return 2

    formats = {f.strip() for f in args.formats.split(",") if f.strip()}
    vault = Vault(root)
    schema, schema_error = load_schema()
    findings = []
    if schema_error:
        findings.append(Finding("export-schema-unreadable", None, None, schema_error))

    roles = resolve_roles(vault, schema, findings)
    ROLE_CACHE.clear()
    ROLE_CACHE.update(roles)
    bindings = discover_bindings(vault, schema, findings)
    graph, _proven = build_graph(vault, schema, roles, bindings)
    graph.findings = findings + graph.findings
    back = reverse_index(graph, schema)
    coverage = assess(graph, back)

    inputs = []
    for p in sorted(root.rglob("*.md")):
        if ".obsidian" in p.parts or ".git" in p.parts:
            continue
        try:
            inputs.append((rel(p, root),
                           hashlib.sha256(p.read_bytes()).hexdigest()))
        except OSError:
            continue
    prov = provenance(vault, schema, argv, inputs, timestamp(args.no_timestamp))

    doc = None
    if "json" in formats:
        doc = write_json(out / "traceability.json", graph, back, coverage, prov,
                         roles, bindings)
    finding_dicts = sorted((f.as_dict(root) for f in graph.findings),
                           key=lambda d: (d["code"], d["file"] or "", d["line"] or 0))
    if "csv" in formats:
        write_csv_matrix(out / "traceability_requirements.csv", graph, coverage)
        write_csv_edges(out / "traceability_edges.csv", graph)
    if "html" in formats:
        write_html(out / "traceability.html", graph, back, coverage, prov,
                   finding_dicts)

    proven = sum(1 for c in coverage.values() if c["proven"])
    print(f"vault: {root}")
    print(f"requirements: {len(coverage)}  proven: {proven}  "
          f"not proven: {len(coverage) - proven}")
    print(f"objects: {len(graph.nodes)}  relations: {len(graph.edges)}  "
          f"findings: {len(finding_dicts)}")
    for name, b in sorted(bindings.items()):
        if b.get("section"):
            print(f"bound {name} -> '## {b['section']}'")
    print(f"written to: {out}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except SystemExit:
        raise
    except Exception as e:  # noqa: BLE001 - a crash must not look like an export
        print(f"exporter crash: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(2)
