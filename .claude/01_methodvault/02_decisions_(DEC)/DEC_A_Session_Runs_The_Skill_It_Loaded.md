---
domain: DEC
id: DEC-MTH-045
created: 2026-08-10
last-verified: 2026-08-10
---
Date: 2026-08-10
Status: Accepted

## Context

The skill ships in two places at once. A derived project vendors a full
copy into its own repository, because its CI runs
`python3 .claude/skills/mechatronics-docs/validate_vault.py` on a runner
that has no `~/.claude` (DEC-MTH-036), and because a reader who clones the
project gets the tool with it. A person who works across machines also
keeps a personal entry at `~/.claude/skills/mechatronics-docs`, pointing at
the copy they actually edit.

Claude Code resolves those two by name, and personal overrides project —
measured on 2.1.220 and 2.1.226. So the SKILL.md a session reads is the
maintained one. The hook commands in that same frontmatter, however,
resolved their scripts through a hardcoded candidate list that tried
`$CLAUDE_PROJECT_DIR/.claude/skills/mechatronics-docs` first and
`$HOME/.claude/skills/mechatronics-docs` second, and each hook script then
resolves its validator relative to itself. The result is a session that
reads one copy of the skill and enforces another: in a project whose
vendored copy predates the current template, the rules the text describes
are not the rules that run, and nothing says so.

The list existed for a reason. `CLAUDE_SKILL_DIR`, which the skill's own
prose relies on, is empty inside skill-scoped hook commands — measured. The
author had no variable naming the loaded copy and enumerated the candidates
instead, project first.

## Options

- **A — Reverse the list to `$HOME` first.** Rejected: it repairs the
  symptom by guessing better. It still enumerates candidates rather than
  naming the loaded copy, and it makes a project unable to pin its own
  version deliberately.
- **B — Distribute the skill as a plugin from a git marketplace.**
  Rejected: `CLAUDE_PLUGIN_ROOT` is documented for plugin hooks and
  plugin skills carry their own namespace, so the collision disappears by
  construction. But it changes the invocation name, restructures the
  public template around a plugin manifest, and leaves the vendored copy —
  and therefore the CI route — exactly as it is. The cost is a repository
  restructure; the benefit does not reach the failure being fixed.
- **C — Detect and report the drift, keep the resolution as is.**
  Rejected as a solution, adopted as a complement: a report that the wrong
  copy is running does not stop it from running.
- **D — Resolve through `${CLAUDE_PLUGIN_ROOT}`, which Claude Code sets
  inside skill hooks to the loaded skill directory.** Chosen.

## Decision

Option D. Both hook commands try `${CLAUDE_PLUGIN_ROOT}` first, then the
personal entry, then the project copy, and say so out loud through the
`systemMessage` channel when none of them resolves. The candidate list
survives only as a degradation path for a Claude Code version that does not
set the variable, and it is ordered by the measured name precedence, so a
fallback never lands on a copy the session did not load.

`validate_vault.py` carries a `SKILL_REVISION` constant that
`--check-install` prints, so the question "which copy just enforced this?"
has an answer that does not require comparing two directory trees.

## Justification

- `CLAUDE_PLUGIN_ROOT` is the loaded skill directory, measured on 2.1.220
  and 2.1.226 and in every shape the personal entry takes: a real
  directory, a symlink into a repository, a dangling symlink (the project
  copy loads and the variable points at it), and absent (likewise).
- A tree comparison was considered for the drift report and rejected: the
  derived copy legitimately lacks `tests/` (`tools/new_project.py` strips
  it, `tests/run.sh` asserts the absence), so 9 tracked files stand against
  11 and every derived project would report divergence forever.
- The price is explicit: after this change a session and that project's CI
  can enforce different revisions of the rules, where before both were
  equally stale. That is the better failure — the stale one is now named by
  `--check-install` and fixed by bumping the vendored copy, instead of
  silently governing the session.

## Consequences

- The vendored copy stops being the session's enforcement code and becomes
  what it was always documented as: the CI and portability artifact. The
  `.github` workflow lines and `tools/new_project.py` are unchanged.
- The pre-commit hook still runs the vendored copy by construction — it is
  installed as a symlink inside `.git/hooks` and has no session to ask.
  Keeping a derived project's vendored copy current therefore remains a
  real task, not a cosmetic one.
- Realized in the `hooks:` frontmatter of `SKILL.md`, in `SKILL_REVISION`
  and `check_install()` in `validate_vault.py`, and pinned behaviourally in
  `tests/run.sh`: the test extracts the `command:` string from `SKILL.md`,
  places two competing copies on disk, and asserts which one ran.
