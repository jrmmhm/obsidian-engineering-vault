# Project Instructions

This project uses the Obsidian Engineering Vault layout. Read `README.md` for
the overview and `STRUCTURE.md` for what belongs in which folder.

## Documentation

All engineering documentation lives in `00_documentation/01_projectvault/`.
It follows the SSOT method described in
`01_projectvault/00_documentation_file_creation_and_conventions.md` — read that
file before creating or editing any vault note.

The `mechatronics-docs` skill in `.claude/skills/` implements this method and
activates automatically. It is the authority on vault work; these instructions
only cover what surrounds it.

Non-negotiables when touching the vault:

- **Never modify vault files through Bash** (`sed -i`, `tee`, heredocs). The
  validation hooks only observe `Edit`/`Write`/`MultiEdit`.
- **Never delegate vault writing to subagents.** Hooks do not fire for subagent
  tool calls. Research may be delegated; writing stays in the main session.
- One file answers exactly one question. If it needs "and", split it.
- Link with exact filenames: `[[REQ_Measurement_(MEG)]]`. No relative
  references like "see above" that break under search.
- When you confirm a file's content is still accurate, update `last-verified`.
  When it becomes wrong, fix it or mark it superseded in the same session.

Run the validator after larger documentation passes:

```bash
python3 .claude/skills/mechatronics-docs/validate_vault.py \
        00_documentation/01_projectvault
```

## Where things go

Documentation explains the work; everything else is the artifact of it.

| Artifact | Location |
| -------- | -------- |
| Vault notes (Markdown only) | `00_documentation/01_projectvault/` |
| Internal PDFs, exports, photos | `00_documentation/02_documents/` |
| External datasheets, standards, papers | `50_sources/` |
| Measurement files | `30_testdata/` |
| Source code | `20_software/` |
| CAD, PCB, electronics | `10_hardware/` |

Never put Markdown documentation outside the vault, and never put binaries
inside it.

## Code

Source code lives under `20_software/`, one folder per responsibility. Those
folders may carry their own `CLAUDE.md` with language- and stack-specific rules
— defer to it when working inside one.

Document code in the vault, not in sprawling comments: an `IMP` note records
how something is implemented and points at the artifact path.

## Git

Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
Subject in imperative mood, under 72 characters. Commit logical units — one
concern per commit.
