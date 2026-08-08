# System overview — the method's decisions

One line per decision, in the order the record was written. That order is the
order the appended log carried, which is not always date order: the suffix of an
amendment was assigned when its pull request landed, so `2026-08-04e` stands
before `2026-08-04d` and `2026-08-05j` before `2026-08-05i`. Renumbering them
would invent a history nobody had.

Every entry up to [[DEC_The_Decision_Log_Moves_Into_A_Vault]] is a verbatim
migration of one amendment of `.claude/skills/mechatronics-docs/DECISIONS.md`;
the title column repeats the source heading. Entries after it are decisions
made since the migration and written here directly. Where a later record
corrects a statement of an earlier one, the earlier file carries a
`Corrected by:` line above its Context.

| ID | Date | Decision |
| --- | --- | --- |
| DEC-MTH-001 | 2026-07-25 | [[DEC_Enforcement_Layer_For_The_Vault_Conventions]] — an enforcement layer for the vault conventions |
| DEC-MTH-002 | 2026-07-27 | [[DEC_E2E_Test_Driven_Hardening]] — E2E-test-driven hardening |
| DEC-MTH-003 | 2026-07-28 | [[DEC_Language_Independent_Recognition_And_VCS_Tier]] — language-independent recognition, VCS tier |
| DEC-MTH-004 | 2026-07-28b | [[DEC_Object_Identity_And_Typed_Relations]] — object identity and typed relations |
| DEC-MTH-005 | 2026-07-28c | [[DEC_Identifier_Enforcement]] — identifier enforcement |
| DEC-MTH-006 | 2026-07-28d | [[DEC_Schema_Driven_Field_Validation]] — schema-driven field validation |
| DEC-MTH-007 | 2026-07-28e | [[DEC_One_Project_Path_Definition_In_Both_Zones]] — one project-path definition in both zones |
| DEC-MTH-008 | 2026-07-28f | [[DEC_Records_Not_Copies_For_Fenced_Blocks]] — records, not copies, for fenced blocks whose source is not a file here |
| DEC-MTH-009 | 2026-07-31 | [[DEC_A_Near_Miss_Is_Not_An_Absence]] — a near miss is not an absence |
| DEC-MTH-010 | 2026-07-31b | [[DEC_Reading_The_Vault_As_A_Graph]] — reading the vault as a graph |
| DEC-MTH-011 | 2026-08-01 | [[DEC_One_Fence_Definition_For_Both_Tools]] — one fence definition for both tools |
| DEC-MTH-012 | 2026-08-01b | [[DEC_One_Cell_Splitter_For_Both_Tools]] — one cell splitter for both tools |
| DEC-MTH-013 | 2026-08-01c | [[DEC_Frontmatter_Reader_Learns_The_Editor_Spelling]] — the frontmatter reader learns the spelling the editor writes |
| DEC-MTH-014 | 2026-08-01d | [[DEC_Link_Matcher_Reads_Two_Unseen_Shapes]] — the link matcher reads the two shapes it never saw |
| DEC-MTH-015 | 2026-08-04 | [[DEC_One_BOM_Safe_Reader_For_Every_File]] — one BOM-safe reader for every file the validator opens |
| DEC-MTH-016 | 2026-08-04b | [[DEC_Requirement_Table_Recognised_By_Shape]] — a requirement table is recognised by its shape, not by its header text |
| DEC-MTH-017 | 2026-08-04c | [[DEC_A_Non_UTF8_File_Says_Which_Encoding]] — a file that is not UTF-8 says which encoding it is |
| DEC-MTH-018 | 2026-08-04e | [[DEC_Every_Requirement_Table_Of_The_Bound_Section]] — every requirement table of the bound section is read |
| DEC-MTH-019 | 2026-08-04d | [[DEC_Exporter_Reports_Unread_Requirement_Rows]] — the exporter reports the requirement rows it never read |
| DEC-MTH-020 | 2026-08-04f | [[DEC_Two_Folders_One_Domain_Is_A_Finding]] — two folders meaning one domain is a finding, not a choice |
| DEC-MTH-021 | 2026-08-04g | [[DEC_One_Abbreviation_One_Folder_By_Rule]] — one abbreviation, one folder, chosen by a rule |
| DEC-MTH-022 | 2026-08-05 | [[DEC_The_Gate_Names_The_Code_That_Stopped_Firing]] — the gate says which code stopped firing |
| DEC-MTH-023 | 2026-08-05b | [[DEC_The_Stop_Report_Goes_Where_It_Is_Read]] — the stop report goes where someone reads it |
| DEC-MTH-024 | 2026-08-05c | [[DEC_A_Replicated_Link_Is_Valid_Where_Written]] — a replicated link is valid only where it was written |
| DEC-MTH-025 | 2026-08-05d | [[DEC_Two_Declared_Relations_Get_A_Source]] — two declared relations get a source the templates teach |
| DEC-MTH-026 | 2026-08-05e | [[DEC_Coverage_Is_Decided_On_The_Graph]] — coverage is decided on the graph, not on a mention |
| DEC-MTH-027 | 2026-08-05f | [[DEC_The_Agent_Index_Is_Generated_Not_Committed]] — the index an agent reads is generated, not committed |
| DEC-MTH-028 | 2026-08-05g | [[DEC_AGENTS_File_Forwards_It_Does_Not_Duplicate]] — AGENTS.md forwards, it does not duplicate |
| DEC-MTH-029 | 2026-08-05h | [[DEC_The_Method_Carries_A_Version]] — the method carries a version, and a breaking change is defined |
| DEC-MTH-030 | 2026-08-05j | [[DEC_Safety_Standard_Correspondence_Is_Structural]] — the correspondence to a safety standard is structural, not a claim |
| DEC-MTH-031 | 2026-08-05i | [[DEC_A_REQ_File_Without_A_Table_Is_A_Process_Defect]] — a REQ file with no table is a process defect, not a validator finding |
| DEC-MTH-032 | 2026-08-05 | [[DEC_The_Decision_Log_Moves_Into_A_Vault]] — the decision log moves into a vault of its own |
| DEC-MTH-033 | 2026-08-08 | [[DEC_One_Reverse_Key_Derivation_For_Both_Readers]] — one reverse-key derivation for both readers of the graph |
| DEC-MTH-034 | 2026-08-08 | [[DEC_Requirement_Index_Follows_The_Role_Map]] — the requirement index follows the role map |
| DEC-MTH-035 | 2026-08-08 | [[DEC_A_Phantom_Citation_Is_Retargeted]] — a citation that resolves to no record is retargeted, not preserved |
| DEC-MTH-036 | 2026-08-08 | [[DEC_Deriving_A_Project_Is_One_Command]] — deriving a project is one command |
| DEC-MTH-037 | 2026-08-08 | [[DEC_Generated_Content_Is_Stored_Only_Where_CI_Proves_It]] — generated content is stored only where CI proves it current |
| DEC-MTH-038 | 2026-08-08 | [[DEC_Tool_Internals_Are_Documented_Beside_The_Tool]] — maintainer-facing tool internals are documented beside the tool |
| DEC-MTH-039 | 2026-08-08 | [[DEC_CI_Blocks_On_What_A_Session_Only_Warns_About]] — CI blocks on what a session only warns about |
| DEC-MTH-040 | 2026-08-08 | [[DEC_A_Tutorial_Is_Replayed_Not_Reviewed]] — a tutorial is replayed, not reviewed |

DEC-MTH-032 is the only entry of the log's own era that was not migrated: it
is the decision that performed the migration, and it is written here rather
than in the file it retires.
