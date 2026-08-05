---
domain: DEC
id: DEC-MTH-003
created: 2026-07-28
last-verified: 2026-08-05
---
Date: 2026-07-28
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-07-28 — Language-independent recognition, VCS tier (Accepted)". Its title names two questions; the record argues both from one Context and is therefore kept whole — see [[DEC_The_Decision_Log_Moves_Into_A_Vault]].

## Context

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
the 2026-07-25 decision ([[DEC_Enforcement_Layer_For_The_Vault_Conventions]]) (CI/pre-commit) and follow-up 1 were deferred
then; human Obsidian edits and Bash mutations remained uncovered.

## Options

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

## Decision

Option B, behind one named constant `TEMPLATE_MARKERS` used at all four
sites (vault-root detection, section derivation, template classification,
and the CLI error message). Plus a pre-commit hook and a GitHub Actions
workflow, both stdlib-only. The pre-commit hook reports and never blocks
by default; blocking is opt-in per environment variable.

## Justification

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

## Consequences

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
