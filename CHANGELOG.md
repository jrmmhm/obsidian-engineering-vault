# Changelog

Everything notable that happens to this template is recorded here. The format
follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and the
version numbers follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
applied to the *method* rather than to a code API.
[CONTRIBUTING.md](CONTRIBUTING.md#versioning-what-a-breaking-change-means-here)
defines what a breaking change is for a project derived from this template, and
every entry below is classified by that table.

A repository created from a template starts with a single commit and shares no
history with the template it came from, so an update cannot be pulled — it is
copied in by hand. This file is what an existing project reads to decide whether
a version is worth copying, and what the copy will cost it.

The development so far: 126 commits since 2026-01-22, of which the recent
stretch arrived as 26 pull requests merged between 2026-07-28 and 2026-08-05.
What changed is recorded here; *why* it changed is in
[`DECISIONS.md`](.claude/skills/mechatronics-docs/DECISIONS.md), one amendment
per decision.

> **In a project made from this template**, this file describes the template and
> not your project. Replace it with your own or delete it — the same holds for
> [CONTRIBUTING.md](CONTRIBUTING.md) and the `.github/` directory.

## [Unreleased]

The first tagged release will be **0.1.0**, and what follows is its release
notes — drafted, not yet cut. [CONTRIBUTING.md](CONTRIBUTING.md#cutting-a-release)
describes how this heading becomes `## [0.1.0] - YYYY-MM-DD`.

Major version zero is the honest number. Semantic Versioning reserves it for
initial development, `vault_schema.json` declares `schema_version: 0.3`, and the
open roadmap issues that would redefine domains and relations are breaking
changes under this repository's own policy. A 1.0.0 today would be a 2.0.0 in
weeks, and the point of a version number is to be believed.

### Added

- **A nine-domain Obsidian vault skeleton** — `REQ`, `DEC`, `ARC`, `CMP`, `IFC`,
  `IMP`, `TAE`, `OAU` and `REF`, plus `98_administration_(ADM)` and
  `99_inbox_(INB)` for what does not fit. A README per domain explaining what
  belongs there, and a file template for each domain that has one.
- **Machine-readable YAML frontmatter** on the notes, so freshness is a
  queryable property rather than a guess.
- **`validate_vault.py`** — a dependency-free validator for naming, required
  sections, frontmatter, wikilink and artifact-path integrity,
  requirement-table format, identifier uniqueness, and implementation detail
  leaking into architecture notes. REQ↔TAE coverage is decided on the
  allocation row and the `verifies:` field — on the graph, never on a
  requirement ID appearing somewhere in prose. ERRORs block, WARNs advise, and
  the exit code reflects the worst finding.
- **`vault_schema.json`** at `schema_version` 0.3 — the declaration the
  validator reads instead of hard-coding its rules: the nine domains, the
  identifier scheme, the fields each domain carries, and eight typed relations.
- **`export_traceability.py`** — reads the vault into a graph and writes five
  artifacts: a self-contained HTML report, a requirement-centric CSV, an
  edge-list CSV, a JSON graph at `EXPORT_SCHEMA_VERSION` 1.1, and
  `traceability_index.md`, a compact index written for the agent or newcomer
  who wants to know what the vault holds before opening anything. Both
  directions of the requirement-to-evidence matrix, with what is unproven
  stated rather than left as an empty cell. Standard library only, like the
  validator.
- **The `mechatronics-docs` Claude Code skill** — instructions for writing into
  the vault under these rules, with hooks that run the validator after every
  write and a stop gate that blocks turn end on ERRORs introduced during the
  session, ratcheted against git `HEAD` so legacy files never hold anyone
  hostage. `CLAUDE.md` carries the rules; `AGENTS.md` forwards to it rather
  than restating them, so the two cannot drift apart.
- **`--check-install`** — says which copy of the skill a machine actually
  reaches, for the case where the personal skill entry is a symlink that
  travelled to a host on which its target does not exist.
- **A worked example traced from REQ to TAE** — three requirements with
  acceptance criteria, the decision behind them, the component and the interface
  contract the module owns, an implementation note pointing at two real scripts,
  and a verification note whose evidence is the verbatim output of a command
  anyone can re-run. The same note records the same evaluator failing against a
  deliberately altered log, because a check that cannot fail proves nothing.
- **The `vault` CI workflow** — the validator's own test suite, an audit of the
  template vault by name, a double export diffed against itself to prove the
  export is deterministic, and the worked example's evaluator run together with
  its negative control.
- **The surrounding project structure** — hardware, software, test data,
  procurement, sources, releases and archive, with [STRUCTURE.md](STRUCTURE.md)
  stating what belongs where and why the two easily-confused folders differ.
- **MIT license.**

[Unreleased]: https://github.com/jrmmhm/obsidian-engineering-vault/commits/main
