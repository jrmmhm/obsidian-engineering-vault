# Decision Record — forwarding map

This file carried the decision record of the documentation method itself: one
appended log, 5100 lines, 31 records, from the base decision of 2026-07-25 to
amendment 2026-08-05i.

**The record now lives in `.claude/01_methodvault/`**, one DEC note per
decision, audited by `validate_vault.py` in CI like any other vault. Start at
`.claude/01_methodvault/system_overview.md`.

This file keeps no decision content, so nothing in it can drift. It keeps the
map, because the tools cite an amendment by its date in **48 lines** — counting
every line that names one: 20 in `validate_vault.py`, 14 in `vault_schema.json`,
8 in `export_traceability.py` and 6 in `tests/run.sh`, naming 15 distinct dates
between them. Every date below resolves to the note that carries it. Why the record moved and what that cost is itself a
decision there: `DEC_The_Decision_Log_Moves_Into_A_Vault` (DEC-MTH-032).

**A new decision is a new DEC note in the method vault, not an amendment here.**
`CONTRIBUTING.md` states the route.

All notes below are in `.claude/01_methodvault/02_decisions_(DEC)/`.

| Amendment | ID | Note |
| --- | --- | --- |
| 2026-07-25 (base decision) | DEC-MTH-001 | `DEC_Enforcement_Layer_For_The_Vault_Conventions` |
| 2026-07-27 | DEC-MTH-002 | `DEC_E2E_Test_Driven_Hardening` |
| 2026-07-28 | DEC-MTH-003 | `DEC_Language_Independent_Recognition_And_VCS_Tier` |
| 2026-07-28b | DEC-MTH-004 | `DEC_Object_Identity_And_Typed_Relations` |
| 2026-07-28c | DEC-MTH-005 | `DEC_Identifier_Enforcement` |
| 2026-07-28d | DEC-MTH-006 | `DEC_Schema_Driven_Field_Validation` |
| 2026-07-28e | DEC-MTH-007 | `DEC_One_Project_Path_Definition_In_Both_Zones` |
| 2026-07-28f | DEC-MTH-008 | `DEC_Records_Not_Copies_For_Fenced_Blocks` |
| 2026-07-31 | DEC-MTH-009 | `DEC_A_Near_Miss_Is_Not_An_Absence` |
| 2026-07-31b | DEC-MTH-010 | `DEC_Reading_The_Vault_As_A_Graph` |
| 2026-08-01 | DEC-MTH-011 | `DEC_One_Fence_Definition_For_Both_Tools` |
| 2026-08-01b | DEC-MTH-012 | `DEC_One_Cell_Splitter_For_Both_Tools` |
| 2026-08-01c | DEC-MTH-013 | `DEC_Frontmatter_Reader_Learns_The_Editor_Spelling` |
| 2026-08-01d | DEC-MTH-014 | `DEC_Link_Matcher_Reads_Two_Unseen_Shapes` |
| 2026-08-04 | DEC-MTH-015 | `DEC_One_BOM_Safe_Reader_For_Every_File` |
| 2026-08-04b | DEC-MTH-016 | `DEC_Requirement_Table_Recognised_By_Shape` |
| 2026-08-04c | DEC-MTH-017 | `DEC_A_Non_UTF8_File_Says_Which_Encoding` |
| 2026-08-04d | DEC-MTH-019 | `DEC_Exporter_Reports_Unread_Requirement_Rows` |
| 2026-08-04e | DEC-MTH-018 | `DEC_Every_Requirement_Table_Of_The_Bound_Section` |
| 2026-08-04f | DEC-MTH-020 | `DEC_Two_Folders_One_Domain_Is_A_Finding` |
| 2026-08-04g | DEC-MTH-021 | `DEC_One_Abbreviation_One_Folder_By_Rule` |
| 2026-08-05 | DEC-MTH-022 | `DEC_The_Gate_Names_The_Code_That_Stopped_Firing` |
| 2026-08-05b | DEC-MTH-023 | `DEC_The_Stop_Report_Goes_Where_It_Is_Read` |
| 2026-08-05c | DEC-MTH-024 | `DEC_A_Replicated_Link_Is_Valid_Where_Written` |
| 2026-08-05d | DEC-MTH-025 | `DEC_Two_Declared_Relations_Get_A_Source` |
| 2026-08-05e | DEC-MTH-026 | `DEC_Coverage_Is_Decided_On_The_Graph` |
| 2026-08-05f | DEC-MTH-027 | `DEC_The_Agent_Index_Is_Generated_Not_Committed` |
| 2026-08-05g | DEC-MTH-028 | `DEC_AGENTS_File_Forwards_It_Does_Not_Duplicate` |
| 2026-08-05h | DEC-MTH-029 | `DEC_The_Method_Carries_A_Version` |
| 2026-08-05i | DEC-MTH-031 | `DEC_A_REQ_File_Without_A_Table_Is_A_Process_Defect` |
| 2026-08-05j | DEC-MTH-030 | `DEC_Safety_Standard_Correspondence_Is_Structural` |
| — (the migration itself) | DEC-MTH-032 | `DEC_The_Decision_Log_Moves_Into_A_Vault` |

**One date used to resolve to nothing: `2026-07-28g`.** No amendment ever
carried it. It was cited four times: twice in this repository's own sources
(`validate_vault.py`, `tests/run.sh`) and twice inside the record migrated as
`DEC_A_Non_UTF8_File_Says_Which_Encoding` — always for the condition under which
`section-mismatch` became the first ERROR to enter the stop gate's blocking set.
That condition is stated in `DEC_A_Near_Miss_Is_Not_An_Absence` (2026-07-31),
the amendment that introduced the code. The migration left the wrong date
standing wherever it was written, because correcting it inside a record would be
editing the record; on 2026-08-08 all four citations were retargeted to
`2026-07-31` (issue #74, DEC-MTH-035), so every date the tools cite now
resolves to a row above.

The ID order is the order the log appended in, which is why `2026-08-04e` holds
DEC-MTH-018 while `2026-08-04d` holds DEC-MTH-019: the suffixes were assigned
when the pull requests landed. The rows above are sorted by date so a citation
can be looked up; `system_overview.md` lists the same notes in record order.

The full text of every record is in git history, at the last commit that
contained it.
