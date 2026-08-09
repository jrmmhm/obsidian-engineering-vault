---
domain: DEC
id: DEC-MTH-042
created: 2026-08-09
last-verified: 2026-08-09
---
Date: 2026-08-09
Status: Accepted

## Context

Issue #80. `README.md` argues the method — one place per fact, drift,
retrieval by exact name, the hook channels — over four screens before it
lets anyone in. The entry stands at line 283 and the audience section at
line 530 of 567. The argumentation is good; its position makes it a
doorman, and a reader who wants to know what this is and how to start
scrolls past it to find out.

The question this record answers is not whether to reorder. It is where a
document of this kind belongs at all, because the answer binds every
future document of its kind, and this repository has already answered the
neighbouring case. [[DEC_Tool_Internals_Are_Documented_Beside_The_Tool]]
(DEC-MTH-038) put the validator's map beside the validator rather than in
this vault, on the ground that a map of our own code is neither a
decision nor an external source: placing it here would bend one domain's
question or add a domain to the method vault. Reader-facing argument
fails the same test for the same reason.

Two constraints come from what the repository already built.
[[DEC_Generated_Content_Is_Stored_Only_Where_CI_Proves_It]] (DEC-MTH-037)
calls the stored excerpt "one movable H2 block", and the CI step matches
its markers and fences by content, not position — so the proof may move
as a unit. And `tools/new_project.py` regenerates `README.md` from its
own template, so nothing the README says reaches a derived project.

That last fact carries a defect nobody had reported. `IEC_61508_MAPPING.md`
ships to derived projects and cites `README.md#handing-it-to-someone-else`;
the generated project README has no such section, so that anchor is dead
in every project ever derived from this template. `STRUCTURE.md` carries
the same shape of citation and is repaired by an exact-string replacement
during derivation. The mapping file's is not.

## Options

- **A — Reorder inside `README.md`, essays below a divider.** Rejected,
  and the closest call. Every anchor survives byte-for-byte, no file
  ships or is stripped, and the landing page keeps the mermaid diagram,
  which is its one visual. It leaves the file at 567 lines and the
  argument still in the entry's document — the defect softened, not
  moved.
- **B — The essays into this vault, with a pointer from the README.**
  Rejected on the DEC-MTH-038 ground: they are explanation, not
  decisions, and no domain here answers "how the method works".
  The issue names this option; it does not survive the precedent.
- **C — A `docs/` directory.** Rejected: a directory for one file, and
  `STRUCTURE.md` would have to describe a top-level folder that a
  derived project does not need.
- **D — `METHOD.md` beside the README, split by audience, shipped to
  derived projects (chosen).**

## Decision

Option D. `README.md` answers, in this order, what this is, the proof,
how to start and who it is for; the argument moves to `METHOD.md` at the
repository root, addressed to the reader who is already convinced. Four
properties are part of the decision rather than of the implementation:

1. **Relocation, not rewriting.** Every moved paragraph is verbatim. The
   only edited sentences are the seams a move makes false — three
   directional references between the quick start and the worked
   example, and one self-reference to "this README" inside the moved
   text.
2. **Heading texts are kept.** They are what an anchor is derived from,
   so keeping them makes the repair of an inbound link a one-word change
   of file name rather than a rewrite.
3. **`METHOD.md` ships.** It is not template-repo-only: it describes the
   method a derived project inherits, which is the argument
   `STRUCTURE.md` already makes for `IEC_61508_MAPPING.md`. One
   replacement removes the one template-only sentence it carries, the
   pointer at the skill's own test suite, which the strip list removes.
4. **The derivation names it.** The generated project README lists
   `METHOD.md`, and the `STRUCTURE.md` replacement that previously
   routed around the missing README section now points into `METHOD.md`.
   A shipped file nothing links to is not shipped, it is left behind.

## Justification

- The audience is the only stable split. `README.md` is read once by
  somebody deciding whether to look further; `METHOD.md` is read by
  somebody who already decided. A document serving both serves the
  second, because that is who wrote it.
- Option A keeps every anchor and is the cheaper change, but the issue
  is about what a first-time reader meets first, and a divider two
  screens down does not change that.
- Shipping repairs a dead anchor instead of routing around it. Stripping
  would have left `IEC_61508_MAPPING.md` citing a section no derived
  project has, which is the state of every derived project today.
- The proof stays where it is. Moving the entry up costs nothing that
  the excerpt block was buying, and the block is left untouched at
  position two, its marker pair intact and its CI diff unaffected.

## Consequences

- Two `README.md` anchors are retired: `#the-ai-layer` and
  `#handing-it-to-someone-else` now resolve under `METHOD.md`. The three
  in-repository citations are retargeted in the same change; an external
  bookmark to either breaks silently, which GitHub's own documentation
  names as the cost of moving a heading. This is not mitigated.
- The mermaid diagram leaves the landing page with
  `## How the pieces connect`. GitHub renders mermaid in any Markdown
  file, so the repository's only figure is not lost — it is one click
  further away, and that is the price of D over A.
- `tools/new_project.py` had its exact-string anchors pinned by nothing:
  the warning it raises on a missed anchor is printed and then dropped,
  because the success predicate reads the validator's warning count and
  not its own. The suite gains an assertion that fails on any printed
  warning, pinning every anchor the script carries rather than the one
  this change touches.
- `METHOD.md` states in its own opening that the method has nine domains
  and that `--minimal` starts with three. The alternative was a
  `MINIMAL_REPLACEMENTS` entry rewriting moved text, which property 1
  forbids. `STRUCTURE.md` already carries one uncorrected nine-domain
  sentence into a minimal project, in its `## IEC_61508_MAPPING.md`
  section; this is the same residue and no larger.
- The `Realization` lists of [[DEC_A_Replicated_Link_Is_Valid_Where_Written]]
  and [[DEC_Safety_Standard_Correspondence_Is_Structural]] name README
  sections that are now in `METHOD.md`. They carry no `Corrected by:`
  line: [[system_overview]] scopes that marker to a record whose
  *statement* a later one corrects, and a Realization list is a record of
  what a pull request did, true when written and not a standing claim.
- `STRUCTURE.md` gains no `## METHOD.md` section — it has none for
  `TUTORIAL.md` either, and one placed between `## tools` and
  `## AGENTS.md` would be deleted in every derived project by the `CUTS`
  range spanning exactly those two markers.

### Realization

- `README.md` — 567 lines to 328, ordered proof, quick start, audience,
  then what you get, the worked example, the layout
- `METHOD.md` — the four argument sections verbatim, under an opening
  that names `README.md` alone and sets the nine domains against the
  three-domain `--minimal` start
- `STRUCTURE.md`, `IEC_61508_MAPPING.md` — both anchor citations
  retargeted at `METHOD.md`
- `tools/new_project.py` — the `STRUCTURE.md` skill-pointer replacement
  retires (its target ships now), one replacement drops the test-suite
  pointer from the derived `METHOD.md`, `README_TEMPLATE` names the file
- `tests/run.sh` — no `WARNINGS` in the derivation output, `METHOD.md` in
  the kept list, no stripped-suite reference in it, two files naming it
- `CHANGELOG.md` — `Unreleased`, MINOR, naming the two retired anchors
