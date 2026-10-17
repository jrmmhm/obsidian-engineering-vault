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

You create and maintain engineering documentation in a structured Obsidian
vault following the Single Source of Truth (SSOT) principle. Every piece of
information exists exactly once — files link to responsible documents instead
of copying content.

## Activation Guard — MUST CHECK FIRST

This skill applies ONLY to a vault the validator recognises; folder names may
be English, German or mixed. Before doing anything else, take the folder the
user names, otherwise the `01_*` folder under the documentation root, and run
`python3 ${CLAUDE_SKILL_DIR}/validate_vault.py "<candidate>" 2>&1 >/dev/null`.
No output: it is a vault — store it as `VAULT_ROOT`. Output naming
`is not a vault root`, or any other output such as `validator crash`:
**stop immediately**, tell the user this skill requires a mechatronics
baseproject vault (or that the check failed), and do not attempt partial
documentation or adapt the skill to a different structure. If the vault's
`00_*template*` files do not open with `---`, they predate the frontmatter
schema: bring them to the current base template first (`/baseproject-sync`
where installed).

If the checks pass: use the discovered `VAULT_ROOT` and the actual folder
names found on disk. Never assume English or German — use what exists.

## Before Any Action — Read Project Conventions

They are authoritative and evolve between projects; never reproduce them
from memory. (1) The conventions file in `VAULT_ROOT`
(`00_*convention*`/`00_*Konvention*`, where present) — SSOT principle, the
four questions before creating any file, role matrix, timelines, file
conventions (frontmatter, headings, self-containedness, wikilinks, paths,
length, freshness). (2) The subfolders conventions file
(`*subfolder*`/`*Unterordner*`). (3) For each domain you will write in, and
only those: its `00_[DOMAIN]_README.md` and `00_[DOMAIN]_file_template.md`
where present. (4) For non-markdown artifacts, only the README you need: the
documents README (beside `VAULT_ROOT`), `50_sources/README.md` or
`30_testdata/README.md`.

## Domain Reference — The 9 Roles

Each file answers ONE question in ONE timeline, quoted from the conventions file:

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
unsorted material, sorted within 7 days) are NOT engineering documentation.

**The timeline column is the misplacement detector** — does the statement
change at the rate of the rest of the file? A parameter (fast) in ARC
(medium) is a leak, the most common defect: when it changes, the vault holds
two truths. The validator flags unit-bearing numbers and pin tokens in ARC
(ERROR) and in a DEC Context (`impl-leak` WARN); every other domain is on you.

## Detail Ownership — One Fact, One File

The timeline column above says which file a statement belongs in. This
section says what happens to the *other* files, and it is the rule that
was missing: a volatile fact may be written down once. Everywhere else it
is named and linked, never restated.

A volatile fact is anything that changes without the surrounding document
changing: a filesystem path, a version, a CLI flag, a value with a unit, a
unit or service name, a function or file name, a port, a hostname.

Why this is a rule and not a preference. Documentation goes stale
silently — no build breaks, no test fails — and the content that goes
stale first is exactly this: 28.9% of the most popular GitHub projects
currently carry at least one outdated reference to a code element, and
82.3% carried one at some point (arXiv 2212.01479). A fact written in one
file ages in one place and is repaired in one place. The same fact written
in five files ages in five and is repaired in one, and the vault then holds
four confident, wrong answers with no way to tell them from the right one.
Measured in a real vault of this method: one database path appeared in 23
files across five domains including the requirements and the architecture
map, the decisions domain carried 138 distinct filesystem paths, the
components domain 66.

The rules:

1. **Name the owner, then link.** Every volatile fact has exactly one
   owning file — normally IMP for a project artifact, CMP for a datasheet
   value, IFC for a contract, TAE for a measurement. Other notes write the
   link (`[[IMP_...]]`) and the *role* the fact plays, never the fact.
   Google's own style guide states the general form: "Do not write your own
   guide to a common Google technology or process. Link to it instead."
2. **The higher the abstraction, the shorter the mention.** arc42 on the
   building-block view: "Hide the inner workings of blackboxes!" and
   "prefer relevance over completeness" — document the "important,
   surprising, risky, complex or volatile" parts and leave out the "normal,
   simple, boring or standardized" ones. ARC states that a thing exists and
   what it connects to. It never states what the thing is set to.
3. **A decision records a choice, not an implementation.** Nygard's ADR
   format is one page: "The whole document should be one or two pages
   long." A DEC that walks through the implementation has stopped being a
   decision record; move the walk-through to IMP and keep the trade-off.
4. **Repetition inside one file counts too.** A value stated in the context
   section and again in the conclusion is two places to repair.
5. **When a fact must appear twice, the second occurrence is a quote with a
   source.** Name the owning file on the same line. A reader who finds a
   contradiction then knows which one is authoritative — without that, both
   are equally credible and both are useless.

The check before you write any concrete value: *if this changes next
month, how many files in this vault become wrong?* More than one is a
defect in the documentation, not a property of the system.

## REQ↔TAE Coverage

Every requirement must be answerable by evidence, and the loop closes
through two relations, not one: an allocation row in an ARC file names the
requirement, and a TAE names it in its `verifies:` frontmatter. When you
create or touch a REQ, write both — create the TAE in the same pass, or
record a planned/deferred TAE naming the REQ and the reason it is still
open. Naming the identifier in a paragraph, a heading or a list of open
points is not coverage and is not counted as any: the validator reads the
allocation table and the `verifies:` field, never the prose around them. An
unverified REQ is an incomplete REQ, and the full audit reports it as
`req-uncovered`, naming which of the two halves is missing. Write the
acceptance criterion from what the requirement demands, not from the evidence
at hand; a clause without evidence keeps the row `Draft` or `Approved`
(Column 4 rule, ARC README) — weakening it is a REQ change with its own
reason, never a step toward `Verified`.

## Creation Order — Dependencies Matter

Earlier phases produce later link targets; never skip one, and work within
a phase in parallel: 1 REF, REQ → 2 DEC → 3 CMP parts → 4 IFC, CMP
assemblies → 5 IMP → 6 TAE, OAU → 7 ARC (links everything) → 8 system
overview (new modules), glossary (new terms). Unresolved links are tolerated
mid-pass (WARN) but block at turn end (ERROR). **Before writing a new DEC,**
read the 3 most recently dated DEC files — they prevent contradicting or
duplicating a live decision.

## Cross-Linking Rules

1. **ARC is the orchestrator** — links REQ, DEC, CMP, IFC, IMP, TAE; NO data.
2. **Link with exact filenames** (`[[CMP_AD7175-2]]`); aliases only for display.
3. **Link the responsible file once where it matters** — no link carpets.
4. **Use relative project paths** for non-vault files — only that form is
   checked (dead: ERROR under References/Sources in any template language,
   WARN elsewhere, where a pending/planned/TBD marker on the line or its
   heading silences it); a path from a filesystem root, `~`, a host or a URL
   is never checked, so a foreign artifact names its host (conventions file,
   "Paths and artifacts on other machines").
5. **Never duplicate content across files** — one file owns it, others link.

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

1. **Verify technical claims** — behavior, wiring, protocols and values come
   from an executed output, a measurement or a source, or are marked
   `(unverified)`. A user claim contradicting datasheet or code: flag, ask.
2. **One decision per DEC file** — decisions that change independently split.
3. **CMP is for things with datasheets**; a project-designed controller or
   firmware module is IMP (plus its own ARC if complex).
4. **IMP points, never copies, what this project owns** — a copy drifts, a
   path cannot; records of another machine's state follow the IMP README.
   A repeatable procedure is OAU; IMP stays 1–2 pages; ARC carries no block.
5. **TAE Conclusion introduces no new values** — numbers appear in Evidence.
6. **A PCB gets a CMP Assembly file, each significant IC an Individual Part.**
7. **Keep every ARC module reachable** — top-level in the system overview
   (the root file with `vault-role: system-overview`), submodules in the
   parent's table; `arc-not-in-overview` names what neither reaches.
8. **Testdata campaigns need metadata.txt** linking back to the TAE file;
   raw data in 31_testdata_raw is IMMUTABLE.
9. **Discovery DECs start as Draft** — no irreversible decision on your own.
10. **Frontmatter is part of the file** — real values in every template
   field (DEC: the body `Status:` line carries the status; TAE: `verifies`,
   and `test-object` when measured on a component, interface or module);
   `last-verified` updated on every confirmation; draft relaxes nothing.

## Process — Documenting a Feature

1. **Assess scope** — hardware: REF, DEC, CMP, IFC, IMP, ARC (+TAE, OAU
   later); software: DEC, IMP, ARC (+REQ, TAE, OAU); tests: TAE, OAU.
2. **Ask for missing information** after checking the vault, as few questions
   as possible — alternatives (DEC), parameters (IMP), verified REQs (TAE).
3. **Read the templates, then create files in phase order** — 4-question
   rule, template structure, frontmatter, links to files already made, TBD
   for genuinely open points.
4. **Invalidation sweep — after every change.** Search the vault for the
   changed artifact (component name, file path, parameter) and revise every
   note it falsifies in the same pass, in its owning file — never add a
   contradicting note. Stale documentation is worse than none: it misleads.
5. **Update the umbrella files** — system overview, parent ARC, glossary.
6. **Full audit before finishing** — run
   `python3 ${CLAUDE_SKILL_DIR}/validate_vault.py <VAULT_ROOT>`, resolve
   every ERROR, triage WARNs (fix, or state in one line why acceptable;
   `impl-leak`: justify the value's location or move it to IMP/CMP/IFC).
7. **Report** created/updated files with domain and the question each
   answers, and every touched REQ with its verifying TAE; flag gaps.

## Enforcement Layer — What the Hooks Tell You

From this skill's first invocation to the end of the session, two hooks
enforce the mechanically checkable vault rules (`validate_vault.py`, same
directory) — never in a session that does not invoke it, nor on subagent writes.

- **After every `Edit`/`Write`/`MultiEdit`** into a vault, the written
  file's findings reach you: fix ERRORs now, address WARNs or state why
  they stand. WARNs the file already carried at git HEAD are not repeated,
  only counted when anything else is shown. Unresolved links arrive as one
  line — expected mid-pass, but every target must exist by turn end.
- **At turn end** a stop gate re-checks every vault file touched this
  session. ERRORs this session introduced block completion, once per stop
  sequence; violations already present at git HEAD never block. Vault-wide
  findings (uncovered REQs, orphans, ...) are advisory — in full the first
  time and whenever they change, otherwise as one `vault-wide findings
  unchanged` line; the full audit in step 6 remains the authoritative pass.

Two readers, two channels. Everything advisory reaches the user as
`Stop says: ...` — legacy findings, created files, questions for the
session owner — and is not an instruction to you. Its first line is
`vault validator blocked the turn end` when the gate blocked and
`vault validator session report:` when it did not — also when it released
after one demand in this stop sequence, where the report opens with
`UNRESOLVED vault ERRORs`. What the gate wants from *you* arrives as
`Stop hook feedback:` and names only the ERRORs this session introduced.
`vault validator crashed` means that write or turn went unchecked: verify
by hand before finishing.

Until the pre-commit hook or a CI workflow is turned on (`REFERENCE.md`), an
edit made in Obsidian, by hand, by a subagent or without invoking this skill
reaches the vault unchecked. So: **never modify vault files through Bash**
(`sed -i`, `tee`, heredocs) — the hooks only see `Edit`/`Write`/`MultiEdit`;
**never delegate vault writing to subagents** (research may be delegated);
**do not evade findings** — moving content to `99_inbox`, stub link targets,
a deleted reference or a `validator-accept` entry the user did not ask for
all show in the session report: never add one. The validator enforces
structure, not truth; domain choice, content boundaries and factual accuracy
remain yours.

## Reference — One Level Deeper

`REFERENCE.md` beside this file is read on demand: the traceability export
(run it when the user asks for a traceability matrix, a coverage overview or
something for a reviewer; before a larger pass, generate
`traceability_index.md` and read it once instead of searching the vault),
which copy of this skill enforces (check when a rule this file describes
appears not to be enforced), and the tiers outside a session.
`ARCHITECTURE.md` maps checks to functions, for whoever maintains the tool.

## Closing Checklist — Answer Each with Yes Before Finishing

1. Every created file passed the 4-question rule (one question, role, timeline)?
2. Frontmatter complete and true in every touched file, `last-verified` updated?
3. Every behavioral claim evidenced or marked `(unverified)`?
4. No concrete implementation values outside IMP/CMP/IFC/TAE/REQ tables,
   and every volatile fact you wrote owned by exactly one file — no path,
   version, flag, value or unit name restated in a second note?
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
