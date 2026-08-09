---
domain: DEC
id: DEC-MTH-039
created: 2026-08-08
last-verified: 2026-08-08
---
Date: 2026-08-08
Status: Accepted
Corrected by: [[DEC_The_Export_Draws_The_Graph_It_Reads]] — residual 1 is closed

## Context

[[DEC_Coverage_Is_Decided_On_The_Graph]] (DEC-MTH-026) closed the loop the
method promises — an allocation row names the requirement AND a TAE names
it in `verifies:` — and left it at WARN. The reason is recorded there and
still holds: the check cannot tell a requirement nobody has verified yet
from one whose vault never adopted the `verifies:` convention, and an
ERROR would have turned that ambiguity into a blocked working session.

The exporter answers the same question more precisely, in five named gap
classes, and answers it about nothing that blocks: `export_traceability.py`
states as a design property that "coverage gaps are data and never change
the exit code". So the layer that prevents drift accepts what the layer
that reports refuses to accept, which is the gap issue #50 named and
issue #68 proposes to close on the CI side alone (Alt B of the #50
review).

Measured on the shipped template vault before anything was armed
(2026-08-08):

| | value |
| --- | --- |
| requirements in the graph | 3 |
| proven | 3 |
| `not-allocated` | 0 |
| `no-evidence-note` | 0 |
| exporter findings | 0 |

## Options

- **A — A CI step parsing `traceability.json` in inline Python.** Rejected:
  it writes "what counts as a blocking gap" a second time, in YAML, where
  the suite cannot reach it, and copies that logic into every derived
  project. The same second-definition drift [[DEC_One_Cell_Splitter_For_Both_Tools]],
  [[DEC_One_Fence_Definition_For_Both_Tools]] and
  [[DEC_One_Reverse_Key_Derivation_For_Both_Readers]] each removed.
- **B — A `--fail-on <classes>` option on the exporter, armed by CI.**
  Chosen.
- **C — An assertion inside `tests/run.sh`.** Rejected, though cheapest:
  `tools/new_project.py` strips `tests/` from a derived project, so the
  rule would reach no vault but this one, and the assertion it would join
  pins a literal count (`requirements: 3`) that any honest growth of the
  vault breaks. A snapshot is not a rule.
- **D — Leave it reported and unblocked.** Rejected by issue #68: CI sees
  the whole vault at once and pays no session time for the answer.

## Decision

**The exporter gains `--fail-on`, and CI arms it for `not-allocated` and
`no-evidence-note` on `00_documentation/01_projectvault`.** Without the
option nothing changes: gaps stay data, the exit code stays 0, and the
local validator keeps `req-uncovered` at WARN.

**The scope boundary is the `verifies:` convention, not template versus
derived.** DEC-MTH-026 reason 1 is the reason `no-evidence-note` may be
armed here at all: this repository authors its own template vault and
guarantees that its evidence notes carry `verifies:`. A vault whose
conventions this repository does not own gets the mechanism and not the
arming — `tools/new_project.py` names the option in the workflow it
generates and leaves it off. Measured: a freshly derived project exports
0 requirements, so arming it there would be silent until the author's
first requirement row and red from that moment until a TAE exists.

**An armed run against a graph carrying no requirement is a failure, not
a pass.** `assess()` iterates the requirements of the graph, so an empty
graph yields no gaps and any gate over it is a check that cannot fail —
the shape `vault_schema.json` calls "the one output this tool must not
produce" and the shape the workflow's worked-example step already ships a
negative control against.

**A name the class list does not contain is refused before any work, with
exit 2 and the valid names printed.** A typo that armed nothing while
reporting green would be the same switched-off gate in a different
costume.

## Justification

- One definition, in the tool the suite tests and every project copies,
  rather than two — the precedents named under option A.
- Exit code 1 was free: `main()` returned only 0 and 2, argparse errors
  exit 2, and the crash wrapper maps everything else to 2.
- `sys.exit(1)` is recorded as **rejected** in
  [[DEC_Two_Folders_One_Domain_Is_A_Finding]] option D, and that rejection
  stands unamended: it is about a *finding*, and this is about a *gap*.
  Findings still never change the exit code. `SKILL.md`'s "the exporter
  never blocks a turn" also stands — a CI run is not a turn, and no hook
  invokes the exporter.
- The default path is the one every existing caller uses, so nothing that
  runs today changes behaviour.

## Consequences

### Realization

- `export_traceability.py` — `--fail-on`, validated against `GAP_CLASSES`
  immediately after `parse_args`; the scan runs after the artifacts are
  written, because a run that blocks must hand over the evidence of why
- `.github/workflows/validate-vault.yml` — one step at the end of the file
- `tools/new_project.py` — a comment in `DERIVED_WORKFLOW` naming the
  option; the workflow itself unarmed
- `tests/run.sh` — 17 assertions, 351 to 368. The two positive ones carry
  negative halves, because the fixture's gap sets make them pass without:
  REQ-COV-006 is `not-allocated` only, REQ-COV-005 is `no-evidence-note`
  only, so "names 006" alone also passes against an implementation that
  ignores the armed set and prints every gap it finds
- `CONTRIBUTING.md`, `README.md`, `IEC_61508_MAPPING.md`, `SKILL.md`,
  `vault_schema.json`, `CHANGELOG.md` — five places asserted that nothing
  here blocks on a coverage gap, and one of them had to stop asserting it

Observed at the real entry point, with the command the workflow runs:

    template vault, armed:              exit 0
    same vault, TAE 'verifies:' removed: exit 1
        "no-evidence-note: no evidence note names this requirement in
         'verifies'  3 requirement(s): REQ-BAT-001, REQ-BAT-002, REQ-BAT-003"
    same vault, allocation cells cleared: exit 1
        "not-allocated: no allocation row names this requirement
         3 requirement(s): REQ-BAT-001, REQ-BAT-002, REQ-BAT-003"

Both failing runs wrote all five artifacts. That is the point of scanning
after the writers rather than before them.

### A premise corrected on the record

The brief for this change said derived projects "copy this workflow".
They do not. `tools/new_project.py` writes `DERIVED_WORKFLOW`, a literal
of its own, so a step added to the template's workflow reaches no derived
project unless it is added there as well. Anything reasoning from the
copy assumption is reasoning about a mechanism this repository does not
have.

### Accepted residuals

1. **`--formats` kept the hazard `--fail-on` closes.** Measured: `--formats
   jsonn` exits 0 with an empty output directory — closed 2026-08-09, above.
2. **`not-allocated` was already reachable from the suite.** The existing
   template-vault assertion pins `proven: 3`, and `proven` folds that
   class in. The class genuinely new to the blocking path is
   `no-evidence-note`. Both stay armed: the suite pins a count, the step
   states the rule.
