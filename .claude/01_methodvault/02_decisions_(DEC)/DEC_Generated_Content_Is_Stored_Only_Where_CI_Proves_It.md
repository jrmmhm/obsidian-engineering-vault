---
domain: DEC
id: DEC-MTH-037
created: 2026-08-08
last-verified: 2026-08-08
---
Date: 2026-08-08
Status: Accepted

## Context

Issue #78. The README argues for the method for several screens before it
shows anything the method produces: to see the payoff a reader has to
clone the repository, run the exporter and open the HTML report. The
obvious fix - put the export's real output near the top - is the one
thing this repository tells everybody else not to do.

`STRUCTURE.md` states it about the index, and states it generally:
"It stays generated rather than committed: a stored index is only as
current as its last run, and the vault is what it is derived from.
`CLAUDE.md` therefore names the command, not a path." `CLAUDE.md` rule 15
carries the same sentence for a session reading the vault.

[[DEC_The_Agent_Index_Is_Generated_Not_Committed]] (DEC-MTH-027) already
rejected storing `traceability_index.md`, on three counts. Two of them
are about a file inside a vault: the validator measures every file it
finds there, so an index with no domain prefix, no frontmatter and no
template sections would raise `filename-prefix` and `template-sections`
and need an exemption list existing for one file; and the exporter
refuses an `--output-dir` that resolves inside a vault. Neither reaches
`README.md`, which lies outside both vaults and is measured by no
validator.

The third count does reach it, and is the question this decision has to
answer: between two commits the stored copy is wrong on disk, and an
author who edits a note without running the exporter gets a red pipeline
for a file they never wrote.

## Options

- **A - Leave the README as it is and keep naming the command.**
  Rejected: that is the state issue #78 names as the defect, and the
  argument paragraphs it asks to be shown up by are already good.
- **B - A rendered screenshot of `traceability.html`.** Rejected. A
  binary carries no diff, so its currency can only be checked by
  re-rendering and comparing bytes - which makes the check hostage to the
  browser version on the runner, and a flaky gate is worse than none. Left
  unchecked it is exactly the stale artifact this method exists to
  prevent, placed where the method makes its promise.
- **C - A hand-written imitation of the output.** Rejected: it is a mock,
  and the issue asks for something generated from the shipped vault
  precisely so it can be regenerated when the example changes.
- **D - The export's real output, stored between marker comments in the
  README and regenerated and diffed by CI on every push (chosen).**

## Decision

Generated content may be stored outside any vault, in reader-facing
documentation, on four conditions together: it lives outside every vault,
it is delimited by marker comments, it carries only lines that are
independent of the machine and the run, and a CI step regenerates it and
fails on any difference. Without all four, DEC-MTH-027 continues to
apply.

**What is stored is chosen so that it can be compared at all.** The
provenance head of `traceability_index.md` - the absolute vault path, the
input-file count, the digest and the generation time - stays out of the
block. Those lines differ between two machines by design and would make
the comparison a false alarm on every runner. What remains is the two
count lines of the exporter's own stdout and the tail of the index from
`## Objects` onward, whose paths are vault-relative and whose orderings
are `sorted()` on ASCII keys.

**The block therefore moves when the graph moves, not when any file
moves.** An edit to one of the vault's other input files leaves it alone;
an object, a requirement, an allocation status, a typed relation or a
finding moves it. That is a narrower trigger than DEC-MTH-027's third
count assumed, and it is not zero: the red pipeline for a file the author
did not write remains possible, and it is the accepted price. What the
decision does buy is that the pipeline names the repair rather than the
defect - the failing step prints the command that regenerates the block.

**DEC-MTH-027 stands unamended.** `traceability_index.md` is still not
committed, still not inside a vault, and `CLAUDE.md` still names the
command rather than a path. This record does not widen that decision; it
decides a case it did not rule on, and states the boundary in the four
conditions above.

## Justification

- The claim the README makes about itself becomes checkable. `3 proven`
  stops being a sentence somebody wrote and becomes a count a machine
  recomputes from the vault on every push.
- The alternative that stores nothing (A) is the defect; the alternatives
  that store something uncheckable (B, C) buy the payoff by giving up the
  property the payoff is about.
- The exception is narrow enough to state in one sentence and to check:
  three of the four conditions are structural and visible in a diff, the
  fourth is a CI step.

## Consequences

- `README.md` carries the first stored generated content of this
  repository, in one movable H2 block delimited by
  `traceability-excerpt` marker comments.
- `.github/workflows/validate-vault.yml` gains a step that regenerates
  the export and diffs the block; `STRUCTURE.md` names it in the
  enumeration of what the workflow runs, and the matching exact-string
  anchor in `tools/new_project.py` is updated with it, so a derived
  project's `STRUCTURE.md` keeps describing the two steps it actually
  has.
- A contributor who changes the worked example changes the README in the
  same pull request. The failing step says so and names the command.
