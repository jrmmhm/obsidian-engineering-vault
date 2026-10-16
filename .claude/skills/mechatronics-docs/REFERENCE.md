# mechatronics-docs — reference

How the tools around the vault are used when a documentation session needs
them. `SKILL.md` beside this file says how to write vault notes and is read on
every invocation; this file is read on demand. What a rule *is* lives in the
vault's conventions file, where a check lives in `ARCHITECTURE.md`.

The commands below name `<skill dir>`: the directory holding this file.
`SKILL.md` writes it as `${CLAUDE_SKILL_DIR}`, which Claude Code expands in
`SKILL.md` before a session reads it — but not in this file, and nothing
outside a session expands it at all. Typed into a shell or written into a
workflow, the command takes the path to a copy on disk:
`.claude/skills/mechatronics-docs/` where the project carries the skill,
`~/.claude/skills/mechatronics-docs/` where it does not.

---

## The traceability export

A second tool beside the validator reads the same schema for a different
purpose. `export_traceability.py` walks the declared relations into a graph
and writes the vault out as a traceability artifact:

```bash
python3 <skill dir>/export_traceability.py \
        <VAULT_ROOT> --output-dir <DIR outside the vault>
```

It produces a self-contained HTML report, two CSV views, a JSON graph,
`traceability_graph.mmd` — the coverage chain as a Mermaid diagram, for a
page rather than for a read — and `traceability_index.md`. The index is the
one written for an agent: one line per object and per requirement —
identifier, domain, file, and the first sentence of the section the
project's own requirements template binds. Generate it and read it once
instead of searching the vault for its structure, and generate it again
rather than trusting a copy from an earlier session; nothing about it is
stored in the vault. Every reverse relation in these artifacts is computed,
never read from a file.

Run it when the user asks for a traceability matrix, a coverage overview, or
something to hand to a reviewer — and read its findings section as you would
the validator's: an unbound table, an unresolved requirement ID, an unknown
domain abbreviation or two folders meaning one domain each mean the export
understood less of the vault than it looks like it did.

The exporter never blocks a turn. It can block a caller that asks it to:
`--fail-on <classes>` exits 1 when a requirement carries one of the named
coverage gaps. No hook uses it and no session does — it exists for a CI job,
which sees the whole vault at once and costs nobody a working session. The
template repository's own workflow arms `not-allocated` and
`no-evidence-note` on its vault, so a missing allocation row or a missing
`verifies:` entry there is a red check rather than a WARN you scroll past.

---

## Which copy of the skill enforces

Both hooks in the frontmatter of `SKILL.md` resolve their script through
`CLAUDE_PLUGIN_ROOT` first, so the copy whose text a session reads is the
copy that enforces. Claude Code documents that variable for plugin skills
only; that it names the loaded directory of a standalone skill as well is a
measured behaviour, recorded in DEC-MTH-045, not a documented one. The hooks
therefore fall back to the personal entry and then to the project copy, and
say so through `systemMessage` when none of them resolves. A project that
carries its own vendored copy does not override the loaded one — the
vendored copy serves the CI and the pre-commit hook, which have no session
to ask.

Which copy a session is actually running is a question a global
`~/.claude/skills/` entry cannot answer by itself — it may be a symlink
carrying a path only one machine can follow.
`python3 <skill dir>/validate_vault.py --check-install` says whether that
entry reaches this copy, reaches a different one, or reaches nothing at
all, and prints the revision of the copy that answers. Run it when a rule
`SKILL.md` describes appears not to be enforced.

---

## Enforcement outside a session

Two further tiers apply the same validator outside Claude Code, and neither
one runs by merely being present. `hooks/pre_commit_vault.sh` is installed
per checkout — `.git/hooks/` travels with no clone and no pull — and the
hook's own header carries the symlink command and the
`MECHDOCS_PRECOMMIT_BLOCK=1` switch that makes it block rather than report.
`.github/workflows/validate-vault.yml` runs where the repository is hosted
with Actions enabled, and that file is the only current answer to which
checks it runs; a project derived from this template gets a workflow
written for it, and no run of this skill's own test suite is among them,
because that suite does not travel with the vendored copy. Until one of the
two is turned on, an edit made in Obsidian, by hand, by a subagent or in a
session that never invoked the skill reaches the vault unchecked.

---

## What the stop gate's messages mean

At turn end, the stop gate re-checks every vault file touched this session.
ERRORs newly introduced this session block completion; pre-existing
violations in legacy files are reported but never block — ratcheted against
the git HEAD state. Vault-wide findings (uncovered REQs, orphans, ...) are
listed as advisory and never block; the full audit remains the
authoritative pass for them.

The two halves of the gate address two readers, and the transcript shows
which is which. Everything advisory reaches the user as `Stop says: ...` —
legacy findings, created files, the ERROR codes a file carried at git HEAD
that did not fire this session, and questions the session owner has to
answer. Its first line names the turn it belongs to:
`vault validator blocked the turn end (attempt n/2)` when the gate blocked,
`vault validator session report:` when it did not — including the turn
after two blocked attempts, where the report opens with
`UNRESOLVED vault ERRORs` and the gate has already released. What the gate
wants from the session arrives as `Stop hook feedback:` and names only the
ERRORs this session introduced.

A gate that could not run says so as well:
`vault validator crashed - stop gate released` at turn end, and
`vault validator crashed - validation skipped for this write` after a write,
both to the user and the latter to the session too. Either means the vault
rules went unchecked, so verify by hand before finishing.
