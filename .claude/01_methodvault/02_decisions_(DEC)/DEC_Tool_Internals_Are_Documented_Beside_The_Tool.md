---
domain: DEC
id: DEC-MTH-038
created: 2026-08-08
last-verified: 2026-08-08
---
Date: 2026-08-08
Status: Accepted

## Context

The enforcement layer of this method is two tools in one directory beside
the skill, `validate_vault.py` and `export_traceability.py`, and the
validator alone runs three stages behind five entry points and can emit
several dozen finding codes. Three documents already answer three
questions about it. The conventions file of a project vault says what a
rule is, for the author who met a finding. This record says why a rule
exists, one note per decision since
[[DEC_The_Decision_Log_Moves_Into_A_Vault]]. `SKILL.md` says how to work
inside the rules. None of them says where a check lives — which function
owns it, whether it runs per file or vault-wide, and which findings can
block a turn.

That is issue #81. A contributor changing one rule has to re-derive the
architecture by reading the whole file first, and the layer that
[[DEC_Enforcement_Layer_For_The_Vault_Conventions]] introduced is
maintained by one person. The question this note answers is not what the
map should say but where a map of a tool belongs at all, because the
answer binds every future document of its kind.

## Options

- **A — a `## Architecture` section in `SKILL.md`.** Rejected. `SKILL.md`
  is a prompt: every session that activates the skill reads it in full,
  and a maintainer's map would be a standing cost paid by every session
  that is not maintaining the validator. Its audience is also wrong —
  `SKILL.md` addresses whoever writes vault notes, not whoever changes
  the tool that checks them.
- **B — a note in this vault.** Rejected, and the closest call. It would
  buy `last-verified` as a freshness signal, wikilink resolution and the
  dead-path check for free, all of which C gives up. But this record
  carries DEC, REF and ADM, and a map of our own code is neither a
  decision nor what REF answers, an external source. Placing it here
  would either bend one domain's question or add a domain to the method
  vault — a larger change to the method than the defect being fixed.
- **C — a file beside the tool it describes, `ARCHITECTURE.md` in the
  skill directory, kept complete by an assertion in the suite.** Chosen.
- **D — no document; rely on review to catch a stale claim.** Rejected.
  The premise of this whole layer is that a rule which is not mechanical
  decays, and a map is exactly the kind of document that rots quietly.

## Decision

Option C. Maintainer-facing tool internals live beside the tool, as
`ARCHITECTURE.md` in the skill directory, discoverable through one-line
pointers from `CONTRIBUTING.md`, `SKILL.md` and `STRUCTURE.md`. Its index
of finding codes is delimited in the file and checked in both directions
by the skill's own test suite: every code the validator can emit must
appear, and every code the index names must still be emitted.

## Justification

- The file a maintainer edits and the file describing it sit in one
  directory, so the map is found by whoever is already in the right
  place.
- A map is only useful whole. Outside a vault no line limit pushes it
  toward a split, which is what the one-question rule would have asked
  of it and the one thing this document may not be.
- The guard supplies mechanically what the vault would have supplied by
  convention: the code index is re-derived from the source on every
  suite run, so the part of the map most likely to rot cannot.
- The id was coordinated rather than counted from the folder, the
  practice [[DEC_A_Phantom_Citation_Is_Retargeted]] already established
  when concurrent work held the neighbouring numbers — gaps are legal, a
  collision is not.

## Consequences

- A new finding code with no row in the map turns the suite red. That is
  the intended cost, and the map says so where a maintainer adding a
  code will read it.
- The guard asserts through exit status rather than by comparing printed
  text, so a missing map, a removed delimiter or a `Finding` call it
  cannot follow are red rather than quietly green. A guard that passes
  when it cannot read its input is the switched-off gate this repository
  exists to prevent.
- Only the index is machine-checked. The entry points, the stage tables
  and the blocking rules are prose, and outside a vault they carry no
  `last-verified` and no dead-path check. This is the price of C, it is
  not mitigated, and the map states its own derivation rule so a reader
  knows which of its claims a test stands behind.
- The map ships into a derived project while the suite and the
  derivation tooling do not, per [[DEC_Deriving_A_Project_Is_One_Command]].
  So the map names those two as belonging to the template repository, and
  the derivation test gains the map in its kept list — a derived project
  that silently lost it would otherwise go unnoticed.
- The guard reads every file as UTF-8 with the byte-order mark tolerated,
  the rule [[DEC_One_BOM_Safe_Reader_For_Every_File]] set for every
  reader in this repository.
- `CHANGELOG.md` records it under Unreleased as new documentation, MINOR.
