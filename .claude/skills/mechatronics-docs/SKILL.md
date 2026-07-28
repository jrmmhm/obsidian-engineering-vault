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

**REQ↔TAE coverage.** Every requirement must be answerable by evidence. When
you create or touch a REQ, ensure at least one TAE names it in its
`verifies:` frontmatter — create that TAE in the same pass, or record a
planned/deferred TAE naming the REQ and the reason it is still open. An
unverified REQ is an incomplete REQ, and the full audit reports it.

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
| Code blocks / firmware snippets | IMP | Source files (IMP has paths only) |
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
4. **IMP is pointers, not copies.** Reference artifact paths; never embed
   code blocks or schematics. Keep IMP short (1–2 pages).
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
    `last-verified` (TAE: `verifies`) with real values from the template.
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
   `python3 ~/.claude/skills/mechatronics-docs/validate_vault.py <VAULT_ROOT>`
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
