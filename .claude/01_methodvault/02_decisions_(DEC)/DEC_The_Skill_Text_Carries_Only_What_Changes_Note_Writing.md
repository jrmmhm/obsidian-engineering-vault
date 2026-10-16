---
domain: DEC
id: DEC-MTH-057
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Accepted

## Context

`SKILL.md` of the mechatronics-docs skill is the prompt every session reads
in full when it invokes the skill. It grew from 297 to 514 lines in 24 days,
and a review of it (2026-10-15) measured what the growth was: about a third
was reference for the tools around the vault — the traceability exporter,
`--check-install`, the pre-commit and CI tiers, the schema, duplicate
folders, section near-miss matching — under a sentence that said "None of
that is needed to write vault notes". Other parts restated files the skill
itself calls authoritative, and had drifted from them: the role table gave
CMP the question "What are the building blocks?" where the template
conventions file asks "What do references say about a component?".

The restatement had also produced a contradiction with the tools. The
activation guard demanded at least three folders numbered `01_` to `09_`,
while the validator's own root test, `is_vault_root`, accepts three domain
folders of any number with template files below them, and
[[DEC_A_Project_Starts_With_Three_Domains]] (DEC-MTH-041) counts ADM and INB
toward that floor. The method vault of this repository, holding `02_`,
`09_` and `98_`, was a vault to the validator and the hooks and a STOP to
the prose.

[[DEC_Tool_Internals_Are_Documented_Beside_The_Tool]] (DEC-MTH-038) already
kept the maintainer's map out of `SKILL.md`. What it did not say is where
the rest goes.

## Options

- **A — Trim `SKILL.md` in place, no new file.** Rejected: the exporter and
  install-check text is needed on demand by the same agent, and deleting it
  outright loses it.
- **B — Split by reader and change rate (chosen).** `SKILL.md` carries what
  changes how notes are written; `REFERENCE.md` beside it carries the tools
  an agent reaches for on demand; `ARCHITECTURE.md` stays the maintainer's;
  rules a vault file owns are named, not restated; rationale lives here.
- **C — Several skills, one per concern.** Rejected: more invocation
  surface for the same content, and the semantic rules the validator cannot
  check belong together.

## Decision

Option B, applied as one rule for every future edit of `SKILL.md`:

- A passage stays in `SKILL.md` only if it changes how an agent writes a
  note on an ordinary invocation.
- Tool usage needed on demand moves one level deep to `REFERENCE.md`, which
  `SKILL.md` names in one short section.
- A rule owned by the conventions file or a domain README is named, not
  restated. Where a copy is unavoidable — the role table — it is quoted,
  its source named, and the suite compares it row by row.
- Rationale and measurements live in the method decision that owns them;
  `SKILL.md` keeps at most one line of evidence.
- "Is this a vault?" is answered by the validator, not by prose: the guard
  runs `validate_vault.py` on the candidate and reads only its stderr.

## Justification

- Claude Code's skill guidance asks for a `SKILL.md` under 500 lines with
  detailed reference in separate files; the file stood at 514.
- Every restatement in `SKILL.md` was a second owner of a fact, the defect
  [[DEC_A_Volatile_Fact_Has_One_Owning_File]] (DEC-MTH-048) describes; the
  CMP question showed the second owner drifting.
- A guard that asks the validator cannot disagree with the validator.

## Consequences

- `SKILL.md` went from 514 to 234 lines. Deleted as unsourced: "roughly a
  fifth of plausible-sounding generated statements … are wrong". Deleted as
  unfollowable: the request to say which stopped-firing codes were fixed —
  that list reaches only the user, as DEC-MTH-023 recorded.
- The derivation checks of the suite read `REFERENCE.md` as well as
  `SKILL.md`, and the derived tree must keep it.
- Residual: `--check-install` reads `SKILL.md` and no sibling, so a copy
  missing `REFERENCE.md` goes unnoticed outside the suite.
- Whether the slimmer text changes agent behaviour is measured by an A/B
  run against the previous skill, not assumed.
