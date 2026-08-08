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

## The output, before the argument

This is the vault that ships with this template, read back out of itself. The
worked example is one module — battery monitoring — and the exporter walks it
into a graph:

```bash
python3 .claude/skills/mechatronics-docs/export_traceability.py \
        00_documentation/01_projectvault --output-dir ../traceability
```

Two lines of what it reports, then the index it writes:

<!-- traceability-excerpt:start -->
```text
requirements: 3  proven: 3  not proven: 0
objects: 7  relations: 20  findings: 0

## Objects (7)

- `ARC-BAT-001` · ARC · `03_architecture_(ARC)/ARC_Battery_Monitoring.md` · Battery monitoring module: it records telemetry from the host machine's battery pack into a log and decides whether that log meets its acceptance criteria.
- `CMP-BAT-001` · CMP · `04_components_(CMP)/CMP_Battery_Pack.md` · Rechargeable lithium-polymer battery pack of the host machine, and the supply endpoint of IFC_PWR_DC_LiPo_Pack (IFC-BAT-001) inside the module ARC_Battery_Monitoring (ARC-BAT-001).
- `DEC-BAT-001` · DEC · `02_decisions_(DEC)/DEC_Battery_Log_Acceptance_Check.md` · The module ARC_Battery_Monitoring (ARC-BAT-001) produces telemetry logs whose acceptance criteria are stated in REQ_Battery_Monitoring (BAT) (REQ-BAT-000).
- `IFC-BAT-001` · IFC · `05_interfaces_(IFC)/IFC_PWR_DC_LiPo_Pack.md` · DC power contract of a four-cell lithium-polymer pack: the voltage range a consumer of this contract must tolerate, and the range within which a recorded pack voltage is considered valid.
- `IMP-BAT-001` · IMP · `06_implementation_(IMP)/IMP_Battery_Log_Evaluation.md` · Concrete realization of the battery telemetry chain of ARC_Battery_Monitoring (ARC-BAT-001): one script that records a log from the pack and one that decides the acceptance criteria of REQ_Battery_Monitoring (BAT) (REQ-BAT-000) against…
- `REQ-BAT-000` · REQ · `01_requirements_(REQ)/REQ_Battery_Monitoring (BAT).md` · Requirements on the battery monitoring chain of the module ARC_Battery_Monitoring (ARC-BAT-001): recording pack telemetry into a log and making that log evaluable.
- `TAE-BAT-001` · TAE · `07_testing_and_evidence_(TAE)/TAE_Battery_Log_Acceptance.md` · Acceptance check of a recorded battery telemetry log of the module ARC_Battery_Monitoring (ARC-BAT-001) against all three requirements of REQ_Battery_Monitoring (BAT) (REQ-BAT-000).

## Requirements (3)

- `REQ-BAT-001` · REQ · `01_requirements_(REQ)/REQ_Battery_Monitoring (BAT).md:25` · While logging is active, the battery monitor shall record consecutive samples without a gap larger than twice the nominal sample interval.
- `REQ-BAT-002` · REQ · `01_requirements_(REQ)/REQ_Battery_Monitoring (BAT).md:26` · The battery monitor shall record every pack voltage sample within the operating range of the DC power contract.
- `REQ-BAT-003` · REQ · `01_requirements_(REQ)/REQ_Battery_Monitoring (BAT).md:27` · The battery monitor shall record the manufacturer and the model designation of the sampled pack in the log header.
```
<!-- traceability-excerpt:end -->

Seven objects, one per domain, each carrying its own identifier and the first
sentence of its own context — and three requirements, each at the file and line
it is written on. Nothing there was typed by hand. The first two lines are the
exporter's own summary, the rest is the tail of the `traceability_index.md` the
command above writes.

`proven: 3` is the part worth pausing on. It is not a claim in prose: it counts
the requirements whose allocation row reached `Verified` **and** whose evidence
note names them back, computed from the vault rather than remembered. The same
run writes `traceability.html`, the report you would hand to a reviewer, and
`0 not proven` is the sentence that report exists to be able to stop saying.

A stored copy of generated output is only as current as its last run, which is
why this repository does not keep one — except here, where CI regenerates the
export on every push and fails if these lines have drifted from the vault.

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

**Deleting it.** The example is illustration, not infrastructure, and removing
it is part of deriving a project — which is one command, run from a clone:

```bash
python3 tools/new_project.py ../my-project
```

The script copies the template into a fresh directory, removes the example
together with everything only this template repository needs — including its
own `tools/` folder — and finishes by running the derived vault's validator,
so the result is checked rather than assumed. The known duplicate-basename
warning below stays by default and is explained in the generated README;
`--rename-docs-readme` resolves it instead.

Deriving by hand still works. Remove the seven notes of the example under
`01_projectvault` — `REQ_Battery_Monitoring (BAT)`,
`DEC_Battery_Log_Acceptance_Check`, `ARC_Battery_Monitoring`,
`CMP_Battery_Pack`, `IFC_PWR_DC_LiPo_Pack`, `IMP_Battery_Log_Evaluation` and
`TAE_Battery_Log_Acceptance` — the `2026-07-28_battery_monitoring` folders
under `30_testdata`, `20_software/data_analysis/`, the `ARC_Battery_Monitoring`
row in `system_overview.md`, and the sentence "The worked example under
[[ARC_Battery_Monitoring]] shows all of this in one thread." in
`00_documentation_file_creation_and_conventions.md`, which would otherwise be
the one wikilink left pointing at the example. If you keep `.github/`, replace
`workflows/validate-vault.yml` with the two-step version the script writes —
project vault audit and export determinism — or drop its three template-only
steps: the validator self-test, the method vault audit and the worked example
evidence. The self-test suite in `.claude/skills/mechatronics-docs/tests/`
asserts this template's own vaults and stays red in a derived project, so
remove that directory with the rest. Commit the removal, and the
validator returns to zero errors with all of it gone — and to the single
warning the quick start below explains. Until the commit it also reports each
of the example's identifiers as `id-vanished`, exactly as the conventions file
says it does for an identifier that was present at git HEAD.

---

## Quick start

```bash
# 1. Create your repo from this template (or clone it)
git clone https://github.com/jrmmhm/obsidian-engineering-vault.git my-project
cd my-project
# Starting a real project instead of exploring? Derive one in one command:
#   python3 tools/new_project.py ../my-real-project
# (see "The worked example" above for what it removes)
# Add --minimal to start with three domains instead of nine — REQ, ARC and
# TAE carry the loop; the other six wait beside the vault until they are due
# (the vault README's "Start With Three, Grow Into Nine" says when).

# 2. Check the vault is intact
python3 .claude/skills/mechatronics-docs/validate_vault.py \
        00_documentation/01_projectvault
# -> 0 error(s), 1 warning(s)
```

Zero ERRORs is the gate, and that one warning is the known state of the shipped
vault rather than something you broke. `01_projectvault/README.md` and
`02_documents/README.md` both ship under `00_documentation`, and this vault
resolves a wikilink by its basename alone — Obsidian would tell the two apart by
their path, this validator does not, so `[[README]]` is ambiguous and
`[[01_projectvault/README]]` is reported as `link-unresolved` instead. Renaming
one of them is the only remedy. Keeping both names is a fair choice, and while
you do, no wikilink may address either file by that name.

That generalises: a WARN advises, it does not fail. A run that reports warnings
and no ERROR exits 0, so no gate here blocks on one — not CI, not the pre-commit
hook, not the hooks around a Claude Code session. Each warning is still a
decision you make once, because the warning nobody triages is the one everybody
learns to scroll past. If your run shows an ERROR, or a second warning you did
not expect, that one is yours.

That was a check, though, not a result. **[Your first closed loop](TUTORIAL.md)**
is the same method at working size, in roughly ten minutes: you derive a project
of your own, write one requirement, one evidence note and one allocation row,
and the exporter reads them back as `proven: 1  not proven: 0` — your loop, out
of your own three files. First the aha, then the theory.

CI adds exactly one check that is stricter than a session, and it is not this
one. The traceability export names, per requirement, what is unproven; the
workflow runs it with `--fail-on not-allocated,no-evidence-note` and fails when
a requirement of this repository's own vault is allocated by no row or named by
no evidence note. The validator's `req-uncovered` stays a WARN either way,
because it cannot tell an evidence chain that is still open from a vault that
never adopted the convention — and a session must not stop over that. A run
green locally and red in CI is that one step, and the export it writes says
which requirement. Your own project inherits the option unarmed; turn it on
once your loop closes.

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
# -> ERRORs block, WARNs advise, warnings alone still exit 0
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
├── .claude/01_methodvault/ the method's own decision record — a second vault,
│                           audited by the same validator
├── .github/                CI workflow, issue forms, pull request template
├── tools/                  new_project.py — derives a clean project, strips itself
├── TUTORIAL.md             ten minutes to your own first closed REQ→TAE loop
├── IEC_61508_MAPPING.md    IEC 61508 correspondence — not a conformance claim
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
