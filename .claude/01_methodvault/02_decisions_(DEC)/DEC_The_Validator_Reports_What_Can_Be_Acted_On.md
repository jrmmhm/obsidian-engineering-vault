---
domain: DEC
id: DEC-MTH-053
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Draft

## Context

**Which findings `validate_vault.py` stops emitting, and why none of them
was a defect report.** Run in full mode over six real vaults on 2026-10-16,
the validator printed 94 WARN lines and no ERROR. A classification of every
line (research report R6 of batch skills-1) found four of them true and
actionable; the rest were false positives or findings their owners had
already decided never to act on. A channel that is wrong most of the time
teaches its reader to skip it, and the reader here is an agent whose context
is a budget.

Five sources made most of the noise. The name index walked the file system
instead of the repository, so a vault whose index root is a home directory
indexed plugin caches and session memories. `duplicate-basename` reported
every shared stem, including the two README files every derived vault ships
and nobody links. The link budget counted the table rows the templates
mandate - one allocation row per requirement, one source cell per row - and
links of a note to itself; `link-repeat` fired on the same rows and was
actionable in none of its ten measured lines. `req-uncovered` repeated its
rationale once per requirement. And `path-missing` raised an ERROR for a
gitignored path that cannot exist on a fresh checkout, which one project
answered by rewriting its paths until the check no longer saw them.

## Options

- A: keep every rule and lower the noise by documentation - tell readers
  which findings to ignore.
- B: delete the noisy rules outright.
- C: keep each rule's defect class and narrow what it reads - the
  repository instead of the disk, a linked name instead of any name, prose
  links instead of table rows, one line per file instead of one per
  requirement, a WARN where the checkout cannot know.

## Decision

Option C, except for `link-repeat`, which is deleted: none of its measured
findings was actionable and the remaining link budget covers the carpet it
was meant to catch. Realization details are added when the change lands.

## Justification

- To be completed with the measured before and after counts per vault.

## Consequences

- To be completed: the documents and tests that change with each rule.
