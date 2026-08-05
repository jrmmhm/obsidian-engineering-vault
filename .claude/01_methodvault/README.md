# The method vault

This is the decision record of the documentation method itself — why the
validator, the exporter, the schema and the templates work the way they do. It
is a vault in the same sense as `00_documentation/01_projectvault`, held to the
same rules by the same `validate_vault.py`, and audited by name in CI.

Two vaults, two subjects, and the difference decides where a note belongs:

| Vault | Subject | Who reads it |
| ----- | ------- | ------------ |
| `00_documentation/01_projectvault` | one project's own engineering documentation | whoever works on that project |
| `.claude/01_methodvault` | this method and its tools | whoever changes the method or asks why a rule exists |

**Start at [[system_overview]]** — one line per decision, in the order the
record was written.

The history: until 2026-08-05 this record was one appended file of 5100 lines
beside the skill, `.claude/skills/mechatronics-docs/DECISIONS.md`. That file now
forwards here and carries no decision content of its own. What the move cost and
what it bought is itself a decision here,
[[DEC_The_Decision_Log_Moves_Into_A_Vault]].

**In a project made from this template**, this directory describes the template
and not your project — delete it, the same way you delete `CONTRIBUTING.md`,
`CHANGELOG.md` and `.github/`. Keep `.claude/skills/`: that is the tooling, and
it is the one thing here you do want.
