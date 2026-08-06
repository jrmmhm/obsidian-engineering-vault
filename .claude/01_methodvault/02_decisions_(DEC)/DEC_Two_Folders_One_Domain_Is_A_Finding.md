---
domain: DEC
id: DEC-MTH-020
created: 2026-08-04
last-verified: 2026-08-05
---
Date: 2026-08-04
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-04f — Two folders meaning one domain is a finding, not a choice (Accepted)".
Corrected by: [[DEC_One_Abbreviation_One_Folder_By_Rule]]

## Context

Issue #38, residual 4 of amendment 2026-08-04d ([[DEC_Exporter_Reports_Unread_Requirement_Rows]]), found by the adversarial
review of issue #34 and out of scope there. `resolve_roles` keeps the
sorted-first abbreviation via `roles.setdefault(role, abbr)`, and
`build_graph` then skips every file of the other folder at `if role is
None: continue` — the branch that exists for domains nobody declared.
Neither `export-unknown-domain` (an abbreviation the alias map does not
know) nor `export-domain-mismatch` (a file's name inside its folder) has
anything to say about it.

Measured on a copy of the shipped template vault with a second
requirements folder placed beside its own: `requirements: 3 proven: 3`,
`relations: 14`, `findings: 0` becomes `requirements: 3 proven: 0`,
`relations: 8`, `findings: 6` — and all six blame the ARC and the TAE
file for naming identifiers "that do not exist". The one place that is
right about the vault, the requirements folder that was dropped, appears
nowhere in the report.

Zero of the **eleven** vault roots on this machine carry the shape today.
The way to acquire it is a translation, and this repository's own
German→English migration is exactly that.

The letter `e` is skipped deliberately: PR #39 (issue #37) is open and
carries amendment 2026-08-04e ([[DEC_Every_Requirement_Table_Of_The_Bound_Section]]), so taking `f` here keeps the two records
from colliding when both land.

## Options

**Which folder the graph keeps.**

- **A — the first in sorted order, and the choice is reported (chosen).**
- **B — the folder with more files.** Rejected. It moves every identifier
  of the export a second time, at whatever unrelated edit tips the count,
  and in a symmetric mid-translation state the sort decides anyway.
- **C — ingest both, each with its own prefix.** Closer than it looks:
  `expand_requirement_cell` never touches `req_abbr` in its body, it
  matches the prefix found in the cell against the index. But the index
  is built in `build_graph` from the single `req_abbr`, and widening that
  would write every already-translated requirement into the graph twice
  and report its untranslated twin as unallocated. The export would
  describe a larger vault than the one on disk.
- **D — refuse to export.** StrictDoc's answer for a duplicate UID
  (`sys.exit(1)`). Rejected here: this tool reports, it does not block.

Prior art measured against, because the situation is not new: Sphinx-Needs
logs a duplicate need ID as the suppressible warning `needs.duplicate_id`,
keeps the first and continues, and escalates only under `-W`; Doorstop
refuses a duplicate prefix at `doorstop create` but is silently
first-wins when a tree is read from disk, which is filed there as issue
#460 — a defect, not a design; DITA-OT and Sphinx i18n select a language
per build and never merge two variants into one namespace. Nobody keeps
the fuller container.

**Which shapes are the defect.** Both. Two abbreviations for one role
(`01_requirements_(REQ)` beside `01_Anforderungen_(ANF)`) and one
abbreviation twice (`03_architecture_(ARC)` beside
`03_Architektur_(ARC)`) — German and English spell ARC, IMP and REF
identically, so a vault mid-translation carries the second shape whether
anyone intended it or not.

## Decision

A, for both shapes, under one code. `export-duplicate-role`, once per
excluded folder, naming both folders, both ingestible file counts and the
prefix the graph is written with. The rule is: **one role, one folder.**

## Justification

### Design points

- **The first rejection of B was wrong, and the record says so.**
  Sorted-first switches the identifier prefix of the whole export too —
  `REQ-BAT-*` to `ANF-BAT-*`, measured. What survives of the argument is
  when it switches: once, at the moment the author creates the second
  folder, and never again. A count-based winner switches a second time,
  triggered by an edit that has nothing to do with the decision.
- **The scan reads the vault root, not `Vault.domains`.** The index keys
  by abbreviation, so the same-abbreviation pair is already collapsed
  before any role is resolved. `domain_dirs` re-reads the root and sorts
  by name, which is also what makes the finding say the same thing on two
  machines.
- **The finding can name a pair it cannot choose within.** For two
  folders sharing one abbreviation the export reports which one it read
  and says plainly that the file system decided it. That is honest and it
  is not a fix; see the residuals.
- **The count is `build_graph`'s predicate, not a file count.** A name
  starting with the folder's own abbreviation, counted recursively, so
  the number in the message is the gap the graph actually has.
- **The vocabulary grew by one code, against 2026-08-04d's rule.** That
  amendment kept `export-unbound-table` rather than mint a second code
  for a related case. Here no existing code states the situation:
  `export-unknown-domain` is about an abbreviation the map does not know,
  and this one is known and duplicated. The alternative was to overload a
  code with a second meaning, which is worse for a reader than one more
  row in the legend.
- **The fixture's added folder carries a real five-column template.** The
  adversarial review caught this: with the stub template the
  unknown-domain fixture uses, `req_table` binds to nothing and the row
  assertions would pass because nothing at all was exported.

## Consequences

### Accepted residuals (documented, not solved)

1. **Which of two same-abbreviation folders reaches the graph is still
   readdir's decision.** `Vault.__init__` writes `self.domains[abbr] = s`
   in iteration order, so two machines with the same content can export
   different graphs. The export now says so on every run; repairing it
   means changing the validator's index, which the stop gate depends on.
   Its own issue.
2. **The kept folder's templates decide the bindings.** `discover_bindings`
   reads `template_files(vault.domains[abbr])` of the winner, so a stub
   folder that wins can leave `req_table` bound to nothing and cost more
   than its own file count. The finding carries both counts and cannot
   express that second-order loss.
3. **Unmeasured on the corpus.** None of the eleven roots carries either
   shape, so the fixture and the constructed vault are the only evidence
   there is. The measurement below is a proof of absence, not of effect.
4. **Files of the excluded folder that would have been reported as
   `export-domain-mismatch` disappear with it.** They were never in the
   graph; they are no longer named either, and the count does not include
   them.

### Realization

- `export_traceability.py` — `domain_dirs`, `ingestible_count` and
  `duplicate_role_finding` added; `resolve_roles` iterates folders rather
  than `vault.domains` and reports both shapes; the module docstring
  gains the second exclusion reason
- `vault_schema.json` — `domain_aliases.duplicate_role`, with the rule,
  the two rejected alternatives and the prior art
- `tests/run.sh` — the `dup_req_folder` fixture builds the second
  requirements folder in both twins and the second architecture folder in
  the English one; seven assertions, two of which pin the decision rather
  than the fix and say so; 210 to 217 assertions
- `SKILL.md` — the finding enumeration an agent reads
- `00_documentation_file_creation_and_conventions.md` — one paragraph, so
  an author meets the rule where the conventions are

Measured after the change, all **eleven** vault roots on this machine,
old code and new code against one disk state at the same moment, as
finding sets rather than counts:

| vault | requirements | edges | findings | gone | new |
| --- | --- | --- | --- | --- | --- |
| template | 3 → 3 | 14 → 14 | 0 → 0 | 0 | 0 |
| homelab | 84 → 84 | 264 → 264 | 137 → 137 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 0 → 0 | 8 → 8 | 31 → 31 | 0 | 0 |
| PMDE | 93 → 93 | 150 → 150 | 18 → 18 | 0 | 0 |
| photon | 0 → 0 | 0 → 0 | 0 → 0 | 0 | 0 |
| htwsaar | 0 → 0 | 0 → 0 | 1 → 1 | 0 | 0 |
| realitypatches | 0 → 0 | 0 → 0 | 0 → 0 | 0 | 0 |
| verdantia | 0 → 0 | 0 → 0 | 1 → 1 | 0 | 0 |
| Archiv/Bachelor_Bruder | 0 → 0 | 0 → 0 | 7 → 7 | 0 | 0 |
| tmp/BA_Noah | 0 → 0 | 0 → 0 | 7 → 7 | 0 | 0 |
| tmp/mechdocs-test/testproject | 2 → 2 | 9 → 9 | 0 → 0 | 0 | 0 |

Eleven of eleven identical, which is the expected result and the reason
the fixture had to be built: no vault here carries the shape. On the one
that was constructed to carry both shapes, the graph is identical
(3 requirements, 8 edges) and the finding set grows by exactly two rows,
one per excluded folder.

What proves the change is the runtime check. Against that vault the
exporter prints, beside the six findings it printed before:

    '01_requirements_(REQ)' (1 file) and '01_Anforderungen_(ANF)' (1 file)
    are both the REQ domain of this vault - only '01_Anforderungen_(ANF)'
    is in the graph; an identifier spelled REQ-* therefore resolves to
    nothing, because the graph is written with ANF-*.

    '03_Architektur_(ARC)' (1 file) and '03_architecture_(ARC)' (1 file)
    are both the ARC domain of this vault - only '03_architecture_(ARC)'
    is in the graph; which of the two the graph reads is the order the
    file system returns them in, and no rule fixes it.

The shipped template vault still exports 3 of 3 requirements proven with
no findings. `tests/run.sh` at 217 assertions, 0 failures.

A note for whoever deploys this: one finding code was added,
`export-duplicate-role`, and nothing was renamed. The exporter still
never changes its exit code over a finding, and a vault with one folder
per domain sees no change at all.
