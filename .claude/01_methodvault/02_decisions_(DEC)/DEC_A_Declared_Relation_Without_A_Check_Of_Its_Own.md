---
domain: DEC
id: DEC-MTH-049
created: 2026-08-20
last-verified: 2026-08-20
---
Date: 2026-08-20
Status: Accepted

## Context

The decision-log migration introduced a `Corrected by:` pointer for the case
a later decision overturns a *statement* of an earlier one without replacing
the decision itself. Fifteen such lines stand in thirteen files today; the
migration record counted eleven, so the convention has spread twice since it
was invented. It was declared nowhere: not as a typed relation, not in either
DEC template, and no check knew the line existed. Issue #72 asked for one of
two remedies — declare it, or teach the validator to verify it.

Two measurements decided which. First, the issue's own premise is wrong: it
says the validator "does not verify its targets resolve". It does. A
`Corrected by:` line pointing at a file that does not exist was seeded into a
copy of this vault and reported as a blocking `link-unresolved` ERROR, because
the full audit resolves links strictly. What is genuinely unchecked is
narrower than the issue states: a line carrying no link at all, a line placed
below the first heading, and every spelling variant of the label.

Second, the check that would close that remainder was designed, implemented by
an independent reviewer against the real code, and measured. In the style of
the function it would have joined — `check_dec_status`, whose existing
sibling rule matches unanchored and file-wide — it produced eight false ERRORs
in this vault, in a repository whose CI requires it to be ERROR-free. Among
them was the very file that documents the convention, because it quotes the
label in prose, and the table whose column header reads `Corrected by`.

Anchoring the match removes those, but not the trap underneath: the template
placeholder is written `\[\[DEC_...]]`, escaped so the template itself does
not report an unresolved link. That spelling contains no `[[` at all. Every
file freshly copied from the template would therefore carry a line the new
rule rejects, with a cause invisible to its author — a defect the sibling
rule avoids only because it is gated on a status a new file never has.

The remainder that a correct rule would still catch has, measured against
fifteen real lines, zero instances.

## Options

- **A — Declare it, add no check (chosen).** The schema carries the ninth
  relation, both templates carry the line, and the enforcement gap is written
  down in the schema instead of being left to be discovered.
- **B — Declare it and add an anchored link-presence rule.** Rejected: it
  raises a MAJOR-tier blocking rule, drags the finding-code index and its
  test with it, and must first solve the template-placeholder trap — all to
  catch a defect with no observed instances, while the spelling variants that
  are the actual drift risk stay uncatchable either way.
- **C — Reshape the issue and implement nothing.** Rejected: the undeclared
  half is real and cheap to close, and leaving it open keeps the convention
  learnable only by finding an existing instance.

## Decision

Option A, chosen by the operator on 2026-08-20 after the adversarial review
falsified the premise the earlier severity decision had rested on.

## Justification

- A relation that is declared and not enforced is the vault's normal state,
  not an exception: five of the eight relations that preceded it are
  `declared-only`. The new entry is the sixth, and it says so in its own
  `enforced` field.
- The unenforced remainder is named in `enforced_detail` rather than implied.
  A gap a reader can find in the schema is a different object from a gap they
  discover when it bites.
- The label keeps the sibling's shape, including the optional short reason
  after the link. This overturns the migration record's "a pointer, no gloss"
  — one existing line already carries a reason, and forbidding what the
  `Superseded by` line has always allowed would make the pair inconsistent
  for no gain. That record carries a `Corrected by:` pointer to this one,
  which is the mechanism working on its own subject.
- The property that separates the pair is written into the template label
  itself: the corrected record's Status does not change. This is also the
  established ADR convention — an amended record stays accepted and gains a
  pointer, a replaced one is superseded.

## Consequences

- The ninth relation falsified four count statements at once, across the
  schema, two guides and the standards mapping. All four are corrected, and
  the count is now derived from the schema by the suite on every run, in both
  directions and by relation name for the section that claims to list them
  all. The same "eight" inside older decision records is left standing: a
  decision states what was true when it was made.
- Adding a tenth relation now costs one number-word map entry in that check
  and nothing else; forgetting the prose fails loudly instead of silently.
- Residuals, stated rather than closed: a `Corrected by:` line with no link,
  a line below the first heading, and the spellings `Corrected-by:` or
  lowercase are all accepted. A vault that begins to use the convention
  heavily should revisit this with data — the argument above is an argument
  about frequency, and frequency changes.
- A neighbouring defect was found and is not fixed here: `check_dec_status`
  is reached through a literal `DEC` rather than the role map, so its rules
  do not fire in a vault that aliases the domain. That predates this change
  and belongs to its own issue.
