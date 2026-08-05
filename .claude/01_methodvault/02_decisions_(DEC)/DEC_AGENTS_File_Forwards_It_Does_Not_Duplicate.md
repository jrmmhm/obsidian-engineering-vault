---
domain: DEC
id: DEC-MTH-028
created: 2026-08-05
last-verified: 2026-08-05
---
Date: 2026-08-05
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-05g — AGENTS.md forwards, it does not duplicate (Accepted)".

## Context

This repository is a public template, and its only instruction file is
named after one vendor. `AGENTS.md` is the cross-tool convention for the
same purpose - plain Markdown at the repository root, read by a growing set
of agents (agents.md).

## Options

- **A — A thin `AGENTS.md` that forwards to `CLAUDE.md` (chosen).**
- **B — Move the rules into `AGENTS.md` and leave `@AGENTS.md` in
  `CLAUDE.md`,** which is what the Claude Code documentation recommends for
  repositories that already carry an `AGENTS.md`. Rejected here: it moves
  the one regular text of a public template and every fork's diff with it,
  for no gain a forwarder does not also give.
- **C — `ln -s AGENTS.md CLAUDE.md`.** Rejected: on Windows a symlink needs
  administrator rights or developer mode, which a template cannot assume.

## Decision

`AGENTS.md` names where the rules are and repeats none of them, so there is
nothing in it that can drift. It also records why the rules stay in
`CLAUDE.md`: Claude Code reads `CLAUDE.md` and not `AGENTS.md` (Claude Code
documentation, *How Claude remembers your project*), so a forwarder is the
only shape that serves both without duplication.

## Justification

_The source record carries no section under this title; it states its
grounds inside the two rejected options above and in the second sentence of
its decision._

## Consequences

### Realization

`AGENTS.md` at the repository root: a link to `CLAUDE.md`, one line each
for `STRUCTURE.md` and `.claude/skills/mechatronics-docs/`, and the
sentence that explains the file name. Thirteen lines, no rule of its own,
nothing a later change to `CLAUDE.md` could contradict.
