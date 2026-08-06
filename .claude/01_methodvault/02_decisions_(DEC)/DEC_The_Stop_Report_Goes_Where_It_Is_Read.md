---
domain: DEC
id: DEC-MTH-023
created: 2026-08-05
last-verified: 2026-08-05
---
Date: 2026-08-05
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-05b — The stop report goes where someone reads it (Accepted)". Its `Measured on …` section keeps its position directly behind the context, as the last subsection of `## Context`.

## Context

`hook_stop` emitted its whole non-blocking session report with a bare
`print()`, and `stop_gate.sh` passed it through on exit 0. Plain stdout
of a Stop hook goes to the debug log; it is shown in no transcript and
added to no context. Five classes of output rode that channel: the
pre-existing-ERROR lines, the created-files note with its inbox warning,
the vault-wide advisory — whose only automatic channel this is, because
`hook_post` never shows vault-wide findings — the fail-open ERROR report
that exists precisely to surface unfixed ERRORs once the gate releases,
and, since amendment 2026-08-05 ([[DEC_The_Gate_Names_The_Code_That_Stopped_Firing]]), the codes that stopped firing. Residual
1 of that amendment named the suspicion; issue #44 is it.

Amendment 2026-07-27 had recorded the opposite as a verified hook-API
fact: "Stop-hook plain stdout is user-facing only — the right channel for
advisory legacy drift". Two readings of one page, two opposite answers,
and an open question about the block `reason` that a third reading was
not going to settle either.

So this was measured rather than read. `tests/probe_hook_channels.sh`
ships the measurement; it runs each channel as a real session and reports
who received the marker.

### Measured on Claude Code 2.1.220

Print mode and interactive TUI, hook registered both in settings scope
and in SKILL.md frontmatter scope — the latter is how this gate is
actually registered, and a closed report (anthropics/claude-code#50542)
claimed plugin-scope `systemMessage` had stopped rendering in 2.1.114.

| channel | reaches the user | reaches Claude |
| --- | --- | --- |
| plain stdout, exit 0 | no | no |
| `systemMessage` | yes, renders as `Stop says: ...` | no |
| `hookSpecificOutput.additionalContext` | no | yes, and the turn continues |
| top-level `decision` + `reason` | yes, as `Stop hook error: ...` | yes, as a synthetic user message `Stop hook feedback:` |
| `decision` inside `hookSpecificOutput` | no | no — accepted, reported successful, blocks nothing |

Two further measurements decided the design. A `systemMessage` above
10000 characters is replaced by `Output too large (15.3KB). Full output
saved to: <path>` plus a 2 KB preview — the documented cap, with the
preview at 2 KB rather than the documented 10 KB
(anthropics/claude-code#44086). And `decision` and `systemMessage`
coexist in one object; the user sees both lines.

The nested block form deserves its own sentence. It is the shape every
other event uses, it is the tidier-looking one, and `json.dumps` of it
contains the literal `"decision": "block"`, so all seven substring
assertions in the suite passed against it. Adopting it would have
switched this gate off in a way nothing in this repository could see.

## Options

**Which channel carries the advisory report.**

- **A — `additionalContext`.** Rejected on the measurement: it reaches
  the model but continues the turn. A routine advisory about legacy
  drift would spend a model turn on work nobody asked for — the ground on
  which amendment 2026-07-27 ([[DEC_E2E_Test_Driven_Hardening]]) rejected it, now with a number behind it.
- **B — `systemMessage` (chosen).** The report is written for a human:
  it names files created, legacy findings, and questions only the session
  owner can answer ("say which of them you fixed").

**Which channel carries the fail-open ERROR report.**

- **C — also to the model, so the session fixes them.** Rejected. The
  gate demanded these fixes twice and released deliberately; handing them
  back automatically is the third attempt the release exists to prevent.
- **D — `systemMessage` only (chosen).** Whether to spend another turn on
  them is the user's call.

**What the block reason carries.**

- **E — reason keeps the advisory summary,** as before. Rejected: the
  advisory was measured at 23.9 KB on a 313-file production vault, and a
  block reason carries one obligation. Burying it under legacy drift is
  the failure this layer already refused twice — for vault-wide ERRORs in
  amendment 2026-07-27 and for the vanished-code report in 2026-08-05.
- **F — reason carries only the obligation, the advisory moves to a
  `systemMessage` beside it (chosen).** The two audiences get the two
  things they can act on, and the user learns who blocked the turn — the
  transcript otherwise says only `Stop hook error`, which is what
  Claude Code labels an intentional block (anthropics/claude-code#12667).

**How the report stays under the cap.**

- **G — truncate the assembled report.** Rejected: the last section is
  the vault-wide one, whose ERROR lines are exempt from the line cap on
  purpose because this report is their only automatic channel. Tail
  truncation would drop exactly them to keep a WARN dump.
- **H — cap every section at its source (chosen).** `advisory findings`
  was the only uncapped section; giving it the treatment the vault-wide
  section already had bounds the whole report without a truncation step,
  and `cap_report_lines` now serves all three sections.

## Decision

B, D, F and H. The report travels as `systemMessage`; the block keeps its
top-level `decision`/`reason` with the obligation alone and gains a
`systemMessage`; every section is capped at its source with ERROR lines
exempt. `stop_gate.sh` moves its crash message from stderr to a
`systemMessage` on stdout.

## Justification

### Design points

- **The crash message was the same defect wearing a different hat.**
  `stop_gate.sh` announced a released gate on stderr, which for a hook
  exiting 0 is the same dead channel. It is the one line that says vault
  rules are not being enforced right now, and it was the quietest thing
  the layer emitted.
- **`ensure_ascii` stays at its default, and this is not cosmetic.** A
  path that arrived through `surrogateescape` carries lone surrogates;
  `print()` cannot encode them, raises, and exits 2 — which releases the
  gate. `json.dumps` escapes them and the report survives. The change
  removes a latent crash path, and only stays removed while the default
  stands.
- **The fixtures had to learn what a channel is.** Every hook assertion
  read the validator's raw stdout, which cannot distinguish a channel
  that reaches someone from one that does not — 232 green assertions over
  a report nobody received. They now read a named field through
  `field()`, and the block form is asserted structurally with `has_key`.
- **One assertion got sharper by accident.** The encoding fixture matches
  `[encoding-not-utf8].*(pre-existing, non-blocking)`, which needs code
  and tag on one line. Against `json.dumps` the whole report is one line
  and `.*` would span unrelated findings — the same trap amendment
  2026-08-05 documented for `^` anchors and missed for `.*`. Reading
  through `field()` restores the line structure.
- **Six wrong implementations, each killed by an assertion.** Verified by
  mutation against the full suite: bare `print` (7 failures), the nested
  block form (3), the cap call removed (1), a cap that drops ERRORs (1),
  the crash message back on stderr (1), the fail-open report handed to
  the model (4). The ERROR exemption is asserted on `cap_report_lines`
  directly: below sixteen pre-existing ERRORs, `sorted()` puts every
  ERROR ahead of every WARN and a plain `lines[:15]` agrees with the
  exempting one by accident.
- **The advisory-cap fixture has its own vault.** The assertion is
  arithmetic — twenty notes, one finding each, fifteen reported and five
  counted — and in the violation vault the session would drag along
  whatever else is seeded there.

## Consequences

### Accepted residuals (documented, not solved)

1. **A blocking session still reports neither the vanished codes nor the
   vault-wide findings**, to anyone: both are computed after the branch
   that returns. With the advisory now leaving the reason, the ground for
   that ordering has narrowed to "the reason must stay one obligation",
   which the split already guarantees. Moving them is a change to what a
   blocking turn reports, not to a channel, and belongs to whoever needs
   it.
2. **ERRORs introduced while repairing are shown only to the human.**
   `new_errors` is recomputed per attempt, so an ERROR created during the
   second fix attempt appears for the first time in the fail-open report
   — which by decision D does not reach the model, while the last
   assistant message says the work is done. Distinguishing it needs the
   set of codes already blocked on, a state this layer does not keep.
3. **`hook_post` is uncapped.** Its `additionalContext` is assembled the
   same way and can pass 10000 characters on a file with many findings,
   with the same file-path-and-preview result. Same defect class, other
   event, out of scope here.
4. **The measurement is 2.1.220 and nothing else.** Every channel here is
   a UI decision of one client version, and one of them
   (anthropics/claude-code#50542) has already changed once. That is why
   the probe ships next to the suite rather than only its result.
5. **The probe cannot run offline or for free**, so it is not part of
   `run.sh`. A channel that silently changes upstream is caught by
   running it, not by the suite.

### Realization

- `validate_vault.py` — `cap_report_lines`; `hook_stop` emits
  `systemMessage`, splits the block into obligation and advisory, and
  caps `advisory findings`
- `hooks/stop_gate.sh` — crash message as `systemMessage` on stdout
- `tests/run.sh` — `field()` and `has_key()`; every stop assertion reads
  a named field; new: the structural block form, the block's own
  `systemMessage`, the fail-open channel split, the empty report that
  prints nothing, the crash path, fixture 8 for the cap, and the ERROR
  exemption; 232 to 245 assertions
- `tests/probe_hook_channels.sh` — the measurement, reproducible
- `SKILL.md` — the enforcement section says where the report appears

Observed at the real entry point: a throwaway vault, the skill's own
hooks, an interactive session writing one ARC note:

    ⎿  Stop says: vault validator session report:
       files created this session: ARC_Sensor.md
       vault-wide findings (advisory - not blocking, may include legacy state):
       WARN 00_documentation/01_projectvault/03_architecture_(ARC)/ARC_Sensor.md
       [orphan] no inbound links - unreachable except by search

The same session against the code before this branch shows nothing at
all — which was the point.
