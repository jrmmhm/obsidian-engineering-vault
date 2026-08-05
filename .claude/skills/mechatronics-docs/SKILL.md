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
invocation: auto
hooks:
  PostToolUse:
    - matcher: "Edit|Write|MultiEdit"
      hooks:
        - type: command
          shell: bash
          command: 'for d in "$CLAUDE_PROJECT_DIR/.claude/skills/mechatronics-docs" "$HOME/.claude/skills/mechatronics-docs"; do [ -f "$d/hooks/post_write_check.sh" ] && exec bash "$d/hooks/post_write_check.sh"; done; exit 0'
  Stop:
    - hooks:
        - type: command
          shell: bash
          command: 'for d in "$CLAUDE_PROJECT_DIR/.claude/skills/mechatronics-docs" "$HOME/.claude/skills/mechatronics-docs"; do [ -f "$d/hooks/stop_gate.sh" ] && exec bash "$d/hooks/stop_gate.sh"; done; exit 0'
---

# Mechatronics Project Documentation

You create and maintain engineering documentation in a structured Obsidian
vault following the Single Source of Truth (SSOT) principle. Every piece of
information exists exactly once — files link to responsible documents instead
of copying content.

## Enforcement Layer — How This Skill Is Gated

While this skill is active, two hooks enforce the mechanically checkable
vault rules (`validate_vault.py`, same directory):

- After every `Edit`/`Write`/`MultiEdit` into a vault, the validator checks
  the written file and feeds findings back. Fix ERRORs immediately, while
  the context is fresh. WARNs are advisory — address them or state briefly
  why they are acceptable. Unresolved-link WARNs arrive as one aggregated
  summary line: forward references are expected mid-pass under the phased
  creation order, but every target must exist by turn end.
- At turn end, a stop gate re-checks every vault file touched this session.
  ERRORs newly introduced this session block completion (pre-existing
  violations in legacy files are reported but never block — ratcheted
  against the git HEAD state). The non-blocking session report also lists
  vault-wide findings (uncovered REQs, orphans, ...) as advisory — they
  never block; the full audit in step 7 remains the authoritative pass.
  It further names every ERROR code a file carried at git HEAD that did
  not fire at all this session. Say which of them you fixed: a defect you
  repaired and a check that stopped reaching the file produce the same
  absence, and only the session knows which of the two it did.

The two halves of the gate address two readers, and the transcript shows
which is which. Everything advisory appears as `Stop says: vault
validator session report: ...` — that line is for the user; it lists
legacy findings, created files and questions the session owner has to
answer, and it is not an instruction to you. What the gate wants from
*you* arrives as `Stop hook feedback:` and names only the ERRORs this
session introduced. A released gate says so too: `vault validator
crashed - stop gate released` means the vault rules went unchecked for
that turn, so verify by hand before finishing.

A vault carrying two folders for one domain — `03_architecture_(ARC)`
beside `03_Architektur_(ARC)`, which is what a half-finished translation
looks like — is reported as `domain-duplicate-folder`. The folder the
vault reads is the first in sorted order among those holding files of the
domain, never the one the file system happened to return last, so the
same vault says the same thing on every machine. WARN and vault-wide: two
folders for a while are a legitimate transitional state, so it never
blocks. Finish the translation or delete the folder you no longer write
to; while both exist, only the chosen one feeds the requirement index,
the architecture overview and the traceability export.

Which frontmatter fields exist, of what type and with which permitted
values, is declared in `vault_schema.json` beside the validator — the
validator reads it rather than knowing the rules by heart. A key that is
declared neither for its domain nor as an editor field (Obsidian's own
`tags`, `aliases`, ... and the `excalidraw-*` family) is reported as
`frontmatter-undeclared`. It is a WARN, because a stray key can be a
deliberate plugin field — but a mistyped one is the single frontmatter
defect that fails completely silently, so do not wave it through: either
fix the spelling or declare the field in the schema.

Which H2 sections a file must carry is derived from that domain's own
`00_*template*` file. The comparison ignores case and invisible differences
(umlaut encoding, zero-width characters, collapsed whitespace), so a section
written `## allgemeine Übersicht` counts as present — it is reported as
`section-near-miss` (WARN) naming both spellings and the line, because the
template's spelling is what a reader and a search look for. A title the
template does not carry is a different matter: `## Ablauf (monatlich)` and
`## Zuordnung` for a required `## Zuordnung und Verifikation` are
`section-mismatch` (ERROR) — a differently scoped section is a different
section, and the heading is the anchor other notes bind to. Keep the
template's title and put the qualifier in an `###` below it.

A second tool beside the validator reads the same schema for a different
purpose. `export_traceability.py` walks the declared relations into a
graph and writes the vault out as a traceability artifact:

```bash
python3 .claude/skills/mechatronics-docs/export_traceability.py \
        <VAULT_ROOT> --output-dir <DIR outside the vault>
```

It produces a self-contained HTML report, two CSV views, a JSON graph and
`traceability_index.md`. The index is the one written for you: one line
per object and per requirement — identifier, domain, file, and the first
sentence of the section the project's own requirements template binds.
Generate it and read it once instead of searching the vault for its
structure, and generate it again rather than trusting a copy from an
earlier session; nothing about it is stored in the vault.
Every reverse relation in these artifacts is computed, never read from a
file. Run it when the user asks for a traceability matrix, a coverage overview, or
something to hand to a reviewer — and read its findings section as you
would the validator's: an unbound table, an unresolved requirement ID, an
unknown domain abbreviation or two folders meaning one domain each mean
the export understood less of the vault than it looks like it did. The exporter never blocks a turn.

Two further tiers run the same validator without Claude Code, so a change
authored in Obsidian or by hand is covered too: a pre-commit hook
(`hooks/pre_commit_vault.sh`, install by symlinking it to
`.git/hooks/pre-commit`) that reports findings in the staged files and
only blocks when `MECHDOCS_PRECOMMIT_BLOCK=1` is set, and a GitHub
Actions workflow that runs the test suite and the full vault audit on
every push and pull request.

Which copy of this skill a session is actually running is a separate
question, and one a global `~/.claude/skills/` entry cannot answer by
itself — it may be a symlink carrying a path that only one machine can
follow. `python3 ${CLAUDE_SKILL_DIR}/validate_vault.py --check-install`
says whether that entry reaches this copy, reaches a different one, or
reaches nothing at all. Run it when a rule this file describes appears
not to be enforced.

Rules that follow from this mechanism:

1. **Never modify vault files through Bash** (`sed -i`, `tee`, heredocs) —
   the hooks only see `Edit`/`Write`/`MultiEdit`. Bash mutations bypass
   validation and are forbidden.
2. **Never delegate vault writing to subagents** — hooks do not fire for
   subagent tool calls. Research may be delegated; writing stays here.
3. **Do not evade findings.** Moving content to `99_inbox` to dodge an
   ERROR, creating stub link targets, or deleting a reference instead of
   fixing it defeats the purpose and is visible in the session report.
4. The validator enforces structure, not truth. Everything semantic —
   correct domain choice, content boundaries, factual accuracy — remains
   your responsibility under the rules below.

## Activation Guard — MUST CHECK FIRST

This skill applies ONLY to mechatronics projects derived from the baseproject
template. Projects may use English, German, or mixed folder names. Before
doing anything else, verify the layout:

1. **Documentation root exists:** a subfolder starting with `01_` (the vault)
   or named `docs`/`documentation`. Store the vault path as `VAULT_ROOT`.
2. **Vault has numbered domain subfolders:** `VAULT_ROOT` contains at least
   3 subfolders with numeric prefixes `01_`–`09_` and `(ABBR)` suffixes.

If ANY check fails: **stop immediately.** Tell the user this skill requires a
mechatronics baseproject layout. Do not attempt partial documentation. Do not
adapt the skill to a different structure.

If the checks pass: use the discovered `VAULT_ROOT` and the actual folder
names found on disk. Never assume English or German — use what exists.

## Before Any Action — Read Project Conventions

Read these before creating or modifying documentation; they are authoritative
and evolve between projects, so never reproduce them from memory:

1. The conventions file (matches `*convention*` or `*Konvention*`) — SSOT
   principle, 4-question rule, role matrix, timelines, file conventions
   (frontmatter, self-containedness, wikilinks, length, freshness)
2. The subfolders conventions file (matches `*subfolder*` or `*Unterordner*`)
3. For each domain you will write in: its `00_[DOMAIN]_README.md` and
   `00_[DOMAIN]_file_template.md` (locate by domain suffix). Do NOT read
   READMEs/templates of domains you will not touch this pass.
4. When placing non-markdown artifacts: the documents README (sibling of
   `VAULT_ROOT`), `50_sources/README.md`, or `30_testdata/README.md` —
   only the one you actually need.

## Domain Reference — The 9 Roles

Each file answers ONE question and lives in ONE timeline:

| Domain | Question | Timeline | Typical Trigger |
|--------|----------|----------|-----------------|
| REQ | What should be achieved? | Stable | New requirement, project start |
| DEC | Why was X chosen over Y? | Slow | Trade-off between alternatives |
| ARC | How does everything connect? | Medium | Module decomposition, allocation |
| CMP | What are the building blocks? | Stable | New component with a datasheet |
| IFC | How do two modules communicate? | Slow | New connection contract |
| IMP | How is it concretely implemented? | Fast | Design files, parameters, paths |
| TAE | Did it work? | Slow | Test/verification completed |
| OAU | How is it operated/used? | Medium | Repeatable procedure needed |
| REF | What does the external source say? | Stable | External document referenced |

Two additional folders are NOT engineering documentation:
- **ADM** (98_administration): project management — ToDos, blockers, milestones
- **INB** (99_inbox): temporary unsorted material — sorted within 7 days

**The timeline column is the misplacement detector.** Before writing any
statement, ask: does this statement change at the same rate as the rest of
this file? A concrete parameter (changes fast) inside an ARC file (changes
medium) is a leak — when it later changes, the vault holds two truths. This
is the single most common documentation defect in practice: implementation
details casually dropped into ARC, CMP, DEC or REQ files. The validator
catches numbers in ARC mechanically; every other domain is on you.

## The 4-Question Rule — Before Creating ANY File

1. **Right to exist?** Does this file answer ONE clear question not answered
   elsewhere? If the answer lives in an existing file, link instead.
2. **Which role?** Exactly ONE domain from the table.
3. **Timeline consistent?** All content shares one change rate. Content
   spanning timelines is split into separate files.
4. **Subfolder needed?** Only if same role AND same change rate AND same
   core object (3-question rule in the conventions file).

**REQ↔TAE coverage.** Every requirement must be answerable by evidence, and
the loop closes through two relations, not one: an allocation row in an ARC
file names the requirement, and a TAE names it in its `verifies:`
frontmatter. When you create or touch a REQ, write both — create the TAE in
the same pass, or record a planned/deferred TAE naming the REQ and the
reason it is still open. Naming the identifier in a paragraph, a heading or
a list of open points is not coverage and is not counted as any: the
validator reads the allocation table and the `verifies:` field, never the
prose around them. An unverified REQ is an incomplete REQ, and the full
audit reports it as `req-uncovered`, naming which of the two halves is
missing.

## Creation Order — Dependencies Matter

Create files in this phase order; earlier phases produce the link targets
later phases reference:

```
Phase 1: REF (source extracts), REQ (requirements)
Phase 2: DEC (one decision per file; links REQ, REF)
Phase 3: CMP individual parts (links REF, DEC)
Phase 4: IFC contracts, CMP assemblies (link CMP)
Phase 5: IMP (links IFC, CMP, DEC)
Phase 6: TAE (verifies REQ), OAU (links REQ, IMP, CMP)
Phase 7: ARC (orchestrator; links everything)
Phase 8: system_overview.md (new ARC modules), 00_glossary.md (new terms)
```

Create files within each phase in parallel. Never skip a phase — missing
link targets break traceability. Unresolved links are tolerated mid-pass
(WARN) but block at turn end (ERROR), so finish every pass with all targets
existing.

**Before writing a new DEC:** read the 3 most recently dated DEC files in
the vault. Recent decisions are the highest-value context — they prevent
contradicting or duplicating a live decision.

## Cross-Linking Rules

1. **ARC is the orchestrator.** It links to REQ, DEC, CMP, IFC, IMP, TAE
   but stores NO data. ARC is a map, not a data sink.
2. **Link with exact filenames** (`[[CMP_AD7175-2]]`). Aliases are allowed
   for prose readability, but the target must be the exact filename.
3. **Link the responsible file once where it matters** — not every mention.
   The vault traces from architecture down into every detail through few,
   deliberate links, not through link carpets.
4. **Use relative project paths** for non-vault files (testdata, source
   code, CAD, 02_documents, 50_sources). Paths must exist — a dead path
   is an ERROR in References/Sources sections and a WARN anywhere else
   in the body. Mark intentionally-not-yet-existing paths with
   pending/planned/TBD on the line or its heading; markers never
   silence References/Sources sections.
   Only the relative form is checked. A path that starts at a
   filesystem root, at `~`, at a host name or at a URL scheme names an
   artifact on another machine — it is never reported as dead, and for
   the same reason never verified. So write a project artifact
   relatively, or you switch its staleness check off, and name the host
   when the artifact is foreign: the path alone does not say which
   machine it is true on.
5. **Never duplicate content across files.** One file owns the information,
   others link to it.

## Content Boundaries — What Goes Where

The most common misplacements. Follow strictly:

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

1. **Verify technical claims before documenting.** Any statement about
   behavior, wiring, protocols or measured values is either (a) taken from
   an executed output, a measurement or a referenced source, or (b)
   explicitly marked `(unverified)` in the text. If the user's claim
   contradicts a datasheet or the code, flag the discrepancy and ask.
   Roughly a fifth of plausible-sounding generated statements about
   systems are wrong — evidence beats plausibility.
2. **One decision per DEC file.** Decisions that change independently get
   separate files.
3. **CMP is for things with datasheets.** A project-designed controller or
   firmware module is IMP (plus its own ARC if complex), not CMP.
4. **IMP is pointers, not copies — for artifacts this project owns.** If the
   thing exists as a file in this repository, reference its path and copy
   nothing: a copy drifts against its original, a path cannot. An artifact
   that is not a file here — the state of another machine, a command that
   establishes or verifies one — has no path to point at. It is not a copy
   but a record of an observation, it stays in IMP, and `last-verified`
   carries its currency. Blocks up to 15 content lines are single
   observations and need nothing; a longer block must either give way to a
   path or name the machine it is true on, in the fence's info string:
   ```` ```bash host=userver ````. Use the same machine name as in a
   host-qualified path (rule 4 under Cross-Linking), and name the machine,
   never `localhost` — this vault is read on other machines than yours.
   A repeatable multi-step procedure is OAU; a single verification command
   is not a runbook and does not become one by being moved. Keep IMP short
   (1–2 pages). In ARC no block is allowed at all — ARC is a map.
5. **TAE Conclusion introduces no new values** — all numbers appear in
   Evidence first.
6. **Both Assembly AND Individual Parts for PCBs.** The board gets a CMP
   Assembly file; each significant IC gets a CMP Individual Part file.
7. **Always update system_overview.md** for new ARC modules.
8. **Testdata campaigns need metadata.txt** linking back to the TAE file.
   Raw data in 31_testdata_raw is IMMUTABLE.
9. **DEC files for discoveries start as Draft.** Never make irreversible
   design decisions autonomously.
10. **Frontmatter is part of the file.** Fill `domain`, `status`, `created`,
    `last-verified` (DEC: no frontmatter `status` is required — the body
    `Status:` line carries it, beside the reasoning; TAE: `verifies`, and
    `test-object` when the note was measured on a component, an interface
    or a module) with real values from the template.
    Update `last-verified` whenever you confirm a file's content is still
    true. `status: draft` relaxes nothing.

## Process — Documenting a Feature

1. **Assess scope.** Which domains are affected? Hardware feature: REF,
   DEC, CMP, IFC, IMP, ARC (+TAE, OAU later). Software feature: DEC, IMP,
   ARC (+REQ, TAE, OAU). Test campaign: TAE, OAU (+testdata structure).

2. **Ask for missing information.** Check the vault first, then ask as few
   questions as possible — alternatives considered (DEC), concrete
   parameters (IMP), verified requirements (TAE) — before writing
   incorrect docs.

3. **Read the templates** for each affected domain and follow them exactly.

4. **Create files in phase order.** For each file: 4-question rule, exact
   template structure, frontmatter filled, cross-links to already-created
   files, TBD markers for genuinely open information.

5. **Invalidation sweep — after every change.** The change you just
   documented may falsify existing notes. Search the vault for references
   to the changed artifact or topic (grep for the component name, file
   path, parameter). Update affected notes in the same pass — revise the
   owning file rather than adding a contradicting note elsewhere. Stale
   documentation is worse than none: it actively misleads.

6. **Update the umbrella files.** system_overview.md (new ARC modules),
   parent ARC allocation tables, 00_glossary.md (new terms).

7. **Full audit before finishing.** Run
   `python3 ${CLAUDE_SKILL_DIR}/validate_vault.py <VAULT_ROOT>`
   and resolve every ERROR; triage WARNs (fix, or state in one line why
   acceptable — especially `impl-leak` flags: justify the value's location
   or move it to IMP/CMP/IFC).

8. **Report.** List created/updated files with domain and the question each
   answers; list every touched REQ with its verifying TAE and flag gaps.

## Closing Checklist — Answer Each with Yes Before Finishing

1. Every created file passed the 4-question rule (one question, one role,
   one timeline)?
2. Frontmatter complete and true in every touched file (`last-verified`
   updated)?
3. Every behavioral claim evidenced or marked `(unverified)`?
4. No concrete implementation values outside IMP/CMP/IFC/TAE/REQ tables?
5. All wikilinks resolve; all referenced artifact paths exist?
6. Invalidation sweep done — no existing note contradicts the new state?
7. Every touched REQ has a verifying TAE (or a recorded deferred one)?
8. system_overview / parent ARC / glossary updated where needed?
9. Full vault audit ran with zero ERRORs; WARNs triaged?
10. Report delivered (files, questions answered, REQ coverage)?

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
