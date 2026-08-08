---
domain: DEC
id: DEC-MTH-040
created: 2026-08-08
last-verified: 2026-08-08
---
Date: 2026-08-08
Status: Accepted

## Context

Issue #77. The quick start ends in a check: the reader clones, runs the
validator, reads why one WARN is expected, and has produced nothing. The
fix is a guided path that ends in the reader's own closed REQ-TAE loop, and
it is written as `TUTORIAL.md` at the repository root.

That document has a property no other document here has. It prints file
bodies the reader copies into a vault, and it prints the output the two
tools then produce. Both halves are claims about a machine, and both rot
the same way the README excerpt rotted before
[[DEC_Generated_Content_Is_Stored_Only_Where_CI_Proves_It]] (DEC-MTH-037)
gave it a proving step.

DEC-MTH-037 ruled on stored **output** and named four conditions together:
outside every vault, delimited by marker comments, machine-independent
lines only, and a CI step that regenerates and diffs. A tutorial adds a
case it did not rule on. The pasted note bodies are stored **input** — the
fixture from which the output follows. Output alone can be regenerated
from the vault; input cannot be regenerated from anything, because it does
not exist in this repository at all. The three notes belong to the reader
and are deliberately not committed: committing them would break two
assertions that pin the shipped vault, measured on 2026-08-08 as
`370 tests, 1 failure(s)` on `run.sh` and a diff against `objects: 7` on
the README excerpt step.

So the question is where the tutorial's fixture lives, and what proves the
document still describes what the tools do.

## Options

- **A - Review promise: a reviewer re-runs the tutorial before merging.**
  Rejected. It is the same promise this repository has now twice replaced
  with a mechanism — the excerpt diff (DEC-MTH-037) and the finding-code
  index of `ARCHITECTURE.md`
  ([[DEC_Tool_Internals_Are_Documented_Beside_The_Tool]], DEC-MTH-038),
  whose own reasoning is that prose about code rots silently. A tutorial
  whose printed output is wrong fails at the one place where a new reader
  first decides whether to believe the method.
- **B - Keep the fixture as files under `tests/` and let the tutorial
  quote them.** Rejected: two copies of the same three notes, free to
  drift, and the drift would be invisible in exactly the direction that
  matters — a guard passing against a fixture the document no longer
  shows. That is the second-definition defect [[DEC_One_Cell_Splitter_For_Both_Tools]]
  and [[DEC_One_Fence_Definition_For_Both_Tools]] each removed.
- **C - Commit the three notes into the template vault so the tutorial
  points at real files.** Rejected on measurement, not on taste: the vault
  is pinned at `requirements: 3  proven: 3` by `run.sh` and at
  `objects: 7` by the README excerpt step, and the notes are the reader's
  own by the issue's own framing.
- **D - The document is the fixture: CI extracts the marked blocks from
  `TUTORIAL.md`, writes them into a throwaway project, runs the commands
  the tutorial prints and diffs the machine-independent lines (chosen).**

## Decision

**A reader-facing document that instructs a reader to write files and then
shows what the tools print is itself the CI fixture.** Its file blocks and
its output blocks carry marker comments, a check materializes the file
blocks in a throwaway copy, runs the commands the document prints, and
diffs the output blocks against what was produced. DEC-MTH-037's four
conditions continue to govern the output side unchanged; this record adds
the input side and one condition of its own: **the fixture is extracted
from the document, never stored beside it.**

**The comparison covers only machine-independent lines, and the document is
written so that this is possible.** The validator's finding lines carry an
absolute path (`Finding.render()` is called from `main` without `rel_to`),
so the compared block holds the summary line alone and the WARN above it is
described in prose beside the block. The exporter prints eight lines, two
of which name paths; the document shows all eight and marks which two the
check compares. Index lines are vault-relative and are compared verbatim.

**The tutorial runs in a derived project, not in the template clone.** This
is what makes the reader's own CI stay green after following it — measured:
both steps of the workflow `tools/new_project.py` generates pass on a
project that has completed the tutorial. It also removes the tutorial's
dependency on the worked example entirely. Issue #77 asks that a reader who
later deletes the example lose nothing of their own; under this substrate
there is no example to delete, so the requirement is met by construction
rather than by argument, and the reader's export is `requirements: 1
proven: 1  not proven: 0` with nothing borrowed. `TUTORIAL.md` is therefore
template-repo-only and is stripped by `tools/new_project.py`.

**The check lives in `tests/run.sh`, not in the workflow.** The excerpt
guard sits in the workflow because it diffs a repository file against a
fresh export; this one derives a project and runs a sequence, which is what
the suite already does for `tools/new_project.py`. `run.sh` is CI step one
and is the run `CONTRIBUTING.md` names as the one that has to be green
first, so a contributor meets the break before the push rather than after
it. [[DEC_CI_Blocks_On_What_A_Session_Only_Warns_About]] (DEC-MTH-039)
rejected `tests/run.sh` for `--fail-on` because the suite is stripped from
a derived project and the rule had to reach every vault. That reasoning
does not reach here and the rejection stands unamended: this check is about
a document that is itself stripped, so the suite is exactly the right
scope.

## Justification

- The document's two claims about a machine become checkable by the same
  argument DEC-MTH-037 made for the README: a number a machine recomputes
  beats a number somebody wrote.
- One copy of the fixture. Option B's second copy could drift silently in
  the only direction that matters.
- The reader is never asked to write down a result they do not have. The
  allocation row is `Draft` with an empty evidence cell until the reader
  has run the validator, and the evidence they paste is the line their own
  run printed — `CONTRIBUTING.md` and `CLAUDE.md` rule 7 both require that
  order, and a tutorial that broke it would teach the defect the method
  exists to prevent.
- Every intermediate state is free of ERRORs, so nothing blocks a reader
  working through Claude Code: measured `0 error(s), 3 warning(s)` after
  the first file and `0 error(s), 4 warning(s)` after the second. The REQ
  note names its module in plain text instead of linking back to it, which
  is also the correct reading of the convention that a relation has exactly
  one place where it is authored — the annotated list in the ARC note.

## Consequences

### Realization

- `TUTORIAL.md` - new, at the repository root, outside every vault. Three
  `tutorial-file` blocks, one `tutorial-row` block, three
  `tutorial-output` blocks.
- `.claude/skills/mechatronics-docs/tests/run.sh` - one self-contained
  block appended at the end, no new `trap` (traps in that file overwrite
  rather than accumulate and would silently drop eleven existing cleanup
  roots), an explicit `rm -rf` at the block's end, and the tutorial's
  commands run inside a subshell so the file stays CWD-independent.
- `tools/new_project.py` - `TUTORIAL.md` in `STRIP_PATHS`.
- `.github/workflows/validate-vault.yml` - the excerpt step's comment no
  longer claims the README is the one place where generated content is
  committed; there are now two, each with its own proving mechanism.
- `README.md`, `CHANGELOG.md` - the link into the tutorial, and the entry.

### The limit of a replay, stated

A replay proves the tutorial still **runs** and still prints what it says
it prints. It proves nothing about whether the tutorial **teaches** — that
the order is followable, that the explanation lands, that ten minutes is
the real figure. That is the documented limit of every docs-as-tests
mechanism, and it is written here so that a green check is not read as more
than it is. The ten-minute claim in particular is an estimate and carries
no evidence.

### Accepted residuals

1. **A red run for a file the author did not write.** DEC-MTH-037 accepted
   this for the excerpt and it holds here in a narrower form: only a change
   to the templates, the schema, the validator's or the exporter's output
   wording, or the derivation moves this block. The worked example no
   longer can, which is one trigger fewer than the excerpt has.
2. **The reader reads the tutorial from the clone they derived from.**
   `TUTORIAL.md` does not travel into the derived project, so the document
   sits one directory up while the reader works. Named in the tutorial in
   one sentence; a copy travelling along would carry a step 0 that is
   false there.
3. **The first module a reader documents is their own documentation
   check.** It is the only subject whose evidence both the reader and CI
   can produce on any machine with no setup. A domain example would need
   hardware or an observation neither can replay. The requirement is about
   a deliverable of the project rather than about the tooling, so the
   boundary [[DEC_The_Decision_Log_Moves_Into_A_Vault]] (DEC-MTH-032) drew
   between the two vaults is not crossed — but the lesson can be swapped
   for a domain example later at the cost of one file's content, without
   touching the mechanism.
