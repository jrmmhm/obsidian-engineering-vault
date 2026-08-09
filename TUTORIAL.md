# Your first closed loop

About ten minutes, three files, two commands. At the end a report says that
one requirement of your project is proven, and names the evidence that
proves it — computed from what you wrote, not claimed by anybody.

No theory here. When you want it,
`00_documentation/01_projectvault/00_documentation_file_creation_and_conventions.md`
is the file that explains why any of this is shaped the way it is.

You need a clone of this repository and Python 3. Obsidian is not required.

---

## Step 0 — Make yourself a project

The tutorial writes into *your* project, not into this template. One
command from the clone:

```bash
python3 tools/new_project.py ../my-first-project
cd ../my-first-project
```

It copies the template, removes the worked example and everything only the
template repository needs, and finishes by running your new vault's
validator. The last line says `Verified: matches the predicted state`.

Everything below happens in `../my-first-project`. This file stays behind in
the clone — keep it open in the other window, or read it on GitHub.

---

## Step 1 — What must hold

Create
`00_documentation/01_projectvault/01_requirements_(REQ)/REQ_Documentation_Check (DOC).md`:

<!-- tutorial-file: 01_requirements_(REQ)/REQ_Documentation_Check (DOC).md -->
```markdown
---
domain: REQ
status: active
created: 2026-08-08
last-verified: 2026-08-08
id: REQ-DOC-000
---
## Context

Requirements on the documentation of this project, held by
the module ARC_Documentation_Check (ARC-DOC-001): the vault is checked
mechanically before anyone else reads it. Covers the state the check must
report. Excludes what the notes say — that is each note's own business.

This file carries the scope token `DOC`; its requirement rows are
addressed as `REQ-DOC-NNN`, the file itself as `REQ-DOC-000`.

**Requirement line ID:** REQ-_DOC_-_NNN_ (Explanation: [[00_REQ_README]])

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source / Justification (REF/DEC) |
| ------------- | --: | ------- | -------------------- | -------------------------------- |
| M | 001 | The project documentation shall carry no validator ERROR. | Pass if the validator's summary line reports 0 error(s). | Project rule: documentation is checked, not assumed. |
```

Two lines carry the whole file. `id: REQ-DOC-000` names the file itself;
`000` is reserved for that, so the rows start at `001`. The row's second
cell, `001`, makes it the requirement `REQ-DOC-001` — that identifier is
what everything else will point at.

Use today's date in both date fields. Change nothing else yet; the file
names its module in plain text on purpose, because the link between the two
is written once, in the next file.

---

## Step 2 — Where it belongs

Create
`00_documentation/01_projectvault/03_architecture_(ARC)/ARC_Documentation_Check.md`:

<!-- tutorial-file: 03_architecture_(ARC)/ARC_Documentation_Check.md -->
```markdown
---
domain: ARC
status: active
created: 2026-08-08
last-verified: 2026-08-08
id: ARC-DOC-001
---
## Context

Documentation check module: it holds the rule that this project's
documentation is checked mechanically, and the evidence of the last run.

**Includes:**
- The rule that the documentation carries no validator ERROR
- The evidence of a validator run

**Excludes:**
- What the individual notes say

**Related Modules:**
- None yet.

## Requirements (Files)

- [[REQ_Documentation_Check (DOC)]] (REQ-DOC-000): States what the check
  must report for this project.

## Decisions (Files)

- None yet.

## Components (Files)

- None yet.

## Interfaces

| Interface (IFC) | Endpoint A | Endpoint B | Context |
| --------------- | ---------- | ---------- | ------- |
| None yet. | | | |

## Implementation (Files)

- None yet.

## Allocation and Verification

| Submodule (ARC/CMP/IFC) | Allocated Requirements (REQ-IDs) | Verification (TAE) | Status |
| ----------------------- | -------------------------------- | ------------------ | ------ |
| [[ARC_Documentation_Check]] (ARC-DOC-001) | REQ-DOC-001 |  | Draft |
```

The last table is the load-bearing one. Its row says: this module owns
`REQ-DOC-001`, nothing verifies it yet, status `Draft`. That is the honest
state — you have no evidence, so you claim none.

The link `[[REQ_Documentation_Check (DOC)]] (REQ-DOC-000)` is annotated with
the target's identifier. That annotation is what turns a link into a
relation the export reads; without it, it stays navigation.

---

## Step 3 — Put the module on the map

In `00_documentation/01_projectvault/system_overview.md`, replace the
placeholder row

```
| *Add your modules here* | *Brief description of the module* |
```

with yours:

<!-- tutorial-row: overview -->
```
| [[ARC_Documentation_Check]] | Keeps this project's documentation free of validator errors |
```

A module missing from this table is a documentation island, and the
validator says so as `arc-not-in-overview`.

---

## Step 4 — Measure what you have

Two commands. First the validator:

```bash
python3 .claude/skills/mechatronics-docs/validate_vault.py \
        00_documentation/01_projectvault
```

Its last line:

<!-- tutorial-output: validator-draft -->
```text
-- 0 error(s), 2 warning(s), 0 near miss(es)
```

Zero ERRORs — the gate. Above that line stand the two warnings, each naming
its file with a path on your machine. One is the known `duplicate-basename`
your generated README explains. The other is the one that matters now:

```
[req-uncovered] REQ-DOC-001 is named by no TAE in 'verifies' - an unverified
REQ is indistinguishable from an unmet one
```

Now the exporter:

```bash
python3 .claude/skills/mechatronics-docs/export_traceability.py \
        00_documentation/01_projectvault --output-dir ../traceability
```

It prints eight lines. Two of them name your vault path and your output
directory; the other six are the same on every machine:

<!-- tutorial-output: export-draft -->
```text
requirements: 1  proven: 0  not proven: 1
objects: 2  relations: 2  findings: 0
bound arc_allocation_table -> '## Allocation and Verification'
bound arc_interface_table -> '## Interfaces'
bound arc_main_module_table -> '## Submodules'
bound req_table -> '## Context'
```

`not proven: 1`. Open `../traceability/traceability.html` and your one
requirement is there with the reason spelled out — *no evidence note names
this requirement in `verifies`*. Nothing is hidden in an empty cell.

Close that gap next.

---

## Step 5 — Write down what you observed

Create
`00_documentation/01_projectvault/07_testing_and_evidence_(TAE)/TAE_Vault_Validator_Run.md`,
and in the Evidence section paste **the summary line your own run in step 4
printed**:

<!-- tutorial-file: 07_testing_and_evidence_(TAE)/TAE_Vault_Validator_Run.md -->
````markdown
---
domain: TAE
status: active
created: 2026-08-08
last-verified: 2026-08-08
verifies: [REQ-DOC-001]
test-object: [ARC-DOC-001]
id: TAE-DOC-001
---
## Context

Validator run over the documentation of this project, the module
[[ARC_Documentation_Check]] (ARC-DOC-001), checked against REQ-DOC-001 of
[[REQ_Documentation_Check (DOC)]] (REQ-DOC-000). The run decides whether
the vault carries an ERROR, not whether its content is correct.

## Test Conditions

- Test object: the project vault of [[ARC_Documentation_Check]]
  (ARC-DOC-001)
- Tool: the vault validator shipped with this project
- Prerequisites: a Python 3 interpreter; the validator uses only the
  standard library

## References

_No external artifact belongs to this run: the tool and the vault are both
in this repository._

## Limitations

- The validator checks form, not truth. A note that is well formed and
  wrong passes this run.
- The run is a snapshot. It says nothing about the vault after the next
  edit.

## Evidence

Command, and the summary line it printed:

```
$ python3 .claude/skills/mechatronics-docs/validate_vault.py 00_documentation/01_projectvault
-- 0 error(s), 2 warning(s), 0 near miss(es)
```

## Conclusion

Zero ERRORs, so REQ-DOC-001 is met by this run. Both warnings are
advisory and neither is an ERROR.
````

`verifies: [REQ-DOC-001]` is the half of the loop that lives here. It is a
frontmatter field and not a sentence, because a field can be checked and a
missing sentence cannot.

The full finding lines are left out of the Evidence block on purpose: they
carry an absolute path, which is true on your machine and nowhere else.

---

## Step 6 — Close the loop

Back in `ARC_Documentation_Check.md`, replace the allocation row with:

<!-- tutorial-row: allocation -->
```
| [[ARC_Documentation_Check]] (ARC-DOC-001) | REQ-DOC-001 | [[TAE_Vault_Validator_Run]] (TAE-DOC-001) | Verified |
```

`Verified` is allowed now, and only now: a TAE link exists and its evidence
is written down. That order is the rule, not a formality.

---

## Step 7 — See it

Run the same two commands again.

<!-- tutorial-output: validator-final -->
```text
-- 0 error(s), 1 warning(s), 0 near miss(es)
```

The `req-uncovered` warning is gone — you closed what it was pointing at.

<!-- tutorial-output: export-final -->
```text
requirements: 1  proven: 1  not proven: 0
objects: 3  relations: 5  findings: 0
bound arc_allocation_table -> '## Allocation and Verification'
bound arc_interface_table -> '## Interfaces'
bound arc_main_module_table -> '## Submodules'
bound req_table -> '## Context'
```

`proven: 1  not proven: 0`. Your loop, read back out of your own files:

```bash
grep -- -DOC- ../traceability/traceability_index.md
```

<!-- tutorial-output: index -->
```text
- `ARC-DOC-001` · ARC · `03_architecture_(ARC)/ARC_Documentation_Check.md` · Documentation check module: it holds the rule that this project's documentation is checked mechanically, and the evidence of the last run.
- `REQ-DOC-000` · REQ · `01_requirements_(REQ)/REQ_Documentation_Check (DOC).md` · Requirements on the documentation of this project, held by the module ARC_Documentation_Check (ARC-DOC-001): the vault is checked mechanically before anyone else reads it.
- `TAE-DOC-001` · TAE · `07_testing_and_evidence_(TAE)/TAE_Vault_Validator_Run.md` · Validator run over the documentation of this project, the module ARC_Documentation_Check (ARC-DOC-001), checked against REQ-DOC-001 of REQ_Documentation_Check (DOC) (REQ-DOC-000).
- `REQ-DOC-001` · REQ · `01_requirements_(REQ)/REQ_Documentation_Check (DOC).md:22` · The project documentation shall carry no validator ERROR.
```

The `:22` is the line your requirement row sits on; if you edited the
Context above it, yours will differ.

Now look at it instead of reading it. The same run drew your loop:

```bash
cat ../traceability/traceability_graph.mmd
```

<!-- tutorial-output: graph -->
```text
flowchart LR
  %% Coverage graph of this vault, generated by export_traceability.py.
  %% Drawn are the three relations coverage is decided on - allocates,
  %% evidence, verifies. The complete edge set is in traceability.json
  %% and traceability_edges.csv. Regenerate this rather than editing
  %% it: the vault is the source and this diagram is derived from it.
  o_ARC_DOC_001["ARC-DOC-001<br>ARC_Documentation_Check"]
  o_TAE_DOC_001["TAE-DOC-001<br>TAE_Vault_Validator_Run"]
  r_REQ_DOC_001("REQ-DOC-001<br>proven")
  o_ARC_DOC_001 -->|"allocates: Verified"| r_REQ_DOC_001
  o_ARC_DOC_001 -->|"evidence: Verified"| o_TAE_DOC_001
  o_TAE_DOC_001 -->|"verifies"| r_REQ_DOC_001
```

Three nodes and three arrows: your module owns the requirement, points at
the note, and the note names the requirement back. That is Mermaid, and
GitHub draws it. Paste it into any Markdown file in your repository
between a line reading ` ```mermaid ` and a closing ` ``` `, push, and the
picture is on the page — or open the vault in Obsidian, which renders the
same block. Regenerate it rather than keeping the copy: the vault is the
source, and the loop you just closed is the only reason the picture shows
three arrows instead of two.

Then open `../traceability/traceability.html` — the report you would hand
to a reviewer. Your requirement, its acceptance criterion, the module it is
allocated to, the note that proves it, and `proven`.

> On Windows without a POSIX shell: `python3` may be spelled `python`, the
> trailing `\` is a line continuation you can drop by writing the command on
> one line, and instead of `grep` use `Select-String -Pattern "-DOC-"` — or
> just open `traceability_index.md` and search for `-DOC-`.

---

## What you just did

You wrote what must hold, where it belongs and what proves it, in three
files that each answer one question — and a tool read them back as a graph
and confirmed the loop was closed. Nothing in that report was typed by hand.

`proven: 1` will grow. `not proven` is the number worth watching: it is what
this method exists to keep honest.

Now the theory, in the order it pays off:

1. `00_documentation/01_projectvault/00_documentation_file_creation_and_conventions.md`
   — the rules a note follows, and the four questions before any file exists.
2. `00_documentation/01_projectvault/README.md` — the nine domains and the
   reading order.
3. `STRUCTURE.md` — which folder holds which kind of artifact.

Your three files are yours. Nothing in them points at this template's
worked example, and no update to the template can take them away.
