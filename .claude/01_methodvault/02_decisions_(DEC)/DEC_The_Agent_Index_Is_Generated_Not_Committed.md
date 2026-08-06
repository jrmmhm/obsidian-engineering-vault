---
domain: DEC
id: DEC-MTH-027
created: 2026-08-05
last-verified: 2026-08-05
---
Date: 2026-08-05
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-05f — The index an agent reads is generated, not committed (Accepted)".

## Context

`traceability.json` already is a graph index of the vault, and by design it
is written outside the vault (`STRUCTURE.md`, section
`.claude/skills/mechatronics-docs`; `main` refuses any `--output-dir` that
`find_vault_root` resolves inside a vault). Nothing inside the vault and
nothing in `CLAUDE.md` names it, so a session working in the vault
re-derives the structure by search every time instead of reading it once.
The JSON is also not the artifact for that first read: it carries every
edge, every finding and every coverage record of the graph.

What is missing is the cheap read - one line per object, `identifier ·
domain · file · one sentence` - and something in the instructions that
says it exists.

## Options

- **A — A generated index beside the existing artifacts, plus a pointer
  from `CLAUDE.md` (chosen).** The index becomes a `--formats` output like
  the other four files and stays outside the vault; the visibility problem
  is solved where it is - in the instructions.
- **B — Commit the index inside the vault, guarded by a CI
  regenerate-and-diff step.** Rejected on three counts. It contradicts the
  rule this template teaches (`STRUCTURE.md`) and the refusal the exporter
  enforces in code and pins in `tests/run.sh`. Every file in the vault is
  measured by the validator: an index carries no domain prefix, no
  frontmatter and no template sections, so `filename-prefix` and
  `template-sections` would fire and the vault would need an exemption list
  that exists for one generated file. And a committed generate is the drift
  failure mode this repository exists to prevent: between two commits the
  file is wrong on disk, and an author editing a note without running the
  exporter gets a red pipeline for a file they never wrote.
- **C — Commit it under `00_documentation/02_documents/`.** Rejected.
  `STRUCTURE.md` describes that folder as documents *not* maintained as
  Markdown, with a dated revision naming schema; a continuously
  regenerated file does not fit it, and the drift between commits remains.
- **D — A symlink into the vault.** Rejected: a symlink is a file in the
  vault for every reader except the file system, and Obsidian and Windows
  each make a special case of it.

## Decision

**The index is a `--formats` output named `traceability_index.md`, written
to the same `--output-dir` as the other artifacts**, and `index` joins the
default format list so the CI determinism step - which calls the exporter
without `--formats` - covers it without an edit to the workflow.

**The one sentence per object comes from the section this project's own
REQ template declares**, which `discover_bindings` already resolves as
`bindings["req_table"]["section"]` and which `vault_schema.json` records as
the prose section (`## Context`, `## Kontext`) in every vault measured. No
second discovery rule, no new finding code, and no set iteration that could
make the bound title differ between two runs.

**The sentence itself is cut by a stated rule, never by judgement**: the
first prose paragraph of that section, whitespace collapsed, cut at the
first `.`, `!` or `?` that is followed by whitespace or the end of the text
and whose next non-space character is not a lowercase letter, then capped
at 240 characters on a word boundary. Free text is HTML-escaped, as it is
in the report, because Markdown carries raw HTML.

**The sentences are a derived field.** They live under a top-level
`summaries` key listed in `field_types.derived`, not on the authored
`nodes`, because a located, collapsed, cut and truncated sentence is worked
out and not written down.

**Visibility is prose, not a file**: one paragraph in `CLAUDE.md` and one
sentence in the vault README, both naming the command rather than a path to
trust - a copy on disk is only ever as fresh as its last run.

## Justification

### Rejected by review, before implementation

The plan first discovered the section itself, as the intersection of the
H2 titles of every domain template. An adversarial review of the plan
killed three parts of it against the source. The intersection hangs on a
single file - `00_CMP_file_template.md` carries no H2 at all and is only
excluded by `templates_for`'s empty-set rule - and `extract_h2` returns a
set, whose iteration order is randomised per process, so the display
spelling of a fold-collision (`Kontext` beside `kontext`) could differ
between two runs and fail the CI diff. The planned finding for a file
without a usable sentence broke an existing assertion measurably: the
shadowed requirements fixture, which `tests/run.sh` pins at zero
findings, has a context section holding nothing but tables, and a
prototype of the plan reported it. And the abbreviation rule refuted
itself - "a preceding word longer than two characters" cuts inside
`e.g.`, which was the rule's own counterexample, and cuts inside `bzw.`
and `usw.` in the German half of the corpus. The decision above carries
all three corrections: the REQ binding instead of a second discovery, a
counter in the index head instead of a finding, and a terminator that
ends a sentence only where the next word does not continue it in lower
case.

## Consequences

### Realization

- `export_traceability.py` - `summary_of` (the bound section, its first
  prose block, headings, tables, list items, quotes and fenced blocks
  stepped over), `cut_sentence`, `cap_sentence`, `index_text`,
  `write_index`, `Graph.summaries`, the `summaries` key and its
  `field_types.derived` entry in `write_json`, `index` in the
  `--formats` default, `EXPORT_SCHEMA_VERSION` 1.0 -> 1.1
- `vault_schema.json` - the `index` entry: the artifact, why the REQ
  binding rather than a discovery of its own, the sentence rule verbatim,
  and why a missing sentence is a count and not a finding
- `CLAUDE.md` - rule 15; `00_documentation/01_projectvault/README.md`,
  `README.md`, `SKILL.md`, `STRUCTURE.md` - the same artifact from each
  file's own angle
- `tests/run.sh` - eleven assertions on the index and the rule behind it,
  plus two fixture context paragraphs that carry an abbreviation and a
  sentence that never terminates; 259 to 270 assertions

Observed at the real entry point, the template vault:

    objects: 7  relations: 20  findings: 0
    index: 7 object lines, 3 requirement lines, 0 objects without a sentence
    bound req_table -> '## Context'

    - `CMP-BAT-001` · CMP · `04_components_(CMP)/CMP_Battery_Pack.md` ·
      Rechargeable lithium-polymer battery pack of the host machine, and
      the supply endpoint of IFC_PWR_DC_LiPo_Pack (IFC-BAT-001) inside
      the module ARC_Battery_Monitoring (ARC-BAT-001).

Two runs into the same directory with `--no-timestamp` compare byte-equal
under `diff -r`, which is the property the CI step measures.
