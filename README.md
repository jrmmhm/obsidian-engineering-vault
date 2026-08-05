<div align="center">

# Obsidian Engineering Vault

**A documentation system for hardware, firmware and software projects —
built so that both humans and AI agents can be trusted with it.**

Every requirement traces to a proof. Every file answers exactly one question.
A validator enforces it mechanically, so the documentation cannot quietly rot.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Use this template](https://img.shields.io/badge/GitHub-use%20this%20template-2ea44f?logo=github)](../../generate)
[![Obsidian](https://img.shields.io/badge/Obsidian-vault-7C3AED?logo=obsidian&logoColor=white)](https://obsidian.md)
[![Claude Code skill](https://img.shields.io/badge/Claude%20Code-skill%20included-D97757)](.claude/skills/mechatronics-docs)
[![Vault checks](https://github.com/jrmmhm/obsidian-engineering-vault/actions/workflows/validate-vault.yml/badge.svg?branch=main)](https://github.com/jrmmhm/obsidian-engineering-vault/actions/workflows/validate-vault.yml)

</div>

---

## The problem this solves

Engineering documentation fails in a specific, predictable way. The same fact
gets written down in three places, two of them go stale, and nobody can tell
which one is current. A requirement exists but nothing proves it was ever met.
Six months later the only reliable source is the person who built the thing.

Point an AI agent at that, and it does not get better — it gets faster. Agents
retrieve by exact text search. Documentation that is implicit, duplicated or
out of date does not merely fail to help them; it actively misleads them, at
scale.

This template is the opposite bet: **one question per file, one place per fact,
and a machine that checks it.**

---

## How the pieces connect

The nine domains are not a pipeline. **`ARC` is the orchestrator** — one note per
module that references every other domain and owns none of their content. Read
an ARC note and you have the whole module; read it and follow one link and you
have the detail.

```mermaid
flowchart TB
    SYS(["<b>system_overview</b> — the way in<br/>lists every top-level module"])

    REF["<b>REF</b><br/>external truth<br/><i>datasheet · standard · manual</i>"]
    REQ["<b>REQ</b><br/>what must hold<br/><i>REQ-DOM-NNN + acceptance</i>"]
    DEC["<b>DEC</b><br/>why this way<br/><i>options · consequences</i>"]

    ARC{{"<b>ARC — the module</b><br/>context: includes / excludes<br/>links, never copies"}}
    SUB{{"<b>sub-ARC</b><br/>same structure,<br/>finer scope"}}

    CMP["<b>CMP</b><br/>leaf part<br/><i>no sub-parts of its own</i>"]
    IFC["<b>IFC</b><br/>contract<br/><i>endpoint A ↔ endpoint B</i>"]

    IMP["<b>IMP</b><br/>how + where<br/><i>points at the artifact</i>"]
    OAU["<b>OAU</b><br/>runbook<br/><i>operate · recover</i>"]
    TAE["<b>TAE</b><br/>evidence<br/><i>command + real output</i>"]

    ALLOC[["<b>Allocation &amp; Verification</b><br/>one row: REQ-IDs · owner · TAE · status<br/><i>this table is where the loop closes</i>"]]

    SYS --> ARC
    REF -->|"grounds"| REQ
    REF -->|"grounds"| CMP
    REQ -->|"one sentence:<br/>why relevant here"| ARC
    DEC -->|"one sentence:<br/>what it shapes"| ARC
    ARC -->|"delegates to"| SUB
    ARC -->|"owns"| CMP
    ARC -->|"owns"| IFC
    CMP --> IMP
    IFC --> IMP
    IMP --> OAU
    IMP --> TAE

    ARC ==> ALLOC
    REQ -.->|"REQ-IDs, not text"| ALLOC
    CMP -.->|"the owner"| ALLOC
    IFC -.->|"the owner"| ALLOC
    TAE -.->|"the proof"| ALLOC

    classDef goal fill:#1e3a8a,stroke:#3b82f6,color:#fff
    classDef hub fill:#5b21b6,stroke:#a78bfa,color:#fff
    classDef build fill:#134e4a,stroke:#14b8a6,color:#fff
    classDef proof fill:#78350f,stroke:#f59e0b,color:#fff
    classDef entry fill:#334155,stroke:#94a3b8,color:#fff
    class REF,REQ,DEC goal
    class ARC,SUB hub
    class CMP,IFC,IMP build
    class TAE,OAU,ALLOC proof
    class SYS entry
```

Four things in that picture do the real work:

**ARC references, it never absorbs.** A requirement gets one sentence in an ARC
note saying why it matters here — never its text. A decision gets one sentence
saying what it shapes — never its justification. This is what keeps a fact in
exactly one place while still making the module readable end to end.

**ARC nests, the other domains do not.** A module that mostly contains other
modules uses the main-module template: context plus a table of sub-modules,
nothing else. A module that directly owns parts uses the full template. That
single choice is what stops the architecture layer from flattening into a list.

**The CMP/ARC line is a decision rule, not a feeling.** If a thing has
sub-parts that interact, requirements allocated to it, and internal interfaces,
it is a module and gets an ARC note. Otherwise it is a leaf and gets a CMP note.

**The allocation table is the load-bearing structure.** Each row names the
requirement IDs, the component or interface that owns them, the evidence note,
and a status. A row only reaches `Verified` when a TAE link actually exists —
`Draft → Approved → Verified`, per allocation, not per file. That is what turns
"we tested it" into "these three requirements are still unproven", and it is
the one rule a tool can check for you: the exporter reads the allocation table
and names every requirement whose allocation claims more than its evidence
carries, and the validator reads the same two relations to decide whether a
requirement is covered at all.

| Domain | Question it answers | Change rate |
| ------ | ------------------- | ----------- |
| `01_requirements_(REQ)` | What should be achieved? | Stable |
| `02_decisions_(DEC)` | Why was something chosen? | Slow |
| `03_architecture_(ARC)` | How does everything connect? | Medium |
| `04_components_(CMP)` | What do references say about a component? | Stable |
| `05_interfaces_(IFC)` | How do two modules communicate? | Slow |
| `06_implementation_(IMP)` | How is it implemented? | Fast |
| `07_testing_and_evidence_(TAE)` | Did it work? | Slow |
| `08_operation_and_usage_(OAU)` | How is it operated and maintained? | Medium |
| `09_references_(REF)` | What does the external source say? | Stable |

Two more folders catch what does not fit: `98_administration_(ADM)` for project
logistics and `99_inbox_(INB)` for unclassified raw material.

---

## What you get

- **A complete vault skeleton** — every domain with a README explaining what
  belongs there and a file template to copy.
- **A four-question gate** before any file is created: does this information
  deserve to exist, what single question does it answer, which role does it
  play, at what change rate. If a question cannot be answered cleanly, the file
  gets split instead of written.
- **Machine-readable frontmatter** on every domain note — `domain`, `status`,
  `created`, `last-verified`; DEC files keep their Status line in the body
  instead — so freshness is a queryable property, not a guess.
- **A validator** that checks naming, required sections, frontmatter,
  wikilink and artifact-path integrity, requirement-table format, REQ↔TAE
  coverage — decided on the allocation row and the `verifies:` field, never
  on a mention in prose — and implementation details leaking into
  architecture files.
- **A traceability exporter** that reads the vault into a graph and writes it
  out as a report, two CSV views, a JSON graph and a compact Markdown index —
  both directions of the requirement-to-evidence matrix, with what is unproven
  stated rather than left as an empty cell.
- **A Claude Code skill** that writes into the vault under those rules, gated
  by hooks that run the validator after every write.
- **The surrounding project structure** — hardware, software, test data,
  procurement, sources, releases — so documentation is not an island.

---

## The worked example

The vault ships with one complete thread, so the method can be judged in a few
minutes instead of taken on trust. It starts at
`01_projectvault/system_overview.md` and runs through `ARC_Battery_Monitoring`:
three requirements with acceptance criteria, the decision behind them, the
component and the interface contract the module owns, an implementation note
pointing at two real scripts, and a verification note whose evidence is the
verbatim output of a command you can re-run:

```bash
python3 20_software/data_analysis/eval_battery_log.py \
        30_testdata/31_testdata_raw/2026-07-28_battery_monitoring/battery_log.csv
```

It prints one verdict line per requirement ID. The same note also records the
same evaluator failing against a deliberately altered log — a check that cannot
fail proves nothing, so the example shows that this one can.

Every object in the thread carries an `id` in its frontmatter, and every
cross-domain link between them is annotated with the target's identifier. The
annotation is not decoration: it is what turns a link into a relation the
export reads, and a link that could be one and is not annotated is reported.
What those identifiers and relations mean is declared in
`.claude/skills/mechatronics-docs/vault_schema.json`.

**Deleting it.** The example is illustration, not infrastructure. Remove the
seven notes named `*_Battery_*` under `01_projectvault`, the
`2026-07-28_battery_monitoring` folders under `30_testdata`,
`20_software/data_analysis/`, and the `ARC_Battery_Monitoring` row in
`system_overview.md`. Drop the evaluator step from
`.github/workflows/validate-vault.yml` as well. The validator returns to zero
errors with all of it gone.

---

## Quick start

```bash
# 1. Create your repo from this template (or clone it)
git clone https://github.com/jrmmhm/obsidian-engineering-vault.git my-project
cd my-project

# 2. Check the vault is intact — expect 0 errors
python3 .claude/skills/mechatronics-docs/validate_vault.py \
        00_documentation/01_projectvault
```

Then open the vault:

1. Open Obsidian → **Open folder as vault**
2. Select `00_documentation`
3. Read `01_projectvault/README.md` — it lays out the reading order

Finally, make it yours: update `LICENSE`, fill in
`01_projectvault/00_project_summary.md`, and add your first module to
`01_projectvault/system_overview.md`.

> **New to the method?** Read
> `01_projectvault/00_documentation_file_creation_and_conventions.md` before
> writing anything. It is short, and it is the part that makes the rest work.

---

## The AI layer

This vault is written for two audiences at once. The conventions that make it
searchable for a human in Obsidian — exact filenames, self-contained context
sections, one question per file — are the same ones that make it retrievable
for an agent.

**With Claude Code.** In a project made from this template there is nothing to
install. The skill sits in the project's own `.claude/skills/`, Claude Code
reads it from there, and its hooks look there first.

The global entry is for the other case — using the skill in projects that do
not carry it:

```bash
ln -sfn "$PWD/.claude/skills/mechatronics-docs" ~/.claude/skills/mechatronics-docs
```

That link stores a path, not an identity. Where `~/.claude/` is shared or
replicated between machines, the same path travels to hosts on which it does
not exist, and the failure is silent: the skill keeps appearing in the listing
and only the invocation fails. Keep the entry out of the replication and
create it once per machine. With Syncthing that is one line in the `.stignore`
of whichever folder root covers it, anchored to that root — `/mechatronics-docs`
when the root is `~/.claude/skills`, `/skills/mechatronics-docs` when it is
`~/.claude`. `.stignore` is per device and is never synchronised, so the line
is written on each machine. A Claude Code update can remove a symlinked entry
as well, which is the second reason the command above is worth re-running
rather than remembering.

One command says which copy a machine actually reaches:

```bash
python3 .claude/skills/mechatronics-docs/validate_vault.py --check-install
# -> reaches this copy / dangling / reaches a different copy / no entry at all
```

Call it through the repository path, as written. On a host where the entry is
broken, the path through the entry is the one thing that cannot work.

Which of the two spellings of that path is right follows from who types it.
The skill's own text writes `${CLAUDE_SKILL_DIR}/validate_vault.py`, and
Claude Code substitutes that placeholder in the skill's Markdown before a
session reads it, so the call reaches the copy that is actually running — and
a broken entry is never that copy, which is why the check above is typed by
hand with a real path instead. Nothing outside a session expands the
placeholder. Wherever a person or a script types the command — this README,
`CLAUDE.md`, the CI workflow, a project derived from this template — what
works is the path to a copy on disk: the repository path where the project
carries the skill, `~/.claude/skills/mechatronics-docs/` where it does not.

It ships with two Claude Code hooks, and a third that needs no Claude Code at
all (below). After every write into the vault, the validator checks
the file and feeds findings straight back into the session. At turn end, a stop
gate blocks completion on errors introduced during that session — ratcheted
against git `HEAD`, so pre-existing issues in legacy files never hold you
hostage.

**Without Claude Code.** The validator is a dependency-free Python script. Run
it manually or in CI:

```bash
python3 .claude/skills/mechatronics-docs/validate_vault.py path/to/01_projectvault
# -> ERRORs block, WARNs advise, exit code reflects the worst finding
```

That third hook covers what the editor gates never see — an Obsidian edit, a
hand edit, a subagent write. It validates the staged files at commit time and
reports without blocking:

```bash
ln -sf ../../.claude/skills/mechatronics-docs/hooks/pre_commit_vault.sh \
       .git/hooks/pre-commit
```

Set `MECHDOCS_PRECOMMIT_BLOCK=1` to make it refuse a commit whose staged files
carry ERRORs.

Its own test suite lives next to it:

```bash
bash .claude/skills/mechatronics-docs/tests/run.sh
```

---

## Handing it to someone else

The vault is readable in Obsidian or as raw Markdown, which is no help to a
reviewer, an examiner or an auditor who has not been taught the method. One
command turns it into something that is:

```bash
python3 .claude/skills/mechatronics-docs/export_traceability.py \
        00_documentation/01_projectvault --output-dir ../traceability
```

It writes five files: a self-contained `traceability.html` report, a
requirement-centric `traceability_requirements.csv`, an edge-list
`traceability_edges.csv` that pivots into either direction, `traceability.json`
carrying the whole graph, and `traceability_index.md` — one line per object and
per requirement, written for the agent or the newcomer who wants to know what
the vault contains before opening anything. Standard library only, like the
validator.

Three things make it worth reading rather than filing.

**Both directions, and only one of them is written down.** Requirement to
evidence comes from the allocation table; evidence to requirement is computed
from the same edges in one pass. No note in the vault stores a back-link, so
nothing can drift, and the JSON marks which fields were authored and which
were derived.

**What is unproven is stated, not left as an empty cell.** A requirement that
nothing allocates, an allocation that never reached `Verified`, a status
carrying a qualifier, an evidence note that does not name the requirement it
is linked from — each is a row with a reason, in its own section at the top of
the report. ISO 26262-8 asks for the reasons of verification steps not
executed, and ECSS-E-ST-10-02C for a close-out status with its justification;
an empty cell answers neither.

**It does not quietly understand less than it claims.** A table in a section no
template declares, an identifier that exists nowhere, a domain folder the alias
map does not know: all reported. A range like `REQ-BAT-001 bis REQ-BAT-009` is
expanded only when every identifier it yields actually exists.

The export is not Markdown, so it does not belong in the vault — the exporter
refuses to write there. `00_documentation/02_documents/` is its home when you
want to keep a dated revision; anywhere outside the project works for a
throwaway one.

**Against a safety standard.**
[IEC_61508_MAPPING.md](IEC_61508_MAPPING.md) places the nine domains and the
eight typed relations against the clause structure of IEC 61508, and states
what the standard has titles for that this vault has no home for. It is a
structural correspondence and explicitly **not** a claim of conformance; the
file says that first, and says exactly how far the reading behind it went —
clause numbers and published titles, from previews, with the standard itself
paywalled.

> **A note on the CSV.** Values are written exactly as the vault spells them,
> including a cell that begins with `=`. OWASP records that the usual
> formula-injection prefixes may not survive a spreadsheet round-trip, so a
> prefix would corrupt the record without closing the hole. Open the CSV
> through your spreadsheet's text-import path rather than by double-clicking
> it.

---

## Repository layout

```
├── 00_documentation/
│   ├── 01_projectvault/    Obsidian vault — Markdown only, the SSOT
│   └── 02_documents/       internal PDFs and exports, mirrors the vault domains
├── 10_hardware/            CAD sources, exports, PCB, electronics
├── 20_software/            code, one folder per repo-worthy responsibility
├── 30_testdata/            raw and processed measurement data
├── 40_procurement/         BOM, quotes, orders, invoices, payments
├── 50_sources/             external truth — datasheets, standards, papers
├── 60_releases/            baseline snapshots
├── 90_administration/      non-engineering project material
├── 99_archive/             superseded content, kept not deleted
├── .claude/skills/mechatronics-docs/
│                           the documentation skill, validator, exporter and tests
├── .github/                CI workflow, issue forms, pull request template
└── AGENTS.md, CLAUDE.md    agent instructions — AGENTS.md forwards to CLAUDE.md
```

Full rules for what belongs where — including the two distinctions that trip
people up most — are in **[STRUCTURE.md](STRUCTURE.md)**.

---

## Who this is for

Built for mechatronics work, where a single project spans mechanics, electronics,
firmware and host software, and where the documentation has to survive a
handover. It transfers cleanly to anything with the same shape: robotics,
lab instrumentation, embedded products, homelab infrastructure, research
hardware.

If your project is pure application software, the domain model will feel heavy —
`CMP` and `IFC` earn their keep once physical parts are involved.

The vault is language-agnostic. This template ships in English; the domain
abbreviations are just folder names, and translating them is a rename away.

---

## Contributing

Two kinds of change reach this repository. One fixes a tool — the validator
misreads a table, the exporter drops an edge. The other changes the method
itself: what a domain means, which sections a note must have, which rule becomes
an ERROR. Only the second costs anything to the projects already derived from
this template, because a repository made from a template shares no history with
it and cannot pull an update — it copies one in by hand.

So the two are proposed differently and versioned differently.
**[CONTRIBUTING.md](CONTRIBUTING.md)** says how, including what counts as a
breaking change for a derived project, and
**[CHANGELOG.md](CHANGELOG.md)** records what each release costs one.

---

## License

MIT — see [LICENSE](LICENSE).

Keep it if you are open-sourcing your project, or replace it with your own.
Either way, update the copyright line to your name.
