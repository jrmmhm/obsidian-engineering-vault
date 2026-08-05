---
domain: DEC
id: DEC-MTH-010
created: 2026-07-31
last-verified: 2026-08-05
---
Date: 2026-07-31
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-07-31b — Reading the vault as a graph (Accepted)".

## Context

The vault is readable in Obsidian or as raw Markdown and nowhere else.
Amendment 2026-07-28b declared seven relation kinds with their reverse
keys and left every one of them `declared-only`; amendment 2026-07-28d
made the field vocabulary schema-driven but not the relations. Issue #2
asks for the artifact that turns those declarations into something a
reviewer, an examiner or an auditor can be handed: a requirement-to-
evidence matrix in both directions, with what is unproven stated rather
than left to be noticed.

Two of this file's own residuals decide most of the design. Residual 3
of 2026-07-28b — a vault in another language finds no relation table and
produces an empty graph without an error — is not a theoretical risk:
measured on this machine, no production vault matches any declared
header signature, none carries a single `id:`, and `Vault.req_index()`
returns zero rows on homelab because it asks for the folder abbreviation
`REQ`. Residual 4 — reformatting a header row silently removes every
relation it carried — is live: homelab's ARC template writes
`Verifikation (TUE)` and six of its fourteen ARC files write
`Verifikation (TST)`.

## Options

**Which invariant carries the binding.**

- **A — the declared header signature.** What `table_bindings` states
  today. Rejected on measurement: nothing enforces a header row, and the
  drift is already there. A recognizer keyed on the header accepts 8 of
  homelab's 14 ARC files and 73 of its 148 allocation rows.
- **B — the folder number.** Language-independent by construction and
  identical across all seven vaults on this machine. Rejected as the
  primary mechanism: it invents a second vocabulary next to the
  abbreviations the schema already enumerates, and follow-up 4 of
  amendment 2026-07-28 has already decided the explicit alias map.
- **C — the template-declared section position (chosen).** The project's
  own `00_*template*` file names the section, `check_sections` enforces
  that every file of the domain carries it as a blocking ERROR, and
  `Vault.templates_for` already reads it. Measured: the section title is
  present in 14 of 14 homelab ARC files, so the binding recovers 148 of
  148 allocation rows. This is the mechanism `table_bindings` already
  records as the documented fallback; the amendment promotes it to the
  primary one and keeps the header signature as corroboration.

**How domains are recognised across languages.**

- **D — alias map plus a requirement-ID prefix taken from the vault's own
  requirements domain (chosen).** Exactly follow-up 4 of amendment
  2026-07-28, unbundled from the convention rollout that blocked it
  there, because the exporter reports and never blocks.
- **E — infer the role from the folder number.** See option B.

**How much the exporter is allowed to interpret.**

- **F — normalise into a clean model.** Rejected: real allocation rows
  carry ranges (`ANF-NAV-001 bis ANF-NAV-009`), number continuations
  (`ANF-BAK-008, 027, 028`), prose subjects (115 of 148 homelab rows),
  prose verifications (21 rows), and 17 distinct status values the
  schema does not declare. Silently mapping those onto the declared
  vocabulary is how an export starts lying in the direction that flatters
  the project.
- **G — expand only what can be checked, report the rest (chosen).** A
  range or continuation is expanded only when every identifier it yields
  exists in the requirement index; anything else becomes a named finding.
  A status counts as proven only on an exact match against the declared
  value, a status carrying a qualifier is reported with its verbatim
  text as the reason, and every unrecognised construct is a row in the
  export rather than an absence from it.

## Decision

C, D and G. The exporter ships as `export_traceability.py` beside the
validator, imports from it and is never imported by it, and does not
modify it. It writes JSON, CSV and a self-contained HTML report into a
directory the caller names, refuses to write inside a vault, and derives
every reverse edge instead of reading one.

The two consistency rules that amendment 2026-07-28b reassigned to this
issue are reported by the export and enforced by nothing: measured,
`verified-needs-evidence` fires on 21 legitimate homelab rows whose
verification is prose, which is the false-positive rate this project
refuses in a blocking check.

CSV values are written verbatim. OWASP's own CSV-injection page states
that the commonly suggested mitigations "may fail" because "Microsoft
Excel may remove quotes or escape characters from CSV cells when a file
is saved and re-opened", so a prefix character would trade a documented
record for an undocumented one and still not close the hole. The risk is
named in the README and in the export's provenance block instead.

## Justification

### Design points

- **Proven means what this vault already meant by it.** The ARC README lets
  an allocation reach `Verified` only once a verification link exists and
  its evidence is written down, so that is the rule the export applies.
  Making the `verifies` frontmatter decide instead would report every
  homelab requirement as unproven, because that vault's 39 evidence notes
  all carry an empty list - a convention it never adopted. The
  disagreement is not swallowed either: it is an open question on a
  requirement that is otherwise proven, which is the compliance-plus-
  close-out shape ECSS-E-ST-10-02C asks for.
- **The column count is part of the section match.** PMDE's main-module
  template heads its two-column submodule table with the same title its
  file template gives the four-column allocation table. Binding on the
  title alone fed a submodule row to the allocation parser and produced
  allocations with no requirement.
- **The exporter carries its own parsing primitives.** A fence tracker
  that keeps character and length, a cell splitter that honours the GFM
  escape rule, BOM-safe reading, NFC keys. The validator's equivalents are
  wrong in ways that are harmless there and would not be here: reproduced,
  a requirement table quoted inside a ```markdown block yields three
  findings from `check_req_table`, and a BOM makes `parse_frontmatter`
  return `(None, 0, None)` - the frontmatter of the whole file disappears
  without a message. Fixing them is a change to the blocking layer with
  its own blast radius and belongs in its own issue.
- **CSV values are not mutated.** OWASP's CSV-injection page states that
  the usual prefixes "may fail" because Excel removes quotes and escape
  characters across a save and reopen. A prefix would corrupt the record
  and still not close the hole, so the export stays verbatim and the
  provenance block says so.
- **Two runs, one diff.** Determinism is asserted as the property, in the
  test suite and in CI, not approximated by suppressing a timestamp. The
  comparison uses the same output directory twice, because the provenance
  block records the command line and two directories differ there
  truthfully.

## Consequences

### Accepted residuals (documented, not solved)

1. **The exporter and the validator disagree about how many requirement
   rows a vault has.** The exporter skips fenced blocks and the validator
   does not. The numbers differ only where a vault quotes a requirement
   table as documentation; the fix belongs to the validator.
2. **A language the alias map does not know still exports an empty graph** -
   loudly now (`export-unknown-domain`) rather than silently, but empty.
   Adding a language is an edit to `domain_aliases`.
3. **The status vocabulary is English in every vault measured**, and the
   exporter relies on that. A vault that translates `Verified` would have
   every allocation read as unknown, reported per row but not understood.
4. **`contains` and `test-object` are empty on every production vault**,
   because both rest on annotated links and no production vault carries a
   single `id:`. The mechanism is exercised only by the template vault and
   the test fixtures.
   _Corrected 2026-08-05 (amendment 2026-08-05d): both halves were wrong.
   Measured on the template vault, `contains` and `test-object` were zero
   there too — `test-object` was never implemented, and only the submodule
   table half of `contains` was, which the template vault does not use. The
   fixtures exercised the table half alone. Both now have a working source,
   and an unannotated link that could have been a relation is reported
   rather than left to make the graph quietly short._
5. **The HTML report has no pagination.** It is one document; the largest
   vault measured produces 84 requirement rows, and the design point at
   which that becomes a problem has not been reached or looked for.

### Realization

- `export_traceability.py` — the exporter: `resolve_roles`,
  `discover_bindings`, `bound_tables`, `expand_requirement_cell`,
  `build_graph`, `reverse_index`, `assess`, and the three writers, plus
  its own `read_lines`, `fenced_mask`, `split_cells` and `safe_href`
- `vault_schema.json` — schema 0.2 to 0.3: `domain_aliases` with the
  requirement-ID prefix rule, `binding_discovery` and `status_token` under
  `table_bindings`, `arc_main_module_table`, `qualifier_proven_value`, the
  `export-driven` enforcement level, and six relations plus both
  consistency rules moved from `declared-only` to it
- `tests/run.sh` — fixture 7, a vault carrying a range, a number
  continuation, a prose subject, a qualified status, an identifier that
  exists nowhere, a table quoted in a code fence, an escaped pipe, a
  script tag and a spreadsheet formula, built twice in two languages and
  asserted to export the same graph; 119 to 144 assertions
- `.github/workflows/validate-vault.yml` — the determinism assertion
- `README.md`, `STRUCTURE.md`, `SKILL.md`,
  `00_documentation_file_creation_and_conventions.md`,
  `02_documents/README.md` — what the export is, where it may be written,
  and why the section title is the address a relation table is found by

Measured after the change, all seven vaults on this machine at the same
moment:

| vault | requirements | proven | relations | findings |
| --- | --- | --- | --- | --- |
| template | 3 | 3 | 14 | 0 |
| homelab | 84 | 53 | 260 | 110 |
| PMDE | 93 | 0 | 150 | 18 |
| realitypatches | 0 | 0 | 0 | 0 |
| htwsaar | 0 | 0 | 0 | 1 |
| verdantia | 0 | 0 | 0 | 1 |
| photon | 0 | 0 | 0 | 0 |

PMDE's zero is correct: no allocation row in that vault has ever reached
`Verified`. The single finding on htwsaar and verdantia is the same one -
neither ships a main-module template, so that binding has no section to
resolve. homelab's 110 findings are dominated by 69 requirement
identifiers referenced in allocation tables that no requirement row
defines, which is a defect in that vault and the first thing its export
now says out loud.

The template vault is unchanged at 0 errors and 9 warnings, and
`tests/run.sh` runs 144 assertions with 0 failures.
