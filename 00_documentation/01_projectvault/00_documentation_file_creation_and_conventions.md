The following questions should be asked before creating any file to ensure consistent documentation. If one of these questions cannot be clearly answered, then no file should be created.

## 1) Right to Exist

**Question 1:** Does this information have a right to exist?
	- No: Information should not be documented
	- Yes: Continue with question 2.

**Question 2:** What SINGLE main question does this file answer that is not already answered by another file (Single Source of Truth)?
	- cannot be clearly stated: Subdivide the file into further files until **one** clear main question per file can be answered
	- clear answer: continue with question 3.

---
## 2) Role Determination

**Question 3:** Which role does this information belong to?
	- cannot be clearly classified: File must be further subdivided until the file fulfills only **one** role
	- one clear role: Classification, continue with question 4.

Exactly one role must be chosen per file:

| Folder                              | Purpose                             | Timeline | Question                                       |
| ----------------------------------- | ----------------------------------- | -------- | ---------------------------------------------- |
| `01_requirements_(REQ)`             | Goal definition, framework, constraints | Stable   | What should be achieved?                       |
| `02_decisions_(DEC)`                | Why something is the way it is      | Slow     | Why was something chosen?                      |
| `03_architecture_(ARC)`             | System context                      | Medium   | How does everything connect?                   |
| `04_components_(CMP)`               | Physical / logical building blocks  | Stable   | What do references say about a component?      |
| `05_interfaces_(IFC)`               | Contracts between parts             | Slow     | How do two system modules communicate?         |
| `06_implementation_(IMP)`           | Volatile implementation             | Fast     | How is it implemented?                         |
| `07_testing_and_evidence_(TAE)`     | Evidence, measurements              | Slow     | Did it work?                                   |
| `08_operation_and_usage_(OAU)`      | Practice, maintenance               | Medium   | What do operation and usage look like?         |
| `09_references_(REF)`               | External truth, summarized          | Stable   | What does the external reference say?          |
| `98_administration_(ADM)`           | Project logistics                   | Medium   | What do I need for project management?         |
| `99_inbox_(INB)`                    | Unclassified raw material           |          |                                                |


**Question 4:** In which timeline does this information live?
	 - in multiple: Subdivide file until all information lives in one timeline
	 - in exactly one: File may be created. The answer to the main question should be chosen as the heading.

Possible timelines:
- Stable (practically never changes)
- Slow
- Medium
- Fast

---
## 3) File Conventions (human- and AI-readable)

These conventions keep every file usable both for humans in Obsidian and
for AI agents that find content by exact text search. The mechanically
checkable subset is enforced by the vault validator
(`validate_vault.py` in the mechatronics-docs skill); ERRORs block,
WARNs advise.

### Frontmatter
Every domain file starts with YAML frontmatter (templates contain it):
`domain` (folder abbreviation), `status` (`draft | active | superseded |
deprecated`; DEC files keep their Status line in the body instead),
`created` and `last-verified` (both `YYYY-MM-DD`). TAE files add
`verifies: [REQ-DOM-NNN, ...]` naming the requirements they prove.
`status: draft` does not relax any rule.

### Self-containedness
The first lines of the Context section must situate the file on their
own: what it is, which module it belongs to, using exact component
names and IDs. Never rely on another file for basic understanding — no
"see above", no pronouns whose referent lives in a different file.
Search finds exact names, not implicit references.

### Wikilinks
Link with the exact filename, e.g. `[[REQ_Measurement_(MEG)]]`. Aliases
(pipe syntax with display text) are allowed for readability, but the
target must be the exact filename. Link the responsible file once where it matters —
do not link every mention (guideline: under ~20 outgoing links per
file; hub files like ARC and system_overview may carry more).

### Length
A file answers ONE question. Above ~150 lines, re-apply the 4-question
rule: can the filename still fully describe the content? If not, split.
Above 400 lines the validator blocks — that size is a structural SSOT
violation, not a formatting issue.

### Freshness
Outdated documentation is worse than none: it actively misleads both
readers and AI tools. When you touch a file and confirm its content,
update `last-verified`. When content becomes wrong, fix it or mark it
superseded/deprecated in the same work session — never leave a stale
claim standing. After changing an artifact (code, schematic, parameter),
search the vault for files referencing it and update them.
