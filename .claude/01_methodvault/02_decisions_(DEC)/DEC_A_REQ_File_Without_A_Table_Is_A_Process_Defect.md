---
domain: DEC
id: DEC-MTH-031
created: 2026-08-05
last-verified: 2026-08-05
---
Date: 2026-08-05
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-05i — A REQ file with no table is a process defect, not a validator finding (Accepted)".

## Context

`check_req_table_silence` reports two things it can prove: a table whose
rows the requirement index reads while no row check reads them, and a REQ
file carrying a table wide enough to be a requirement table and not one
readable table. A REQ file carrying no table at all falls through both
predicates and produces nothing — `unread` stays empty, so the check
returns before it can say anything. Nothing downstream notices either: a
file without rows defines no requirement, so `req-uncovered` has nothing to
be uncovered about. The absence is silent in every direction.

Issue #51 asks whether that silence is a gap or a decision. It was neither
so far — it was undocumented, which is the one state a rule may not be in.

## Options

- **A — Report a REQ file without a readable requirement table (WARN).**
  Rejected. The check cannot tell a REQ note that is deliberately prose — a
  scoping narrative, a constraints text, the domain README's neighbour —
  from one whose table was lost. That is exactly the case in which this
  project takes precision over recall, and `check_req_table_silence` already
  argues it in its own docstring for the neighbouring case.
- **B — Report it as an ERROR.** Rejected harder: an ERROR reaches the stop
  gate, so the tool would block a session on a file that may be correct.
- **C — Leave the tool silent and state the rule where the rule lives
  (chosen).**

## Decision

The requirement table is obligatory by process and not enforced by the
tool. The validator stays silent on a REQ file without a table, and the
conventions file says so in the same breath as the codes that do fire, so
no reader concludes from a clean run that the file is complete. The
enforced neighbour keeps its scope: a table that looks like a requirement
table and cannot be read as one is `req-table-unrecognized` (WARN).

This is a statement about the rule set, not a change to it. No vault that
was clean becomes unclean and no finding code starts or stops firing, so
the tier under amendment 2026-08-05h is **MINOR** — "new or corrected
documentation", the line that amendment's own table gives this case. What
that amendment excludes from the classification is the reverse question:
whether a rule happened to be documented never decides the tier of a change
to the rules themselves.

## Justification

_The source record carries no section under this title; it states its
grounds inside the two rejected options above and in the second paragraph
of its decision._

## Consequences

### Realization

`00_documentation_file_creation_and_conventions.md` gains a
`### Validator-enforced rules (quick reference)` subsection under section 3:
the seven codes issue #51 found undocumented (`stub`, `structure`,
`duplicate-basename`, `link-repeat`, `encoding-not-utf8`,
`id-scope-mismatch`, `orphan`) with severity, scope and threshold, the DEC
half of `impl-leak`, and the sentence above. The section states that it is
not the tool's whole code list, so it is not read as an inventory.

The contribution this grew from (PR #56) is preserved as its own commit and
corrected on top. Three of its claims were wrong against the code and are
recorded here because the same mistakes are easy to repeat: `link-repeat`
fires above three repeats rather than at three; `duplicate-basename` indexes
`doc_root`, the documentation folder, not the vault, so `02_documents`
collides with it; and a path-qualified wikilink does not disambiguate a
collision here, because `check_links` resolves by basename and reports that
form as `link-unresolved`. `SKILL.md` stops saying that ARC is the only
domain the leak check reads, and `00_DEC_README.md` no longer sends a value
flagged in DEC Context to ARC, where the same check reports it as an ERROR.
No code changes.
