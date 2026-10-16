---
domain: DEC
id: DEC-MTH-054
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Accepted

## Context

**What the validator does with a finding its reader already knows about.**
Three channels repeated the same known state. The full audit of this
repository's method vault printed 29 `length` WARNs that the CI workflow
accepted in a comment - an acceptance with no place in the vault, so every
audit repeated it. `req-uncovered` ignored a deferral written exactly the
way the skill prescribes, an allocation row whose status says the
requirement is blocked, with a DEC saying why. The post-write hook
re-injected every WARN a legacy file carried at git HEAD on every edit of
that file - 557 characters per edit of one measured note - and the stop
report appended the same vault-wide advisory block at every turn end.

## Options

- A: a baseline file per vault listing accepted findings, the pattern of
  ESLint bulk suppressions and the PHPStan and detekt baselines.
- B: the acceptance in the frontmatter of the file it concerns, with a
  reason, and the known state of a session held in the session state the
  hooks already keep.
- C: leave it to the reader.

## Decision

Option B, in four parts.

- **A file accepts WARNs in its own frontmatter**: `validator-accept`
  names the codes, `validator-accept-reason` says why. Only codes on a
  closed list in `vault_schema.json` (`validator_accept`) can be accepted;
  an ERROR never is, and an entry outside the list is reported as
  `accept-invalid`. Without a reason nothing is in force and
  `accept-reason-missing` says so. A template accepts nothing, because its
  frontmatter is copied into every file made from it. An accepted finding
  is not printed; the full audit prints one line above its summary
  counting what it did not print.
- **A requirement whose every allocation row carries a deferral status** -
  Blocked, Deferred or TBD, exactly or followed by a qualifier - leaves
  `req-uncovered` and is counted in the same line. Every row and not any
  row: one deferred row beside an Approved one leaves the requirement open.
  The values are data, `deferral_status_values` of the coverage rule in the
  schema.
- **The post hook shows a WARN only when it is new since git HEAD**, with
  one line counting the known ones it did not repeat. Numbers in a message
  are folded before the comparison, so a line count that moves with the
  edit does not make a known WARN new.
- **The stop report shows the vault-wide block on a session's first
  report and whenever it changed**, otherwise one line saying it is
  unchanged. The comparison is a digest over every finding without line
  numbers, taken before the report's line cap.

## Justification

- The acceptance sits where the reader of the file sees it, and where a
  review of the file sees it change. A baseline file is a second store that
  drifts from the files it describes.
- The list of acceptable codes is closed on purpose. A code whose severity
  depends on the run - `link-unresolved` is a WARN in the post hook and an
  ERROR at the stop gate - or a vault-wide code that speaks for every
  requirement of a file would let one line hide a defect nobody has seen.
  The adversarial review of this change found exactly those two paths.
- Applied to this repository's method vault, the 29 accepted records and
  their reason replace the CI comment: the audit prints no warning and one
  count line.

## Consequences

- Residual: an acceptance that no longer suppresses anything is not
  reported. Pruning stale entries is left to the reader of the file.
- Residual: the hooks filter accepted findings silently; only the full
  audit prints the count line.
- A copy of the validator older than this decision reports the two new
  frontmatter fields as `frontmatter-undeclared` until it is updated.
- The noise cut these mechanisms complete is
  [[DEC_The_Validator_Reports_What_Can_Be_Acted_On]].
