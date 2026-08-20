# validate_vault.py — architecture

For whoever changes the validator. It says **where** a check lives: which
function owns it, whether it runs per file or across the vault, and which
findings can block a turn.

Two other documents answer the neighbouring questions, and this one repeats
neither. **What a rule is**, for the author who just met a finding, is the
quick-reference table in a project vault's
`00_documentation_file_creation_and_conventions.md`. **Why a rule exists** is
one note per decision in the method vault, starting at its
`system_overview.md`. **How to work inside the rules** is `SKILL.md` beside
this file.

No line numbers anywhere: they decay on the next edit, which is the rot this
file exists to prevent. Names are stable, so names are what it cites.

---

## Entry points

`main` parses the arguments and dispatches. Everything below hangs off one of
these five.

| Invocation | Handler | Per-file | Vault-wide | `strict_links` |
| --- | --- | --- | --- | --- |
| `validate_vault.py <root>` | `run_full` | every `.md` under the root | yes | `True` |
| `--file <path>` | `main` → `validate_file` | that one file | no | `False` |
| `--hook post` | `hook_post` | that one file | no | see below |
| `--hook stop` | `hook_stop` | every file touched this session | yes, advisory | `True` |
| `--check-install` | `check_install` | — | — | — |

`--check-install` is the odd one out: it answers whether the personal
`~/.claude/skills/` entry reaches *this* copy of the skill, reads no vault and
emits no finding at all. It also prints `SKILL_REVISION`, the module-level
constant that names this copy. That constant exists because the copies that
can disagree cannot be compared by content: a derived project ships the
skill without `tests/` on purpose (`tools/new_project.py`), so equal
directories are not the criterion — an equal revision is. The hooks resolve
through `CLAUDE_PLUGIN_ROOT` and therefore always run the loaded copy
(DEC-MTH-045); the CI and the pre-commit hook run the vendored one, and the
revision line is how a disagreement between the two becomes visible.

`--hook post` runs `validate_file` **twice with different values**. The git
HEAD baseline is captured with `strict_links=True`, the live pass runs with
`strict_links=False`. That asymmetry is deliberate: the baseline has to be
counted under the same rule the stop gate will later apply, or the
`link-unresolved` counts on the two sides are not comparable.

Exit codes: `0` no ERROR, `1` at least one ERROR, `2` crash. Both hooks fail
**open** on `2` — a validator that cannot run must not wedge a session, which
is also why nearly every helper here is written never to raise.

---

## Stage 1 — classification and decoding

`Vault.classify` maps a path to one of six kinds, and that kind decides which
checks run at all:

`outside` and `skip` (not under the root, or under `.obsidian`/`.git`) ·
`root` (a file directly in the vault root) · `infra` (a `00_*` README or
template) · `inbox` (anything under the `INB` domain) · `domain` (an ordinary
note in a domain folder).

`decode_source` is the single place bytes become vault content. It names an
encoding only when a byte-order mark proves it, and otherwise reports that the
bytes are not UTF-8 without guessing which encoding they are.

Two findings are emitted before any kind branch, so they reach every file that
is read at all — templates included: `encoding-not-utf8`, and
`schema-unreadable`, which is reported once per vault and never on a HEAD
baseline pass.

---

## Stage 2 — per-file checks

`validate_file` is the dispatcher. What runs depends on the kind:

| Kind | Checks |
| --- | --- |
| `outside`, `skip` | none — returns immediately |
| `inbox` | `check_links`, then `check_inb_age` (disk pass only) |
| `root` | `check_links` only, never strict, hub budget for `system_overview.md` |
| `infra` | frontmatter vocabulary via `check_undeclared`, `template-unreadable` for an unparseable template, then `check_links` |
| `domain` | the full chain below |

The domain chain, in the order it executes:

| # | Function | Emits | Severity rule |
| --- | --- | --- | --- |
| 1 | `validate_file` | `filename-prefix` | ERROR |
| 2 | `parse_frontmatter` | `frontmatter-malformed`, `frontmatter-missing` | ERROR |
| 3 | `check_frontmatter` | `frontmatter-key` | ERROR; only fields marked `schema-driven` are enforced |
| 3a | `check_field_value` | the schema-declared codes | the code comes from the field descriptor, not from Python |
| 3b | `check_undeclared` | `frontmatter-undeclared` | WARN, one grouped finding per file |
| 4 | `check_sections` | `template-sections`, `section-mismatch`, `section-near-miss` | ERROR, ERROR, WARN |
| 5 | `check_length` | `length`, `structure` | `length` is ERROR above the hard limit, WARN above the soft one |
| 6 | `check_links` | `link-unresolved`, `link-budget`, `link-repeat` | `link-unresolved` is ERROR when `strict_links`, WARN otherwise |
| 7 | `check_leaks` | `impl-leak` | ERROR in ARC, WARN in a DEC Context section; no other domain is scanned, and a References/Sources section (`REF_SECTION_TOKENS`, English and German spellings) is exempt |
| 7a | `check_fence` | `code-fence`, `fence-host`, `fence-record` | only in the banned domains; a declared over-long block is WARN, an undeclared one ERROR |
| 8 | `check_paths` | `path-missing` | ERROR under a References or Sources heading (`REF_SECTION_TOKENS` — `Referenzen`, `Verweise` and `Quelle(n)` open the zone too), WARN in the rest of the body |
| 9 | `check_req_table` | `req-class`, `req-nnn`, `req-duplicate`, `req-criterion` | all ERROR; triggered on the literal `REQ` folder |
| 9a | `check_req_table_silence` | `req-table-unrecognized` | WARN |
| 10 | `check_tae_verifies` | `verifies-unknown-req` | ERROR; triggered through the **role map**, so a translated evidence domain is covered |
| 11 | `check_dec_status` | `dec-status`, `dec-superseded` | ERROR |
| 12 | `validate_file` | `stub` | WARN |

Note the asymmetry at steps 9 and 10. The requirement-row checks stay on the
literal `REQ` folder while the evidence check follows the role map. That is
deliberate, not an oversight: extending four blocking row-grammar codes to
translated vaults is a convention rollout, not a fix.

---

## Stage 3 — vault-wide checks

`validate_vault_wide` runs these in order, and the order matters at the top:

1. `check_domain_folders` → `domain-duplicate-folder`. **First on purpose** —
   it survives the stop report's line cap, and it is the explanation for the
   `duplicate-basename` and `orphan` findings a second domain folder produces
   around it.
2. the global requirement-id scan, inline → `req-duplicate-global`
3. `check_identifiers`, with `head_identifiers` reading git HEAD →
   `id-duplicate`, `id-scope-mismatch`, `id-vanished`
4. the coverage rule, inline, fed by `Vault.req_index`, `evidence_index` and
   `allocation_index` → `req-uncovered`
5. the overview scan, inline → `arc-not-in-overview`
6. the orphan scan, inline → `orphan`
7. the basename scan, inline → `duplicate-basename`

`allocation_index` is the one that reaches outside this file: it imports the
exporter and reads the allocation half of the coverage rule off the graph. It
returns `None` — a third answer, distinct from "not allocated" — whenever the
graph cannot see a requirement, so a closed loop is never reported as a gap.

---

## What actually blocks

Three separate mechanisms, and conflating them is the usual mistake.

**The per-file ratchet.** `hook_stop` compares each touched file's current
ERROR codes against the same file's codes at git HEAD. Only a count that went
*up* blocks. A pre-existing ERROR is reported and never blocks, so a session
is never held responsible for legacy state it did not create.

**Vault-wide findings never block.** They have no per-file HEAD baseline, so
they cannot enter the ratchet at all. `hook_stop` renders them into an
advisory block in the session report. The full audit is the pass that counts.

**`strict_links` decides one code's severity.** `link-unresolved` is an ERROR
in the full audit and at the stop gate, a WARN under `--file` and in the live
half of the post hook. Forward references mid-pass are expected under the
phased creation order; by turn end every target must exist.

A gate that crashes releases. `hook_stop` wraps the vault-wide block in its
own `try`, because an exception there would exit `2` and release the gate over
an advisory.

---

## What the two tools share

`export_traceability.py` imports twelve names from this module: `Vault`,
`_dict`, `_strlist`, `fold_key`, `is_separator`, `is_vault_root`,
`load_schema`, `parse_frontmatter`, `req_tables`, `resolve_role_map`,
`split_cells` and `template_files`. One definition each, so the two tools
cannot disagree about what a vault is, which folder holds which role, what a
table cell is, or how many requirement rows a file has.

The fence pattern is the exception: the exporter carries its own `FENCE_RE`
rather than importing one, and the two are held identical by an assertion in
`tests/run.sh` instead of by sharing an object. `req_tables`, which *is*
imported, calls this module's `fence_blocks` internally — so fence *behaviour*
is shared through it even though the constant is duplicated.

---

## The finding codes

Every code the validator can emit. Severity is the value it carries where the
rule is unconditional, and the condition where it is not. Codes marked
*schema-declared* come from `vault_schema.json` rather than from a literal in
Python, which is why a grep of the source alone does not find them.

<!-- finding-codes:begin -->

| Code | Owner | Scope | Severity |
| --- | --- | --- | --- |
| `arc-not-in-overview` | `validate_vault_wide` | vault-wide | WARN |
| `code-fence` | `check_fence` | domain, banned domains only | ERROR |
| `dec-status` | `check_dec_status`, `check_field_value` | domain, DEC | ERROR, schema-declared |
| `dec-superseded` | `check_dec_status` | domain, DEC | ERROR |
| `domain-duplicate-folder` | `check_domain_folders` | vault-wide | WARN |
| `duplicate-basename` | `validate_vault_wide` | vault-wide | WARN |
| `encoding-not-utf8` | `validate_file` | every file read | ERROR |
| `fence-host` | `check_fence` | domain, exempt domains only | ERROR |
| `fence-record` | `check_fence` | domain, exempt domains only | WARN |
| `filename-prefix` | `validate_file` | domain | ERROR |
| `frontmatter-date` | `check_field_value` | domain | ERROR, schema-declared |
| `frontmatter-domain` | `check_field_value` | domain | ERROR, schema-declared |
| `frontmatter-key` | `check_frontmatter` | domain | ERROR |
| `frontmatter-malformed` | `validate_file` | domain | ERROR |
| `frontmatter-missing` | `validate_file` | domain | ERROR |
| `frontmatter-status` | `check_field_value` | domain | ERROR, schema-declared |
| `frontmatter-undeclared` | `check_undeclared` | domain and infra | WARN |
| `frontmatter-value` | `check_field_value` | domain | ERROR; the fallback when a descriptor declares no code — unreachable with the packaged schema, where every enforced field declares one |
| `id-duplicate` | `check_identifiers` | vault-wide | ERROR |
| `id-scope-mismatch` | `check_identifiers` | vault-wide | WARN |
| `id-vanished` | `check_identifiers` | vault-wide | WARN |
| `impl-leak` | `check_leaks` | domain, ARC and DEC only | ERROR in ARC, WARN in DEC |
| `inb-age` | `check_inb_age` | inbox, disk pass only | WARN |
| `length` | `check_length` | domain | ERROR above the hard limit, WARN above the soft one |
| `link-budget` | `check_links` | every file read | WARN |
| `link-repeat` | `check_links` | every file read | WARN |
| `link-unresolved` | `check_links` | every file read | ERROR when `strict_links`, WARN otherwise |
| `orphan` | `validate_vault_wide` | vault-wide | WARN |
| `path-missing` | `check_paths` | domain | ERROR in a References or Sources section (English or German spelling, `REF_SECTION_TOKENS`), WARN elsewhere |
| `req-class` | `check_req_table` | domain, REQ | ERROR |
| `req-criterion` | `check_req_table` | domain, REQ | ERROR |
| `req-duplicate` | `check_req_table` | domain, REQ | ERROR |
| `req-duplicate-global` | `validate_vault_wide` | vault-wide | ERROR |
| `req-nnn` | `check_req_table` | domain, REQ | ERROR |
| `req-table-unrecognized` | `check_req_table_silence` | domain, REQ | WARN |
| `req-uncovered` | `validate_vault_wide` | vault-wide | WARN |
| `schema-unreadable` | `validate_file` | once per vault | WARN |
| `section-mismatch` | `check_sections` | domain | ERROR |
| `section-near-miss` | `check_sections` | domain | WARN |
| `structure` | `check_length` | domain | WARN |
| `stub` | `validate_file` | domain | WARN |
| `template-sections` | `check_sections` | domain | ERROR |
| `template-unreadable` | `validate_file` | infra, templates only | ERROR |
| `test-object-format` | `check_field_value` | domain | ERROR, schema-declared |
| `verifies-empty` | `check_field_value` | domain, evidence role | WARN, schema-declared |
| `verifies-format` | `check_field_value` | domain, evidence role | ERROR, schema-declared |
| `verifies-unknown-req` | `check_tae_verifies` | domain, evidence role | ERROR |

<!-- finding-codes:end -->

---

## Keeping this file true

The table above is checked by the test suite, in both directions: a code the
validator can emit but the table does not name fails the suite, and so does a
code the table names that the validator can no longer emit. The check reads
the codes out of `validate_vault.py` and `vault_schema.json` directly, so it
cannot be satisfied by editing it in isolation.

**Adding a finding code:** add the row. The suite tells you if you forget, and
it names the code. The check reads the first column of the table between the
two `finding-codes` markers, so the row has to be a table row and the code has
to be in backticks — and the markers have to stay.

The check follows four declaration sites: a literal in a `Finding` call; the
fallback string when the code comes from a schema descriptor; a `code` or
`empty_code` value in a dict, which covers the built-in fallback schema; and
the same keys in `vault_schema.json`, including a `codes` object that names
its codes as keys. Declare one a fifth way and the check fails loudly, naming
the line it could not follow, rather than passing in silence.

Everything else here — the entry points, the two stage tables, the blocking
rules — is prose that no test stands behind. It was derived by reading the
source and it is only as current as the last person who checked it.

**In a project derived from this template**, `tests/run.sh` and `tools/` are
stripped, so this file arrives without the check that keeps its table honest.
It still describes the validator you kept, and the template repository is
where its guard lives.
