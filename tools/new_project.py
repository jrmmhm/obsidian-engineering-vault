#!/usr/bin/env python3
"""Derive a clean project from the obsidian-engineering-vault template.

    python3 tools/new_project.py <target-dir> [--name NAME] [--minimal]
                                              [--rename-docs-readme]

Copies the template this script lives in into a fresh target directory,
strips everything the repository names as template-repo-only, removes the
worked example along the README's documented deletion path, rewrites the CI
workflow to the two steps that hold in a derived project (issue #85), and
generates a project README carrying the project name. It finishes by running
the derived copy's own vault validator and refuses to report success unless
the output matches the predicted state: zero ERRORs and either the one known
`duplicate-basename` warning or, with --rename-docs-readme, none at all.

The strip list is assembled from what the repository says about itself
(CONTRIBUTING.md and CHANGELOG.md blockquotes, STRUCTURE.md's per-directory
notes, the README's worked-example section); the reasoning is recorded in the
method vault as DEC-MTH-036. Standard library only. The script never writes
outside the target it creates, refuses a non-empty target, and removes a
partially written target when the derivation itself fails.

--minimal derives the reduced profile of issue #79: the vault starts with the
three domains the tools close a loop over - REQ, ARC, TAE - and the other six
domain folders are moved, not deleted, to a parking folder beside the vault so
a domain joins later by moving its folder back. The reasoning, including why
the parked folders keep their templates, is DEC-MTH-041.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# Template-relative paths that never ship in a derived project. Each entry is
# checked for existence first, so a template layout change surfaces as a named
# warning instead of a silent no-op.
STRIP_PATHS = [
    # The derivation tooling itself - template-repo-only by definition.
    "tools",
    # "Replace it with your own rules or delete it" - their own blockquotes.
    "CONTRIBUTING.md",
    "CHANGELOG.md",
    # The tutorial derives a project as its step 0 and quotes the output of
    # a vault that has just been derived, so it is false from its first
    # line inside one. Read it in the clone it came from (DEC-MTH-040).
    "TUTORIAL.md",
    # "In a project made from this template, delete this directory" (STRUCTURE.md).
    ".claude/01_methodvault",
    # ".github/: delete it, or keep the workflow and replace the templates
    # with your own" (STRUCTURE.md) - the workflow is kept and rewritten below.
    ".github/ISSUE_TEMPLATE",
    ".github/pull_request_template.md",
    # The suite asserts this template's own vaults (worked-example export
    # counts, method vault presence) and stays red anywhere else - issue #85.
    ".claude/skills/mechatronics-docs/tests",
    # The worked example, along the README's documented deletion path (#70).
    "00_documentation/01_projectvault/01_requirements_(REQ)/REQ_Battery_Monitoring (BAT).md",
    "00_documentation/01_projectvault/02_decisions_(DEC)/DEC_Battery_Log_Acceptance_Check.md",
    "00_documentation/01_projectvault/03_architecture_(ARC)/ARC_Battery_Monitoring.md",
    "00_documentation/01_projectvault/04_components_(CMP)/CMP_Battery_Pack.md",
    "00_documentation/01_projectvault/05_interfaces_(IFC)/IFC_PWR_DC_LiPo_Pack.md",
    "00_documentation/01_projectvault/06_implementation_(IMP)/IMP_Battery_Log_Evaluation.md",
    "00_documentation/01_projectvault/07_testing_and_evidence_(TAE)/TAE_Battery_Log_Acceptance.md",
    "20_software/data_analysis",
    "30_testdata/31_testdata_raw/2026-07-28_battery_monitoring",
    "30_testdata/32_testdata_processed/2026-07-28_battery_monitoring",
]

# Machine-local state a working clone may carry; absence is not a finding.
JUNK_RELPATHS = {".claude/settings.local.json"}
JUNK_NAMES = {".git", "__pycache__", ".DS_Store", "Thumbs.db"}
# Only these two ship inside .obsidian/ - they carry settings the method
# depends on (link auto-update, properties view). Everything else there is
# per-machine state.
OBSIDIAN_KEEP = {"app.json", "core-plugins.json"}

VAULT_REL = "00_documentation/01_projectvault"
VALIDATOR_REL = ".claude/skills/mechatronics-docs/validate_vault.py"

# --minimal: the six domain folders a project does not start with (issue #79).
# The three that stay - REQ, ARC, TAE - are the ones the coverage rule is
# decided on: an allocation row lives in ARC, a 'verifies:' field in TAE, and
# both are about a REQ. ADM and INB stay too; they are not engineering domains.
MINIMAL_PARKED_DOMAINS = [
    "02_decisions_(DEC)",
    "04_components_(CMP)",
    "05_interfaces_(IFC)",
    "06_implementation_(IMP)",
    "08_operation_and_usage_(OAU)",
    "09_references_(REF)",
]
# Moved, never deleted: a folder recreated by hand later would arrive without
# its file template, and the validator enforces no section at all for a domain
# that has none - the domain would come back with its rules switched off
# (DEC-MTH-041). Parked under 00_documentation so every wikilink still
# resolves: the name index is built over the whole documentation root.
PARK_REL = "00_documentation/03_vault_domains_not_in_use"
# Not 'README.md'. That name exists twice under 00_documentation already, and a
# third one would make the warning-free state of --rename-docs-readme
# unreachable - measured as the difference between one warning and none.
PARK_README_NAME = "00_domains_not_in_use_README.md"

PARK_README = """\
# Domain folders this project has not started

The vault next door carries the three domains a project starts with:
`01_requirements_(REQ)` (what must hold), `03_architecture_(ARC)` (where it is
allocated and how it is verified) and `07_testing_and_evidence_(TAE)` (what
proves it). These six wait here with their READMEs and their file templates
until the project grows into them.

`00_documentation/01_projectvault/README.md` says when each one typically
joins. When that day comes, **move the folder back** into the vault:

    mv "00_documentation/03_vault_domains_not_in_use/02_decisions_(DEC)" \\
       00_documentation/01_projectvault/

Move it — do not create a fresh folder of the same name beside it. Two folders
for one domain collide on their file names, and the validator reports the
collision rather than choosing for you.

Nothing here is validated while it waits: the audit runs on the vault by path.
A folder is checked again the moment it moves back in.
"""

# Applied only with --minimal: every surviving sentence that describes a
# nine-domain vault would be false in a project that starts with three.
MINIMAL_REPLACEMENTS = [
    ("STRUCTURE.md",
     "All engineering documentation. Two subfolders that share the same nine-domain\n"
     "structure.\n",
     "All engineering documentation. Three subfolders: the vault, the document\n"
     "folder mirroring its domains, and the domain folders this project has not\n"
     "started yet.\n"
     "\n"
     "This project was derived with the minimal profile, so its vault carries\n"
     "`01_requirements_(REQ)`, `03_architecture_(ARC)` and\n"
     "`07_testing_and_evidence_(TAE)`. The other six domain folders wait in\n"
     "`00_documentation/03_vault_domains_not_in_use/` and join by moving the\n"
     "folder back — the vault's `README.md` says when each one typically does.\n"),
]

MINIMAL_PARAGRAPH = """\
## Minimal profile

This project was derived with `--minimal`. Its vault starts with the three
domains the tools close a loop over: `01_requirements_(REQ)` — what must hold,
`03_architecture_(ARC)` — where it is allocated and how it is verified, and
`07_testing_and_evidence_(TAE)` — what proves it.

The other six domain folders are not gone. They wait, with their READMEs and
file templates, in `00_documentation/03_vault_domains_not_in_use/`. When a
domain joins, move its folder back:

```bash
mv "00_documentation/03_vault_domains_not_in_use/02_decisions_(DEC)" \\
   00_documentation/01_projectvault/
```

Move it rather than creating a fresh one beside it, and read that domain's
`00_*_README.md` before writing in it. The vault's own
`README.md` says when each domain typically joins.

"""

DERIVED_WORKFLOW = """\
name: vault

# Enforcement that does not depend on one editor being used. The Claude
# Code hooks only see Edit/Write/MultiEdit; this runs on every push and
# pull request regardless of how the change was authored.

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      # The validator is stdlib-only, and ubuntu-latest ships python3
      # preinstalled - no setup-python, no dependency installation step.
      # The vault is named by path so the check fails loudly instead of
      # silently skipping if the layout ever moves.
      - name: Project vault audit
        run: python3 .claude/skills/mechatronics-docs/validate_vault.py 00_documentation/01_projectvault

      # An export is evidence only if it is reproducible. Running it twice and
      # diffing is the property itself, not a proxy for it.
      - name: Traceability export is deterministic
        run: |
          # The same output directory twice, with the first run copied aside.
          # Two different directories would differ in the provenance block's
          # command line, which is a true record and not a determinism defect.
          python3 .claude/skills/mechatronics-docs/export_traceability.py \\
            00_documentation/01_projectvault --output-dir "$RUNNER_TEMP/tr" \\
            --no-timestamp
          cp -r "$RUNNER_TEMP/tr" "$RUNNER_TEMP/tr-ref"
          python3 .claude/skills/mechatronics-docs/export_traceability.py \\
            00_documentation/01_projectvault --output-dir "$RUNNER_TEMP/tr" \\
            --no-timestamp
          diff -r "$RUNNER_TEMP/tr-ref" "$RUNNER_TEMP/tr"

      # When your evidence chain stands, you can make CI refuse an open
      # one. Add --fail-on to the export above, or as a step of its own:
      #
      #   --fail-on not-allocated,no-evidence-note
      #
      # It exits 1 when a requirement is allocated by no row, or named by
      # no evidence note in 'verifies:'. Left off here on purpose: a
      # project starts with requirements and without evidence, and a check
      # that goes red at your first requirement row teaches you to ignore
      # it. Arm it once the loop closes - the template repository does
      # (DEC-MTH-039).
"""

# Exact-string edits applied to the derived copy: every surviving sentence
# that points at stripped material goes, so the derived project carries no
# prose about files it does not have. A miss (the template moved) becomes a
# named warning, and the template's own test suite pins each anchor.
REPLACEMENTS = [
    ("00_documentation/01_projectvault/system_overview.md",
     "| [[ARC_Battery_Monitoring]] | Worked example: records battery telemetry and evaluates the log |\n",
     ""),
    ("00_documentation/01_projectvault/00_documentation_file_creation_and_conventions.md",
     "The worked example under\n"
     "[[ARC_Battery_Monitoring]] shows all of this in one thread. The validator",
     "The validator"),
    ("CLAUDE.md",
     "This repository carries **two** vaults, and the subject decides which one a note\n"
     "belongs in. `00_documentation/01_projectvault/` documents one project's\n"
     "engineering work. `.claude/01_methodvault/` documents this method and its tools —\n"
     "why the validator, the exporter, the schema and the templates work as they do,\n"
     "one DEC note per decision, starting at\n"
     "`.claude/01_methodvault/system_overview.md`. Both are held to the same rules by\n"
     "the same validator and audited separately in CI. A change to how a tool behaves\n"
     "is recorded there, not as an amendment to a log file.\n</context>",
     "</context>"),
    ("STRUCTURE.md",
     "the vault validator, the traceability exporter, its hooks and its test suite.",
     "the vault validator, the traceability exporter, and its hooks."),
    # STRUCTURE.md's skill pointer had an entry here for one reason: it cited
    # README.md#the-ai-layer, a section the generated project README does not
    # have. That section is METHOD.md#the-ai-layer now and METHOD.md ships, so
    # the citation resolves in a derived project and needs no rerouting.
    # METHOD.md carries exactly one template-only sentence - the pointer at the
    # skill's own test suite, which the strip list removes (DEC-MTH-042).
    ("METHOD.md",
     "\nIts own test suite lives next to it:\n\n"
     "```bash\nbash .claude/skills/mechatronics-docs/tests/run.sh\n```\n",
     ""),
    ("STRUCTURE.md",
     "That is *your project's* release trail. The template's own is\n"
     "[CHANGELOG.md](CHANGELOG.md) at the repository root — keep the two apart, or\n"
     "your project's first baseline inherits the template's history.",
     "That is *your project's* release trail."),
    ("STRUCTURE.md",
     "Everything GitHub reads rather than a person: `workflows/validate-vault.yml`\n"
     "runs the validator, the template vault audit, the export determinism check, the\n"
     "README traceability excerpt and the worked example on every push and pull\n"
     "request; `ISSUE_TEMPLATE/` holds the bug report and the method change proposal,\n"
     "with `config.yml` for the chooser; `pull_request_template.md` carries the\n"
     "checklist of gates a reviewer would otherwise re-derive.",
     "Everything GitHub reads rather than a person: `workflows/validate-vault.yml`\n"
     "runs the project vault audit and the export determinism check on every push\n"
     "and pull request."),
    ("STRUCTURE.md",
     "\n**In a project made from this template**, this directory arrives with it and\n"
     "describes the template rather than your project. Delete it, or keep the workflow\n"
     "and replace the templates with your own.\n",
     "\n"),
    ("IEC_61508_MAPPING.md",
     "no machine checks.** The worked example is re-run by CI and its\n"
     "negative control must fail. The export is diffed",
     "no machine checks.** The export is diffed"),
    ("IEC_61508_MAPPING.md",
     "The template vault is audited by path so the check cannot silently\nskip.",
     "The project vault is audited by path so the check cannot silently\nskip."),
    (".gitignore",
     "# The mechatronics-docs skill ships WITH this template - keep .claude/skills/\n"
     "# tracked. The method's own decision record is a vault and ships too, so\n"
     "# .claude/01_methodvault/ is re-included as well: git cannot re-include a file\n"
     "# under an excluded DIRECTORY, so both exceptions name the directory itself and\n"
     "# must stay below the '.claude/*' line. Only machine-local Claude Code state is\n"
     "# ignored.\n"
     ".claude/*\n"
     "!.claude/skills/\n"
     "!.claude/01_methodvault/\n",
     "# The mechatronics-docs skill ships WITH this project - keep .claude/skills/\n"
     "# tracked: git cannot re-include a file under an excluded DIRECTORY, so the\n"
     "# exception names the directory itself and must stay below the '.claude/*'\n"
     "# line. Only machine-local Claude Code state is ignored.\n"
     ".claude/*\n"
     "!.claude/skills/\n"),
]

# Cut a whole STRUCTURE.md section: [start marker, end marker).
CUTS = [
    ("STRUCTURE.md", "## .claude/01_methodvault", "## .github"),
    ("STRUCTURE.md", "## tools", "## AGENTS.md"),
]

RENAME_TARGET = "00_documentation/02_documents/README.md"
RENAMED_NAME = "00_documents_README.md"
RENAME_REFERENCE = (
    "STRUCTURE.md",
    "See `00_documentation/02_documents/README.md` for the full type table.",
    "See `00_documentation/02_documents/00_documents_README.md` for the full type table.")

WARN_PARAGRAPH = """\
## Known validator warning

`01_projectvault/README.md` and `02_documents/README.md` share the basename
`README`, and the validator resolves a wikilink by its basename alone, so it
reports one `duplicate-basename` WARN for this layout. It is advisory: keeping
both names is fine as long as no wikilink addresses either file as
`[[README]]`. Renaming `00_documentation/02_documents/README.md` (for example
to `00_documents_README.md`) is the only remedy.

"""

README_TEMPLATE = """\
# {name}

{name} is documented with the Single Source of Truth method of the
[obsidian-engineering-vault](https://github.com/jrmmhm/obsidian-engineering-vault)
template ({version}): one question per file, one place per fact, and a
validator that checks it mechanically.

## Where things live

- `00_documentation/01_projectvault/` — the Obsidian vault, the documentation
  itself. Start at its `README.md` for the reading order, and read
  `00_documentation_file_creation_and_conventions.md` before writing anything.
- [STRUCTURE.md](STRUCTURE.md) — which folder holds which kind of artifact.
- [METHOD.md](METHOD.md) — why the method is shaped this way: the failure it is
  built against, how the domains connect, and how to hand the result to
  somebody who was never taught it.
- `.claude/skills/mechatronics-docs/` — the validator, the traceability
  exporter and the Claude Code skill that enforce the method.

## Checking the vault

```bash
python3 .claude/skills/mechatronics-docs/validate_vault.py \\
        00_documentation/01_projectvault
```

ERRORs block, WARNs advise; a run that reports warnings alone still exits 0.
The same audit runs in CI on every push
(`.github/workflows/validate-vault.yml`). To hand the documentation to a
reviewer, export it:

```bash
python3 .claude/skills/mechatronics-docs/export_traceability.py \\
        00_documentation/01_projectvault --output-dir ../traceability
```

{minimal_paragraph}{warn_paragraph}## First steps

- Update the copyright line in `LICENSE`.
- Describe the project in
  `00_documentation/01_projectvault/00_project_summary.md`.
- Add your first module to
  `00_documentation/01_projectvault/system_overview.md`.
"""


def die(msg):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(2)


def method_version(source):
    """The template version this derivation is based on, from CHANGELOG.md.

    Reads the first released heading below [Unreleased]; when the Unreleased
    section carries content, the derivation is ahead of that release and the
    provenance line says so instead of claiming the tag.
    """
    changelog = source / "CHANGELOG.md"
    try:
        text = changelog.read_text(encoding="utf-8")
    except OSError:
        return "method version unknown"
    m = re.search(r"^## \[Unreleased\]\n(.*?)^## \[(\d+\.\d+\.\d+)\]",
                  text, re.S | re.M)
    if not m:
        return "method version unknown"
    unreleased, version = m.group(1), m.group(2)
    has_unreleased = any(line.strip() and not line.startswith("[")
                         for line in unreleased.splitlines())
    if has_unreleased:
        return f"method version {version} plus unreleased changes"
    return f"method version {version}"


def make_ignore(source, strip_set):
    src_resolved = source.resolve()

    def ignore(dirpath, names):
        rel = Path(dirpath).resolve().relative_to(src_resolved)
        ignored = set()
        in_obsidian = Path(dirpath).name == ".obsidian"
        for name in names:
            relname = name if str(rel) == "." else f"{rel.as_posix()}/{name}"
            if (name in JUNK_NAMES or relname in JUNK_RELPATHS
                    or relname in strip_set
                    or (in_obsidian and name not in OBSIDIAN_KEEP)):
                ignored.add(name)
        return ignored

    return ignore


def populated_parked_domains(source):
    """-> [(relative folder, [note names])] for parked domains carrying notes.

    Checked in the SOURCE, before anything is copied. The script copies a
    working tree rather than the git index, so a clone whose vault already
    documents something is a legal input - and parking such a domain would
    cut its notes out of the graph while the validator, which reads the
    vault by path, stays green. A refusal before the first write beats a
    half-derived target (DEC-MTH-041).

    Counted are the notes that would SURVIVE the derivation: the worked
    example lives in four of these six folders and is stripped by name, so
    counting it would make --minimal refuse in the template repository
    itself, which is the one clone every derivation starts from.
    """
    stripped = set(STRIP_PATHS)
    found = []
    for rel in MINIMAL_PARKED_DOMAINS:
        d = source / VAULT_REL / rel
        if not d.is_dir():
            continue
        notes = []
        for p in sorted(d.rglob("*.md")):
            if p.name.startswith("00_"):
                continue
            if p.relative_to(source).as_posix() in stripped:
                continue
            notes.append(p.name)
        if notes:
            found.append((rel, notes))
    return found


def park_minimal_domains(target, warnings):
    """Move the six non-starting domain folders out of the derived vault."""
    park = target / PARK_REL
    park.mkdir(parents=True, exist_ok=True)
    (park / PARK_README_NAME).write_text(PARK_README, encoding="utf-8")
    parked = []
    for rel in MINIMAL_PARKED_DOMAINS:
        src = target / VAULT_REL / rel
        if not src.is_dir():
            warnings.append(f"{rel}: expected domain folder not found in the "
                            "vault - template layout changed?")
            continue
        shutil.move(str(src), str(park / rel))
        parked.append(rel)
    return parked


def apply_text_edits(target, rename_readme, minimal, warnings):
    def edit(relpath, transform, what):
        path = target / relpath
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            warnings.append(f"{relpath}: not found, {what} not applied")
            return
        new = transform(text)
        if new is None:
            warnings.append(f"{relpath}: anchor text not found once, {what} "
                            "not applied - template layout changed?")
            return
        path.write_text(new, encoding="utf-8")

    for relpath, old, new in REPLACEMENTS + (MINIMAL_REPLACEMENTS if minimal else []):
        edit(relpath,
             lambda t, old=old, new=new:
                 t.replace(old, new, 1) if t.count(old) == 1 else None,
             f"removal of template-only prose ({old.splitlines()[0][:40]}...)")

    for relpath, start, end in CUTS:
        def cut(t, start=start, end=end):
            i, j = t.find(start), t.find(end)
            if i == -1 or j == -1 or j <= i:
                return None
            return t[:i] + t[j:]
        edit(relpath, cut, f"removal of the section {start!r}")

    if rename_readme:
        old_path = target / RENAME_TARGET
        if old_path.is_file():
            old_path.rename(old_path.with_name(RENAMED_NAME))
            relpath, old, new = RENAME_REFERENCE
            edit(relpath,
                 lambda t, old=old, new=new:
                     t.replace(old, new, 1) if t.count(old) == 1 else None,
                 "update of the renamed README reference")
        else:
            warnings.append(f"{RENAME_TARGET}: not found, nothing to rename")


def run_validator(target):
    """Run the derived copy's validator on the derived vault.

    Returns (returncode, output, errors, warnings) with counts parsed from
    the summary line, or None counts when the summary is unreadable.
    """
    proc = subprocess.run(
        [sys.executable, str(target / VALIDATOR_REL), str(target / VAULT_REL)],
        capture_output=True, text=True)
    output = (proc.stdout + proc.stderr).strip()
    m = re.search(r"--\s+(\d+) error\(s\), (\d+) warning\(s\)", output)
    if not m:
        return proc.returncode, output, None, None
    return proc.returncode, output, int(m.group(1)), int(m.group(2))


def main():
    parser = argparse.ArgumentParser(
        description="Derive a clean project from this template.")
    parser.add_argument("target", help="directory to create the project in "
                        "(must not exist, or be an empty directory)")
    parser.add_argument("--name", help="project name for the generated "
                        "README (default: the target directory's name)")
    parser.add_argument("--minimal", action="store_true",
                        help="start the vault with REQ, ARC and TAE and move "
                        "the other six domain folders to "
                        f"{PARK_REL}, where they wait until the project grows "
                        "into them")
    parser.add_argument("--rename-docs-readme", action="store_true",
                        help="rename 00_documentation/02_documents/README.md "
                        f"to {RENAMED_NAME}, resolving the known "
                        "duplicate-basename validator warning")
    args = parser.parse_args()

    if sys.version_info < (3, 8):
        die("Python 3.8 or newer is required")

    source = Path(__file__).resolve().parent.parent
    if not (source / VAULT_REL).is_dir() or not (source / VALIDATOR_REL).is_file():
        die(f"{source} does not look like the template repository - run the "
            "script from inside a clone (tools/new_project.py)")

    if args.minimal:
        populated = populated_parked_domains(source)
        if populated:
            listed = "; ".join(f"{rel}: {', '.join(names)}"
                               for rel, names in populated)
            die("--minimal would park domain folders that already carry "
                f"notes in {source} - {listed}. Parking them would take "
                "those notes out of the vault the validator reads. Derive "
                "without --minimal, or move the notes out of the template "
                "clone first.")

    target = Path(args.target)
    if target.exists():
        if not target.is_dir():
            die(f"target {target} exists and is not a directory")
        if any(target.iterdir()):
            die(f"target {target} is not empty - refusing to write into it")
    real_source = os.path.realpath(source)
    real_target = os.path.realpath(target)
    if (real_target == real_source
            or real_target.startswith(real_source + os.sep)
            or real_source.startswith(real_target + os.sep)):
        die(f"target {target} overlaps the template clone at {source}")

    name = args.name or target.resolve().name
    version = method_version(source)

    warnings = []
    strip_set = set(STRIP_PATHS)
    for rel in STRIP_PATHS:
        if not (source / rel).exists():
            warnings.append(f"{rel}: expected template path not found - "
                            "template layout changed?")

    target_pre_existed = target.exists()
    parked = []
    try:
        shutil.copytree(source, target, ignore=make_ignore(source, strip_set),
                        dirs_exist_ok=True)
        (target / ".github/workflows/validate-vault.yml").write_text(
            DERIVED_WORKFLOW, encoding="utf-8")
        # Inside the try with everything else: a move that fails half way
        # through must leave no target behind, or the non-empty guard refuses
        # the next run over a tree this script wrote.
        if args.minimal:
            parked = park_minimal_domains(target, warnings)
        apply_text_edits(target, args.rename_docs_readme, args.minimal, warnings)
        warn_paragraph = "" if args.rename_docs_readme else WARN_PARAGRAPH
        (target / "README.md").write_text(
            README_TEMPLATE.format(
                name=name, version=version, warn_paragraph=warn_paragraph,
                minimal_paragraph=MINIMAL_PARAGRAPH if args.minimal else ""),
            encoding="utf-8")
    except BaseException:
        # Never leave a half-derived target that the non-empty check would
        # then refuse: remove what this run created, and only that.
        if target_pre_existed:
            for child in target.iterdir():
                shutil.rmtree(child) if child.is_dir() else child.unlink()
        else:
            shutil.rmtree(target, ignore_errors=True)
        print(f"derivation failed - removed the partial target {target}",
              file=sys.stderr)
        raise

    expected_warns = 0 if args.rename_docs_readme else 1
    rc, output, errors, warns = run_validator(target)

    print(f"Derived project '{name}' at {target}   ({version})")
    print()
    print("Removed (template-repo-only material and the worked example):")
    for rel in STRIP_PATHS:
        print(f"  - {rel}")
    print()
    print("Rewritten for a derived project: .github/workflows/validate-vault.yml")
    print("(project vault audit + export determinism; the template-only steps"
          " are gone,")
    print("so CI is green on first push), README.md (generated), and the "
          "template-only")
    print("prose in CLAUDE.md, STRUCTURE.md, IEC_61508_MAPPING.md, .gitignore "
          "and the vault.")
    if args.rename_docs_readme:
        print(f"Renamed {RENAME_TARGET} -> {RENAMED_NAME}.")
    if parked:
        print()
        print("Minimal profile: the vault starts with REQ, ARC and TAE. Moved "
              f"to {PARK_REL}/,")
        print("where each folder waits with its README and file template:")
        for rel in parked:
            print(f"  - {rel}")
        print("Move a folder back into the vault when its domain joins - the "
              "vault's README")
        print("says when that typically is.")
    print()
    print("Copied from the working tree, not the git index - untracked files "
          "travel along.")
    if warnings:
        print()
        print("WARNINGS - review these by hand:")
        for w in warnings:
            print(f"  ! {w}")
    print()
    print("Still yours to do:")
    print("  - update the copyright line in LICENSE")
    print("  - describe the project in "
          "00_documentation/01_projectvault/00_project_summary.md")
    print("  - add your first module to "
          "00_documentation/01_projectvault/system_overview.md")
    print("  - git init && git add -A && git commit  (no git required until "
          "here)")
    if not args.rename_docs_readme:
        print("  - decide the README basename collision (see 'Known validator"
              " warning'")
        print("    in the generated README.md)")
    print()
    print("Validator check of the derived vault:")
    print(output)
    print()

    if expected_warns:
        predicted = "0 error(s), 1 warning(s) - the known duplicate-basename WARN"
    else:
        predicted = "0 error(s), 0 warning(s)"
    ok = (rc == 0 and errors == 0 and warns == expected_warns
          and (expected_warns == 0 or "duplicate-basename" in output))
    if ok:
        print(f"Verified: matches the predicted state ({predicted}).")
        return 0
    print(f"DEVIATION: predicted {predicted}, but the validator "
          f"{'crashed' if rc not in (0, 1) or errors is None else 'reported the output above'} "
          f"(exit {rc}).", file=sys.stderr)
    print(f"The target {target} was kept for inspection - remove it before "
          "re-running.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
