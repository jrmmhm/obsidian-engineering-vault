#!/usr/bin/env python3
"""Derive a clean project from the obsidian-engineering-vault template.

    python3 tools/new_project.py <target-dir> [--name NAME] [--rename-docs-readme]

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
    ("STRUCTURE.md",
     "See the [README](README.md#the-ai-layer) for how to use it, with or without\nClaude Code.",
     "See `.claude/skills/mechatronics-docs/SKILL.md` for how to use it, with or\nwithout Claude Code."),
    ("STRUCTURE.md",
     "That is *your project's* release trail. The template's own is\n"
     "[CHANGELOG.md](CHANGELOG.md) at the repository root — keep the two apart, or\n"
     "your project's first baseline inherits the template's history.",
     "That is *your project's* release trail."),
    ("STRUCTURE.md",
     "Everything GitHub reads rather than a person: `workflows/validate-vault.yml`\n"
     "runs the validator, the template vault audit, the export determinism check and\n"
     "the worked example on every push and pull request; `ISSUE_TEMPLATE/` holds the\n"
     "bug report and the method change proposal, with `config.yml` for the chooser;\n"
     "`pull_request_template.md` carries the checklist of gates a reviewer would\n"
     "otherwise re-derive.",
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

{warn_paragraph}## First steps

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


def apply_text_edits(target, rename_readme, warnings):
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

    for relpath, old, new in REPLACEMENTS:
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
    try:
        shutil.copytree(source, target, ignore=make_ignore(source, strip_set),
                        dirs_exist_ok=True)
        (target / ".github/workflows/validate-vault.yml").write_text(
            DERIVED_WORKFLOW, encoding="utf-8")
        apply_text_edits(target, args.rename_docs_readme, warnings)
        warn_paragraph = "" if args.rename_docs_readme else WARN_PARAGRAPH
        (target / "README.md").write_text(
            README_TEMPLATE.format(name=name, version=version,
                                   warn_paragraph=warn_paragraph),
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
