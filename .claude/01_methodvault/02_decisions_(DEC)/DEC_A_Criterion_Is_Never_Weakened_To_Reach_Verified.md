---
domain: DEC
id: DEC-MTH-064
created: 2026-10-17
last-verified: 2026-10-17
---
Date: 2026-10-17
Status: Accepted

## Context

An allocation row of an ARC note carries a status, and `Verified` is the one
the exporter counts as proof. The rule for reaching it is stated in the
template's `CLAUDE.md` (rule 7) and in the Column 4 rule of the ARC README:
a TAE link exists and its evidence is written down. Neither says what the
evidence has to cover. The acceptance criterion it is measured against sits
in column 4 of the requirement's own row, and in a documentation pass the
same agent often writes that row, the evidence note and the status.

The A/B comparison AB-S2 (2026-10-17) shows where that leaves the gap. Its
task gave twelve documentation sessions the facts of a finished software
change - six unit tests green in one hosted run, a sync path checked by code
reading only, the owner's check on the real device still pending - and asked
each to write a new requirement row, REQ-SQN-007, with its TAE and its
allocation row. The task carried no requirement text and no criterion; every
session wrote both itself. The report records:

- 7 of 12 sessions set the row `Verified` (6 of 12 in the reading that
  replaces one session, t6, by its rerun t6b) - 5 of 6 in the treatment
  arm (4 of 6 with t6b), 2 of 6 in control. Every one of them wrote a criterion made of the
  unit tests alone.
- Every session that wrote the device check into the criterion (c1, c3, c4,
  t6b) left the row `Approved`.
- Every TAE, in both groups, marked the start-up duration as not measured
  and the sync path as code reading only.

Session t1 is the pattern in one diff. Its requirement content says the
items of user playlists "shall stay unchanged"; its criterion names only the
`testQueueCleanup_*` tests; its own ARC status bullet says the row is
`Verified` although "its user-playlist sync clause rests on code reading,
and the owner's device check and the SwiftFormat lint re-run are open".
Session c1 wrote "on the owner's device the first start ... shows no
perceptible delay, graded by the owner" into the criterion and kept the row
`Approved`, because "the first start on the owner's existing store is a
device clause".

What the comparison does not show: this was not a rubric letter, the judge
preferred the tests-only `Verified` arm in two of six pairs (one of six with
t6b), and n = 6 per arm cannot separate the arm difference from noise; AB-S1
saw 4 of 6 `Verified` in each arm. The arm-independent count is what this
record rests on: half or more of all sessions wrote the criterion to the
evidence they held and then reported it met.

## Options

- **A - A validator check.** Rejected: a weakened criterion and a
  deliberately narrow one are the same text to a tool. The criterion of a
  new row has no earlier version to compare with, and the clause that is
  missing is by definition not in the file.
- **B - Leave it to the existing wording.** Rejected: "its evidence is
  written down" is met by evidence for whatever criterion was written, which
  is exactly what the sessions that set `Verified` did.
- **C - One sentence wherever the `Verified` rule is stated (chosen)**,
  aimed at the moment the criterion is written, not only at the moment the
  status is set.

## Decision

Option C. An acceptance criterion is written from what its requirement
demands, not from the evidence at hand. While the evidence covers only part
of the criterion of an allocated requirement, the row stays `Draft` or
`Approved`. A clause is changed or split off only as a change of the REQ
file with its reason in column 5 (Source / Justification), never dropped or
softened so the row can be set to `Verified`.

The sentence stands in `CLAUDE.md` rule 7, in its copy in `CONTRIBUTING.md`,
in the Column 4 rule of the template vault's ARC README
(`00_documentation/01_projectvault/03_architecture_(ARC)/00_ARC_README.md`),
which owns the status rule, and
at the end of the REQ-TAE coverage section of `SKILL.md`, which names that
README as the owner.

`Blocked` is not named in the sentence, and a row with part of its evidence
in hand does not move to it. The ARC README keeps `Blocked` for an
allocation that is "not verifiable/implementable (dependency missing)" -
one whose verification cannot start at all for now, such as a device that
does not exist yet. It is also a deferral status: a requirement whose every
row carries it leaves the printed `req-uncovered` findings for the audit's
accepted line ([[DEC_A_Known_Finding_Is_Counted_Not_Repeated]]), so using it
for a row whose evidence is merely incomplete would hide the open clause.
Evidence that waits for somebody to run a check - the owner's device check
above - keeps the row `Approved`.

## Justification

- The defect sits in the writing of the criterion, so a rule that only
  speaks about the status would have passed every session that set `Verified`: each had
  evidence for every clause it wrote.
- A changed criterion is a changed requirement. The REQ file has a column
  for the reason, and a verification pass is not one; recording the change
  there keeps it visible to whoever reads the requirement, not only to
  whoever reads the TAE.
- Column 3 of the ARC README already asks for evidence that demonstrates
  "fulfillment of the assigned requirements". Evidence for part of a
  requirement never met that, so the sentence makes the existing rule
  explicit; it does not move it.
- The agent writes notes with `SKILL.md` in its context, and a derived
  project's own `CLAUDE.md` is a copy this template cannot update; the
  sentence in `SKILL.md` reaches a session as soon as the project takes the
  skill.

## Consequences

- No validator, schema or exporter change; no finding moves. Corrected
  documentation, MINOR by the versioning table in `CONTRIBUTING.md`.
- Residual: nothing checks the rule. A criterion written to the evidence
  passes every tool, as it did before.
- Derived projects carry their own `CLAUDE.md` and ARC README; they gain the
  sentence only when they copy it in, which the changelog entry says.
- Whether the sentence changes the rate measured above is unmeasured; a
  later A/B of the status choice would answer it.
