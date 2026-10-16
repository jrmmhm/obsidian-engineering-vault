---
name: mechatronics-docs
description: >
  Create, update, and maintain engineering documentation in mechatronics
  projects that use the SSOT Obsidian vault structure (9 domains: REQ, DEC,
  ARC, CMP, IFC, IMP, TAE, OAU, REF). Use this skill when the user asks to
  document a feature, component, decision, test result, or engineering
  artifact — or when completed work (hardware, software, PCB, test campaign)
  needs documentation. Also triggers on "document this", "write it up",
  "add to the vault", or any vault domain prefix. Only activates in projects
  with the mechatronics baseproject directory layout.
hooks:
  PostToolUse:
    - matcher: "Edit|Write|MultiEdit"
      hooks:
        - type: command
          shell: bash
          command: 'for d in "${CLAUDE_PLUGIN_ROOT:-}" "$HOME/.claude/skills/mechatronics-docs" "${CLAUDE_PROJECT_DIR:-}/.claude/skills/mechatronics-docs"; do [ -n "$d" ] && [ -f "$d/hooks/post_write_check.sh" ] && exec bash "$d/hooks/post_write_check.sh"; done; printf "%s\n" "{\"systemMessage\":\"vault validator: no reachable skill copy - vault rules are NOT enforced this turn\"}"; exit 0'
  Stop:
    - hooks:
        - type: command
          shell: bash
          command: 'for d in "${CLAUDE_PLUGIN_ROOT:-}" "$HOME/.claude/skills/mechatronics-docs" "${CLAUDE_PROJECT_DIR:-}/.claude/skills/mechatronics-docs"; do [ -n "$d" ] && [ -f "$d/hooks/stop_gate.sh" ] && exec bash "$d/hooks/stop_gate.sh"; done; printf "%s\n" "{\"systemMessage\":\"vault validator: no reachable skill copy - vault rules are NOT enforced this turn\"}"; exit 0'
---

# Mechatronics Project Documentation

You maintain engineering documentation in an Obsidian vault under the Single
Source of Truth principle: every piece of information exists exactly once,
and other files link to the file responsible for it instead of copying it.

## Activation Guard — MUST CHECK FIRST

This skill applies only to a vault the validator recognises. Take the folder
the user names, otherwise the `01_*` folder under the documentation root, and
run `python3 ${CLAUDE_SKILL_DIR}/validate_vault.py "<candidate>" 2>&1 >/dev/null`.
No output: it is a vault, your `VAULT_ROOT`. Output naming
`is not a vault root`: **stop**, tell the user this skill requires a
mechatronics baseproject vault, and do not adapt it to another layout.
Any other output, such as `validator crash`: tell the user, start no vault
work. If the vault's `00_*template*` files do not open with `---`, they
predate the frontmatter schema: update them first (`/baseproject-sync` where
installed) or stop. Use the folder names found on disk, in any language, and
only the domains present on disk — a missing one is not yours to assume.

## Before Any Action — Read Project Conventions

They are authoritative and evolve; never reproduce them from memory. (1) The
conventions file in `VAULT_ROOT` itself (`00_*convention*`/`00_*Konvention*`;
none: the root `README.md`) — the four questions before creating any file,
the role matrix, frontmatter, headings, identifiers, links, paths, length.
(2) The subfolders file (`*subfolder*`/`*Unterordner*`). (3) README and
template of each domain you will write in, only those, where present. (4) For
non-markdown artifacts, only the README you need: the documents README
(beside `VAULT_ROOT`), `50_sources/README.md` or `30_testdata/README.md`.

## Domain Reference — The 9 Roles

One question, one timeline per file — both quoted from the conventions file:

| Domain | Question | Timeline | Typical Trigger |
|--------|----------|----------|-----------------|
| REQ | What should be achieved? | Stable | New requirement, project start |
| DEC | Why was something chosen? | Slow | Trade-off between alternatives |
| ARC | How does everything connect? | Medium | Module decomposition, allocation |
| CMP | What do references say about a component? | Stable | New component with a datasheet |
| IFC | How do two system modules communicate? | Slow | New connection contract |
| IMP | How is it implemented? | Fast | Design files, parameters, paths |
| TAE | Did it work? | Slow | Test/verification completed |
| OAU | What do operation and usage look like? | Medium | Repeatable procedure needed |
| REF | What does the external reference say? | Stable | External document referenced |

ADM (98_administration: ToDos, blockers, milestones) and INB (99_inbox:
unsorted, sorted within 7 days) are not engineering documentation.

**The timeline column is the misplacement detector** — does the statement
change at the rate of the rest of the file? A parameter (fast) in ARC
(medium) is a leak, the most common defect: when it changes, the vault holds
two truths. The validator flags unit-bearing numbers and pin tokens in ARC
(ERROR) and a DEC Context (`impl-leak` WARN); every other domain is on you.

## Detail Ownership — One Fact, One File

A volatile fact — a filesystem path, a version, a CLI flag, a value with a
unit, a unit or service name, a function or file name, a port, a hostname —
is written down once; everywhere else it is named and linked, never
restated. It goes stale silently and first: 28.9% of popular GitHub projects
carry an outdated reference to a code element (arXiv 2212.01479).

1. **Name the owner, then link** — IMP for a project artifact, CMP for a
   datasheet value, IFC for a contract, TAE for a measurement. Others write
   the link (`[[IMP_...]]`) and the fact's role — "Link to it instead" (Google).
2. **The higher the abstraction, the shorter the mention.** ARC says a thing
   exists and what it connects to, never its settings — "Hide the inner
   workings of blackboxes!", "prefer relevance over completeness" (arc42).
3. **A decision records a choice, not an implementation** — "one or two
   pages long" (Nygard); the walk-through goes to IMP.
4. **Repetition inside one file counts too** — two places to repair.
5. **A fact that must appear twice is quoted** with the owning file named.

The check before any concrete value: *if this changes next month, how many
files become wrong?* More than one is a documentation defect.

## REQ↔TAE Coverage

Every requirement is closed by two relations: an allocation row in an ARC
file and a TAE naming it in `verifies:`. When you create or touch a REQ,
write both — the TAE in the same pass, or a planned/deferred TAE naming the
REQ and why it is open. An ID in prose, a heading or a list is not coverage;
the full audit reports either missing half as `req-uncovered`.

## Creation Order — Dependencies Matter

Earlier phases produce later link targets; never skip one, and work within a
phase in parallel: 1 REF, REQ → 2 DEC → 3 CMP parts → 4 IFC, CMP assemblies
→ 5 IMP → 6 TAE, OAU → 7 ARC → 8 system overview (new modules), glossary.
**Before writing a new DEC,** read the 3 most recently dated DEC files — they
prevent contradicting or duplicating a live decision.

## Cross-Linking Rules

1. **ARC is the orchestrator** — links REQ, DEC, CMP, IFC, IMP, TAE; no data.
2. **Link exact filenames** (`[[CMP_AD7175-2]]`); aliases only for display.
3. **Link the responsible file once where it matters** — no link carpets.
4. **Reference non-vault files relative to the project root** — only that
   form is checked; a foreign artifact names its host (see conventions file).
5. **Never duplicate content across files** — one owns it, others link.

## Content Boundaries — What Goes Where

| Information | WRONG Location | CORRECT Location |
|-------------|---------------|-----------------|
| Datasheet specifications | IMP | CMP (project-relevant extract) |
| Concrete parameter values (Kp, gain, voltage) | ARC or CMP | IMP |
| Design file paths (KiCad, CAD, code) | CMP | IMP References section |
| Calibration equation (as evidence) | IMP only | TAE Evidence + IMP (link to TAE) |
| Repeatable test procedure | TAE | OAU (TAE links to it) |
| Component selection rationale | CMP | DEC |
| Copy of a file this repository owns | IMP | The file itself (IMP carries the path) |
| State of, or command against, a foreign host | OAU, when it is a procedure | IMP, in a block naming the machine |
| External PDF (datasheet, standard) | 02_documents | 50_sources |
| Project-created PDF (export, report) | 50_sources | 02_documents |
| Raw test data | 32_processed | 31_raw (IMMUTABLE) |

## Rules — Critical Pitfalls

1. **Verify technical claims** — behavior, wiring, protocols and values come
   from an executed output, a measurement or a source, or are marked
   `(unverified)`. A user claim contradicting datasheet or code: flag, ask.
2. **One decision per DEC file** — decisions that change independently split.
3. **CMP is for things with datasheets**; a project-designed controller or
   firmware module is IMP (plus its own ARC if complex).
4. **IMP points, never copies, what this project owns** — a copy drifts, a
   path cannot. Records of another machine's state follow the IMP README.
5. **TAE Conclusion introduces no new values** — numbers appear in Evidence.
6. **A PCB gets a CMP Assembly file, each significant IC an Individual Part.**
7. **Keep every ARC module reachable** — top-level in the system overview
   (root file with `vault-role: system-overview`), submodules in the parent's.
8. **Discovery DECs start as Draft** — no irreversible decision on your own.
9. **Frontmatter is part of the file** — real values in every template
   field; `last-verified` updated on every confirmation; draft relaxes nothing.

## Process — Documenting a Feature

1. **Assess scope** among the domains present — hardware: REF, DEC, CMP, IFC,
   IMP, ARC (+TAE, OAU); software: DEC, IMP, ARC (+REQ, TAE, OAU); tests: TAE, OAU.
2. **Ask for what is missing** after checking the vault, as few questions as
   possible — alternatives (DEC), parameters (IMP), verified requirements
   (TAE); then read the templates of each domain and follow them exactly.
3. **Create files in phase order** — four questions, template structure,
   frontmatter, links to files already made, TBD for genuinely open points.
4. **Invalidation sweep after every change** — search the vault for the
   changed artifact (name, path, parameter) and revise every note it
   falsifies in the same pass, in its owning file. Stale docs mislead.
5. **Update the umbrella files** — system overview, parent ARC, glossary.
6. **Full audit for what spans the vault** — the hooks check touched files;
   `python3 ${CLAUDE_SKILL_DIR}/validate_vault.py <VAULT_ROOT>` adds the
   vault-wide findings (`req-uncovered`, orphans). Resolve every ERROR; fix
   each WARN or say in one line why it stands (`impl-leak`: justify or move).
7. **Report** files with domain and question, every touched REQ with its TAE.

## Enforcement Layer — What the Hooks Tell You

From the skill's first invocation to the end of the session, two hooks run
`validate_vault.py` (which copy: `REFERENCE.md`) — structure, not truth.

- **After each `Edit`/`Write`/`MultiEdit`** into a vault, that file's
  findings reach you: fix ERRORs now, fix WARNs or say why they stand.
  Unresolved links come as one line — fine mid-pass, resolved by turn end.
- **`Stop hook feedback:`** is the only blocking channel: the ERRORs this
  session introduced. ERRORs present at git HEAD never block.
- **`Stop says: ...`** is the session report for the user, not for you.
- **`vault validator crashed`**: that write or turn went unchecked — verify
  by hand before finishing.

Edits in a session that never invoked this skill, and subagent writes, are
not validated in-session; only a CI workflow or the pre-commit hook, where
turned on, catches them. So: **never modify vault files through Bash**
(`sed -i`, `tee`, heredocs); **never delegate vault writing to subagents**
(research may be delegated); **do not evade findings** — moving content to
`99_inbox`, stub link targets or deleted references show in the report.

## Reference — One Level Deeper

`REFERENCE.md` beside this file covers the tools around the vault on demand:
the traceability export (for a larger pass, generate `traceability_index.md`
and read it instead of searching), which copy enforces, the out-of-session
tiers, the stop messages in full. `ARCHITECTURE.md` maps checks to functions.

## Closing Checklist — Answer Each with Yes Before Finishing

1. Every created file passed the conventions file's four questions?
2. Frontmatter complete and true in every touched file, `last-verified` set?
3. Every behavioral claim evidenced or marked `(unverified)`?
4. Implementation values only in IMP/CMP/IFC/TAE/REQ tables, each volatile fact in one file?
5. Invalidation sweep done — no note contradicts the new state?
6. Every touched REQ has a verifying TAE (or a recorded deferred one)?
7. System overview / parent ARC / glossary updated where needed?
8. Full audit ran; vault-wide findings resolved or triaged?
9. Report delivered (files, questions answered, REQ coverage)?

## File Placement & Naming — Quick Reference

| Artifact | Structural Pattern |
|----------|--------------------|
| Vault markdown (REQ–REF) | `{VAULT_ROOT}/[NN_domain_(ABBR)]/ABBR_name.md` |
| Project-internal non-markdown | `00_*/02_*/[NN_domain]/type__desc__YYYY-MM-DD__rev-N.ext` |
| External sources | `50_*/...` (see its README for per-type naming) |
| Raw test data (IMMUTABLE) | `30_*/31_*/YYYY-MM-DD_campaign/` |
| Processed test data | `30_*/32_*/YYYY-MM-DD_campaign/` |
| CAD sources / exports | `10_*/11_*|13_*/ and 10_*/12_*/` |
| Source code | `20_*/` |

Requirement IDs: `REQ-DOM-NNN` — DOM from the REQ filename parentheses,
NNN sequential, never reused, gaps allowed.
