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
[![Validator](https://img.shields.io/badge/validator-47%20tests%20passing-success)](.claude/skills/mechatronics-docs/tests/run.sh)

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

Nine domains, each answering a different question, wired into a traceable chain
from goal to evidence:

```mermaid
flowchart LR
    REF["<b>REF</b><br/>What does the<br/>source say?"]
    REQ["<b>REQ</b><br/>What should be<br/>achieved?"]
    DEC["<b>DEC</b><br/>Why was it<br/>chosen?"]
    ARC["<b>ARC</b><br/>How does it<br/>connect?"]
    CMP["<b>CMP</b><br/>Which building<br/>blocks?"]
    IFC["<b>IFC</b><br/>Which contracts<br/>between parts?"]
    IMP["<b>IMP</b><br/>How is it<br/>implemented?"]
    TAE["<b>TAE</b><br/>Did it<br/>work?"]
    OAU["<b>OAU</b><br/>How is it<br/>operated?"]

    REF --> REQ
    REF --> CMP
    REQ --> ARC
    DEC --> ARC
    ARC --> CMP
    ARC --> IFC
    CMP --> IMP
    IFC --> IMP
    IMP --> TAE
    IMP --> OAU
    TAE -. "verifies" .-> REQ

    classDef goal fill:#1e3a8a,stroke:#3b82f6,color:#fff
    classDef build fill:#134e4a,stroke:#14b8a6,color:#fff
    classDef proof fill:#78350f,stroke:#f59e0b,color:#fff
    class REQ,DEC,REF goal
    class ARC,CMP,IFC,IMP build
    class TAE,OAU proof
```

The dotted line is the one that matters. `TAE` files declare which requirements
they verify, and the validator reports every requirement that nothing proves.

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
- **Machine-readable frontmatter** on every note — `domain`, `status`,
  `created`, `last-verified` — so freshness is a queryable property, not a
  guess.
- **A validator** that checks naming, required sections, frontmatter,
  wikilink and artifact-path integrity, requirement-table format, REQ↔TAE
  coverage, and implementation details leaking into architecture files.
- **A Claude Code skill** that writes into the vault under those rules, gated
  by hooks that run the validator after every write.
- **The surrounding project structure** — hardware, software, test data,
  procurement, sources, releases — so documentation is not an island.

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

**With Claude Code.** Symlink the bundled skill into your skills directory and
it activates automatically in any project with this layout:

```bash
ln -s "$PWD/.claude/skills/mechatronics-docs" ~/.claude/skills/mechatronics-docs
```

It ships with two hooks. After every write into the vault, the validator checks
the file and feeds findings straight back into the session. At turn end, a stop
gate blocks completion on errors introduced during that session — ratcheted
against git `HEAD`, so pre-existing issues in legacy files never hold you
hostage.

**Without Claude Code.** The validator is a dependency-free Python script. Run
it manually, in a pre-commit hook, or in CI:

```bash
python3 .claude/skills/mechatronics-docs/validate_vault.py path/to/01_projectvault
# -> ERRORs block, WARNs advise, exit code reflects the worst finding
```

Its own test suite lives next to it:

```bash
bash .claude/skills/mechatronics-docs/tests/run.sh
```

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
└── .claude/skills/mechatronics-docs/
                            the documentation skill, validator and tests
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

## License

MIT — see [LICENSE](LICENSE).

Keep it if you are open-sourcing your project, or replace it with your own.
Either way, update the copyright line to your name.
