<!--
  In a project made from this template, this file describes the template and not
  your project. Delete the .github directory or replace it with your own.
-->

## What this changes

<!-- One paragraph: what behaves differently after this, and why it had to. -->

## What kind of change

- [ ] **Tool fix** — a tool stops being wrong about an input it already had an opinion on
- [ ] **New capability** — existing vaults stay clean
- [ ] **Method change** — a domain definition, a required template section, the field schema, an identifier rule, a typed relation, a validator rule's severity, or an exporter field. See [CONTRIBUTING.md](../CONTRIBUTING.md#versioning-what-a-breaking-change-means-here).
- [ ] **Documentation only**

## Checks

- [ ] `bash .claude/skills/mechatronics-docs/tests/run.sh` → `ALL TESTS PASSED`
- [ ] `python3 .claude/skills/mechatronics-docs/validate_vault.py 00_documentation/01_projectvault` → `0 error(s)` (the one `duplicate-basename` WARN is the known state)
- [ ] New behaviour is pinned by an assertion in `tests/run.sh`; a fix carries the assertion that would have caught it
- [ ] Every document that asserted the old behaviour is corrected in this pull request
- [ ] Tool behaviour changed, or a design was chosen over an alternative → an amendment in `.claude/skills/mechatronics-docs/DECISIONS.md`
- [ ] The method changed → a `CHANGELOG.md` entry under `Unreleased` naming what it costs a derived project
- [ ] *If this touches `00_documentation/01_projectvault/`:* the vault files were written with `Edit`/`Write`/`MultiEdit`, never through a shell rewrite — the hooks see nothing else

## Evidence

<!--
  The tail of the test run. For a tool change, also the before/after at the real
  entry point: what the validator or the exporter said on the same vault, first
  without your change and then with it.
-->
