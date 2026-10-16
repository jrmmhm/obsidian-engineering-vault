# mechatronics-docs — reference

How the tools around the vault are used when a documentation session needs
them. `SKILL.md` beside this file says how to write vault notes and when to
open this file; this file is read on demand, not on every invocation.

The commands below name `<skill dir>`, the directory holding this file.
`SKILL.md` writes it as `${CLAUDE_SKILL_DIR}`; Claude Code expands that in
`SKILL.md` before a session reads it, and nothing outside a session expands
it. Typed into a shell or written into a workflow, the command takes the
path to a copy on disk instead — `.claude/skills/mechatronics-docs/` where
the project carries the skill, `~/.claude/skills/mechatronics-docs/` where
it does not.

---

## The traceability export

A second tool beside the validator reads the same schema for a different
purpose. `export_traceability.py` walks the declared relations into a
graph and writes the vault out as a traceability artifact:

```bash
python3 <skill dir>/export_traceability.py \
        <VAULT_ROOT> --output-dir <DIR outside the vault>
```

It produces a self-contained HTML report, two CSV views, a JSON graph,
`traceability_graph.mmd` — the coverage chain as a Mermaid diagram, for a
page rather than for a read — and `traceability_index.md`. The index is
the one written for an agent: one line per object and per requirement —
identifier, domain, file, and the first sentence of the section the
project's own requirements template binds. Generate it again rather than
trusting a copy from an earlier session; nothing about it is stored in the
vault. Every reverse relation in these artifacts is computed, never read
from a file.

Read its findings section as you would the validator's: an unbound table,
an unresolved requirement ID, an unknown domain abbreviation or two folders
meaning one domain each mean the export understood less of the vault than
it looks like it did.

The exporter never blocks a turn. It can block a caller that asks it to:
`--fail-on <classes>` exits 1 when a requirement carries one of the named
coverage gaps. No hook uses it and no session does — it exists for a CI
job, which sees the whole vault at once and costs nobody a working session.
The template repository's own workflow arms `not-allocated` and
`no-evidence-note` on its vault, so a missing allocation row or a missing
`verifies:` entry there is a red check rather than a WARN you scroll past.

---

## Which copy of the skill enforces

Both hooks in the frontmatter of `SKILL.md` resolve their script through
`CLAUDE_PLUGIN_ROOT`, which Claude Code sets to the skill directory it
actually loaded, so the copy whose `SKILL.md` a session reads is the copy
that enforces. A project that carries its own vendored copy no longer
overrides that — the vendored copy serves the CI and the pre-commit hook,
which have no session to ask (DEC-MTH-045).

Which copy of this skill a session is actually running is a separate
question, and one a global `~/.claude/skills/` entry cannot answer by
itself — it may be a symlink carrying a path that only one machine can
follow. `python3 <skill dir>/validate_vault.py --check-install` says
whether that entry reaches this copy, reaches a different one, or reaches
nothing at all, and prints the revision of the copy that answers, which is
how the two are told apart.

---

## Enforcement outside a session

Two further tiers apply the same validator outside Claude Code, and
neither one runs by merely being present. `hooks/pre_commit_vault.sh` is
installed per checkout — `.git/hooks/` travels with no clone and no pull
— and the hook's own header carries the symlink command and the
`MECHDOCS_PRECOMMIT_BLOCK=1` switch that makes it block rather than
report. `.github/workflows/validate-vault.yml` runs where the repository
is hosted with Actions enabled, and that file is the only current answer
to which checks it runs; a project derived from this template gets a
workflow written for it, and no run of this skill's own test suite is
among them, because that suite does not travel with the vendored copy.
What reaches the vault unchecked until one of the two is turned on is
stated in `SKILL.md`, "Enforcement Layer".
