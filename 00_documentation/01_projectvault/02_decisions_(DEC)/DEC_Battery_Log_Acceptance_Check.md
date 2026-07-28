---
domain: DEC
created: 2026-07-28
last-verified: 2026-07-28
id: DEC-BAT-001
---
Date: 2026-07-28
Status: Accepted

## Context

The module [[ARC_Battery_Monitoring]] (ARC-BAT-001) produces telemetry
logs whose acceptance criteria are stated in
[[REQ_Battery_Monitoring (BAT)]] (REQ-BAT-000). Those criteria have to be
decided per log, repeatably, by somebody who did not record the log. The
question this decision answers is how that check is performed, not what
the criteria are.

The constraint that shapes the answer: this project already runs its
vault validator and its continuous integration without any third-party
runtime dependency. A check that needs an installed data-analysis stack
would be the only step in the project that does.

## Options

- Option A — Inspect the log manually in a spreadsheet. No tooling, no
  maintenance, immediately available.
- Option B — A small evaluation script using only the Python standard
  library, kept under `20_software/`.
- Option C — A notebook built on a data-analysis library, kept alongside
  the processed data.

## Decision

Option B.

## Justification

- Option A does not survive repetition: a human deciding the same three
  criteria by eye produces a different verdict on a bad day, and leaves
  no output that can be quoted as evidence.
- Option C would introduce the project's first runtime dependency for a
  check that needs arithmetic and nothing else, and a notebook records
  its result in a form that is awkward to diff and easy to re-run
  accidentally over the evidence it is supposed to preserve.
- Option B prints one verdict line per requirement ID, so the evaluation
  output can be quoted verbatim into a verification note without a human
  re-deriving which line proves which requirement.
- The same script can be pointed at a deliberately altered log, which is
  what makes the check falsifiable rather than decorative.

## Consequences

- The evaluation script and the collector are realized as described in
  [[IMP_Battery_Log_Evaluation]] (IMP-BAT-001).
- The operating range the voltage criterion tests against is owned by
  [[IFC_PWR_DC_LiPo_Pack]] (IFC-BAT-001); the script mirrors it and names
  that note as the source, so the contract stays single-source.
- Continuous integration runs the evaluator against the committed log, so
  the evidence quoted in [[TAE_Battery_Log_Acceptance]] (TAE-BAT-001)
  cannot silently stop being reproducible.
