# Decision Record — AI Documentation Enforcement Layer

Date: 2026-07-25
Status: Accepted

## Context

The mechatronics baseproject vault is conceptually sound (SSOT, atomic
files, role/timeline separation — all consistent with current research on
LLM context quality), but every rule was prompt prose in SKILL.md.
Prompt-rule adherence measurably decays: ~5.6% lower compliance odds per
generated unit within a session (arXiv 2605.10039, which also found NULL
effects for rule-file size/position/structure — rewriting prose does not
help), collapse under rule count (arXiv 2509.21051), and 0% → 30–59%
policy violations after context compaction, restored to 0% only by
mechanical pinning (arXiv 2606.22528). Observed symptoms in real projects:
overlong files, implementation details leaking into ARC/DEC/CMP,
link sprawl, ignored templates, docs contradicting code.

## Options

- **A — Harden the prose:** more rules, sharper checklists in SKILL.md.
  Rejected: the factorial study shows restructuring rule files has no
  detectable effect; decay is the mechanism, and prose cannot stop it.
- **B — Validator + skill-scoped hooks (chosen):** `validate_vault.py`
  enforces the mechanically checkable subset; PostToolUse feeds findings
  back immediately (external feedback works where self-correction does
  not, arXiv 2310.01798); a Stop gate blocks turn end on newly introduced
  ERRORs, ratcheted against git HEAD so legacy vaults never force mass
  migration.
- **C — CI/pre-commit in project repos:** catches human/Obsidian edits and
  all bypass routes uniformly, but blocks only at commit time and needs
  per-project rollout. Deferred as follow-up, not rejected.

## Decision

Option B now; C as follow-up. Required template sections are derived at
runtime from each project's own `00_*file_template*` files, so the global
validator cannot drift against per-project templates.

## Design points

- Severities: ERROR blocks (via ratchet, only when introduced this
  session), WARN advises. Heuristic checks are WARN except
  numbers-with-units in ARC, which the ARC README bans outright (ERROR,
  unit whitelist, dates/versions/IDs stripped).
- Leak detection scans only ARC (whole body) and DEC Context — the
  value-bearing domains (REQ tables, CMP specs, IFC specs, TAE evidence,
  IMP, OAU) are legitimate homes for numbers. Naive holistic LLM auditing
  was rejected: 98% flag rate at 14% accuracy vs 94% with local scoped
  categorization (DocPrism, arXiv 2511.00215).
- Stop gate: max 2 blocks per session, then fail-open with a visible
  report; validator crash (exit 2) always fails open. A gate that can
  brick a session gets disabled by its user — the worst outcome.
- Thresholds: length WARN >150 / ERROR >400 lines (Anthropic's 500-line
  skill ceiling is the only published hard number; retrieval quality
  degrades well below context limits — Chroma context rot); link budget
  WARN >20 (hubs 50), from Wikipedia MOS norms; no LLM-specific link
  study exists.
- `status: draft` relaxes nothing (silent-bypass prevention).

## Accepted residuals (documented, not solved)

- Bash file mutations, subagent writes, and human Obsidian edits bypass
  the hooks. SKILL.md forbids the first two; option C closes all three.
- Doc-vs-code *semantic* consistency is only partially covered (artifact
  paths must exist; pointers-over-copies shrinks the drift surface; the
  invalidation sweep is prose). Full coverage needs the follow-up below.
- Leak detection outside ARC stays advisory; a determined session can
  rubber-stamp WARNs. The precision fixture in tests/ keeps the detector
  honest against false-positive creep.

## Follow-ups

1. Ship the validator (or a caller) as a pre-commit/CI hook in the
   baseproject template so derived projects and human edits are covered
   (the arXiv 2212.01479 outdated-reference GitHub-Action pattern).
2. Doc-claim grep check: literal values/identifiers quoted in IMP checked
   against the referenced source files.
3. Roll out template frontmatter to existing derived projects via
   /baseproject-sync when their vaults are next touched.

## Realization

- `validate_vault.py` — validator (CLI + hook modes, stdlib only)
- `hooks/post_write_check.sh`, `hooks/stop_gate.sh` — thin wrappers,
  fail-open on crash
- `SKILL.md` — hooks in frontmatter; prose trimmed where now mechanical;
  added: invalidation sweep, 3-recent-DECs rule, evidence-or-unverified
  rule, closing checklist, full-audit closing step
- `tests/run.sh` — 37 assertions: precision vault (zero findings),
  violation vault (24 seeded codes), hook post/stop incl. block release,
  crash mode, real template vault
- Baseproject: frontmatter in 12 templates; conventions file section 3
  (frontmatter, self-containedness, wikilinks, length, freshness); EARS +
  anti-smells in REQ README; AI-layer paragraph in vault README

## Amendment 2026-07-27 — E2E-test-driven hardening (Accepted)

A trapped end-to-end harness run (11 seeded traps, answer key written
before the run) passed 11/11 via skill prose alone, but exposed three
enforcement gaps. All three fixes accepted and shipped:

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

Verified hook-API facts (code.claude.com/docs/en/hooks): PostToolUse
`additionalContext` reaches the model (10k char cap); Stop-hook plain
stdout is user-facing only — the right channel for advisory legacy
drift; Stop `hookSpecificOutput.additionalContext` would continue the
conversation and is therefore unsuitable for routine advisories.

Open question (follow-up): the docs suggest a Stop block `reason` may
be user-only too. If confirmed by a live probe, the gate's fix
instructions should additionally be emitted as `additionalContext`
alongside `decision: block` so the model reliably sees them.

New accepted residual: the body path scan only catches `NN_`-prefixed
project paths (precision over recall, consistent with the leak
detector). Realization: `validate_vault.py` (`check_paths`,
`hook_post`, `hook_stop`); `tests/run.sh` now 47 assertions;
SKILL.md cross-linking rule 4 and enforcement section updated.
