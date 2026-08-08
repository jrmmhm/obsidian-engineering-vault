# Changelog

Everything notable that happens to this template is recorded here. The format
follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and the
version numbers follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
applied to the *method* rather than to a code API.
[CONTRIBUTING.md](CONTRIBUTING.md#versioning-what-a-breaking-change-means-here)
defines what a breaking change is for a project derived from this template. That
table governs every entry that moves the rule set: from here on, such an entry
names its tier. The entries of the first release mostly describe what the
template *is* rather than a change to something a project already adopted, so
only those that revise an earlier decision carry one.

A repository created from a template starts with a single commit and shares no
history with the template it came from, so an update cannot be pulled — it is
copied in by hand. This file is what an existing project reads to decide whether
a version is worth copying, and what the copy will cost it.

The development so far: a first commit in January 2026, a long quiet stretch,
and then the run of pull requests through late July and early August that turned
a folder convention into an enforced method. The counts are deliberately not
written down — `git log` holds them and holds them correctly, and a figure
copied into prose is wrong from the next merge onward.
What changed is recorded here; *why* it changed is in the method vault,
[`system_overview.md`](.claude/01_methodvault/system_overview.md), one note per
decision.

> **In a project made from this template**, this file describes the template and
> not your project. Replace it with your own or delete it — the same holds for
> [CONTRIBUTING.md](CONTRIBUTING.md) and the `.github/` directory.

## [Unreleased]

### Fixed

- **The worked example's deletion instructions now name the whole example** —
  the old paragraph said "the seven notes named `*_Battery_*`", a glob that
  matches six: the interface note `IFC_PWR_DC_LiPo_Pack.md` was never deleted,
  and following the instructions left `[[ARC_Battery_Monitoring]]` unresolved
  in the conventions file — a second warning the quick start does not predict.
  The paragraph now lists all seven notes by name, has the reader remove the
  conventions sentence that carried the last link, and says what the validator
  reports before and after the removal is committed. This is issue #70:
  documentation only, no rule moves and no vault gains a finding, so it is
  MINOR.

- **`export_traceability.py` — one reverse-key derivation for both readers of
  the graph** (issue #67). `assess()` read the coverage's evidence half through
  the literal `verifies_back` while `reverse_index()` derived the key from
  `relations.verifies.reverse_key`, so renaming that schema key silently
  emptied the evidence half of every requirement — a falsified coverage report
  at exit 0. One shared derivation now feeds both readers; absence at any
  level — the `relations` block, a kind's entry, the `reverse_key` field —
  still falls back to the `<kind>_back` convention. Two shapes are now refused
  loudly with exit 2 and the schema entry named, where they were previously
  guessed around or crashed bare: a `relations` block that no longer declares
  `verifies` (the relation the coverage report is defined on), and a
  `reverse_key` declared as anything but a non-empty string. A derived project
  that edited its `vault_schema.json` should read that refusal as the cost of
  this update. PATCH — no rule moved; the tool stopped being wrong about an
  input it already had an opinion on. Why:
  `DEC_One_Reverse_Key_Derivation_For_Both_Readers` in the method vault.

## [0.1.0] - 2026-08-06

The first tagged release, and the point from which the version number in this
file starts meaning something to a project that copied the template in.

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
  a run that reports warnings alone still exits 0. The enforced rule set,
  including the findings the prose sections of the conventions do not
  describe, is listed in that file's validator quick reference.
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
- **An IEC 61508 correspondence** — [IEC_61508_MAPPING.md](IEC_61508_MAPPING.md)
  places the nine domains and the eight typed relations against the clause
  structure of IEC 61508 and names the gaps, from hazard analysis and integrity
  levels through to who approved a note and with what independence. It is a
  structural correspondence and explicitly not a claim of conformance, cited by
  clause number and published title only, with a source key recording which
  document was read, how far and on which day. This is what issue #6 turned
  into: no domain, relation, field or rule moved, so it is MINOR — the
  expectation recorded in `DECISIONS.md` amendment 2026-08-05h, that #6 would
  be MAJOR because it would remap object and relation types, was not borne out.
- **The method's own decision record, as a vault** —
  [`.claude/01_methodvault/`](.claude/01_methodvault/system_overview.md). The 31
  records of the appended decision log were migrated verbatim into one DEC note
  each, held to the same frontmatter, template sections, line limits and link
  rules as any project vault and audited by name in CI and in the test suite.
  `.claude/skills/mechatronics-docs/DECISIONS.md` keeps no decision content and
  forwards, mapping every amendment date to its note, so every citation of an
  amendment by date in the tools stays true. A method change now earns a DEC
  note rather than an amendment; `CONTRIBUTING.md`, the pull request template
  and the issue forms say so. This is issue #53: no domain, relation, field,
  template section or rule moved and no vault that was clean becomes unclean, so
  it is MINOR. The audit found one real defect in the log on first contact — an
  unbackticked wikilink example that thirty amendments of review had not caught.
- **A contribution route that does not depend on asking** —
  [CONTRIBUTING.md](CONTRIBUTING.md) with the tool-versus-method split, the three
  local checks and their real output, the versioning table that defines a
  breaking change for a derived project, and the release procedure; a bug-report
  and a method-change issue form under `.github/ISSUE_TEMPLATE/`, the latter
  asking for the cost to a project that already adopted the current rule and for
  the expected tier; and a pull request template whose checklist is the set of
  gates a reviewer would otherwise have to re-derive.
- **MIT license.**

[Unreleased]: https://github.com/jrmmhm/obsidian-engineering-vault/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/jrmmhm/obsidian-engineering-vault/releases/tag/v0.1.0
