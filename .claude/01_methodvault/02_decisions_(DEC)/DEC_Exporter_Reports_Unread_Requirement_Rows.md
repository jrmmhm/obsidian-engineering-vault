---
domain: DEC
id: DEC-MTH-019
created: 2026-08-04
last-verified: 2026-08-05
---
Date: 2026-08-04
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-04d — The exporter reports the requirement rows it never read (Accepted)".

## Context

Issue #34, residual 4 of amendment 2026-08-04b. `_report_unbound` is
called from the ARC loop of `build_graph` and from nowhere else, so a
requirement table the export did not read leaves no trace at all. That
contradicts `table_bindings.binding_discovery.unbound_table` ("an empty
graph is never silent") and this module's own docstring ("a table in no
recognised section … is a row in the export, never an absence from it").

Two corrections to that residual, both measured: `REQ_persona_voice.md`
carries **seven** five-column tables and one two-column source map, not
six; and the file is not silent today — `export-no-scope` names it, one
of that vault's seven. What is silent is its 34 requirement rows.

Measured across the nine vault roots on this machine: 376 requirement
rows exist in REQ files, **112 of them never reach the graph**. 78 sit
in homelab, 34 in nativclaw; template, PMDE and Bachelor_Bruder lose
none of their 3, 93 and 34.

## Options

**What to report.**

- **A — extend the ARC check to REQ**, which is what the issue proposes
  and what this session first planned. Rejected on measurement, twice
  over. It reports 34 of the 112 rows: all 78 homelab rows sit *inside*
  the bound `## Kontext` section, in its second to tenth table, which
  `bound_tables` stops before and `sections_with_tables` never yields
  ("only the first table of a section binds"). It also says something
  false — "sits in no section this project's templates declare" is wrong
  whenever an incidental table merely precedes the requirement table in
  a section that is declared, and the bound REQ section is the prose
  section in all nine vaults, the one most likely to carry a glossary or
  a revision history. A two-column glossary above the requirement table
  is enough to trigger the false wording.
- **B — extend it to every ingested domain**, the issue's first delivery
  item read at face value. Rejected: 663 new findings across the same
  nine roots (PMDE 131, homelab 242, nativclaw 269, realitypatches 20,
  and one in the shipped template vault, which is under a hard
  `findings: 0` assertion). No binding exists for those seven domains,
  so "unbound" degenerates to "every table they carry". That is the
  shape amendment 2026-08-04b rejected as option E, and the argument
  survives the move from validator to exporter: an exporter finding
  never blocks a turn, but a report nobody can act on still trains its
  reader to skip the section.
- **C — report the requirement rows the graph does not contain
  (chosen).** Asked a row at a time, per table, anchored at the first
  lost row. It covers 112 of 112, it cannot make a false statement about
  a section, and it stays silent on a table that carries no requirement
  row at all.

**Where to ask it.**

- **D — after the `export-no-scope` return.** Rejected by measurement:
  **+0 findings across all nine roots**. Every REQ file of the nativclaw
  vault returns there, so the check would be inert on the one corpus
  that motivated the issue.
- **E — before it (chosen).** A file whose rows cannot be addressed is
  precisely a file whose rows are lost; reporting the scope and stopping
  answers a different question than the one asked.

## Decision

C and E. `_report_unexported_rows` is added beside `_report_unbound`,
reached from the REQ loop before the scope check, and it reuses
`req_tables` — the GFM table reader amendment 2026-08-04b added to the
validator. ARC keeps `_report_unbound` unchanged: a table is the right
unit where a whole table is bound by its section, and a row is the right
unit where the loss is per row.

## Justification

### Design points

- **The obvious repair was rejected by measurement, not by argument.**
  Extending the ARC check reports 34 of 112 rows and misses every one of
  the six homelab files that lose the rest. The corpus signal was
  already there and pointing the other way: homelab's 69
  `export-unresolved-requirement` findings name 65 identifiers as
  non-existent, and `ANF-BAK-017` to `-040` do exist — in lines the
  exporter never reads. The export accuses the ARC side of naming
  requirements that are not there while quietly failing to read them.
- **A row cannot lie about a section.** The rejected wording is
  falsifiable by a two-column glossary; the shipped wording states a
  count and a cause. This also disposes of the empty-title case, where
  a table above the first heading rendered `table under '## '`.
- **The width floor sits on the header, not on the row.** GFM pads a
  short body row to the header's width (example 204, the rule
  `split_cells` already implements), so a four-cell row of a
  five-column table is a requirement row that would have been ingested
  had its table been read. Checking the row's own width instead would
  have skipped it — caught by a fixture, not by the corpus, which
  contains no such row.
- **The bound-line set became load-bearing.** Under option A it was
  decorative: `_report_unbound` only ever tests the one line per section
  that `sections_with_tables` yields, so including the body rows could
  not change an answer. Under C the body rows are exactly what is
  compared, which is why the set is built from header *and* row entries.
- **Two fence readers, one answer.** `req_tables` masks fences with the
  validator's `fence_blocks` while `bound_tables` uses the exporter's
  `fenced_mask`. They agree on all 956 Markdown files of the nine
  roots, and `req_tables` is asserted identical across the two tools the
  way `split_cells` already is, so a re-declared copy fails a test
  rather than drifting.
- **The code name stays `export-unbound-table`.** The vocabulary a
  consumer sees does not grow, the schema clause keeps the name it
  declares, and the two detection rules are written down under it.
- **The docstring was amended.** The issue quotes it as broken; leaving
  it as the strongest claim in the file while the file only half keeps
  it would have been the same defect in prose.
- **Reviewed adversarially before implementation, and reversed by it.**
  A fresh-context review produced thirteen findings. All thirteen were
  confirmed against the corpus or a fixture, none refuted, and two of
  them (the 78-row blind spot and the total-loss shape) discarded the
  approved plan in favour of option C. The reviewer's own draft was
  refined once: it dropped the short body row of scenario 15.

## Consequences

### Accepted residuals (documented, not solved)

1. **A table in an unbound section that carries no requirement rows is
   not reported.** nativclaw's two-column `## Source map` is the case.
   Deliberate: it is what amendment 2026-08-04b's option E rejected, and
   nothing is lost from the graph by leaving it out.
2. **A REQ template that declares no table amplifies.** The exporter
   already reports `export-no-binding` once; every requirement table in
   the vault then also reports its rows as lost, which is true and
   redundant. No vault here has that shape — all nine bind `req_table` —
   so it is unmeasured.
3. **This reports the loss; it does not repair it.** The 112 rows are
   still absent from the graph, and the 69 `export-unresolved-requirement`
   findings they cause are still emitted. Reading every five-column
   table of the bound section instead of the first is a change to
   ingestion, with its own risk of reading a revision history as
   requirements, and belongs in its own issue.
4. **A vault carrying both a `REQ` and an `ANF` folder loses one of them
   without any finding.** `resolve_roles` keeps the first by
   `setdefault` and `build_graph` skips the other at `role is None`. Out
   of scope for #34; found by the same review.
5. **`_report_unbound` and `_report_unexported_rows` now answer the same
   schema clause with two rules.** That is written into the clause
   rather than hidden, but it does mean a future third domain has to
   decide which of the two it wants.

### Realization

- `export_traceability.py` — `_report_unexported_rows` added, reached
  from the REQ loop of `build_graph` before the `export-no-scope`
  return; `req_tables` imported from the validator; module docstring
  corrected to claim only what the exporter can prove
- `vault_schema.json` — `table_bindings.binding_discovery.unbound_table`
  rewritten with the two per-domain rules and the measurement,
  `unbound_table_scope` added for the seven exempt domains
- `tests/run.sh` — three fixtures in the export vault (undeclared
  section, undeclared section without a scope, requirement table behind
  a revision history in the bound section), the counter-assertions that
  the revision row and the bound table stay unreported, a German-twin
  comparison of finding codes, and `req_tables` in the shared-parser
  assertions; 203 to 210 assertions

Measured after the change, all **nine** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts. Re-measured after rebasing onto amendment
2026-08-04c, whose encoding reader changes how every file is read: the
numbers are unchanged.

| vault | findings before | findings after | new | gone |
| --- | --- | --- | --- | --- |
| template | 0 | 0 | 0 | 0 |
| homelab | 112 | 137 | 25 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 24 | 31 | 7 | 0 |
| PMDE | 18 | 18 | 0 | 0 |
| photon | 0 | 0 | 0 | 0 |
| htwsaar | 1 | 1 | 0 | 0 |
| realitypatches | 0 | 0 | 0 | 0 |
| verdantia | 1 | 1 | 0 | 0 |
| Archiv/Bachelor_Bruder | 7 | 7 | 0 | 0 |

The 32 new findings account for exactly the 112 rows counted above — 78
in homelab over 25 tables, 34 in nativclaw over 7. Nothing disappears
anywhere, and the shipped template vault still exports 3 of 3
requirements proven with no findings, which is the assertion a visitor
is most likely to check.

A note for whoever deploys this: no finding code was added or renamed,
and the exporter still never changes its exit code over a finding. A
vault whose requirement tables all sit first in the bound section — five
of the nine here — sees no change at all.
