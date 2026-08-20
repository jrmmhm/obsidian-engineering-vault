---
domain: DEC
id: DEC-MTH-046
created: 2026-08-20
last-verified: 2026-08-20
---
Date: 2026-08-20
Status: Accepted

## Context

The method has always said where a statement belongs. The timeline column
of the role map is the misplacement detector, the content-boundary table
names the common misplacements, and the validator enforces two of them:
unit-bearing numbers and pin tokens are an ERROR in ARC and an `impl-leak`
WARN in a DEC context section.

What none of that says is what happens to the *other* files. A path may
sit in an IMP note where it belongs and simultaneously in four other notes
that merely mention it, and every one of those five is, individually,
within the rules as written.

Measured in a vault built with this method (homelab, 2026-08-20, 195 notes):

| Observation | Count |
| --- | --- |
| Files naming one database path (`navidrome.db`) | 23, across 5 domains |
| Files naming one notification script path | 9, including the ARC map |
| Distinct filesystem paths in the decisions domain | 138 |
| Distinct filesystem paths in the components domain | 66 |
| Size of the largest ARC note, whose context section is capped at 5-7 sentences | 31 KB |

The requirements domain and the architecture map are in that list. ARC is
defined as an orchestrator that stores no data.

Documentation of this kind fails silently: no build breaks and no test
fails when a path moves. The rate is measured — 28.9% of the most popular
GitHub projects currently carry at least one outdated reference to a code
element, and 82.3% carried one at some point (arXiv 2212.01479) — and the
content that goes stale first is exactly the volatile kind: identifiers,
locations, values. A fact in one file ages in one place and is repaired in
one place. The same fact in five ages in five and is repaired in one; the
vault then holds four confident, wrong answers, indistinguishable from the
right one.

The failure is also the one an LLM author produces by default. The single
measurement that exists for generated architecture records puts zero-context
output at 1123 tokens against 527 for human-authored ones, normalising to
710 when grounded in prior human examples (arXiv 2604.03826). Nothing in
the skill told the author what to leave out.

## Options

- **A — Extend the validator to flag paths and identifiers outside
  IMP/CMP/IFC/TAE.** Rejected for now, on blast radius rather than on
  principle: it would raise roughly 200 findings against the measured
  vault in one step, and a ratchet that large is adopted wholesale or
  ignored wholesale. It stays a follow-up, to be armed after the rule has
  been applied by hand once.
- **B — Length budgets per domain.** Rejected. A budget nobody measures is
  advice, and the two budgets the method already states — the 5-7 sentence
  ARC context and the 1-2 page IMP note — are the ones the measured vault
  overruns by an order of magnitude. Adding a third of the same kind
  changes nothing.
- **C — An ownership rule with an explicit exclusion list (chosen).** One
  owning file per volatile fact; every other note names and links it. The
  rule is stated in the skill, is checkable by a reader and by a
  fresh-context reviewer, and turns a judgement ("is this too detailed?")
  into a question with one answer ("how many files become wrong if this
  changes?").
- **D — Do nothing in the skill and catch it in review.** Rejected as the
  sole measure: a reviewer needs a written standard to review against, or
  the finding is one opinion against another. C is what makes review of
  this class possible at all.

## Decision

Option C. `SKILL.md` gains a *Detail Ownership* section: a volatile fact —
path, version, flag, value with a unit, unit or service name, function or
file name, port, hostname — is written once, in its owning file, and named
with a link everywhere else. The closing checklist asks for it by name.

The rule quotes its sources rather than asserting: arc42's "Hide the inner
workings of blackboxes!" and "prefer relevance over completeness" for the
abstraction levels, Nygard's "The whole document should be one or two pages
long" for decision records, and Google's "Do not write your own guide to a
common Google technology or process. Link to it instead." for the general
form. The test a reader applies is one question: if this value changes next
month, how many files become wrong?

## Justification

- The defect is measured in a real vault of this method, not inferred, and
  it sits in the two domains the method declares data-free.
- Staleness of this content class is measured in the field, and it is the
  silent kind — nothing fails when it happens.
- A rule stating what to leave out is the lever the generation side lacks:
  the one measurement for generated decision records shows the over-length
  is a default that grounding corrects, not an accident.
- The rule is reviewable without a tool, which the validator extension is
  not yet. That order is deliberate: the rule first, the ratchet after the
  first pass has been made by hand.

## Consequences

- Existing notes are not retro-fixed by this decision. They are corrected
  when they are next touched, under the invalidation sweep the process
  already prescribes.
- The validator extension of option A stays open, and its cost is now
  known rather than guessed: roughly 200 findings in the measured vault.
  Whoever arms it measures the finding-set difference at that time — the
  numbers above are from 2026-08-20 and are not a forecast.
- `/implement` Phase 6 reviews documentation against this rule
  (`DEC-AIW-001` in the AI method vault). Without a written standard that
  criterion would have been one opinion against another.
