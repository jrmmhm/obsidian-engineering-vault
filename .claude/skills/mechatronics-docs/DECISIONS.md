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
