---
domain: DEC
id: DEC-MTH-009
created: 2026-07-31
last-verified: 2026-08-05
---
Date: 2026-07-31
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-07-31 — A near miss is not an absence (Accepted)".

## Context

`check_sections` derived the required H2 set from the domain template and
reported `template_h2 - file_h2`: a difference of two sets of raw strings,
compared exactly, without positions. A heading a reader would call the
required section but that differs by one byte therefore landed in the
missing set and was reported with the same code, the same message shape and
the same severity as a section nobody ever wrote — and the message named
only the template's spelling. Resolving it meant diffing two heading sets by
hand, at the one place that already held both.

Two questions were conflated, and only one of them is policy. Whether exact
matching is right is defensible either way. Whether the diagnosis is usable
is not: naming a string the author cannot find in their own file is a
missing sentence, not a consequence of strictness. The second question
stands whatever the first one answers (issue #10).

Measured across all six vaults on this machine at the same moment: template
vault, homelab, verdantia and htwsaar carry no `template-sections` finding
at all; PMDE carries 112 affected files naming 241 headings, of which **6
are case-only** (`allgemeine Übersicht` in the template against
`Allgemeine Übersicht` in six `KMP` files) and 235 are genuine; and
realitypatches carries 3, of which **1 is a qualifier**
(`Konsequenzen` against `Konsequenzen / Offene Risiken`). The issue's own
figures — 45 files, 64 headings, 27 % near misses — were measured on
homelab before its English migration and no longer reproduce; PMDE is the
corpus that carries the case class today. The blast radius is small and
measured, which puts this in the bug-fix class rather than the convention-
rollout class this project keeps separating out.

## Options

**Is case part of the contract?**

- **A1 — yes, keep exact matching and only improve the message.**
  Rejected. markdownlint's `MD043`, the most widely deployed required-
  headings rule there is, matches case-insensitively **by default** and
  makes `match_case: true` opt-in, explicitly to avoid breaking existing
  documents. The prostep ivip ReqIF Implementation Guide V1.8 §2.3 states
  the same asymmetry for attribute names: export case-sensitive, but "a
  ReqIF importing tool SHOULD be forgiving when the attribute name is not
  case-sensitive". rustc, Cargo and CPython all treat a case-only
  difference as privileged — rustc short-circuits on a case-insensitive
  exact match *before* any edit-distance math. And blocking on it is a
  convention rollout in disguise: 6 of PMDE's 241 findings, every one of
  them a section that demonstrably exists.
- **A2 — case-insensitive, but the drift stays visible (chosen).** The
  requirement counts as met and a WARN names both spellings, so the
  template's own spelling stays the thing a reader and a search find.

**Is a qualifier part of the contract?**

- **B1 — treat every near miss as met, report a WARN, block on nothing.**
  This is what the adversarial review of this change preferred, and it is
  genuinely simpler: no ERROR moves anywhere, and the issue itself calls
  exact matching for qualifiers "defensible either way". Rejected on one
  concrete consequence: amendment 2026-07-28b binds relations to
  template-declared sections (option E, the documented fallback for a vault
  whose schema signature does not match), so a retitled section silently
  drops out of that binding — the failure is invisible exactly where the
  vault is machine-read. Severity here also follows *certainty*, Clippy's
  criterion for its deny-by-default group: a title the template does not
  carry is a certain deviation, not a guess about intent. Measured blocking
  cost: one file across six vaults.
- **B2 — a qualifier leaves the requirement unmet, but the message becomes
  usable (chosen).** `## Ablauf (Monatlich empfohlen)` is a differently
  scoped section; it should be `## Ablauf` with the qualifier on an `###`
  below. The finding now says so, at the line the heading sits on.

**How is "similar" decided?**

- **C1 — edit distance,** as rustc, Clang and CPython use it, all three
  bounded at about one third of the queried name's length. Rejected: a
  required heading is a *declared* string, not a guess at what the author
  meant, so the whole problem those tools solve — ranking candidates from
  an open vocabulary — does not exist here. Distance would invent
  relationships the corpus does not contain (`Kontext` and `Konzept` are
  two edits apart) and would need a tie policy, which is the documented
  nondeterminism trap in CPython and TypeScript.
- **C2 — one heading extends the other at a word boundary (chosen),** in
  both directions. It covers the two forms the corpora actually contain and
  has no ranking, no threshold and no ties by construction.

## Decision

A2, B2, C2. Three outcomes replace two: met and silent, met and reported
(`section-near-miss`, WARN), unmet and reported with both spellings
(`section-mismatch`, ERROR). `template-sections` keeps its code, its
severity and its one-per-file shape, and now names only sections that were
genuinely never written.

## Justification

### Design points

- **Two levels of comparison, because they answer different questions.**
  `strict_key` removes what the author cannot see — NFC vs NFD spelling of
  an umlaut (macOS hands out NFD, Linux NFC), zero-width characters,
  collapsed whitespace — and two headings differing only there are the same
  heading and stay silent; reporting that would be a finding nobody can
  act on. `fold_key` additionally applies Unicode default case folding
  (Unicode 15.0 §3.13 D144, which `str.casefold` implements), and
  normalises again afterwards, as D145 asks: `casefold('İ')` yields `i`
  plus a combining dot.
- **Folding is not lowercasing, and the message does not pretend it is.**
  `casefold` maps `ß` to `ss`, so `Maßnahmen` and `Massnahmen` fold equal.
  Both spellings are therefore quoted verbatim in every message instead of
  a claim that only the case differs.
- **One grouped finding per file per class.** The lesson of the aggregated
  link feedback in amendment 2026-07-27, and here it carries a second
  weight: `hook_stop` compares per-code counts against the HEAD baseline,
  so a per-heading finding would let a file that *improved* — one absence
  replaced by a qualifier heading — produce more findings of one code than
  its baseline and block the gate for it.
- **Nothing depends on set order.** `extract_h2` returns a set, so which of
  two headings extending one requirement got named used to depend on the
  hash seed. Required headings are iterated sorted, file headings keep
  their first occurrence, candidates are ordered by line, and the finding
  is anchored at the smallest line it names. A test runs the validator
  under two hash seeds and compares.
- **An empty required heading requires nothing.** `extract_h2` keeps `""`
  for a bare `## ` line and `templates_for` filters empty *sets*, not empty
  members — and `fold_key("")` is a prefix of everything, so one stray
  `## ` in a template would have produced a mismatch against the first
  heading of every file of that domain.
- **The new ERROR code is safe against the ratchet.** `hook_post` computes
  the per-file baseline at runtime from `git show HEAD:<file>` with the
  *running* validator, as amendment 2026-07-28f already recorded, so
  `section-mismatch` appears in baseline and current run alike and a
  pre-existing one never blocks. The git-backed fixture asserts it rather
  than the reasoning being trusted.
- **The near-miss count goes in the CLI summary only.** The findings
  themselves already reach `hook_post` and `hook_stop` through the normal
  channels; a second counting mechanism in the hooks would be plumbing
  without a reader.

## Consequences

### Accepted residuals (documented, not solved)

1. **A required section written at the wrong level is still an absence.**
   `### Kontext` where the template declares `## Kontext` produces exactly
   the diagnosis this amendment set out to remove. Measured 0 occurrences
   across all six vaults, and fixing it means deciding whether the level is
   part of a section's identity — markdownlint folds the `#` prefix into
   the compared string, contextlint ignores the level entirely, and neither
   documents the choice. Owed to a follow-up that states the answer.
2. **Heading extraction is fence-blind.** A `## Context` line inside a
   fenced block counts as a heading, which is pre-existing behaviour — but
   the new line anchors can now point *into* a code block. Measured 0
   occurrences.
3. **Case folding collapses more than case**, `ß`/`ss` being the German
   case. The near-miss class is therefore slightly wider than "same
   heading, different case"; the verbatim spellings in the message are what
   keeps it honest.
4. **A file nobody edited can change its message.** Because case misses no
   longer count as unmet, a different template can win the "fewest unmet"
   contest, changing the named closest template and the listed absences.
   Live on the six PMDE `KMP` files.
5. **The error count can rise while the defect count falls.** One grouped
   finding listing two headings becomes one grouped finding plus one
   mismatch finding, which is what takes realitypatches from 12 to 13
   errors without a single new defect.

### Realization

- `validate_vault.py` — `NEAR_MISS_CODES`, `ZERO_WIDTH`, `BOUNDARY_RE`,
  `h2_index()`, `strict_key()`, `fold_key()`, `prefix_related()`,
  `classify_sections()`, `render_headings()`; `check_sections` rewritten
  around the three outcomes and the unmet-first template score;
  `main()` prints the near-miss count. `extract_h2` is untouched — it still
  serves the template side, where positions are meaningless
- `tests/run.sh` — now 119 assertions: a case-only fixture (WARN, and the
  explicit negative that it is not reported as missing), a qualifier
  fixture with two extensions of one requirement, the reverse direction
  where the file's title is the shorter one, a longer-word negative
  control, a hash-seed determinism check, a sixth fixture whose template
  declares two required headings that are prefixes of each other, the
  summary-count assertion, and a git-backed assertion that a pre-existing
  `section-mismatch` does not block the stop gate
- `SKILL.md` and `00_documentation_file_creation_and_conventions.md` — the
  authoring side: the template's spelling is the contract, a qualifier
  belongs on an `###` below

Measured after the change, old vs new validator against the same content at
the same moment: the finding sets are **identical on all six vaults except
where the two new classes apply**. Template vault unchanged at 0 errors /
9 warnings, homelab, verdantia and htwsaar byte-identical, PMDE 404 → 398
errors and 96 → 102 warnings (the six case findings changing severity and
nothing else), realitypatches 12 → 13 errors as residual 5 describes.
`tests/run.sh` at 119 tests, 0 failures.

A note for whoever deploys this: the stop gate's per-session baseline in
`/tmp/claude-mechdocs` is keyed by finding code and recomputed from HEAD by
the running validator, so a session started after the swap is unaffected. A
session already in flight keeps a baseline computed by the old code, where
`section-mismatch` has no entry and a pre-existing one would count as
introduced. Baselines expire after 7 days; deleting the directory makes it
immediate.
