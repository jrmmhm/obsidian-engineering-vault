---
domain: DEC
id: DEC-MTH-026
created: 2026-08-05
last-verified: 2026-08-05
---
Date: 2026-08-05
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-05e — Coverage is decided on the graph, not on a mention (Accepted)".

## Context

`req-uncovered` was a substring search over whole files:

    covered = any(rid in text for p, text in corpus.items()
                  if p != f and vault.classify(p)[1] in ("TAE", "ARC"))

A requirement counted as covered because its identifier appeared
somewhere in some ARC or TAE file — in a heading, in a list of open
points, in a sentence explaining why it was dropped. No allocation row
was required, no evidence note was required, no `verifies:` entry was
required. The README states the method's value as turning "we tested it"
into "these three requirements are still unproven"; that sentence was
true of the exporter and of nothing in the blocking path (issue #50).

Two facts about the state of the rule, measured 2026-08-05 on the two
vault roots this session had access to:

| | template vault | homelab (read-only) |
| --- | --- | --- |
| md files | 39 | 313 |
| `Vault.req_index()` | 3 | **0** |
| requirements in the graph | 3 | 162 |
| `req-uncovered`, old rule | 0 | 0 |
| `req-uncovered`, this change | 0 | 0 |

The homelab column is the more important one. That vault spells its
requirements folder `01_Anforderungen_(ANF)`, so `domains.get("REQ")` is
`None`, `req_index()` is empty, and the coverage rule has never checked
anything there at all — accepted residual 1 of amendment 2026-07-28,
still accepted and now measured a second time.

## Options

- **A — Restrict the text search to table cells.** Rejected: a cell in
  any table is still not an allocation row, and the rule would keep
  answering a question nobody asked.
- **B — Read the allocation table inside `validate_vault.py`.** Rejected:
  an allocation row lives in the section the project's own ARC template
  declares, so this means re-implementing `discover_bindings` and
  `bound_tables` — a third definition of an allocation beside the two the
  table readers were unified into (amendments 2026-07-31b, 2026-08-01).
- **C — Two halves from the two places that already own them.** Chosen.

## Decision

**A requirement is covered when an allocation row names it AND a TAE
names it in `verifies:`.** The two halves come from two readers. The
`verifies:` half is frontmatter, which this validator already parses, so
`evidence_index` builds it from the corpus it has read anyway. The
allocation half is read from the graph `export_traceability.analyse()`
builds, because only its binding discovery finds the section a given
project declares.

**Where the graph carries no requirement of that identifier, the
allocation half is not held against it.** `allocation_index` returns
three states, not two: allocated, not allocated, and *cannot say*. The
graph carries a requirement row only when it sits in the bound section of
a file the graph reads, so a row under a heading of the author's own
making (`REQ_Loose (LSE)` in the suite; seven such tables in nativclaw),
every row of a vault whose REQ role went to a second folder mid-
translation, and every row of a project whose templates declare no
allocation table are invisible there and perfectly correct in the vault.
An adversarial review of the plan measured the alternative: three
findings on the three correct requirements of the shipped template vault,
and a full sweep on a mid-translation vault this project explicitly
supports. The exporter names those three situations itself, as
`export-unbound-table`, `export-duplicate-role` and `export-no-binding`.

**`evidence-disagrees` does not decide coverage.** An allocation row
linking evidence note A while note B is the one naming the requirement in
`verifies:` is a real disagreement and is reported — by the exporter,
where both relations are extracted. Folding it in here would report one
defect under two codes and would contradict `OPEN_QUESTION_CLASSES`.

**The severity stays WARN, and no new finding code is introduced.** The
basis, in order:

1. The line this project already draws. `consistency_rules.verified-needs-
   evidence` refuses anything that "cannot tell them apart" in a check
   that blocks, and this check cannot tell a requirement nobody has
   verified yet from one whose vault never adopted the `verifies:`
   convention.
2. The two false-positive classes above, which the *cannot say* state
   avoids by construction and which an ERROR would have turned into a
   blocked session.
3. External precedent: Doorstop reports an item without links from a
   child document as WARNING and reserves ERROR for an invalid or unknown
   UID — the split this validator already has between `req-uncovered` and
   `verifies-unknown-req`.
4. Vault-wide findings never enter the stop gate's blocking set anyway
   (amendment 2026-07-28f), so ERROR would only change the exit code of
   the full audit.

The measured effect of this change on both real vault roots is **zero
findings either way**. The number that says what ERROR would cost is a
counterfactual and is recorded as one: *if* `req_index()` were role-aware,
the rule would report 162 of homelab's 162 requirements, 129 of them
solely because that vault's evidence notes carry an empty `verifies:`
list. That is a statement about a change this repository has not made,
not about this one.

## Justification

### Rejected by review, before implementation

The plan first added a `coverage-unavailable` WARN and suppressed all
coverage findings whenever the project's templates declared no allocation
table. An adversarial review prototyped it and measured four failing
assertions: the precision fixture's templates carry no tables at all, so
the guard fired on the fixture that must produce zero findings, took
`req-uncovered` out of the violation vault, emptied the fail-open stop
report, and put a vault-wide section into the stop report of a clean
session. The same review found that the planned fixture would have been
built from those very templates and would therefore have asserted nothing
about coverage; that `analyse()` as first specified dropped the findings
accumulator `main()` seeds with `export-schema-unreadable`; that
`except Exception` does not catch `SystemExit`, which is the one exception
class that would exit 2 and release both hooks; and that `ROLE_CACHE`, a
module global refilled per vault root, can bind one vault's tables against
another vault's roles because `hook_stop` loops over roots in one process.
All five corrections are in the decision above, and the fixture now
carries its own table-bearing templates.

## Consequences

### Realization

- `validate_vault.py` — `evidence_index`, `allocation_index` and the
  rewritten coverage block in `validate_vault_wide`; the lazy import
  registers this module under its import name first, because a script run
  leaves it in `sys.modules` as `__main__` and the exporter's own
  `from validate_vault import ...` would otherwise load a second copy of
  it, with two `Vault` classes and two schema caches
- `export_traceability.py` — `analyse()` as the one place the graph is
  built, called by `main()` and by the validator; `ROLE_CACHE` deleted in
  favour of a `roles` parameter on `discover_bindings`
- `vault_schema.json` — `consistency_rules.requirement-coverage`, and the
  `export-driven` level text, which said an entry at that level "never
  produces a validator finding": still true of the entry, no longer true
  of the graph built from it
- `SKILL.md`, `README.md` — the allocation half of the loop, which the
  skill file had never asked for
- `tests/run.sh` — fixture 10, a coverage vault with its own table-bearing
  templates and seven requirements: a closed loop, three identifiers
  written only in prose or in a heading, an allocation without evidence,
  evidence without an allocation, and a closed loop in a table outside the
  bound section. Three variants pin the *cannot say* state (no allocation
  binding, no exporter beside the validator, two requirement folders), and
  one asserts that a script-mode validator and the exporter are one pair
  of modules; 259 to 278 assertions

Observed at the real entry point, the shipped template vault and two
copies of it:

    template vault:                     0 error(s), 1 warning(s), no req-uncovered
    same vault, TAE 'verifies:' removed: 3 x req-uncovered
        "REQ-BAT-001 is named by no TAE in 'verifies'"
    same vault, allocation cells cleared: 3 x req-uncovered
        "REQ-BAT-001 is verified by TAE_Battery_Log_Acceptance but no
         allocation row allocates it"

In both copies the identifiers are still written in the ARC file and in
the TAE body. That is precisely what the old rule accepted as proof.

### Accepted residuals (documented, not solved)

1. **The rule reaches one vault root of the eight on this machine.**
   `req_index()` resolves the REQ domain by folder abbreviation, so every
   German vault is silent here — residual 1 of amendment 2026-07-28,
   unchanged. Whatever this predicate says, it says it about the one
   corpus that spells its folders in English. A role-aware `req_index()`
   is the change with the larger measured payoff and is deliberately not
   in this amendment.
2. **`assess` reads `verifies_back` as a literal** while `reverse_index`
   derives the key from `relations.verifies.reverse_key`. Renaming that
   schema key today mis-renders the export; it does not reach this rule,
   which takes only `not-allocated` from the coverage map, and that class
   is computed from the allocations alone.
3. **A missing `export_traceability.py` degrades the rule silently.** The
   verification half still decides, and nothing says the allocation half
   stopped. `--check-install` is the place that answers "is this copy of
   the skill complete"; it checks `SKILL.md` and no sibling file.
