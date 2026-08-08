---
domain: DEC
id: DEC-MTH-041
created: 2026-08-08
last-verified: 2026-08-08
---
Date: 2026-08-08
Status: Accepted

## Context

Issue #79. A reader who opens a fresh project meets nine domain
abbreviations, a timeline column and the four-question rule before writing
a single note. The tools never asked for nine: `is_vault_root` accepts a
directory with at least three domain folders and template files below them,
and `98_administration_(ADM)` and `99_inbox_(INB)` count toward that floor
like any other. A smaller start has always been legal and was never
written down.

Two claims of the issue do not survive reading the source, and the
correction decides the design rather than footnoting it. The issue names
REQ, IMP and TAE as the trio and calls the folder floor exact. The floor is
a minimum, not an equality, and it exists to tell `01_projectvault` from
`02_documents`, which mirrors the same folder names without templates. The
trio is REQ, ARC and TAE: `GAP_CLASSES` in `export_traceability.py` names
five coverage gaps, all of them decided on an allocation row in an ARC file
or on a TAE's `verifies:` field, and none of them on IMP.
[[DEC_Coverage_Is_Decided_On_The_Graph]] (DEC-MTH-026) is where that became
the rule, and [[DEC_CI_Blocks_On_What_A_Session_Only_Warns_About]]
(DEC-MTH-039) armed two of the five in CI. The tutorial that
[[DEC_A_Tutorial_Is_Replayed_Not_Reviewed]] (DEC-MTH-040) pins writes
exactly three files, and they are REQ, ARC and TAE. A project started on
REQ, IMP and TAE would carry no allocation row at all, so every one of its
requirements would stand at `not-allocated` forever.

The second half of the problem is the one that decides whether this is
worth doing. A reduced start that nobody grows out of leaves an author
meeting rules years later that they never read — the domain README they
skipped is the one that says what belongs in the file they are now writing.
So the deliverable is staged guidance with a named trigger per domain, and
the folder reduction is what makes that guidance concrete.

`tools/new_project.py` already derives a project in one command
([[DEC_Deriving_A_Project_Is_One_Command]], DEC-MTH-036) and refuses to
report success unless the derived vault matches a predicted validator
state. Whatever the reduced profile does must survive that prediction, and
must leave the default derivation untouched, because the tutorial replay
guard reads the default path's numbers.

## Options

- **A — Documentation only, no flag.** A staging section plus one sentence
  per domain README; the reader deletes folders by hand or leaves them.
  Rejected: it is the prose checklist DEC-MTH-036 replaced, one level
  down. Every hand step is a chance to do it half, and the issue asks for
  the flag by name.
- **B — `--minimal` deletes the six folders.** Rejected on measurement.
  The derived vault then reports a second warning, because the one link
  that points out of the vault into a removed domain
  (`See [[00_DEC_README]].` in the conventions file) resolves nowhere. And
  a folder recreated by hand later arrives without its file template:
  `check_sections` returns without enforcing anything when a domain has no
  template, so the domain would come back with its section rules silently
  switched off.
- **C — `--minimal` parks the six folders inside `00_documentation/`.**
  The vault keeps REQ, ARC and TAE beside ADM and INB; DEC, CMP, IFC, IMP,
  OAU and REF move to `00_documentation/03_vault_domains_not_in_use/` and
  come back with one `mv`. Chosen.
- **D — Park outside `00_documentation/`, under `99_archive/`.**
  Rejected, and the trade is recorded because it is real: parking there
  would take the six folders out of the Obsidian pane, which C does not.
  It costs the resolving link of option B and misnames the state —
  `99_archive` holds superseded material, and a domain not started yet is
  not superseded.

## Decision

Option C. `--minimal` is a boolean flag beside the existing
`--rename-docs-readme`, it composes with `--name`, and four properties are
part of the decision rather than of the implementation:

1. The parking lot lives under `00_documentation/`, so every wikilink
   still resolves through the name index the validator builds over the
   whole documentation root — a minimal vault reports the same single
   known warning as the default one.
2. The marker file there is named `00_domains_not_in_use_README.md` and
   not `README.md`. A third `README` stem under `00_documentation` would
   make the zero-warning promise of `--rename-docs-readme` unreachable;
   measured, the two names differ by exactly that one warning.
3. `--minimal` refuses when a folder it would park carries notes. The
   script copies a working tree, so a clone that already documents
   something is a legal input, and parking a domain out of the vault
   would cut its notes out of the graph while the validator stays green.
4. The default derivation is not touched at all: no strip-list entry, no
   replacement, no output line. The tutorial's numbers are its witness.

## Justification

- The trio the tools decide on is the trio the profile ships, so a minimal
  project can close a loop on its first day instead of discovering that
  its requirements can never leave `not-allocated`.
- Parking beats deleting on both halves of the growth promise: the
  validator and the exporter report the same state before and after a
  domain returns, and the domain returns with the template that re-arms
  its section rules.
- The staged triggers are taken from files this repository already ships —
  each domain's own README, the ARC allocation rule, the tutorial's three
  steps — so the guidance says when to read a rule that exists, and
  invents no project-management prose.
- No rule moves. The validator, the schema and the templates are
  untouched; a vault that was clean stays clean, and the reduced start was
  legal before this decision wrote it down.

## Consequences

- The parking lot is vault-shaped: it holds domain folders with template
  files, so `is_vault_root` recognises it. A hook walking upward from a
  file edited inside it would treat it as a vault root. The consequence is
  harmless — parked files are infra files, whose links are never checked
  strictly — but it is real and is named here rather than discovered.
- Nothing validates the parking lot in a derived project: the derived
  workflow audits the vault by path. A parked folder is checked again the
  moment it moves back in.
- A domain returns by moving the folder, never by creating a fresh one
  beside it. Two folders of one domain under `00_documentation` would
  collide on their basenames, and inside the vault they would be reported
  as `domain-duplicate-folder`.
- `00_documentation/02_documents/` keeps mirroring all nine domains in a
  minimal project. An empty folder makes no claim, and pruning it would
  cost a second reduction path for no reader.
- The staging table lives in the vault README as the single source; the
  conventions file and the nine domain READMEs point at it and repeat
  nothing.
- The refusal counts the notes that would survive the derivation, not every
  note it sees. Four of the six parked folders hold the worked example,
  which the strip list removes anyway — counting it would make `--minimal`
  refuse in the template repository itself, the one clone every derivation
  starts from. This was found by running the guard, not by reading it.
