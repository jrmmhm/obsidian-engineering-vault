---
domain: DEC
id: DEC-MTH-018
created: 2026-08-04
last-verified: 2026-08-05
---
Date: 2026-08-04
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-04e — Every requirement table of the bound section is read (Accepted)".

## Context

Issue #37, residual 3 of amendment 2026-08-04d ([[DEC_Exporter_Reports_Unread_Requirement_Rows]]). `bound_tables` takes the
first table of the bound section whose header has the requested column
count and stops at the blank line below it, so a REQ file that writes its
requirements as several tables under `###` subheadings inside one
`## Kontext` contributes its first table and nothing else. Amendment
2026-08-04d reports that loss; it does not repair it.

Measured across the vault roots on this machine — **ten** now, not the
nine of the last four amendments: `Documents/tmp/BA_Noah` has appeared
and loses none of its 36 rows. 378 requirement rows sit in a bound
section, **78 of them never reach the graph**, all in homelab, in six
files. The consequence reads as the opposite defect: homelab's export
carried 69 `export-unresolved-requirement` findings naming 65 identifiers
as non-existent, and `ANF-BAK-017` … `-040` do exist, in lines the
exporter never read.

## Options

**Which tables of the bound section are ingested.**

- **A — a section map plus `req_tables`.** Ingestion would share the
  validator's table reader with the loss report of amendment 2026-08-04d,
  making the two exact complements by construction. Built and measured;
  rejected. It yields the identical graph (162 requirements, 427
  relations for homelab, requirement and edge sets equal to B's) at fifty
  changed lines instead of six, and it adds 13 findings across three
  vaults that issue #37 never asked for. It also mixes two fence readers:
  the section map masks with `fenced_mask` while `req_tables` switches
  its own mask off when a block is left open, and a file with an unclosed
  fence then ingests a quoted example table as requirements — verified on
  a probe, `REQ-XXX-900` from a ` ```markdown ` block.
- **B — `bound_tables` reads every table of the bound section
  (chosen)**, behind an `every` keyword that the REQ call passes and no
  ARC call does.

**Which rows of those tables are requirements.** Unchanged, and this is
what makes B safe: the second cell must carry three digits, the predicate
`Vault.req_index` already uses. A five-column revision history in the
same section carries a date there and contributes nothing.

**Whether ARC follows.** No. PMDE's main-module template heads its
two-column submodule table with the title its file template gives the
four-column allocation table, so two bindings resolve to one section
name, and an allocation row has no row-level predicate of its own — a
second four-column table in that section would invent allocations. The
asymmetry is now written into `binding_discovery.step_3` with its reason.

## Decision

B, scoped to REQ. `bound_tables` gains `every=False`; with it set, a new
`## ` heading no longer ends the scan and the blank line below a table
ends that table rather than the search — which is what GFM means by "the
table is broken at the first empty line" (tables extension, verified
against the specification for this change).

## Justification

### Design points

- **The plan was discarded by its own review.** A fresh-context
  adversarial review produced nine findings. Six were confirmed, three
  refuted against the corpus. Two of the confirmed ones (the mixed fence
  readers, and `hline is None` making the planned report unimplementable)
  killed option A, and the reviewer's alternative — six lines instead of
  fifty — is what shipped. The one place it was not followed: it changed
  `bound_tables` for every caller, which would have widened ARC too.
- **The column count is the binding, the row predicate is the filter.**
  Reading more tables is only safe because these are two gates and not
  one. The Shadowed fixture is the guard for exactly this and is now
  built the way homelab writes: a revision history, then two requirement
  tables separated by a `###` subheading.
- **`###` is not a section boundary.** Only `## ` moves the binding, so
  the subheadings homelab uses to layer its requirements never end it.
  Asserted by the fixture rather than left to the reader.
- **The finding message stated the defect as if it were a rule.** "The
  export reads the first five-column table of the bound section and no
  other" was true when amendment 2026-08-04d wrote it and false the
  moment this change landed. It now names the rule that survives.
- **Nothing was gained by widening the header floor.** Ingestion keeps
  `len(cells) == ncols` while the loss report keeps `>= 5`, so a
  six-column table in a bound section is not read *and* is reported. The
  asymmetry is deliberate: it is the shape in which "nothing is silent"
  and "column roles are positional" can both hold.

## Consequences

### Accepted residuals (documented, not solved)

1. **A four-column table carrying requirement rows in the bound section
   is neither ingested nor reported.** The binding requires five columns
   and the loss report's floor is five, so nothing sees it. Pre-existing
   and unchanged by this fix; zero occurrences across the ten roots.
2. **An unclosed fence can still produce a false loss finding.**
   `req_tables` switches its mask off when a block is left open, so the
   report can name a quoted example row that ingestion correctly refused.
   Pre-existing from amendment 2026-08-04d; this change can only shrink
   it, because the set of ingested lines grew.
3. **ARC still reads the first table of its bound section.** A second
   allocation table under one `## Zuordnung und Verifikation` is silently
   not read — the ARC counterpart of the defect just repaired for REQ.
   `_report_unbound` does not see it either, since both tables sit in a
   bound section. Not measured on this corpus.
4. **A five-column table whose second column happens to hold three
   digits becomes requirements.** Same predicate the validator's
   requirement index uses, so the two tools agree about it; the risk is
   real and unmeasured, because no such table exists in any bound section
   here.
5. **The 34 rows under sections nativclaw's templates do not declare stay
   out of the graph.** They are reported, which is issue #34's answer,
   and reading them would mean abandoning the section title as the
   address.

### Realization

- `export_traceability.py` — `bound_tables` gains `every=False` and two
  branches under it; the REQ call in `build_graph` passes `every=True`;
  `_report_unexported_rows` keeps its shape and loses the sentence that
  described the old ingestion rule
- `vault_schema.json` — `binding_discovery.step_3` rewritten per domain
  with the reason the two differ; `unbound_table` restated for what the
  REQ rule still names
- `tests/run.sh` — the Shadowed fixture rebuilt as homelab's shape and
  flipped from asserting the loss to asserting the read, plus the `###`
  subheading and the revision-row counter-assertion; the export vault's
  graph count moves from `5 4 15` to `7 4 15`; 210 to 211 assertions
- `00_documentation_file_creation_and_conventions.md` — one sentence, so
  an author can read the rule where the conventions are, not only in the
  schema

Measured after the change, all **ten** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts:

| vault | requirements | findings | gone | new |
| --- | --- | --- | --- | --- |
| template | 3 → 3 | 0 → 0 | 0 | 0 |
| homelab | **84 → 162** | 137 → 53 | 70 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 0 → 0 | 31 → 31 | 0 | 0 |
| PMDE | 93 → 93 | 18 → 18 | 0 | 0 |
| photon | 0 → 0 | 0 → 0 | 0 | 0 |
| htwsaar | 0 → 0 | 1 → 1 | 0 | 0 |
| realitypatches | 0 → 0 | 0 → 0 | 0 | 0 |
| verdantia | 0 → 0 | 1 → 1 | 0 | 0 |
| Archiv/Bachelor_Bruder | 0 → 0 | 7 → 7 | 0 | 0 |
| tmp/BA_Noah | 0 → 0 | 7 → 7 | 0 | 0 |

Nine of ten byte-identical; the tenth is the vault the issue was filed
for. Not one requirement is lost anywhere. homelab's 70 vanished findings
are its 25 `export-unbound-table` — the rows they named are in the graph
now — and 59 of its 69 `export-unresolved-requirement`. The remaining 10
are true: `ANF-TSC-006/007/008`, `ANF-YTD-007/008/010` and `ANF-SPO-012`
are named by allocation rows and written in no requirements file. That is
a gap in the vault, and the export is now able to say so without also
being wrong about 59 others. Export runtime, median of five: homelab
0.166 → 0.174 s, PMDE 0.122 → 0.128 s, nativclaw 0.120 → 0.122 s.
`tests/run.sh` at 211 assertions, 0 failures.

What proves the change is the runtime check. Against the real homelab
vault the exporter now prints `requirements: 162 proven: 91 not proven:
71` and `relations: 427 findings: 53`, `ANF-BAK-040` appears in
`traceability_requirements.csv` with its acceptance criterion, and no
`export-unbound-table` finding remains in the report.
