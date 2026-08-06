---
domain: DEC
id: DEC-MTH-025
created: 2026-08-05
last-verified: 2026-08-05
---
Date: 2026-08-05
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-05d — Two declared relations get a source the templates teach (Accepted)". Its `Measured on …` section keeps its position directly behind the context, as the last subsection of `## Context`. One byte-level change: the example wikilink under `### Rejected by review, before implementation` is enclosed in backticks, as the source encloses thirteen of its fourteen wikilink examples, so that it is read as an example and not as a link into this vault.

## Context

`vault_schema.json` declares eight typed relations. Two of them produce no
edge anywhere, and for two different reasons.

`test-object` is declared `export-driven` — "export_traceability.py reads
this entry" — and appears nowhere in the exporter. It was never built.

`contains` declares annotated links in the ARC body lists as its primary
source and the main-module submodule table as `authored_in_secondary`.
Only the secondary source is implemented. The template vault's one ARC
file uses the full template, which has no submodule table, so the
mechanism produces nothing there either.

Behind both sits the same authoring gap. The form the relations rest on,
`[[CMP_Battery_Pack]] (CMP-BAT-001)`, is defined in the conventions file
and in `link_annotation.example` and is shown by no template and no
domain README. A project working strictly from the templates never
writes an annotation and therefore never produces either relation.

### Measured on the template vault, 2026-08-05

    objects: 7  relations: 14  findings: 0
    Counter({'allocates': 3, 'evidence': 3, 'justified-by': 3,
             'verifies': 3, 'connects': 2})

`contains` = 0, `test-object` = 0. The claim in accepted residual 4 of
the export amendment — that the mechanism "is exercised only by the
template vault and the test fixtures" — is false for the template vault
in both cases, and false about the cause for `contains`, which does not
rest on annotated links at all today.

## Options

- **A — Implement both from annotated links, binding the TAE test-object
  to its `## Test Conditions` section.** Rejected. The section would have
  to be discovered from the project's own TAE template, and the only
  available discriminator is "the section containing a wikilink
  placeholder" — template body content, which nothing enforces. This
  file already rejected exactly that class of signal for the table
  bindings (`binding_discovery.why_not_the_header`): the section title is
  enforced by `check_sections`, template body text is not. A project
  adding one example link elsewhere in its TAE template loses every
  `test-object` edge with no finding anywhere. The templates also write
  `\[\[…]]`, so a discovery pass over raw template lines matches nothing
  at all. Beyond discovery, the section is four bullets of which only the
  first is the test object; binding the whole section exports test
  equipment as test object.
- **B — Downgrade both entries to `declared-only`.** Rejected. The data
  the relations need already exists in the template vault: four annotated
  links in `ARC_Battery_Monitoring.md`, two in
  `TAE_Battery_Log_Acceptance.md`. Downgrading deletes a declared
  capability that the corpus already supports, and it removes the
  containment edges a graph-based coverage rule (issue #50) would need.
- **C — Split the two, because they are not one problem.** Chosen.

## Decision

**`test-object` is authored in TAE frontmatter, not in prose.** A
`test-object:` list of object identifiers beside `verifies:`, declared in
`domain_defaults.fields` and required nowhere. This is the only variant
the blocking layer can check — an identifier naming nothing is a finding,
a missing prose annotation never can be — it needs no section binding and
no discovery rule, and frontmatter keys are English in every corpus
measured, which the schema already relies on for `verifies`.

**`contains` keeps its link-based primary source, with object domains
declared per source.** Annotated links in an ARC body outside the bound
tables become `contains` edges to REQ, DEC, CMP and IMP; the submodule
table remains the secondary source and is the one that may reach ARC.
The split is what keeps a "Related Modules" bullet — an annotated ARC
link in the Context section — from being exported as containment, and it
corrects a schema that currently forbids the ARC target its own
secondary source produces.

**A wikilink that could have been a relation and carries no annotation is
reported.** Without it this change is a no-op on every vault that has not
adopted `id:` yet, and silently so — the one output this exporter's own
module docstring forbids.

**An annotation whose identifier contradicts the file it links to is
reported.** The edge follows the wikilink, as everywhere else; the
disagreement is named rather than resolved. This is what makes the
annotation load-bearing instead of a decorative suffix.

## Justification

### Rejected by review, before implementation

The plan first bound `test-object` to the TAE `## Test Conditions`
section, discovered as "the section of the project's own TAE template
that contains a wikilink placeholder". An adversarial review of the plan
killed it on three counts, each verified against the source: the
discriminator is template body text, which nothing enforces — the same
class of signal `binding_discovery.why_not_the_header` already rejected
with measurements; the templates write `\[\[…]]`, so a pass over raw
template lines would have matched nothing at all; and the section holds
the setup and the equipment beside the test object, so a real note
reading "Test setup: `[[CMP_Oscilloscope]]` (CMP-EQP-002)" would have
exported an oscilloscope as a test object. The review also found the
plan internally inconsistent — it read only REQ/DEC/CMP/IMP from the ARC
body while widening `object_domains` with ARC — and noticed that without
a finding for unannotated links the change is a no-op on every vault
that has not adopted `id:`, silently. All three corrections are in the
decision above.

## Consequences

### Realization

- `export_traceability.py` — `body_links` (annotated and unannotated
  wikilinks of a file body, fenced blocks and frontmatter and
  already-bound table lines stepped over, one entry per distinct target
  in file order), `_contains_from_body`, the `test-object` block beside
  `verifies` in `build_graph`, per-source domain filtering for both
  `contains` sources, and `ANNOTATION_RE`
- `vault_schema.json` — `domain_defaults.fields.test-object`;
  `contains.object_domains_primary` / `object_domains_secondary` with
  `object_domains` kept as their union; both relation notes
- `validate_vault.py` — `OBJECT_ID_RE` and the `object-identifier` item
  branch of `check_field_value`, plus the same field in
  `FALLBACK_SCHEMA`, which the suite compares against the shipped schema
- templates and READMEs — the annotated form in the four ARC list
  sections and their README entries, the `test-object` field in the TAE
  template, the worked example filling it
- `00_documentation_file_creation_and_conventions.md` — the annotation
  as the statement, the two deliberately unannotated shapes, and the
  frontmatter form of `test-object`
- `tests/run.sh` — fixture 7 gains the four link shapes and a
  `test-object` field naming one file that exists and one that does not;
  251 to 259 assertions

Observed at the real entry point, the template vault, before and after:

    before:  objects: 7  relations: 14  findings: 0
             allocates 3, evidence 3, justified-by 3, verifies 3, connects 2

    after:   objects: 7  relations: 20  findings: 0
             contains 4, allocates 3, evidence 3, justified-by 3,
             verifies 3, connects 2, test-object 2

The four `contains` edges come from links that were already in
`ARC_Battery_Monitoring.md` and had never been read.

---
