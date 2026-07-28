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

Exit codes: 0 = no errors (warnings allowed), 1 = at least one error,
2 = validator crash (hooks fail open on 2).

Severities: ERROR blocks (via the stop gate, ratcheted against the git
HEAD baseline of pre-existing files), WARN reports. status: draft does
NOT relax any check.
"""

import json
import re
import subprocess
import sys
import time
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
WIKILINK_RE = re.compile(r"(!?)\[\[([^\]|#\n]+)(#[^\]|\n]*)?(\|[^\]\n]*)?\]\]")
REQ_ID_RE = re.compile(r"REQ-[A-Z]{2,4}-\d{3}")
DOM_IN_NAME_RE = re.compile(r"\(([A-Z]{2,4})\)")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
PATH_TOKEN_RE = re.compile(r"(?<![\w(])((?:[\w.-]+/)+[\w.-]+\.\w{1,12})\b")
PIN_RE = re.compile(r"\b(?:GPIO\d+|P[A-K]\d{1,2}|0x[0-9A-Fa-f]{2,})\b")
# Project-artifact path shape (NN_folder/... per the vault conventions);
# gates the body-wide dead-path scan so ratio notation (3.3V/1.8V),
# bare domains (heise.de/...) and foreign paths never WARN.
ARTIFACT_SEG_RE = re.compile(r"^\d{2}_")
# Explicit open-item markers suppress the body-wide dead-path WARN only -
# never the References/Sources ERROR (silent-bypass prevention).
PENDING_RE = re.compile(r"\b(pending|planned|tbd|not\s+yet)\b", re.I)

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

ROOT_ALLOWLIST = {
    "README.md",
    "system_overview.md",
    "00_glossary.md",
    "00_project_summary.md",
    "00_documentation_file_creation_and_conventions.md",
    "00_documentation_subfolders.md",
}

GENERIC_STATUS = {"draft", "active", "superseded", "deprecated"}
DEC_BODY_STATUS = {"Draft", "Accepted", "Superseded", "Deprecated"}


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
    return any(next(iter(s.glob("00_*file_template*.md")), None) for s in subs)


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
        self.domains = {}      # ABBR -> domain dir path
        for s in self.root.iterdir():
            m = DOMAIN_DIR_RE.match(s.name) if s.is_dir() else None
            if m:
                self.domains[m.group(1)] = s
        self._templates = None
        self._md_names = None
        self._all_names = None
        self._req_index = None

    def templates_for(self, abbr):
        """H2 heading sets of each template of a domain (empty sets excluded)."""
        if self._templates is None:
            self._templates = {}
            for dom, ddir in self.domains.items():
                sets = []
                for tf in sorted(ddir.glob("00_*file_template*.md")):
                    try:
                        h2s = extract_h2(tf.read_text(encoding="utf-8", errors="replace"))
                    except OSError:
                        continue
                    if h2s:
                        sets.append((tf.name, h2s))
                self._templates[dom] = sets
        return self._templates.get(abbr, [])

    def _build_name_index(self):
        self._md_names, self._all_names = {}, {}
        for p in self.doc_root.rglob("*"):
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
        """All full REQ IDs defined in REQ domain files: id -> (path, line)."""
        if self._req_index is None:
            self._req_index = {}
            reqdir = self.domains.get("REQ")
            if reqdir:
                for f in reqdir.rglob("*.md"):
                    if f.name.startswith("00_"):
                        continue
                    m = DOM_IN_NAME_RE.search(f.stem)
                    if not m:
                        continue
                    dom = m.group(1)
                    for i, line in enumerate(read_lines(f), 1):
                        row = parse_table_row(line)
                        if row and len(row) >= 2 and re.fullmatch(r"\d{3}", row[1]):
                            self._req_index.setdefault(f"REQ-{dom}-{row[1]}", (f, i))
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

def read_lines(path: Path):
    return path.read_text(encoding="utf-8", errors="replace").splitlines()


def extract_h2(text: str):
    return {l[3:].strip() for l in text.splitlines() if l.startswith("## ")}


def parse_table_row(line: str):
    s = line.strip()
    if not (s.startswith("|") and s.endswith("|") and s.count("|") >= 3):
        return None
    cells = [c.strip() for c in s[1:-1].split("|")]
    if all(re.fullmatch(r":?-{2,}:?", c) for c in cells if c):
        return None  # separator row
    return cells


def parse_frontmatter(lines):
    """Minimal flat YAML parser. Returns (dict|None, end_line, malformed_msg)."""
    if not lines or lines[0].strip() != "---":
        return None, 0, None
    data = {}
    for i in range(1, len(lines)):
        line = lines[i]
        if line.strip() == "---":
            return data, i + 1, None
        if not line.strip() or line.strip().startswith("#"):
            continue
        m = re.match(r"^([A-Za-z][\w-]*):\s*(.*)$", line.strip())
        if not m:
            return None, i + 1, f"unparseable frontmatter line: {line.strip()!r}"
        key, val = m.group(1), m.group(2).strip()
        if val.startswith("[") and val.endswith("]"):
            inner = val[1:-1].strip()
            data[key] = [v.strip().strip("'\"") for v in inner.split(",") if v.strip()]
        else:
            data[key] = val.strip("'\"")
    return None, len(lines), "frontmatter never closed with ---"


def section_of(lines, idx, fm_end):
    """Lowercased H2 heading governing line idx (0-based)."""
    for j in range(idx, fm_end - 1, -1):
        if j < len(lines) and lines[j].startswith("## "):
            return lines[j][3:].strip().lower()
    return ""


# --------------------------------------------------------------------------
# File-local checks
# --------------------------------------------------------------------------

def validate_file(vault: Vault, path: Path, content=None, strict_links=False):
    findings = []
    kind, abbr = vault.classify(path)
    if kind in ("outside", "skip"):
        return findings
    lines = content.splitlines() if content is not None else read_lines(path)

    if kind == "inbox":
        check_links(vault, path, lines, findings, strict_links, hub=False)
        if content is None:
            check_inb_age(path, findings)
        return findings

    if kind in ("root", "infra"):
        if kind == "infra" and "file_template" in path.name:
            fm, _, bad = parse_frontmatter(lines)
            if bad:
                findings.append(Finding("ERROR", "template-unreadable", str(path), 1, bad))
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
                                "domain files need YAML frontmatter "
                                "(domain, status, created, last-verified)"))
        fm, fm_end = {}, 0
    else:
        check_frontmatter(fm, abbr, path, findings)

    check_sections(vault, abbr, path, lines, findings)
    check_length(path, lines, findings)
    check_links(vault, path, lines, findings, strict_links, hub=abbr == "ARC")
    check_leaks(abbr, path, lines, fm_end, findings)
    check_paths(vault, path, lines, fm_end, findings)
    if abbr == "REQ":
        check_req_table(path, lines, findings)
    if abbr == "TAE":
        check_tae_verifies(vault, fm, path, findings)
    if abbr == "DEC":
        check_dec_status(path, lines, findings)

    body = [l for l in lines[fm_end:] if l.strip()]
    if len(body) < STUB_MIN_LINES:
        findings.append(Finding("WARN", "stub", str(path), None,
                                f"only {len(body)} content lines - stub file? "
                                "Fill it or do not create it yet."))
    return findings


def check_frontmatter(fm, abbr, path, findings):
    required = ["domain", "created", "last-verified"]
    if abbr != "DEC":
        required.insert(1, "status")
    for key in required:
        if key not in fm:
            findings.append(Finding("ERROR", "frontmatter-key", str(path), 1,
                                    f"frontmatter missing required key '{key}'"))
    if fm.get("domain") and fm["domain"] != abbr:
        findings.append(Finding("ERROR", "frontmatter-domain", str(path), 1,
                                f"frontmatter domain '{fm['domain']}' != folder domain '{abbr}'"))
    if abbr != "DEC" and fm.get("status") and fm["status"] not in GENERIC_STATUS:
        findings.append(Finding("ERROR", "frontmatter-status", str(path), 1,
                                f"status '{fm['status']}' not in {sorted(GENERIC_STATUS)}"))
    for key in ("created", "last-verified"):
        v = fm.get(key)
        if v and not DATE_RE.match(str(v)):
            findings.append(Finding("ERROR", "frontmatter-date", str(path), 1,
                                    f"'{key}' must be YYYY-MM-DD, got '{v}'"))
    if abbr == "TAE":
        ver = fm.get("verifies")
        if ver is None:
            findings.append(Finding("ERROR", "frontmatter-key", str(path), 1,
                                    "TAE frontmatter missing 'verifies: [REQ-...]'"))
        elif isinstance(ver, list):
            for rid in ver:
                if not REQ_ID_RE.fullmatch(rid):
                    findings.append(Finding("ERROR", "verifies-format", str(path), 1,
                                            f"'{rid}' is not a REQ-DOM-NNN id"))
            if not ver:
                findings.append(Finding("WARN", "verifies-empty", str(path), 1,
                                        "TAE verifies no requirement - what does it prove?"))


def check_sections(vault, abbr, path, lines, findings):
    templates = vault.templates_for(abbr)
    if not templates:
        return  # domain without templates (e.g. ADM): nothing to enforce
    file_h2 = extract_h2("\n".join(lines))
    best_missing, best_name = None, None
    for tname, th2 in templates:
        missing = th2 - file_h2
        if best_missing is None or len(missing) < len(best_missing):
            best_missing, best_name = missing, tname
        if not missing:
            return
    findings.append(Finding("ERROR", "template-sections", str(path), None,
                            f"missing required sections {sorted(best_missing)} "
                            f"(closest template: {best_name})"))


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


def check_links(vault, path, lines, findings, strict, hub=False):
    md_names, all_names = vault.md_names(), vault.all_names()
    targets = Counter()
    total = 0
    in_fence = False
    for i, line in enumerate(lines, 1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        # Obsidian does not resolve links inside code spans
        line = re.sub(r"`[^`]*`", " ", line)
        for m in WIKILINK_RE.finditer(line):
            target = m.group(2).strip()
            total += 1
            targets[target] += 1
            resolved = (target in md_names or target in all_names
                        or f"{target}.md" in all_names)
            if not resolved:
                sev = "ERROR" if strict else "WARN"
                findings.append(Finding(sev, "link-unresolved", str(path), i,
                                        f"[[{target}]] does not resolve to any file "
                                        "under 00_documentation"))
    budget = LINK_BUDGET_HUB if (hub or path.name == "system_overview.md") else LINK_BUDGET
    if total > budget:
        findings.append(Finding("WARN", "link-budget", str(path), None,
                                f"{total} outgoing links > {budget}. Link the responsible "
                                "file once - do not link every mention."))
    for t, c in targets.items():
        if c > LINK_REPEAT_WARN:
            findings.append(Finding("WARN", "link-repeat", str(path), None,
                                    f"[[{t}]] linked {c}x in one file."))


def check_leaks(abbr, path, lines, fm_end, findings):
    """Implementation-detail leak detector.

    Precision over recall: only ARC (whole body, ERROR - the README bans
    concrete values outright) and DEC Context (WARN) are scanned; the
    value-bearing domains (REQ tables, CMP specs, IFC specs, TAE evidence,
    IMP, OAU) are legitimate homes for numbers and are never flagged.
    Code fences are banned in IMP and ARC (pointers, not copies).
    """
    in_fence = False
    for i, line in enumerate(lines, 1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            if in_fence and abbr in ("IMP", "ARC"):
                findings.append(Finding("ERROR", "code-fence", str(path), i,
                                        f"code blocks are banned in {abbr} - link the "
                                        "source file instead (pointers, not copies)"))
            continue
        if in_fence or abbr not in ("ARC", "DEC") or i <= fm_end:
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

    References/Sources H2 sections keep the strict historical contract:
    every path token is checked, dead ones ERROR, no suppression, fenced
    content included. The rest of the body is scanned advisorily: only
    project-artifact-shaped tokens (NN_ segment), WARN severity, inline
    code and fenced blocks skipped, and an explicit pending/planned/TBD
    marker on the line or its governing heading suppresses the finding.
    Fence state is tracked first so fenced '## ' lines never switch zones.
    """
    in_ref = False
    in_fence = False
    pending_scope = False
    for i, line in enumerate(lines, 1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
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
            if not in_ref and not (ARTIFACT_SEG_RE.match(segs[0])
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


def check_req_table(path, lines, findings):
    seen = {}
    header_ok = False
    for i, line in enumerate(lines, 1):
        row = parse_table_row(line)
        if not row:
            continue
        if "Class" in row[0] or "NNN" in " ".join(row[:2]):
            header_ok = True
            continue
        if not header_ok or len(row) < 5:
            continue
        cls, nnn, content, crit = row[0], row[1], row[2], row[3]
        if not (cls or nnn or content):
            continue  # empty template row
        if cls not in ("M", "S", "O"):
            findings.append(Finding("ERROR", "req-class", str(path), i,
                                    f"class '{cls}' must be exactly M, S or O"))
        if not re.fullmatch(r"\d{3}", nnn):
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
                                    "empty acceptance criterion - untestable requirement"))


def check_tae_verifies(vault, fm, path, findings):
    ver = fm.get("verifies") if fm else None
    if not isinstance(ver, list):
        return
    index = vault.req_index()
    for rid in ver:
        if REQ_ID_RE.fullmatch(rid) and rid not in index:
            findings.append(Finding("ERROR", "verifies-unknown-req", str(path), 1,
                                    f"{rid} is not defined in any REQ file"))


def check_dec_status(path, lines, findings):
    status = None
    for i, line in enumerate(lines, 1):
        m = re.match(r"^Status:\s*(.+)$", line.strip())
        if m:
            status = m.group(1).strip()
            if status not in DEC_BODY_STATUS:
                findings.append(Finding("ERROR", "dec-status", str(path), i,
                                        f"Status '{status}' not in {sorted(DEC_BODY_STATUS)}"))
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

def validate_vault_wide(vault: Vault):
    findings = []
    all_md = [p for p in vault.root.rglob("*.md")
              if ".obsidian" not in p.parts and ".git" not in p.parts]
    domain_files = [p for p in all_md if vault.classify(p)[0] == "domain"]

    # duplicate REQ ids across files
    reqdir = vault.domains.get("REQ")
    if reqdir:
        ids = {}
        for f in reqdir.rglob("*.md"):
            if f.name.startswith("00_"):
                continue
            m = DOM_IN_NAME_RE.search(f.stem)
            if not m:
                continue
            for i, line in enumerate(read_lines(f), 1):
                row = parse_table_row(line)
                if row and len(row) >= 2 and re.fullmatch(r"\d{3}", row[1]):
                    rid = f"REQ-{m.group(1)}-{row[1]}"
                    if rid in ids and ids[rid][0] != f:
                        findings.append(Finding("ERROR", "req-duplicate-global", str(f), i,
                                                f"{rid} already defined in "
                                                f"{ids[rid][0].name}:{ids[rid][1]}"))
                    else:
                        ids.setdefault(rid, (f, i))

    corpus = {}
    for p in all_md:
        try:
            corpus[p] = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            corpus[p] = ""

    # REQ coverage: every REQ id referenced by some TAE (frontmatter) or ARC table
    for rid, (f, i) in vault.req_index().items():
        covered = any(rid in text for p, text in corpus.items()
                      if p != f and vault.classify(p)[1] in ("TAE", "ARC"))
        if not covered:
            findings.append(Finding("WARN", "req-uncovered", str(f), i,
                                    f"{rid} has no TAE/ARC referencing it - an unverified "
                                    "REQ is indistinguishable from an unmet one"))

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
                                    f"'{name}' exists {len(paths)}x under 00_documentation - "
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
    try:
        rel = path.resolve().relative_to(vault.project_root)
    except ValueError:
        return None
    try:
        r = subprocess.run(["git", "-C", str(vault.project_root), "show", f"HEAD:{rel}"],
                           capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout if r.returncode == 0 else None


def error_counts(findings):
    return dict(Counter(f.code for f in findings if f.sev == "ERROR"))


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
    reports, new_errors, created, inb_added = [], [], [], []
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

    summary = []
    if created:
        summary.append("files created this session: "
                       + ", ".join(Path(c).name for c in created))
    if inb_added:
        summary.append("NOTE: new inbox files while documenting - the inbox is not an "
                       "escape hatch for validation: "
                       + ", ".join(Path(c).name for c in inb_added))
    if reports:
        summary.append("advisory findings:\n" + "\n".join(sorted(set(reports))))

    if new_errors:
        blocks_f = state_path("blocks", session)
        blocks = load_json(blocks_f, 0)
        if blocks < MAX_STOP_BLOCKS:
            blocks_f.write_text(json.dumps(blocks + 1))
            reason = ("vault validator: ERRORs introduced this session must be fixed "
                      f"before finishing (attempt {blocks + 1}/{MAX_STOP_BLOCKS}):\n"
                      + "\n".join(sorted(set(new_errors)))
                      + ("\n" + "\n".join(summary) if summary else ""))
            print(json.dumps({"decision": "block", "reason": reason}))
            return 0
        summary.insert(0, "UNRESOLVED vault ERRORs (gate released after "
                       f"{MAX_STOP_BLOCKS} attempts - surface these to the user):\n"
                       + "\n".join(sorted(set(new_errors))))

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
        shown = wide[:15]
        if len(wide) > 15:
            shown.append(f"... +{len(wide) - 15} more")
        summary.append("vault-wide findings (advisory - not blocking, may "
                       "include legacy state):\n" + "\n".join(shown))

    if summary:
        print("vault validator session report:\n" + "\n".join(summary))
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
    args = ap.parse_args(argv)

    if args.hook:
        payload = json.load(sys.stdin)
        return hook_post(payload) if args.hook == "post" else hook_stop(payload)

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
            print(f"ERROR - {root} is not a vault root (needs >=3 NN_name_(ABBR) "
                  "domain folders containing 00_*file_template* files)", file=sys.stderr)
            return 2
        findings = run_full(Vault(root))

    errors = [f for f in findings if f.sev == "ERROR"]
    warns = [f for f in findings if f.sev == "WARN"]
    for f in findings:
        print(f.render())
    print(f"-- {len(errors)} error(s), {len(warns)} warning(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except SystemExit:
        raise
    except Exception as e:  # crash -> exit 2, hooks fail open
        print(f"validator crash: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(2)
