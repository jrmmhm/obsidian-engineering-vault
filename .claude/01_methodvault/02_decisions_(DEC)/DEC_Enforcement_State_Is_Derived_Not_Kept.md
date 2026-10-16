---
domain: DEC
id: DEC-MTH-055
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Accepted

## Context

**Which state the enforcement layer derives instead of keeping by hand.**
Two values were kept, and both had drifted from what they claimed. The stop
gate counted its blocks per session in a state file that was never reset,
so after two blocks it stayed advisory for the rest of a long session -
the cap [[DEC_Enforcement_Layer_For_The_Vault_Conventions]] describes as
"max 2 blocks per session". And `--check-install` printed a revision that
was a hand-bumped constant, introduced by
[[DEC_A_Session_Runs_The_Skill_It_Loaded]] so that "which copy just
enforced this?" has an answer. It was not bumped for four behaviour
changes, so two different validators reported the same revision, and the
one comparison built on that line declared them equal.

## Options

- A: keep both and add the missing maintenance - reset the counter, add the
  bump to the release checklist.
- B: derive both - the block decision from the Stop payload Claude Code
  sends, the revision from the bytes of the files that decide behaviour.

## Decision

Option B.

- **The stop gate blocks once per stop sequence.** Claude Code sets
  `stop_hook_active` in the Stop payload when the turn is already a
  continuation forced by a Stop hook. New ERRORs and no such flag: the
  gate blocks. New ERRORs and the flag a JSON true: the gate releases and
  the user report opens with the unresolved ERRORs. Anything but a JSON
  true counts as absent. No counter file is kept; a later stop sequence of
  the same session blocks again.
- **The revision is derived from content**: a short sha256 prefix over the
  bytes of the validator, the schema and the exporter the validator
  imports. A missing file enters as a fixed marker rather than crashing the
  check meant to diagnose a broken install. The printed line keeps its
  shape, so a line-based comparison between copies still works.

## Justification

- Claude Code's hooks reference states that `stop_hook_active` is true
  "when Claude Code is already continuing as a result of a stop hook", and
  that Claude Code itself ends a turn after eight consecutive Stop-hook
  continuations, a count reset by every tool call. A loop on a defect the
  session cannot fix is bounded twice; a gate that went quiet for the rest
  of a session after its second block is not bounded at all.
- The revision answers its question only if it changes whenever behaviour
  can. Content cannot be forgotten the way a bump can. The whole skill
  directory would be the wrong input: a derived project ships it without
  its tests on purpose.
- Raw bytes, not normalised text: two copies differing in one byte are two
  validators, and saying so is the point.

## Consequences

- Residual, accepted: when another Stop hook continued the turn and the
  ERRORs were introduced only after that, this gate sees the flag and
  releases without having blocked once in that sequence. The ERRORs still
  reach the user in the session report, and the next stop sequence blocks.
- The first sentence of the session report changes - it no longer counts
  attempts - and so do the skill's description of it and the stop hook's
  header comment, both owned outside this change.
- The revision now differs between any two copies whose three files
  differ, including a vendored copy one release behind.
