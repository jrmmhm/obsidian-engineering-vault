---
domain: DEC
id: DEC-MTH-065
created: 2026-10-17
last-verified: 2026-10-17
---
Date: 2026-10-17
Status: Accepted

## Context

**This note decides when the two size measures of
[[DEC_A_Tracker_Row_Holds_Current_State_Only]] (DEC-MTH-058) reach the
agent writing a vault note** — the word count of `length` and
`adm-cell-long`, both advisory WARNs of the mechatronics-docs validator.
Until now every new WARN of a written file reached the agent through the
post-write hook, right after the write, as
[[DEC_A_Known_Finding_Is_Counted_Not_Repeated]] (DEC-MTH-054) shaped it.

An A/B replay of a kernel send event (docs-2, AB-T1 round 2, three pairs)
rejected DEC-MTH-058 and DEC-MTH-059 on cost alone: tokens +28.9 % against
a limit of +15 %, with contradictions, kept next-step facts and ERRORs
equal. The shipped skill text was only 647 characters longer; the extra
tokens came from work in the session. A read of the three treatment
streams found:

- In every arm the agent's own edit pushed a note over a limit it had
  nearly reached at HEAD: the hunt plan from 2,413 words, one tracker cell
  from 595 characters. No arm paid for a WARN the file carried at HEAD.
- Each WARN was cleared by one edit in one extra late turn, each turn
  re-reading 100-150k tokens of context: 328.8k tokens in t4 (12.4 % of the
  arm), about 360k in t5 (10.6 %), 282.5k in t6 (11.4 %). Repeated reports
  of the same file did not drive the cost; the first report did.
- The repair was a cut, not a move. All three arms deleted a dated
  patchwork status that stood in the open row at HEAD — the repair
  DEC-MTH-058 calls wrong — though the message named moving as the repair.
- The stop report did not carry the WARNs either: its advisory section
  holds 15 lines, ERRORs first, and the kernel vault's legacy unresolved
  links filled it (17 ERROR lines, no WARN line, in each arm).

## Options

- **A — The post hook leaves the two size measures out; the full audit,
  `--file`, CI and the stop report keep them (chosen).**
- **B — Report a size WARN only the first time a file crosses the limit
  in a session.** Rejected: every trim followed the first report, so it
  saves the text of the repeats and none of the turns.
- **C — A WARN text that names one concrete repair.** Rejected: the cell
  WARN already named one, and every arm cleared it by cutting instead.
- **D — Report only files the session pushed over the limit.** Rejected as
  already in force: the post hook compares against git HEAD, and every
  trigger was crossed in the session.
- **E — Raise the limits.** Rejected: the evidence shows the WARN arriving
  at the wrong moment, not a wrong number.

## Decision

Option A. After a write the post hook takes neither the word count of
`length` nor `adm-cell-long`, at HEAD or in the live file, so its
comparison stays like with like. The line measure of `length` stays in
the post hook, unchanged. Everywhere else both measures run as before:
the full audit, `--file`, the CI workflow, and the stop report's advisory
findings.

What the agent does when its own full audit shows them (workflow step 6 of
the skill, project `CLAUDE.md` rule 10): in a task pass it names each one
in its report as open; it moves a row's history to the note that owns it
when that move is part of the task; it never shortens text to clear one.

## Justification

- The repair the measures ask for, moving history to its owner, is work of
  its own. Prompted mid-task, agents made the cheaper wrong repair; at the
  audit, naming the WARN as open costs one line, and the move stays a
  deliberate pass.
- The line measure stays because it is the behaviour every earlier session
  had, and because keeping it lets the next A/B attribute what changed to
  the two measures alone.
- Advisory stays advisory: both remain WARNs with their limits in the
  schema; only the moment they reach the agent changes.

## Consequences

- `SKILL.md` says in its enforcement section that the two measures wait
  for the full audit and what the agent does with them there;
  `ARCHITECTURE.md` maps the hook's parameter. DEC-MTH-058 gains a
  Consequences line naming this note.
- Residual: in-session enforcement of the ADM size limits is gone. A
  tracker cell can grow past the limit in a session and is caught by the
  full audit and CI only.
- Residual: the stop report reaches the user, not the agent, and its line
  cap can drop both WARNs behind legacy ERRORs, as it did in the kernel
  vault.
- Pending: whether agents still trim when the full audit shows the WARNs
  is measured by the next A/B of this change (trimming calls after a size
  WARN); if they do, this record is revisited.
- No `schema_version` change of its own and no new code: the change ships
  with the two measures it delivers, in the same release.
