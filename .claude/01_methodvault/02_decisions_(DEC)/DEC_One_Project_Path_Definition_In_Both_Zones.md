---
domain: DEC
id: DEC-MTH-007
created: 2026-07-28
last-verified: 2026-08-05
---
Date: 2026-07-28
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-07-28e — One definition of a project path in both zones (Accepted)".

## Context

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

## Options

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

## Decision

Option B. One definition of a project path, used in both zones. The two
zones keep differing where the difference was decided on purpose:
severity (ERROR vs WARN), coverage of fenced and backticked content, and
the fact that `pending/planned/TBD` never silences the References/Sources
zone — the silent-bypass prevention of amendment 2026-07-27 stands
unchanged.

## Justification

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

## Consequences

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
