---
domain: DEC
id: DEC-MTH-054
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Draft

## Context

**What the validator does with a finding its reader already knows about.**
Three channels repeated the same known state. The full audit of this
repository's method vault printed 29 `length` WARNs that the CI workflow
accepts in a comment - an acceptance with no place in the vault, so every
audit repeated it. `req-uncovered` ignored a deferral written exactly the
way the skill prescribes, an allocation row whose status says the
requirement is blocked. The post-write hook re-injected every WARN a legacy
file carried at git HEAD on every edit of that file, and the stop report
appended the same vault-wide advisory block at every turn end.

## Options

- A: a baseline file per vault listing accepted findings, the pattern of
  ESLint bulk suppressions and the PHPStan and detekt baselines.
- B: the acceptance in the frontmatter of the file it concerns, with a
  reason, and the known state of a session held in the session state the
  hooks already keep.
- C: leave it to the reader.

## Decision

Option B. An accepted finding is not printed; the audit prints one count
line instead. An ERROR is never acceptable. The hooks show a WARN only when
it is new since git HEAD, and the vault-wide block only when it changed.
Realization details are added when the change lands.

## Justification

- To be completed.

## Consequences

- To be completed.
