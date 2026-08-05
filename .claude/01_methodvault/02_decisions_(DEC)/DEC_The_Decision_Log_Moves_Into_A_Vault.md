---
domain: DEC
id: DEC-MTH-032
created: 2026-08-05
last-verified: 2026-08-05
---
Date: 2026-08-05
Status: Accepted

## Context

The decision record of this method's own tooling was written beside the vault
format rather than in it: one appended file, 5100 lines, 31 records, at
`.claude/skills/mechatronics-docs/DECISIONS.md`. Under this repository's own
rules that file breaks three of them at once — the 400-line ERROR, "one
decision per DEC file", and the `superseded-by` relation that the schema
declares for exactly this domain. A method that is not applied to its own
hardest document is a method nobody has evidence for, and 31 real decisions
with real cross-corrections are the largest scale test this format can be
given. Issue #53 asks for that test to be run.

## Options

- Option A — leave the appended log and add a generated table of contents.
  One file touched, zero fidelity risk, and the scale test does not happen.
- Option B — split the log into 31 plain Markdown files beside the skill,
  with no frontmatter, no domain folders and no validator. Achieves
  findability, and again declines the test the issue asks for.
- Option C — migrate the log into a second vault, `.claude/01_methodvault/`,
  audited by this repository's own validator in CI, with the appended file
  reduced to a forwarding map.

## Decision

Option C.

## Justification

_Filled in Phase 5 together with the Realization, once the migration has been
carried out and the audit result is measured rather than predicted._

## Consequences

_Filled in Phase 5._
