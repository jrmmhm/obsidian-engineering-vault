---
domain: DEC
id: DEC-MTH-015
created: 2026-08-04
last-verified: 2026-08-05
---
Date: 2026-08-04
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-04 — One BOM-safe reader for every file the validator opens (Accepted)". The source record opens without headings; its opening paragraphs are placed under the template's sections unchanged and unsplit.

## Context

`parse_frontmatter` compares the first line of a file against `---`.
`read_lines` opened files as `utf-8`, so a byte-order mark made that
comparison fail and the reader returned `(None, 0, None)`: the third
element is the malformed-message slot, and it was empty. Nothing was
reported anywhere. `validate_file` then took the `fm is None` branch and
produced `frontmatter-missing` — an ERROR naming the wrong cause, on
frontmatter sitting visibly in the file — while `frontmatter_id`
returned `None` and dropped the file out of the identifier checks
without a word. A mark is never typed on purpose: it arrives from an
editor, a redirect or an export tool, and the resulting message points
away from the cause rather than at it.

`read_lines` was not the only reader. Four more open files, and each
fails differently:

- `validate_vault_wide` builds its corpus with its own read, and
  `check_identifiers` compares nothing else. Fixing `read_lines` alone
  would have removed the false ERROR and left the identifier hole
  exactly where it was.
- `Vault.templates_for` reads templates for their headings. `extract_h2`
  tests `startswith("## ")`, so a mark in front of a heading on line 1
  removes that heading from the required set of a whole domain, and
  `check_sections` returns early when a template yields nothing.
- `git_head_content` decoded with `text=True`, so the HEAD baseline and
  the working tree disagreed about the same file.
- `_read_schema` decodes `vault_schema.json`, and `json.loads` rejects a
  leading BOM outright. The schema drops to `FALLBACK_SCHEMA` behind a
  single WARN that `validate_file` suppresses on baseline passes:
  declared values and editor fields silently out of force.

Measured across all **nine** vault roots on this machine: 1091 files,
**zero** carrying a byte-order mark and zero that are not valid UTF-8.
Every one of these defects is latent, and the blast radius of the
correction is zero findings in either direction.

## Options

_The source record carries no section under this title; where it weighs a
rejected variant it does so inside the design points below — five
scattered encoding literals against one shared reader, and a new negative
assertion against a mark placed on a fixture that already asserts._

## Decision

_The source record carries no section under this title; it states what was
chosen inside the design points below, beginning with "One reader, not
five encoding literals"._

## Justification

### Design points

- **One reader, not five encoding literals.** `read_text` is what
  `read_lines`, the corpus and the template scan now share, and
  `git_head_content` and `_read_schema` carry the same rule where a
  `Path.read_text` is not what they call. The scattered literals are how
  the fifth site stayed unnoticed until an adversarial review went
  looking — the issue named two. What actually keeps a sixth site
  honest, though, is not the helper but the assertion: the reader-parity
  harness now compares `validate_vault.read_lines` against
  `export_traceability.read_lines` on every fixture file.
- **The exporter has been right since amendment 2026-07-31b.** Its
  `read_lines` docstring names this exact defect, and its design point
  "the exporter carries its own parsing primitives" listed the
  validator's BOM behaviour as a live, exported defect. That statement
  is now historical: both tools read a file the same way, and the
  harness that is supposed to keep them in step was blind to precisely
  this divergence until this change added the line for it.
- **Both halves ship in one commit, measured.** With only the HEAD
  reader fixed, the baseline of a marked file comes back clean while the
  working tree still reports `frontmatter-missing` — so the stop gate
  blocks the session on a file nobody touched, with a message naming the
  wrong cause. Reverting either half alone was run through both hooks
  before this was written.
- **The schema reader was taken along deliberately.** It is not in issue
  #21, it is the same defect class in one token, and its test costs no
  new assertion: fixture 5's declared-schema block is written with a
  mark, so the existing `'owner'` assertions became the control. Scope
  extensions are announced, not slipped in — this one was approved
  before it was written.
- **The tests are positive controls on assertions that already
  existed.** Four fixtures gained a mark rather than a new assertion:
  the violation vault's REQ template (the `'squad'` undeclared key), its
  IMP template (both IMP near-miss assertions), fixture 5's declared
  schema (`'owner'`), and a domain file whose twin claims the same
  identifier (`id-duplicate`). Each reverted reader fails at least one
  of them, and the mapping was measured rather than assumed. A mark on a
  fixture is cheaper than a new negative assertion and much harder to
  fool: a negative passes for any reason at all.
- **Every marked fixture carries a byte-level guard.** `head -c 3 | od`
  against `ef bb bf`, the idiom the CSV export's BOM assertion already
  uses. A fixture that silently loses its mark satisfies every assertion
  above while proving nothing, and nothing else in the suite would
  notice.
- **The template site is fixed for the class, not for a live defect.**
  All but one of the thirteen shipped templates begin with `---`, so
  `extract_h2` — which scans every line and only loses line 1 — would
  keep the full heading set for them. The plan claimed more than that
  and was corrected during review. The fix stays: a template is the one
  file a whole domain's section checks depend on, and "harmless today"
  is not a property of the reader.
- **Reviewed adversarially before implementation.** A fresh-context
  review produced fifteen findings; twelve were confirmed and changed
  the plan, three were refuted with the code. Two of the confirmed ones
  removed work rather than adding it: the direction of the
  `id-vanished` pair that passes against today's code as well (the file
  is in neither set, so it proves nothing), and a mark on
  `CMP_MCU_Board.md`, which already guards the editor-field tolerance
  and the block-sequence `aliases` of issue #24 through one
  zero-findings assertion.

## Consequences

### Accepted residuals (documented, not solved)

1. **A doubled mark still breaks it.** `utf-8-sig` strips exactly one,
   and Windows tools can write a second on re-save. The fix is one BOM
   deep; the second one produces the original defect unchanged.
2. **A file that is not UTF-8 at all is unchanged by this.** UTF-16 —
   what Windows PowerShell 5.1 writes for `Out-File`, `>` and `>>` —
   decodes to replacement characters and NUL-separated text under both
   readers, and still produces `frontmatter-missing` plus
   `template-sections` rather than a word about the encoding. A
   truncated mark (`ef bb`) is the same class. Filed as issue #31,
   which needs a new finding, not a reading option.
3. **The `splitlines()` half of residual 5 of amendment 2026-08-01b
   stays open.** That residual named two ways the two tools read lines
   differently; the BOM half is closed here. The validator still splits
   with `splitlines()`, which also breaks on `\v`, `\f` and U+2028,
   while the exporter splits on `\n` alone. Measured: 0 files in nine
   vaults contain any of those characters.
4. **A per-session baseline written before this change is milder than it
   should be.** A session that touched a marked file carries
   `{"frontmatter-missing": 1}` in `/tmp/claude-mechdocs`, so that code
   counts as pre-existing until the state expires after
   `STATE_MAX_AGE_S`. Harmless — it tolerates, it never blocks.

### Realization

- `validate_vault.py` — `read_text` added and used by `read_lines`,
  the corpus in `validate_vault_wide` and `Vault.templates_for`;
  `git_head_content` given `encoding="utf-8-sig"` in place of
  `text=True`; `_read_schema` decoding with `utf-8-sig`
- `tests/run.sh` — a reader probe asserting that a marked and an
  unmarked file yield identical lines and that a mark inside the text
  survives; marks on the REQ template, the IMP template, fixture 5's
  declared schema, a new domain file with an identifier twin, and a
  committed file in the identity fixture; a byte-level guard per marked
  fixture; the reader-parity line in the fence-mask harness;
  164 to 174 assertions
- no change to `00_documentation_file_creation_and_conventions.md`: a
  byte-order mark is not something an author writes, so there is no
  convention to state

Measured after the change, all **nine** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| template | 0 | 9 | 0 | 0 |
| homelab | 9 | 114 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 503 | 233 | 0 | 0 |
| PMDE | 398 | 102 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |
| Archiv/Bachelor_Bruder | 68 | 32 | 0 | 0 |

Nine of nine are byte-identical, which is the expected result for a
defect that no file on this machine carries. What proves the change
works is therefore the runtime check rather than the corpus: on a
throwaway vault holding a marked file and an unmarked twin claiming the
same identifier, the old code reports `frontmatter-missing` on the
marked file and stays silent about the collision, while the new code
reports `id-duplicate ARC-BOM-001 ... already declared in ARC_Bom.md`
and says nothing about missing frontmatter. Against a marked
`vault_schema.json` the old code reports `schema-unreadable` and falls
back; the new code reports nothing and keeps the schema in force. Run
through both hooks, the marked file produces one `stub` WARN and no
block.

A note for whoever deploys this: no finding code was renamed and no code
was added to the blocking set. A vault whose files carry no mark — every
vault measured here — sees no change at all.
