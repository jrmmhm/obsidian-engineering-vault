---
domain: DEC
id: DEC-MTH-033
created: 2026-08-08
last-verified: 2026-08-08
---
Date: 2026-08-08
Status: Accepted

## Context

`export_traceability.py` filed every computed reverse edge under a key
derived from `relations.<kind>.reverse_key` in `vault_schema.json`, while
`assess()` read the coverage's evidence half through the literal
`verifies_back` — accepted residual 2 of
[[DEC_Coverage_Is_Decided_On_The_Graph]]. Renaming that one schema key
moved the edges away from the reader: every requirement silently gained a
`no-evidence-note` gap and lost its `evidence-disagrees` check — a
falsified coverage report at exit 0, with the full suite green either
way. Issue #67 asks for the falsification to become impossible or loud.

## Options

- **Option A — fall back everywhere, raise nowhere.** One shared
  derivation with the `<kind>_back` fallback for any absence or junk.
  Once one derivation feeds both readers, a false report is no longer
  constructible, so no error is ever needed. The genuinely minimal diff,
  and the alternative the adversarial review of the plan preferred.
- **Option B — refuse any schema whose relations block lacks an entry for
  an emitted kind.** Loud everywhere. Measured against the seven emitted
  kinds: the refusal fires for five and stays silent for two —
  `contains` and `test-object` edges empty out at their schema-read
  domain gates before any reverse key is asked for — an asymmetry decided
  by read order, and it turns pruned schemas the coverage rule never
  reads into exit-2 refusals.
- **Option C — one shared derivation; absence falls back, declared junk
  and the one load-bearing absence are refused.** `relation_reverse_key()`
  feeds both readers. Any absence — block, entry, field — falls back to
  `<kind>_back`. A `reverse_key` that is declared but not a non-empty
  string is refused, and `assess()` refuses a relations block that no
  longer declares `verifies`, the relation the coverage report is defined
  on.

## Decision

Option C. The refusal is a `ValueError`, caught in `main()` and printed
as `ERROR - …` with exit 2 — the docstring's "output refused", not a
crash. The validator's `allocation_index` already catches every exception
and degrades to its *cannot say* state, so the refusal can never release
the hooks; that degradation is pinned as a fourth variant beside the
three of the coverage fixture.

## Justification

- Consistency alone (option A) makes the false report unconstructible,
  but a schema author who removed the declared vocabulary would get a
  report built on names nobody declared, silently. "Nothing is guessed"
  is the exporter's own charter, and the schema's rule for an unknown
  domain — report and exclude, never guess — is the posture applied here.
- Loudness everywhere (option B) is asymmetric in a way no reader can
  predict, and it widens the change beyond the defect: issue #67 is about
  the coverage report, and `verifies` is the one relation that report is
  defined on.
- The declared-junk refusal replaces two silent behaviours of the old
  inline `or` fallback: `""` and `null` were overridden without a word,
  and a non-string value crashed as a bare `TypeError` dressed as
  `exporter crash`.
- `FALLBACK_SCHEMA` carries no `relations` block, so the
  unreadable-schema path takes the fallback branch and keeps exporting —
  the suite pins it.

## Consequences

- `export_traceability.py` — `relation_reverse_key()` above
  `reverse_index`; `assess(graph, back, schema)`; the `ValueError`
  refusal in `main()`.
- `tests/run.sh` — five A/B scenarios against a patched schema copy, with
  both tools copied beside it because the exporter imports the
  `validate_vault.py` at `sys.path[0]`; 291 tests become 302.
- [[DEC_Coverage_Is_Decided_On_The_Graph]] — accepted residual 2 is
  closed and says so.
- A derived project whose edited schema declares a defective `relations`
  block sees exit 2 with the entry named, where it saw a silently wrong
  or accidentally right report. PATCH under CONTRIBUTING's table: no rule
  moved; the tool stopped being wrong about an input it already had an
  opinion on.
