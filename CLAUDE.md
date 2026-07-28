# Project Instructions

<role>
You maintain an engineering project that keeps its documentation in an Obsidian
vault under `00_documentation/01_projectvault/`, following the Single Source of
Truth method this repository is built around.
</role>

<context>
Read before your first vault edit — these are the authority, this file is not:

- `00_documentation/01_projectvault/00_documentation_file_creation_and_conventions.md`
  — when a file may exist, which domain it belongs to, the conventions.
- `00_documentation/01_projectvault/03_architecture_(ARC)/00_ARC_README.md`
  — how ARC orchestrates the other domains and how allocation works.
- `STRUCTURE.md` — which folder holds which kind of artifact.

The `mechatronics-docs` skill in `.claude/skills/` implements the method and
activates on its own. When it is active, follow it over this file.
</context>

<rules>
1. Edit vault files only with `Edit`, `Write` or `MultiEdit`. The validation
   hooks observe those three tools and nothing else — a `sed -i` or a heredoc
   writes an unvalidated file that looks identical in review.

2. Never delegate vault writing to a subagent. Hooks do not fire for subagent
   tool calls, so the write escapes validation the same way. Delegate research
   freely; keep writing in the main session.

3. Give each file exactly one question to answer. When a title needs "and",
   split the file — a file answering two questions cannot be found reliably by
   either one.

4. Link by exact filename: `[[REQ_Measurement_(MEG)]]`. Aliases are fine, the
   target is not negotiable. Retrieval matches exact names, so a link that
   depends on context ("see above", a pronoun pointing at another file) reads
   as a dead end.

5. Write the first lines of every Context section so they stand alone: what the
   thing is, which module it belongs to, spelled with real component names and
   IDs.

6. In ARC notes, reference other domains in one sentence each and copy nothing
   from them. ARC states why a requirement matters here and what a decision
   shapes; the requirement text and the justification stay in their own files.

7. Mark an allocation row `Verified` only once a TAE link exists and its
   evidence is written down. `Draft` and `Approved` are the honest states until
   then.

8. Update `last-verified` when you confirm a file still holds. When you find it
   wrong, correct it or mark it superseded in the same session — a stale file
   with a fresh date is worse than no file.

9. After changing an artifact (code, schematic, parameter), search the vault for
   notes referencing it and bring them along in the same session.

10. Run the validator after any larger documentation pass:
    `python3 .claude/skills/mechatronics-docs/validate_vault.py 00_documentation/01_projectvault`
    Fix every ERROR. Address WARNs or say briefly why they are acceptable.

11. Keep Markdown documentation inside the vault and binaries outside it. The
    vault is Markdown-only; exports, photos and PDFs belong in
    `00_documentation/02_documents/`, external material in `50_sources/`.

12. Implement the minimum solution in `20_software/`. Avoid premature
    abstraction. Those folders may carry their own `CLAUDE.md` — defer to it
    when working inside one.

13. Record implementation in an `IMP` note that points at the artifact path,
    rather than in sprawling code comments.

14. Use Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`,
    `chore:`), imperative subject under 72 characters, one concern per commit.
</rules>

<verification>
Before ending a session that touched the vault: validator clean of ERRORs?
Every new wikilink resolving to a real file? Every `Verified` row backed by a
TAE link? Every file you confirmed carrying a current `last-verified`?
</verification>
