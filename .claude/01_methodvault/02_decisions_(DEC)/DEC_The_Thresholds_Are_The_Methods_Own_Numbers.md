---
domain: DEC
id: DEC-MTH-062
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Accepted

## Context

The method's founding record, [[DEC_Enforcement_Layer_For_The_Vault_Conventions]]
(DEC-MTH-001), sets the validator's file-length and link-budget thresholds
in one design point and gives three reasons for them from outside arXiv: a
skill-length figure attributed to Anthropic, Chroma's context-rot report
and the Wikipedia Manual of Style on linking.
[[DEC_A_Citation_States_What_Its_Source_Reports]] (DEC-MTH-052) corrected
the record's arXiv citations and left these three open as a stated
residual, to be checked the same way when the thresholds were next
revisited.

The thresholds are the rules a writer meets most often - every long note
and every link-heavy note is measured against them - so the reason given
for them is the one most often looked up. A reason that says more than its
source fails the method's own rule: a statement is taken from a source or
marked unverified.

## Options

- **A - correct the design point in place, declared above Context, with a
  `Corrected by:` line pointing here (chosen).** The pattern DEC-MTH-052
  set for the arXiv citations: history is corrected forward, and the
  corrected file says so.
- **B - change the thresholds to fit what the sources say.** Not this
  record's question. None of the three sources gives a number for a vault
  note, so none of them can supply a better one, and a changed threshold
  moves a rule that needs its own measurement and its own decision.
- **C - leave the residual open.** Every reader who follows one of the
  three citations finds a different claim than the one quoted, with no
  sign at the site that the record knew.

## Decision

A. Each source was opened at its primary location on 2026-10-16 and the
cited passage read in the page text. A statement the source does not carry
was rewritten to what the source reports, and a statement it does carry was
left alone. The thresholds and their severities do not change. Status of
DEC-MTH-001 stays Accepted; its Migrated line declares the correction and
its `Corrected by:` line points here. The corrected wording lives in that
file only and is not restated here.

## Justification

What each source reports, quoted, against what the record said:

- **Anthropic, skill length.** The record said "Anthropic's 500-line skill
  ceiling is the only published hard number". The Agent Skills
  best-practices page
  (`https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices`):
  "Keep SKILL.md body under 500 lines for optimal performance" and "Split
  content into separate files when approaching this limit"; the Claude Code
  skills page (`https://code.claude.com/docs/en/skills`): "Keep `SKILL.md`
  under 500 lines." The number holds, and it is about the SKILL.md body. It
  is guidance given for performance, not an enforced ceiling. Nor is it the
  only number: the same best-practices page asks for a table of contents
  "For reference files longer than 100 lines", and the Claude Code memory
  page (`https://code.claude.com/docs/en/memory`) says "target under 200
  lines per CLAUDE.md file. Longer files consume more context and reduce
  adherence." Whether those two stood on the pages when the record was
  written was not established; the record now says what the pages say.
- **Chroma, context rot.** The record said "retrieval quality degrades well
  below context limits". The report is "Context Rot: How Increasing Input
  Tokens Impacts LLM Performance" (Hong, Troynikov, Huber; Chroma, 14 July
  2025; `https://www.trychroma.com/research/context-rot`, where the older
  `research.trychroma.com` address now redirects). It evaluates 18 models,
  each "across its maximum context window", on needle-in-a-haystack
  variants, LongMemEval conversational question answering and a
  repeated-words replication task: "Across all experiments, model
  performance consistently degrades with increasing input length", and
  "Even on tasks as simple as non-lexical retrieval or text replication, we
  see increasing non-uniformity in performance as input length grows."
  Degradation inside the context window holds. "Retrieval quality" was
  narrower than the report, which measures task performance with retrieval
  as one task among three, and "well below" is not the report's: it does
  not say how far below the limit the decline sets in.
- **Wikipedia, linking.** The record said the link budget came "from
  Wikipedia MOS norms". Wikipedia:Manual of Style/Linking
  (`https://en.wikipedia.org/wiki/Wikipedia:Manual_of_Style/Linking`, read
  in its wikitext): an article "is said to be overlinked if it contains an
  excessive number of links, making it difficult to identify those likely
  to aid a reader's understanding"; "Link a term at most once per major
  section, at first occurrence"; and, as of 2024, "most stub articles
  average two links per sentence, or about 10 to 20 links total. Most
  longer articles average somewhere around one link per 20 words." The
  guideline sets no count. Its figures describe averages, and the only one
  near 20 is the stub total. It supports having a budget, not its size.
- **What none of the three gives.** No source names 150, 400 or 20, and
  none measures notes in a documentation vault. The numbers are the
  method's own, set below the vendor's guidance for instruction files and
  informed by the decline the context-rot report measures. The record now
  says so instead of lending them a source's authority.
- **An absence is not a finding.** "No LLM-specific link study exists" is a
  claim that nothing exists, and this check did not search for one. The
  record now states it as what was known when the budget was set.
- **Checked against the page, not against a summary of it.** Every quote
  above was taken from the page text retrieved in this pass. Where a
  summary of a page disagreed with its text, the text won.

## Consequences

- `DEC_Enforcement_Layer_For_The_Vault_Conventions` - the Thresholds
  design point rewritten, the Migrated line declaring the correction, a
  `Corrected by:` line pointing here, `last-verified` 2026-10-16. Its
  decision, its other design points and its residuals are unchanged. The
  same pass drops the hub link budget the design point still named and adds
  the `Corrected by:` line to
  [[DEC_The_Validator_Reports_What_Can_Be_Acted_On]], the record that
  deleted it; that correction is its own and is not argued here.
- `DEC_A_Citation_States_What_Its_Source_Reports` gains a `Corrected by:`
  line pointing here: the residual it stated is closed. Its Status stays.
- `system_overview.md` gains one row; `CHANGELOG.md` records corrected
  documentation, MINOR. No validator constant, severity or test moves.
- No other file in the repository cites the three sources. The project
  vault's conventions file states the link guideline as a number without a
  source and is not changed.
- Residual, stated rather than closed: the thresholds rest on no
  measurement of this method's own notes. They stay as they are until such
  a measurement gives a reason to move them, and that change would be a
  decision of its own.
