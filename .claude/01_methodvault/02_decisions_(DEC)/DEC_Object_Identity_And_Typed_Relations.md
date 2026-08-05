---
domain: DEC
id: DEC-MTH-004
created: 2026-07-28
last-verified: 2026-08-05
---
Date: 2026-07-28
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-07-28b — Object identity and typed relations (Accepted)". Its title names two questions; the record argues both from one Context and is therefore kept whole — see [[DEC_The_Decision_Log_Moves_Into_A_Vault]].

## Context

The vault ships as templates only. A visitor can read the method but
cannot see it work (issue #1), and three structural gaps block the
roadmap behind it. Requirements carry a real identifier scheme
(`REQ-DOM-NNN`); every other domain is identified by its filename, so a
rename changes identity and history cannot connect the note called X
today with the note called Y last spring (issue #3). Relations are
untyped: a wikilink to a requirement and a wikilink to a decision are
the same two brackets, and their meaning lives entirely in the heading
they appear under, so "which requirements does this module allocate" is
a heading-position heuristic rather than a query (issue #4). Without
both, the requirement-to-evidence matrix in issue #2 has no graph to
read — least of all in the reverse direction, which today exists only
as a heading a human interprets.

This amendment settles the minimum data model that carries the worked
example and does not block #3, #4 or #2. It deliberately ships an
*unenforced* scheme: the exporter is not built and the validator is not
made schema-driven, because both are separate issues with their own
acceptance criteria.

## Options

**Identity.**

- **A — Filename stays the identifier, uniqueness promoted to ERROR.**
  Cheapest: `duplicate-basename` already computes vault-wide name
  uniqueness, Obsidian already maintains wikilinks, and a rename becomes
  a loud `link-unresolved` ERROR instead of a silent event. Rejected:
  uniqueness of the *current* name is not continuity of identity, which
  is exactly what issue #3 asks for; and Doorstop is the shipped proof
  of how painful filename-as-UID becomes — its UID *is* the filename,
  renaming invalidates every `links:` entry, and no rename command
  exists.
- **B — Human identifier in frontmatter (chosen).** `id: <DOMAIN>-<SCOPE>-<NNN>`,
  with the existing `REQ-DOM-NNN` row IDs as the already-shipped special
  case of the same rule. Survives renames because identity lives in the
  file, not in its name. Assignment without a registry follows
  StrictDoc, which scans the tree for the next free value rather than
  keeping a counter file.
- **C — Machine identifier (StrictDoc MID).** A 32-character hex UUID
  per object, immune to every human edit. Rejected: MIDs are generated
  by a round-trip writer on save, and this vault is edited by humans in
  Obsidian and has no writer that could assign one. A hand-typed UUID is
  a transcription error waiting to happen.

**Relations.**

- **D — Relation lists in frontmatter on both the ARC note and the
  targets.** Trivial to parse with the existing flat YAML reader.
  Rejected: the allocation would then exist twice, in the table a human
  reads and in the frontmatter a machine reads, and the two would drift.
  Issue #4 is explicit that typing the relations must not move them.
- **E — Bind relations to the template-declared section.** `Vault.templates_for`
  already derives each domain's H2 set from that project's own
  `00_*template*` file, in whatever language it is written, so "the
  table under the ARC template's seventh H2" is language-independent by
  construction. Rejected as the primary mechanism because it is still
  heading position, which is the property issue #4 names as the defect;
  kept as the documented fallback for a vault whose schema is missing.
- **F — Declared table-header signature plus self-typing annotated
  links (chosen).** The schema declares the header row of each relation
  table and binds column roles to it, so the heading above the table is
  irrelevant. Everywhere else, a cross-domain link is annotated with the
  target's identifier — `[[CMP_Battery_Pack]] (CMP-BAT-001)` — and the
  domain token inside the identifier types the relation. Both mechanisms
  read the single place the fact is already authored.

**Reverse direction.** Not an option set: StrictDoc, Doorstop and
Sphinx-Needs all author the relation on the source only and derive the
reverse at build or query time — Sphinx-Needs computes `<kind>_back`
fields, StrictDoc builds the reverse in the traceability graph from
`REVERSE_ROLE`, Doorstop scans every document whose parent prefix
matches. Hand-maintained back-links are rejected by all three, and by
this decision.

## Decision

Option B for identity, option F for relations, with the reverse
direction always derived and never authored.

Identifiers: `id:` in frontmatter, shape `<DOMAIN>-<SCOPE>-<NNN>`,
`DOMAIN` the folder abbreviation, `SCOPE` the subsystem token the REQ
file carries in parentheses, `NNN` local to that pair, never reused,
gaps allowed. REQ files take `REQ-<SCOPE>-000`, with `000` reserved for
the file so that the row IDs `001…` keep their existing meaning and the
two namespaces cannot collide. ADM and INB are excluded because
SKILL.md classifies them as not engineering documentation.

Relations: seven named kinds — `allocates`, `evidence`, `verifies`,
`justified-by`, `connects`, `contains`, `test-object` — each with
exactly one authoring location, each declared in `vault_schema.json`
together with its subject and object domains and its reverse key.

The schema is written now and read by nothing. Every entry carries a
flag stating whether the validator already enforces it internally
(`validator-internal`, meaning the rule exists in Python and the schema
only describes it so that #4 can remove the duplication) or whether
nothing enforces it yet (`declared-only`).

## Justification

_The source record argues its rejections inside Options and carries no
section under this title._

## Consequences

- Issue #3 inherits a settled scheme and one concrete rule to
  implement: vault-wide `id` uniqueness, plus detection of identifiers
  that vanish between commits.
- Issue #4 inherits the schema file, the seven relation kinds and the
  binding rules; its work is making the validator read them.
- Issue #2 inherits a graph in which both directions are derivable from
  authored data, which is the precondition it names.

### Accepted residuals (documented, not solved)

1. **Nothing detects an identifier collision.** The scheme says collisions
   are detected, not prevented; in this change they are neither. Two
   branches can assign the same number and merge green. Owed to #3.
2. **REQ row IDs are still derived from the filename.** `Vault.req_index`
   reads the scope token out of the parentheses in the REQ filename, so
   renaming a REQ file still changes the identity of its rows — the very
   defect #3 describes, now one indirection away from fixed. The scope
   token is additionally declared as the REQ file's own `id`
   (`REQ-<SCOPE>-000`), which is the migration path; making the validator
   prefer it is #3's work.
3. **The table header signature is language-dependent.** A vault written
   in another language finds no relation table and produces an empty
   graph without an error — the same silent-loss class as residual 2 of
   the 2026-07-28 amendment ([[DEC_Language_Independent_Recognition_And_VCS_Tier]]). Mitigated by declaring the schema
   per-project overridable at `00_documentation/vault_schema.json`;
   discovery is declared, not implemented.
4. **Nothing keeps the header signature and the templates in sync.**
   Reformatting the allocation table's header row silently removes every
   relation it carried. A validator rule asserting that an ARC file
   contains a table matching the declared signature belongs to #4.
5. **The example ships into every derived project.** `README.md` names
   the files to delete; `/baseproject-sync` has no notion of the example
   and will not remove it for you.

### Realization

- `vault_schema.json` — field and relation declarations, per entry
  flagged `validator-internal` or `declared-only`; table header
  signatures, consistency rules owed to #3/#4, and the list of links
  that deliberately stay untyped
- Worked example thread in the vault: `REQ_Battery_Monitoring (BAT)`,
  `DEC_Battery_Log_Acceptance_Check`, `ARC_Battery_Monitoring`,
  `CMP_Battery_Pack`, `IFC_PWR_DC_LiPo_Pack`,
  `IMP_Battery_Log_Evaluation`, `TAE_Battery_Log_Acceptance`, plus the
  module row in `system_overview.md`
- `20_software/data_analysis/collect_battery_log.py` and
  `eval_battery_log.py` — stdlib only; the evaluator prints one verdict
  per requirement ID so its output is quotable as evidence
- `30_testdata/31_testdata_raw/2026-07-28_battery_monitoring/` — the
  recorded log and its campaign metadata; the negative control lives
  under `32_testdata_processed/` because it is derived, not measured
- Nine domain templates gained an `id` line; the conventions file gained
  the identifier and relation section
- `.github/workflows/validate-vault.yml` — runs the evaluator against the
  committed log and asserts the negative control still fails
- `README.md` — the worked example, how to re-run its evidence, and how
  to delete it

Measured after the change: template vault unchanged at 0 errors /
9 warnings — the example introduced no new finding — and
`tests/run.sh` at 55 tests, 0 failures. The nine warnings are the
pre-existing ones: eight placeholder wikilinks in READMEs and templates
that no example file can resolve, and one duplicate `README` basename.
The example was never able to clear them; that claim in issue #1 is
wrong and the issue has been corrected.
