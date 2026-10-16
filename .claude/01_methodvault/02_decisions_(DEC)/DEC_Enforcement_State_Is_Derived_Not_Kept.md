---
domain: DEC
id: DEC-MTH-055
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Draft

## Context

**Which state the enforcement layer derives instead of keeping by hand.**
Two values were kept, and both had drifted from what they claimed. The stop
gate counted its blocks per session in a state file that was never reset,
so after two blocks it stayed advisory for the rest of a long session. And
`--check-install` printed a revision that was a hand-bumped constant, which
was not bumped for four behaviour changes - so two different validators
reported the same revision, and the one comparison built on that line
declared them equal.

## Options

- A: keep both and add the missing maintenance - reset the counter, add the
  bump to the release checklist.
- B: derive both - the block decision from the Stop payload Claude Code
  sends, the revision from the bytes of the files that decide behaviour.

## Decision

Option B. Realization details, and the residual of deciding from the
payload, are added when the change lands.

## Justification

- To be completed.

## Consequences

- To be completed.
