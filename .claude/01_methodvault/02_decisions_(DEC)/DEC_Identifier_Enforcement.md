---
domain: DEC
id: DEC-MTH-005
created: 2026-07-28
last-verified: 2026-08-05
---
Date: 2026-07-28
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-07-28c — Identifier enforcement (Accepted)".

## Context

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

## Options

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

## Decision

_The source record marks its chosen options inline in Options ("A2 …
(chosen)", "B2 — WARN (chosen)", "C2 … (chosen)") and carries no section
under this title._

## Justification

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

## Consequences

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
