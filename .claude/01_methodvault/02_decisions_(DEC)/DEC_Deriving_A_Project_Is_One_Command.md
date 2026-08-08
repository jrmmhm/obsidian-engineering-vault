---
domain: DEC
id: DEC-MTH-036
created: 2026-08-08
last-verified: 2026-08-08
---
Date: 2026-08-08
Status: Accepted

## Context

Deriving a real project from this template was a prose checklist spread
over four files: the README's deletion path for the worked example, the
blockquotes in `CONTRIBUTING.md` and `CHANGELOG.md` naming themselves and
`.github/` as template-only, and the `STRUCTURE.md` sections doing the
same for `.claude/01_methodvault/`. Every step of that checklist was a
chance to do it half (issue #76), and one omission was guaranteed rather
than possible: `tests/run.sh` asserts the template's own worked example
(`requirements: 3  proven: 3`) and fails loudly when the method vault is
missing, and the CI workflow runs that suite as its first step — so a
derived project that kept `.github/` unmodified pushed straight into red
CI (issue #85).

## Options

- **A — Keep the checklist, fix only the CI assertions.** Rejected: it
  documents the problem instead of solving it, which is the state issue
  #76 names as the defect.
- **B — An in-place script that strips the clone it runs in.** Rejected:
  irreversible on mistake, leaves the clone unusable for a second
  derivation, and breaks the rule that a tool never deletes outside a
  target it created.
- **C — Make the test suite template-aware so it skips template-only
  assertions in a derived project.** Rejected: a suite that silently
  asserts less is the switched-off-gate pattern this repository exists
  to prevent — the loud failure on a missing template vault was added
  deliberately after that guard once skipped in silence.
- **D — A copy-and-strip script `tools/new_project.py` that copies the
  template into a fresh target, strips template-only material and the
  worked example, rewrites the workflow to the two steps that hold in a
  derived project, and strips itself.** Chosen.

## Decision

Option D. The strip list is assembled from what the repository already
says about itself, not decided fresh; the derived workflow keeps the
project vault audit and the export determinism check; the
duplicate-basename README collision is surfaced with a default of
keeping the shipped state and a `--rename-docs-readme` flag; the script
ends by running the derived copy's validator and refusing to call the
derivation successful unless the output matches its own prediction.

## Justification

- One command replaces a checklist whose every step could be done half.
- A derived project's first push is green (closes issue #85) without the
  template's own CI asserting anything less than before.
- Copy-then-strip is reversible by deleting a directory the script
  itself created; the clone is never modified.

## Consequences

- `tools/` is a new top-level directory that ships in the template and
  never in a derived project — the script strips it.
- The script embeds knowledge of the template's layout; an exact-string
  patch that stops matching is reported as a warning by the script and
  caught as a test failure in the template's own CI.
- Realized as `tools/new_project.py` (stdlib only), pinned by the
  derivation block at the end of the skill's test suite: strip list,
  rewritten workflow, leftover-reference greps, the predicted validator
  states of both the default and the `--rename-docs-readme` path, and
  the untouched refusal of a non-empty target.
