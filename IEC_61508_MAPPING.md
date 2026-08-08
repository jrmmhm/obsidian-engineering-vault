# IEC 61508 — Structural Correspondence

**The one question this file answers:** which clauses of IEC 61508 do this
vault's domains and typed relations structurally resemble, and which of them
have no home here at all?

---

## 1. What this document is, and what it is not

This is a **structural correspondence** between the object kinds and relation
kinds this template declares and the clause structure of IEC 61508. It is
**not a claim of conformance**, not a certification claim, and not evidence of
anything. No assessment has taken place. No auditor, notified body or
functional safety assessor has looked at this repository. Using this template
does not make a project IEC 61508 conforming, and a row below marked
*structural analogue* says only that two things have the same shape — never
that a clause is satisfied.

It is also, and this matters, **the only claim-bearing document in this
repository that no machine checks.** The worked example is re-run by CI and its
negative control must fail. The export is diffed against itself for
determinism. The template vault is audited by path so the check cannot silently
skip. This document has none of that: IEC 61508 is a paid standard, this
repository owns no copy of it, `50_sources/04_standards/` is empty, and no CI
step reads root Markdown. What stands in for a checker is Section 3 and the
source key on every clause cited — a dated record of exactly which document was
read, on which day, and how far into it the reading went.

Read that as the honest limit it is. The durable part of this file is
[Section 6](#6-gaps--what-the-standard-names-and-this-vault-has-no-home-for):
the gaps hold against IEC 61508, ISO 13849, IEC 62061 and ISO 26262 alike,
because they are properties of this vault rather than of any one standard.

---

## 2. Why IEC 61508, and not ISO 26262 or ISO 13849

The choice was deliberate and it was made on scope, not on familiarity.

| Standard | Scope, as its publisher states it | Verdict |
| -------- | --------------------------------- | ------- |
| **IEC 61508-1:2010**, Ed. 2.0 | Functional safety of E/E/PE safety-related systems. The IEC catalogue entry states it "has the status of a basic safety publication according to IEC Guide 104", aimed at enabling sector-specific standards and at systems for which no product standard exists `[W1]` | **Chosen** |
| **ISO 26262-2:2018** | Applies to E/E systems "installed in series production road vehicles, excluding mopeds" `[C262]` | Rejected on scope |
| **ISO 13849-1:2023**, 4th ed. | Design and integration of safety-related parts of control systems (SRP/CS) performing safety functions, for high demand and continuous mode `[C849-1]` | Rejected on breadth |

IEC 61508 is chosen because this is a **generic** template. It does not know
whether the project derived from it is a vehicle, a machine, a laboratory
instrument or a homelab rack, and a basic safety publication is precisely the
document written for the case where no product standard has been picked yet.
ISO 26262 excludes this template by its own scope sentence: mapping a
domain-neutral method onto a road-vehicle standard would assert a domain the
template does not have.

The ISO 13849 rejection is the one worth stating carefully, because the weak
version of it would be wrong. ISO 13849-1 and IEC 62061 are exactly the
standards a machine-building project *would* be held to, and IEC 61508 answers
this vault's `REF`, `DEC` and `OAU` domains no better than they do. ISO 13849
is rejected here for breadth alone: it addresses the safety-related parts of a
*control system*, while this vault carries mechanics, electronics, firmware and
host software in one structure. Its validation clauses are notably well shaped
for this purpose — `[C849-2]` names 4.2 *Validation plan*, 4.5 *Information for
validation* and 4.6 *Validation record* — and a project that needs them should
map against ISO 13849 in a second file rather than bending this one.

One relationship claim, stated so it is not inferred: ISO 13849 does **not**
derive from IEC 61508. It comes from the EN 954 line; the machinery-sector
derivative of IEC 61508 is IEC 62061.

**The credibility model, described accurately.** GitHub issue #6 names
StrictDoc's DO-178C document as the model for establishing credibility against
a standard. Read at the source, that document is something narrower than the
framing suggests `[SD]`: it is titled *"Technical Note: DO-178C requirements
tool requirements"*, carries `CLASSIFICATION: Draft`, and holds requirements on
the **tool** — each with a `COMPLIANCE` field taking `C`, `PC` or `NC` — split
into sections *"Already implemented features"* and *"Needs discussion"*. Its
own introduction says these requirements "are recommended by engineers who
adhere to the DO-178B and DO-178C standards of the aviation industry". It is
therefore not a mapping of object kinds onto work products, and it makes no
conformance claim. What is borrowed here is its **form** and not its function:
a state per row rather than a paragraph of prose, an explicit place for what is
unresolved, and a draft classification worn openly.

---

## 3. What was read, and what was not

Every IEC 61508 clause, table, figure and annex named in this document is cited
by **number and published title only**. No normative requirement text was read,
and none is paraphrased anywhere below. Where a term such as *demand mode* or
*independence* appears, it is because that term stands in a title that was
read — the source key says which one.

| Key | Document actually read | Extent | Retrieved |
| --- | ---------------------- | ------ | --------- |
| `[P1]` | **I.S. EN 61508-1:2010** — the Irish adoption of EN 61508-1:2010, itself the adoption of IEC 61508-1:2010 — NSAI free page sample, 17 pages, published via Intertek Inform | Contents list, foreword start. No clause body. | 2026-08-05 |
| `[P3]` | **IEC 61508-3:2010**, Ed. 2.0 — iTeh standard preview | Contents list. No clause body. | 2026-08-05 |
| `[W1]` | IEC catalogue entry for IEC 61508-1:2010 (webstore.iec.ch, publication 5515) | Title, edition, abstract | 2026-08-05 |
| `[C262]` | ISO catalogue entry for ISO 26262-2:2018 (iso.org, standard 68384) | Title, abstract | 2026-08-05 |
| `[C849-1]` | ISO catalogue entry for ISO 13849-1:2023 (iso.org, standard 73481) | Title, abstract | 2026-08-05 |
| `[C849-2]` | ISO 13849-2:2012 — iTeh standard preview | Contents list | 2026-08-05 |
| `[SD]` | `docs/strictdoc_40_DO178_requirements.sdoc` in `strictdoc-project/strictdoc`, at commit `5a9b679` | Whole file | 2026-08-05 |

Note that `[P1]` is the Irish adoption, not the IEC publication. Clause
numbering is identical between them; document identity and foreword are not.

**Not read at all:** IEC 61508 parts 2, 4, 5, 6 and 7. Part 4 is *Definitions
and abbreviations*, so every IEC 61508 term in this document is used in its
ordinary English sense and **not** as IEC 61508-4 defines it. A reader who
needs the defined meaning needs the standard.

**Not published here:** no full text of any standard is reproduced, quoted at
length, or linked through an unauthorised copy. Several such copies surfaced
during the research for this file and were deliberately not used.

**The rule that produced the tables below:** a row that could not be anchored
to a title actually read became a gap in Section 6 instead of a guess. That is
the same refusal `vault_schema.json` states for the export — *"Never guessed: a
silent guess is how an export starts describing a vault it did not
understand."*

---

## 4. Domain → clause

State vocabulary, which is this file's own and **not** the standard's:
*structural analogue* — the two describe the same kind of thing;
*partial analogue* — they overlap and diverge in a way the note states;
*none* — nothing in the parts read names a counterpart.

*Nothing in this table is a conformance statement. A clause is named by its
published title; what it requires is not stated here.*

| Vault domain | IEC 61508 clause, by number and published title | State | What the state rests on |
| ------------ | ----------------------------------------------- | ----- | ----------------------- |
| `01_requirements_(REQ)` | 7.5 *Overall safety requirements*; 7.10 *E/E/PE system safety requirements specification* `[P1]`; Part 3, 7.2 *Software safety requirements specification* `[P3]` | partial analogue | REQ rows carry `Class (M/S/O)` and an acceptance criterion. The class is a binding nature, defined in `00_REQ_README.md` as "M (Mandatory): Must be fulfilled. Without fulfillment no release / unsafe / core function not provided" — it is not derived from a risk estimate and carries neither a demand mode nor a target failure measure (contrast Tables 2 and 3 of `[P1]`). |
| `02_decisions_(DEC)` | none named in the parts read | none | A rationale record is not a work product named in `[P1]` or `[P3]`. DEC is a vault-native domain. |
| `03_architecture_(ARC)` | 7.6 *Overall safety requirements allocation* `[P1]` | partial analogue | The allocation table is authored in ARC, one row per submodule. Figure 6 of `[P1]` is titled *"Allocation of overall safety requirements to E/E/PE safety-related systems and other risk reduction measures"*; the vault allocates to `ARC`/`CMP`/`IFC` submodules and to nothing else, and attaches no integrity level. |
| `04_components_(CMP)` | none named in the parts read | none | Element and subsystem description lives in IEC 61508-2, which was not read. Stated as unsourced rather than assumed. |
| `05_interfaces_(IFC)` | none named in the parts read | none | No interface work product is named in the contents lists read. |
| `06_implementation_(IMP)` | 7.11 *E/E/PE safety-related systems – realisation* `[P1]` | partial analogue | Title-level analogue only: the substance of 7.11 lives in parts 2 and 3, and part 2 was not read. IMP points at the artifact rather than describing a realisation activity. |
| `07_testing_and_evidence_(TAE)` | 7.18 *Verification*; 7.14 *Overall safety validation* `[P1]`; Part 3, 7.7 *Software aspects of system safety validation* and 7.9 *Software verification* `[P3]` | partial analogue | One vault domain stands opposite two separately titled activities. `[P3]` keeps verification (7.9) and validation (7.7) as distinct clauses; TAE carries no field that distinguishes the two kinds of evidence. See gap 8. |
| `08_operation_and_usage_(OAU)` | 7.7 *Overall operation and maintenance planning*; 7.15 *Overall operation, maintenance and repair* `[P1]` | partial analogue | OAU is the runbook. Nothing in it is a plan produced before operation, and it has no counterpart to 7.17 *Decommissioning or disposal*. |
| `09_references_(REF)` | none named in the parts read | none | A summary of an external document is a vault-native domain. |
| `98_administration_(ADM)`, `99_inbox_(INB)` | 6 *Management of functional safety* `[P1]` — no home | none | `SKILL.md` classifies both as **not** engineering documentation, and `vault_schema.json` excludes them from the identifier scheme. ADM does carry a "Risk/blocker list (What prevents progress)" — that is project and schedule risk, not hazard or safety risk. See gap 3. |

---

## 5. Relation → trace

All eight typed relations declared in
[`vault_schema.json`](.claude/skills/mechatronics-docs/vault_schema.json) are
listed, including the five with no counterpart. Each is authored in exactly one
place and one direction; the reverse direction is computed and never written
down.

*Nothing in this table is a conformance statement.*

| Relation, and where it is authored | Nearest activity named in the parts read | State | Note |
| ---------------------------------- | ---------------------------------------- | ----- | ---- |
| **`allocates`** — subject `ARC`/`CMP`/`IFC`, object `REQ`; authored in the ARC allocation table | 7.6 *Overall safety requirements allocation* `[P1]` | partial analogue | The authored direction is submodule → requirement; "is allocated to" is the computed reverse. Structurally the same act, over a different object set: Figure 6 of `[P1]` names E/E/PE safety-related systems and other risk reduction measures, and the vault's edge carries no integrity level. |
| **`verifies`** — subject `TAE`, object `REQ`; authored in TAE frontmatter | 7.18 *Verification* `[P1]`; Part 3, 7.9 *Software verification* `[P3]` | partial analogue | The one edge in this vault that closes a requirement-to-evidence loop by naming the requirement rather than the module. |
| **`evidence`** — subject `ARC`/`CMP`/`IFC`, object `TAE`, qualified by a status; authored in the same allocation row | none named | none | The status qualifier (`Draft`, `Approved`, `Verified`, `Deprecated`, `Blocked`) is a close-out state of an allocation. No trace of that name appears in the parts read; the shape is this project's own. |
| **`justified-by`** — subject `REQ`, object `DEC`/`REF`; authored in the requirement table's justification column | none named | none | Vault-native. |
| **`connects`** — subject `IFC`, object `CMP`/`ARC`; authored in the ARC interface table | none named | none | Vault-native. |
| **`contains`** — subject `ARC`, objects `REQ`/`DEC`/`CMP`/`IMP`/`ARC`; authored in annotated ARC body links and the main-module submodule table | none named | none | Vault-native decomposition. |
| **`test-object`** — subject `TAE`, object `CMP`/`IFC`/`ARC`; authored in TAE frontmatter | none named in `[P1]`/`[P3]`; compare ISO 13849-2:2012, 4.5 *Information for validation* `[C849-2]` | none | Named across the fence deliberately: the nearest titled counterpart found sits in a standard this file did not choose. |
| **`superseded-by`** — subject `DEC`, object `DEC`; authored in the DEC body line | none named | none | Vault-native document control. |

---

## 6. Gaps — what the standard names and this vault has no home for

Each gap names a clause, table or annex **title** that was read, and then what
this vault does and does not carry against it. This is the section to read
first if you are deciding whether the method is enough for your project. It is
not exhaustive: five of the seven parts were never opened.

1. **7.4 *Hazard and risk analysis* `[P1]` — no home.** There is no hazard
   object kind, no risk estimate anywhere, and nothing that produces the
   integrity level the requirement rows would need to carry one.
2. **Tables 2 and 3 of `[P1]`, titled *"Safety integrity levels – target
   failure measures for a safety function operating in low demand mode of
   operation"* and *"…high demand mode of operation or continuous mode of
   operation"* — no home.** The vault has no object kind for a safety function,
   no demand mode attribute and no target failure measure. A repository-wide
   search finds no integrity-level field in the schema, the templates or the
   frontmatter of any note.
3. **6 *Management of functional safety* `[P1]` — no home.** Nothing under that
   heading has a place: `SKILL.md` puts project logistics in `ADM` and excludes
   `ADM` from engineering documentation, so anything organisational is outside
   the traced structure by construction.
4. **8 *Functional safety assessment* `[P1]`, with Tables 4 and 5 titled
   *"Minimum levels of independence of those carrying out functional safety
   assessment"* — partial, and the missing half is the important one.** States
   exist: a DEC body line reaches `Accepted`, an allocation row reaches
   `Approved` and then `Verified`. What no field records is **who** approved
   anything, and there is no attribute anywhere for the independence of whoever
   did.
5. **7.8 *Overall safety validation planning* `[P1]`; Part 3, 7.3 *Validation
   plan for software aspects of system safety* `[P3]` — no artifact.** The
   allocation status `Approved` is defined in `00_ARC_README.md` as "allocation
   is set, verification plan exists (TAE link or TBD)". The status therefore
   *asserts* that a plan exists and never points at one: there is no plan
   artifact and no object kind for one.
6. **7.16 *Overall modification and retrofit* `[P1]` — procedure without
   record.** `CLAUDE.md` and the vault conventions do require that after
   changing an artifact you search the vault for notes referencing it and bring
   them along in the same session. No artifact records that the search
   happened or what it found; `last-verified` records only that a file was
   re-read.
7. **7.17 *Decommissioning or disposal* `[P1]` — no home.** No domain answers
   it, and `99_archive/` is a location rather than a record.
8. **Verification and validation are one domain here.** `[P3]` titles 7.9
   *Software verification* and 7.7 *Software aspects of system safety
   validation* as separate clauses; `TAE` covers both and carries no field
   distinguishing the two kinds of evidence.
9. **Part 3, 7.4.4 *Requirements for support tools, including programming
   languages* `[P3]`, and Table A.3 *"Software design and development – support
   tools and programming language"* — no home.** There is nowhere to write down
   anything about the tools the documentation is itself checked by, which in
   this repository means `validate_vault.py` and `export_traceability.py`.
10. **Part 3, Annex D (normative) *Safety manual for compliant items –
    additional requirements for software elements* `[P3]` — no home.** No
    domain produces a manual of that kind for a reused element.
11. **5 *Documentation* `[P1]` and Annex A (informative) *Example of a
    documentation structure* `[P1]` — partial.** The vault gives every note
    machine-readable frontmatter, a validator and git history, and
    [`60_releases/`](STRUCTURE.md) is where a project records baseline
    snapshots with a version, a date and a git tag. What is missing is the
    link: no note, field or identifier references a baseline, no document
    carries a revision index of its own, and no field names an approver.

---

## 7. What this document does not establish

It does not establish conformance, and nothing in it should be quoted as
evidence of any. It does not establish that a clause named above is satisfied
by anything in this repository — only that two structures resemble each other
at the level of a published title. It does not cover IEC 61508 parts 2, 4, 5, 6
and 7, which were never opened, and it therefore cannot say what those parts
would add to Section 6.

What the repository's own tools do contribute is narrow and worth stating
exactly once, because [METHOD.md](METHOD.md#handing-it-to-someone-else)
already describes it: the exporter names, per requirement, what is unproven
rather than leaving an empty cell. Three of its classes decide whether a
requirement counts as proven — `not-allocated`, `not-proven` and
`evidence-is-prose` — while `no-evidence-note` and `evidence-disagrees` are
reported as open questions and deliberately do not decide, because a vault that
never adopted the `verifies:` convention would otherwise have every requirement
declared unproven. The validator raises `req-uncovered` as a WARN on the same
question, for the same reason.

That reason is about a vault whose conventions the reader owns and the tool does
not. It does not hold where both are the same party: this repository authors the
vault under `00_documentation/01_projectvault` and guarantees that its evidence
notes carry `verifies:`, so its CI runs the exporter with
`--fail-on not-allocated,no-evidence-note` and fails on either. Two things
follow, and neither should be read as more than it is. The exporter still
reports by default — the exit code changes only where a caller names the classes
it refuses, and no session, hook or derived project does. And a check armed
against one vault says nothing about any other: a project made from this
template inherits the option switched off, because it will have requirements
long before it can have evidence.

If you actually need conformance rather than a resemblance, the honest next
steps are to buy the parts that apply to your project, decide with a competent
assessor which of the gaps in Section 6 your project has to close, and treat
this file as what it is: a starting map, drawn from titles, by someone who has
not read the standard.
