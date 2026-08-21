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

### Added

- **The system overview declares itself, and two new WARNs say when the ARC
  reachability check did not run** — `arc-not-in-overview` resolved
  `system_overview.md` as a literal path and returned without a word when
  that file did not exist, and the hub link budget went to the same name.
  Both were dark in every vault that renamed the file:
  measured on a derived German vault whose overview is `Systemuebersicht.md`,
  16 ARC modules and 0 findings. The overview is now the file in the vault
  root whose frontmatter carries `vault-role: system-overview`.
  **What an existing project has to do: put a frontmatter block carrying
  `vault-role: system-overview` at the top of its overview file** — until it
  does, every run reports `overview-unidentified`, the island check does not
  run, and that file loses the hub link budget. `vault-role` and not `role`,
  because `role` already names the canonical domain token in these tools.
  The second new code, `arc-containment-unreadable`, is the same principle
  one layer in: where the containment source cannot be read at all — no
  exporter beside the validator, or a schema the validator could not parse —
  the check says so instead of reporting every submodule as unreachable.
  **MAJOR** by the table in
  [CONTRIBUTING.md](CONTRIBUTING.md#versioning-what-a-breaking-change-means-here)
  — a rule is newly introduced and a frontmatter field starts deciding
  behaviour — recorded as MINOR while the repository is at 0.x. `schema_version`
  moves to `0.5`. The reasoning, with the four rejected alternatives and what
  each was measured against, is
  [`DEC_Reachability_Is_Decided_From_A_Self_Declared_Overview`](.claude/01_methodvault/02_decisions_(DEC)/DEC_Reachability_Is_Decided_From_A_Self_Declared_Overview.md).

- **`corrected-by` is a declared typed relation** — the `Corrected by:
  [[DEC_...]]` line has been authored in decision records since the
  decision-log migration without being declared anywhere: not a relation, not
  in a template, known to no check. It is now the ninth typed relation in
  `vault_schema.json`, subject-first like the other eight, with `corrects` as
  the computed reverse, and both DEC templates declare the line — the method
  vault's own and the one every derived project inherits. It is not
  `superseded-by` under another name: a corrected record keeps its Status,
  because a later decision overturned a *statement* it makes rather than
  replacing the decision. **MAJOR** by the table in
  [CONTRIBUTING.md](CONTRIBUTING.md#versioning-what-a-breaking-change-means-here)
  — a typed relation was added — recorded as MINOR while the repository is at
  0.x. **Nothing in an existing vault turns red**: the relation is
  `declared-only`, no new finding code exists, and a dead pointer was already
  a blocking `link-unresolved` ERROR before this change. `schema_version` moves
  to `0.4`, because the data model is what that number tracks and
  `traceability.json` publishes it — without the bump a consumer cannot tell
  the eight-relation model from the nine-relation one. What stays unchecked
  is named in the schema's own `enforced_detail` rather than left to be
  discovered — a line with no link, a line below the first heading, and the
  spelling variants. The reasoning, including the rule that was designed for
  those cases and rejected on measurement, is
  [`DEC_A_Declared_Relation_Without_A_Check_Of_Its_Own`](.claude/01_methodvault/02_decisions_(DEC)/DEC_A_Declared_Relation_Without_A_Check_Of_Its_Own.md).

### Changed

- **A module its parent contains is no longer a documentation island** —
  `arc-not-in-overview` demanded that every ARC file appear in the overview,
  while `vault_schema.json` declares that ARC-to-ARC containment is authored
  in the submodule table of the main-module template and nowhere else. A
  vault that uses that table correctly got one island finding per submodule:
  measured on a derived vault that adopted it, 12 containment edges from one
  main module and 11 findings that would have been wrong. Reachability is now
  transitive from the overview over those edges. **Grep your vault for
  `arc-not-in-overview` after updating:** in a nested vault the count falls,
  and in a flat one nothing changes — a vault whose templates declare no
  submodule table cannot author containment, so every ARC module must still
  be named in the overview. Transitive and not one hop, because a module
  listing itself in its own submodule table, and two modules listing each
  other, would otherwise delete their own findings. A rule redefined:
  **MAJOR** by the table, recorded as MINOR while the repository is at 0.x.

- **The requirement-row checks follow the requirements role** —
  `check_req_table` and `check_req_table_silence` compared the folder
  abbreviation to the literal `REQ`, so a vault spelling its requirements
  folder `01_Anforderungen_(ANF)` had its rows read by the index and by no
  row check. **Grep your vault for `req-class`, `req-nnn`, `req-duplicate`,
  `req-criterion` and `req-table-unrecognized` before updating:** in a
  translated vault every requirement row is now held to the row grammar for
  the first time, four of those five codes are ERRORs, and a table the index
  reads while no row check can is the fifth as a WARN. Measured across three
  derived German vaults — 289 requirement rows — the finding sets are
  identical before and after, so the rows those projects wrote already
  conform; that is a measurement, not a promise about yours. Pre-existing
  findings stay non-blocking at the stop gate through the per-file HEAD
  baseline. `DEC_Requirement_Index_Follows_The_Role_Map` called this
  extension a convention rollout and refused it; that refusal is overturned
  here, and the entry under *Fixed* below explains why the cost it priced
  belonged to a different check. A blocking check reaching files it never
  reached is a rule change by the table: MAJOR — recorded as MINOR while the
  repository is at 0.x. The reasoning is
  [`DEC_Per_File_Checks_Follow_The_Role_Map`](.claude/01_methodvault/02_decisions_(DEC)/DEC_Per_File_Checks_Follow_The_Role_Map.md)
  (issue #115).

- **The strict pointer zone opens in every template language** —
  `check_paths` promoted a dead artifact path to ERROR only under an H2
  containing `reference` or `source`, and `check_leaks` exempted the same
  headings; the German template sections (`Referenzen`, `Verweise`,
  `Quelle(n)`, `Kanonische Quelle`) never matched. One predicate
  (`REF_SECTION_TOKENS`, `is_ref_section()`) now carries the English and
  the German spellings for both zones. **Grep your vault for
  `path-missing` before updating:** in a German vault every dead path in a
  reference/source section moves WARN→ERROR, fenced and backticked
  pointers there are scanned for the first time, the pending/planned/TBD
  escape no longer applies there, and the stop gate's blocking set grows
  (pre-existing findings stay non-blocking through the per-file HEAD
  baseline). German ARC/DEC files lose `impl-leak` findings inside those
  sections — the exemption English sections always had. The reasoning is
  [`DEC_The_Strict_Zone_Opens_In_Every_Template_Language`](.claude/01_methodvault/02_decisions_(DEC)/DEC_The_Strict_Zone_Opens_In_Every_Template_Language.md),
  closing the decided English-only residual of
  [`DEC_One_Project_Path_Definition_In_Both_Zones`](.claude/01_methodvault/02_decisions_(DEC)/DEC_One_Project_Path_Definition_In_Both_Zones.md).
  An existing WARN is raised to ERROR, so by the table this is MAJOR —
  recorded as MINOR while the repository is at 0.x.

### Fixed

- **A file carrying two template contracts is held to both** —
  `check_sections` scored a file against every template of its domain and
  kept the best, so an ARC file carrying the main-module template's two
  sections stopped being measured against the seven-section one and could
  lose any of the other five in silence. Where the best-matching template
  scores a perfect match, the file is now also held to any other template of
  the domain whose *exclusive* section it carries — a section exactly one
  template requires is what says which template a file was written from.
  **Grep your vault for `template-sections`, `section-mismatch` and
  `section-near-miss` before updating.** Measured across four vaults and 455
  domain files: no file changes its findings, and the one deliberately broken
  probe — a main module with an allocation table minus its `Interfaces`
  section — goes from silent to one ERROR. A domain whose templates require
  identical or nested section sets is unaffected by construction. PATCH: the
  rule did not move, the tool stopped guessing which template a file came
  from. It narrows a sentence of
  [`DEC_One_Abbreviation_One_Folder_By_Rule`](.claude/01_methodvault/02_decisions_(DEC)/DEC_One_Abbreviation_One_Folder_By_Rule.md),
  which now carries a `Corrected by:` line saying so.

- **`SKILL.md` states the enforcement tiers a derived project actually
  has** — the skill travels verbatim into every derived project, so its
  sentences are read in two repositories at once, and two of them were
  false in one. The tier paragraph promised "a GitHub Actions workflow
  that runs the test suite and the full vault audit on every push and
  pull request"; the suite was removed from a derived project together
  with `.claude/skills/mechatronics-docs/tests` and the derived workflow
  rewritten to a vault audit and an export-determinism diff, so the first
  half has been false in every project derived since. The same paragraph
  said both tiers "run" and that a hand or Obsidian edit "is covered"
  while naming the pre-commit hook's install step in its own parenthesis:
  `.git/hooks/` travels with no clone and no pull, so the hook ships
  uninstalled and covers nothing until it is symlinked, and the
  derivation leaves no repository behind at all. That paragraph is what
  argues the editor hooks may miss Obsidian edits, `sed -i` and subagent
  writes, so overstating it overstates the design. It now states
  conditions instead of states — a state claim is false in at least one
  of the environments the file is read in — and leaves the install
  command with the hook's own header and the step list with the workflow
  file. Second clause: "This repository's own workflow arms
  `not-allocated` and `no-evidence-note`" is deictic in a file read in
  two repositories, and only the template's workflow arms them; it now
  names the template. `METHOD.md`, the other file that travels verbatim,
  carried the same present-tense claim about the pre-commit hook above
  the install command it prints, and is corrected the same way. The
  derivation block of `tests/run.sh` gains four assertions, structural
  where a claim names a path or a file in this repository and a denylist
  where it names neither. Nothing in a vault changes and no rule moves;
  corrected documentation: MINOR.
- **The decision checks and the requirement-row identifier follow the role
  map** (PATCH; the codes are named below) — `check_dec_status` compared the
  folder abbreviation to the literal `DEC`, so a vault spelling its decisions
  folder `02_Entscheidungen_(ENT)` had no Status line checked at all: not its
  presence, not its value against the schema's list, not the successor link a
  `Superseded` state requires. **Grep your vault for `dec-status` and
  `dec-superseded`.** No decision ever covered this — it was residual 1 of
  `DEC_Language_Independent_Recognition_And_VCS_Tier` and nothing closed it —
  and across three derived German vaults (141 decision files) the finding sets
  are identical before and after.

  In the same pass, `check_field_value` and `check_tae_verifies` stopped
  disagreeing about what a requirement-row identifier looks like. The format
  check used a constant English prefix while the reference check used the
  vault's own, so a vault carrying an English `07_testing_and_evidence_(TAE)`
  folder beside a translated requirements folder reported every correctly
  written `ANF-BAK-001` as `verifies-format` at ERROR — and resolved the same
  id in the same run. **Grep for `verifies-format` and
  `verifies-unknown-req`,** because three consequences follow:

  - the false `verifies-format` on the vault's own spelling is gone;
  - where the format check runs at all, the canonical `REQ-` spelling is
    accepted only while a literal `REQ` folder still exists — that is the
    mid-translation state and its whole extent — so an English-spelled
    entry in a vault that has finished translating is now
    `verifies-format`. This reaches a vault whose *evidence* folder is
    still spelled `TAE`, and only that one: the field profile that turns
    the check on is looked up by folder abbreviation, so a vault spelling
    its evidence folder `TUE` has no `verifies` check of any kind and is
    unaffected. That lookup stays as it is, for the reason in the last
    paragraph;
  - in a vault carrying **both** evidence folders, `check_tae_verifies` now
    also reads the one that lost the role, so a dead requirement reference
    there is reported for the first time.

  One risk worth knowing before you update: a folder whose abbreviation the
  alias map translates but which does not hold that domain — an `(ENT)`
  folder that is not decisions — now receives one `dec-status` ERROR per
  file. The finding names the translation it applied, and the alias map is
  data: a project that means something else by that token removes the entry
  from its own `vault_schema.json`. The requiredness of `verifies` in a
  translated evidence domain stays unshipped; that is the 38-ERROR rollout
  refused since issue #66 and refused again here, and it is the cost the
  earlier record priced when it also refused the row checks. Reasoning:
  [`DEC_Per_File_Checks_Follow_The_Role_Map`](.claude/01_methodvault/02_decisions_(DEC)/DEC_Per_File_Checks_Follow_The_Role_Map.md)
  (issue #115).

- **The IMP README states the whole `host=` rule it teaches** — the
  "Artifacts on Other Machines" section explained the declaration but not
  its failure mode: a `host=` naming no machine is reported as an error
  (`fence-host`), which the validator has enforced since the rule landed
  and the README never said. The References rules now also carry the
  ownership qualifier the rule hinges on — "IMP refers to artifacts, it
  does not replace them" holds **for artifacts this project owns**, and a
  path on another machine names the machine — with a pointer to the
  section that governs the non-owned case. Corrected documentation, no
  rule moves and no vault gains a finding: MINOR.
- **A continuation number inherits from its nearest preceding identifier,
  never from a later one** — `expand_requirement_cell` resolved every
  continuation against the LAST full identifier of the whole cell, so a
  cell that changes scope, `ANF-BAK-001, -010, -011, ANF-PUB-011`, lost
  BAK-010/011's allocations silently and invented one for PUB-010, with
  no finding on either side. One positional scan now reads the cell in
  order; a number standing before the first full identifier is returned
  as an unresolved fragment instead of borrowing a scope from later in
  the cell. Grep your vault before updating: affected cells surface as
  `export-unresolved-requirement`, and requirements whose allocations
  were mis-resolved can newly gain or lose `req-uncovered` (validator)
  and `not-allocated` / `no-evidence-note` (the `--fail-on` classes) —
  those results were computed from wrong edges before. Single-scope
  cells, which the authoring convention produces, expand unchanged. The
  reasoning is
  [`DEC_A_Continuation_Inherits_From_Its_Nearest_Preceding_Identifier`](.claude/01_methodvault/02_decisions_(DEC)/DEC_A_Continuation_Inherits_From_Its_Nearest_Preceding_Identifier.md).
  The rules do not move, the tool stops misreading an input it already
  had an opinion on: PATCH.

### Added

- **The export draws the graph it reads, and the README opens with it** —
  the exporter has read the vault as a graph since its first version and
  has never drawn one: the HTML report is tables, the index is one line per
  object, and the REQ→TAE edge appeared in no output at all (issue #99). A
  fifth format, `mermaid`, writes `traceability_graph.mmd`: the coverage
  chain as a Mermaid node-link diagram GitHub renders natively. Drawn are
  the three relations coverage is decided on — `allocates`, `evidence`,
  `verifies` — and the diagram's own header says so and points at
  `traceability.json` and `traceability_edges.csv` for the other four. It
  is deterministic, stdlib-only and free of anything machine- or
  run-dependent, so it is byte-identical with and without `--no-timestamp`.
  `README.md` now opens on **what this is** in four plain sentences, then
  that diagram, then one requirement traced through it; the two count
  lines stay under the picture and the index tail moves into a `<details>`
  block under "The worked example". Three stored blocks, one marker pair
  each, all three regenerated and diffed by CI — which now also refuses a
  `traceability-*` marker pair it was not told to check, so a stored block
  cannot lose its gate quietly. `TUTORIAL.md` step 7 shows the reader their
  own three-node loop, replayed by the suite like the rest of that page.
  The reasoning, including why three relations and not eight, is
  [`DEC_The_Export_Draws_The_Graph_It_Reads`](.claude/01_methodvault/02_decisions_(DEC)/DEC_The_Export_Draws_The_Graph_It_Reads.md).
  A new exporter output and new documentation; no domain, template section,
  frontmatter field, identifier rule, typed relation or validator severity
  moves, and no existing vault gains a finding — a derived project sees one
  additional file in its export directory and nothing else: MINOR.

- **The entry comes first, the argument moves to [METHOD.md](METHOD.md)** —
  `README.md` argued the method over four screens before letting anyone in:
  the quick start stood at line 283 and the audience section at line 530 of
  567 (issue #80). It now answers, in order, what this is, the proof, how to
  start and who it is for — and who it is not for, which it never said. The
  four argument sections — "The problem this solves", "How the pieces
  connect" with the domain graph, "The AI layer" and "Handing it to someone
  else" — moved to `METHOD.md` **verbatim**; the only edited sentences are
  four seams a move makes false, and the diff shows relocation rather than
  rewriting. The stored traceability excerpt stays where it was, marker pair
  and CI diff untouched. `METHOD.md` ships into derived projects, which
  repairs a link that was dead in every one of them: `IEC_61508_MAPPING.md`
  cited `README.md#handing-it-to-someone-else`, and the generated project
  README has no such section. **Two README anchors are retired** —
  `#the-ai-layer` and `#handing-it-to-someone-else` now resolve under
  `METHOD.md`. The three citations inside this repository are retargeted;
  an external bookmark to either breaks silently, and that cost is not
  mitigated. The reasoning is
  [`DEC_The_Argument_Moves_Out_Of_The_Entry`](.claude/01_methodvault/02_decisions_(DEC)/DEC_The_Argument_Moves_Out_Of_The_Entry.md).
  New and reordered documentation; no domain, template section, frontmatter
  field, identifier rule, typed relation, validator severity or exporter
  field moves, and no existing vault gains a finding: MINOR.

- **A project starts with three domains and grows into nine** — the vault
  README gains the section "Start With Three, Grow Into Nine": REQ, ARC and
  TAE carry the loop the tools decide on, and one table row per domain names
  the day the other six typically join, with the rule, README or template
  section each trigger comes from. Every domain README states its own trigger
  in one sentence; the conventions file points at the section rather than
  repeating it. `tools/new_project.py` gains `--minimal`, which derives that
  profile: the vault keeps `01_requirements_(REQ)`, `03_architecture_(ARC)`
  and `07_testing_and_evidence_(TAE)` beside ADM and INB, and the other six
  domain folders **move** — they are not deleted — to
  `00_documentation/03_vault_domains_not_in_use/`, where each waits with its
  README and file template. A domain joins later by moving its folder back:
  one command, no migration, and the validator and the export report the same
  state before and after. The flag composes with `--name` and
  `--rename-docs-readme`, refuses before writing anything when a folder it
  would park already carries notes, and leaves the default derivation
  untouched — the tutorial replay is the witness. This is issue #79, and two
  of its premises are corrected in the process: the minimal trio is REQ, ARC
  and TAE rather than REQ, IMP and TAE, because all five coverage gap classes
  are decided on an ARC allocation row or a TAE `verifies:` field and none on
  IMP; and `is_vault_root` never required *exactly* three domain folders, but
  at least three with template files below them, counting `98_administration_(ADM)`
  and `99_inbox_(INB)`. The reasoning is
  [`DEC_A_Project_Starts_With_Three_Domains`](.claude/01_methodvault/02_decisions_(DEC)/DEC_A_Project_Starts_With_Three_Domains.md).
  New capability and new documentation; no domain is added, removed, renamed
  or redefined, `vault_schema.json` and the templates are untouched, and a
  derived project's predicted validator state is unchanged: MINOR.

- **`tools/new_project.py` — deriving a project is one command** — it copies
  the template into a fresh target, strips everything the repository already
  names as template-only (`CONTRIBUTING.md`, this file, the issue forms and
  pull request template, `.claude/01_methodvault/`, the skill's test suite,
  the script's own `tools/` folder), removes the worked example along the
  README's deletion path, rewrites `.github/workflows/validate-vault.yml` to
  the two steps that hold in a derived project — project vault audit and
  export determinism — and generates a project README carrying the project
  name and the method version it derived from. It ends by running the derived
  vault's validator and exits nonzero unless the output matches its
  prediction: zero ERRORs and the one known `duplicate-basename` WARN, or
  none at all with `--rename-docs-readme`, which renames
  `02_documents/README.md` instead of keeping the collision. This is issue
  #76, and it also closes issue #85: the derived workflow no longer runs the
  template's self-test suite, whose worked-example and method-vault
  assertions cannot hold outside this repository, so a derived project's
  first push is green. The reasoning is
  [`DEC_Deriving_A_Project_Is_One_Command`](.claude/01_methodvault/02_decisions_(DEC)/DEC_Deriving_A_Project_Is_One_Command.md).
  New capability, no rule moves, no existing vault gains a finding: MINOR.
- **An architecture map of the validator, for whoever maintains it** —
  [`.claude/skills/mechatronics-docs/ARCHITECTURE.md`](.claude/skills/mechatronics-docs/ARCHITECTURE.md).
  It states the validator's three stages in execution order behind their five
  entry points, one row per check family with the function that owns it and
  whether it runs per file or across the vault, what the stop gate can
  actually block on, and an index of every finding code the tool can emit.
  Until now nothing said where a check lived, so changing one rule meant
  re-deriving the architecture by reading — the defect issue #81 reports. The
  index is not prose: the test suite derives the codes from
  `validate_vault.py` and `vault_schema.json` on every run and fails in both
  directions, on a code the map does not name and on a code the map still
  names after the validator stopped emitting it. Issue #81 puts the number of
  finding codes at 37; that figure was already wrong when the issue was
  filed, and the count of record is now the map's index, which a test keeps
  true. Pointers from `CONTRIBUTING.md`, `SKILL.md` and `STRUCTURE.md`; the
  reasoning is
  [`DEC_Tool_Internals_Are_Documented_Beside_The_Tool`](.claude/01_methodvault/02_decisions_(DEC)/DEC_Tool_Internals_Are_Documented_Beside_The_Tool.md).
  New and corrected documentation, no rule moves: MINOR.
- **The README shows what the export produces, and CI proves it is current** —
  the first section of [README.md](README.md) is now the shipped worked
  example read back out of the vault: the exporter's two count lines and the
  tail of `traceability_index.md`, stored between two marker comments. Nothing
  in it is hand-written or drawn, and a new workflow step regenerates the
  export on every push and fails when the block has drifted, naming the
  command that repairs it. Only the machine-independent lines are stored — the
  index's provenance head carries an absolute path and a digest and would
  differ on every runner. This was the first place in this repository where
  generated content is committed, and the four conditions that bound the
  exception are
  [`DEC_Generated_Content_Is_Stored_Only_Where_CI_Proves_It`](.claude/01_methodvault/02_decisions_(DEC)/DEC_Generated_Content_Is_Stored_Only_Where_CI_Proves_It.md);
  it does not amend the decision that keeps the index itself generated. This is
  issue #78. A derived project inherits neither the block nor the step —
  `tools/new_project.py` writes its own README and its own workflow — so no
  rule moves and no existing vault gains a finding: MINOR.
- **A first success, not a first check — [TUTORIAL.md](TUTORIAL.md)** — the
  quick start used to end with the validator reporting that the shipped vault
  is intact, which is a check and not a result (issue #77). The tutorial is
  the ten-minute path from there: derive a project, write one requirement,
  one evidence note and one allocation row, and watch the exporter go from
  `proven: 0  not proven: 1` to `proven: 1  not proven: 0` — the reader's own
  loop, out of the reader's own three files. The worked example is untouched
  and the tutorial does not depend on it: it runs in a project derived with
  `tools/new_project.py`, where the example is already gone and the two CI
  steps a derived project carries stay green after the reader is done. The
  allocation row starts at `Draft` with an empty evidence cell and only
  reaches `Verified` after the run whose output the reader pastes, because
  the opposite order is the defect this method exists to prevent. The
  document is its own CI fixture: the self-test extracts every file block
  from it, writes them into a throwaway derived project, runs the commands
  the page prints and diffs the output the page quotes, so a tutorial that
  stopped being true fails the suite before it reaches a reader. The
  reasoning is
  [`DEC_A_Tutorial_Is_Replayed_Not_Reviewed`](.claude/01_methodvault/02_decisions_(DEC)/DEC_A_Tutorial_Is_Replayed_Not_Reviewed.md),
  which extends the four conditions of DEC-MTH-037 by the stored-input case.
  `TUTORIAL.md` is template-repo-only and `tools/new_project.py` strips it.
  New documentation and a new assertion, no rule moves, no existing vault
  gains a finding: MINOR.

### Changed

- **The validator's coverage checks now reach translated vaults:
  `req-uncovered`, `verifies-unknown-req` and `req-duplicate-global`.** The
  requirement index resolved its domain by the literal folder abbreviation
  `REQ`, so a vault spelling its requirements folder `01_Anforderungen_(ANF)`
  had an empty index and the three checks never fired there — measured on a
  real 313-file vault: 162 requirements in the exporter's graph, 0 visible to
  the validator. Both tools now resolve domain roles through the schema's
  `domain_aliases` map in one shared derivation
  (`validate_vault.resolve_role_map`), and requirement identifiers are indexed
  under the vault's own prefix (`ANF-BAK-001`), which is what the schema's
  `requirement_id_prefix` rule always promised. This is **PATCH**: no rule
  moved — the coverage definition and the alias contract are unchanged, the
  tool's blindness ended — and per the versioning table's PATCH rule the codes
  are named here so a translated vault can grep before updating. What such a
  vault may newly see: a `verifies:` entry naming a requirement that does not
  exist is an ERROR (`verifies-unknown-req`), a requirement number defined in
  two files is an ERROR (`req-duplicate-global`), and a requirement no
  evidence note verifies is a WARN (`req-uncovered`). In a vault
  mid-translation carrying both folders, both tools now read the folder that
  wins the role — first in sorted order, `export-duplicate-role` names the
  loser — where the validator previously read the English one on its own. The
  row-grammar checks (`req-class`, `req-nnn`, `req-criterion`,
  `req-duplicate`) and the requiredness of `verifies` deliberately stay on the
  English domains: extending blocking checks to translated files would be a
  rule change, not a repaired blind spot. Decision record:
  `DEC_Requirement_Index_Follows_The_Role_Map` (issue #66). **The
  row-grammar half of that last sentence no longer holds:** the entry above
  moves those four codes onto the requirements role, and it is classified as
  the rule change this sentence says it is. The requiredness of `verifies`
  stays exactly where this entry leaves it.

### Fixed

- **A session enforces the copy of the skill it loaded** (PATCH; no finding
  code changes, see the consequence below) — the skill exists twice at once by
  design: vendored in a derived project for its CI and its pre-commit hook,
  installed personally on the machine that maintains it. Claude Code loads the
  personal copy, because personal overrides project by name. The hook commands
  in that same frontmatter, however, enumerated candidate directories starting
  with the project's, and each hook script then resolves its validator relative
  to itself — so a session read the maintained `SKILL.md` and enforced the
  vendored `validate_vault.py` beside it, with nothing saying so. Measured in a
  derived project: the hook executed a validator four days behind the copy the
  session was reading. Both hooks now resolve through `CLAUDE_PLUGIN_ROOT`,
  which Claude Code sets to the loaded skill directory inside skill hooks
  (verified on 2.1.220 and 2.1.226, and for every shape the personal entry
  takes, including a dangling symlink and no entry at all); the remaining
  candidates survive only as a degradation path for a version that does not set
  it, and an unresolvable chain now announces that nothing is enforcing this
  turn instead of exiting silently. `validate_vault.py` carries a
  `SKILL_REVISION` that `--check-install` prints, because the two copies cannot
  be told apart by content — a derived project ships without `tests/` on
  purpose. **Consequence:** a project whose vendored copy lagged behind is now
  enforced by the copy its maintainer edits, so it can report findings the
  vendored copy was blind to. Bump the vendored copy to match, and compare
  `--check-install` on both if they disagree (DEC-MTH-045).

- **The name index stops at the repository, so one commit indexes one set of
  files** — the two indexes every wikilink is resolved against, and the one
  `duplicate-basename` is decided on, were built over the vault root's
  *parent*. In the canonical layout that parent is `00_documentation` and it
  lies inside the repository, which is why the collision between
  `01_projectvault` and `02_documents` is reported and stays reported. In a
  project that versions the vault alone — the layout the validator has
  supported since it learned to read git HEAD — that parent lies outside the
  working tree: measured on such a vault, 53 of 378 indexed files sat outside
  the repository, and the same commit as an isolated clone indexed 322 files
  and none outside it. A link therefore resolved or failed depending on what
  sat beside the checkout, and in a `git worktree` below a scratch directory
  the walk reached that whole directory. The boundary is now the narrower of
  the two, never the wider, so the canonical layout is untouched: verified,
  its index holds the same 49 files and the shipped vault reports the same
  findings. Both messages name the boundary in use instead of a hardcoded
  `00_documentation`, which reads identically in the canonical layout and
  names the vault's own path where no such folder exists. The reasoning, and
  the two accepted residuals — a vault-at-repository-root layout *outside*
  version control, and git-ignored state inside the working tree — is
  [`DEC_The_Name_Index_Stops_At_The_Repository`](.claude/01_methodvault/02_decisions_(DEC)/DEC_The_Name_Index_Stops_At_The_Repository.md).
  Two finding codes can move in a vault of that layout, both named here so
  you can grep before updating: a link that only ever resolved through a
  neighbour of the checkout becomes `link-unresolved` (an ERROR in a full
  run), and a collision with a file outside the repository stops being a
  `duplicate-basename`. Measured on the vault this was found on: zero of
  either. No rule of the method moves: PATCH.

- **A mistyped `--formats` value no longer exits 0 and writes nothing** —
  `--formats jsonn` produced an empty output directory and a green exit, so
  a caller who mistyped it read that as a clean run (issue #98). It is now
  refused with exit 2 and the list of valid formats, checked before the
  vault is read and behind `--fail-on`, whose own precedence is unchanged.
  An empty value is refused the same way rather than falling back to the
  defaults, because `--formats ""` would otherwise stay the one spelling
  that writes nothing in silence. It weighs heavier than the same typo at
  `--fail-on`: there it skips a check, here it destroys the artifact the
  caller asked for, and a CI step diffing two such runs can never fail.
  This closes the first accepted residual of
  [`DEC_CI_Blocks_On_What_A_Session_Only_Warns_About`](.claude/01_methodvault/02_decisions_(DEC)/DEC_CI_Blocks_On_What_A_Session_Only_Warns_About.md),
  which carries a `Corrected by:` line for it now. A run that names a valid
  format is unaffected, and no rule of the method moves: PATCH.

- **The frontmatter-missing message is built from the domain schema** — a file
  without YAML frontmatter was told it needs `(domain, status, created,
  last-verified)` for every domain, but DEC carries no frontmatter `status`
  (the body Status line owns it) and TAE also requires `verifies`. The message
  now lists exactly what the file's own domain requires. This is issue #69,
  fixed in the template's first outside code contribution (#84, thanks to
  @slegarraga): a tool message corrected, no rule moves, so it is PATCH — and
  the only text that changes is the one shown beside an already-firing ERROR.

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

- **No cited amendment date resolves to nothing anymore** — "amendment
  2026-07-28g" was cited four times (`validate_vault.py`, `tests/run.sh`, and
  twice inside the migrated record `DEC_A_Non_UTF8_File_Says_Which_Encoding`)
  for the condition under which `section-mismatch` became the first ERROR to
  enter the stop gate's blocking set, but no record ever carried that date.
  All four citations now read `amendment 2026-07-31` —
  `DEC_A_Near_Miss_Is_Not_An_Absence`, the record that states the condition —
  and the sites that documented the phantom as an open defect (the forwarding
  map in `DECISIONS.md`, residual 5 of the migration decision) record the
  correction instead of describing it as open. This is issue #74:
  documentation and comments only, no rule moves and no vault gains a
  finding, so it is MINOR. Why: `DEC_A_Phantom_Citation_Is_Retargeted` in the
  method vault.
- **CI fails on an open evidence chain in the template vault** — the exporter
  gained `--fail-on <classes>`, and `.github/workflows/validate-vault.yml`
  arms it for `not-allocated` and `no-evidence-note` on
  `00_documentation/01_projectvault`. Without the option nothing changes: a
  coverage gap is still data and still leaves the exit code at 0, and the
  validator still raises `req-uncovered` as a WARN, so no session is blocked
  by an evidence chain that is merely still open. What changes is that the
  closed REQ→TAE loop is now in a blocking path somewhere — until now it
  existed only in a tool that reports. A class name the tool does not know,
  and an empty class list, are refused before anything is read (exit 2, valid
  names printed); an armed run against a graph carrying no requirement fails
  rather than passing, because a gate that cannot fail proves nothing. A
  derived project inherits the option and not the arming — it starts with
  requirements and without evidence, so `tools/new_project.py` names the flag
  in the workflow it generates and leaves it off. This is issue #68 (proposed
  as Alt B in the #50 review): no domain, relation, field, template section
  or rule moves, no vault that was clean becomes unclean, and the default
  path of every existing caller is unchanged, so it is MINOR. Why:
  `DEC_CI_Blocks_On_What_A_Session_Only_Warns_About` in the method vault.

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
