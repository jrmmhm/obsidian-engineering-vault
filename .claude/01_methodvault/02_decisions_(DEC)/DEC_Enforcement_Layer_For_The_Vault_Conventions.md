---
domain: DEC
id: DEC-MTH-001
created: 2026-07-25
last-verified: 2026-10-16
---
Date: 2026-07-25
Status: Accepted
Migrated 2026-08-05 from the appended decision log, base record "Decision Record — AI Documentation Enforcement Layer". Corrected 2026-10-16: six research citations — in Context, option A, option B, the leak-detection design point and follow-up 1 — said more than their sources report; each now states what its source reports, and option B stands on the corrected evidence; and the stop gate's "max 2 blocks per session" no longer holds - it blocks once per stop sequence.
Corrected by: [[DEC_A_Citation_States_What_Its_Source_Reports]] – the DocPrism figures were misquoted, "collapse" and "only" overstated their sources, and caveats the sources attach were dropped
Corrected by: [[DEC_Enforcement_State_Is_Derived_Not_Kept]] – the gate decides from the Stop payload's `stop_hook_active` and blocks once per stop sequence; the per-session counter behind "max 2 blocks per session" is gone

## Context

The mechatronics baseproject vault is conceptually sound (SSOT, atomic
files, role/timeline separation — all consistent with current research on
LLM context quality), but every rule was prompt prose in SKILL.md.
Prompt-rule adherence measurably decays: each additional function a
coding agent generated within a session was associated with ~5.6% lower
odds of compliance (arXiv 2605.10039; non-monotonic rather than a
constant per-step effect, and found during analysis, not pre-specified).
The same factorial study detected no effect of rule-file size,
instruction position, file architecture or conflicting adjacent files —
affirmative nulls for size and conflict, failures to reject for position
and architecture. Performance degrades consistently as the number of
simultaneous instructions grows (up to ten tested, arXiv 2509.21051).
In an agent benchmark, policy violations rose from 0% with the policy in
full context to 30% after context compaction, up to 59% for some models,
and fell back to 0% when the constraints were pinned outside the lossy
compaction (arXiv 2606.22528). Observed symptoms in real projects:
overlong files, implementation details leaking into ARC/DEC/CMP,
link sprawl, ignored templates, docs contradicting code.

## Options

- **A — Harden the prose:** more rules, sharper checklists in SKILL.md.
  Rejected: the factorial study detected no effect of how the rule file
  is structured, while compliance still fell within the session, and more
  rules is what the instruction-count benchmark measured degrading. No
  measured lever on the decline lies in the prose.
- **B — Validator + skill-scoped hooks (chosen):** `validate_vault.py`
  enforces the mechanically checkable subset; PostToolUse feeds findings
  back immediately (the external feedback without which models struggle
  to self-correct on reasoning tasks, and sometimes get worse, arXiv
  2310.01798); a Stop gate blocks turn end on newly introduced
  ERRORs, ratcheted against git HEAD so legacy vaults never force mass
  migration.
- **C — CI/pre-commit in project repos:** catches human/Obsidian edits and
  all bypass routes uniformly, but blocks only at commit time and needs
  per-project rollout. Deferred as follow-up, not rejected.

## Decision

Option B now; C as follow-up. Required template sections are derived at
runtime from each project's own `00_*file_template*` files, so the global
validator cannot drift against per-project templates.

## Justification

### Design points

- Severities: ERROR blocks (via ratchet, only when introduced this
  session), WARN advises. Heuristic checks are WARN except
  numbers-with-units in ARC, which the ARC README bans outright (ERROR,
  unit whitelist, dates/versions/IDs stripped).
- Leak detection scans only ARC (whole body) and DEC Context — the
  value-bearing domains (REQ tables, CMP specs, IFC specs, TAE evidence,
  IMP, OAU) are legitimate homes for numbers. Naive holistic LLM auditing
  was rejected: plain prompting flagged 98% of functions as inconsistent
  with their documentation at F1 0.22, and local categorization with
  external filtering brought the flag rate to 14% and F1 to 0.77
  (DocPrism, arXiv 2511.00215).
- Stop gate: max 2 blocks per session, then fail-open with a visible
  report; validator crash (exit 2) always fails open. A gate that can
  brick a session gets disabled by its user — the worst outcome.
- Thresholds: length WARN >150 / ERROR >400 lines (Anthropic's 500-line
  skill ceiling is the only published hard number; retrieval quality
  degrades well below context limits — Chroma context rot); link budget
  WARN >20 (hubs 50), from Wikipedia MOS norms; no LLM-specific link
  study exists.
- `status: draft` relaxes nothing (silent-bypass prevention).

## Consequences

### Accepted residuals (documented, not solved)

- Bash file mutations, subagent writes, and human Obsidian edits bypass
  the hooks. SKILL.md forbids the first two; option C closes all three.
- Doc-vs-code *semantic* consistency is only partially covered (artifact
  paths must exist; pointers-over-copies shrinks the drift surface; the
  invalidation sweep is prose). Full coverage needs the follow-up below.
- Leak detection outside ARC stays advisory; a determined session can
  rubber-stamp WARNs. The precision fixture in tests/ keeps the detector
  honest against false-positive creep.

### Follow-ups

1. Ship the validator (or a caller) as a pre-commit/CI hook in the
   baseproject template so derived projects and human edits are covered
   (the per-commit GitHub Action scan for outdated code-element
   references that arXiv 2212.01479 proposes as future work).
2. Doc-claim grep check: literal values/identifiers quoted in IMP checked
   against the referenced source files.
3. Roll out template frontmatter to existing derived projects via
   /baseproject-sync when their vaults are next touched.

### Realization

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
