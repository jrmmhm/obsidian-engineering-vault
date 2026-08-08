To ensure consistent high-quality documentation, rules and guidelines have been divided into a series of files that together provide the user with a comprehensive guide.

## Quick Orientation

- Requirements → `01_requirements_(REQ)`
- Decisions/Why → `02_decisions_(DEC)`
- Architecture/Assignment+Verification → `03_architecture_(ARC)`
- Components/Details relevant for project → `04_components_(CMP)`
- Interfaces/connections → `05_interfaces_(IFC)`
- Implementation/Artifact paths → `06_implementation_(IMP)`
- Evidence/Measurements → `07_testing_and_evidence_(TAE)`
- Operation/Runbooks → `08_operation_and_usage_(OAU)`
- Source extracts → `09_references_(REF)`

**Important:** The files under 03_architecture_(ARC) represent the individual project modules and combine files into an overall picture. The central starting point for the project and its architecture can be found at [[system_overview]].

## Start With Three, Grow Into Nine

Nine domains is where a project ends up, not where it starts. Three of them
carry the loop the tools decide on: a requirement in `01_requirements_(REQ)`,
an allocation row in `03_architecture_(ARC)` that gives that requirement an
owner and a status, and an evidence note in `07_testing_and_evidence_(TAE)`
naming it in `verifies:`. Every coverage statement the validator and the
traceability export make is decided on those three. A project can start
there, close a real loop on its first day, and meet the rest when they
become due.

The other six are not optional in the long run — they are *not yet due*.
Each row below names the day its domain typically joins and where that
trigger comes from, so the question is never "do I need this folder?" but
"has this happened yet?".

| Domain | Joins when | Where the trigger comes from |
| ------ | ---------- | ---------------------------- |
| `01_requirements_(REQ)` | Day one. Everything else is defined on requirements. | The coverage report is computed per requirement; a traceability export armed against a vault carrying none fails on purpose. |
| `03_architecture_(ARC)` | Day one. The allocation row is where a requirement gets an owner, a verification link and a status. | `00_ARC_README`, the Allocation and Verification table; a requirement no row names is reported as not allocated. |
| `07_testing_and_evidence_(TAE)` | Day one — filled the first time you actually check something. | `00_TAE_README` and the `verifies:` field; a requirement no evidence note names is reported as uncovered. |
| `02_decisions_(DEC)` | The first time a choice had a real alternative and you would otherwise argue it again in six months. | `00_DEC_README`: "represents a choice between alternatives", "could have been different"; a REQ row's Source column asking for a `DEC` link. |
| `06_implementation_(IMP)` | The first artifact outside the vault — code, schematic, CAD, a configuration — that someone has to find. | `00_IMP_README`: IMP files are pointers, not duplicates; your ARC module's Implementation section stops reading "None yet." |
| `04_components_(CMP)` | The first part you buy or build whose datasheet decides something in more than one place. | `00_CMP_README`'s decision rule: a manufacturer datasheet and no further decomposition make an individual part; parts with a boundary make an assembly. |
| `05_interfaces_(IFC)` | The first contract between two parts that must keep holding while the parts on either side change. | `00_IFC_README`: a contract type without endpoints; your ARC module's Interfaces table stops reading "None yet." |
| `08_operation_and_usage_(OAU)` | The first procedure somebody repeats — including you, after six months away from it. | `00_OAU_README`: "actions a human takes", "procedures that repeat over system lifetime". |
| `09_references_(REF)` | The first external source — datasheet, standard, paper — that decides something and gets quoted a second time. | `00_REF_README`: the project-relevant extract of external truth; the PDF itself belongs in `50_sources`. |

Three things are worth knowing before a domain joins late, because a start
of three is only honest if the growth path is.

**The rules of a domain live in that domain's own README.** A folder you have
not started is also a set of conventions you have not read — what belongs in
the file, what must not, which sections its template requires. Read
`00_<ABBR>_README.md` on the day the row above says the domain is due, not on
the day you first need the note. The table exists so that day is a
recognisable event rather than a surprise.

**A late domain costs no migration.** Nothing you already wrote is renumbered,
retitled or re-linked when a domain joins. The folder arrives with its own
file template, and the validator derives the required sections from that
template, so the new domain brings its rules with it and the notes around it
are untouched. If this project was derived with the minimal profile, the
waiting folders are in `00_documentation/03_vault_domains_not_in_use/` and a
domain joins by moving its folder back — move it rather than creating a fresh
one beside it, or the two folders collide on their file names.

**Your ARC notes keep all their sections meanwhile.** The ARC template asks
for Decisions, Components, Interfaces and Implementation even in a project
that has none of those domains yet. Answer them `None yet.` — that is what
the tutorial's own module does, and it is an honest empty compartment rather
than a missing one.

## Understanding

A deep understanding of the documentation method is achieved by reading all _00_filename_ files.

The starting point involves questions about when a file may be created at all, and how it should be sorted into the folder structure. These questions are listed and explained in [[00_documentation_file_creation_and_conventions]].

After successfully answering each of these questions, a file may be created with the filename:
_**FolderAbbreviation_AnswerToTheMainQuestion**_

The creation of subfolders is explained in [[00_documentation_subfolders]].

Once it is understood when a file may be created, how it should be sorted into the existing folders, and when a subfolder should be created, it is recommended to look at the README files and file templates of each main folder. The README file explains what should explicitly be sorted under this folder, and what the file template describes. The file template provides a file template to consistently structure files and clearly answer what belongs in a file. For each new file in a main folder, it is recommended to duplicate the file template and build the new file according to the duplicated template.

These files can be found in each main folder under:
`/XX_foldername_(FolderAbbreviation)`
	- `/00_FolderAbbreviation_README`
	- `/00_FolderAbbreviation_file_template`

## AI Documentation Layer

This vault is written for two audiences: humans reading in Obsidian and
AI agents that retrieve context by exact text search. The conventions in
[[00_documentation_file_creation_and_conventions]] (frontmatter,
self-containedness, wikilink discipline, length, freshness) exist for
both. The mechanically checkable subset is enforced by a validator
(`validate_vault.py`, part of the `mechatronics-docs` skill that ships
with this template under `.claude/skills/`): it checks naming, required
template sections, frontmatter, link and artifact-path integrity,
requirement-table format and REQ↔TAE coverage, and flags implementation
details leaking into ARC. Run it manually from the project root with
`python3 .claude/skills/mechatronics-docs/validate_vault.py 00_documentation/01_projectvault`.

The second tool of that skill reads this vault as a graph and writes it out
beside the project: `python3 .claude/skills/mechatronics-docs/export_traceability.py 00_documentation/01_projectvault --output-dir ../traceability`
produces, next to the report and the two CSV views, a
`traceability_index.md` carrying one line per object and per requirement —
the fastest way to see what this vault contains without opening it file by
file. It is generated on the spot, never stored here: the vault is the
source, the export is derived from it.


Finally, it is recommended to open [[system_overview]], as it centrally describes and explains the main modules in the form of ARC files. The system overview thus serves as a central point of contact.

---

## Onboarding Path (Recommended Reading Order)

For new project members, the following reading path is recommended:

| Step | File | Goal |
| ------: | ----- | ---- |
| 1 | [[00_documentation_file_creation_and_conventions]] | Understand SSOT principle and role matrix |
| 2 | [[00_documentation_subfolders]] | 3-question rule for subfolders |
| 3 | [[00_glossary]] | Look up abbreviations and technical terms |
| 4 | [[system_overview]] | Get to know top-level modules |
| 5 | [[00_ARC_README]] | Understand ARC structure and verification table |
| 6 | [[00_REQ_README]] | Requirements ID schema (REQ-DOM-NNN) |
| 7 | Any ARC module of interest | Deepen knowledge in specific module |
