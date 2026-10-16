---
domain: DEC
id: DEC-MTH-056
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Accepted

## Context

The in-session tier of the mechatronics-docs enforcement layer is two hooks,
`hooks/post_write_check.sh` after every `Edit`/`Write`/`MultiEdit` and
`hooks/stop_gate.sh` at turn end, and both are registered in the `hooks:`
frontmatter of the skill's `SKILL.md`. Claude Code documents what that scope
means: skill hooks are registered when the skill is invoked and keep running
for the rest of the session, and the hook sources documented to run inside
subagents are settings files, managed policy and plugins — skill frontmatter
is not among them (code.claude.com/docs/en/skills, frontmatter table;
code.claude.com/docs/en/hooks, "Hook locations"; read 2026-10-16).

Two routes therefore reach a vault without in-session validation: a session
that edits vault files without ever invoking the skill — an implementation
session updating an IMP note, say — and a subagent that writes a vault file.
[[DEC_Enforcement_Layer_For_The_Vault_Conventions]] (DEC-MTH-001) already
lists subagent writes among its accepted residuals; the never-invoked
session was nowhere written down, and `SKILL.md` described the hooks as
running "while this skill is active". A review of the skill (2026-10-15,
finding F11) proposed closing both routes by registering the same two hooks
in each derived project's `.claude/settings.json`.

The same review found the one dead channel left in this tier: a validator
crash in the post hook was announced on stderr at exit 0, which Claude Code
never shows to anyone — the defect
[[DEC_The_Stop_Report_Goes_Where_It_Is_Read]] (DEC-MTH-023) had already
fixed for the stop hook.

## Options

- **A — Register the hooks in project settings as well.** Every session in
  a derived project, and every subagent in it, is validated. Rejected by the
  operator on 2026-10-16: it would run the validator in sessions that have
  nothing to do with documentation, and it would move part of the skill's
  behaviour out of the skill into every project's configuration.
- **B — Distribute the skill as a plugin.** Plugin hooks run in subagents by
  documentation. Rejected for the reasons
  [[DEC_A_Session_Runs_The_Skill_It_Loaded]] (DEC-MTH-045) gives against
  option B there: a changed invocation name and a restructured template for
  a benefit the vendored CI copy does not share.
- **C — Keep the hooks skill-scoped and state the residual where the agent
  reads it (chosen).**

## Decision

Option C. The hooks stay in the `SKILL.md` frontmatter, with the candidate
loop DEC-MTH-045 decided left unchanged. `SKILL.md` says that the hooks run
from the skill's first invocation to the end of the session, that a session
which never invokes the skill and subagent writes are not validated
in-session, and that only an out-of-session tier — a CI workflow or the
pre-commit hook, where one is turned on — catches them. The rule against
delegating vault writes to subagents stays, because the registration scope
it compensates for stays.

The post hook reports a crash as one JSON object carrying `systemMessage`
for the user and `hookSpecificOutput.additionalContext` for the model: the
skill tells the session to verify a write by hand after a crash, and an
instruction the model cannot see could not be followed.

## Justification

- The operator decides what runs in sessions that never asked for this
  skill; a validator in every session of a derived project is a cost those
  sessions did not choose.
- The residual is not new, only unwritten. A rule the agent can read beats
  a gap only a maintainer knows about, and the out-of-session tiers already
  exist for exactly the edits the hooks never see.
- Both fields of the crash notice are documented for `PostToolUse` and may
  share one object; the stop hook keeps `systemMessage` alone, because there
  the model is reached only by blocking, which a released gate must not do.

## Consequences

- Unvalidated in-session: sessions that never invoke the skill, and subagent
  writes. Covered only where a CI workflow or the pre-commit hook runs.
- The suite pins the crash notice in both channels beside the stop hook's
  crash assertion, and the phrase `SKILL.md` quotes against what both hooks
  print; the old stderr line fails it.
- Revisit if Claude Code documents skill hooks as running inside subagents,
  or if the operator wants every session in a project validated.
