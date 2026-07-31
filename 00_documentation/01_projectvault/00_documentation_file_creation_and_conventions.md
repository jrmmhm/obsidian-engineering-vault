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

These fields are not a habit the validator memorised: they are declared,
with their types and their permitted values, in
`.claude/skills/mechatronics-docs/vault_schema.json`, and the validator
reads that file. A key that is declared neither there nor as an editor
field — Obsidian's own `tags`, `aliases`, `cssclasses` and the
`excalidraw-*` family are recognised — is reported as
`frontmatter-undeclared`. The check exists for one specific mistake:
`crated` instead of `created` looks like a filled-in field and takes
effect nowhere. Adding a field to the vault's vocabulary is an edit to
the schema file, not a change to the validator.

### Section headings
The H2 headings a file must carry are the ones its domain template
declares. Write them as the template spells them: the heading is the
address other notes, searches and the relation bindings use, so its
spelling is part of the contract, not decoration.

The validator compares forgivingly where the difference is invisible or
cosmetic and strictly where it changes meaning. Case, umlaut encoding,
zero-width characters and collapsed whitespace do not make a section
missing — a file writing `## allgemeine Übersicht` for a template's
`## Allgemeine Übersicht` has the section, and gets a `section-near-miss`
WARN naming both spellings and the line. A title the template does not
carry is a different section: `## Ablauf (Monatlich empfohlen)` for a
required `## Ablauf`, or `## Zuordnung` for a required
`## Zuordnung und Verifikation`, is a `section-mismatch` ERROR. Keep the
template's title and put the qualifier one level down:

```markdown
## Ablauf
### Monatlich empfohlen
```

Only H2 headings are compared, and only against the template of the file's
own domain. A required section written as `###` is reported as missing,
because the level is what makes it a section rather than a subsection.

### Identifiers and typed relations
Every domain file also carries `id`, of the form `DOMAIN-SCOPE-NNN` — the
folder abbreviation, the subsystem token the matching REQ file carries in
parentheses, and a three-digit number local to that pair. Numbers are
never reused and gaps are allowed, exactly like requirement row IDs. A
REQ file uses number `000`, reserved for the file itself, so its rows
keep `001` and up. The identifier lives in the frontmatter and not in the
filename, so renaming a file does not change what it is.

Cross-domain links carry the identifier of their target after the link:
`[[CMP_Battery_Pack]] (CMP-BAT-001)`. Because an identifier starts with
its domain, an annotated link states what kind of relation it is without
anyone reading the heading above it. Which relations exist, and where
each one is written down, is declared in
`.claude/skills/mechatronics-docs/vault_schema.json`. Each relation has
exactly one place where it is authored; the opposite direction is never
written by hand.

The worked example under
[[ARC_Battery_Monitoring]] shows all of this in one thread. The validator
checks the identifiers it can see: the same value on two files is an
error, and a value that was present in the last commit but is gone now is
reported. It does not require an identifier — a file without one is not a
finding — and it does not read the relations at all.

The relations have a second reader instead. `export_traceability.py`,
beside the validator, walks them into a graph and writes the vault out as
a traceability report. Two consequences for the way you write:

The **section title is the address**, not the table's header row. A
relation table is found by the section its domain template declares, so
retitling `## Allocation and Verification` removes every relation it
carried, while reformatting the header row costs nothing but a note in
the export. This is why a differently titled section is an error and a
differently spelled one is only a warning.

Everything the export cannot resolve **becomes a line in the report**
rather than disappearing from it: a requirement ID nobody defined, a
table in a section no template declares, a status the schema does not
list, a range reaching past the last requirement. The export is allowed
to say that a vault is incomplete; it is not allowed to look complete
because something failed quietly. Schema entries flagged `export-driven`
are read by it and produce no validator finding — the exporter reports,
it never blocks.

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

### Paths and artifacts on other machines
Artifacts of this project — testdata, source code, CAD files, documents,
sources — are referenced by a path relative to the project root, starting
with its numbered top-level folder (`30_testdata/2026-01-10_run/log.csv`),
optionally with the project folder name in front of it. Only that form is
checked: a path that does not exist is an ERROR inside a References or
Sources section and a WARN elsewhere in the body, where a
`pending`/`planned`/`TBD` marker on the line or its heading suppresses it.

An artifact that lives on a different machine is written the way that
machine addresses it — absolute (`/etc/libvirt/network.conf`),
home-relative (`~/.config/hypr/monitors.conf`), qualified by host
(`omarchy:/etc/keyd/default.conf`), as a git remote or as a URL. RFC 8089
defines `file://host/path` as the formal spelling of the same thing. Name
the host in one of these ways: the path alone does not say which machine
it is true on, and a reader on a different machine cannot recover it.

The validator does not resolve any of those. It cannot tell a file that
was deleted from a file on a machine that is simply not attached, so it
reports neither — the claim is carried by you alone, and `last-verified`
is the only record that it was checked. The reverse follows: writing a
project artifact with an absolute path removes it from the check as well.
Keep project paths relative, so the vault keeps noticing when a file
moves.

The same question arises one level down, for content rather than for
paths. IMP and ARC hold no copies, because a copied artifact drifts
against its original — but a directory listing from a server, or the
command that proves a setting is in effect, is not a copy of anything
this repository holds. There is no file to point at, and the block is
the only record of that observation. In IMP such a block may stay, and
above 15 content lines it names the machine it is true on, in the fence's
info string after the language:

````
```bash host=userver
systemctl --user status navidrome
```
````

The machine name is the same one a host-qualified path uses
(`userver:/etc/systemd/system/navidrome.service`) — one fact, written in
two positions, never two different names. Write the machine, never
`localhost`: this vault is read on other machines than yours. A declared
block is reported as a warning and not silently accepted, because nothing
can verify that no source file exists; the claim stays visible and stays
yours. In ARC no block is permitted at all, declared or not.

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
