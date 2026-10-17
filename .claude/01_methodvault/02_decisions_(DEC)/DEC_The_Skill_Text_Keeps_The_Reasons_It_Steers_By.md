---
domain: DEC
id: DEC-MTH-063
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Accepted

## Context

`SKILL.md` of the mechatronics-docs skill is the prompt every session reads
in full when it invokes the skill, and it had grown to 514 lines. About a
fifth of them were reference for the tools around the vault — the
traceability exporter, `--check-install`, the pre-commit and CI tiers — and
explanations of findings whose validator message already carries the
remedy, under the file's own sentence "None of that is needed to write
vault notes". Other passages restated what the conventions file of a vault
owns, and the copies had drifted from their owner: the four questions the
skill asked before creating a file were not the conventions file's four. Claude Code's skill guidance asks for a
`SKILL.md` under 500 lines with detailed reference in separate files one
level deep, which a session reads only when it needs them
(code.claude.com/docs/en/skills; platform.claude.com, Agent Skills best
practices; both read 2026-10-16).

[[DEC_Tool_Internals_Are_Documented_Beside_The_Tool]] (DEC-MTH-038)
already keeps the maintainer's map, `ARCHITECTURE.md`, out of `SKILL.md`.
What no record says is where the rest goes, and what must stay.

A first slim version, pull request #126, answered that by moving the
rationale and measurements of every rule out of the skill text. It was not
merged: an A/B comparison over six pairs of documentation sessions against
the full-length text (AB-S1, 2026-10-16) found the slim arm worse on the
rubric letter "a volatile fact written in more than one new or edited note"
in four of six pairs, with 33 semantic defects against 30 in total, and 9
against 4 of the duplicates that told the arms apart. The comparison report
names a likely cause and calls it unproven: the slim "Detail Ownership"
kept the rules of [[DEC_A_Volatile_Fact_Has_One_Owning_File]] (DEC-MTH-048)
but dropped the paragraph explaining why, and the measured example of one
path written into many files that DEC-MTH-048 records.

## Options

- **A — Trim `SKILL.md` in place, no new file.** Rejected: the tool
  reference is needed on demand by the same agent, and deleting it loses it.
- **B — Split by reader, and move rationale out with the reference.** The
  rule of pull request #126. Rejected: it is the variant the A/B comparison
  measured worse on exactly the defect the moved rationale argues against.
- **C — Split by reader, and keep beside each rule the reasoning that makes
  an agent apply it (chosen).**

## Decision

Option C, as the rule for every edit of the skill text:

- Text that steers how an agent writes notes stays in `SKILL.md` —
  including the reasoning and the measured example behind a rule, not only
  the rule.
- Tool reference read on demand moves one level deep to `REFERENCE.md`
  beside `SKILL.md`; `SKILL.md` names it and says when to open it.
- Maintainer text stays in `ARCHITECTURE.md`, as DEC-MTH-038 decided.
- A rule a vault file owns — the conventions file, a domain README — is
  named, not restated. Where a copy is unavoidable, as with the role table,
  it is quoted, its source named, and the test suite compares it.
- A phrase the test suite pins against what a hook or the validator prints
  stays in `SKILL.md`, because the agent must recognise it when it arrives.

## Justification

- The one measurement there is says the reasoning is the part that cannot
  go: the defect rose where the reasoning was cut and the rules were kept.
- Reference an agent needs once a session costs every session if it sits
  in the prompt; one level deep it costs only the session that opens it.
- A restated rule is a second owner of the fact, the defect DEC-MTH-048
  describes, and the drifted copy showed it happening in the skill itself.

## Consequences

- `SKILL.md` went from 514 to 320 lines and from 29,570 to 18,721 bytes,
  not to half: the parts kept word for word — frontmatter, activation
  guard, role and boundary tables, Detail Ownership, coverage, checklist,
  file placement — are about a third of the old size on their own. `REFERENCE.md` holds the
  export, which copy enforces, and the tiers outside a session.
- Pending: the rule rests on one comparison and a stated hypothesis. The
  A/B comparison of this change against the full-length text decides
  whether it holds; if the slim text with its rationale still duplicates
  more, this record is superseded rather than amended.
- The suite's derivation checks read `REFERENCE.md` as well as `SKILL.md`,
  and a derived project must keep it.
- Residual: `--check-install` reads `SKILL.md` and no sibling file, so a
  copy missing `REFERENCE.md` goes unnoticed outside the suite.
