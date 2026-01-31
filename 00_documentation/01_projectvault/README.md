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
