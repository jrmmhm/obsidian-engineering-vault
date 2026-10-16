---
domain: DEC
id: DEC-MTH-052
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Accepted

## Context

The method's founding record, [[DEC_Enforcement_Layer_For_The_Vault_Conventions]]
(DEC-MTH-001), argues for the validator and its hooks from published
research: five arXiv papers on instruction adherence, context compaction,
self-correction and LLM auditing of documentation, and a sixth on outdated
references in repository documentation behind its first follow-up. An audit
of the skill's research citations on 2026-10-15 read the five abstracts and
found that the record states several of them more strongly than the papers
do, and misquotes one outright. Nothing else in the repository repeats
those five identifiers, so the defect sits in one file.

A decision record that overstates its evidence fails the method's own rule:
a statement is taken from a source or marked unverified. And this record is
the one every later validator change refines, so it is where a reader
checks why the method exists at all.

## Options

- **A — leave the record as migrated, the defect documented elsewhere.**
  Keeps the migrated text intact, but every reader who follows a citation
  finds a different claim than the one quoted, with no sign at the site
  that the author knew.
- **B — correct each wrong site in place, declared above Context, with a
  `Corrected by:` line pointing here (chosen).** The precedent of
  [[DEC_A_Phantom_Citation_Is_Retargeted]]: history is corrected forward,
  and the corrected file says so.
- **C — supersede the record with a rewritten one.** Superseding says the
  decision changed. It did not: option B of DEC-MTH-001 stands on the
  corrected evidence (below), so a new decision would misstate history in
  the other direction.

## Decision

B. Every citation was checked on 2026-10-16 against the paper's abstract
page, `https://arxiv.org/abs/<id>`. For arXiv 2212.01479 the cited claim
lies outside the abstract, so its full text was read as well. A statement
the source does not carry was rewritten to what the source reports, and a
statement it does carry was left alone. Status of DEC-MTH-001 stays
Accepted; its Migrated line declares the correction and its `Corrected by:`
line points here. The corrected wording lives in that file only and is not
restated here.

## Justification

What each source reports, quoted, against what the record said:

- **arXiv 2605.10039.** The record said "~5.6% lower compliance odds per
  generated unit", "NULL effects for rule-file size/position/structure" and
  "rewriting prose does not help"; option A added "decay is the mechanism,
  and prose cannot stop it". The abstract: each additional function "is
  associated with approximately 5.6% lower odds of compliance per step (OR
  = 0.944) … though the relationship is non-monotonic rather than a
  constant per-step effect", and "it was identified during analysis rather
  than pre-specified". On structure: "Size and conflict nulls are supported
  by affirmative-null Bayes factors …; position and architecture nulls are
  failures to reject without Bayes-factor support." The figure held. The
  caveats, two of the four variables and the claims about prose went
  further than the study, which tested file structure and not wording.
- **arXiv 2509.21051.** The record said "collapse under rule count". The
  abstract: "performance consistently degrades as the number of
  instructions increases", with up to ten instructions for text and six for
  code. Steady degradation, not collapse.
- **arXiv 2606.22528.** The record said "0% → 30–59% … restored to 0% only
  by mechanical pinning". The abstract: "violation rises from 0% with the
  policy in full context to 30% after compaction, reaching 59% for some
  models", and Constraint Pinning "restores violation to 0% in our
  benchmark". The paper does not claim that pinning is the only remedy, and
  30 is the overall figure, not a floor across models.
- **arXiv 2310.01798.** The record said "external feedback works where
  self-correction does not". The abstract: "In the context of reasoning,
  … LLMs struggle to self-correct their responses without external
  feedback, and at times, their performance even degrades after
  self-correction." The abstract shows that self-correction without feedback
  fails on reasoning tasks. It does not show that feedback works, and the
  record now claims only what it shows.
- **arXiv 2511.00215 (DocPrism).** The record said "98% flag rate at 14%
  accuracy vs 94% with local scoped categorization". The abstract: "LCEF
  reduces DocPrism's inconsistency flag rate from 98% to 14%, and increases
  F1 score from 0.22 to 0.77, compared to standard prompting techniques."
  Both percentages are flag rates, and no 94 appears. This one was
  misquoted.
- **arXiv 2212.01479.** Follow-up 1 called the pre-commit/CI hook "the
  outdated-reference GitHub-Action pattern". The paper's implementation is
  run by hand on each commit. A GitHub Action is its future work:
  "Using a tool such as GitHub Action to automate the workflow simplifies
  the process considerably". The follow-up now says so.
- **The decision stands.** Restructuring the rule file showed no detectable
  effect, while compliance still declined within a session, degraded with
  instruction count and vanished with compaction, and models need external
  feedback to correct themselves. Every reason option B gives survives the
  correction. What changed is how far each source carries it.
- **Checked against the page, not against a summary of it.** The audit that
  found the defects was a lead. Every quote above was taken from the source
  opened in this pass. Where it disagreed with the audit, the source won.

## Consequences

- `DEC_Enforcement_Layer_For_The_Vault_Conventions` — six citation sites
  rewritten (Context, options A and B, the leak-detection design point,
  follow-up 1), the Migrated line declaring the correction, a `Corrected
  by:` line, `last-verified` 2026-10-16. Its decision, design points and
  residuals are unchanged.
- `system_overview.md` gains one row; `CHANGELOG.md` records corrected
  documentation, MINOR.
- Residual, stated rather than closed: the record's non-arXiv sources were
  not checked in this pass. Those are the 500-line skill ceiling attributed
  to Anthropic, the Chroma context-rot report and the Wikipedia Manual of
  Style link norms behind the length and link-budget thresholds. Each
  should be checked the same way when those thresholds are next revisited.
- No other file repeats the five corrected identifiers. Two other method
  records and `SKILL.md` cite arXiv 2212.01479 for its outdated-reference
  rates. Those rates appear in the paper's full text, so the citations
  hold, and none of them is changed here.
