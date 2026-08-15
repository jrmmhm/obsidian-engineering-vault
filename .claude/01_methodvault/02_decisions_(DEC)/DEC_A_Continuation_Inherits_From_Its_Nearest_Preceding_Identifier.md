---
domain: DEC
id: DEC-MTH-046
created: 2026-08-15
last-verified: 2026-08-15
---
Date: 2026-08-15
Status: Accepted

## Context

`expand_requirement_cell` reads the three requirement spellings an
allocation cell actually contains: full identifiers, a range, and a
continuation number that inherits prefix and scope ("ANF-BAK-008, 027,
028"). Since [[DEC_Reading_The_Vault_As_A_Graph]] (DEC-MTH-010) the
continuation loop ran AFTER the full-identifier loop had completed, so
every continuation inherited from the LAST full identifier of the cell
rather than from the one before it.

In a cell that changes scope the expansion is silently wrong:
`'ANF-BAK-001, -010, -011, ANF-PUB-011'` returned
`['ANF-BAK-001', 'ANF-PUB-010', 'ANF-PUB-011']` — ANF-BAK-010 and
ANF-BAK-011 lost their allocation without a finding, and ANF-PUB-010
gained one it was never given. Both violate the exporter's stated
property that nothing it can prove it lost is lost silently, and the
second invents data outright. The defect was measured on 2026-08-15
against a production vault's live index; the vault's own "one scope per
allocation cell" authoring convention had masked it.

## Options

- **A — Keep last-of-cell and document it as the rule.** Rejected: the
  corpus spellings read left to right, and no author writing
  "BAK-001, -010" means the -010 to belong to an identifier they have
  not written yet. Documenting a misreading does not stop it inventing
  allocations.
- **B — One positional scan over both shapes (chosen).** A single
  alternation of FULL_ID_RE and CONTINUATION_RE walks the cell in
  order; the scope a continuation inherits is the last full identifier
  the scan has passed. The consumed-offset bookkeeping of the two-loop
  version disappears with the second loop.
- **C — Two loops, but track positions.** Merge the two match lists by
  offset while keeping both regexes separate. Same behavior as B with
  more state; rejected as the strictly noisier spelling of it.

## Decision

Option B. A continuation inherits prefix and scope from its nearest
preceding full identifier. A continuation standing before the first
full identifier of the cell inherits nothing and is returned as an
unresolved fragment ("010 (no full identifier precedes it)") — under
the old code it resolved backwards against a later identifier, which is
the same invention in the other direction.

## Justification

- The scan order is the reading order; "nearest preceding" is the only
  rule under which every corpus spelling means what its author wrote.
- Expansion stays offered, never asserted: a fragment with no scope to
  inherit is reported through `export-unresolved-requirement`, not
  guessed at and not dropped.
- Single-scope cells — every cell the fixture vaults and the authoring
  convention produce — expand exactly as before; fixture 7's counts
  (7 requirements, 4 proven, 18 edges) are unchanged.

## Consequences

- Vaults carrying mixed-scope cells can newly gain or lose
  `req-uncovered`, `not-allocated` and `no-evidence-note` results:
  those findings were computed from misresolved allocations before.
- Residual, named rather than fixed here: the range path still returns
  on the first range it finds, dropping any further identifiers in the
  same cell silently — the same defect class, one shape over. A cell of
  ONLY continuations still takes the early return and is reported as
  `export-allocation-without-requirement`, so the two fragment shapes
  surface under two codes.
- `tests/run.sh` pins the mixed-scope cell, both single-scope corpus
  spellings and the leading fragment directly against
  `expand_requirement_cell`.
