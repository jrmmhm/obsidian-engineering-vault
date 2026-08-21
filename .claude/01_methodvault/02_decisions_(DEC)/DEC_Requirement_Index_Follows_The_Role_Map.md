---
domain: DEC
id: DEC-MTH-034
created: 2026-08-08
last-verified: 2026-08-08
---
Date: 2026-08-08
Status: Accepted
Corrected by: [[DEC_Per_File_Checks_Follow_The_Role_Map]] – the row-grammar refusal below priced a cost belonging to the 'verifies' requirement alone; measured for the row checks it is nil

## Context

The validator's requirement index resolved its domain by the literal
folder abbreviation: `Vault.req_index()` asked `domains.get("REQ")`, so a
vault spelling its requirements folder `01_Anforderungen_(ANF)` had an
empty index, and `req-uncovered`, `verifies-unknown-req` and
`req-duplicate-global` never fired there. [[DEC_Coverage_Is_Decided_On_The_Graph]]
measured the gap - 313 files, 162 requirements in the exporter's graph,
0 visible to the validator - and recorded a role-aware index as the
residual with the larger payoff, deliberately left open. The same
residual stood since [[DEC_Language_Independent_Recognition_And_VCS_Tier]].
The exporter never had the gap: `resolve_roles` translates folder
abbreviations to canonical roles through the schema's `domain_aliases`
map. Issue #66 asked the validator to resolve the same way, through one
shared derivation rather than a second resolver.

## Options

- **A - Duplicate the alias resolution in the validator.** Rejected: two
  resolvers drift exactly where it costs the most, a vault
  mid-translation, and drift between twin readers is what the table and
  fence unifications were bought to end.
- **B - Have the validator call the exporter's resolver.** Rejected: the
  exporter imports `validate_vault` at module level, the validator
  reaches the exporter only lazily and defensively in
  `allocation_index` - and a vendored validator without the exporter
  (tested as fixture 10c) must keep working.
- **C - Move the derivation into the validator, exporter delegates.**
  Chosen: `resolve_role_map` in `validate_vault.py` is the one rule;
  the exporter's `resolve_roles` keeps its name and renders its findings
  from the shared result.

## Decision

**One role derivation, in `validate_vault.resolve_role_map`.** Sorted
iteration over the vault's abbreviations, ADM and INB excluded, an
abbreviation is its own role when the identity list names it and is
translated through `domain_aliases.map` otherwise, first in sorted order
wins a contested role. `Vault.roles()` caches it; the exporter's
`resolve_roles` turns the dropped abbreviations into its existing
findings, set-identical, order changed only where every consumer sorts.

**The index carries the vault's own requirement prefix.** Keys are
`ANF-BAK-001` in a German vault, per
`domain_aliases.requirement_id_prefix` - the exporter's spelling, so
`verifies:` entries, graph requirements and the index meet under one
vocabulary. Doorstop keys item UIDs on the document's own prefix and
Sphinx-Needs resolves external needs through a declared prefix map; a
constant `REQ` was the anomaly. `req_scope` takes the abbreviation and,
for `REQ`, accepts exactly what it accepted before.

**Only the coverage path follows the map.** The evidence trigger, the
`verifies` id pattern, `evidence_index` and the global duplicate scan
resolve roles; the four blocking row-grammar codes and the requiredness
of `verifies` stay on the literal English domains - extending blocking
checks to translated files is the convention rollout
[[DEC_Language_Independent_Recognition_And_VCS_Tier]] refused, and it
stays refused. `FALLBACK_SCHEMA` carries the alias map, so an unreadable
schema cannot switch the capability off silently behind one WARN.

## Justification

- One derivation is the same argument as one cell splitter and one fence
  definition: two readers of one vault must not disagree about what the
  vault contains.
- The prefix rule was already written down in the schema and already
  lived in the exporter; the validator was the only reader ignoring it.
- An adversarial review confirmed the `req_scope` equivalence for the
  English prefix case by case and in a 295-case property test, and
  caught the fallback gap and a fixture sort-order inversion before
  implementation.

## Consequences

### Realization

- `validate_vault.py` - `resolve_role_map`, `Vault.roles()`, role-aware
  `req_index`/`req_scope`/`check_tae_verifies`/`evidence_index` and the
  duplicate scan, `FALLBACK_SCHEMA.domain_aliases`
- `export_traceability.py` - `resolve_roles` delegates to the shared
  derivation and keeps its findings
- `vault_schema.json` - `domain_aliases` notes and the coverage rule's
  `enforced_detail` describe the shared readership
- `tests/run.sh` - the German twin pair carries requirements and
  evidence domains; the issue #66 block pins the three codes under the
  `ANF` prefix, the fallback parity and the one-derivation identity;
  291 to 300 assertions
- `CHANGELOG.md` - PATCH: no rule moved, the tool's blindness ended;
  the entry names the three codes

### Accepted residuals (documented, not solved)

1. **The mid-translation handoff has no validator finding.** With `ANF`
   beside `REQ`, the role - and with it the whole coverage path - goes
   to the first in sorted order for both tools, by
   [[DEC_One_Abbreviation_One_Folder_By_Rule]]'s argument. The English
   rows leave the index silently as far as the validator is concerned;
   `export-duplicate-role` names the folder that lost, and the twin
   fixtures pin both halves of the behavior.
2. **`id-scope-mismatch` stays literal.** The identifier scheme itself
   is English-vocabulary by decision, so an `ANF`-prefixed id never
   enters that comparison; aligning the folder lookup would change
   nothing observable.
3. **Translated rows are indexed but not row-checked.** The index reads
   `ANF` rows the row-grammar checks never read, and
   `req-table-unrecognized` deliberately stays dark there - firing on
   every translated file would be a rollout, not a defect report.
