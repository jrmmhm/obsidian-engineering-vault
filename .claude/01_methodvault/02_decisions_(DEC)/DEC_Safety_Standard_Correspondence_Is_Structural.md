---
domain: DEC
id: DEC-MTH-030
created: 2026-08-05
last-verified: 2026-08-05
---
Date: 2026-08-05
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-05j — The correspondence to a safety standard is structural, not a claim (Accepted)".

## Context

This repository argues that its documentation can be trusted, and it has
never said where its method stands relative to any safety standard. Issue
#6 asks for that: which domain corresponds to which required work product,
which relation kind carries which required trace, what the standard
demands that this vault has no home for, and — said plainly — whether the
result is a conformance claim or a correspondence.

Three things constrain the answer. The vault's type system is now
declared as data (`vault_schema.json`, nine domains and eight typed
relations, one authoring site each), so there is something concrete to
map. The candidate standards are paywalled, so a mapping written from
memory would be a fabrication with clause numbers on it. And the model
the issue names — StrictDoc's DO-178C document — turns out on reading to
be something else: `docs/strictdoc_40_DO178_requirements.sdoc` at commit
`5a9b679` is titled "Technical Note: DO-178C requirements tool
requirements", carries `CLASSIFICATION: Draft`, and holds requirements on
the tool, each with a `COMPLIANCE` field taking `C`, `PC` or `NC`, split
into "Already implemented features" and "Needs discussion". It is not a
work-product mapping and it claims no conformance. Its form is worth
borrowing; its function was misremembered.

## Options

- **A — No mapping. Close #6 with a comment saying the standard has to be
  bought first.** The strongest option against, and it was argued
  seriously in review: every other claim-bearing artifact here has a
  checker behind it, and this one cannot have one. Rejected because the
  credibility question is asked of this repository whether or not it
  answers, and a correspondence with its gaps named is more useful than
  silence — provided the document says what it is and how far the reading
  behind it went. That proviso became Section 1.
- **B — ISO 26262.** Rejected on its own scope sentence: the ISO
  catalogue entry for ISO 26262-2:2018 states it applies to E/E systems
  installed in series production road vehicles, excluding mopeds. This
  template does not know what its derived project is; asserting that
  scope would assert a domain it does not have.
- **C — ISO 13849, or IEC 62061.** Rejected on breadth and explicitly not
  on applicability. ISO 13849-1:2023 addresses the safety-related parts
  of a control system, while this vault carries mechanics, electronics,
  firmware and host software in one structure. A machine-building project
  would be held to ISO 13849 or IEC 62061 and should write that mapping
  as a second file rather than bending this one. Recording the honest
  reason matters: the weak version of this rejection — "the sector
  standards are inapplicable" — is false.
- **D — IEC 61508 (chosen).** The IEC catalogue entry for IEC 61508-1:2010
  states it has the status of a basic safety publication according to IEC
  Guide 104, aimed at enabling sector standards and at systems for which
  no product standard exists. That is exactly the position of a generic
  mechatronics template. It also has somewhere to map onto: clause 5
  *Documentation* and Annex A *Example of a documentation structure*.
- **E — Place the mapping in the template vault as a REF note.**
  Rejected. It describes the method rather than a project, so every
  derived project would copy an example it has to delete, as with the
  battery thread. It would additionally owe frontmatter, its domain
  template's sections and the 400-line limit. And a REF note points at
  the source it summarises, while `50_sources/04_standards/` is empty
  because a paid standard cannot be committed — the note would point at
  nothing.

## Decision

**`IEC_61508_MAPPING.md` at the repository root, and it is a structural
correspondence.** Not conformance, not certification, not evidence. The
file says so in its first paragraph, repeats it above each table, and
closes on it.

**Clause numbers and published clause titles only.** No normative
requirement text was read and none is paraphrased. Every clause, table,
figure and annex named carries a source key, and the key names the
document that was actually read — I.S. EN 61508-1:2010 as an NSAI free
page sample, not IEC 61508-1:2010 — how far the reading went (contents
list), and the retrieval date. IEC 61508 parts 2, 4, 5, 6 and 7 were
never opened, which the file states; because part 4 is *Definitions and
abbreviations*, the file also states that it uses every 61508 term in its
ordinary English sense.

**A row that cannot be sourced becomes a gap, never a guess** — the same
refusal the export makes for an unknown domain abbreviation. The state
vocabulary is this file's own and deliberately not the standard's:
*structural analogue*, *partial analogue*, *none*.

**The gaps are the durable part**, and they are standard-independent: no
hazard object, no risk estimate, no integrity level anywhere, no object
kind for a safety function with a demand mode, nothing under management
of functional safety because ADM is not engineering documentation, no
field naming who approved anything or with what independence, a
validation-plan status that asserts a plan exists and never points at
one, no record that the impact search after an artifact change happened,
nothing for decommissioning, no home for anything about the tools the
vault is checked by, and no note or field referencing a baseline.

**The file is named for the standard** so the pick is visible in the root
listing and a second mapping is a second file rather than a rewrite.

**The change is MINOR.** No domain, relation, field, template section or
rule moved; a vault that was clean stays clean and gains no finding.
Amendment 2026-08-05h expected issue #6 to be MAJOR "because it would
remap object and relation types" — it did not, and this is recorded here
rather than by editing that amendment, which is append-only. The
changelog entry carries the same sentence, so the two cannot drift.

## Justification

### Rejected by review, before implementation

An adversarial review of the plan, run in a fresh context against the
repository rather than against the plan's reasoning, killed a series of
claims that would otherwise have shipped. Three phrasings had no title
behind them and were replaced by the titles that do: "SIL determination"
under 7.4, which is titled *Hazard and risk analysis*; "competence,
roles, FSM plan" under clause 6, which is titled *Management of
functional safety*; and "tool qualification" for part 3's 7.4.4, titled
*Requirements for support tools, including programming languages*. The
document would have violated its own source rule on its second page.

Five vault-side statements were wrong or loose. The `allocates` direction
was stated backwards — the schema makes the submodule the subject and the
requirement the object. The validation-plan gap ignored that
`00_ARC_README.md` defines the allocation status `Approved` as
"allocation is set, verification plan exists (TAE link or TBD)", which
sharpened the gap into its true form: the status asserts a plan and never
points at one. The baseline gap ignored `60_releases`, which
`STRUCTURE.md` describes as exactly that. The approval gap ignored that
a DEC body line reaches `Accepted` and an allocation row `Approved`,
leaving the real gap at *who* and *with what independence*. And the
exporter section would have presented all five gap classes as deciding
what is proven, when `export_traceability.py` lets only three decide and
holds `no-evidence-note` and `evidence-disagrees` as open questions on
purpose.

Four smaller corrections followed from the same pass: `Class (M/S/O)` is
not merely a priority, since the REQ README defines M as "no release /
unsafe / core function not provided"; the modification gap is a procedure
without a record rather than a missing procedure, because `CLAUDE.md`
already requires the impact search; the vault collapses verification and
validation, which part 3 keeps apart as 7.9 and 7.7, and that collapse is
itself a gap; and part 3's Annex D *Safety manual for compliant items* is
a further named artifact with no home here.

The review's strongest objection was not answered but adopted: this would
be the only document in the repository that asks to be believed, in a
repository whose pitch is that nothing has to be. It is now the content
of Section 1, together with the source key that is the only compensating
control available.

## Consequences

### Realization

- `IEC_61508_MAPPING.md` — seven sections: what it is and is not, why
  IEC 61508 with the three-standard comparison and the StrictDoc
  correction, what was read and what was not, domain-to-clause,
  relation-to-trace over all eight relations including the five with no
  counterpart, eleven gaps, and what the document does not establish
- `README.md` — a pointer at the end of the exporter section, where the
  credibility question is already asked, and the file in the layout block
- `STRUCTURE.md` — a `## IEC_61508_MAPPING.md` section, the treatment
  `AGENTS.md` got, saying why the file is not in the vault
- `CHANGELOG.md` — the entry under `Unreleased`, MINOR, naming the
  deviation from amendment 2026-08-05h

The suffix `j` assumes that issue #51 takes `i`. Like amendment
2026-08-05h before it, this one may move at integration.
