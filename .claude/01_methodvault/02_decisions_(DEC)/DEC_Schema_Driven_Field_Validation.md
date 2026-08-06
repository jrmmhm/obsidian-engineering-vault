---
domain: DEC
id: DEC-MTH-006
created: 2026-07-28
last-verified: 2026-08-05
---
Date: 2026-07-28
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-07-28d — Schema-driven field validation (Accepted)".
Corrected by: [[DEC_Frontmatter_Reader_Learns_The_Editor_Spelling]]

## Context

Amendment 2026-07-28b wrote `vault_schema.json` and had nothing read it.
The frontmatter rules therefore existed twice: as data in the schema and
as Python literals in `check_frontmatter` (`GENERIC_STATUS`,
`DEC_BODY_STATUS`, the required-key list, the `("M","S","O")` tuple).
Issue #4 asks for the reverse: the file becomes authoritative, the code
reads it, and a field nobody declared is reported instead of ignored.

Two measurements framed the whole change. First, a field inventory over
the template vault and both German production vaults: **no file carries
an undeclared frontmatter key** — the single candidate, PMDE's
`IMP_Host_Website_Beispiel.md`, carries `excalidraw-plugin` and `tags`,
both of which an editor-field allowlist covers. An undeclared-field
check therefore costs all three vaults zero findings, which puts it in
the bug-fix class rather than the convention-rollout class that
follow-up 4 of the 2026-07-28 amendment ([[DEC_Language_Independent_Recognition_And_VCS_Tier]]) exists to keep separate.

Second, and unrelated to the issue but on the exact code path it
rewrites: a list-valued scalar field crashes the validator.
`fm["status"] not in GENERIC_STATUS` hashes its left operand, and
`parse_frontmatter` returns a list for `status: [active]`. Measured on a
seeded fixture, all three entry points exit 2 — and both hooks swallow
exit 2, so one such file switches the entire enforcement layer off
silently. It is fixed first, as its own change.

## Options

**Where the schema lives and who may override it.**

- **A1 — packaged schema plus a per-project override at
  `00_documentation/vault_schema.json`,** as `discovery` in the schema
  declared and left unimplemented. Rejected on two independent grounds.
  It is a silent off-switch for the blocking gate: the ERRORs that reach
  the stop gate's blocking set come from `check_frontmatter`,
  `check_dec_status` and `check_req_table`, which are precisely the three
  this change makes schema-driven, so a two-line override flipping an
  `enforced` flag to `declared-only` disables a blocking check from a file
  that is not even committed — the same class as `status: draft` relaxing
  a rule, which this project rejected outright. And it would not work
  where it was meant to: `Vault.doc_root` is the vault's parent, but both
  German vaults *are* their own git repository, so the override path lies
  outside version control and would not sync between the two machines
  that push homelab.
- **A2 — one packaged schema, read-only, no override (chosen).** Every
  vault is checked against the schema shipped with the validator that
  checks it. A project needing different rules forks the skill, which is
  visible in a diff.

**Severity of an undeclared field.**

- **B1 — ERROR,** as StrictDoc does: an unregistered field raises
  `unregistered_field` and exits 1, with no permissive mode. Rejected.
  StrictDoc's grammar ships inside the document and its primary author is
  a round-trip editor; here the file is hand-written in Obsidian and the
  schema ships with the tool, so the two can drift.
- **B2 — WARN (chosen).** The check cannot distinguish a typo from an
  intention, which is exactly Clippy's disqualification criterion for its
  deny-by-default `correctness` group — reserved for lints "free of false
  positives", while anything that "might be ... intentionally written like
  it is" belongs to warn-level `suspicious` — and Google Tricorder's bar
  for a build-blocking check ("produce no effective false positives").
  PMDE's Excalidraw file is the empirical case: a plugin's own field, not
  a defect. Sphinx-Needs reaches the same place from the other side, where
  `unevaluatedProperties: false` is opt-in and motivated verbatim by
  "catching typos in property names"; SchemaStore advises against closing
  human-authored schemas at all, and Cargo warns rather than fails on an
  unknown manifest key.

**Which rules move into the schema.**

- **C1 — everything the schema describes,** including `ID_RE`,
  `REQ_ID_RE` and `ID_EXCLUDED_DOMAINS`. Rejected: `frontmatter_id()` and
  `head_identifiers()` resolve identity in module-level functions that run
  without a schema in hand, and identity resolution decides which values
  are compared against git HEAD. Drift is instead caught by a test
  asserting the Python constants and the schema's declared patterns accept
  and reject the same samples.
- **C2 — the field vocabulary and the enumerations (chosen):** required
  keys, permitted `status` values, the DEC body `Status` values, the REQ
  class values, and the declared-field vocabulary the new check reads.

**Domains the schema does not name.** The dispatch key is the folder
abbreviation, and the German vaults spell it `ANF`, `ENT`, `KMP`, `SST`,
`TUE`, `BUN` — none of which appears in `domains`. Reading only
`domains[abbr]` would leave 220 of homelab's 248 domain files unchecked,
or, if absence meant "nothing is declared", report every field of every
one of them. Chosen: a `domain_defaults` block that declares the
vault-wide vocabulary and applies to every domain, with per-domain
entries merging into it attribute by attribute. This reproduces today's
behaviour exactly, including that `DEC` alone is exempt from `status`.

## Decision

Option A2, B2, C2, with `domain_defaults` as the fallback profile for
unnamed domains. The `enforced` flag stops being a comment and becomes
the switch: `schema-driven` means the validator reads this entry from
here, `validator-internal` means the rule stays in Python for a stated
reason, `declared-only` means nothing enforces it. `id` stays
`declared-only`, so the identifier pattern remains unenforced on values
and an unfilled `ARC-DOM-NNN` placeholder still produces no finding.

`verifies` is declared vault-wide but enforced only in `TAE`. homelab's
37 `TUE` files carry it as an empty list; enforcing the rule globally
would add 37 `verifies-empty` warnings to a vault that never had the
convention, which is the language-fix-plus-convention-rollout mixture
that follow-up 4 was split off to avoid.

The relation `superseded-by` is added, closing a gap between the issue
text and the schema. Direction matters: the link is authored in the
*superseded* decision as `Superseded by: [[DEC_...]]`, so the subject is
the old decision, and naming it `supersedes` would reverse the arrow
against the other seven kinds, which are all authored subject-first.

## Justification

### Design points

- **The undeclared check also runs on `00_` templates, for vocabulary
  only.** A template is the file every new file is copied from, so an
  undeclared key there propagates silently into everything derived from
  it. Its *values* stay unchecked, because they are placeholders by
  design (`created: YYYY-MM-DD`, `id: ARC-DOM-NNN`). Measured cost of
  extending it this way: zero findings on all three vaults.
- **One grouped finding per file, not one per key.** A file with five
  stray keys must not produce five lines — the lesson of the aggregated
  link feedback in amendment 2026-07-27 ([[DEC_E2E_Test_Driven_Hardening]]), where dozens of identical WARNs
  taught the reader to ignore the channel.
- **Every schema access is type-checked at the access, not once at
  load.** `check_dec_status` and `check_req_table` read nested keys; a
  schema declaring `"body_fields": 5` would otherwise reach a subscript
  on an int, raise `TypeError` and exit 2. Two accessors (`_dict`,
  `_strlist`) return an empty container for anything unexpected, so the
  worst a malformed schema can do is fall back.
- **`RecursionError`, not only `ValueError`.** Deeply nested JSON raises
  the former out of `json.loads`, and an `except (OSError, ValueError)`
  would not catch it — again exit 2, again both hooks failing open.
- **The fallback is minimal on purpose.** It is not a second copy of the
  schema; it is the answer to "check nothing or check the essentials",
  and it exists because validating nothing silently is the failure mode
  amendment 2026-07-28 was written about. A test asserts it agrees with
  the shipped schema on what is required and permitted.
- **A test forbids domain-exclusive fields.** The undeclared check is
  language-symmetric only while every named domain resolves to the same
  vocabulary as an unnamed one. Introducing a field that exists for `TAE`
  but not for a German `TUE` has to break that test first.

## Consequences

### Accepted residuals (documented, not solved)

1. **The relations are still declared and not read.** All eight kinds
   stay `declared-only`, `table_bindings` is unread, and no graph is
   built — so the query issue #4 opens with ("which decisions are
   superseded but still referenced from an active module") remains
   unanswerable. This is the boundary with issue #2, which says in its
   own text that without typed relations there is nothing to export: #4
   declares them, #2 reads them. The two consistency rules that need a
   parsed allocation table were reassigned to #2 accordingly.
2. **The table header signatures remain language-dependent and
   unverified**, as residuals 3 and 4 of amendment 2026-07-28b ([[DEC_Object_Identity_And_Typed_Relations]]) describe.
   A rule asserting that a vault's own tables still match the declared
   signature was considered here and deferred: while nothing extracts
   relations, such a rule would report that an extraction failed which
   does not exist, and on a vault in another language it would fire on
   every ARC file for being correctly written in that language.
3. **Obsidian's own block-sequence frontmatter is an ERROR.** The
   properties UI writes `tags:` followed by `  - hardware`, which
   `parse_frontmatter` rejects as malformed — so the editor-field
   tolerance introduced here covers only the inline spelling
   `tags: [hardware]`. Measured today: zero occurrences and zero
   malformed frontmatter across all three vaults, which is why it is a
   follow-up rather than a blocker. It is a latent trap, not a current
   defect.
4. **The check cannot see the files that need it most.** It runs only on
   well-formed, present frontmatter, so 231 of PMDE's 232 domain files
   are excluded by construction. They already report
   `frontmatter-missing`, so nothing is lost — but "zero undeclared
   findings on PMDE" is partly an artefact of that vault having almost
   no frontmatter at all.
5. **The identifier patterns are declared in the schema and enforced
   from Python.** A drift test compares them on a sample set, which
   catches divergence but does not prevent it.
6. **One schema for every vault.** A project needing different rules
   forks the skill. This is deliberate (see the rejected override), but
   it does mean the language residual the override was meant to address
   stays open.

### Follow-ups

7. Accept YAML block sequences in `parse_frontmatter`, closing residual 3.
   It is a parser change with its own blast radius — some files currently
   reported as malformed would start parsing — and belongs in its own
   change with its own measurement.
8. Reconsider requiring `id`, and merging the file and row identifier
   namespaces (residual 1 of amendment 2026-07-28c ([[DEC_Identifier_Enforcement]])), once the vaults that
   predate the scheme have been migrated. Both are convention rollouts and
   must not ride along with a bug fix.

### Realization

- `validate_vault.py` — `SCHEMA_PATH`, `FALLBACK_SCHEMA`, `load_schema()`,
  `_dict()`/`_strlist()`, `Vault.schema()`/`fields_for()`/`editor_fields()`;
  `check_frontmatter()` rewritten schema-driven and split into
  `check_field_value()` and the new `check_undeclared()`;
  `check_dec_status()` and `check_req_table()` take the vault and read
  their value lists from the schema; `GENERIC_STATUS` and
  `DEC_BODY_STATUS` deleted, since the schema and the fallback now carry
  them
- `vault_schema.json` — schema 0.2: `enforcement_levels`,
  `domain_defaults`, `editor_fields`, the `superseded-by` relation, the
  `declared-fields-only` consistency rule, a rewritten `discovery` that
  records why the per-project override is not implemented, and per-entry
  reasons on every remaining `validator-internal` flag
- `tests/run.sh` — now 88 assertions. A fifth fixture exercises the schema
  itself by copying the validator next to a different schema file: an
  unreadable one (must WARN, must fall back, must not exit 2), one that
  declares the stray key (the finding disappears and the new value list is
  enforced, with byte-identical Python — the A/B proof of the whole
  change), and one that parses but declares nonsense (must not crash).
  Plus editor fields seeded in the precision fixture, which stays at zero
  findings; two stray keys and a template-borne one in the violation
  fixture; a stray key in both twins; and three drift guards (schema vs
  identifier constants, schema vs fallback, vocabulary symmetry)
- `SKILL.md` and `00_documentation_file_creation_and_conventions.md` — the
  schema as the place a field is declared, and the undeclared-field check

Measured after the change: the finding sets of the old and the new
validator are **byte-identical** on the template vault, homelab and PMDE,
compared against the same content at the same moment. Counts alone would
have been misleading here: homelab is a live vault under active work and
moved from 218/115 to 197/113 during this session without any validator
change, so the set comparison rather than the number is the evidence.
Template stays 0 errors / 9 warnings. Zero `frontmatter-undeclared`
findings on all three vaults, templates included. Full-audit runtime
0.08 → 0.08 s (template), 0.30 → 0.31 s (homelab), 0.22 → 0.21 s (PMDE).
`tests/run.sh` at 88 tests, 0 failures.

A note for whoever deploys this: the stop gate's per-session baseline in
`/tmp/claude-mechdocs` is keyed by finding code. No existing code was
renamed, and every code added here is a WARN, so the blocking set is
untouched and a stale baseline from before this change stays valid.
