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

## Amendment 2026-07-28 — Language-independent recognition, VCS tier (Accepted)

### Context

The validator was unusable on every non-English vault. `is_vault_root`
tested `00_*file_template*.md`, an English-only spelling, so both German
production vaults (homelab, PMDE) exited 2 — "validator could not run" —
which both Claude Code hooks deliberately swallow. Enforcement had been
silently off on ~250 files edited since 2026-07-25. Two further sites
assumed the same spelling: `templates_for`, which derives the required
section headings, and the infra-template branch of `validate_file`.
Fixing only the first would have been worse than the hard failure:
`check_sections` returns early on an empty template list, so the vault
would have validated green while checking no sections at all.

Enforcement also depended entirely on one editor being used. Option C of
the 2026-07-25 decision (CI/pre-commit) and follow-up 1 were deferred
then; human Obsidian edits and Bash mutations remained uncovered.

### Options

- **A — Marker pair per language** (`file_template`, `Dateitemplate`):
  explicit, but produces an EN/DE asymmetry in REF, where German
  `00_REF_Dateireferenz_Dateitemplate.md` carries the marker as a
  compound suffix while English `00_REF_file_reference_template.md` does
  not — the German vault would be checked more loosely than the English
  one, the exact divergence this change exists to remove.
- **B — Single case-insensitive marker `template` (chosen):** the shared
  Latin root covers `file_template` and `Dateitemplate` alike, READMEs
  never contain it, and the REF asymmetry disappears. Measured identical
  on all four vaults and both `02_documents` mirrors.
- **C — Negative pattern** (any `00_*.md` that is not a README): needs no
  marker at all, but makes the `01_projectvault` vs `02_documents`
  distinction depend on the *absence* of arbitrary `00_*.md` files in the
  mirror. Rejected: that is the looser test the distinction exists to
  prevent.

### Decision

Option B, behind one named constant `TEMPLATE_MARKERS` used at all four
sites (vault-root detection, section derivation, template classification,
and the CLI error message). Plus a pre-commit hook and a GitHub Actions
workflow, both stdlib-only. The pre-commit hook reports and never blocks
by default; blocking is opt-in per environment variable.

### Design points

- The pre-commit hook validates the **staged files only**, not the vault.
  A ratchet like the stop gate's would need a HEAD baseline per file; the
  staged-file scope achieves the same practical effect ("what you touch,
  you keep clean") without a second baseline mechanism, and keeps the
  blocking mode reachable on a vault with 501 legacy ERRORs.
- Report-not-block is the default, opt-in blocking via
  `MECHDOCS_PRECOMMIT_BLOCK=1`. Same reasoning as the stop gate's
  fail-open: a hook that strands its owner mid-commit gets deleted.
- The ratchet itself was broken wherever the vault is its own git repo
  (both German vaults are). `git_head_content` asked `project_root`, the
  grandparent, which is not a repo there — so the baseline was always
  empty and every pre-existing ERROR counted as introduced this session.
  Making the German vaults visible without this fix would have blocked
  the stop gate twice in every session on them. `Vault.git_root()`
  resolves the real repo root via `git rev-parse --show-toplevel`.

### Accepted residuals (documented, not solved)

1. **German domain abbreviations never reach the domain-specific checks.**
   The folder abbreviation is the dispatch key, and only `REQ`, `DEC` and
   `TAE` have domain-specific branches. A German vault spells them `ANF`,
   `ENT` and `TUE`, so those branches never run: no REQ table validation,
   no `req_index` (hence no `req-uncovered` coverage check and no
   `verifies-unknown-req`), no DEC `Status:` validation, no `verifies:`
   frontmatter requirement, and no Context leak scan (`check_leaks`
   covers `ARC`/`DEC` only). In homelab that is 108 of 244 domain files
   (ANF 9, ENT 61, TUE 38). `KMP`, `SST` and `BUN` lose nothing — `CMP`,
   `IFC` and `OAU` have no domain-specific branches to begin with.
   Note the effect is not uniformly laxer: `check_frontmatter` exempts
   only `DEC` from the `status` key, so German `ENT` files are held to a
   **stricter** frontmatter contract than English `DEC` files.
2. **English-only section and file name heuristics.** `system_overview.md`
   is hardcoded twice (hub link budget, `arc-not-in-overview`), and the
   References/Sources ERROR zone in `check_paths` plus the leak exemption
   in `check_leaks` test for the literal substrings `reference`/`source`.
   German vaults name these `Systemuebersicht.md`, `## Referenzen` and
   `## Quelle(n)`, so those checks stay dark. This produces missing
   findings, never wrong ones, and never an exit 2.
3. **The pre-commit hook reads the worktree, not the index.** A cleanly
   staged file with broken unstaged changes is judged by the unstaged
   state. Tolerable while the hook only reports.
4. **The CI workflow hardcodes the English vault path** and lives in the
   template repo. A derived German project cannot use it as-is: its repo
   root *is* the vault and carries no `.claude/skills/`.

### Follow-ups

4. Domain-role alias map (`ANF→REQ`, `ENT→DEC`, `KMP→CMP`, `SST→IFC`,
   `TUE→TAE`, `BUN→OAU`) plus a requirement-ID prefix constant, closing
   residual 1. Deliberately not bundled here: it would immediately raise
   38 new `verifies` ERRORs on a vault that never had that convention,
   mixing a language fix with a convention rollout.
5. Lift `system_overview.md` and the References/Sources section names into
   named constants, closing residual 2.
6. Ship the pre-commit hook and a vault-discovering CI workflow into
   derived projects via `/baseproject-sync`, closing residual 4.

### Realization

- `validate_vault.py` — `TEMPLATE_MARKERS`/`TEMPLATE_NAME_RE`,
  `template_files()`, `Vault.git_root()`; `ROOT_ALLOWLIST` removed (dead
  since written, English-only, reads like a fifth language dependency)
- `hooks/pre_commit_vault.sh`, `.github/workflows/validate-vault.yml`
- `tests/run.sh` — now 55 assertions: German/English twin pair with
  byte-identical content and separate mktemp roots (`check_paths` probes
  `project_root.parent`), German `02_Dokumente` mirror rejected via both
  entry points, `--file` upward detection. Also resolves the skill path
  with `cd -P`: invoked through the `~/.claude/skills` symlink,
  `REAL_VAULT` pointed outside the repo and the "template vault stays at
  0 errors" guard skipped silently — 46 assertions instead of 47
- `SKILL.md` — enforcement section names the two VCS tiers

Measured after the change: English template vault unchanged at 0 errors /
9 warnings, homelab 501 errors / 113 warnings, PMDE 414 errors / 96
warnings, both `02_documents` mirrors still rejected as non-roots.

## Amendment 2026-07-28b — Object identity and typed relations (Accepted)

### Context

The vault ships as templates only. A visitor can read the method but
cannot see it work (issue #1), and three structural gaps block the
roadmap behind it. Requirements carry a real identifier scheme
(`REQ-DOM-NNN`); every other domain is identified by its filename, so a
rename changes identity and history cannot connect the note called X
today with the note called Y last spring (issue #3). Relations are
untyped: a wikilink to a requirement and a wikilink to a decision are
the same two brackets, and their meaning lives entirely in the heading
they appear under, so "which requirements does this module allocate" is
a heading-position heuristic rather than a query (issue #4). Without
both, the requirement-to-evidence matrix in issue #2 has no graph to
read — least of all in the reverse direction, which today exists only
as a heading a human interprets.

This amendment settles the minimum data model that carries the worked
example and does not block #3, #4 or #2. It deliberately ships an
*unenforced* scheme: the exporter is not built and the validator is not
made schema-driven, because both are separate issues with their own
acceptance criteria.

### Options

**Identity.**

- **A — Filename stays the identifier, uniqueness promoted to ERROR.**
  Cheapest: `duplicate-basename` already computes vault-wide name
  uniqueness, Obsidian already maintains wikilinks, and a rename becomes
  a loud `link-unresolved` ERROR instead of a silent event. Rejected:
  uniqueness of the *current* name is not continuity of identity, which
  is exactly what issue #3 asks for; and Doorstop is the shipped proof
  of how painful filename-as-UID becomes — its UID *is* the filename,
  renaming invalidates every `links:` entry, and no rename command
  exists.
- **B — Human identifier in frontmatter (chosen).** `id: <DOMAIN>-<SCOPE>-<NNN>`,
  with the existing `REQ-DOM-NNN` row IDs as the already-shipped special
  case of the same rule. Survives renames because identity lives in the
  file, not in its name. Assignment without a registry follows
  StrictDoc, which scans the tree for the next free value rather than
  keeping a counter file.
- **C — Machine identifier (StrictDoc MID).** A 32-character hex UUID
  per object, immune to every human edit. Rejected: MIDs are generated
  by a round-trip writer on save, and this vault is edited by humans in
  Obsidian and has no writer that could assign one. A hand-typed UUID is
  a transcription error waiting to happen.

**Relations.**

- **D — Relation lists in frontmatter on both the ARC note and the
  targets.** Trivial to parse with the existing flat YAML reader.
  Rejected: the allocation would then exist twice, in the table a human
  reads and in the frontmatter a machine reads, and the two would drift.
  Issue #4 is explicit that typing the relations must not move them.
- **E — Bind relations to the template-declared section.** `Vault.templates_for`
  already derives each domain's H2 set from that project's own
  `00_*template*` file, in whatever language it is written, so "the
  table under the ARC template's seventh H2" is language-independent by
  construction. Rejected as the primary mechanism because it is still
  heading position, which is the property issue #4 names as the defect;
  kept as the documented fallback for a vault whose schema is missing.
- **F — Declared table-header signature plus self-typing annotated
  links (chosen).** The schema declares the header row of each relation
  table and binds column roles to it, so the heading above the table is
  irrelevant. Everywhere else, a cross-domain link is annotated with the
  target's identifier — `[[CMP_Battery_Pack]] (CMP-BAT-001)` — and the
  domain token inside the identifier types the relation. Both mechanisms
  read the single place the fact is already authored.

**Reverse direction.** Not an option set: StrictDoc, Doorstop and
Sphinx-Needs all author the relation on the source only and derive the
reverse at build or query time — Sphinx-Needs computes `<kind>_back`
fields, StrictDoc builds the reverse in the traceability graph from
`REVERSE_ROLE`, Doorstop scans every document whose parent prefix
matches. Hand-maintained back-links are rejected by all three, and by
this decision.

### Decision

Option B for identity, option F for relations, with the reverse
direction always derived and never authored.

Identifiers: `id:` in frontmatter, shape `<DOMAIN>-<SCOPE>-<NNN>`,
`DOMAIN` the folder abbreviation, `SCOPE` the subsystem token the REQ
file carries in parentheses, `NNN` local to that pair, never reused,
gaps allowed. REQ files take `REQ-<SCOPE>-000`, with `000` reserved for
the file so that the row IDs `001…` keep their existing meaning and the
two namespaces cannot collide. ADM and INB are excluded because
SKILL.md classifies them as not engineering documentation.

Relations: seven named kinds — `allocates`, `evidence`, `verifies`,
`justified-by`, `connects`, `contains`, `test-object` — each with
exactly one authoring location, each declared in `vault_schema.json`
together with its subject and object domains and its reverse key.

The schema is written now and read by nothing. Every entry carries a
flag stating whether the validator already enforces it internally
(`validator-internal`, meaning the rule exists in Python and the schema
only describes it so that #4 can remove the duplication) or whether
nothing enforces it yet (`declared-only`).

### Consequences

- Issue #3 inherits a settled scheme and one concrete rule to
  implement: vault-wide `id` uniqueness, plus detection of identifiers
  that vanish between commits.
- Issue #4 inherits the schema file, the seven relation kinds and the
  binding rules; its work is making the validator read them.
- Issue #2 inherits a graph in which both directions are derivable from
  authored data, which is the precondition it names.

### Accepted residuals (documented, not solved)

1. **Nothing detects an identifier collision.** The scheme says collisions
   are detected, not prevented; in this change they are neither. Two
   branches can assign the same number and merge green. Owed to #3.
2. **REQ row IDs are still derived from the filename.** `Vault.req_index`
   reads the scope token out of the parentheses in the REQ filename, so
   renaming a REQ file still changes the identity of its rows — the very
   defect #3 describes, now one indirection away from fixed. The scope
   token is additionally declared as the REQ file's own `id`
   (`REQ-<SCOPE>-000`), which is the migration path; making the validator
   prefer it is #3's work.
3. **The table header signature is language-dependent.** A vault written
   in another language finds no relation table and produces an empty
   graph without an error — the same silent-loss class as residual 2 of
   the 2026-07-28 amendment. Mitigated by declaring the schema
   per-project overridable at `00_documentation/vault_schema.json`;
   discovery is declared, not implemented.
4. **Nothing keeps the header signature and the templates in sync.**
   Reformatting the allocation table's header row silently removes every
   relation it carried. A validator rule asserting that an ARC file
   contains a table matching the declared signature belongs to #4.
5. **The example ships into every derived project.** `README.md` names
   the files to delete; `/baseproject-sync` has no notion of the example
   and will not remove it for you.

### Realization

- `vault_schema.json` — field and relation declarations, per entry
  flagged `validator-internal` or `declared-only`; table header
  signatures, consistency rules owed to #3/#4, and the list of links
  that deliberately stay untyped
- Worked example thread in the vault: `REQ_Battery_Monitoring (BAT)`,
  `DEC_Battery_Log_Acceptance_Check`, `ARC_Battery_Monitoring`,
  `CMP_Battery_Pack`, `IFC_PWR_DC_LiPo_Pack`,
  `IMP_Battery_Log_Evaluation`, `TAE_Battery_Log_Acceptance`, plus the
  module row in `system_overview.md`
- `20_software/data_analysis/collect_battery_log.py` and
  `eval_battery_log.py` — stdlib only; the evaluator prints one verdict
  per requirement ID so its output is quotable as evidence
- `30_testdata/31_testdata_raw/2026-07-28_battery_monitoring/` — the
  recorded log and its campaign metadata; the negative control lives
  under `32_testdata_processed/` because it is derived, not measured
- Nine domain templates gained an `id` line; the conventions file gained
  the identifier and relation section
- `.github/workflows/validate-vault.yml` — runs the evaluator against the
  committed log and asserts the negative control still fails
- `README.md` — the worked example, how to re-run its evidence, and how
  to delete it

Measured after the change: template vault unchanged at 0 errors /
9 warnings — the example introduced no new finding — and
`tests/run.sh` at 55 tests, 0 failures. The nine warnings are the
pre-existing ones: eight placeholder wikilinks in READMEs and templates
that no example file can resolve, and one duplicate `README` basename.
The example was never able to clear them; that claim in issue #1 is
wrong and the issue has been corrected.

## Amendment 2026-07-28c — Identifier enforcement (Accepted)

### Context

Amendment 2026-07-28b settled the identifier scheme and shipped it
deliberately unenforced, leaving two named residuals: nothing detected a
collision, and REQ row identity was still derived from the filename, so
renaming a REQ file still changed what its rows were. Issue #3 asks for
exactly those two things — a validator rule for uniqueness and for
identifiers that vanish between commits — plus the rollout into the two
templates the worked example never touched.

The whole question is one of severity, not of mechanism. The vault this
repository ships carries sixteen identifiers; the two German production
vaults carry **none**, and a rule that treats their absence as a defect
would report every domain file in both.

### Options

**A missing identifier.**

- **A1 — require `id` on every domain file.** Rejected on measurement:
  homelab has 244 domain files and PMDE 232, none with an identifier, so
  this single decision would have roughly doubled homelab's finding count
  and added about 56% to PMDE's. That is a convention rollout wearing a
  bug fix's clothes — the same mixing that follow-up 4 of the 2026-07-28
  amendment was split off to avoid.
- **A2 — compare only the identifiers that are actually present
  (chosen).** Costs both German vaults exactly zero findings, measured
  before and after rather than assumed.

**A vanished identifier.**

- **B1 — ERROR.** Rejected. No established tool treats disappearance as a
  validation error. StrictDoc surfaces `REQUIREMENT_REMOVED` as a
  changelog entry with exit code 0, and documents that UID-based change
  tracking cannot reliably distinguish a modified node from a relocated
  one. prostep ivip's ReqIF Implementation Guide V1.8 §2.15 addresses
  literally this case — requirements missing from a re-imported
  specification — and prescribes *marking them deleted*, noting that a
  deliberate deletion and an accidental export loss are indistinguishable;
  the standard carries `ReqIF.ForeignDeleted` as the tombstone attribute
  for it, and DOORS implements the same thing as a soft delete before an
  explicit purge.
- **B2 — WARN (chosen).** Clippy reserves its deny-by-default
  `correctness` group for lints that "should be free of false positives"
  and files code that "might be possible ... is intentionally written like
  it is" under warn-level `suspicious`; Google's Tricorder criteria demand
  "no effective false positives" and "issues affecting only correctness"
  before a check may block a build. A disappearance meets none of that: it
  is equally a retirement, a rename or a loss.

**A duplicate identifier.** ERROR, uncontested. StrictDoc aborts with
`sys.exit(1)` when two nodes share a UID, annotated against its own
requirement SDOC-SRS-29. After the pattern gate below the check has zero
false positives by construction, concerns correctness alone, and is
trivially actionable — which is precisely Tricorder's bar for a blocking
check and Clippy's definition of `correctness`. The damage it prevents is
silent: of two objects sharing an identifier, one drops out of every
evaluation without anyone noticing.

**Reading HEAD.**

- **C1 — diff in the pre-commit hook** (`git diff --cached` filtered for
  removed `id:` lines). Genuinely simpler: it needs no pathspec probe, no
  candidate loop and no git-backed fixture, and it removes the rebase and
  vault-rename false positives outright. Rejected because issue #3 asks
  the *validator* for the rule, and because the hook sees staged files
  only — a loss that is never staged stays invisible for the whole
  session. Recorded here rather than dropped, since it remains the better
  design if the check ever proves noisy.
- **C2 — set difference against HEAD inside the validator (chosen)**,
  reusing `Vault.git_root()` and `git_head_content()`, which already
  handle a vault that is its own repository — which both German vaults are.

### Design points

- **Only pattern-conforming identifiers are compared.** An unfilled
  template placeholder (`ARC-DOM-NNN`), an empty `id:`, a trailing comment
  and a YAML list (`id: [X]`, which the frontmatter reader returns as a
  list) are not identities. Without this gate the documented workflow —
  copy the template, then fill it in — would produce an ERROR between two
  files that merely share an unedited placeholder.
- **A candidate prefilter bounds the cost.** One `git grep` selects the
  files that declare an identifier at HEAD; only those are read
  individually. A vault without identifiers therefore performs zero
  per-file reads, which is what keeps both German vaults free of the cost.
- **"Cannot compare" stays distinct from "nothing to compare".** A vault
  folder renamed since HEAD would otherwise look like a vault that lost
  every identifier at once — which is the state of the in-flight
  `feat/vault-english-migration` branch of the homelab vault. An
  `ls-tree` probe on the vault path separates the two.
- **`id-scope-mismatch` (WARN).** When a REQ file's identifier scope
  contradicts the token in its filename, the identifier wins and every row
  of that file is silently rekeyed. Without this the failure surfaces as
  `verifies-unknown-req` on the *evidence* notes — a per-file ERROR that
  does enter the stop gate's blocking set, on files that are not at fault.
- **ADM and INB are excluded** from the identifier scheme, as
  `identifier.rules` already declared; `classify()` alone would have let
  ADM through.
- **Iteration is sorted.** Which of two colliding files is reported and
  which is named as the other one must not depend on filesystem order.
  This also fixes the same latent nondeterminism in `req-duplicate-global`.
- **Vault-wide ERRORs survive the stop report's 15-line cap.** That report
  is their only automatic channel, because `hook_post` never shows
  vault-wide findings at all.
- **Nothing in the new code may raise.** A crash exits 2, and both hooks
  swallow exit 2 — a hard failure would switch enforcement off silently
  rather than loudly. Every git call carries a timeout and every failure
  path returns "skip the check". `git_head_content` additionally decodes
  with `errors="replace"`, because a non-UTF-8 byte in a tracked file
  would otherwise raise inside `subprocess.run` itself.

### Accepted residuals (documented, not solved)

1. **File identifiers and REQ row identifiers remain separate
   namespaces.** A REQ file declaring `id: REQ-BAT-001` collides with its
   own row `001`, and neither check sees it — the very collision the
   `000` reservation exists to prevent. Merging the namespaces would
   immediately ERROR on any legacy REQ file whose identifier is not
   `-000`, which is option A1's mistake in miniature. Owed to a follow-up.
2. **The identifier pattern itself is still unenforced.** A malformed
   identifier is ignored rather than reported, so a malformed *and*
   duplicated one escapes. Deliberate: the alternative is a presence-and-
   shape rule, which is residual 1's problem again.
3. **`git cat-file --batch` would read all blobs in one process, measured
   about 30× faster than one `git show` per file.** Not adopted: the
   prefilter already bounds the per-file reads to files that declare an
   identifier, and the measured full-audit cost is +34 ms on the template
   vault and +66 ms on homelab.
4. **Case-sensitive.** `Id:` or `ID:` is missed by both the prefilter and
   the frontmatter reader — consistently, so it produces no wrong finding,
   but it is a silent miss.
5. **A file moved out of the vault reports as vanished**, because the
   identifier is genuinely no longer in the vault. WARN only, and the
   message says so.
6. **An interrupted rebase, bisect or conflicted merge** leaves HEAD ahead
   of the worktree and produces a burst of WARNs. Advisory only.
7. **The environment is not scrubbed** before the git calls, so a
   `GIT_DIR` inherited from an enclosing git hook could redirect them at
   another repository. Unreachable today: the pre-commit hook runs the
   validator in `--file` mode, which never reaches these checks.
8. **In CI the vanished check can never fire**, because there the working
   tree equals HEAD. It is a pre-commit-window signal by nature — which is
   what "vanish between commits" means — and the uniqueness check is the
   one that carries CI.

### Realization

- `validate_vault.py` — `ID_RE`, `REQ_FILE_ID_RE`, `ID_EXCLUDED_DOMAINS`,
  `frontmatter_id()`, `req_scope()`, `head_identifiers()`,
  `check_identifiers()`; `Vault.req_index()` and the vault-wide REQ
  duplicate loop now resolve the scope token through `req_scope()` and
  iterate sorted; `hook_stop` keeps vault-wide ERRORs out of the cap
- `tests/run.sh` — now 71 assertions: identifiers in the precision fixture
  (which must stay at zero findings), a collision and a scope mismatch in
  the violation fixture, a placeholder pair that must *not* collide, a
  collision in both twins, and a fourth fixture under version control —
  hermetic against ambient git configuration, since a CI runner has no
  user identity and global gpg signing would hang on a passphrase prompt
- `vault_schema.json` — `identifier.collision_policy` and the new
  `identifier.scope_resolution` flagged `validator-internal`,
  `consistency_rules/identifier-uniqueness` likewise with the codes and
  severities named, `identifier.enforced_detail` stating what is still
  *not* enforced, and `OAU` and `REF` added to `domains`, where both were
  missing entirely
- `00_OAU_file_template.md`, `00_REF_file_template.md`,
  `00_REF_file_reference_template.md` — the identifier field, completing
  the rollout the worked example skipped
- `00_documentation_file_creation_and_conventions.md` — the claim that the
  validator does not check identifiers, which this change makes false

Measured after the change: template vault unchanged at 0 errors /
9 warnings, homelab unchanged at 255 / 115, PMDE unchanged at 414 / 96,
with zero identifier findings in either German vault. Full-audit runtime
0.073 → 0.107 s (template), 0.360 → 0.426 s (homelab), 0.290 → 0.327 s
(PMDE). `tests/run.sh` at 71 tests, 0 failures.

Note on an earlier figure: the 2026-07-28 amendment recorded homelab at
501 errors / 113 warnings. Re-measured at the start of this change it
stood at 255 / 115 — the vault has been worked on since, and the older
number should not be carried forward as a baseline.

## Amendment 2026-07-28d — Schema-driven field validation (Accepted)

### Context

Amendment 2026-07-28b wrote `vault_schema.json` and had nothing read it.
The frontmatter rules therefore existed twice: as data in the schema and
as Python literals in `check_frontmatter` (`GENERIC_STATUS`,
`DEC_BODY_STATUS`, the required-key list, the `("M","S","O")` tuple).
Issue #4 asks for the reverse: the file becomes authoritative, the code
reads it, and a field nobody declared is reported instead of ignored.

Two measurements framed the whole change. First, a field inventory over
the template vault and both German production vaults: **no file carries
an undeclared frontmatter key** — the single candidate, PMDE's
`IMP_Host_Website_Beispiel.md`, carries `excalidraw-plugin` and `tags`,
both of which an editor-field allowlist covers. An undeclared-field
check therefore costs all three vaults zero findings, which puts it in
the bug-fix class rather than the convention-rollout class that
follow-up 4 of the 2026-07-28 amendment exists to keep separate.

Second, and unrelated to the issue but on the exact code path it
rewrites: a list-valued scalar field crashes the validator.
`fm["status"] not in GENERIC_STATUS` hashes its left operand, and
`parse_frontmatter` returns a list for `status: [active]`. Measured on a
seeded fixture, all three entry points exit 2 — and both hooks swallow
exit 2, so one such file switches the entire enforcement layer off
silently. It is fixed first, as its own change.

### Options

**Where the schema lives and who may override it.**

- **A1 — packaged schema plus a per-project override at
  `00_documentation/vault_schema.json`,** as `discovery` in the schema
  declared and left unimplemented. Rejected on two independent grounds.
  It is a silent off-switch for the blocking gate: the ERRORs that reach
  the stop gate's blocking set come from `check_frontmatter`,
  `check_dec_status` and `check_req_table`, which are precisely the three
  this change makes schema-driven, so a two-line override flipping an
  `enforced` flag to `declared-only` disables a blocking check from a file
  that is not even committed — the same class as `status: draft` relaxing
  a rule, which this project rejected outright. And it would not work
  where it was meant to: `Vault.doc_root` is the vault's parent, but both
  German vaults *are* their own git repository, so the override path lies
  outside version control and would not sync between the two machines
  that push homelab.
- **A2 — one packaged schema, read-only, no override (chosen).** Every
  vault is checked against the schema shipped with the validator that
  checks it. A project needing different rules forks the skill, which is
  visible in a diff.

**Severity of an undeclared field.**

- **B1 — ERROR,** as StrictDoc does: an unregistered field raises
  `unregistered_field` and exits 1, with no permissive mode. Rejected.
  StrictDoc's grammar ships inside the document and its primary author is
  a round-trip editor; here the file is hand-written in Obsidian and the
  schema ships with the tool, so the two can drift.
- **B2 — WARN (chosen).** The check cannot distinguish a typo from an
  intention, which is exactly Clippy's disqualification criterion for its
  deny-by-default `correctness` group — reserved for lints "free of false
  positives", while anything that "might be ... intentionally written like
  it is" belongs to warn-level `suspicious` — and Google Tricorder's bar
  for a build-blocking check ("produce no effective false positives").
  PMDE's Excalidraw file is the empirical case: a plugin's own field, not
  a defect. Sphinx-Needs reaches the same place from the other side, where
  `unevaluatedProperties: false` is opt-in and motivated verbatim by
  "catching typos in property names"; SchemaStore advises against closing
  human-authored schemas at all, and Cargo warns rather than fails on an
  unknown manifest key.

**Which rules move into the schema.**

- **C1 — everything the schema describes,** including `ID_RE`,
  `REQ_ID_RE` and `ID_EXCLUDED_DOMAINS`. Rejected: `frontmatter_id()` and
  `head_identifiers()` resolve identity in module-level functions that run
  without a schema in hand, and identity resolution decides which values
  are compared against git HEAD. Drift is instead caught by a test
  asserting the Python constants and the schema's declared patterns accept
  and reject the same samples.
- **C2 — the field vocabulary and the enumerations (chosen):** required
  keys, permitted `status` values, the DEC body `Status` values, the REQ
  class values, and the declared-field vocabulary the new check reads.

**Domains the schema does not name.** The dispatch key is the folder
abbreviation, and the German vaults spell it `ANF`, `ENT`, `KMP`, `SST`,
`TUE`, `BUN` — none of which appears in `domains`. Reading only
`domains[abbr]` would leave 220 of homelab's 248 domain files unchecked,
or, if absence meant "nothing is declared", report every field of every
one of them. Chosen: a `domain_defaults` block that declares the
vault-wide vocabulary and applies to every domain, with per-domain
entries merging into it attribute by attribute. This reproduces today's
behaviour exactly, including that `DEC` alone is exempt from `status`.

### Decision

Option A2, B2, C2, with `domain_defaults` as the fallback profile for
unnamed domains. The `enforced` flag stops being a comment and becomes
the switch: `schema-driven` means the validator reads this entry from
here, `validator-internal` means the rule stays in Python for a stated
reason, `declared-only` means nothing enforces it. `id` stays
`declared-only`, so the identifier pattern remains unenforced on values
and an unfilled `ARC-DOM-NNN` placeholder still produces no finding.

`verifies` is declared vault-wide but enforced only in `TAE`. homelab's
37 `TUE` files carry it as an empty list; enforcing the rule globally
would add 37 `verifies-empty` warnings to a vault that never had the
convention, which is the language-fix-plus-convention-rollout mixture
that follow-up 4 was split off to avoid.

The relation `superseded-by` is added, closing a gap between the issue
text and the schema. Direction matters: the link is authored in the
*superseded* decision as `Superseded by: [[DEC_...]]`, so the subject is
the old decision, and naming it `supersedes` would reverse the arrow
against the other seven kinds, which are all authored subject-first.

### Design points

- **The undeclared check also runs on `00_` templates, for vocabulary
  only.** A template is the file every new file is copied from, so an
  undeclared key there propagates silently into everything derived from
  it. Its *values* stay unchecked, because they are placeholders by
  design (`created: YYYY-MM-DD`, `id: ARC-DOM-NNN`). Measured cost of
  extending it this way: zero findings on all three vaults.
- **One grouped finding per file, not one per key.** A file with five
  stray keys must not produce five lines — the lesson of the aggregated
  link feedback in amendment 2026-07-27, where dozens of identical WARNs
  taught the reader to ignore the channel.
- **Every schema access is type-checked at the access, not once at
  load.** `check_dec_status` and `check_req_table` read nested keys; a
  schema declaring `"body_fields": 5` would otherwise reach a subscript
  on an int, raise `TypeError` and exit 2. Two accessors (`_dict`,
  `_strlist`) return an empty container for anything unexpected, so the
  worst a malformed schema can do is fall back.
- **`RecursionError`, not only `ValueError`.** Deeply nested JSON raises
  the former out of `json.loads`, and an `except (OSError, ValueError)`
  would not catch it — again exit 2, again both hooks failing open.
- **The fallback is minimal on purpose.** It is not a second copy of the
  schema; it is the answer to "check nothing or check the essentials",
  and it exists because validating nothing silently is the failure mode
  amendment 2026-07-28 was written about. A test asserts it agrees with
  the shipped schema on what is required and permitted.
- **A test forbids domain-exclusive fields.** The undeclared check is
  language-symmetric only while every named domain resolves to the same
  vocabulary as an unnamed one. Introducing a field that exists for `TAE`
  but not for a German `TUE` has to break that test first.

### Accepted residuals (documented, not solved)

1. **The relations are still declared and not read.** All eight kinds
   stay `declared-only`, `table_bindings` is unread, and no graph is
   built — so the query issue #4 opens with ("which decisions are
   superseded but still referenced from an active module") remains
   unanswerable. This is the boundary with issue #2, which says in its
   own text that without typed relations there is nothing to export: #4
   declares them, #2 reads them. The two consistency rules that need a
   parsed allocation table were reassigned to #2 accordingly.
2. **The table header signatures remain language-dependent and
   unverified**, as residuals 3 and 4 of amendment 2026-07-28b describe.
   A rule asserting that a vault's own tables still match the declared
   signature was considered here and deferred: while nothing extracts
   relations, such a rule would report that an extraction failed which
   does not exist, and on a vault in another language it would fire on
   every ARC file for being correctly written in that language.
3. **Obsidian's own block-sequence frontmatter is an ERROR.** The
   properties UI writes `tags:` followed by `  - hardware`, which
   `parse_frontmatter` rejects as malformed — so the editor-field
   tolerance introduced here covers only the inline spelling
   `tags: [hardware]`. Measured today: zero occurrences and zero
   malformed frontmatter across all three vaults, which is why it is a
   follow-up rather than a blocker. It is a latent trap, not a current
   defect.
4. **The check cannot see the files that need it most.** It runs only on
   well-formed, present frontmatter, so 231 of PMDE's 232 domain files
   are excluded by construction. They already report
   `frontmatter-missing`, so nothing is lost — but "zero undeclared
   findings on PMDE" is partly an artefact of that vault having almost
   no frontmatter at all.
5. **The identifier patterns are declared in the schema and enforced
   from Python.** A drift test compares them on a sample set, which
   catches divergence but does not prevent it.
6. **One schema for every vault.** A project needing different rules
   forks the skill. This is deliberate (see the rejected override), but
   it does mean the language residual the override was meant to address
   stays open.

### Follow-ups

7. Accept YAML block sequences in `parse_frontmatter`, closing residual 3.
   It is a parser change with its own blast radius — some files currently
   reported as malformed would start parsing — and belongs in its own
   change with its own measurement.
8. Reconsider requiring `id`, and merging the file and row identifier
   namespaces (residual 1 of amendment 2026-07-28c), once the vaults that
   predate the scheme have been migrated. Both are convention rollouts and
   must not ride along with a bug fix.

### Realization

- `validate_vault.py` — `SCHEMA_PATH`, `FALLBACK_SCHEMA`, `load_schema()`,
  `_dict()`/`_strlist()`, `Vault.schema()`/`fields_for()`/`editor_fields()`;
  `check_frontmatter()` rewritten schema-driven and split into
  `check_field_value()` and the new `check_undeclared()`;
  `check_dec_status()` and `check_req_table()` take the vault and read
  their value lists from the schema; `GENERIC_STATUS` and
  `DEC_BODY_STATUS` deleted, since the schema and the fallback now carry
  them
- `vault_schema.json` — schema 0.2: `enforcement_levels`,
  `domain_defaults`, `editor_fields`, the `superseded-by` relation, the
  `declared-fields-only` consistency rule, a rewritten `discovery` that
  records why the per-project override is not implemented, and per-entry
  reasons on every remaining `validator-internal` flag
- `tests/run.sh` — now 88 assertions. A fifth fixture exercises the schema
  itself by copying the validator next to a different schema file: an
  unreadable one (must WARN, must fall back, must not exit 2), one that
  declares the stray key (the finding disappears and the new value list is
  enforced, with byte-identical Python — the A/B proof of the whole
  change), and one that parses but declares nonsense (must not crash).
  Plus editor fields seeded in the precision fixture, which stays at zero
  findings; two stray keys and a template-borne one in the violation
  fixture; a stray key in both twins; and three drift guards (schema vs
  identifier constants, schema vs fallback, vocabulary symmetry)
- `SKILL.md` and `00_documentation_file_creation_and_conventions.md` — the
  schema as the place a field is declared, and the undeclared-field check

Measured after the change: the finding sets of the old and the new
validator are **byte-identical** on the template vault, homelab and PMDE,
compared against the same content at the same moment. Counts alone would
have been misleading here: homelab is a live vault under active work and
moved from 218/115 to 197/113 during this session without any validator
change, so the set comparison rather than the number is the evidence.
Template stays 0 errors / 9 warnings. Zero `frontmatter-undeclared`
findings on all three vaults, templates included. Full-audit runtime
0.08 → 0.08 s (template), 0.30 → 0.31 s (homelab), 0.22 → 0.21 s (PMDE).
`tests/run.sh` at 88 tests, 0 failures.

A note for whoever deploys this: the stop gate's per-session baseline in
`/tmp/claude-mechdocs` is keyed by finding code. No existing code was
renamed, and every code added here is a WARN, so the blocking set is
untouched and a stale baseline from before this change stays valid.

## Amendment 2026-07-28e — One definition of a project path in both zones (Accepted)

### Context

`check_paths` scans two zones with different rules. In the ordinary body
it considers only project-artifact-shaped tokens (`ARTIFACT_SEG_RE`, an
`NN_` first or second segment), strips inline code, honours a
`pending/planned/TBD` marker and reports WARN. Under an H2 whose name
contains `reference` or `source` it switches to a strict contract: every
path token is checked, fenced and backticked content included, no
suppression, severity ERROR.

The strict zone assumes that everything a note points at is an artifact
of this project, resolvable under `project_root`. A vault documenting a
distributed system breaks that assumption: its References sections
legitimately name `/etc/libvirt/network.conf` on one host,
`~/.config/hypr/monitors.conf` on another and
`/srv/services/backup/scripts/backup-srv.sh` on a third. None of them can
ever exist under `project_root`, and none of them is a stale pointer.

The check is dormant today only because both German production vaults
spell the headings `## Verweise` and `## Quelle(n)`, which contain
neither marker word — accepted residual 2 of amendment 2026-07-28. Any
vault adopting the English template inherits the whole set at once.

Measured on a structure-faithful copy of the homelab vault (288 files,
sibling folders symlinked so path resolution is identical to the
original; control: identical finding sets except `inb-age`, which
depends on mtime). Renaming `## Verweise` to `## References` and
`## Quelle(n)` to `## Source(s)` — nothing else — takes it from 178 to
356 errors, `path-missing` from 3 to 178. Classified with the
validator's own regex, those 178 are: 91 absolute paths, 35
`~`-relative, 4 remainders of URLs (`flathub.org/apps/...` out of
`https://...`), 37 foreign paths written relative (`services/create-playlist/...`
in a repository that lives on the server), and **11 genuine stale
pointers** — `20_Software/userver-scripts/...`, where the directory is
named `userver-services` today. The strict zone therefore does find real
defects, and no fix may cost those 11.

### Options

- **A — Skip a token whose preceding character is `/` or `~`.** The
  cheapest reading of the issue, and the one it proposes: `PATH_TOKEN_RE`
  cannot consume a leading `/` or `~`, so such a token is the tail of a
  larger path expression. Rejected on measurement. It silences far more
  than foreign paths: a Markdown link (`[schematic](10_hardware/13_PCB/x.sch)`)
  matches only from its second segment, which sits behind a `/`, so every
  Markdown-linked project artifact stops being checked; and a
  repo-anchored `/10_hardware/13_PCB/x.sch` is silenced by its leading
  slash alone. Both verified on a probe fixture. It also misses the
  foreign forms the vault actually contains — `omarchy:~/.config/Code - OSS/User/settings.json`
  (cut by a space, preceded by a space), `git@github.com:owner/repo.git`
  (preceded by a colon), `$HOME/.config/waybar/config.jsonc` — leaving 48
  of the 178 findings standing, 37 of them false. And it is a silent
  bypass: a leading `/` switches a blocking check off with nothing
  visible in the text, which is weaker than the deliberately *visible*
  `pending` marker of amendment 2026-07-27.
- **B — Apply the existing shape gate in both zones (chosen).** Delete
  the `not in_ref and` conjunct, so a token is checked only where it is
  shaped like a project artifact, in either zone. This is the first
  option the issue names ("the same treatment inside the strict zone as
  outside it"). It introduces no new concept, reuses `ARTIFACT_SEG_RE`,
  and makes no claim about absolute paths that this project's own corpus
  refutes — homelab references its *own* artifacts absolutely in several
  places, and all of them exist on disk.
- **C — An explicit foreign-path syntax in the vault** (`file://host/path`,
  RFC 8089, or a per-line marker). Formally the most honest, and it keeps
  the strict zone maximally strict. Rejected as a convention rollout over
  175 lines of a live vault, which this project has repeatedly split off
  from bug fixes (follow-up 4 of amendment 2026-07-28, option A1 of
  2026-07-28c). It stays available if the residuals below ever bite.

### Decision

Option B. One definition of a project path, used in both zones. The two
zones keep differing where the difference was decided on purpose:
severity (ERROR vs WARN), coverage of fenced and backticked content, and
the fact that `pending/planned/TBD` never silences the References/Sources
zone — the silent-bypass prevention of amendment 2026-07-27 stands
unchanged.

### Design points

- **The rule is about ownership, not about severity.** A path this
  project cannot own is not a pointer that went stale; it is a statement
  the validator has no way to check. Reporting it as a dead pointer is
  not a strictness setting, it is a wrong finding — which is why the
  answer is to skip it in both zones rather than to downgrade it to WARN
  in one.
- **Two forms reach the shape gate through a leading character the path
  regex cannot consume**, and both had to keep working: a Markdown link
  (`[schematic](10_hardware/13_PCB/x.sch)`), where `PATH_TOKEN_RE`'s
  `(?<![\w(])` blocks the first segment and the match starts at the
  second, behind a slash; and a repo-anchored `/10_hardware/13_PCB/x.sch`.
  Under option A both went silent. They are now positive controls in the
  violation fixture, because "fix the false positives by switching the
  zone off" is the failure mode this change is one step away from.
- **The fixtures carry the forms the production vaults actually
  contain**, not the forms the implementation happens to catch: a host
  path, a home path, a host-qualified path containing a space
  (`labhost:~/.config/Code - OSS/User/settings.json`, which the token
  regex cuts at the space), a git remote and an env-rooted `$HOME/...`
  path. Written into the *precision* vault, so the zero-findings
  assertion is what proves them silent — a pattern that cannot rot into
  a test that matches nothing.
- **The measurement that counts is the renamed copy.** Both German
  production vaults spell the headings `## Verweise` and `## Quelle(n)`,
  so the References/Sources zone never runs there (residual 2 of
  amendment 2026-07-28) and the template vault has no `path-missing`
  finding at all. "Finding sets identical before and after" on those
  three corpora proves the absence of regressions *outside* the zone and
  nothing whatsoever about the zone being changed.

### Accepted residuals (documented, not solved)

1. **A project file whose path carries no `NN_` segment is no longer
   checked in References.** `.github/workflows/ci.yml` inside this
   repository is the realistic case. Measured cost on all three corpora:
   zero lost true positives. This is the precision-over-recall trade of
   the body scan (residual of amendment 2026-07-27), now extended to the
   strict zone — which is exactly what the change decides.
2. **A project artifact referenced by an absolute path loses its
   staleness check.** homelab does this in several places
   (`~/Documents/innovation/homelab/20_Software/omarchy-system/...`, all
   of them present on disk), where the same pointers are today reported
   as dead with a wrong message. The conventions file now states the
   consequence and asks for the relative form; nothing enforces it.
3. **37 foreign paths written relative stay ERROR in the renamed
   corpus** — `services/create-playlist/systemd/create-playlist.service`
   and its kin, rooted at `/srv/` on the server. They are mechanically
   indistinguishable from a project path, so no validator rule can
   separate them. The conventions rule ("write a foreign path the way its
   machine addresses it") converts them into an authoring fix, and their
   number is measured rather than estimated.
4. **The heading names stay hardcoded English substrings.** `reference`
   and `source` still gate the zone, so the whole strict contract remains
   dark in a vault written in another language. Unchanged by this
   amendment; still follow-up 5 of amendment 2026-07-28.

### Realization

- `validate_vault.py` — `check_paths` applies the `ARTIFACT_SEG_RE`
  shape gate in both zones (the `not in_ref and` conjunct is gone);
  docstring and the `ARTIFACT_SEG_RE` comment restated in terms of what
  the project can own
- `tests/run.sh` — now 91 assertions: five foreign forms in the precision
  vault's IMP References section, guarded by its zero-findings
  assertion; a Markdown-linked and a repo-anchored dead project path in
  the violation vault that must stay ERROR; and an explicit negative
  that a foreign host path in References produces no finding
- `SKILL.md` — cross-linking rule 4 states that only the relative form is
  checked, and that writing a project artifact absolutely switches its
  check off
- `00_documentation_file_creation_and_conventions.md` — new section
  "Paths and artifacts on other machines": the relative form for project
  artifacts, the host-qualified form for foreign ones with RFC 8089 as
  the formal spelling, and the statement that the validator does not
  resolve those, so the claim rests on the author and on `last-verified`

Measured after the change: template vault unchanged at 0 errors /
9 warnings; homelab and PMDE finding sets **identical** to the
pre-change validator at the same moment (178/112 and 414/96 — counts
alone would mislead here, homelab is under active work). On the
structure-faithful homelab copy with English headings: 356 → 189 errors,
`path-missing` 178 → 11, and the surviving 11 are the genuine stale
pointers `20_Software/userver-scripts/...`, whose directory is named
`userver-services` today. `tests/run.sh` at 91 tests, 0 failures.

The stop gate's per-session baseline in `/tmp/claude-mechdocs` is keyed
by finding code. No code was renamed or added, and the blocking set only
shrinks, so a stale baseline from before this change stays valid.

## Amendment 2026-07-28f — Records, not copies: fenced blocks whose source is not a file here (Accepted)

### Context

`check_leaks` reported every fenced block in `IMP` or `ARC` as an ERROR.
The rule it enforces is stated three times in the method — `SKILL.md`
rule 4, the content-boundary table, and `00_IMP_README.md` — and it
protects a real, measured property: 28.9 % of the 1000 most popular
GitHub projects carry at least one outdated code reference in their
documentation (arXiv 2307.04291), most of 3000+ projects do at some
point in their history (arXiv 2212.01479), and inconsistent code/comment
changes are ~1.5× more likely to lead to a bug-introducing commit
(arXiv 2409.10781). A copied snippet drifts against its original; a path
cannot.

The rule was written for a project whose artifacts are files in the same
repository — `00_IMP_README.md` illustrates it with `Messplatine.kicad_sch`
and `Gehäuse.step`. A vault documenting a distributed system has
artifacts that are not files here and never will be. Measured on the
homelab vault: 185 fenced blocks in 43 `IMP` notes and one `ARC` note,
1282 content lines, most of them a single operator command against a
host under a comment saying what it establishes or proves, plus
directory trees and command output — the state of a filesystem on
another machine. About five are genuine excerpts from a script.

For those the rule has no destination, so every route out of it costs
something: pointing at a source file works only where one exists;
moving the command to `OAU` splits one fact from its proof; indenting by
four spaces or converting to inline code renders identically and evades
the rule while remaining a copy; deleting removes the operational
knowledge the vault exists to hold. The downstream vault decided this
locally (`ENT_IMP_Betriebskommandos`, Accepted 2026-07-28, option C)
with an explicit clause to re-evaluate if this repository decided
otherwise. It now has.

This is the content half of the assumption whose path half was amendment
2026-07-28e: that everything a note refers to is an artifact of this
project, resolvable under `project_root`.

### Options

- **A — Lift the ban in `IMP`, keep it in `ARC`.** Cheapest. Rejected:
  it discards the measured property outright and legalises exactly the
  five genuine script excerpts, which are the blocks that can actually
  drift.
- **B — A declared exemption alone** (`host=<machine>` on any block,
  the ban otherwise unchanged). Rejected after an adversarial review
  measured what it would do to the corpus: appending the attribute is
  the cheapest possible response to every one of the 127 remaining
  ERRORs, so the first users of the exemption would be the copies —
  `IMP_userver_YT-DLP_Del_Script.md:40`, 23 lines of CLI against a
  script named two sections above it, is the concrete case. An exemption
  that is the path of least resistance for everyone documents nothing.
- **C — Length decides whether the question is asked, a declaration
  answers it (chosen).** Up to `FENCE_RECORD_MAX` content lines a block
  is a single observation and is silent. Above it, the block either
  gives way to a path (ERROR `code-fence`) or names the machine it is
  true on (WARN `fence-record`). Length is the only signal correlating
  with drift risk that costs the author nothing, and it makes the
  declaration rare enough to be conspicuous: 9 blocks vault-wide rather
  than 127.
- **D — A tenth domain owning operator records.** Rejected: a convention
  rollout across two production vaults, and every authoritative
  definition of a runbook (AWS Well-Architected "a series of steps … to
  achieve a specific outcome", Google SRE's per-alert playbook, Azure
  WAF, PagerDuty) makes a single command not a procedure. Google's own
  style guide states that a one-step procedure is not formatted as a
  procedure at all.

### Decision

Option C. The ban is expressed as drift against a named source rather
than as a syntax ban on fences, and a block whose subject is a machine
this project does not own is classified as a **record**, not a copy —
ISO 9000:2015 3.8.10, "document stating results achieved or providing
evidence of activities performed", whose Note 2 states that records
"generally need not be under revision control". The same artifact class
appears as *report* in ISO/IEC/IEEE 15289 ("describes the results of …
investigations, observations, assessments, or tests"), as *snapshot* in
ITIL ("the current state of a configuration item … recorded at a
specific point in time"), and as *observation* in NIST OSCAL, which
makes its `collected` timestamp mandatory.

`OAU` keeps procedures and gains nothing here: a repeatable multi-step
workflow is a runbook, a single verification command is not, and Red
Hat's modular-documentation standard states the carve-out this needs
verbatim — a reference module may carry an action when it is "simple,
are highly dependent on the context of the module, and have no place in
any procedure module".

### Design points

- **The threshold is measured, not chosen.** The smallest genuine script
  excerpt across both German production vaults has 16 content lines, so
  15 is the largest value that still catches every measured copy. At
  that value homelab's `code-fence` count goes 127 → 9 and PMDE's
  17 → 7; the nine survivors are the four real copies plus five
  directory trees between 17 and 77 lines, which are exactly the case
  where a declaration carries information instead of being routine.
- **The exemption is a WARN, never silence.** This project's rule is
  that a visible marker may soften a WARN and never an ERROR
  (`status: draft` relaxes nothing; `pending/planned/TBD` never silences
  the References zone). `fence-record` keeps the claim visible,
  greppable and countable. It is not an ERROR because the check cannot
  distinguish a legitimate record from a disguised copy, which is
  Clippy's stated disqualification for its deny-by-default `correctness`
  group ("should be free of false positives") and Google Tricorder's for
  a blocking check ("produce no effective false positives").
- **The declaration is read at any token position.** 23 of 127 blocks in
  homelab and 14 of 17 in PMDE carry no language at all, so "language
  first, host second" would have had no spelling for 18 % and 82 % of
  the two corpora.
- **The info string is the spec-sanctioned place.** CommonMark 0.31.2:
  the first word is typically the language, but "this spec does not
  mandate any particular treatment of the info string"; GFM discards
  further tokens and keeps the language class (spec example 113), and
  Obsidian registers code-block processors on the first word alone.
  Pandoc's braced form was rejected because `{bash}` costs syntax
  highlighting in Obsidian, which is the rendering target here.
  Verified: neither vault has any community plugin installed, so the
  plugins that parse `=` as their own parameter separator are absent.
- **Two cheaper ways out closed with it.** A tilde fence was invisible to
  every fence-keyed rule — and worse, `check_links` and `check_paths`
  then read the block's content as prose, producing two WRONG findings
  per block. An unclosed fence silenced everything below it. Both are
  now handled through one `fence_info()` definition shared by all three
  checks. Measured cost: zero tilde fences exist in either vault.
- **`check_paths` reads the declaration.** In the References zone fenced
  content is scanned and no marker suppresses anything; a declared block
  containing `deploy/20_software/...` was therefore reported as a stale
  project pointer. It is now skipped there, which is the ownership rule
  of amendment 2026-07-28e — reachable for the first time because the
  block says so instead of the validator guessing.
- **The baseline argument, stated correctly.** `hook_post` computes the
  per-file baseline at runtime from `git show HEAD:<file>` with the
  *current* validator, so a new code can perfectly well appear in a
  baseline. A stale session baseline still stays valid here for a
  different reason: the `host=` syntax cannot occur in any HEAD revision
  written before this change, and `code-fence` only ever shrinks.

### Accepted residuals (documented, not solved)

1. **Nothing verifies that a declared block truly has no source file.**
   The declaration is an author's claim; the validator can see neither
   the other machine nor the absence of a local original. This is
   follow-up 2 of the 2026-07-25 decision (doc-claim grep check), and it
   is why the exemption reports rather than stays silent.
2. **The machine name is validated against nothing.** Ruff's split is
   the model — RUF100 stays permissive while RUF102 checks codes against
   a declared registry, and Ansible reports an uninventoried host as a
   warning by default — but a host list is per project, and amendment
   2026-07-28d rejected the per-project schema override as a silent
   off-switch. There is no home for the registry yet; see follow-up 9.
3. **A copy short enough stays silent.** A 10-line excerpt of a file in
   `20_software/` produces no finding. Precision over recall, the same
   trade as the body path scan of amendment 2026-07-27.
4. **The four-space indented block still evades every fence rule.**
   Closing it would mean judging every indented line inside every list,
   which is a false-positive surface this project has consistently
   refused. It remains the bypass named in the 2026-07-25 residuals.
5. **`last-verified` is only a lower bound for a block's age.** With N
   records under one date, that date says when the note was confirmed,
   not when each observation was made. A per-block `captured=` was
   considered and rejected: no surveyed documentation system stamps a
   block with a date, and every freshness convention that exists
   (Microsoft `ms.date`, Google g3doc `reviewed:`, Kubernetes
   `evergreen`) keeps exactly one dated place per document. OSCAL's
   split — mandatory `collected`, optional `expires` — is the model if
   it is ever needed.
6. **`host="lab host"` is cut at the space** and yields `"lab`. Accepted
   rather than parsed: machine names do not contain spaces, and the
   value is reported in the finding, so the mistake is visible.
7. **Case-sensitive.** `HOST=` is not recognised, consistently, like the
   identifier reader of amendment 2026-07-28c.
8. **This partially adopts option C of amendment 2026-07-28e** (an
   explicit foreign-artifact syntax in the vault), for fenced blocks
   only. The 37 foreign paths written relative, residual 3 there, stay
   exactly as they were: they carry no fence and no declaration.

### Follow-ups

9. Validate the declared machine name against an inventory once a
   per-project registry has a home that is not the packaged schema —
   most likely the vault documenting its own hosts. Prior art for the
   shape: a separate, independently switchable rule (Ruff RUF102),
   warning severity (Ansible `HOST_PATTERN_MISMATCH`), and an empty
   registry meaning "passes" (commitlint `scope-enum`).
10. Re-measure the threshold when the German vaults have finished their
    fence work. It is calibrated on a corpus that is being actively
    restructured, and the smallest genuine excerpt may move.

### Realization

- `validate_vault.py` — `FENCE_RE`, `FENCE_HOST_RE`, `FENCE_RECORD_MAX`,
  `FENCE_BANNED_DOMAINS`, `FENCE_EXEMPT_DOMAINS`, `fence_info()`,
  `fence_host()`, new `check_fence()`; `check_leaks` restructured to
  measure a block instead of reporting its opening line, and to evaluate
  an unclosed fence to EOF; `check_links` and `check_paths` share the
  one fence definition, and `check_paths` skips a declared block in the
  References zone
- `tests/run.sh` — now 101 assertions: the precision vault gains an IMP
  note whose artifacts live on another machine (its zero-findings
  assertion is what proves both the silence of short blocks and the
  References-zone skip); the violation vault gains a long bare block, an
  empty `host=`, a declared long block with the file-scoped negative
  that it produces no `code-fence`, a tilde fence, an unclosed fence,
  and a second, declared fence in `ARC_Leaky.md` that must still fail
- `vault_schema.json` — `code_fences` with the domain lists, the
  threshold and its provenance, the declaration form and its spec
  basis, the three codes with their severities, and what stays
  unenforced
- `SKILL.md` rule 4 and the content-boundary table,
  `00_IMP_README.md` (new section "Artifacts on Other Machines"),
  `00_documentation_file_creation_and_conventions.md` (the content half
  beside the path half)

Measured after the change, old vs new validator in the same run pair:
template vault unchanged at 0 errors / 9 warnings; homelab 127 → 9
errors with all 112 warnings and every other finding code identical;
PMDE 414 → 404 errors, `code-fence` 17 → 7, warnings unchanged at 96.
`code-fence` is the only code that moves anywhere. `tests/run.sh` at
101 tests, 0 failures.

## Amendment 2026-07-31 — A near miss is not an absence (Accepted)

### Context

`check_sections` derived the required H2 set from the domain template and
reported `template_h2 - file_h2`: a difference of two sets of raw strings,
compared exactly, without positions. A heading a reader would call the
required section but that differs by one byte therefore landed in the
missing set and was reported with the same code, the same message shape and
the same severity as a section nobody ever wrote — and the message named
only the template's spelling. Resolving it meant diffing two heading sets by
hand, at the one place that already held both.

Two questions were conflated, and only one of them is policy. Whether exact
matching is right is defensible either way. Whether the diagnosis is usable
is not: naming a string the author cannot find in their own file is a
missing sentence, not a consequence of strictness. The second question
stands whatever the first one answers (issue #10).

Measured across all six vaults on this machine at the same moment: template
vault, homelab, verdantia and htwsaar carry no `template-sections` finding
at all; PMDE carries 112 affected files naming 241 headings, of which **6
are case-only** (`allgemeine Übersicht` in the template against
`Allgemeine Übersicht` in six `KMP` files) and 235 are genuine; and
realitypatches carries 3, of which **1 is a qualifier**
(`Konsequenzen` against `Konsequenzen / Offene Risiken`). The issue's own
figures — 45 files, 64 headings, 27 % near misses — were measured on
homelab before its English migration and no longer reproduce; PMDE is the
corpus that carries the case class today. The blast radius is small and
measured, which puts this in the bug-fix class rather than the convention-
rollout class this project keeps separating out.

### Options

**Is case part of the contract?**

- **A1 — yes, keep exact matching and only improve the message.**
  Rejected. markdownlint's `MD043`, the most widely deployed required-
  headings rule there is, matches case-insensitively **by default** and
  makes `match_case: true` opt-in, explicitly to avoid breaking existing
  documents. The prostep ivip ReqIF Implementation Guide V1.8 §2.3 states
  the same asymmetry for attribute names: export case-sensitive, but "a
  ReqIF importing tool SHOULD be forgiving when the attribute name is not
  case-sensitive". rustc, Cargo and CPython all treat a case-only
  difference as privileged — rustc short-circuits on a case-insensitive
  exact match *before* any edit-distance math. And blocking on it is a
  convention rollout in disguise: 6 of PMDE's 241 findings, every one of
  them a section that demonstrably exists.
- **A2 — case-insensitive, but the drift stays visible (chosen).** The
  requirement counts as met and a WARN names both spellings, so the
  template's own spelling stays the thing a reader and a search find.

**Is a qualifier part of the contract?**

- **B1 — treat every near miss as met, report a WARN, block on nothing.**
  This is what the adversarial review of this change preferred, and it is
  genuinely simpler: no ERROR moves anywhere, and the issue itself calls
  exact matching for qualifiers "defensible either way". Rejected on one
  concrete consequence: amendment 2026-07-28b binds relations to
  template-declared sections (option E, the documented fallback for a vault
  whose schema signature does not match), so a retitled section silently
  drops out of that binding — the failure is invisible exactly where the
  vault is machine-read. Severity here also follows *certainty*, Clippy's
  criterion for its deny-by-default group: a title the template does not
  carry is a certain deviation, not a guess about intent. Measured blocking
  cost: one file across six vaults.
- **B2 — a qualifier leaves the requirement unmet, but the message becomes
  usable (chosen).** `## Ablauf (Monatlich empfohlen)` is a differently
  scoped section; it should be `## Ablauf` with the qualifier on an `###`
  below. The finding now says so, at the line the heading sits on.

**How is "similar" decided?**

- **C1 — edit distance,** as rustc, Clang and CPython use it, all three
  bounded at about one third of the queried name's length. Rejected: a
  required heading is a *declared* string, not a guess at what the author
  meant, so the whole problem those tools solve — ranking candidates from
  an open vocabulary — does not exist here. Distance would invent
  relationships the corpus does not contain (`Kontext` and `Konzept` are
  two edits apart) and would need a tie policy, which is the documented
  nondeterminism trap in CPython and TypeScript.
- **C2 — one heading extends the other at a word boundary (chosen),** in
  both directions. It covers the two forms the corpora actually contain and
  has no ranking, no threshold and no ties by construction.

### Decision

A2, B2, C2. Three outcomes replace two: met and silent, met and reported
(`section-near-miss`, WARN), unmet and reported with both spellings
(`section-mismatch`, ERROR). `template-sections` keeps its code, its
severity and its one-per-file shape, and now names only sections that were
genuinely never written.

### Design points

- **Two levels of comparison, because they answer different questions.**
  `strict_key` removes what the author cannot see — NFC vs NFD spelling of
  an umlaut (macOS hands out NFD, Linux NFC), zero-width characters,
  collapsed whitespace — and two headings differing only there are the same
  heading and stay silent; reporting that would be a finding nobody can
  act on. `fold_key` additionally applies Unicode default case folding
  (Unicode 15.0 §3.13 D144, which `str.casefold` implements), and
  normalises again afterwards, as D145 asks: `casefold('İ')` yields `i`
  plus a combining dot.
- **Folding is not lowercasing, and the message does not pretend it is.**
  `casefold` maps `ß` to `ss`, so `Maßnahmen` and `Massnahmen` fold equal.
  Both spellings are therefore quoted verbatim in every message instead of
  a claim that only the case differs.
- **One grouped finding per file per class.** The lesson of the aggregated
  link feedback in amendment 2026-07-27, and here it carries a second
  weight: `hook_stop` compares per-code counts against the HEAD baseline,
  so a per-heading finding would let a file that *improved* — one absence
  replaced by a qualifier heading — produce more findings of one code than
  its baseline and block the gate for it.
- **Nothing depends on set order.** `extract_h2` returns a set, so which of
  two headings extending one requirement got named used to depend on the
  hash seed. Required headings are iterated sorted, file headings keep
  their first occurrence, candidates are ordered by line, and the finding
  is anchored at the smallest line it names. A test runs the validator
  under two hash seeds and compares.
- **An empty required heading requires nothing.** `extract_h2` keeps `""`
  for a bare `## ` line and `templates_for` filters empty *sets*, not empty
  members — and `fold_key("")` is a prefix of everything, so one stray
  `## ` in a template would have produced a mismatch against the first
  heading of every file of that domain.
- **The new ERROR code is safe against the ratchet.** `hook_post` computes
  the per-file baseline at runtime from `git show HEAD:<file>` with the
  *running* validator, as amendment 2026-07-28f already recorded, so
  `section-mismatch` appears in baseline and current run alike and a
  pre-existing one never blocks. The git-backed fixture asserts it rather
  than the reasoning being trusted.
- **The near-miss count goes in the CLI summary only.** The findings
  themselves already reach `hook_post` and `hook_stop` through the normal
  channels; a second counting mechanism in the hooks would be plumbing
  without a reader.

### Accepted residuals (documented, not solved)

1. **A required section written at the wrong level is still an absence.**
   `### Kontext` where the template declares `## Kontext` produces exactly
   the diagnosis this amendment set out to remove. Measured 0 occurrences
   across all six vaults, and fixing it means deciding whether the level is
   part of a section's identity — markdownlint folds the `#` prefix into
   the compared string, contextlint ignores the level entirely, and neither
   documents the choice. Owed to a follow-up that states the answer.
2. **Heading extraction is fence-blind.** A `## Context` line inside a
   fenced block counts as a heading, which is pre-existing behaviour — but
   the new line anchors can now point *into* a code block. Measured 0
   occurrences.
3. **Case folding collapses more than case**, `ß`/`ss` being the German
   case. The near-miss class is therefore slightly wider than "same
   heading, different case"; the verbatim spellings in the message are what
   keeps it honest.
4. **A file nobody edited can change its message.** Because case misses no
   longer count as unmet, a different template can win the "fewest unmet"
   contest, changing the named closest template and the listed absences.
   Live on the six PMDE `KMP` files.
5. **The error count can rise while the defect count falls.** One grouped
   finding listing two headings becomes one grouped finding plus one
   mismatch finding, which is what takes realitypatches from 12 to 13
   errors without a single new defect.

### Realization

- `validate_vault.py` — `NEAR_MISS_CODES`, `ZERO_WIDTH`, `BOUNDARY_RE`,
  `h2_index()`, `strict_key()`, `fold_key()`, `prefix_related()`,
  `classify_sections()`, `render_headings()`; `check_sections` rewritten
  around the three outcomes and the unmet-first template score;
  `main()` prints the near-miss count. `extract_h2` is untouched — it still
  serves the template side, where positions are meaningless
- `tests/run.sh` — now 119 assertions: a case-only fixture (WARN, and the
  explicit negative that it is not reported as missing), a qualifier
  fixture with two extensions of one requirement, the reverse direction
  where the file's title is the shorter one, a longer-word negative
  control, a hash-seed determinism check, a sixth fixture whose template
  declares two required headings that are prefixes of each other, the
  summary-count assertion, and a git-backed assertion that a pre-existing
  `section-mismatch` does not block the stop gate
- `SKILL.md` and `00_documentation_file_creation_and_conventions.md` — the
  authoring side: the template's spelling is the contract, a qualifier
  belongs on an `###` below

Measured after the change, old vs new validator against the same content at
the same moment: the finding sets are **identical on all six vaults except
where the two new classes apply**. Template vault unchanged at 0 errors /
9 warnings, homelab, verdantia and htwsaar byte-identical, PMDE 404 → 398
errors and 96 → 102 warnings (the six case findings changing severity and
nothing else), realitypatches 12 → 13 errors as residual 5 describes.
`tests/run.sh` at 119 tests, 0 failures.

A note for whoever deploys this: the stop gate's per-session baseline in
`/tmp/claude-mechdocs` is keyed by finding code and recomputed from HEAD by
the running validator, so a session started after the swap is unaffected. A
session already in flight keeps a baseline computed by the old code, where
`section-mismatch` has no entry and a pre-existing one would count as
introduced. Baselines expire after 7 days; deleting the directory makes it
immediate.

## Amendment 2026-07-31b — Reading the vault as a graph (Accepted)

### Context

The vault is readable in Obsidian or as raw Markdown and nowhere else.
Amendment 2026-07-28b declared seven relation kinds with their reverse
keys and left every one of them `declared-only`; amendment 2026-07-28d
made the field vocabulary schema-driven but not the relations. Issue #2
asks for the artifact that turns those declarations into something a
reviewer, an examiner or an auditor can be handed: a requirement-to-
evidence matrix in both directions, with what is unproven stated rather
than left to be noticed.

Two of this file's own residuals decide most of the design. Residual 3
of 2026-07-28b — a vault in another language finds no relation table and
produces an empty graph without an error — is not a theoretical risk:
measured on this machine, no production vault matches any declared
header signature, none carries a single `id:`, and `Vault.req_index()`
returns zero rows on homelab because it asks for the folder abbreviation
`REQ`. Residual 4 — reformatting a header row silently removes every
relation it carried — is live: homelab's ARC template writes
`Verifikation (TUE)` and six of its fourteen ARC files write
`Verifikation (TST)`.

### Options

**Which invariant carries the binding.**

- **A — the declared header signature.** What `table_bindings` states
  today. Rejected on measurement: nothing enforces a header row, and the
  drift is already there. A recognizer keyed on the header accepts 8 of
  homelab's 14 ARC files and 73 of its 148 allocation rows.
- **B — the folder number.** Language-independent by construction and
  identical across all seven vaults on this machine. Rejected as the
  primary mechanism: it invents a second vocabulary next to the
  abbreviations the schema already enumerates, and follow-up 4 of
  amendment 2026-07-28 has already decided the explicit alias map.
- **C — the template-declared section position (chosen).** The project's
  own `00_*template*` file names the section, `check_sections` enforces
  that every file of the domain carries it as a blocking ERROR, and
  `Vault.templates_for` already reads it. Measured: the section title is
  present in 14 of 14 homelab ARC files, so the binding recovers 148 of
  148 allocation rows. This is the mechanism `table_bindings` already
  records as the documented fallback; the amendment promotes it to the
  primary one and keeps the header signature as corroboration.

**How domains are recognised across languages.**

- **D — alias map plus a requirement-ID prefix taken from the vault's own
  requirements domain (chosen).** Exactly follow-up 4 of amendment
  2026-07-28, unbundled from the convention rollout that blocked it
  there, because the exporter reports and never blocks.
- **E — infer the role from the folder number.** See option B.

**How much the exporter is allowed to interpret.**

- **F — normalise into a clean model.** Rejected: real allocation rows
  carry ranges (`ANF-NAV-001 bis ANF-NAV-009`), number continuations
  (`ANF-BAK-008, 027, 028`), prose subjects (115 of 148 homelab rows),
  prose verifications (21 rows), and 17 distinct status values the
  schema does not declare. Silently mapping those onto the declared
  vocabulary is how an export starts lying in the direction that flatters
  the project.
- **G — expand only what can be checked, report the rest (chosen).** A
  range or continuation is expanded only when every identifier it yields
  exists in the requirement index; anything else becomes a named finding.
  A status counts as proven only on an exact match against the declared
  value, a status carrying a qualifier is reported with its verbatim
  text as the reason, and every unrecognised construct is a row in the
  export rather than an absence from it.

### Decision

C, D and G. The exporter ships as `export_traceability.py` beside the
validator, imports from it and is never imported by it, and does not
modify it. It writes JSON, CSV and a self-contained HTML report into a
directory the caller names, refuses to write inside a vault, and derives
every reverse edge instead of reading one.

The two consistency rules that amendment 2026-07-28b reassigned to this
issue are reported by the export and enforced by nothing: measured,
`verified-needs-evidence` fires on 21 legitimate homelab rows whose
verification is prose, which is the false-positive rate this project
refuses in a blocking check.

CSV values are written verbatim. OWASP's own CSV-injection page states
that the commonly suggested mitigations "may fail" because "Microsoft
Excel may remove quotes or escape characters from CSV cells when a file
is saved and re-opened", so a prefix character would trade a documented
record for an undocumented one and still not close the hole. The risk is
named in the README and in the export's provenance block instead.

### Design points

- **Proven means what this vault already meant by it.** The ARC README lets
  an allocation reach `Verified` only once a verification link exists and
  its evidence is written down, so that is the rule the export applies.
  Making the `verifies` frontmatter decide instead would report every
  homelab requirement as unproven, because that vault's 39 evidence notes
  all carry an empty list - a convention it never adopted. The
  disagreement is not swallowed either: it is an open question on a
  requirement that is otherwise proven, which is the compliance-plus-
  close-out shape ECSS-E-ST-10-02C asks for.
- **The column count is part of the section match.** PMDE's main-module
  template heads its two-column submodule table with the same title its
  file template gives the four-column allocation table. Binding on the
  title alone fed a submodule row to the allocation parser and produced
  allocations with no requirement.
- **The exporter carries its own parsing primitives.** A fence tracker
  that keeps character and length, a cell splitter that honours the GFM
  escape rule, BOM-safe reading, NFC keys. The validator's equivalents are
  wrong in ways that are harmless there and would not be here: reproduced,
  a requirement table quoted inside a ```markdown block yields three
  findings from `check_req_table`, and a BOM makes `parse_frontmatter`
  return `(None, 0, None)` - the frontmatter of the whole file disappears
  without a message. Fixing them is a change to the blocking layer with
  its own blast radius and belongs in its own issue.
- **CSV values are not mutated.** OWASP's CSV-injection page states that
  the usual prefixes "may fail" because Excel removes quotes and escape
  characters across a save and reopen. A prefix would corrupt the record
  and still not close the hole, so the export stays verbatim and the
  provenance block says so.
- **Two runs, one diff.** Determinism is asserted as the property, in the
  test suite and in CI, not approximated by suppressing a timestamp. The
  comparison uses the same output directory twice, because the provenance
  block records the command line and two directories differ there
  truthfully.

### Accepted residuals (documented, not solved)

1. **The exporter and the validator disagree about how many requirement
   rows a vault has.** The exporter skips fenced blocks and the validator
   does not. The numbers differ only where a vault quotes a requirement
   table as documentation; the fix belongs to the validator.
2. **A language the alias map does not know still exports an empty graph** -
   loudly now (`export-unknown-domain`) rather than silently, but empty.
   Adding a language is an edit to `domain_aliases`.
3. **The status vocabulary is English in every vault measured**, and the
   exporter relies on that. A vault that translates `Verified` would have
   every allocation read as unknown, reported per row but not understood.
4. **`contains` and `test-object` are empty on every production vault**,
   because both rest on annotated links and no production vault carries a
   single `id:`. The mechanism is exercised only by the template vault and
   the test fixtures.
   _Corrected 2026-08-05 (amendment 2026-08-05d): both halves were wrong.
   Measured on the template vault, `contains` and `test-object` were zero
   there too — `test-object` was never implemented, and only the submodule
   table half of `contains` was, which the template vault does not use. The
   fixtures exercised the table half alone. Both now have a working source,
   and an unannotated link that could have been a relation is reported
   rather than left to make the graph quietly short._
5. **The HTML report has no pagination.** It is one document; the largest
   vault measured produces 84 requirement rows, and the design point at
   which that becomes a problem has not been reached or looked for.

### Realization

- `export_traceability.py` — the exporter: `resolve_roles`,
  `discover_bindings`, `bound_tables`, `expand_requirement_cell`,
  `build_graph`, `reverse_index`, `assess`, and the three writers, plus
  its own `read_lines`, `fenced_mask`, `split_cells` and `safe_href`
- `vault_schema.json` — schema 0.2 to 0.3: `domain_aliases` with the
  requirement-ID prefix rule, `binding_discovery` and `status_token` under
  `table_bindings`, `arc_main_module_table`, `qualifier_proven_value`, the
  `export-driven` enforcement level, and six relations plus both
  consistency rules moved from `declared-only` to it
- `tests/run.sh` — fixture 7, a vault carrying a range, a number
  continuation, a prose subject, a qualified status, an identifier that
  exists nowhere, a table quoted in a code fence, an escaped pipe, a
  script tag and a spreadsheet formula, built twice in two languages and
  asserted to export the same graph; 119 to 144 assertions
- `.github/workflows/validate-vault.yml` — the determinism assertion
- `README.md`, `STRUCTURE.md`, `SKILL.md`,
  `00_documentation_file_creation_and_conventions.md`,
  `02_documents/README.md` — what the export is, where it may be written,
  and why the section title is the address a relation table is found by

Measured after the change, all seven vaults on this machine at the same
moment:

| vault | requirements | proven | relations | findings |
| --- | --- | --- | --- | --- |
| template | 3 | 3 | 14 | 0 |
| homelab | 84 | 53 | 260 | 110 |
| PMDE | 93 | 0 | 150 | 18 |
| realitypatches | 0 | 0 | 0 | 0 |
| htwsaar | 0 | 0 | 0 | 1 |
| verdantia | 0 | 0 | 0 | 1 |
| photon | 0 | 0 | 0 | 0 |

PMDE's zero is correct: no allocation row in that vault has ever reached
`Verified`. The single finding on htwsaar and verdantia is the same one -
neither ships a main-module template, so that binding has no section to
resolve. homelab's 110 findings are dominated by 69 requirement
identifiers referenced in allocation tables that no requirement row
defines, which is a defect in that vault and the first thing its export
now says out loud.

The template vault is unchanged at 0 errors and 9 warnings, and
`tests/run.sh` runs 144 assertions with 0 failures.

## Amendment 2026-08-01 — One fence definition for both tools (Accepted)

### Context

Issue #20. `check_req_table` iterated every line of a REQ file and called
`parse_table_row` on it with nothing tracking fence state, so a
requirement table quoted inside a ```` ```markdown ```` block — the
ordinary way to show a reader what a malformed row looks like — was read
as data. Reproduced on a REQ file documenting its own table format: three
blocking ERRORs about the quoted row, and a fourth, `req-duplicate`,
blaming the real requirement below it for colliding with the quotation.

Two more readers count requirement rows the same way, which the issue did
not name: `Vault.req_index`, whose result decides `verifies-unknown-req`
and `req-uncovered`, and the global duplicate scan in
`validate_vault_wide`. Measured on the same file, the index resolved
`REQ-DOC-001` to the line inside the fence rather than to the real row,
so a quoted example could satisfy a TAE `verifies:` entry and mask a
genuine ERROR.

This is residual 1 of amendment 2026-07-31b — the exporter and the
validator disagreeing about how many requirement rows a vault has —
observed from the other side.

### Options

**Which fence definition the requirement-row readers use.**

- **A — the toggle `fence_info` already provided.** What issue #20 asks
  for literally, and cheap. Rejected on measurement: it moves the
  boundary on a four-backtick block and on a ` ``` ` inside a `~~~`
  block, which are exactly the shapes a file documenting fenced content
  contains. This repository's own conventions file carries the first one,
  so the fix would have failed on the corpus it ships with.
- **B — a second, CommonMark-correct tracker local to the requirement
  readers.** Rejected: two definitions inside one tool is the defect
  being fixed, restated one level down.
- **C — the exporter's rule as the one primitive every check uses
  (chosen).** `export_traceability.fenced_mask` already implements
  CommonMark 0.31.2 correctly. Promoting it makes "no two checks can
  disagree about where a block starts" true across both tools rather
  than within one, which is the only reading under which residual 1
  closes.

**How much of the validator changes.**

- **D — `check_req_table` alone**, the issue's literal deliverable.
  Rejected on measurement: it removes the four findings and leaves the
  index pointing into a fenced block.
- **E — every place a requirement row is counted (chosen).** One reader,
  `req_rows`, for `check_req_table`, `Vault.req_index` and the global
  duplicate scan.

**What an unclosed fence means for a requirement table.**

- **F — treat the block as running to EOF and drop the rows**, which is
  what the mask says. Rejected, and measured before rejecting: three
  backticks anywhere above a table then buy unconditional exemption from
  `req-class`, `req-nnn`, `req-criterion` and `req-duplicate`, all four
  of which reach the stop gate's blocking set. `check_leaks` already
  refused this trade in writing.
- **G — read the file as if it carried no fence at all (chosen).** The
  quoted rows are reported again, which is a loud false positive rather
  than a silent loss, and the file renders visibly broken in Obsidian
  either way.

### Decision

C, E and G. `fence_blocks` returns every block as `(open_line, info,
body_lines, close_line|None)`, `fence_mask` derives per-line flags from
it, and `check_leaks`, `check_links`, `check_paths` and `req_rows` are
its only consumers. `fence_info` is gone; `fence_host` still reads the
info string the block records.

### Design points

- **Measured before deciding, in both directions.** Across all seven
  vaults on this machine (726 Markdown files), the old and the new fence
  definition disagree about exactly one line — line 196 of this
  repository's own `00_documentation_file_creation_and_conventions.md`,
  inside the four-backtick block that documents the `host=` syntax — and
  no finding hangs on it. Running both validators over all seven vaults
  at the same moment produces identical finding *sets*, not merely
  identical counts: 0 gone, 0 new, everywhere. The change is neutral on
  what exists and only removes a failure mode that nothing bounded.
- **Parity is asserted, not intended.** Two copies of one rule drift;
  that is what residual 1 was. `tests/run.sh` now compares
  `validate_vault.fence_mask` against `export_traceability.fenced_mask`
  on every Markdown file every fixture builds plus the shipped vault, and
  refuses to pass if the fixtures shrink below 50 files.
- **The unclosed fence is answered differently in two places, on
  purpose.** `check_leaks` judges such a block on its body to EOF, because
  the question there is whether a long copy exists. `req_rows` ignores
  fences entirely, because the question there is whether a requirement
  exists, and the answer must not become "no" by accident.
- **The positive control is the assertion that matters.** Asserting that
  a quoted row produces no finding is also satisfied by a check that
  stopped working, so the same rows appear unfenced in a second file and
  must produce all four findings.

### Accepted residuals (documented, not solved)

1. **`check_req_table` switches itself off when the canonical header only
   appears quoted** — issue #25. `header_ok` is set by the header row and
   by nothing else, so a REQ file whose real table drifted from the
   template header and whose only canonical header sits inside a quoted
   block is now read and then not checked. Measured: no REQ file in any
   of the seven vaults depends on this today. The same file without the
   quoted block was equally unchecked before this change; what is new is
   that the accident which covered one instance is gone.
2. **The stop gate does not notice when a session makes ERRORs
   disappear** — issue #26. `hook_stop` blocks on `cur > base` with no
   lower bound, so a file whose findings stop firing ends the session
   green and unmentioned. That is why residual 1 and option F would have
   been invisible rather than merely wrong.
3. **The rule still lives in two files.** The parity assertion makes
   drift a test failure rather than a silent divergence, but the
   exporter importing the primitive from the validator was not done here:
   amendment 2026-07-31b states that the exporter imports from the
   validator and is never imported by it, and reversing that direction is
   not this issue's to decide.

### Realization

- `validate_vault.py` — `FENCE_RE` to the CommonMark shape, `fence_blocks`,
  `fence_mask`, `req_rows`; `fence_info` removed; `check_leaks`,
  `check_links`, `check_paths`, `check_req_table`, `Vault.req_index` and
  the duplicate scan in `validate_vault_wide` converted to them
- `tests/run.sh` — three REQ files in the violation vault (a quoted
  table, the unfenced positive control, a stray unclosed fence), the
  index assertion that the real row is the one addressed, the cross-tool
  mask parity assertion, and the assertion that fixture 7's quoted row is
  invisible to the validator and the exporter reading the same vault;
  144 to 153 assertions

Measured after the change, all seven vaults on this machine at the same
moment, as finding sets rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| homelab | 9 | 115 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| template | 0 | 9 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| PMDE | 398 | 102 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |

The template vault is unchanged at 0 errors and 9 warnings, and
`tests/run.sh` runs 153 assertions with 0 failures.

## Amendment 2026-08-01b — One cell splitter for both tools (Accepted)

### Context

Issue #22. `parse_table_row` divided a row with `s[1:-1].split("|")`,
which the GFM tables extension explicitly rules out: "Include a pipe in a
cell's content by escaping it, including inside other inline spans." An
escaped pipe therefore shifted every column behind it, and the shape that
produces one is not exotic — Obsidian's own documentation requires it for
an aliased wikilink inside a table ("If you want to use aliases, or to
resize an image in your table, you need to add a `\` before the vertical
bar").

Reproduced on a REQ row whose content cell carries `value a \| b` and
whose acceptance criterion is empty: the split moved the next column into
the criterion, the criterion was never empty, and `req-criterion` — a
code in the stop gate's blocking set — did not fire. The same file after
the change reports it.

Measured across all seven vaults on this machine (729 Markdown files):
58 rows change their cell division, spread over two vaults and five
domain folders (homelab TUE 26, BUN 26, IMP 4, ADM 1, PMDE IMP 1). None
of them is in a REQ or an ARC file, so no positional reader touches one
today — 58 rows carry an escaped pipe inside a code span and 0 carry an
unescaped one, which is why the defect has stayed latent.

This is the other half of the design point in amendment 2026-07-31b, "the
exporter carries its own parsing primitives … fixing them is a change to
the blocking layer with its own blast radius and belongs in its own
issue". This is that issue, and it supersedes that design point for the
cell splitter. Residual 3 of amendment 2026-08-01 — "the rule still lives
in two files" — closes here for the splitter and stays open for the fence.

### Options

**Where the one implementation lives.**

- **A — the exporter's splitter copied into the validator, both kept,
  drift caught by a corpus parity assertion.** The compromise the fence
  rule carries. Rejected: residual 3 of amendment 2026-08-01 already
  records that compromise as unfinished business, and a parity test that
  compares two copies still needs both copies to be maintained.
- **B — the exporter imports the primitive from the validator (chosen).**
  The direction amendment 2026-07-31b sanctions — the exporter imports
  from the validator and is never imported by it — and it is already how
  `Vault`, `parse_frontmatter` and `fold_key` are shared. Sharing is then
  asserted by identity rather than by comparison.

**What the splitter returns.**

- **C — cells with their escapes resolved**, which is issue #22's literal
  wording ("resolves `\|` and `\\` before dividing"). Rejected on
  measurement: every consumer that carries cell text forward already
  calls `unescape` on it — four call sites in `_alloc_row` alone — so
  resolving here would unescape twice.
- **D — cells verbatim (chosen).** Splitting is the primitive's job;
  resolving stays where the text is used.

**How much of the row rule is shared.**

- **E — the splitter alone, keeping the validator's stricter gate.** What
  the issue asks for. Rejected on measurement: GFM leaves the trailing
  pipe optional, so a row written without one was a requirement row for
  the exporter and not for the validator — the disagreement amendment
  2026-08-01 removed for fences, one layer further down.
- **F — splitter and row predicate (chosen).** Measured across all seven
  vaults: not one line is classified differently by the two predicates,
  so sharing one costs nothing today and leaves nothing to drift.

### Decision

B, D and F. `split_cells(line, ncols=None)` and `is_separator` live in
`validate_vault.py`; `parse_table_row` is a gate over them and the
exporter imports both. `bound_tables` passes its column count instead of
padding and truncating by hand.

### Design points

- **Both halves of the sentence, in both directions.** An escaped pipe
  must not divide even inside a code span, and an unescaped one must
  divide even inside a code span. A splitter that merely skipped
  backticks would satisfy every example in the spec's escaped column and
  fail the unescaped one; both directions are asserted.
- **The closing delimiter is recognised, not cut off.** `s.endswith("|")`
  is a raw-text test and is also true of a row ending in a deliberate
  `\|`. Stripping it first deleted the author's pipe and left a stray
  backslash that `unescape` cannot restore. The delimiter is now
  identified during the scan. Measured: 0 rows in the corpus end that
  way, and the exporter's output on every vault is unchanged.
- **The spec over the implementation, once.** `\\|` divides here: the
  backslash is itself escaped and no longer escapes the pipe. cmark-gfm,
  and therefore GitHub, renders it the other way — reported as
  github/cmark-gfm#277, unanswered and unfixed. Measured: 0 occurrences
  in seven vaults, so the choice is free; it is recorded because a later
  reader comparing against GitHub will otherwise think this is a bug.
- **Obsidian is the renderer, not GitHub.** The escape is not a
  GitHub-only convention this vault could ignore: obsidian.md documents
  `\|` as the pipe escape and requires it for aliased links and sized
  embeds inside tables.
- **Sharing is asserted by identity.** `validate_vault.split_cells is
  export_traceability.split_cells`, and the same for `is_separator`. A
  re-added local copy would satisfy every behavioural assertion in the
  suite and still be the defect this removes.
- **Measured before deciding, and measured again after.** The old and the
  new validator were run against one disk state at the same moment,
  because homelab drifts under Syncthing while a session runs: a baseline
  captured an hour earlier showed a phantom `link-budget` delta on
  `ARC_omarchy.md` that had nothing to do with this change.

### Accepted residuals (documented, not solved)

1. **A row whose only interior pipes are escaped is no longer a row.**
   It has one column, and two is the minimum both tools have always
   required. The data rows of GFM example 200 are exactly that shape, so
   the spec's own example is accepted by the splitter and refused by the
   row predicate. Measured: 0 such rows in seven vaults.
2. **A four-column REQ table containing an escaped pipe loses the
   coverage the defect gave it.** `check_req_table` skips a row shorter
   than five cells, and the mis-split used to inflate such a row to five,
   so `req-class` and `req-nnn` fired on a table that has never been
   canonical. The same table without an escaped pipe was unchecked before
   and after. This is the shape residual 1 of amendment 2026-08-01
   describes: an accident that covered one instance is gone. Measured: no
   REQ file in any of the seven vaults carries an escaped pipe.
3. **`unescape` stays in the exporter.** The validator has no consumer
   for it, and moving it now would be a helper kept in the file that owns
   the stop gate for a user that does not exist yet. Issue #23 needs it
   for wikilink targets and moves it together with that use.
4. **The fence rule still lives in two files.** Unifying it is not the
   same edit as unifying the splitter: `validate_vault.fence_mask` is
   1-based over `splitlines()` and `export_traceability.fenced_mask` is
   0-based over `split("\n")`, so one of the two signatures has to
   change. The corpus parity assertion keeps them honest until then.
5. **The two tools still read lines differently.** The exporter reads
   BOM-safe and splits on `\n` alone, the validator uses `splitlines()`,
   which also breaks on `\v`, `\f` and U+2028. One splitter therefore
   still does not mean one answer about what the rows of a file are.
   Measured: 0 files in seven vaults contain any of those characters, and
   the BOM half belongs to issue #21.

### Realization

- `validate_vault.py` — `split_cells` and `is_separator` added,
  `parse_table_row` reduced to the shared row predicate over them
- `export_traceability.py` — its local `split_cells` and `is_separator`
  removed and imported instead; `bound_tables` hands its column count to
  the splitter rather than padding and truncating by hand
- `tests/run.sh` — GFM examples 200 and 204 verbatim, both directions of
  the escape rule, the trailing escaped pipe, the escaped alias wikilink,
  a real homelab row whose code span holds a lone backslash before a
  delimiter, the two identity assertions, and a REQ file in the violation
  vault whose escaped pipe used to hide an empty acceptance criterion;
  153 to 156 assertions

Measured after the change, all seven vaults on this machine, old code and
new code against one disk state at the same moment, as finding sets
rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| homelab | 9 | 115 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| template | 0 | 9 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| PMDE | 398 | 102 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |

The exported graph is unchanged too: `traceability.json` is identical on
the template vault, on homelab and on PMDE apart from the provenance line
that records the output directory.

The template vault is unchanged at 0 errors and 9 warnings, and
`tests/run.sh` runs 156 assertions with 0 failures.

## Amendment 2026-08-01c — The frontmatter reader learns the spelling the editor writes (Accepted)

`parse_frontmatter` matched every frontmatter line against `key: value`
and reported anything else as `frontmatter-malformed` — an ERROR in the
stop gate's blocking set. A YAML block sequence has no key on its item
lines, so the spelling Obsidian's own properties editor produces was
rejected:

```
tags:
- hardware
```

`editor_fields` had tolerated `tags`, `aliases` and `cssclasses` in the
vocabulary since amendment 2026-07-28d while the parser rejected the form
the editor writes them in. That contradiction was recorded there as
residual 3 and deferred as follow-up 7, on the measured grounds that no
file anywhere carried the form. Both spellings now fold into one list.

**The measurement that deferred it was scoped wrongly, and the defect was
never latent.** Vaults had been enumerated by folder name
(`01_projectvault`, `01_Projektvault`); the validator defines a vault
through `is_vault_root`. Enumerating by the validator's own definition
finds **nine** vault roots on this machine, not seven —
`homelab/20_Software/userver-nativclaw/docs` and
`Documents/mind/Archiv/Bachelor_Bruder/00_Vault` were never measured. The
first of them holds fifteen files whose `related:` is a block sequence,
eleven of them domain files reporting `frontmatter-malformed` today. Every
"measured across all seven vaults" in this document is a claim about seven
of nine, and issue #24's own zero-occurrence finding inherits the same
error. The rule this leaves behind: a measurement over a population is
only as good as the predicate that enumerates it, and the predicate that
counts is the one the code uses.

What the eleven files gain is the point of the change. One
`frontmatter-malformed` is replaced by 37 `frontmatter-key`, 7
`frontmatter-status` and 11 grouped `frontmatter-undeclared` findings —
all true, all previously masked. The files carry no `domain`, no `created`
and no `last-verified`, and spell `status: Accepted`, which is not in the
vocabulary. A single parse failure had been standing in for five real
defects, which is the same shape as amendment 2026-08-01's stop-gate blind
spot: a check that reports something is not the same as a check that
reports the truth.

### Design points

- **Items are accepted with or without indentation.** YAML 1.2 §8.2.1
  permits a block sequence at the indentation of its parent mapping key,
  and the Obsidian documentation writes it flush left. Issue #24 asked
  for "indented `- item` lines"; implementing that literally would have
  left the editor's own documented output rejected, which is the defect
  the issue was filed about.
- **The closing `---` is located before anything is parsed.** The reader
  used to stop at the first line it could not read, which put `end_line`
  wherever the parse happened to fail. With block sequences accepted, a
  file missing its closing marker would swallow the body's bullet lists
  into a value and push `end_line` to EOF — which is precisely where
  `check_leaks` and `check_paths` stop looking. Reproduced before the fix:
  a `path-missing` ERROR disappeared and `stub` fired on a full file. Such
  a file is now reported *and* handed `end_line` 0, so it is read as if it
  carried no frontmatter at all and the body checks still run. That is
  `req_rows`' rule for an unclosed fence, one layer up: one stray marker
  must not switch a check off.
- **One spelling more, not one rule less.** A tab anywhere in an item line
  (YAML forbids tab indentation, and `line.strip()` would hide it), a
  nested mapping inside an item (`- key: value`), an item indented
  differently from the first item of its sequence, an indented key line,
  and a sequence item belonging to no key all stay malformed. The
  indentation rule is stricter than PyYAML, which reads `- a` followed by
  a deeper `- b` as the single scalar `a - b`; being stricter than the
  reference implementation is honest where agreeing with it is not cheap.
  `- foo:bar` carries no space after the colon, is a plain scalar in YAML
  too, and stays one here.
- **A key with nothing under it keeps the empty string it always had.**
  `verifies:` alone still parses as `""`, not `[]`. The parser holds no
  schema and cannot know which keys are list-valued; `[]` would be wrong
  for `status:` and would newly fire `verifies-empty` on files nobody
  touched.
- **No YAML library.** The validator is stdlib-only, which the CI workflow
  states as the reason it needs no dependency step. Measured before
  deciding: the hand-written reader and PyYAML 6.0.3 agree on all 283
  frontmatter blocks in the corpus, so the reader is not the problem. The
  library would bring problems of its own — 540 date values would become
  `datetime.date` objects, `NO` and `yes` would become booleans (YAML 1.1,
  the Norway problem), and `created: 2026-13-45` raises `ValueError`,
  which does **not** inherit from `yaml.YAMLError` and would exit 2, which
  both hooks swallow. An optional import would be worse still: two parsers
  judging differently on different machines is the drift this project has
  refused three times already.

### Accepted residuals (documented, not solved)

1. **A trailing comment is part of the value.** `tags: # note` parses as
   the string `"# note"` and its items then belong to no key. This is not
   new — `status: active # temp` has always parsed as `active # temp` —
   and it is uniform across every line, but it means a comment above a
   working block list turns it into an ERROR.
2. **A bare `verifies:` still reports nothing.** `check_field_value` sees
   `""`, `isinstance("", list)` is false, and it returns. The honest home
   for that is the type-aware check, not the parser, and it is a finding
   rollout of its own.
3. **`-` with no value yields `[]`, where YAML yields `[None]`.** For a
   required list this makes `verifies-empty` fire, which is the right
   answer for the wrong reason.
4. **The nine-vault correction is not automated.** Nothing stops the next
   measurement from enumerating by folder name again.

### Realization

- `validate_vault.py` — `parse_frontmatter` rewritten around a located
  closing marker and one open-key state; `SEQ_ITEM_RE` and
  `SEQ_NESTED_RE` added
- `tests/run.sh` — the two spellings asserted equal at the parser, the
  unindented form seeded in the precision fixture that must stay at zero
  findings, `verifies` respelled as a block sequence in the violation
  fixture with an assertion that the finding names `REQ-XXX-999`, and
  nine negative controls plus the `end_line` 0 assertion; 156 to 159
  assertions
- `00_documentation_file_creation_and_conventions.md` — both list
  spellings named as equivalent

Measured after the change, all **nine** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| template | 0 | 9 | 0 | 0 |
| homelab | 11 | 115 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 503 | 233 | 11 | 55 |
| PMDE | 398 | 102 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |
| Archiv/Bachelor_Bruder | 68 | 32 | 0 | 0 |

Eight of nine are byte-identical. The ninth is the vault the change was
written for, and its diff is the mask lifting: eleven parse failures out,
fifty-five true findings in. The template vault stays at 0 errors and 9
warnings, and `tests/run.sh` runs 159 assertions with 0 failures. All four
new parser assertions were verified to fail against the previous
`parse_frontmatter`, so the suite can still tell the two apart.

A note for whoever deploys this: no finding code was renamed and no code
was added to the blocking set, so a stale per-session baseline in
`/tmp/claude-mechdocs` stays valid. A full audit of
`homelab/20_Software/userver-nativclaw/docs` will report 44 more ERRORs
than before — all of them pre-existing and previously hidden behind the
parse failure, none of them introduced here.


## Amendment 2026-08-01d — The link matcher reads the two shapes it never saw (Accepted)

`WIKILINK_RE` demanded at least one character before an anchor and read
its target greedily. Two documented Obsidian shapes fell through that,
in opposite directions.

A link into the file itself — `[[#Heading]]`, `[[#^blockid]]`, both
spelled out on obsidian.md/help/links — matched nothing at all and was
invisible to `check_links`: not resolved, not counted, not reported. And
a link written the way Obsidian *requires* inside a table, with the alias
pipe escaped, was matched with the backslash glued to its target. The
target `Note\` resolves against nothing, so `link-unresolved` fired — an
ERROR at turn end on a link that works. Obsidian states the escape as an
instruction, not a workaround: "If you want to use aliases, or to resize
an image in your table, you need to add a `\` before the vertical bar"
(obsidian.md/help/advanced-syntax), with the example
`[[Basic formatting syntax\|Markdown syntax]] | ![[Engelbart.jpg\|200]]`.
Both halves of that example were broken here.

Measured across all **nine** vault roots on this machine — enumerated
with `is_vault_root`, the tenth being a scratch fixture under
`/home/jerome/tmp/mechdocs-test/` that is named and excluded rather than
quietly skipped: 1090 files, 4609 links, **zero** same-file links and
**zero** escaped aliases. Both defects are latent, and the blast radius
of the correction is zero findings in either direction.

### Design points

- **The escape is handled at the alias boundary and nowhere else.** A
  legal link target cannot carry an escape at all: Obsidian forbids
  `[ ] # ^ |` in file names outright and `\` on Linux and macOS, so the
  only legal backslash inside `[[...]]` is the one in front of an alias
  or embed-size pipe. Three quantifiers do the whole job — `*` instead of
  `+` on the target, lazy target and anchor, and `\\?` in front of the
  alias pipe.
- **The anchor carried the same defect, one field over.** `[[Note#Head\|alias]]`
  used to yield the anchor `#Head\`. Nothing resolves anchors of other
  files, so it cost nothing — but it was the same bug, and it is fixed
  and asserted rather than left for the next reader to rediscover.
- **`unescape` stays in the exporter, and residual 3 of amendment
  2026-08-01b stays open.** That residual authorised the move *together
  with the use issue #23 would bring*. With the escape handled in the
  regex, the use does not exist: measured over the nine vaults, 4792
  targets contain not one backslash, and `unescape` cannot act on any
  target the new matcher can produce. Moving a helper across a module
  boundary for a call that provably changes nothing would be the
  decoration this document keeps refusing. The issue asked for it; the
  purpose behind it — a table-escaped alias must resolve — is delivered
  by the regex.
- **A same-file link is resolved, not exempted.** The issue asked for
  links "resolved against the containing file rather than the name
  index", and exempting them would have produced the same output for an
  anchor that exists and one invented on the spot — a fixture that cannot
  fail. `anchor_index` reads headings of every level and block
  identifiers, both outside fenced blocks, so a `# rebuild the image`
  line in a `bash` block resolves nobody's anchor. Headings compare
  folded, which is the tolerance `classify_sections` already grants.
- **Same-file links stay out of the link budget and the repeat counter.**
  The issue named the missing count as part of the defect; the shipped
  conventions say "under ~20 **outgoing** links per file", and "link the
  responsible file once" has no addressee when the target is the file the
  reader is already in. An ordinary table of contents would otherwise
  trip `link-repeat` at four entries and `link-budget` at twenty-one,
  with advice nobody can follow.
- **`[[]]` remains no link.** It is the one line in 81028 where the old
  and the new regex disagree, and the only occurrence on this machine is
  the REF template of a foreign archive vault — not of the vault this
  repository ships. Skipping it preserves exactly what the old regex did
  by not matching it; reporting the empty placeholder is a finding
  rollout of its own.
- **Reviewed adversarially before implementation.** A fresh-context
  review produced ten findings; nine were confirmed and changed the plan,
  including the two above that reverse the issue's own wording. The one
  refuted finding is residual 3 below.

### Accepted residuals (documented, not solved)

1. **An anchor into another file is still unchecked.** `[[Note#Heading]]`
   resolves as soon as `Note` exists; whether that heading is there is
   nobody's question yet. The asymmetry is deliberate — `check_links`
   holds the lines of the file it is checking and nothing else.
2. **A chained anchor is checked segment-wise, not as a path.**
   `[[#Chapter#Section]]` passes when both name headings, even if the
   second is not below the first. Obsidian resolves the path; this reads
   the set.
3. **`check_links` is quadratic in line length, and this change makes it
   1.23× worse.** Measured on a single line of `n` opening brackets:
   503 ms old against 617 ms new at n=4000, quadrupling per doubling in
   both. `hook_post` runs it on every write, so one pasted single-line
   blob stalls the hook rather than failing it. The obvious guard
   (`if "[[" not in line: continue`) does not touch this case — the
   pathological line contains `[[` — it only spares link-free lines
   (0.07 ms → 0.002 ms). Pre-existing, out of scope here, worth its own
   issue.
4. **`[[A\\|B]]` yields the target `A\`.** The escaped backslash no
   longer escapes the pipe, so `split_cells` divides the cell there
   (amendment 2026-08-01b) while the link matcher keeps the backslash.
   Degenerate in both readings — the target is illegal either way, and
   the shape occurs zero times.

### Realization

- `validate_vault.py` — `WIKILINK_RE` rewritten with the three
  quantifiers documented inline; `HEADING_RE` and `BLOCK_ID_RE` added;
  `anchor_index` and `anchor_resolves` added; `check_links` given the
  same-file branch, the empty-link skip and the counter exclusion
- `tests/run.sh` — fourteen matcher assertions (six verified to fail
  against the previous `WIKILINK_RE`, two negative controls), nine
  assertions on `anchor_index`/`anchor_resolves` including the fenced
  shell comment, four on `check_links` primitives including the
  budget-exclusion pair, a resolving anchor pair and an escaped alias in
  the precision fixture, a reported pair in the violation fixture, and
  the post hook's aggregation count moved 2 → 4 with a by-name
  assertion; 159 to 164 assertions
- `00_documentation_file_creation_and_conventions.md` — the table escape
  and the same-file anchor named in the Wikilinks section

Measured after the change, all **nine** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| template | 0 | 9 | 0 | 0 |
| homelab | 9 | 114 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 503 | 233 | 0 | 0 |
| PMDE | 398 | 102 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |
| Archiv/Bachelor_Bruder | 68 | 32 | 0 | 0 |

Nine of nine are byte-identical, which is the expected result for a
change whose two shapes occur nowhere. What proves the change works is
therefore the runtime check rather than the corpus: on a throwaway vault
carrying all four shapes, the old code reports
`[[CMP_Converter\]] does not resolve to any file` on a working link and
says nothing about two anchors pointing at nothing, while the new code
stays silent on the link and names both anchors.

A note for whoever deploys this: no finding code was renamed and no code
was added to the blocking set, so a stale per-session baseline in
`/tmp/claude-mechdocs` stays valid. Nothing in any measured vault changes
severity or count.


## Amendment 2026-08-04 — One BOM-safe reader for every file the validator opens (Accepted)

`parse_frontmatter` compares the first line of a file against `---`.
`read_lines` opened files as `utf-8`, so a byte-order mark made that
comparison fail and the reader returned `(None, 0, None)`: the third
element is the malformed-message slot, and it was empty. Nothing was
reported anywhere. `validate_file` then took the `fm is None` branch and
produced `frontmatter-missing` — an ERROR naming the wrong cause, on
frontmatter sitting visibly in the file — while `frontmatter_id`
returned `None` and dropped the file out of the identifier checks
without a word. A mark is never typed on purpose: it arrives from an
editor, a redirect or an export tool, and the resulting message points
away from the cause rather than at it.

`read_lines` was not the only reader. Four more open files, and each
fails differently:

- `validate_vault_wide` builds its corpus with its own read, and
  `check_identifiers` compares nothing else. Fixing `read_lines` alone
  would have removed the false ERROR and left the identifier hole
  exactly where it was.
- `Vault.templates_for` reads templates for their headings. `extract_h2`
  tests `startswith("## ")`, so a mark in front of a heading on line 1
  removes that heading from the required set of a whole domain, and
  `check_sections` returns early when a template yields nothing.
- `git_head_content` decoded with `text=True`, so the HEAD baseline and
  the working tree disagreed about the same file.
- `_read_schema` decodes `vault_schema.json`, and `json.loads` rejects a
  leading BOM outright. The schema drops to `FALLBACK_SCHEMA` behind a
  single WARN that `validate_file` suppresses on baseline passes:
  declared values and editor fields silently out of force.

Measured across all **nine** vault roots on this machine: 1091 files,
**zero** carrying a byte-order mark and zero that are not valid UTF-8.
Every one of these defects is latent, and the blast radius of the
correction is zero findings in either direction.

### Design points

- **One reader, not five encoding literals.** `read_text` is what
  `read_lines`, the corpus and the template scan now share, and
  `git_head_content` and `_read_schema` carry the same rule where a
  `Path.read_text` is not what they call. The scattered literals are how
  the fifth site stayed unnoticed until an adversarial review went
  looking — the issue named two. What actually keeps a sixth site
  honest, though, is not the helper but the assertion: the reader-parity
  harness now compares `validate_vault.read_lines` against
  `export_traceability.read_lines` on every fixture file.
- **The exporter has been right since amendment 2026-07-31b.** Its
  `read_lines` docstring names this exact defect, and its design point
  "the exporter carries its own parsing primitives" listed the
  validator's BOM behaviour as a live, exported defect. That statement
  is now historical: both tools read a file the same way, and the
  harness that is supposed to keep them in step was blind to precisely
  this divergence until this change added the line for it.
- **Both halves ship in one commit, measured.** With only the HEAD
  reader fixed, the baseline of a marked file comes back clean while the
  working tree still reports `frontmatter-missing` — so the stop gate
  blocks the session on a file nobody touched, with a message naming the
  wrong cause. Reverting either half alone was run through both hooks
  before this was written.
- **The schema reader was taken along deliberately.** It is not in issue
  #21, it is the same defect class in one token, and its test costs no
  new assertion: fixture 5's declared-schema block is written with a
  mark, so the existing `'owner'` assertions became the control. Scope
  extensions are announced, not slipped in — this one was approved
  before it was written.
- **The tests are positive controls on assertions that already
  existed.** Four fixtures gained a mark rather than a new assertion:
  the violation vault's REQ template (the `'squad'` undeclared key), its
  IMP template (both IMP near-miss assertions), fixture 5's declared
  schema (`'owner'`), and a domain file whose twin claims the same
  identifier (`id-duplicate`). Each reverted reader fails at least one
  of them, and the mapping was measured rather than assumed. A mark on a
  fixture is cheaper than a new negative assertion and much harder to
  fool: a negative passes for any reason at all.
- **Every marked fixture carries a byte-level guard.** `head -c 3 | od`
  against `ef bb bf`, the idiom the CSV export's BOM assertion already
  uses. A fixture that silently loses its mark satisfies every assertion
  above while proving nothing, and nothing else in the suite would
  notice.
- **The template site is fixed for the class, not for a live defect.**
  All but one of the thirteen shipped templates begin with `---`, so
  `extract_h2` — which scans every line and only loses line 1 — would
  keep the full heading set for them. The plan claimed more than that
  and was corrected during review. The fix stays: a template is the one
  file a whole domain's section checks depend on, and "harmless today"
  is not a property of the reader.
- **Reviewed adversarially before implementation.** A fresh-context
  review produced fifteen findings; twelve were confirmed and changed
  the plan, three were refuted with the code. Two of the confirmed ones
  removed work rather than adding it: the direction of the
  `id-vanished` pair that passes against today's code as well (the file
  is in neither set, so it proves nothing), and a mark on
  `CMP_MCU_Board.md`, which already guards the editor-field tolerance
  and the block-sequence `aliases` of issue #24 through one
  zero-findings assertion.

### Accepted residuals (documented, not solved)

1. **A doubled mark still breaks it.** `utf-8-sig` strips exactly one,
   and Windows tools can write a second on re-save. The fix is one BOM
   deep; the second one produces the original defect unchanged.
2. **A file that is not UTF-8 at all is unchanged by this.** UTF-16 —
   what Windows PowerShell 5.1 writes for `Out-File`, `>` and `>>` —
   decodes to replacement characters and NUL-separated text under both
   readers, and still produces `frontmatter-missing` plus
   `template-sections` rather than a word about the encoding. A
   truncated mark (`ef bb`) is the same class. Filed as issue #31,
   which needs a new finding, not a reading option.
3. **The `splitlines()` half of residual 5 of amendment 2026-08-01b
   stays open.** That residual named two ways the two tools read lines
   differently; the BOM half is closed here. The validator still splits
   with `splitlines()`, which also breaks on `\v`, `\f` and U+2028,
   while the exporter splits on `\n` alone. Measured: 0 files in nine
   vaults contain any of those characters.
4. **A per-session baseline written before this change is milder than it
   should be.** A session that touched a marked file carries
   `{"frontmatter-missing": 1}` in `/tmp/claude-mechdocs`, so that code
   counts as pre-existing until the state expires after
   `STATE_MAX_AGE_S`. Harmless — it tolerates, it never blocks.

### Realization

- `validate_vault.py` — `read_text` added and used by `read_lines`,
  the corpus in `validate_vault_wide` and `Vault.templates_for`;
  `git_head_content` given `encoding="utf-8-sig"` in place of
  `text=True`; `_read_schema` decoding with `utf-8-sig`
- `tests/run.sh` — a reader probe asserting that a marked and an
  unmarked file yield identical lines and that a mark inside the text
  survives; marks on the REQ template, the IMP template, fixture 5's
  declared schema, a new domain file with an identifier twin, and a
  committed file in the identity fixture; a byte-level guard per marked
  fixture; the reader-parity line in the fence-mask harness;
  164 to 174 assertions
- no change to `00_documentation_file_creation_and_conventions.md`: a
  byte-order mark is not something an author writes, so there is no
  convention to state

Measured after the change, all **nine** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| template | 0 | 9 | 0 | 0 |
| homelab | 9 | 114 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 503 | 233 | 0 | 0 |
| PMDE | 398 | 102 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |
| Archiv/Bachelor_Bruder | 68 | 32 | 0 | 0 |

Nine of nine are byte-identical, which is the expected result for a
defect that no file on this machine carries. What proves the change
works is therefore the runtime check rather than the corpus: on a
throwaway vault holding a marked file and an unmarked twin claiming the
same identifier, the old code reports `frontmatter-missing` on the
marked file and stays silent about the collision, while the new code
reports `id-duplicate ARC-BOM-001 ... already declared in ARC_Bom.md`
and says nothing about missing frontmatter. Against a marked
`vault_schema.json` the old code reports `schema-unreadable` and falls
back; the new code reports nothing and keeps the schema in force. Run
through both hooks, the marked file produces one `stub` WARN and no
block.

A note for whoever deploys this: no finding code was renamed and no code
was added to the blocking set. A vault whose files carry no mark — every
vault measured here — sees no change at all.

## Amendment 2026-08-04b — A requirement table is recognised by its shape, not by its header text (Accepted)

### Context

Issue #25, residual 1 of amendment 2026-08-01. `check_req_table` gates
every row check on `header_ok`, a flag set by one thing only: a table row
whose first cell contains `Class` or whose first two cells contain `NNN`.
Nothing resets it and nothing else sets it. Since issue #20 made
`req_rows` skip fenced blocks, a canonical header that survives only
inside a quoted example no longer switches the check on, so a REQ file
whose real table header drifted — translated, reworded, reformatted —
is read and then not checked, silently, on four codes that all reach the
stop gate's blocking set.

Reproduced against the current validator: a REQ file quoting the
canonical header inside a ```` ```markdown ```` block and carrying its
real table below under `| Klasse | Nr. | Inhalt | Kriterium | Quelle |`
with one broken row produces zero findings.

### Options

**What identifies a requirement table.**

- **A — the template-declared section title**, as `export_traceability.py`
  binds its tables since amendment 2026-07-31b, and the candidate issue
  #25 names. Rejected on measurement: across the four vault roots on this
  machine that carry a `REQ` folder, 121 requirement rows are checked
  today and the section binding would check 87. The 34 lost rows all sit
  in `REQ_persona_voice.md` (userver-nativclaw), which carries seven
  five-column requirement tables under seven section titles of its own.
  The option would install the very failure mode the issue was filed
  against. It also has no answer for a project whose REQ template
  declares no table at all — the exporter reports `export-no-binding`
  there, but a validator that binds to nothing checks nothing.
- **B — the width of the table alone.** Rejected: a five-column
  changelog or revision table in a REQ file becomes a requirement table
  and produces four blocking ERRORs on rows nobody wrote as
  requirements.
- **C — the GFM table structure plus a requirement signal (chosen).** A
  table is what the GFM tables extension says it is: a delimiter row,
  and above it a header row with the same number of cells. Such a table
  is a requirement table when it has at least five columns AND either
  its header carries the canonical tokens or at least one of its rows
  carries a three-digit identifier in the second cell — the very
  predicate `Vault.req_index` and the global duplicate scan already use
  to decide that a row defines a requirement. The recognition is a union
  with today's rule, so no row that is checked today stops being
  checked, and it needs neither the header's wording nor a section title
  to survive.

**What to do about the silence that remains.**

- **D — leave it.** Rejected: issue #25's second delivery item exists
  because a check that stops checking without saying so is the failure
  mode this layer is for.
- **E — report every table that is not a requirement table.** Rejected:
  a REQ file may legitimately carry a source map or a rubric, and a WARN
  nobody can act on trains the reader to ignore the channel.
- **F — report the two cases the validator can prove from its own state
  (chosen).** `req-table-unrecognized` (WARN, one grouped finding per
  file) when a table group that is not a recognised requirement table
  carries a row the requirement index will index anyway — the validator
  disagreeing with itself — or when a REQ file has a table of at least
  five columns and not one recognised requirement table, which is a file
  that looks like it defines requirements and defines none the checks
  can read.

### Decision

C and F. `req_tables` becomes the one reader that groups table lines
into GFM tables, `req_rows` becomes its flattening view so
`Vault.req_index` and the global duplicate scan keep reading exactly
what they read today, and `check_req_table` iterates tables instead of
latching on a header. The column count stays a Python constant, the
exporter is not touched, and the row checks themselves are unchanged.

### Design points

- **The candidate the issue named was rejected by measurement, not by
  argument.** Only four of the nine vault roots on this machine carry a
  `REQ` folder at all — the five German ones spell it `ANF`, where
  `check_req_table` never runs, so the translated header that motivates
  this issue cannot occur in the vaults that are actually written in
  German. Across those four: 121 requirement rows are checked today, the
  section binding would check 87, and every one of the 34 it drops sits
  in `REQ_persona_voice.md`, which carries seven five-column requirement
  tables under seven section titles of its own. The binding is right for
  the exporter, where an unbound table becomes a row in a report, and
  wrong here, where it becomes a check nobody runs.
- **Two signals, unioned with the old rule, so nothing stops being
  checked.** The canonical header keeps its job — it is the only signal
  left when every row of a table is malformed — and the requirement
  number in the second cell is the one that survives translation. Because
  the second signal is `Vault.req_index`'s own predicate, "this table is
  a requirement table" and "this row defines a requirement" can no longer
  give different answers about the same line.
- **Width is a floor, not an equality.** The first draft required exactly
  five columns, which would have sold an exemption from four blocking
  codes for one `| Comment |` in a header — the same bypass amendment
  2026-08-01 refused to sell for three backticks, at a tenth of the
  price. The adversarial review found it with a fixture the corpus does
  not contain.
- **A fenced line ends a table, it does not vanish from it.** `req_rows`
  may skip fenced lines because it asks a per-line question. A reader
  that groups lines into tables cannot: two tables separated by a quoted
  example would merge, and the second table's header would be read as a
  body row — two blocking findings on a line the author wrote correctly.
  Also found by the review, also with a shape no vault here contains.
- **The column count stays in Python.** Reading it from
  `domains.REQ.rows.columns` would have made a data file the off-switch
  for four blocking codes, which is exactly what `discovery`'s rejected
  per-project override refuses, and `_strlist` drops non-strings
  silently, so a typo in that list would have disabled the checks without
  even a `schema-unreadable` WARN.
- **The new WARN reports only what the validator can prove from its own
  state.** Reporting every table that is not a requirement table would
  fire on the source map, the rubric and the revision history that real
  REQ files legitimately carry. The two conditions that ship are a
  self-disagreement (the index reads rows no check reads) and an empty
  answer (a file with a wide table and no readable requirement table).
  Measured: zero findings across all nine vault roots.
- **Reviewed adversarially before implementation.** A fresh-context
  review produced fourteen findings; twelve were confirmed and four of
  them changed the design — the width floor, the fence break, the Python
  constant, and the WARN's scope. Two were refuted with measurement: the
  claimed 1-in-1 false-positive rate of the WARN belonged to the draft
  that was replaced, and the rejected section binding remains rejected
  even though the exporter extracts nothing from that vault for an
  unrelated reason. Every counter-example the review wrote out was run
  against both the old and the new code before the plan was revised.

### Accepted residuals (documented, not solved)

1. **A REQ file with no table at all is not reported.** Requirements
   written as prose under a heading — `REQ_secrets_isolation.md` in the
   nativclaw vault is one — produce no row, so neither WARN condition can
   fire. Reporting it would be a convention rollout on files that never
   adopted the table form, not a defect report.
2. **A five-column table nobody meant as a requirement table is still
   read as one** when its rows carry three-digit numbers in the second
   cell. That is deliberate: the requirement index already reads those
   rows as requirements, so the alternative is not silence but
   disagreement. The fixture for the opposite case — a revision history
   whose second column holds dates — is what keeps the signal honest.
3. **A short body row is still skipped rather than padded.** GFM inserts
   empty cells for a row narrower than its header, so a four-cell row in
   a five-column table genuinely has an empty acceptance criterion. The
   `len(row) < REQ_ROW_COLUMNS` guard predates this change and keeps its
   behaviour; padding would have added blocking findings this issue never
   asked for. Measured: zero such rows in nine vault roots.
4. **The exporter never reports an unbound table in a REQ file.**
   `_report_unbound` is called from the ARC loop of `build_graph` alone,
   so the six unbound five-column tables of `REQ_persona_voice.md`
   are absent from its export without a finding — which contradicts
   `table_bindings.binding_discovery.unbound_table` ("an empty graph is
   never silent") and the exporter's own docstring. Found by the
   adversarial review of this issue, measured, and left alone: it is an
   exporter defect and belongs in its own issue. Filed as issue #34,
   which also names the second gap it hides behind — that file returns at
   `export-no-scope` before any table is looked at.
5. **`parse_table_row` has no production caller left.** `req_tables`
   needs the delimiter row distinguishable from "not a row", which that
   predicate deliberately conflates. It stays because it is what the
   test harness asserts the two tools share, and `req_rows` is now
   asserted to agree with it line by line.

### Realization

- `validate_vault.py` — `req_tables` added as the one reader of table
  structure, `req_rows` reduced to its flat view, `check_req_table`
  rewritten around it with `canonical_req_header` and
  `check_req_table_silence`; `ROW_NNN_RE` and `REQ_ROW_COLUMNS` added and
  read by `Vault.req_index` and the global duplicate scan as well
- `vault_schema.json` — `domains.REQ.rows` gains `recognition` and
  `unrecognized`; `enforced_detail` names the new code and why the column
  count is not data
- `tests/run.sh` — four REQ fixtures (drifted header behind a quoted one,
  a fence between two tables, a widened second table, a revision history
  as the only wide table), the placeholder rows in the precision vault's
  REQ file, and `req_tables` in the parser assertions;
  174 to 188 assertions
- no change to `export_traceability.py`: the section binding is right
  where an unbound table becomes a row in a report

Measured after the change, all **nine** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| template | 0 | 9 | 0 | 0 |
| homelab | 9 | 114 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 503 | 233 | 0 | 0 |
| PMDE | 398 | 102 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |
| Archiv/Bachelor_Bruder | 68 | 32 | 0 | 0 |

Nine of nine are byte-identical, which is the expected result for a
recognition rule that only ever adds: every table checked before is still
checked, and no vault here carries the drifted shape. What proves the
change works is therefore the runtime check. On a throwaway vault holding
the issue's own reproduction — a REQ file quoting the canonical header
inside a ```` ```markdown ```` block, with its real table below under
`| Klasse | Nr. | Inhalt | Kriterium | Quelle |` and one broken row — the
old code reports nothing at all and the new code reports `req-class`,
`req-nnn` and `req-criterion` on that row and nothing on the quoted one,
while `REQ-DRF-002` reaches the requirement index and the quoted
`REQ-DRF-001` does not. Run against the shipped template vault, the
result is unchanged at 0 errors and 9 warnings.

A note for whoever deploys this: no finding code was renamed, and the one
added code is a WARN and not in the blocking set. A vault whose
requirement tables are recognised today sees no change at all; a vault
whose table header drifted starts being checked, which is the point.

## Amendment 2026-08-04c — A file that is not UTF-8 says which encoding it is (Accepted)

### Context

Issue #31, residual 2 of amendment 2026-08-04. `read_text` decoded every
file with `errors="replace"`, so a file that is not UTF-8 was read
successfully and read wrongly. Reproduced against the validator as it
stood: an ARC note written as UTF-16LE — what Windows PowerShell 5.1
produces for `Out-File`, `>` and `>>`
(learn.microsoft.com/powershell/module/microsoft.powershell.core/about/
about_character_encoding) — yields `frontmatter-missing` and
`template-sections`, two ERRORs in the stop gate's blocking set, both
naming a cause that is written in the file, while `frontmatter_id`
returns None and the file drops out of the identifier checks.

The signature-less half is worse and the issue understates it. The same
shell writes the active ANSI code page for `Set-Content` and
`Add-Content`. Such a file keeps its frontmatter and its `## ` headings,
because those are ASCII; only the umlauts of its prose become U+FFFD.
Measured on a probe: **zero** findings. The file validates green while
its text is corrupted.

Measured across all nine vault roots on this machine: 1091 files, zero
that are not valid UTF-8, zero carrying any byte-order mark. The defect
is latent, like #21's, and what proves the change is therefore the
runtime behaviour rather than the corpus.

### Options

**What to detect.**

- **A — a leading byte-order mark, and nothing else**, which is what
  issue #31 asks for. Rejected as half the defect: the ANSI file above
  carries no signature and is exactly the case that produces no finding
  at all today.
- **B — the mark, plus one strict decode whose failure is reported by
  byte offset (chosen).** A mark is proof rather than a guess: `FF` and
  `FE` are not legal UTF-8 bytes anywhere, so no valid UTF-8 file can
  begin with one. Where no mark exists, "these bytes are not UTF-8, at
  this offset" is the strongest true statement available — a Latin-1
  file and a corrupted UTF-8 file cannot be told apart, and the message
  names the byte instead of claiming the encoding.
- **C — statistical charset detection** (chardet and its kin). Rejected:
  a dependency, a guess, and a guess that has to be right to be useful.

**What to do with the encoding once it is known.**

- **D — decode with it and check the file normally.** Rejected. Obsidian
  does not open such a file either, so a validator that understands it
  would bless a file that does not work in the tool the vault exists
  for; and `export_traceability.py`, which reads with its own reader,
  would begin carrying that file's requirement rows into the
  traceability graph.
- **E — name it, read on exactly as before (chosen).** `read_text`
  returns, for every input, byte-for-byte what it returned before this
  change. That is what leaves the exporter untouched and keeps the two
  tools reading one way, and it is asserted per shape rather than
  assumed.

**Whether the finding replaces the file's other findings.**

- **F — replace them**, which issue #31 argues for: every check below is
  reading replacement characters, so reporting their conclusions is
  reporting noise. Rejected on evidence. `hook_stop` compares each ERROR
  code against the count the same file carries at git HEAD. Replace, and
  a file committed as UTF-16 has a baseline of one code where the run
  used to report three — so the session that does what the finding asks
  and re-saves the file as UTF-8 produces `template-sections` against a
  baseline of 0 and is blocked for it. Measured: re-introducing the
  early return fails three assertions, one of them that repair path.
- **G — add it (chosen)**, first in the file's findings and saying in so
  many words that what follows are consequences of the encoding rather
  than defects of their own. The reader keeps the diagnosis; the ratchet
  keeps its symmetry.

**Severity.**

- **H — WARN**, on the argument that the producer of such a file is never
  the running session: `Write` and `Edit` emit UTF-8, so the file arrives
  from a Windows shell, a sync client or an export tool, and the blocking
  channel aims at a party that is not at the table. Rejected: this
  project's criterion is whether a check can tell a mistake from an
  intention, and a Markdown file of a UTF-8 vault written in UTF-16 is
  never anybody's intention. `template-unreadable` is the standing
  precedent for "cannot be read at all" being an ERROR.
- **I — ERROR (chosen)**, under the condition amendment 2026-07-28g
  stated when `section-mismatch` became the first ERROR to enter the
  blocking set: the code has to appear in the HEAD baseline as well, or
  the gate blocks a session on a file nobody touched. That is why
  `git_head_content` hands out the blob as bytes and why both halves
  ship in one commit.

### Decision

B, E, G and I. `decode_source` becomes the one place where bytes become
vault content, `read_source` its file-level form, and `read_text` a view
on it with its old contract intact. `validate_file` takes the raw bytes
of a revision rather than its text, and `encoding-not-utf8` (ERROR, line
1) joins the file's findings.

### Design points

- **The signature table is ordered longest first, and that is the whole
  reason it is a table.** `FF FE 00 00` begins with the UTF-16LE mark, so
  a table tested in any other order calls every UTF-32LE file UTF-16LE.
  The four sequences and their byte orders are Microsoft's table
  (learn.microsoft.com/globalization/encoding/byte-order-mark), which
  states the Unicode standard's. The probe for that pair is the one
  assertion a reversed table fails.
- **The UTF-8 mark is deliberately not in the table.** It is stripped and
  the file is read on, which is what amendment 2026-08-04 settled; a file
  saved by a well-meaning Windows editor is not a file with a problem.
- **Both halves were measured by reverting each alone.** With only the
  working-tree half in place, a file committed as UTF-16 reports a code
  its own baseline does not carry and the gate blocks a session that
  touched nothing — one assertion catches it. This is the test amendment
  2026-07-28g asked for, in the form it asked for it.
- **The newline translation had to be restored explicitly.**
  `Path.read_text` opens in text mode and translates `\r\n` and a lone
  `\r`; decoding bytes does not, and 16 of the 1091 files carry CRLF.
  Every consumer splits with `splitlines()` and would never have noticed
  — but `read_text` is this module's public reader and the claim that its
  output is unchanged has to be true, not nearly true. The claim was
  wrong in the plan and the review caught it. Doing the two rewrites on
  every string cost a fifth of a full audit (homelab 0.32 s → 0.39 s), so
  a membership test skips them for the 1075 files without a CR.
- **`decode_source` never raises, including on a `str`.** It runs in both
  hook paths, where an exception exits 2 and fails the gate open. There
  is one producer of the bytes today and none tomorrow; a `TypeError`
  there would switch the enforcement layer off silently, which is too
  high a price for a type check the language does not enforce anyway.
- **Reviewed adversarially before implementation.** A fresh-context
  review returned thirteen findings; ten changed the plan and three were
  refuted with the code. The consequential ones: the ratchet inversion
  that killed the early return, the claim that `read_text`'s output would
  be byte-identical (false for 16 files), and two proposed assertions
  that would have passed against the unchanged validator. Refuted, with
  evidence: the alleged rule that no amendment may add to the blocking
  set — `section-mismatch` did exactly that and recorded the condition
  under which it is safe; that `content is None` would stop being a
  usable baseline signal, which only holds for a refactor this change
  does not make; and that pairing a positive assertion with "never a
  WARN" is worthless, which is the shape the suite already uses for
  `fence-record` and `id-vanished`.
- **The tests were measured against three wrong versions, not just the
  right one.** Five of the new assertions fail against the old
  validator, one against the fix with only its HEAD half reverted, and
  three against the fix with the early return re-introduced.

### Accepted residuals (documented, not solved)

1. **UTF-16 without a mark stays invisible.** ASCII text encoded as
   UTF-16LE is valid UTF-8 — every second byte is NUL, which decodes
   fine — so the strict decode does not fail and no signature exists to
   read. Windows PowerShell writes a mark for every Unicode encoding
   except UTF-7, so the source this was filed for is covered; a
   hand-crafted file is not.
2. **A doubled UTF-8 mark is still not reported.** `EF BB BF EF BB BF`
   remains valid UTF-8 after `utf-8-sig` strips one, so residual 1 of
   amendment 2026-08-04 stays open and this change must not be read as
   closing it. A probe asserts that it is still open.
3. **A template nobody can decode still empties its domain silently.**
   `Vault.templates_for` reads through `read_text`, `extract_h2` finds no
   `## ` line in the mojibake, and `check_sections` returns early for
   every file of that domain. The template's own `encoding-not-utf8` is
   the only message, which is at least a blocking one naming the cause.
   Unchanged from before this fix, and the same shape as the defect
   amendment 2026-08-04 closed for marks.
4. **The exporter reports nothing about encodings.** It shares the
   decoding — its reader applies the same `utf-8-sig` rule — but it has
   no finding channel for this and will read such a file as mojibake,
   contributing no rows. "One rule for both tools" holds for how the
   bytes are read, not for what is said about them.
5. **A REQ file in the wrong encoding takes its rows down with it.**
   `Vault.req_index` reads no rows out of mojibake, so every TAE file
   whose `verifies:` names those requirements gets `verifies-unknown-req`
   — a blocking ERROR on files that are not at fault, the failure shape
   `id-scope-mismatch` was introduced against. Pre-existing and
   unchanged; the cause is now named on the file that has it.
6. **`vault_schema.json` in another encoding is still reported as "not
   valid JSON".** The schema reader has its own path and its own WARN,
   and the message points at the parse rather than at the bytes.

### Realization

- `validate_vault.py` — `BOM_SIGNATURES`, `_universal_newlines`,
  `decode_source` and `read_source` added; `read_text` reduced to a view
  on `read_source`; `validate_file` documented as taking the raw bytes of
  a revision and emitting `encoding-not-utf8`; `git_head_content`
  returning the blob unfiltered; `head_identifiers` decoding through the
  shared reader
- `tests/run.sh` — a UTF-16LE and an ANSI fixture in the violation vault,
  each with a byte guard; probes at `decode_source` for the
  UTF-32-before-UTF-16 order, the truncated and the doubled mark, the
  `str` and empty-input paths, and `read_text`'s unchanged output across
  six shapes; in the git-backed fixture a committed UTF-16 file, an empty
  committed file and the repair path; 174 to 189 assertions
- no change to `00_documentation_file_creation_and_conventions.md`: an
  encoding is not something an author writes, so there is no convention
  to state — the same argument as amendment 2026-08-04
- `export_traceability.py` untouched, which is a consequence of decision
  E rather than an omission

Measured after the change, all **nine** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| template | 0 | 9 | 0 | 0 |
| homelab | 9 | 114 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 503 | 233 | 0 | 0 |
| PMDE | 398 | 102 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |
| Archiv/Bachelor_Bruder | 68 | 32 | 0 | 0 |

Nine of nine byte-identical, which is the expected result for a defect no
file on this machine carries. Full-audit runtime, median of five:
homelab 0.32 → 0.35 s, PMDE 0.30 → 0.31 s, userver-nativclaw 0.70 →
0.73 s, template 0.13 → 0.12 s. `tests/run.sh` at 189 assertions, 0
failures.

What proves the change is the runtime check. On a throwaway vault holding
a UTF-16LE file and an ANSI file, the CLI reports `the file is UTF-16LE,
not UTF-8` and `the file is not valid UTF-8 (invalid start byte at byte
119)`, each on line 1 of its file, with the misread's consequences below
them. Through the hooks: the same file created this session blocks the
stop gate; committed at HEAD it does not block and is reported as
pre-existing; and after the session re-saves it as UTF-8 the gate stays
quiet while the section ERROR underneath becomes readable.

A note for whoever deploys this: `encoding-not-utf8` is an ERROR and does
enter the stop gate's blocking set. The per-file baseline in
`/tmp/claude-mechdocs` is recomputed from HEAD by the running validator,
so a session started after the swap is unaffected. A session already in
flight keeps a baseline written by the old code, where the code has no
entry and a pre-existing occurrence would count as introduced; baselines
expire after 7 days, and deleting the directory makes it immediate. A
vault whose files are UTF-8 — every vault measured here — sees no change
at all.

## Amendment 2026-08-04e — Every requirement table of the bound section is read (Accepted)

### Context

Issue #37, residual 3 of amendment 2026-08-04d. `bound_tables` takes the
first table of the bound section whose header has the requested column
count and stops at the blank line below it, so a REQ file that writes its
requirements as several tables under `###` subheadings inside one
`## Kontext` contributes its first table and nothing else. Amendment
2026-08-04d reports that loss; it does not repair it.

Measured across the vault roots on this machine — **ten** now, not the
nine of the last four amendments: `Documents/tmp/BA_Noah` has appeared
and loses none of its 36 rows. 378 requirement rows sit in a bound
section, **78 of them never reach the graph**, all in homelab, in six
files. The consequence reads as the opposite defect: homelab's export
carried 69 `export-unresolved-requirement` findings naming 65 identifiers
as non-existent, and `ANF-BAK-017` … `-040` do exist, in lines the
exporter never read.

### Options

**Which tables of the bound section are ingested.**

- **A — a section map plus `req_tables`.** Ingestion would share the
  validator's table reader with the loss report of amendment 2026-08-04d,
  making the two exact complements by construction. Built and measured;
  rejected. It yields the identical graph (162 requirements, 427
  relations for homelab, requirement and edge sets equal to B's) at fifty
  changed lines instead of six, and it adds 13 findings across three
  vaults that issue #37 never asked for. It also mixes two fence readers:
  the section map masks with `fenced_mask` while `req_tables` switches
  its own mask off when a block is left open, and a file with an unclosed
  fence then ingests a quoted example table as requirements — verified on
  a probe, `REQ-XXX-900` from a ` ```markdown ` block.
- **B — `bound_tables` reads every table of the bound section
  (chosen)**, behind an `every` keyword that the REQ call passes and no
  ARC call does.

**Which rows of those tables are requirements.** Unchanged, and this is
what makes B safe: the second cell must carry three digits, the predicate
`Vault.req_index` already uses. A five-column revision history in the
same section carries a date there and contributes nothing.

**Whether ARC follows.** No. PMDE's main-module template heads its
two-column submodule table with the title its file template gives the
four-column allocation table, so two bindings resolve to one section
name, and an allocation row has no row-level predicate of its own — a
second four-column table in that section would invent allocations. The
asymmetry is now written into `binding_discovery.step_3` with its reason.

### Decision

B, scoped to REQ. `bound_tables` gains `every=False`; with it set, a new
`## ` heading no longer ends the scan and the blank line below a table
ends that table rather than the search — which is what GFM means by "the
table is broken at the first empty line" (tables extension, verified
against the specification for this change).

### Design points

- **The plan was discarded by its own review.** A fresh-context
  adversarial review produced nine findings. Six were confirmed, three
  refuted against the corpus. Two of the confirmed ones (the mixed fence
  readers, and `hline is None` making the planned report unimplementable)
  killed option A, and the reviewer's alternative — six lines instead of
  fifty — is what shipped. The one place it was not followed: it changed
  `bound_tables` for every caller, which would have widened ARC too.
- **The column count is the binding, the row predicate is the filter.**
  Reading more tables is only safe because these are two gates and not
  one. The Shadowed fixture is the guard for exactly this and is now
  built the way homelab writes: a revision history, then two requirement
  tables separated by a `###` subheading.
- **`###` is not a section boundary.** Only `## ` moves the binding, so
  the subheadings homelab uses to layer its requirements never end it.
  Asserted by the fixture rather than left to the reader.
- **The finding message stated the defect as if it were a rule.** "The
  export reads the first five-column table of the bound section and no
  other" was true when amendment 2026-08-04d wrote it and false the
  moment this change landed. It now names the rule that survives.
- **Nothing was gained by widening the header floor.** Ingestion keeps
  `len(cells) == ncols` while the loss report keeps `>= 5`, so a
  six-column table in a bound section is not read *and* is reported. The
  asymmetry is deliberate: it is the shape in which "nothing is silent"
  and "column roles are positional" can both hold.

### Accepted residuals (documented, not solved)

1. **A four-column table carrying requirement rows in the bound section
   is neither ingested nor reported.** The binding requires five columns
   and the loss report's floor is five, so nothing sees it. Pre-existing
   and unchanged by this fix; zero occurrences across the ten roots.
2. **An unclosed fence can still produce a false loss finding.**
   `req_tables` switches its mask off when a block is left open, so the
   report can name a quoted example row that ingestion correctly refused.
   Pre-existing from amendment 2026-08-04d; this change can only shrink
   it, because the set of ingested lines grew.
3. **ARC still reads the first table of its bound section.** A second
   allocation table under one `## Zuordnung und Verifikation` is silently
   not read — the ARC counterpart of the defect just repaired for REQ.
   `_report_unbound` does not see it either, since both tables sit in a
   bound section. Not measured on this corpus.
4. **A five-column table whose second column happens to hold three
   digits becomes requirements.** Same predicate the validator's
   requirement index uses, so the two tools agree about it; the risk is
   real and unmeasured, because no such table exists in any bound section
   here.
5. **The 34 rows under sections nativclaw's templates do not declare stay
   out of the graph.** They are reported, which is issue #34's answer,
   and reading them would mean abandoning the section title as the
   address.

### Realization

- `export_traceability.py` — `bound_tables` gains `every=False` and two
  branches under it; the REQ call in `build_graph` passes `every=True`;
  `_report_unexported_rows` keeps its shape and loses the sentence that
  described the old ingestion rule
- `vault_schema.json` — `binding_discovery.step_3` rewritten per domain
  with the reason the two differ; `unbound_table` restated for what the
  REQ rule still names
- `tests/run.sh` — the Shadowed fixture rebuilt as homelab's shape and
  flipped from asserting the loss to asserting the read, plus the `###`
  subheading and the revision-row counter-assertion; the export vault's
  graph count moves from `5 4 15` to `7 4 15`; 210 to 211 assertions
- `00_documentation_file_creation_and_conventions.md` — one sentence, so
  an author can read the rule where the conventions are, not only in the
  schema

Measured after the change, all **ten** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts:

| vault | requirements | findings | gone | new |
| --- | --- | --- | --- | --- |
| template | 3 → 3 | 0 → 0 | 0 | 0 |
| homelab | **84 → 162** | 137 → 53 | 70 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 0 → 0 | 31 → 31 | 0 | 0 |
| PMDE | 93 → 93 | 18 → 18 | 0 | 0 |
| photon | 0 → 0 | 0 → 0 | 0 | 0 |
| htwsaar | 0 → 0 | 1 → 1 | 0 | 0 |
| realitypatches | 0 → 0 | 0 → 0 | 0 | 0 |
| verdantia | 0 → 0 | 1 → 1 | 0 | 0 |
| Archiv/Bachelor_Bruder | 0 → 0 | 7 → 7 | 0 | 0 |
| tmp/BA_Noah | 0 → 0 | 7 → 7 | 0 | 0 |

Nine of ten byte-identical; the tenth is the vault the issue was filed
for. Not one requirement is lost anywhere. homelab's 70 vanished findings
are its 25 `export-unbound-table` — the rows they named are in the graph
now — and 59 of its 69 `export-unresolved-requirement`. The remaining 10
are true: `ANF-TSC-006/007/008`, `ANF-YTD-007/008/010` and `ANF-SPO-012`
are named by allocation rows and written in no requirements file. That is
a gap in the vault, and the export is now able to say so without also
being wrong about 59 others. Export runtime, median of five: homelab
0.166 → 0.174 s, PMDE 0.122 → 0.128 s, nativclaw 0.120 → 0.122 s.
`tests/run.sh` at 211 assertions, 0 failures.

What proves the change is the runtime check. Against the real homelab
vault the exporter now prints `requirements: 162 proven: 91 not proven:
71` and `relations: 427 findings: 53`, `ANF-BAK-040` appears in
`traceability_requirements.csv` with its acceptance criterion, and no
`export-unbound-table` finding remains in the report.

## Amendment 2026-08-04d — The exporter reports the requirement rows it never read (Accepted)

### Context

Issue #34, residual 4 of amendment 2026-08-04b. `_report_unbound` is
called from the ARC loop of `build_graph` and from nowhere else, so a
requirement table the export did not read leaves no trace at all. That
contradicts `table_bindings.binding_discovery.unbound_table` ("an empty
graph is never silent") and this module's own docstring ("a table in no
recognised section … is a row in the export, never an absence from it").

Two corrections to that residual, both measured: `REQ_persona_voice.md`
carries **seven** five-column tables and one two-column source map, not
six; and the file is not silent today — `export-no-scope` names it, one
of that vault's seven. What is silent is its 34 requirement rows.

Measured across the nine vault roots on this machine: 376 requirement
rows exist in REQ files, **112 of them never reach the graph**. 78 sit
in homelab, 34 in nativclaw; template, PMDE and Bachelor_Bruder lose
none of their 3, 93 and 34.

### Options

**What to report.**

- **A — extend the ARC check to REQ**, which is what the issue proposes
  and what this session first planned. Rejected on measurement, twice
  over. It reports 34 of the 112 rows: all 78 homelab rows sit *inside*
  the bound `## Kontext` section, in its second to tenth table, which
  `bound_tables` stops before and `sections_with_tables` never yields
  ("only the first table of a section binds"). It also says something
  false — "sits in no section this project's templates declare" is wrong
  whenever an incidental table merely precedes the requirement table in
  a section that is declared, and the bound REQ section is the prose
  section in all nine vaults, the one most likely to carry a glossary or
  a revision history. A two-column glossary above the requirement table
  is enough to trigger the false wording.
- **B — extend it to every ingested domain**, the issue's first delivery
  item read at face value. Rejected: 663 new findings across the same
  nine roots (PMDE 131, homelab 242, nativclaw 269, realitypatches 20,
  and one in the shipped template vault, which is under a hard
  `findings: 0` assertion). No binding exists for those seven domains,
  so "unbound" degenerates to "every table they carry". That is the
  shape amendment 2026-08-04b rejected as option E, and the argument
  survives the move from validator to exporter: an exporter finding
  never blocks a turn, but a report nobody can act on still trains its
  reader to skip the section.
- **C — report the requirement rows the graph does not contain
  (chosen).** Asked a row at a time, per table, anchored at the first
  lost row. It covers 112 of 112, it cannot make a false statement about
  a section, and it stays silent on a table that carries no requirement
  row at all.

**Where to ask it.**

- **D — after the `export-no-scope` return.** Rejected by measurement:
  **+0 findings across all nine roots**. Every REQ file of the nativclaw
  vault returns there, so the check would be inert on the one corpus
  that motivated the issue.
- **E — before it (chosen).** A file whose rows cannot be addressed is
  precisely a file whose rows are lost; reporting the scope and stopping
  answers a different question than the one asked.

### Decision

C and E. `_report_unexported_rows` is added beside `_report_unbound`,
reached from the REQ loop before the scope check, and it reuses
`req_tables` — the GFM table reader amendment 2026-08-04b added to the
validator. ARC keeps `_report_unbound` unchanged: a table is the right
unit where a whole table is bound by its section, and a row is the right
unit where the loss is per row.

### Design points

- **The obvious repair was rejected by measurement, not by argument.**
  Extending the ARC check reports 34 of 112 rows and misses every one of
  the six homelab files that lose the rest. The corpus signal was
  already there and pointing the other way: homelab's 69
  `export-unresolved-requirement` findings name 65 identifiers as
  non-existent, and `ANF-BAK-017` to `-040` do exist — in lines the
  exporter never reads. The export accuses the ARC side of naming
  requirements that are not there while quietly failing to read them.
- **A row cannot lie about a section.** The rejected wording is
  falsifiable by a two-column glossary; the shipped wording states a
  count and a cause. This also disposes of the empty-title case, where
  a table above the first heading rendered `table under '## '`.
- **The width floor sits on the header, not on the row.** GFM pads a
  short body row to the header's width (example 204, the rule
  `split_cells` already implements), so a four-cell row of a
  five-column table is a requirement row that would have been ingested
  had its table been read. Checking the row's own width instead would
  have skipped it — caught by a fixture, not by the corpus, which
  contains no such row.
- **The bound-line set became load-bearing.** Under option A it was
  decorative: `_report_unbound` only ever tests the one line per section
  that `sections_with_tables` yields, so including the body rows could
  not change an answer. Under C the body rows are exactly what is
  compared, which is why the set is built from header *and* row entries.
- **Two fence readers, one answer.** `req_tables` masks fences with the
  validator's `fence_blocks` while `bound_tables` uses the exporter's
  `fenced_mask`. They agree on all 956 Markdown files of the nine
  roots, and `req_tables` is asserted identical across the two tools the
  way `split_cells` already is, so a re-declared copy fails a test
  rather than drifting.
- **The code name stays `export-unbound-table`.** The vocabulary a
  consumer sees does not grow, the schema clause keeps the name it
  declares, and the two detection rules are written down under it.
- **The docstring was amended.** The issue quotes it as broken; leaving
  it as the strongest claim in the file while the file only half keeps
  it would have been the same defect in prose.
- **Reviewed adversarially before implementation, and reversed by it.**
  A fresh-context review produced thirteen findings. All thirteen were
  confirmed against the corpus or a fixture, none refuted, and two of
  them (the 78-row blind spot and the total-loss shape) discarded the
  approved plan in favour of option C. The reviewer's own draft was
  refined once: it dropped the short body row of scenario 15.

### Accepted residuals (documented, not solved)

1. **A table in an unbound section that carries no requirement rows is
   not reported.** nativclaw's two-column `## Source map` is the case.
   Deliberate: it is what amendment 2026-08-04b's option E rejected, and
   nothing is lost from the graph by leaving it out.
2. **A REQ template that declares no table amplifies.** The exporter
   already reports `export-no-binding` once; every requirement table in
   the vault then also reports its rows as lost, which is true and
   redundant. No vault here has that shape — all nine bind `req_table` —
   so it is unmeasured.
3. **This reports the loss; it does not repair it.** The 112 rows are
   still absent from the graph, and the 69 `export-unresolved-requirement`
   findings they cause are still emitted. Reading every five-column
   table of the bound section instead of the first is a change to
   ingestion, with its own risk of reading a revision history as
   requirements, and belongs in its own issue.
4. **A vault carrying both a `REQ` and an `ANF` folder loses one of them
   without any finding.** `resolve_roles` keeps the first by
   `setdefault` and `build_graph` skips the other at `role is None`. Out
   of scope for #34; found by the same review.
5. **`_report_unbound` and `_report_unexported_rows` now answer the same
   schema clause with two rules.** That is written into the clause
   rather than hidden, but it does mean a future third domain has to
   decide which of the two it wants.

### Realization

- `export_traceability.py` — `_report_unexported_rows` added, reached
  from the REQ loop of `build_graph` before the `export-no-scope`
  return; `req_tables` imported from the validator; module docstring
  corrected to claim only what the exporter can prove
- `vault_schema.json` — `table_bindings.binding_discovery.unbound_table`
  rewritten with the two per-domain rules and the measurement,
  `unbound_table_scope` added for the seven exempt domains
- `tests/run.sh` — three fixtures in the export vault (undeclared
  section, undeclared section without a scope, requirement table behind
  a revision history in the bound section), the counter-assertions that
  the revision row and the bound table stay unreported, a German-twin
  comparison of finding codes, and `req_tables` in the shared-parser
  assertions; 203 to 210 assertions

Measured after the change, all **nine** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts. Re-measured after rebasing onto amendment
2026-08-04c, whose encoding reader changes how every file is read: the
numbers are unchanged.

| vault | findings before | findings after | new | gone |
| --- | --- | --- | --- | --- |
| template | 0 | 0 | 0 | 0 |
| homelab | 112 | 137 | 25 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 24 | 31 | 7 | 0 |
| PMDE | 18 | 18 | 0 | 0 |
| photon | 0 | 0 | 0 | 0 |
| htwsaar | 1 | 1 | 0 | 0 |
| realitypatches | 0 | 0 | 0 | 0 |
| verdantia | 1 | 1 | 0 | 0 |
| Archiv/Bachelor_Bruder | 7 | 7 | 0 | 0 |

The 32 new findings account for exactly the 112 rows counted above — 78
in homelab over 25 tables, 34 in nativclaw over 7. Nothing disappears
anywhere, and the shipped template vault still exports 3 of 3
requirements proven with no findings, which is the assertion a visitor
is most likely to check.

A note for whoever deploys this: no finding code was added or renamed,
and the exporter still never changes its exit code over a finding. A
vault whose requirement tables all sit first in the bound section — five
of the nine here — sees no change at all.

## Amendment 2026-08-04f — Two folders meaning one domain is a finding, not a choice (Accepted)

### Context

Issue #38, residual 4 of amendment 2026-08-04d, found by the adversarial
review of issue #34 and out of scope there. `resolve_roles` keeps the
sorted-first abbreviation via `roles.setdefault(role, abbr)`, and
`build_graph` then skips every file of the other folder at `if role is
None: continue` — the branch that exists for domains nobody declared.
Neither `export-unknown-domain` (an abbreviation the alias map does not
know) nor `export-domain-mismatch` (a file's name inside its folder) has
anything to say about it.

Measured on a copy of the shipped template vault with a second
requirements folder placed beside its own: `requirements: 3 proven: 3`,
`relations: 14`, `findings: 0` becomes `requirements: 3 proven: 0`,
`relations: 8`, `findings: 6` — and all six blame the ARC and the TAE
file for naming identifiers "that do not exist". The one place that is
right about the vault, the requirements folder that was dropped, appears
nowhere in the report.

Zero of the **eleven** vault roots on this machine carry the shape today.
The way to acquire it is a translation, and this repository's own
German→English migration is exactly that.

The letter `e` is skipped deliberately: PR #39 (issue #37) is open and
carries amendment 2026-08-04e, so taking `f` here keeps the two records
from colliding when both land.

### Options

**Which folder the graph keeps.**

- **A — the first in sorted order, and the choice is reported (chosen).**
- **B — the folder with more files.** Rejected. It moves every identifier
  of the export a second time, at whatever unrelated edit tips the count,
  and in a symmetric mid-translation state the sort decides anyway.
- **C — ingest both, each with its own prefix.** Closer than it looks:
  `expand_requirement_cell` never touches `req_abbr` in its body, it
  matches the prefix found in the cell against the index. But the index
  is built in `build_graph` from the single `req_abbr`, and widening that
  would write every already-translated requirement into the graph twice
  and report its untranslated twin as unallocated. The export would
  describe a larger vault than the one on disk.
- **D — refuse to export.** StrictDoc's answer for a duplicate UID
  (`sys.exit(1)`). Rejected here: this tool reports, it does not block.

Prior art measured against, because the situation is not new: Sphinx-Needs
logs a duplicate need ID as the suppressible warning `needs.duplicate_id`,
keeps the first and continues, and escalates only under `-W`; Doorstop
refuses a duplicate prefix at `doorstop create` but is silently
first-wins when a tree is read from disk, which is filed there as issue
#460 — a defect, not a design; DITA-OT and Sphinx i18n select a language
per build and never merge two variants into one namespace. Nobody keeps
the fuller container.

**Which shapes are the defect.** Both. Two abbreviations for one role
(`01_requirements_(REQ)` beside `01_Anforderungen_(ANF)`) and one
abbreviation twice (`03_architecture_(ARC)` beside
`03_Architektur_(ARC)`) — German and English spell ARC, IMP and REF
identically, so a vault mid-translation carries the second shape whether
anyone intended it or not.

### Decision

A, for both shapes, under one code. `export-duplicate-role`, once per
excluded folder, naming both folders, both ingestible file counts and the
prefix the graph is written with. The rule is: **one role, one folder.**

### Design points

- **The first rejection of B was wrong, and the record says so.**
  Sorted-first switches the identifier prefix of the whole export too —
  `REQ-BAT-*` to `ANF-BAT-*`, measured. What survives of the argument is
  when it switches: once, at the moment the author creates the second
  folder, and never again. A count-based winner switches a second time,
  triggered by an edit that has nothing to do with the decision.
- **The scan reads the vault root, not `Vault.domains`.** The index keys
  by abbreviation, so the same-abbreviation pair is already collapsed
  before any role is resolved. `domain_dirs` re-reads the root and sorts
  by name, which is also what makes the finding say the same thing on two
  machines.
- **The finding can name a pair it cannot choose within.** For two
  folders sharing one abbreviation the export reports which one it read
  and says plainly that the file system decided it. That is honest and it
  is not a fix; see the residuals.
- **The count is `build_graph`'s predicate, not a file count.** A name
  starting with the folder's own abbreviation, counted recursively, so
  the number in the message is the gap the graph actually has.
- **The vocabulary grew by one code, against 2026-08-04d's rule.** That
  amendment kept `export-unbound-table` rather than mint a second code
  for a related case. Here no existing code states the situation:
  `export-unknown-domain` is about an abbreviation the map does not know,
  and this one is known and duplicated. The alternative was to overload a
  code with a second meaning, which is worse for a reader than one more
  row in the legend.
- **The fixture's added folder carries a real five-column template.** The
  adversarial review caught this: with the stub template the
  unknown-domain fixture uses, `req_table` binds to nothing and the row
  assertions would pass because nothing at all was exported.

### Accepted residuals (documented, not solved)

1. **Which of two same-abbreviation folders reaches the graph is still
   readdir's decision.** `Vault.__init__` writes `self.domains[abbr] = s`
   in iteration order, so two machines with the same content can export
   different graphs. The export now says so on every run; repairing it
   means changing the validator's index, which the stop gate depends on.
   Its own issue.
2. **The kept folder's templates decide the bindings.** `discover_bindings`
   reads `template_files(vault.domains[abbr])` of the winner, so a stub
   folder that wins can leave `req_table` bound to nothing and cost more
   than its own file count. The finding carries both counts and cannot
   express that second-order loss.
3. **Unmeasured on the corpus.** None of the eleven roots carries either
   shape, so the fixture and the constructed vault are the only evidence
   there is. The measurement below is a proof of absence, not of effect.
4. **Files of the excluded folder that would have been reported as
   `export-domain-mismatch` disappear with it.** They were never in the
   graph; they are no longer named either, and the count does not include
   them.

### Realization

- `export_traceability.py` — `domain_dirs`, `ingestible_count` and
  `duplicate_role_finding` added; `resolve_roles` iterates folders rather
  than `vault.domains` and reports both shapes; the module docstring
  gains the second exclusion reason
- `vault_schema.json` — `domain_aliases.duplicate_role`, with the rule,
  the two rejected alternatives and the prior art
- `tests/run.sh` — the `dup_req_folder` fixture builds the second
  requirements folder in both twins and the second architecture folder in
  the English one; seven assertions, two of which pin the decision rather
  than the fix and say so; 210 to 217 assertions
- `SKILL.md` — the finding enumeration an agent reads
- `00_documentation_file_creation_and_conventions.md` — one paragraph, so
  an author meets the rule where the conventions are

Measured after the change, all **eleven** vault roots on this machine,
old code and new code against one disk state at the same moment, as
finding sets rather than counts:

| vault | requirements | edges | findings | gone | new |
| --- | --- | --- | --- | --- | --- |
| template | 3 → 3 | 14 → 14 | 0 → 0 | 0 | 0 |
| homelab | 84 → 84 | 264 → 264 | 137 → 137 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 0 → 0 | 8 → 8 | 31 → 31 | 0 | 0 |
| PMDE | 93 → 93 | 150 → 150 | 18 → 18 | 0 | 0 |
| photon | 0 → 0 | 0 → 0 | 0 → 0 | 0 | 0 |
| htwsaar | 0 → 0 | 0 → 0 | 1 → 1 | 0 | 0 |
| realitypatches | 0 → 0 | 0 → 0 | 0 → 0 | 0 | 0 |
| verdantia | 0 → 0 | 0 → 0 | 1 → 1 | 0 | 0 |
| Archiv/Bachelor_Bruder | 0 → 0 | 0 → 0 | 7 → 7 | 0 | 0 |
| tmp/BA_Noah | 0 → 0 | 0 → 0 | 7 → 7 | 0 | 0 |
| tmp/mechdocs-test/testproject | 2 → 2 | 9 → 9 | 0 → 0 | 0 | 0 |

Eleven of eleven identical, which is the expected result and the reason
the fixture had to be built: no vault here carries the shape. On the one
that was constructed to carry both shapes, the graph is identical
(3 requirements, 8 edges) and the finding set grows by exactly two rows,
one per excluded folder.

What proves the change is the runtime check. Against that vault the
exporter prints, beside the six findings it printed before:

    '01_requirements_(REQ)' (1 file) and '01_Anforderungen_(ANF)' (1 file)
    are both the REQ domain of this vault - only '01_Anforderungen_(ANF)'
    is in the graph; an identifier spelled REQ-* therefore resolves to
    nothing, because the graph is written with ANF-*.

    '03_Architektur_(ARC)' (1 file) and '03_architecture_(ARC)' (1 file)
    are both the ARC domain of this vault - only '03_architecture_(ARC)'
    is in the graph; which of the two the graph reads is the order the
    file system returns them in, and no rule fixes it.

The shipped template vault still exports 3 of 3 requirements proven with
no findings. `tests/run.sh` at 217 assertions, 0 failures.

A note for whoever deploys this: one finding code was added,
`export-duplicate-role`, and nothing was renamed. The exporter still
never changes its exit code over a finding, and a vault with one folder
per domain sees no change at all.


## Amendment 2026-08-04g — One abbreviation, one folder, chosen by a rule (Accepted)

### Context

Issue #42, residual 1 of amendment 2026-08-04f. `Vault.__init__` writes
`self.domains[abbr] = s` while iterating `self.root.iterdir()`, so two
folders carrying one abbreviation — `03_architecture_(ARC)` beside
`03_Architektur_(ARC)` — collapse to the one the file system happens to
return last. Python states the order is arbitrary; on APFS it is hash
order, on ext4 insertion order. Two machines holding the same content
therefore index different folders, and the export measured `objects: 8`
under one creation order and `objects: 7` under the other.

German and English spell **ARC, IMP and REF identically**, so a vault
halfway through a translation carries three such pairs. This repository's
own German→English migration is exactly that state.

The exporter has reported the pair as `export-duplicate-role` since
2026-08-04f and says in the same breath that "no rule fixes it". This
amendment is that rule.

### Options

**Which of two same-abbreviation folders is the vault's.**

- **A — the first in sorted order**, the rule 2026-08-04f states for the
  two-abbreviation shape. Rejected here, and the measurement is why:
  `Architektur` sorts before `architecture` because a capital letter
  does, so in all three identically spelled abbreviations the folder a
  translation is moving *away from* wins — and a leftover folder holding
  nothing but templates wins over the folder holding the vault. Measured
  on a copy of the shipped template vault with a template-only German ARC
  folder beside the real one: `requirements 3 proven 3, relations 14`
  becomes `proven 0, relations 6`, with no finding beyond the one line
  that names the pair. Deterministically choosing the empty folder is
  worse than choosing arbitrarily.
- **B — the folder with more files.** Rejected in 2026-08-04f because it
  moves every identifier of the export a second time at whatever
  unrelated edit tips the count. The first half of that argument does not
  reach this shape: the same amendment states that one abbreviation twice
  "leaves the identifiers alone". The second half does — a count-based
  winner still oscillates on an ordinary edit.
- **C — the first in sorted order among the folders that carry at least
  one `ABBR_*.md` file; the first in sorted order overall when none does
  (chosen).** The predicate is `build_graph`'s own ingestion rule, which
  the exporter already counts with (`ingestible_count`). It flips only
  when a folder gains its first or loses its last content file — twice
  over a whole migration, at the two moments that mean something — so it
  buys B's outcome without B's instability.
- **D — index both and merge their files.** Rejected: it writes every
  already-translated file into the graph twice and reports its
  untranslated twin as uncovered, which is 2026-08-04f's option C one
  layer down.

**What the losing folder still costs.** `templates_for` reads the
templates of the indexed folder alone, so every file of the *other*
folder is checked against the winner's required sections. In the shape
this vault will actually have — German templates winning, English files
below the other folder — that is a `template-sections` ERROR on correct
files, measured as `0 errors → 1 error` on the template vault, and it
would both fail the CI audit and block the stop gate. Reading the
templates of every folder of an abbreviation removes the class outright:
`check_sections` already scores a file against each template of its
domain and keeps the best, so a union can only be more permissive.

**Severity of the new finding.** WARN. The conventions call two folders
a legitimate transitional state during a translation, and this project's
line is that a check which cannot tell a mistake from an intention
reports rather than blocks. An ERROR would also fail the CI audit
throughout this repository's own migration.

### Decision

C, plus the template union, plus a new vault-wide WARN
`domain-duplicate-folder`, one per folder that is not the vault's,
naming both folders, which one the vault reads and why, and what reading
only it costs. The rule is: **one abbreviation, one folder — the vault's
is the first in sorted order among those that carry files of that
domain.** The sort key is the NFC-normalized folder name with the raw
name as tie-break, because macOS stores a name decomposed where Linux
stores it composed, and folders reached through a symlink are deduped by
their resolved path.

### Design points

- **The qualifier is what the adversarial review bought.** The plan under
  review said sorted-first, full stop — the rule 2026-08-04f states for
  the other shape. The review implemented it, measured it and produced
  the stub-wins case; the qualifier and the template union are both its
  findings, and both are in the fixture as assertions rather than as
  prose.
- **The template union removes an ERROR the rule would have caused.**
  `templates_for` used to read the indexed folder alone. Deterministic
  selection would then have measured every English file against the
  German templates in exactly the three abbreviations both languages
  spell alike — `template-sections` on correct files, which fails the CI
  audit and blocks the stop gate, since a newly created file has an empty
  HEAD baseline and every ERROR on it is net-new. `check_sections`
  already keeps the best-matching template of a domain, so a union can
  only be more permissive.
- **The name index is sorted for the same reason the folder index is.**
  `_build_name_index` walked `rglob` unsorted and `duplicate-basename`
  names `paths[0]`, so the finding named a different file depending on
  the file system's order — including in the shipped vault, where two
  files are called `README`. Measured across the eleven roots, this is
  the only behaviour that changed at all: four vaults report the same
  collisions on a different, now sorted-first, member of each pair.
- **A symlink is not a second folder.** `is_dir()` follows a symlink, so
  a compatibility link left behind by a rename would have been indexed
  and reported as a pair, telling the author to delete a folder that does
  not exist. `rglob` does not descend into it either, so there is no loss
  to report. Deduped by resolved path, per abbreviation: two
  abbreviations sharing one directory remain two names for one folder and
  stay visible as `export-duplicate-role`.
- **`has_domain_files` asks a yes/no, not a count.** That is what
  separates it from option B: a count changes at whatever unrelated edit
  tips it, while whether a folder holds the domain at all changes twice
  over a whole translation, at the first file moved in and the last one
  moved out.
- **One index, two tools.** `export_traceability.domain_dirs` existed to
  read the vault root a second time, because `Vault` had thrown the
  second folder away before any role was resolved. It now returns the
  Vault's index. The `OSError` fallback it carried was unreachable —
  `Vault.__init__` iterates the same root without a guard, so an
  unreadable root already exits 2 — and its removal closes the window in
  which the two reads could disagree.
- **WARN, and vault-wide.** The finding has no per-file HEAD baseline and
  therefore never enters the stop gate's blocking set. It is appended
  first in `validate_vault_wide` so it survives `hook_stop`'s 15-line cut
  of the advisory block: it is the explanation for the
  `duplicate-basename` and `orphan` findings a second domain folder
  produces around it.

### Accepted residuals (documented, not solved)

1. **`hook_post` still says nothing at the moment the second folder
   appears.** It reports per-file findings only — vault-wide checks are
   not run there at all — so the author learns about the pair at turn end
   or in the next full audit. Running the vault-wide pass on every write
   is the cost that decision was made against, and it has not changed.
2. **The exporter's binding discovery still reads one folder.**
   `discover_bindings` calls `template_files(vault.domains[abbr])`, so
   residual 2 of 2026-08-04f survives on the export side: the chosen
   folder's templates decide which section carries which table. It is now
   at least the folder holding the domain's files. Widening it would
   change what the graph binds, which is not this issue's question.
3. **`is_vault_root` counts folders, not abbreviations.** A directory
   with two real domains and one duplicate clears the `>= 3` bar. It
   predates this change and is unchanged by it; naming it here is the
   first time the shape is describable at all.
4. **Three or more folders under one abbreviation cost 2N−2 lines.** Each
   tool reports once per folder that is not the vault's. No vault has
   ever carried more than two.
5. **Still unmeasured on the corpus.** None of the eleven roots carries
   the shape, so the fixture and the constructed vault remain the only
   evidence that the rule does anything. The corpus measurement is a
   proof of absence.

### Realization

- `validate_vault.py` — `dir_sort_key`, `has_domain_files` and
  `pick_domain_dir` added; `Vault.__init__` keeps `domain_dirs` and
  derives `domains` from it; `templates_for` reads every folder of an
  abbreviation and labels a template with its folder where there is more
  than one; `_build_name_index` sorted; `check_domain_folders` added and
  called first from `validate_vault_wide`
- `export_traceability.py` — `domain_dirs` returns the Vault's index;
  `duplicate_role_finding` states the rule where it used to state its
  absence; the now-unused `DOMAIN_DIR_RE` import dropped
- `tests/run.sh` — the `dup_vault` fixture builds two ARC folders with
  DIFFERENT templates in both creation orders, plus the stub and symlink
  shapes; eight assertions, 217 to 225
- `vault_schema.json`, `SKILL.md`,
  `00_documentation_file_creation_and_conventions.md` — the rule where an
  agent, a reader and an author each meet it

Measured old code against new code, all **eleven** vault roots on this
machine, one disk state, as finding sets rather than counts:

| vault | findings old → new | gone | new |
| --- | --- | --- | --- |
| template | 9 → 9 | 0 | 0 |
| homelab | 123 → 123 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 736 → 736 | 2 | 2 |
| PMDE | 500 → 500 | 0 | 0 |
| photon | 9 → 9 | 0 | 0 |
| htwsaar | 9 → 9 | 1 | 1 |
| realitypatches | 28 → 28 | 0 | 0 |
| verdantia | 9 → 9 | 0 | 0 |
| Archiv/Bachelor_Bruder | 100 → 100 | 3 | 3 |
| tmp/BA_Noah | 340 → 340 | 3 | 3 |
| tmp/mechdocs-test/testproject | 9 → 9 | 0 | 0 |

Every one of the nine differences is the same `duplicate-basename`
finding naming the sorted-first member of its pair instead of whichever
`rglob` reached first. No finding was added or lost anywhere, and no
vault carries a duplicate domain folder — which is why the constructed
vault below is the evidence that the rule works.

What proves the change is the runtime check. On a copy of the shipped
template vault with a template-only `03_Architektur_(ARC)` beside the
real folder, the validator prints:

    WARN .../03_Architektur_(ARC) [domain-duplicate-folder]
    '03_Architektur_(ARC)' and '03_architecture_(ARC)' both carry the ARC
    domain of this vault. '03_architecture_(ARC)' is the one this vault
    reads: the first in sorted order among the folders holding ARC_*
    files. [...] One domain, one folder: finish the translation, or
    remove the folder this vault no longer writes to

and with `Path.iterdir` forced into the adverse order, the two code
versions part company:

    old code, reversed readdir -> ARC folder used: 03_Architektur_(ARC)
    new code, reversed readdir -> ARC folder used: 03_architecture_(ARC)

The fixture shows the same thing from the other side: five of its eight
assertions fail against the code before this branch, and the two
creation orders report the `template-sections` ERROR on the German file
in one order and on the English file in the other — issue #42's
`objects: 8` versus `objects: 7`, reproduced.

The shipped template vault stays at 0 errors and 9 warnings and still
exports 3 of 3 requirements proven with no findings. `tests/run.sh` at
225 assertions, 0 failures.

A note for whoever deploys this: one finding code was added,
`domain-duplicate-folder`, nothing was renamed, and no severity changed.
A vault with one folder per domain sees exactly one difference — a
`duplicate-basename` finding may name the other file of a pair it was
already naming.

## Amendment 2026-08-05 — The gate says which code stopped firing (Accepted)

### Context

Issue #26, residual 2 of amendment 2026-08-01. `hook_stop` compares each
finding of the current run against the file's git HEAD baseline and
blocks on `cur[f.code] > base.get(f.code, 0)`. The loop iterates the
findings that *exist*. A code standing in the baseline that produces no
finding at all is therefore never reached by it — not to block, and not
to be mentioned either, because the pre-existing branch below it
(`elif f.sev == "ERROR"`) is equally unreachable for a code that no
longer fires.

Reproduced before touching anything: an ARC file committed with `##
Kontext` carries `template-sections` in its baseline; the session repairs
the heading; the stop gate emits a report that does not contain the code,
the file, or any hint that something changed. The session ends green and
silent.

That is correct for the case it was built for — repairing a defect must
not block — but the same silence covers a change that makes a check stop
*reaching* the file. Amendment 2026-08-01 removed the concrete instance
(a stray fence marker silencing `req-nnn`); this is why that instance was
invisible rather than merely wrong, and the blind spot survived the fix.

### Options

**Whether the report blocks.**

- **A — block, treating a vanished code as suspicious until explained.**
  Rejected. From counts alone a repaired defect and an unreachable check
  are the same absence, and this layer's standing rule is to report
  wherever it cannot tell a mistake from an intention — the same ground
  on which the vault-wide findings never block. Blocking would punish
  precisely the session that fixed the ERROR the gate asked it to fix.
- **B — report (chosen).** What the issue argues for.

**What counts as "stopped firing".**

- **C — every decrease, `base > cur`.** Rejected on measurement.
  `link-unresolved` is an ERROR under `strict=True` (`check_links`), the
  baseline and the stop run are both strict, and links resolve against
  the *worktree*. A session that creates any link target anywhere lowers
  the count in a file nobody edited: measured `{'link-unresolved': 2}` →
  `{'link-unresolved': 1}` on a committed file whose content was
  untouched. Under the phased creation order that is the ordinary
  mid-pass state, so the channel would be noise on arrival — the same
  noise the aggregated link WARN of amendment 2026-07-28f exists to
  suppress one layer up.
- **D — full disappearance only, `n → 0` (chosen).** Asks a yes/no
  instead of comparing counts, for the reason `has_domain_files` does:
  a count changes at whatever unrelated edit tips it, while "does this
  code still fire" is the question the session can actually answer.

**Where the report is emitted.**

- **E — into `summary` before the blocking branch**, so a blocking
  session sees it too. Rejected: `summary` is appended to the block
  reason, and a block reason carries one obligation. A second,
  non-blocking observation inside it spends one of the two allowed block
  attempts on legacy drift — the same finding an adversarial review made
  about vault-wide ERROR lines in amendment 2026-07-28f.
- **F — after the blocking branch, beside the vault-wide advisory
  (chosen).** The branch returns before reaching it, so the report is
  structurally incapable of entering a block reason. No rule has to be
  remembered for it to hold.

**Which fixture proves it.**

- **G — reuse the existing encoding-repair session (`SIDF`)**, which
  already contains a real `1 → 0`. Rejected on measurement: that file's
  baseline carries three codes, not two — `{'encoding-not-utf8': 1,
  'frontmatter-missing': 1, 'template-sections': 1}` — and
  `frontmatter-missing` disappears as an artifact of the misread rather
  than as a fix. The fixture would also bind issue #26's only positive
  test to issue #31's fixture, so re-committing that file as UTF-8 would
  silently retire it.
- **H — an own committed file and an own session (chosen).** Eight lines
  in the git-backed identity vault, which already exists.

### Decision

B, D, F and H. `hook_stop` collects, per touched file, the baseline codes
with `cur[c] == 0`, and appends one line per file to the non-blocking
session report after the blocking branch, capped at 15 lines like the
vault-wide block. `SIDF` keeps its original assertion in a form that
still fails against the regression it was written for.

### Design points

- **Neither the header nor the lines begin with `ERROR` or `WARN`.** A
  rendered `Finding` and a code being reported as gone would otherwise be
  indistinguishable to a reader and to every assertion in the suite,
  which is how the old `SIDF` assertion came to forbid exactly what this
  issue requires.
- **The assertion that broke is the interesting one.** `SIDF` asserted
  `! contains "$fout" "encoding-not-utf8"` — the repaired file must not
  still be reported as non-UTF-8. Since this change the code name also
  appears in the report of what stopped firing, so the assertion had to
  move to the finding's *message* (`this vault is UTF-8`), which no
  disappearance line carries. It was not anchored to `^ERROR` instead,
  although that was the first proposal: a blocking stop hook emits one
  `json.dumps` line with escaped newlines, where `^` can never match, so
  the anchored form would have passed vacuously on the issue #31
  regression it exists to catch. The adversarial review found this; it
  was measured against a real block line before the wording changed.
- **Three wrong implementations, three distinct assertions that kill
  them.** Verified by mutation, each run against the full suite: the
  feature removed entirely fails the two positive assertions; echoing the
  whole baseline fails the unchanged-file control (`SIDR`); reporting
  decreases as well as disappearances fails the partial-decrease control
  (`SIDH`). A negative control that no mutant can kill is decoration, and
  the first version of `SIDH` was exactly that.
- **The partial-decrease fixture asserts its own baseline first.**
  `hook_post` validates the HEAD *content* against the *current* file
  set, so a link target created before the baseline is taken never counts
  as unresolved in it. Written in the natural order — create the target,
  then touch the file — the baseline is already 1 and the fixture proves
  nothing. It now pins `"link-unresolved": 2` in the state file before
  creating anything.
- **No `try/except` shield, unlike the vault-wide block.** The collection
  is dict arithmetic on data the loop has already loaded plus the same
  `relative_to`-with-fallback that both `hook_post` and `Finding.render`
  perform on every line. It adds no I/O and therefore no new way for an
  advisory to crash the gate into exit 2, which would release it.
- **The wording asks, and says why the answer is not free.** "say which
  of them you fixed; a check that became unreachable looks exactly the
  same" — a bare list invites the reader to assume the good case, which
  is the assumption that made this defect invisible for the whole of
  amendment 2026-08-01.

### Accepted residuals (documented, not solved)

1. **The report may reach nobody at all** — issue #44. The current hook
   documentation states that plain stdout of a Stop hook exiting 0 goes
   to the debug log and is shown neither in the transcript nor to Claude.
   `hook_stop` emits its entire session report that way, and
   `stop_gate.sh` passes it through. If that is accurate, this amendment
   adds one more line to a channel that already carried the fail-open
   ERROR report and the vault-wide advisory unread. It is deliberately
   not fixed here: the defect predates issue #26, affects every advisory
   the gate emits, and amendment 2026-07-28f recorded the opposite as a
   verified fact — which means the question needs a live probe, not a
   third reading of the docs.
2. **Deletion, rename and move stay invisible.** A file deleted this
   session is skipped by `if not path.exists(): continue`; a renamed one
   arrives under a new key, has no blob at HEAD, and is recorded as
   `new: True` with an empty baseline. Neither operation fires the
   PostToolUse hook at all, whose matcher is `Edit|Write|MultiEdit`. The
   likeliest ways to make a check unreachable are therefore still the
   ways this report cannot see, and `id-vanished` remains the only signal
   for the identifier half of it.
3. **The baseline is HEAD, not the start of the session.** In a dirty
   worktree — an unpushed branch, a Syncthing peer mid-sync — the first
   touch of a legacy file reports every code an *earlier* session already
   repaired as though this one had done it. The same baseline already
   carries the blocking decision, so this is a property of the ratchet
   rather than of this report, but the report is the first thing to state
   it out loud.
4. **A code can disappear for a reason that lies in another file.**
   `Vault.templates_for` reads the templates of every folder of an
   abbreviation, so creating a second domain folder can retire
   `template-sections` in a file nobody edited; `verifies-unknown-req`
   depends on the worktree's requirement index the same way. Choosing
   `n → 0` removes the frequent instance of this class, not the class.
5. **Counts are not the only possible signal.** Whether a check still
   *reached* the file is mechanically knowable — `check_sections` returns
   early when a domain has no readable template, and that is one of the
   real unreachability paths. Carrying a reachability flag out of the
   checks would answer the question this report can only ask, and it
   costs a return-value change in `check_sections` and `check_req_table`.
   Out of scope under "minimum change"; named here so the next reader
   does not have to rediscover that counts were a deliberate floor.
6. **Only files in `touched` are examined**, which is the secondary half
   of issue #26 and unchanged: an edit to a REQ file that invalidates a
   `verifies:` entry on a TAE file still surfaces only in the next full
   run.

### Realization

- `validate_vault.py` — `hook_stop` collects `resolved` per file and
  emits it after the blocking branch; nothing else changed, and the CLI
  is untouched (the shipped template vault stays at 0 errors and 9
  warnings)
- `tests/run.sh` — two committed files in the identity vault
  (`ARC_Resolved.md`, `ARC_Linker.md`), sessions `SIDG` and `SIDH`, the
  unchanged-file control on `SIDR`, the naming assertion on `SIDF` and
  its rewritten encoding assertion; 226 to 232 assertions
- `SKILL.md` — the enforcement section names the new report line

Observed at the real entry point, on a throwaway repository whose HEAD
carries the defect:

    baseline recorded from git HEAD: {'codes': {'template-sections': 1}, 'new': False}

    vault validator session report:
    codes that stood at HEAD and did not fire this session (say which of
    them you fixed; a check that became unreachable looks exactly the same):
    00_documentation/01_projectvault/03_architecture_(ARC)/ARC_Demo.md [template-sections]

The same session against the code before this branch prints an advisory
block about a stub and nothing else.

## Amendment 2026-08-05b — The stop report goes where someone reads it (Accepted)

### Context

`hook_stop` emitted its whole non-blocking session report with a bare
`print()`, and `stop_gate.sh` passed it through on exit 0. Plain stdout
of a Stop hook goes to the debug log; it is shown in no transcript and
added to no context. Five classes of output rode that channel: the
pre-existing-ERROR lines, the created-files note with its inbox warning,
the vault-wide advisory — whose only automatic channel this is, because
`hook_post` never shows vault-wide findings — the fail-open ERROR report
that exists precisely to surface unfixed ERRORs once the gate releases,
and, since amendment 2026-08-05, the codes that stopped firing. Residual
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

### Options

**Which channel carries the advisory report.**

- **A — `additionalContext`.** Rejected on the measurement: it reaches
  the model but continues the turn. A routine advisory about legacy
  drift would spend a model turn on work nobody asked for — the ground on
  which amendment 2026-07-27 rejected it, now with a number behind it.
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

### Decision

B, D, F and H. The report travels as `systemMessage`; the block keeps its
top-level `decision`/`reason` with the obligation alone and gains a
`systemMessage`; every section is capped at its source with ERROR lines
exempt. `stop_gate.sh` moves its crash message from stderr to a
`systemMessage` on stdout.

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

## Amendment 2026-08-05c — A replicated link is valid only where it was written (Accepted)

### Context

`~/.claude/skills/mechatronics-docs` is a symlink into this repository,
created by the command the README told people to run. `~/.claude/skills/`
is also a Syncthing folder root, and Syncthing replicates a symlink as an
entry of its own type carrying the target as a string (BEP v1,
`symlink_target`); it never follows or dereferences one on Linux. So the
authoring host's path travels to every peer, and on a host that does not
have that path the entry reaches nothing.

Nothing in this repository could see that. The skill listing shows the
entry either way — it is the invocation that fails — the validator had no
opinion about its own installation, and the install command was the thing
producing the state. Issue #40 ran seven days on the server before anyone
noticed, during which documentation was written against the conventions
file with none of this layer's checks running.

### Measured on the two hosts, 2026-08-05

`--check-install`, run through the repository path on each:

| host | entry | stored target | verdict |
| --- | --- | --- | --- |
| laptop | `/home/jerome/.claude/skills/mechatronics-docs` | `/home/jerome/Documents/innovation/…` | reaches this copy, exit 0 |
| userver | `/home/asteraa/.claude/skills/mechatronics-docs` | `/home/jerome/Documents/innovation/…` | DANGLING, exit 1 |

Same replicated byte string, two verdicts. That is the defect stated as a
measurement rather than as an argument.

### Options

- **A — A relative symlink.** Rejected on the layout. GNU documents a
  relative link as the answer when the link is visible from more than one
  machine, but only while link and target keep the same relative
  relation. Here the repository sits at `~/Documents/innovation/…` on one
  host and `/srv/data/sync/Innovation/…` on the other while the link
  stays in `~/.claude/skills/`, so the relative path differs too.
- **B — Replicate the skill directory instead of a link.** Rejected
  twice over. `tests/run.sh` derives the template vault three levels
  above the skill directory and, since the guard was made loud, fails
  when it is absent — a copy under `~/.claude/skills/` puts that
  assertion permanently red. And two replicated folders holding the same
  bytes drift with nothing to arbitrate between them.
- **C — Ship it as a marketplace plugin.** Real, and the right answer for
  someone who only consumes this template: the install lands outside the
  replicated directory and stores no host path. Rejected for the people
  who develop the skill, because a marketplace plugin is copied into
  `~/.claude/plugins/cache` keyed by the manifest `version` — a change in
  the working tree reaches no session until commit, push, marketplace
  update and a version bump.
- **D — Keep the absolute link, take the entry out of the replication per
  device, and let the validator say what the entry reaches (chosen).**
  The precedent was already on the affected machine: the neighbouring
  `omarchy` entry is an absolute symlink into a host-local path and has
  never caused trouble, because one line of `.stignore` keeps it from
  replicating.

An installer script was designed for D and rejected before implementation.
The adversarial review found it would write the link before the ignore
line — reproducing the defect in the opposite direction, since the new
link can be scanned before the pattern is loaded — depend on GNU-only
`mv -T` in a public template, and add a predictable temporary symlink plus
an append that follows a symlink, both inside a directory peers write to
(CWE-59, CWE-61). The one thing it would have bought, an ignore line that
does not depend on being typed per machine, it cannot buy: a new device
runs the installer after Syncthing has already scanned.

### Decision

D. `--check-install` reports what the personal entry reaches; the README
says the global entry is the special case and how to keep it out of a
replicated directory; `SKILL.md` stops naming one host's home path.

### Design points

- **`is_symlink()` before `exists()`, and this is the whole check.**
  `exists()` follows the link and is `False` for a dangling one — the
  exact state this exists for. Mutation: asking about existence first
  reports the server's dangling entry as absent and exits 0.
- **Readability is not the check.** An entry reaching a second clone of
  the template, or a replicated copy of the skill directory, opens
  `SKILL.md` fine and serves a version nobody is editing. The resolved
  target is compared against the validator's own directory. Mutation:
  dropping that comparison passes both wrong shapes.
- **Absent is exit 0.** Carrying the skill only inside the project is how
  this template ships, and a CI runner has no `~/.claude` at all. The
  cost is that an entry a Claude Code update removed
  (anthropics/claude-code#50052) also reports 0; the message names that
  case rather than guessing which one it is looking at.
- **The check is a flag on the validator, not a new program.** Stdlib
  only, writes nothing, and testable with the fixture pattern the suite
  already has — where a shell installer would have introduced the first
  code in this repository that writes into `$HOME`.
- **`${CLAUDE_SKILL_DIR}`, not the two-candidate probe.** The probe in
  this file's own hook definitions works because hooks are given
  `CLAUDE_PROJECT_DIR`. A bash call the model types from prose is not, so
  the probe would expand its first candidate to `/.claude/skills/…` and
  fall through to `$HOME/.claude/skills/mechatronics-docs` — the very
  path this amendment removes.
- **The suite's trap chain is replaced, not extended.** Bash substitutes
  the `EXIT` handler, so only the last one runs; the chain had already
  stopped removing two fixture directories. The new one lists all of them.

### Accepted residuals (documented, not solved)

1. **`.stignore` lives in no repository.** It is per device by design and
   is never replicated, so a rebuilt machine has no line, pulls the
   replicated entry again, and gets the same silent break. Syncthing
   writes no `.sync-conflict` copy for a symlink, so nothing marks the
   moment. `--check-install` detects the state; nothing prevents it.
2. **A removed entry and a deliberate project-only setup are the same
   observation**, and both exit 0. Distinguishing them needs a record of
   what the user intended, which this layer does not keep.
3. **Only the personal entry is checked.** The project-level workaround in
   place on the server — a gitignored `.claude/skills/mechatronics-docs`
   inside one unrelated project — is invisible to it.
4. **One host at a time.** Nothing in this repository knows the set of
   machines an entry is replicated to, so a green check on the machine you
   are sitting at says nothing about the other one.

### Realization

- `validate_vault.py` — `check_install()` and the `--check-install` mode
- `SKILL.md` — step 7 loses the hardcoded home path for
  `${CLAUDE_SKILL_DIR}`; the enforcement section names the check and when
  to run it
- `README.md` — the install section leads with "nothing to install in a
  project made from this template", gives `ln -sfn`, the anchored
  `.stignore` line for either folder root, and the check
- `tests/run.sh` — fixture 9, 245 to 251 assertions

Observed at the real entry point, the server before remediation:

    this copy:      /srv/data/sync/Innovation/obsidian-engineering-vault/…
    personal entry: /home/asteraa/.claude/skills/mechatronics-docs
      link target:    /home/jerome/Documents/innovation/…
      DANGLING - that path does not exist on this host.

Seven days of silence, printed in four lines.

## Amendment 2026-08-05d — Two declared relations get a source the templates teach (Accepted)

### Context

`vault_schema.json` declares eight typed relations. Two of them produce no
edge anywhere, and for two different reasons.

`test-object` is declared `export-driven` — "export_traceability.py reads
this entry" — and appears nowhere in the exporter. It was never built.

`contains` declares annotated links in the ARC body lists as its primary
source and the main-module submodule table as `authored_in_secondary`.
Only the secondary source is implemented. The template vault's one ARC
file uses the full template, which has no submodule table, so the
mechanism produces nothing there either.

Behind both sits the same authoring gap. The form the relations rest on,
`[[CMP_Battery_Pack]] (CMP-BAT-001)`, is defined in the conventions file
and in `link_annotation.example` and is shown by no template and no
domain README. A project working strictly from the templates never
writes an annotation and therefore never produces either relation.

### Measured on the template vault, 2026-08-05

    objects: 7  relations: 14  findings: 0
    Counter({'allocates': 3, 'evidence': 3, 'justified-by': 3,
             'verifies': 3, 'connects': 2})

`contains` = 0, `test-object` = 0. The claim in accepted residual 4 of
the export amendment — that the mechanism "is exercised only by the
template vault and the test fixtures" — is false for the template vault
in both cases, and false about the cause for `contains`, which does not
rest on annotated links at all today.

### Options

- **A — Implement both from annotated links, binding the TAE test-object
  to its `## Test Conditions` section.** Rejected. The section would have
  to be discovered from the project's own TAE template, and the only
  available discriminator is "the section containing a wikilink
  placeholder" — template body content, which nothing enforces. This
  file already rejected exactly that class of signal for the table
  bindings (`binding_discovery.why_not_the_header`): the section title is
  enforced by `check_sections`, template body text is not. A project
  adding one example link elsewhere in its TAE template loses every
  `test-object` edge with no finding anywhere. The templates also write
  `\[\[…]]`, so a discovery pass over raw template lines matches nothing
  at all. Beyond discovery, the section is four bullets of which only the
  first is the test object; binding the whole section exports test
  equipment as test object.
- **B — Downgrade both entries to `declared-only`.** Rejected. The data
  the relations need already exists in the template vault: four annotated
  links in `ARC_Battery_Monitoring.md`, two in
  `TAE_Battery_Log_Acceptance.md`. Downgrading deletes a declared
  capability that the corpus already supports, and it removes the
  containment edges a graph-based coverage rule (issue #50) would need.
- **C — Split the two, because they are not one problem.** Chosen.

### Decision

**`test-object` is authored in TAE frontmatter, not in prose.** A
`test-object:` list of object identifiers beside `verifies:`, declared in
`domain_defaults.fields` and required nowhere. This is the only variant
the blocking layer can check — an identifier naming nothing is a finding,
a missing prose annotation never can be — it needs no section binding and
no discovery rule, and frontmatter keys are English in every corpus
measured, which the schema already relies on for `verifies`.

**`contains` keeps its link-based primary source, with object domains
declared per source.** Annotated links in an ARC body outside the bound
tables become `contains` edges to REQ, DEC, CMP and IMP; the submodule
table remains the secondary source and is the one that may reach ARC.
The split is what keeps a "Related Modules" bullet — an annotated ARC
link in the Context section — from being exported as containment, and it
corrects a schema that currently forbids the ARC target its own
secondary source produces.

**A wikilink that could have been a relation and carries no annotation is
reported.** Without it this change is a no-op on every vault that has not
adopted `id:` yet, and silently so — the one output this exporter's own
module docstring forbids.

**An annotation whose identifier contradicts the file it links to is
reported.** The edge follows the wikilink, as everywhere else; the
disagreement is named rather than resolved. This is what makes the
annotation load-bearing instead of a decorative suffix.

### Rejected by review, before implementation

The plan first bound `test-object` to the TAE `## Test Conditions`
section, discovered as "the section of the project's own TAE template
that contains a wikilink placeholder". An adversarial review of the plan
killed it on three counts, each verified against the source: the
discriminator is template body text, which nothing enforces — the same
class of signal `binding_discovery.why_not_the_header` already rejected
with measurements; the templates write `\[\[…]]`, so a pass over raw
template lines would have matched nothing at all; and the section holds
the setup and the equipment beside the test object, so a real note
reading "Test setup: [[CMP_Oscilloscope]] (CMP-EQP-002)" would have
exported an oscilloscope as a test object. The review also found the
plan internally inconsistent — it read only REQ/DEC/CMP/IMP from the ARC
body while widening `object_domains` with ARC — and noticed that without
a finding for unannotated links the change is a no-op on every vault
that has not adopted `id:`, silently. All three corrections are in the
decision above.

### Realization

- `export_traceability.py` — `body_links` (annotated and unannotated
  wikilinks of a file body, fenced blocks and frontmatter and
  already-bound table lines stepped over, one entry per distinct target
  in file order), `_contains_from_body`, the `test-object` block beside
  `verifies` in `build_graph`, per-source domain filtering for both
  `contains` sources, and `ANNOTATION_RE`
- `vault_schema.json` — `domain_defaults.fields.test-object`;
  `contains.object_domains_primary` / `object_domains_secondary` with
  `object_domains` kept as their union; both relation notes
- `validate_vault.py` — `OBJECT_ID_RE` and the `object-identifier` item
  branch of `check_field_value`, plus the same field in
  `FALLBACK_SCHEMA`, which the suite compares against the shipped schema
- templates and READMEs — the annotated form in the four ARC list
  sections and their README entries, the `test-object` field in the TAE
  template, the worked example filling it
- `00_documentation_file_creation_and_conventions.md` — the annotation
  as the statement, the two deliberately unannotated shapes, and the
  frontmatter form of `test-object`
- `tests/run.sh` — fixture 7 gains the four link shapes and a
  `test-object` field naming one file that exists and one that does not;
  251 to 259 assertions

Observed at the real entry point, the template vault, before and after:

    before:  objects: 7  relations: 14  findings: 0
             allocates 3, evidence 3, justified-by 3, verifies 3, connects 2

    after:   objects: 7  relations: 20  findings: 0
             contains 4, allocates 3, evidence 3, justified-by 3,
             verifies 3, connects 2, test-object 2

The four `contains` edges come from links that were already in
`ARC_Battery_Monitoring.md` and had never been read.

---

## Amendment 2026-08-05e — Coverage is decided on the graph, not on a mention (Accepted)

### Context

`req-uncovered` was a substring search over whole files:

    covered = any(rid in text for p, text in corpus.items()
                  if p != f and vault.classify(p)[1] in ("TAE", "ARC"))

A requirement counted as covered because its identifier appeared
somewhere in some ARC or TAE file — in a heading, in a list of open
points, in a sentence explaining why it was dropped. No allocation row
was required, no evidence note was required, no `verifies:` entry was
required. The README states the method's value as turning "we tested it"
into "these three requirements are still unproven"; that sentence was
true of the exporter and of nothing in the blocking path (issue #50).

Two facts about the state of the rule, measured 2026-08-05 on the two
vault roots this session had access to:

| | template vault | homelab (read-only) |
| --- | --- | --- |
| md files | 39 | 313 |
| `Vault.req_index()` | 3 | **0** |
| requirements in the graph | 3 | 162 |
| `req-uncovered`, old rule | 0 | 0 |
| `req-uncovered`, this change | 0 | 0 |

The homelab column is the more important one. That vault spells its
requirements folder `01_Anforderungen_(ANF)`, so `domains.get("REQ")` is
`None`, `req_index()` is empty, and the coverage rule has never checked
anything there at all — accepted residual 1 of amendment 2026-07-28,
still accepted and now measured a second time.

### Options

- **A — Restrict the text search to table cells.** Rejected: a cell in
  any table is still not an allocation row, and the rule would keep
  answering a question nobody asked.
- **B — Read the allocation table inside `validate_vault.py`.** Rejected:
  an allocation row lives in the section the project's own ARC template
  declares, so this means re-implementing `discover_bindings` and
  `bound_tables` — a third definition of an allocation beside the two the
  table readers were unified into (amendments 2026-07-31b, 2026-08-01).
- **C — Two halves from the two places that already own them.** Chosen.

### Decision

**A requirement is covered when an allocation row names it AND a TAE
names it in `verifies:`.** The two halves come from two readers. The
`verifies:` half is frontmatter, which this validator already parses, so
`evidence_index` builds it from the corpus it has read anyway. The
allocation half is read from the graph `export_traceability.analyse()`
builds, because only its binding discovery finds the section a given
project declares.

**Where the graph carries no requirement of that identifier, the
allocation half is not held against it.** `allocation_index` returns
three states, not two: allocated, not allocated, and *cannot say*. The
graph carries a requirement row only when it sits in the bound section of
a file the graph reads, so a row under a heading of the author's own
making (`REQ_Loose (LSE)` in the suite; seven such tables in nativclaw),
every row of a vault whose REQ role went to a second folder mid-
translation, and every row of a project whose templates declare no
allocation table are invisible there and perfectly correct in the vault.
An adversarial review of the plan measured the alternative: three
findings on the three correct requirements of the shipped template vault,
and a full sweep on a mid-translation vault this project explicitly
supports. The exporter names those three situations itself, as
`export-unbound-table`, `export-duplicate-role` and `export-no-binding`.

**`evidence-disagrees` does not decide coverage.** An allocation row
linking evidence note A while note B is the one naming the requirement in
`verifies:` is a real disagreement and is reported — by the exporter,
where both relations are extracted. Folding it in here would report one
defect under two codes and would contradict `OPEN_QUESTION_CLASSES`.

**The severity stays WARN, and no new finding code is introduced.** The
basis, in order:

1. The line this project already draws. `consistency_rules.verified-needs-
   evidence` refuses anything that "cannot tell them apart" in a check
   that blocks, and this check cannot tell a requirement nobody has
   verified yet from one whose vault never adopted the `verifies:`
   convention.
2. The two false-positive classes above, which the *cannot say* state
   avoids by construction and which an ERROR would have turned into a
   blocked session.
3. External precedent: Doorstop reports an item without links from a
   child document as WARNING and reserves ERROR for an invalid or unknown
   UID — the split this validator already has between `req-uncovered` and
   `verifies-unknown-req`.
4. Vault-wide findings never enter the stop gate's blocking set anyway
   (amendment 2026-07-28f), so ERROR would only change the exit code of
   the full audit.

The measured effect of this change on both real vault roots is **zero
findings either way**. The number that says what ERROR would cost is a
counterfactual and is recorded as one: *if* `req_index()` were role-aware,
the rule would report 162 of homelab's 162 requirements, 129 of them
solely because that vault's evidence notes carry an empty `verifies:`
list. That is a statement about a change this repository has not made,
not about this one.

### Rejected by review, before implementation

The plan first added a `coverage-unavailable` WARN and suppressed all
coverage findings whenever the project's templates declared no allocation
table. An adversarial review prototyped it and measured four failing
assertions: the precision fixture's templates carry no tables at all, so
the guard fired on the fixture that must produce zero findings, took
`req-uncovered` out of the violation vault, emptied the fail-open stop
report, and put a vault-wide section into the stop report of a clean
session. The same review found that the planned fixture would have been
built from those very templates and would therefore have asserted nothing
about coverage; that `analyse()` as first specified dropped the findings
accumulator `main()` seeds with `export-schema-unreadable`; that
`except Exception` does not catch `SystemExit`, which is the one exception
class that would exit 2 and release both hooks; and that `ROLE_CACHE`, a
module global refilled per vault root, can bind one vault's tables against
another vault's roles because `hook_stop` loops over roots in one process.
All five corrections are in the decision above, and the fixture now
carries its own table-bearing templates.

### Realization

- `validate_vault.py` — `evidence_index`, `allocation_index` and the
  rewritten coverage block in `validate_vault_wide`; the lazy import
  registers this module under its import name first, because a script run
  leaves it in `sys.modules` as `__main__` and the exporter's own
  `from validate_vault import ...` would otherwise load a second copy of
  it, with two `Vault` classes and two schema caches
- `export_traceability.py` — `analyse()` as the one place the graph is
  built, called by `main()` and by the validator; `ROLE_CACHE` deleted in
  favour of a `roles` parameter on `discover_bindings`
- `vault_schema.json` — `consistency_rules.requirement-coverage`, and the
  `export-driven` level text, which said an entry at that level "never
  produces a validator finding": still true of the entry, no longer true
  of the graph built from it
- `SKILL.md`, `README.md` — the allocation half of the loop, which the
  skill file had never asked for
- `tests/run.sh` — fixture 10, a coverage vault with its own table-bearing
  templates and seven requirements: a closed loop, three identifiers
  written only in prose or in a heading, an allocation without evidence,
  evidence without an allocation, and a closed loop in a table outside the
  bound section. Three variants pin the *cannot say* state (no allocation
  binding, no exporter beside the validator, two requirement folders), and
  one asserts that a script-mode validator and the exporter are one pair
  of modules; 259 to 278 assertions

Observed at the real entry point, the shipped template vault and two
copies of it:

    template vault:                     0 error(s), 1 warning(s), no req-uncovered
    same vault, TAE 'verifies:' removed: 3 x req-uncovered
        "REQ-BAT-001 is named by no TAE in 'verifies'"
    same vault, allocation cells cleared: 3 x req-uncovered
        "REQ-BAT-001 is verified by TAE_Battery_Log_Acceptance but no
         allocation row allocates it"

In both copies the identifiers are still written in the ARC file and in
the TAE body. That is precisely what the old rule accepted as proof.

### Accepted residuals (documented, not solved)

1. **The rule reaches one vault root of the eight on this machine.**
   `req_index()` resolves the REQ domain by folder abbreviation, so every
   German vault is silent here — residual 1 of amendment 2026-07-28,
   unchanged. Whatever this predicate says, it says it about the one
   corpus that spells its folders in English. A role-aware `req_index()`
   is the change with the larger measured payoff and is deliberately not
   in this amendment.
2. **`assess` reads `verifies_back` as a literal** while `reverse_index`
   derives the key from `relations.verifies.reverse_key`. Renaming that
   schema key today mis-renders the export; it does not reach this rule,
   which takes only `not-allocated` from the coverage map, and that class
   is computed from the allocations alone.
3. **A missing `export_traceability.py` degrades the rule silently.** The
   verification half still decides, and nothing says the allocation half
   stopped. `--check-install` is the place that answers "is this copy of
   the skill complete"; it checks `SKILL.md` and no sibling file.


## Amendment 2026-08-05f — The index an agent reads is generated, not committed (Accepted)

### Context

`traceability.json` already is a graph index of the vault, and by design it
is written outside the vault (`STRUCTURE.md`, section
`.claude/skills/mechatronics-docs`; `main` refuses any `--output-dir` that
`find_vault_root` resolves inside a vault). Nothing inside the vault and
nothing in `CLAUDE.md` names it, so a session working in the vault
re-derives the structure by search every time instead of reading it once.
The JSON is also not the artifact for that first read: it carries every
edge, every finding and every coverage record of the graph.

What is missing is the cheap read - one line per object, `identifier ·
domain · file · one sentence` - and something in the instructions that
says it exists.

### Options

- **A — A generated index beside the existing artifacts, plus a pointer
  from `CLAUDE.md` (chosen).** The index becomes a `--formats` output like
  the other four files and stays outside the vault; the visibility problem
  is solved where it is - in the instructions.
- **B — Commit the index inside the vault, guarded by a CI
  regenerate-and-diff step.** Rejected on three counts. It contradicts the
  rule this template teaches (`STRUCTURE.md`) and the refusal the exporter
  enforces in code and pins in `tests/run.sh`. Every file in the vault is
  measured by the validator: an index carries no domain prefix, no
  frontmatter and no template sections, so `filename-prefix` and
  `template-sections` would fire and the vault would need an exemption list
  that exists for one generated file. And a committed generate is the drift
  failure mode this repository exists to prevent: between two commits the
  file is wrong on disk, and an author editing a note without running the
  exporter gets a red pipeline for a file they never wrote.
- **C — Commit it under `00_documentation/02_documents/`.** Rejected.
  `STRUCTURE.md` describes that folder as documents *not* maintained as
  Markdown, with a dated revision naming schema; a continuously
  regenerated file does not fit it, and the drift between commits remains.
- **D — A symlink into the vault.** Rejected: a symlink is a file in the
  vault for every reader except the file system, and Obsidian and Windows
  each make a special case of it.

### Decision

**The index is a `--formats` output named `traceability_index.md`, written
to the same `--output-dir` as the other artifacts**, and `index` joins the
default format list so the CI determinism step - which calls the exporter
without `--formats` - covers it without an edit to the workflow.

**The one sentence per object comes from the section this project's own
REQ template declares**, which `discover_bindings` already resolves as
`bindings["req_table"]["section"]` and which `vault_schema.json` records as
the prose section (`## Context`, `## Kontext`) in every vault measured. No
second discovery rule, no new finding code, and no set iteration that could
make the bound title differ between two runs.

**The sentence itself is cut by a stated rule, never by judgement**: the
first prose paragraph of that section, whitespace collapsed, cut at the
first `.`, `!` or `?` that is followed by whitespace or the end of the text
and whose next non-space character is not a lowercase letter, then capped
at 240 characters on a word boundary. Free text is HTML-escaped, as it is
in the report, because Markdown carries raw HTML.

**The sentences are a derived field.** They live under a top-level
`summaries` key listed in `field_types.derived`, not on the authored
`nodes`, because a located, collapsed, cut and truncated sentence is worked
out and not written down.

**Visibility is prose, not a file**: one paragraph in `CLAUDE.md` and one
sentence in the vault README, both naming the command rather than a path to
trust - a copy on disk is only ever as fresh as its last run.

### Rejected by review, before implementation

The plan first discovered the section itself, as the intersection of the
H2 titles of every domain template. An adversarial review of the plan
killed three parts of it against the source. The intersection hangs on a
single file - `00_CMP_file_template.md` carries no H2 at all and is only
excluded by `templates_for`'s empty-set rule - and `extract_h2` returns a
set, whose iteration order is randomised per process, so the display
spelling of a fold-collision (`Kontext` beside `kontext`) could differ
between two runs and fail the CI diff. The planned finding for a file
without a usable sentence broke an existing assertion measurably: the
shadowed requirements fixture, which `tests/run.sh` pins at zero
findings, has a context section holding nothing but tables, and a
prototype of the plan reported it. And the abbreviation rule refuted
itself - "a preceding word longer than two characters" cuts inside
`e.g.`, which was the rule's own counterexample, and cuts inside `bzw.`
and `usw.` in the German half of the corpus. The decision above carries
all three corrections: the REQ binding instead of a second discovery, a
counter in the index head instead of a finding, and a terminator that
ends a sentence only where the next word does not continue it in lower
case.

### Realization

- `export_traceability.py` - `summary_of` (the bound section, its first
  prose block, headings, tables, list items, quotes and fenced blocks
  stepped over), `cut_sentence`, `cap_sentence`, `index_text`,
  `write_index`, `Graph.summaries`, the `summaries` key and its
  `field_types.derived` entry in `write_json`, `index` in the
  `--formats` default, `EXPORT_SCHEMA_VERSION` 1.0 -> 1.1
- `vault_schema.json` - the `index` entry: the artifact, why the REQ
  binding rather than a discovery of its own, the sentence rule verbatim,
  and why a missing sentence is a count and not a finding
- `CLAUDE.md` - rule 15; `00_documentation/01_projectvault/README.md`,
  `README.md`, `SKILL.md`, `STRUCTURE.md` - the same artifact from each
  file's own angle
- `tests/run.sh` - eleven assertions on the index and the rule behind it,
  plus two fixture context paragraphs that carry an abbreviation and a
  sentence that never terminates; 259 to 270 assertions

Observed at the real entry point, the template vault:

    objects: 7  relations: 20  findings: 0
    index: 7 object lines, 3 requirement lines, 0 objects without a sentence
    bound req_table -> '## Context'

    - `CMP-BAT-001` · CMP · `04_components_(CMP)/CMP_Battery_Pack.md` ·
      Rechargeable lithium-polymer battery pack of the host machine, and
      the supply endpoint of IFC_PWR_DC_LiPo_Pack (IFC-BAT-001) inside
      the module ARC_Battery_Monitoring (ARC-BAT-001).

Two runs into the same directory with `--no-timestamp` compare byte-equal
under `diff -r`, which is the property the CI step measures.


## Amendment 2026-08-05g — AGENTS.md forwards, it does not duplicate (Accepted)

### Context

This repository is a public template, and its only instruction file is
named after one vendor. `AGENTS.md` is the cross-tool convention for the
same purpose - plain Markdown at the repository root, read by a growing set
of agents (agents.md).

### Options

- **A — A thin `AGENTS.md` that forwards to `CLAUDE.md` (chosen).**
- **B — Move the rules into `AGENTS.md` and leave `@AGENTS.md` in
  `CLAUDE.md`,** which is what the Claude Code documentation recommends for
  repositories that already carry an `AGENTS.md`. Rejected here: it moves
  the one regular text of a public template and every fork's diff with it,
  for no gain a forwarder does not also give.
- **C — `ln -s AGENTS.md CLAUDE.md`.** Rejected: on Windows a symlink needs
  administrator rights or developer mode, which a template cannot assume.

### Decision

`AGENTS.md` names where the rules are and repeats none of them, so there is
nothing in it that can drift. It also records why the rules stay in
`CLAUDE.md`: Claude Code reads `CLAUDE.md` and not `AGENTS.md` (Claude Code
documentation, *How Claude remembers your project*), so a forwarder is the
only shape that serves both without duplication.

### Realization

`AGENTS.md` at the repository root: a link to `CLAUDE.md`, one line each
for `STRUCTURE.md` and `.claude/skills/mechatronics-docs/`, and the
sentence that explains the file name. Thirteen lines, no rule of its own,
nothing a later change to `CLAUDE.md` could contradict.


## Amendment 2026-08-05h — The method carries a version, and a breaking change is defined (Accepted)

### Context

The method is versioned in two places and as a whole in none.
`vault_schema.json` declares `schema_version: 0.3`, and
`export_traceability.py` declares `EXPORT_SCHEMA_VERSION = "1.1"`. Neither
answers the question a reader of this repository actually has, which is
whether the method they adopted six months ago still means what it meant.

That question is not academic here, because of how the template is
consumed. A repository created from a GitHub template starts with a single
commit and shares no history with the template — unlike a fork, which
carries the whole commit history. There is no upstream to pull from and no
merge to resolve. An update is somebody reading a changelog, deciding it is
worth it, and copying files across.

Under those mechanics a version number is not decoration; it is the only
channel through which this repository can tell an existing project what a
change will cost it. Until now the repository carried no tags, no releases
and no changelog at all (issue #5).

### Options

- **A — Do not version; point at the git log.** Rejected on the mechanics
  above: a derived project does not have this log. `git log` is exactly the
  artifact a template-created repository does not inherit, so the one
  audience that needs the information is the one audience that cannot read
  it.
- **B — Promote `schema_version` to the repository version.** Rejected.
  The two measure different things and move on different schedules: a
  documentation release moves the method without touching the data model,
  and `EXPORT_SCHEMA_VERSION` would still be a third number with no
  relation to either. Collapsing them would force a schema bump for changes
  that do not touch the schema, which makes the schema number stop meaning
  anything.
- **C — Classify by intent: a documented rule that starts firing correctly
  is a PATCH, a new rule is a MAJOR.** Rejected during review, and it is
  worth recording why, because it was the plan. Issue #51 documents seven
  rules the validator enforces that no document in the repository states
  (`stub`, `structure`, `duplicate-basename`, `link-repeat`,
  `encoding-not-utf8`, `id-scope-mismatch`, `orphan`). For every one of
  them the criterion returns no answer. Worse, the answer would depend on
  whether the pull request that documents them lands first — a versioning
  rule whose outcome depends on merge order is not a rule.
- **D — Classify by consequence for an existing vault (chosen).**

### Decision

**Semantic Versioning applies to the method, and the tier is decided by one
question: does the set of rules itself move?**

MAJOR is a vault that was clean *and correct* no longer conforming, because
what counts as correct changed — a domain added, removed, renamed or
redefined; a template-required section changed; a frontmatter field made
required or its value set changed; the identifier pattern or a scope rule
changed; a typed relation added, removed or re-sourced; a rule newly
introduced or a WARN raised to ERROR; a field in `traceability.json` or a
column in either CSV renamed, removed or given a new meaning.

MINOR is new capability that leaves existing vaults clean. PATCH is the
rules staying put while a tool starts applying them correctly.

**A PATCH may still make a vault report findings it never reported.** Those
findings were always true and the tool was blind to them. Rather than
hiding that behind a tier, the compensating rule is that a PATCH entry in
the changelog **names the finding code**, so a reader can grep their own
vault before deciding to update. Whether a rule was documented does not
enter into the classification at all; that is the subject of issue #51 and
a documentation defect, not a versioning question.

**Highest tier wins on a multiple hit.** Amendment 2026-08-05d is the
worked case: it added an optional frontmatter field (MINOR) and changed
where two typed relations are authored (MAJOR) in one change. Without this
rule the most recent real merge in this repository is classified two ways.

**A template-section change is MAJOR, and it does not hit a derived project
passively.** `check_sections` derives the required sections from each
project's own `00_*file_template*` files, so a project keeping its old
templates keeps its old required sections and stays clean. The tier prices
what adopting costs; it does not announce a break that happens to somebody
who does nothing. This is the one tier in the table that is a statement
about the future rather than the present, and it is deliberate.

**The first release is 0.1.0, and it is not cut by this change.** SemVer
reserves major version zero for initial development; `schema_version` is at
0.3; and the open roadmap issues that would remap object and relation types
(#6) and move the decision log into the vault (#53) are MAJOR under the
table above. A 1.0.0 now would be a 2.0.0 within weeks, which is the one
thing a version number cannot survive.

### Rejected by review, before implementation

An adversarial review of the plan killed four factual claims that would
have shipped in the changelog, each verified against the source: that the
schema declares nine typed relations (it declares eight — the ninth
`relations` key is `note`, a prose explanation, and this file already said
"eight" in amendment 2026-08-05d); that the skill ships two hooks (`hooks/`
holds three, and the README sentence claiming two is issue #52); that
frontmatter carries `domain, status, created, last-verified` on every note
(DEC carries no `status` — issue #52 again); and that 26 pull requests were
merged since 2026-01-22 (the first commit is from that date, the earliest
merged pull request is #7 from 2026-07-28). The review also rejected the
intent-based tier criterion recorded as option C, found that no tier
covered the exporter's output contract, and rejected a changelog heading of
`## [0.1.0] — unreleased` as unparseable under the format the file's own
header claims to follow — an em dash where Keep a Changelog specifies an
ASCII hyphen, a version heading with no date, and two sections that both
mean "unreleased". The release notes are therefore drafted inside
`## [Unreleased]`, which is the shape every changelog parser already knows.

### Realization

- `CHANGELOG.md` — Keep a Changelog 1.1.0 form, the 0.1.0 notes drafted
  under `## [Unreleased]`, one link definition that resolves today
  (`commits/main`); the tag link is added when the tag is cut
- `CONTRIBUTING.md` — the tool-versus-method split, the local check
  commands with their real output including the known `duplicate-basename`
  WARN, the method-change route through an issue, how the vault conventions
  bind a contribution, the tier table above, the three version numbers and
  which one a derived project reads, and the release procedure
- `.github/ISSUE_TEMPLATE/bug_report.yml`,
  `.github/ISSUE_TEMPLATE/method_change.yml`,
  `.github/ISSUE_TEMPLATE/config.yml`,
  `.github/pull_request_template.md` — the method-change form asks for the
  cost to a project that already adopted the current rule and for the
  expected tier, because those are the two a reviewer cannot supply
- `README.md` — a Contributing section, and `.github/` added to the
  repository layout block it was missing from
- `STRUCTURE.md` — a `## .github` section, and the note in `60_releases`
  that a project's baseline trail is not the template's changelog

No tag is created and no GitHub release is published by this change. The
version number is chosen and justified; cutting it is a separate act,
described in `CONTRIBUTING.md` under *Cutting a release*.

### Aligned on integration

Rebased onto amendments 2026-08-05e (coverage on the graph) and 05f/05g (the
generated index and the `AGENTS.md` forwarder); this amendment moved from
suffix `e` to `h`. Both of those changes then became the tier table's worked
examples, because they are the two ends of it: coverage moving from a prose
mention to the allocation row and `verifies:` is a rule redefined, so a
previously clean vault can report `req-uncovered` with its notes untouched —
MAJOR. The fifth export artifact and the additive `summaries` key, with
`EXPORT_SCHEMA_VERSION` at 1.1, break no reader and dirty no vault — MINOR. A
policy stated against two changes that already happened is harder to argue
with than one stated in the abstract.

## Amendment 2026-08-05j — The correspondence to a safety standard is structural, not a claim (Accepted)

### Context

This repository argues that its documentation can be trusted, and it has
never said where its method stands relative to any safety standard. Issue
#6 asks for that: which domain corresponds to which required work product,
which relation kind carries which required trace, what the standard
demands that this vault has no home for, and — said plainly — whether the
result is a conformance claim or a correspondence.

Three things constrain the answer. The vault's type system is now
declared as data (`vault_schema.json`, nine domains and eight typed
relations, one authoring site each), so there is something concrete to
map. The candidate standards are paywalled, so a mapping written from
memory would be a fabrication with clause numbers on it. And the model
the issue names — StrictDoc's DO-178C document — turns out on reading to
be something else: `docs/strictdoc_40_DO178_requirements.sdoc` at commit
`5a9b679` is titled "Technical Note: DO-178C requirements tool
requirements", carries `CLASSIFICATION: Draft`, and holds requirements on
the tool, each with a `COMPLIANCE` field taking `C`, `PC` or `NC`, split
into "Already implemented features" and "Needs discussion". It is not a
work-product mapping and it claims no conformance. Its form is worth
borrowing; its function was misremembered.

### Options

- **A — No mapping. Close #6 with a comment saying the standard has to be
  bought first.** The strongest option against, and it was argued
  seriously in review: every other claim-bearing artifact here has a
  checker behind it, and this one cannot have one. Rejected because the
  credibility question is asked of this repository whether or not it
  answers, and a correspondence with its gaps named is more useful than
  silence — provided the document says what it is and how far the reading
  behind it went. That proviso became Section 1.
- **B — ISO 26262.** Rejected on its own scope sentence: the ISO
  catalogue entry for ISO 26262-2:2018 states it applies to E/E systems
  installed in series production road vehicles, excluding mopeds. This
  template does not know what its derived project is; asserting that
  scope would assert a domain it does not have.
- **C — ISO 13849, or IEC 62061.** Rejected on breadth and explicitly not
  on applicability. ISO 13849-1:2023 addresses the safety-related parts
  of a control system, while this vault carries mechanics, electronics,
  firmware and host software in one structure. A machine-building project
  would be held to ISO 13849 or IEC 62061 and should write that mapping
  as a second file rather than bending this one. Recording the honest
  reason matters: the weak version of this rejection — "the sector
  standards are inapplicable" — is false.
- **D — IEC 61508 (chosen).** The IEC catalogue entry for IEC 61508-1:2010
  states it has the status of a basic safety publication according to IEC
  Guide 104, aimed at enabling sector standards and at systems for which
  no product standard exists. That is exactly the position of a generic
  mechatronics template. It also has somewhere to map onto: clause 5
  *Documentation* and Annex A *Example of a documentation structure*.
- **E — Place the mapping in the template vault as a REF note.**
  Rejected. It describes the method rather than a project, so every
  derived project would copy an example it has to delete, as with the
  battery thread. It would additionally owe frontmatter, its domain
  template's sections and the 400-line limit. And a REF note points at
  the source it summarises, while `50_sources/04_standards/` is empty
  because a paid standard cannot be committed — the note would point at
  nothing.

### Decision

**`IEC_61508_MAPPING.md` at the repository root, and it is a structural
correspondence.** Not conformance, not certification, not evidence. The
file says so in its first paragraph, repeats it above each table, and
closes on it.

**Clause numbers and published clause titles only.** No normative
requirement text was read and none is paraphrased. Every clause, table,
figure and annex named carries a source key, and the key names the
document that was actually read — I.S. EN 61508-1:2010 as an NSAI free
page sample, not IEC 61508-1:2010 — how far the reading went (contents
list), and the retrieval date. IEC 61508 parts 2, 4, 5, 6 and 7 were
never opened, which the file states; because part 4 is *Definitions and
abbreviations*, the file also states that it uses every 61508 term in its
ordinary English sense.

**A row that cannot be sourced becomes a gap, never a guess** — the same
refusal the export makes for an unknown domain abbreviation. The state
vocabulary is this file's own and deliberately not the standard's:
*structural analogue*, *partial analogue*, *none*.

**The gaps are the durable part**, and they are standard-independent: no
hazard object, no risk estimate, no integrity level anywhere, no object
kind for a safety function with a demand mode, nothing under management
of functional safety because ADM is not engineering documentation, no
field naming who approved anything or with what independence, a
validation-plan status that asserts a plan exists and never points at
one, no record that the impact search after an artifact change happened,
nothing for decommissioning, no home for anything about the tools the
vault is checked by, and no note or field referencing a baseline.

**The file is named for the standard** so the pick is visible in the root
listing and a second mapping is a second file rather than a rewrite.

**The change is MINOR.** No domain, relation, field, template section or
rule moved; a vault that was clean stays clean and gains no finding.
Amendment 2026-08-05h expected issue #6 to be MAJOR "because it would
remap object and relation types" — it did not, and this is recorded here
rather than by editing that amendment, which is append-only. The
changelog entry carries the same sentence, so the two cannot drift.

### Rejected by review, before implementation

An adversarial review of the plan, run in a fresh context against the
repository rather than against the plan's reasoning, killed a series of
claims that would otherwise have shipped. Three phrasings had no title
behind them and were replaced by the titles that do: "SIL determination"
under 7.4, which is titled *Hazard and risk analysis*; "competence,
roles, FSM plan" under clause 6, which is titled *Management of
functional safety*; and "tool qualification" for part 3's 7.4.4, titled
*Requirements for support tools, including programming languages*. The
document would have violated its own source rule on its second page.

Five vault-side statements were wrong or loose. The `allocates` direction
was stated backwards — the schema makes the submodule the subject and the
requirement the object. The validation-plan gap ignored that
`00_ARC_README.md` defines the allocation status `Approved` as
"allocation is set, verification plan exists (TAE link or TBD)", which
sharpened the gap into its true form: the status asserts a plan and never
points at one. The baseline gap ignored `60_releases`, which
`STRUCTURE.md` describes as exactly that. The approval gap ignored that
a DEC body line reaches `Accepted` and an allocation row `Approved`,
leaving the real gap at *who* and *with what independence*. And the
exporter section would have presented all five gap classes as deciding
what is proven, when `export_traceability.py` lets only three decide and
holds `no-evidence-note` and `evidence-disagrees` as open questions on
purpose.

Four smaller corrections followed from the same pass: `Class (M/S/O)` is
not merely a priority, since the REQ README defines M as "no release /
unsafe / core function not provided"; the modification gap is a procedure
without a record rather than a missing procedure, because `CLAUDE.md`
already requires the impact search; the vault collapses verification and
validation, which part 3 keeps apart as 7.9 and 7.7, and that collapse is
itself a gap; and part 3's Annex D *Safety manual for compliant items* is
a further named artifact with no home here.

The review's strongest objection was not answered but adopted: this would
be the only document in the repository that asks to be believed, in a
repository whose pitch is that nothing has to be. It is now the content
of Section 1, together with the source key that is the only compensating
control available.

### Realization

- `IEC_61508_MAPPING.md` — seven sections: what it is and is not, why
  IEC 61508 with the three-standard comparison and the StrictDoc
  correction, what was read and what was not, domain-to-clause,
  relation-to-trace over all eight relations including the five with no
  counterpart, eleven gaps, and what the document does not establish
- `README.md` — a pointer at the end of the exporter section, where the
  credibility question is already asked, and the file in the layout block
- `STRUCTURE.md` — a `## IEC_61508_MAPPING.md` section, the treatment
  `AGENTS.md` got, saying why the file is not in the vault
- `CHANGELOG.md` — the entry under `Unreleased`, MINOR, naming the
  deviation from amendment 2026-08-05h

The suffix `j` assumes that issue #51 takes `i`. Like amendment
2026-08-05h before it, this one may move at integration.


