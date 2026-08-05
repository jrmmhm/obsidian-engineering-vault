---
domain: DEC
id: DEC-MTH-016
created: 2026-08-04
last-verified: 2026-08-05
---
Date: 2026-08-04
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-04b — A requirement table is recognised by its shape, not by its header text (Accepted)".
Corrected by: [[DEC_Exporter_Reports_Unread_Requirement_Rows]]

## Context

Issue #25, residual 1 of amendment 2026-08-01 ([[DEC_One_Fence_Definition_For_Both_Tools]]). `check_req_table` gates
every row check on `header_ok`, a flag set by one thing only: a table row
whose first cell contains `Class` or whose first two cells contain `NNN`.
Nothing resets it and nothing else sets it. Since issue #20 made
`req_rows` skip fenced blocks, a canonical header that survives only
inside a quoted example no longer switches the check on, so a REQ file
whose real table header drifted — translated, reworded, reformatted —
is read and then not checked, silently, on four codes that all reach the
stop gate's blocking set.

Reproduced against the current validator: a REQ file quoting the
canonical header inside a ```` ```markdown ```` block and carrying its
real table below under `| Klasse | Nr. | Inhalt | Kriterium | Quelle |`
with one broken row produces zero findings.

## Options

**What identifies a requirement table.**

- **A — the template-declared section title**, as `export_traceability.py`
  binds its tables since amendment 2026-07-31b ([[DEC_Reading_The_Vault_As_A_Graph]]), and the candidate issue
  #25 names. Rejected on measurement: across the four vault roots on this
  machine that carry a `REQ` folder, 121 requirement rows are checked
  today and the section binding would check 87. The 34 lost rows all sit
  in `REQ_persona_voice.md` (userver-nativclaw), which carries seven
  five-column requirement tables under seven section titles of its own.
  The option would install the very failure mode the issue was filed
  against. It also has no answer for a project whose REQ template
  declares no table at all — the exporter reports `export-no-binding`
  there, but a validator that binds to nothing checks nothing.
- **B — the width of the table alone.** Rejected: a five-column
  changelog or revision table in a REQ file becomes a requirement table
  and produces four blocking ERRORs on rows nobody wrote as
  requirements.
- **C — the GFM table structure plus a requirement signal (chosen).** A
  table is what the GFM tables extension says it is: a delimiter row,
  and above it a header row with the same number of cells. Such a table
  is a requirement table when it has at least five columns AND either
  its header carries the canonical tokens or at least one of its rows
  carries a three-digit identifier in the second cell — the very
  predicate `Vault.req_index` and the global duplicate scan already use
  to decide that a row defines a requirement. The recognition is a union
  with today's rule, so no row that is checked today stops being
  checked, and it needs neither the header's wording nor a section title
  to survive.

**What to do about the silence that remains.**

- **D — leave it.** Rejected: issue #25's second delivery item exists
  because a check that stops checking without saying so is the failure
  mode this layer is for.
- **E — report every table that is not a requirement table.** Rejected:
  a REQ file may legitimately carry a source map or a rubric, and a WARN
  nobody can act on trains the reader to ignore the channel.
- **F — report the two cases the validator can prove from its own state
  (chosen).** `req-table-unrecognized` (WARN, one grouped finding per
  file) when a table group that is not a recognised requirement table
  carries a row the requirement index will index anyway — the validator
  disagreeing with itself — or when a REQ file has a table of at least
  five columns and not one recognised requirement table, which is a file
  that looks like it defines requirements and defines none the checks
  can read.

## Decision

C and F. `req_tables` becomes the one reader that groups table lines
into GFM tables, `req_rows` becomes its flattening view so
`Vault.req_index` and the global duplicate scan keep reading exactly
what they read today, and `check_req_table` iterates tables instead of
latching on a header. The column count stays a Python constant, the
exporter is not touched, and the row checks themselves are unchanged.

## Justification

### Design points

- **The candidate the issue named was rejected by measurement, not by
  argument.** Only four of the nine vault roots on this machine carry a
  `REQ` folder at all — the five German ones spell it `ANF`, where
  `check_req_table` never runs, so the translated header that motivates
  this issue cannot occur in the vaults that are actually written in
  German. Across those four: 121 requirement rows are checked today, the
  section binding would check 87, and every one of the 34 it drops sits
  in `REQ_persona_voice.md`, which carries seven five-column requirement
  tables under seven section titles of its own. The binding is right for
  the exporter, where an unbound table becomes a row in a report, and
  wrong here, where it becomes a check nobody runs.
- **Two signals, unioned with the old rule, so nothing stops being
  checked.** The canonical header keeps its job — it is the only signal
  left when every row of a table is malformed — and the requirement
  number in the second cell is the one that survives translation. Because
  the second signal is `Vault.req_index`'s own predicate, "this table is
  a requirement table" and "this row defines a requirement" can no longer
  give different answers about the same line.
- **Width is a floor, not an equality.** The first draft required exactly
  five columns, which would have sold an exemption from four blocking
  codes for one `| Comment |` in a header — the same bypass amendment
  2026-08-01 refused to sell for three backticks, at a tenth of the
  price. The adversarial review found it with a fixture the corpus does
  not contain.
- **A fenced line ends a table, it does not vanish from it.** `req_rows`
  may skip fenced lines because it asks a per-line question. A reader
  that groups lines into tables cannot: two tables separated by a quoted
  example would merge, and the second table's header would be read as a
  body row — two blocking findings on a line the author wrote correctly.
  Also found by the review, also with a shape no vault here contains.
- **The column count stays in Python.** Reading it from
  `domains.REQ.rows.columns` would have made a data file the off-switch
  for four blocking codes, which is exactly what `discovery`'s rejected
  per-project override refuses, and `_strlist` drops non-strings
  silently, so a typo in that list would have disabled the checks without
  even a `schema-unreadable` WARN.
- **The new WARN reports only what the validator can prove from its own
  state.** Reporting every table that is not a requirement table would
  fire on the source map, the rubric and the revision history that real
  REQ files legitimately carry. The two conditions that ship are a
  self-disagreement (the index reads rows no check reads) and an empty
  answer (a file with a wide table and no readable requirement table).
  Measured: zero findings across all nine vault roots.
- **Reviewed adversarially before implementation.** A fresh-context
  review produced fourteen findings; twelve were confirmed and four of
  them changed the design — the width floor, the fence break, the Python
  constant, and the WARN's scope. Two were refuted with measurement: the
  claimed 1-in-1 false-positive rate of the WARN belonged to the draft
  that was replaced, and the rejected section binding remains rejected
  even though the exporter extracts nothing from that vault for an
  unrelated reason. Every counter-example the review wrote out was run
  against both the old and the new code before the plan was revised.

## Consequences

### Accepted residuals (documented, not solved)

1. **A REQ file with no table at all is not reported.** Requirements
   written as prose under a heading — `REQ_secrets_isolation.md` in the
   nativclaw vault is one — produce no row, so neither WARN condition can
   fire. Reporting it would be a convention rollout on files that never
   adopted the table form, not a defect report.
2. **A five-column table nobody meant as a requirement table is still
   read as one** when its rows carry three-digit numbers in the second
   cell. That is deliberate: the requirement index already reads those
   rows as requirements, so the alternative is not silence but
   disagreement. The fixture for the opposite case — a revision history
   whose second column holds dates — is what keeps the signal honest.
3. **A short body row is still skipped rather than padded.** GFM inserts
   empty cells for a row narrower than its header, so a four-cell row in
   a five-column table genuinely has an empty acceptance criterion. The
   `len(row) < REQ_ROW_COLUMNS` guard predates this change and keeps its
   behaviour; padding would have added blocking findings this issue never
   asked for. Measured: zero such rows in nine vault roots.
4. **The exporter never reports an unbound table in a REQ file.**
   `_report_unbound` is called from the ARC loop of `build_graph` alone,
   so the six unbound five-column tables of `REQ_persona_voice.md`
   are absent from its export without a finding — which contradicts
   `table_bindings.binding_discovery.unbound_table` ("an empty graph is
   never silent") and the exporter's own docstring. Found by the
   adversarial review of this issue, measured, and left alone: it is an
   exporter defect and belongs in its own issue. Filed as issue #34,
   which also names the second gap it hides behind — that file returns at
   `export-no-scope` before any table is looked at.
5. **`parse_table_row` has no production caller left.** `req_tables`
   needs the delimiter row distinguishable from "not a row", which that
   predicate deliberately conflates. It stays because it is what the
   test harness asserts the two tools share, and `req_rows` is now
   asserted to agree with it line by line.

### Realization

- `validate_vault.py` — `req_tables` added as the one reader of table
  structure, `req_rows` reduced to its flat view, `check_req_table`
  rewritten around it with `canonical_req_header` and
  `check_req_table_silence`; `ROW_NNN_RE` and `REQ_ROW_COLUMNS` added and
  read by `Vault.req_index` and the global duplicate scan as well
- `vault_schema.json` — `domains.REQ.rows` gains `recognition` and
  `unrecognized`; `enforced_detail` names the new code and why the column
  count is not data
- `tests/run.sh` — four REQ fixtures (drifted header behind a quoted one,
  a fence between two tables, a widened second table, a revision history
  as the only wide table), the placeholder rows in the precision vault's
  REQ file, and `req_tables` in the parser assertions;
  174 to 188 assertions
- no change to `export_traceability.py`: the section binding is right
  where an unbound table becomes a row in a report

Measured after the change, all **nine** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| template | 0 | 9 | 0 | 0 |
| homelab | 9 | 114 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 503 | 233 | 0 | 0 |
| PMDE | 398 | 102 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |
| Archiv/Bachelor_Bruder | 68 | 32 | 0 | 0 |

Nine of nine are byte-identical, which is the expected result for a
recognition rule that only ever adds: every table checked before is still
checked, and no vault here carries the drifted shape. What proves the
change works is therefore the runtime check. On a throwaway vault holding
the issue's own reproduction — a REQ file quoting the canonical header
inside a ```` ```markdown ```` block, with its real table below under
`| Klasse | Nr. | Inhalt | Kriterium | Quelle |` and one broken row — the
old code reports nothing at all and the new code reports `req-class`,
`req-nnn` and `req-criterion` on that row and nothing on the quoted one,
while `REQ-DRF-002` reaches the requirement index and the quoted
`REQ-DRF-001` does not. Run against the shipped template vault, the
result is unchanged at 0 errors and 9 warnings.

A note for whoever deploys this: no finding code was renamed, and the one
added code is a WARN and not in the blocking set. A vault whose
requirement tables are recognised today sees no change at all; a vault
whose table header drifted starts being checked, which is the point.
