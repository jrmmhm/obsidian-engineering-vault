---
domain: DEC
id: DEC-MTH-032
created: 2026-08-05
last-verified: 2026-08-08
---
Date: 2026-08-05
Status: Accepted
Corrected by: [[DEC_A_Declared_Relation_Without_A_Check_Of_Its_Own]] – the pointer may carry a short reason, as its sibling line always has

## Context

The decision record of this method's own tooling was written beside the vault
format rather than in it: one appended file, 5100 lines, 31 records, at
`.claude/skills/mechatronics-docs/DECISIONS.md`. Under this repository's own
rules that file breaks three of them at once — the 400-line ERROR, "one
decision per DEC file", and the `superseded-by` relation that the schema
declares for exactly this domain. A method that is not applied to its own
hardest document is a method nobody has evidence for, and 31 real decisions
with real cross-corrections are the largest scale test this format can be
given. Issue #53 asks for that test to be run.

## Options

- Option A — leave the appended log and add a generated table of contents.
  One file touched, zero fidelity risk, and the scale test does not happen.
- Option B — split the log into 31 plain Markdown files beside the skill,
  with no frontmatter, no domain folders and no validator. Achieves
  findability, and again declines the test the issue asks for.
- Option C — migrate the log into a second vault, `.claude/01_methodvault/`,
  audited by this repository's own validator in CI, with the appended file
  reduced to a forwarding map.

## Decision

Option C.

## Justification

### Why `.claude/01_methodvault/` and not somewhere else

- **`project_root` resolves correctly.** `Vault.__init__` derives
  `doc_root = root.parent` and `project_root = root.parent.parent`, so a vault
  one level under `.claude/` puts `project_root` at the repository root and every
  historical path token (`20_software/…`, `00_documentation/…`) resolves. Under
  `.claude/skills/mechatronics-docs/` it would be `.claude/skills` — semantically
  wrong, and a trap for the first path token somebody writes outside backticks.
  This argument is precautionary, not measured: the corpus carries zero
  shape-gated path tokens outside inline code today.
- **The template vault keeps its known state.** A vault under
  `00_documentation/` shares `doc_root` with the project vault, and its audit
  measured 1 → 5 `duplicate-basename` WARNs. Here the two vaults share no name
  index; the template vault stays at `0 error(s), 1 warning(s)`.
- **Derived projects get cleaner, not dirtier.** 234 kB of method history used to
  travel inside `.claude/skills/`, which a derived project keeps. It now sits
  beside it and is deleted like `CONTRIBUTING.md` and `.github/`.
- **The `01_` prefix** is what the activation guard looks for, so the second
  vault is found by the same rule as the first rather than as an exception.
- **The hooks fire there.** `post_write_check.sh` calls
  `validate_vault.py --hook post`, which locates the vault with
  `find_vault_root(path)` walking up from the written file. Measured on a probe
  file under this root: regular findings, over exactly the path the PostToolUse
  hook takes.

### Why `DECISIONS.md` forwards instead of being deleted or kept

Ten source comments in `validate_vault.py`, one in `export_traceability.py`, the
prose notes in `vault_schema.json` and one assertion comment in `tests/run.sh`
cite an amendment by date. A forwarding map keeps every one of those citations
true and resolvable without touching two large Python files to solve a
documentation problem. Deleting the file orphans them; keeping it as an append
log means two logs. The shape is the one this log decided for itself in
amendment 2026-08-05g ([[DEC_AGENTS_File_Forwards_It_Does_Not_Duplicate]]): a
forwarder repeats nothing, so nothing in it can drift.

### Why this is not overruled by `STRUCTURE.md`'s argument about `IEC_61508_MAPPING.md`

Amendment 2026-08-05j ([[DEC_Safety_Standard_Correspondence_Is_Structural]])
kept the IEC mapping out of a vault because a note there additionally owes
frontmatter, its domain template's sections and the line limits. Those three
costs are real and are paid here deliberately. The difference is what the
content is: the IEC file is one structural comparison with no alternatives and
no chosen option — it is not a decision and therefore not a DEC. The 31 records
migrated here are each of the form "option X rather than Y, for this reason",
which is the DEC domain's own definition. That amendment is not overruled; it
is applied to a different kind of document.

### Tier: MINOR

No domain is added, removed or renamed, no template section changes (the method
vault copies the shipped DEC template unchanged), no frontmatter field, no
identifier pattern, no typed relation, no rule, no WARN raised to ERROR, no
export field. What changes is documentation and the contribution convention —
the "new or corrected documentation" line of the table in amendment 2026-08-05h
([[DEC_The_Method_Carries_A_Version]]).

## Consequences

### Measured result

- Method vault: **0 errors, 26 warnings**, all 26 `length` (>150 lines). They are
  the honest measurement the issue asked for: 25 of the 31 migrated decisions are
  longer than the recommendation, and the twenty-sixth is this note, which fails
  its own format exactly as the records it describes do. Removing the 25 means
  shortening or splitting records, which fidelity rule 1 forbids. No record
  exceeds 400 lines (longest: 255).
- Template vault: unchanged at **0 errors, 1 warning**.
- Test suite: **0 failures**, one assertion richer than before — the method
  vault is now held to the same zero-ERROR bar as the template vault locally,
  not only in CI. The count itself is deliberately not quoted: it climbs with
  every behaviour anyone pins.
- Fidelity: every one of the 31 records was compared paragraph by paragraph
  against its source line range with `difflib`. Deviations found beyond the
  declared classes — frontmatter, heading level, the migration metadata block,
  the checked placeholder sentences, the inserted wikilinks: **one**, the
  declared backtick fix below.

### The one byte-level change

`DECISIONS.md` line 4326 wrote the example `[[CMP_Oscilloscope]]` inside quotes
rather than inside backticks — the only one of its fourteen wikilink examples
that does. Migrated verbatim it becomes a real link into this vault, resolves to
nothing, and is a `link-unresolved` ERROR that would fail the CI step this
change adds. It is backticked in
[[DEC_Two_Declared_Relations_Get_A_Source]] and the file says so above its
Context. No word is changed. The audit found this defect on first contact with a
record thirty amendments of review had not caught, which is the plainest
available answer to "the audit finds nothing here".

### Corrected-by back-references

The source contains no supersession: all 31 headings read `(Accepted)`, no
`Status: Superseded` and no `Superseded by` line exists anywhere. Status is
therefore unchanged everywhere. But thirteen places do have a later record
overturning a statement of an earlier one, and in one file a reader simply read
on. Each corrected file carries a `Corrected by:` pointer above its Context —
a pointer, no gloss, no status change. The table below is the protocol of that
pass and names the files rather than linking them a second time, which is what
`link-budget` asks for; the live pointers sit in the eleven corrected files and
every file is reachable from [[system_overview]].

| Corrected record | Corrected by | What the later record says |
| --- | --- | --- |
| `DEC_E2E_Test_Driven_Hardening` | `DEC_The_Stop_Report_Goes_Where_It_Is_Read` | the hook-channel fact was recorded the other way round |
| `DEC_Language_Independent_Recognition_And_VCS_Tier` | `DEC_Identifier_Enforcement` | the homelab figure is not to be carried forward |
| `DEC_Schema_Driven_Field_Validation` | `DEC_Frontmatter_Reader_Learns_The_Editor_Spelling` | the measurement that deferred the block sequence was scoped wrongly |
| `DEC_Records_Not_Copies_For_Fenced_Blocks` | `DEC_The_Gate_Names_The_Code_That_Stopped_Firing` | the stdout channel claim is the opposite of what was measured |
| `DEC_Reading_The_Vault_As_A_Graph` | `DEC_One_Cell_Splitter_For_Both_Tools` | supersedes the "own parsing primitives" design point for the splitter |
| `DEC_Reading_The_Vault_As_A_Graph` | `DEC_One_BOM_Safe_Reader_For_Every_File` | the same design point's BOM half is now historical |
| `DEC_Reading_The_Vault_As_A_Graph` | `DEC_Two_Declared_Relations_Get_A_Source` | both halves of its residual 4 were false |
| `DEC_One_Cell_Splitter_For_Both_Tools` | `DEC_Link_Matcher_Reads_Two_Unseen_Shapes` | the use its residual 3 anticipated does not exist |
| `DEC_Requirement_Table_Recognised_By_Shape` | `DEC_Exporter_Reports_Unread_Requirement_Rows` | its residual 4 miscounted the tables and the silence |
| `DEC_Exporter_Reports_Unread_Requirement_Rows` | `DEC_Every_Requirement_Table_Of_The_Bound_Section` | its finding message stated the defect as if it were a rule |
| `DEC_Two_Folders_One_Domain_Is_A_Finding` | `DEC_One_Abbreviation_One_Folder_By_Rule` | its first rejection of option B was wrong |
| `DEC_The_Gate_Names_The_Code_That_Stopped_Firing` | `DEC_The_Stop_Report_Goes_Where_It_Is_Read` | the `.*` trap it documented for `^` it then walked into |
| `DEC_The_Method_Carries_A_Version` | `DEC_Safety_Standard_Correspondence_Is_Structural` | issue #6 was expected MAJOR and landed MINOR |

[[DEC_Frontmatter_Reader_Learns_The_Editor_Spelling]] carries a migration note
instead: its "this document" pointed at the appended log and would point at
itself here.

### Accepted residuals (documented, not solved)

1. **Two records name two questions each** — `2026-07-28` ("Language-independent
   recognition, VCS tier") and `2026-07-28b` ("Object identity and typed
   relations"). Splitting them would mean rewriting a shared Context, which
   fidelity rule 1 forbids, so both are kept whole and the deviation from "one
   question per file" is named rather than hidden.
2. **25 `length` WARNs stand.** See above; they are the measurement, not a
   defect of the migration.
3. **The vault needs three domain folders to be a vault.** `is_vault_root`
   requires it, so `09_references_(REF)` and `98_administration_(ADM)` exist
   with a README each and no content. Loosening the predicate would make any
   one-folder directory a vault and is a MAJOR method change.
4. **ID order is append order, not date order.** `2026-08-04e` precedes
   `2026-08-04d` and `2026-08-05j` precedes `2026-08-05i`, because suffixes were
   assigned when pull requests landed. Renumbering would invent a history.
5. **One cited date resolves to no record.** "amendment 2026-07-28g" is cited
   four times — twice inside the record migrated as
   [[DEC_A_Non_UTF8_File_Says_Which_Encoding]] and twice in the tool sources
   (`validate_vault.py`, `tests/run.sh`). No record carries that date, and the
   statement it attributes belongs to `2026-07-31`
   ([[DEC_A_Near_Miss_Is_Not_An_Absence]]), which introduced `section-mismatch`.
   All four are left standing and unlinked: correcting the two in the record
   would be editing the record, and the two in the code are Group C, which this
   change does not touch. Found by this migration, and worth its own issue.
   Closed 2026-08-08: all four citations were retargeted to `2026-07-31`,
   decided in [[DEC_A_Phantom_Citation_Is_Retargeted]] (issue #74) — the
   corrected record now carries a second declared deviation from its source,
   beyond the one byte-level change counted above.
6. **Bare cross-references stay unlinked.** "follow-up 7", "residual 3 there" and
   a date reached only through a continuation (`amendments 2026-07-31b,
   2026-08-01`) carry no link — linking mid-sentence there would be a text edit.
7. **`doc_root` for this vault is `.claude/`**, so its name index covers local,
   git-ignored state. Harmless today; the alternative is a change to
   `Vault.__init__`, which the stop gate depends on.
8. **The thirteen date citations in `validate_vault.py`,
   `export_traceability.py`, `vault_schema.json` and `tests/run.sh` keep their
   date form.** They stay true through the forwarding map. Rewriting them to
   `[[DEC_…]]` names is cleaner in the end state and is a change to production
   code for a documentation gain; named here as a follow-up rather than done.

### Realization

- `.claude/01_methodvault/` — `README.md`, `system_overview.md`, the DEC domain
  with the unchanged shipped template and 32 notes, plus the REF and ADM folders
  the vault predicate requires
- `.gitignore` — a second exception beside `!.claude/skills/`
- `.claude/skills/mechatronics-docs/DECISIONS.md` — reduced to a forwarding map,
  one row per amendment date, no decision content
- `.github/workflows/validate-vault.yml` — the method-vault audit step, named by
  path like the step above it
- `.claude/skills/mechatronics-docs/tests/run.sh` — the method-vault assertion,
  and the vault added to the fence/reader parity guard's argument list
- `CONTRIBUTING.md`, `.github/pull_request_template.md`,
  `.github/ISSUE_TEMPLATE/method_change.yml`,
  `.github/ISSUE_TEMPLATE/config.yml`, `CHANGELOG.md`, `README.md`,
  `STRUCTURE.md`, `CLAUDE.md` — the amendment convention replaced by the DEC
  note, and the second vault named in the layout documents
