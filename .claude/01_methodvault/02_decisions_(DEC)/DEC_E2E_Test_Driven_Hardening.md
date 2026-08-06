---
domain: DEC
id: DEC-MTH-002
created: 2026-07-27
last-verified: 2026-08-05
---
Date: 2026-07-27
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-07-27 — E2E-test-driven hardening (Accepted)". The source record carries no headings; its paragraphs are placed under the template's sections unchanged and unsplit.
Corrected by: [[DEC_The_Stop_Report_Goes_Where_It_Is_Read]]

## Context

A trapped end-to-end harness run (11 seeded traps, answer key written
before the run) passed 11/11 via skill prose alone, but exposed three
enforcement gaps. All three fixes accepted and shipped:

## Options

_The source record carries no section under this title; where it weighs a
rejected variant it does so inside the numbered fixes below._

## Decision

1. **Body-wide dead-path scan.** `check_paths` scanned only H2
   References/Sources sections; dead paths elsewhere (observed in the
   E2E run under an H3 `### Firmware source`) were invisible.
   References/Sources keep the strict contract (every token, ERROR, no
   suppression, fenced content included). The rest of the body WARNs on
   project-artifact-shaped tokens only (`NN_` first/second segment —
   an FP survey killed the naive variant: `3.3V/1.8V`, `10k/4.7k`,
   bare domains all match the raw path regex), with inline code and
   fences skipped and pending/planned/TBD markers (line or governing
   heading) suppressing. Markers never silence the ERROR zone —
   silent-bypass prevention, same principle as `status: draft`.
2. **Aggregated link feedback.** The E2E run produced 22 PostToolUse
   events whose findings were exclusively link-unresolved WARNs (56
   lines) — pure forward-reference noise under the phased creation
   order, i.e. the documented false-positive-fatigue failure mode.
   `hook_post` now emits one deduplicated summary line, with explicit
   net-new-vs-HEAD semantics (pre-existing unresolved links never
   block; the ratchet counts per code against the HEAD baseline).
3. **Vault-wide advisory at the stop gate.** `req-uncovered`, `orphan`
   etc. ran only in the manual full audit (process step 7) — skipping
   the step silently skipped the checks. `hook_stop` now appends them
   to the non-blocking session report (capped at 15 lines, original
   order). They never enter `new_errors` (no per-file baseline → the
   ratchet stays strictly per-file), never appear in a block reason
   (an adversarial review showed vault-wide ERROR lines inside a block
   reason burn the 2 block attempts on legacy work), and the
   computation is try/except-shielded so an advisory bug can never
   crash-release the gate.

## Justification

Verified hook-API facts (code.claude.com/docs/en/hooks): PostToolUse
`additionalContext` reaches the model (10k char cap); Stop-hook plain
stdout is user-facing only — the right channel for advisory legacy
drift; Stop `hookSpecificOutput.additionalContext` would continue the
conversation and is therefore unsuitable for routine advisories.

## Consequences

Open question (follow-up): the docs suggest a Stop block `reason` may
be user-only too. If confirmed by a live probe, the gate's fix
instructions should additionally be emitted as `additionalContext`
alongside `decision: block` so the model reliably sees them.

New accepted residual: the body path scan only catches `NN_`-prefixed
project paths (precision over recall, consistent with the leak
detector). Realization: `validate_vault.py` (`check_paths`,
`hook_post`, `hook_stop`); `tests/run.sh` now 47 assertions;
SKILL.md cross-linking rule 4 and enforcement section updated.
