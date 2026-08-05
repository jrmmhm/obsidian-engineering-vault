---
domain: DEC
id: DEC-MTH-012
created: 2026-08-01
last-verified: 2026-08-05
---
Date: 2026-08-01
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-01b — One cell splitter for both tools (Accepted)".

## Context

Issue #22. `parse_table_row` divided a row with `s[1:-1].split("|")`,
which the GFM tables extension explicitly rules out: "Include a pipe in a
cell's content by escaping it, including inside other inline spans." An
escaped pipe therefore shifted every column behind it, and the shape that
produces one is not exotic — Obsidian's own documentation requires it for
an aliased wikilink inside a table ("If you want to use aliases, or to
resize an image in your table, you need to add a `\` before the vertical
bar").

Reproduced on a REQ row whose content cell carries `value a \| b` and
whose acceptance criterion is empty: the split moved the next column into
the criterion, the criterion was never empty, and `req-criterion` — a
code in the stop gate's blocking set — did not fire. The same file after
the change reports it.

Measured across all seven vaults on this machine (729 Markdown files):
58 rows change their cell division, spread over two vaults and five
domain folders (homelab TUE 26, BUN 26, IMP 4, ADM 1, PMDE IMP 1). None
of them is in a REQ or an ARC file, so no positional reader touches one
today — 58 rows carry an escaped pipe inside a code span and 0 carry an
unescaped one, which is why the defect has stayed latent.

This is the other half of the design point in amendment 2026-07-31b, "the
exporter carries its own parsing primitives … fixing them is a change to
the blocking layer with its own blast radius and belongs in its own
issue". This is that issue, and it supersedes that design point for the
cell splitter. Residual 3 of amendment 2026-08-01 — "the rule still lives
in two files" — closes here for the splitter and stays open for the fence.

## Options

**Where the one implementation lives.**

- **A — the exporter's splitter copied into the validator, both kept,
  drift caught by a corpus parity assertion.** The compromise the fence
  rule carries. Rejected: residual 3 of amendment 2026-08-01 already
  records that compromise as unfinished business, and a parity test that
  compares two copies still needs both copies to be maintained.
- **B — the exporter imports the primitive from the validator (chosen).**
  The direction amendment 2026-07-31b sanctions — the exporter imports
  from the validator and is never imported by it — and it is already how
  `Vault`, `parse_frontmatter` and `fold_key` are shared. Sharing is then
  asserted by identity rather than by comparison.

**What the splitter returns.**

- **C — cells with their escapes resolved**, which is issue #22's literal
  wording ("resolves `\|` and `\\` before dividing"). Rejected on
  measurement: every consumer that carries cell text forward already
  calls `unescape` on it — four call sites in `_alloc_row` alone — so
  resolving here would unescape twice.
- **D — cells verbatim (chosen).** Splitting is the primitive's job;
  resolving stays where the text is used.

**How much of the row rule is shared.**

- **E — the splitter alone, keeping the validator's stricter gate.** What
  the issue asks for. Rejected on measurement: GFM leaves the trailing
  pipe optional, so a row written without one was a requirement row for
  the exporter and not for the validator — the disagreement amendment
  2026-08-01 removed for fences, one layer further down.
- **F — splitter and row predicate (chosen).** Measured across all seven
  vaults: not one line is classified differently by the two predicates,
  so sharing one costs nothing today and leaves nothing to drift.

## Decision

B, D and F. `split_cells(line, ncols=None)` and `is_separator` live in
`validate_vault.py`; `parse_table_row` is a gate over them and the
exporter imports both. `bound_tables` passes its column count instead of
padding and truncating by hand.

## Justification

### Design points

- **Both halves of the sentence, in both directions.** An escaped pipe
  must not divide even inside a code span, and an unescaped one must
  divide even inside a code span. A splitter that merely skipped
  backticks would satisfy every example in the spec's escaped column and
  fail the unescaped one; both directions are asserted.
- **The closing delimiter is recognised, not cut off.** `s.endswith("|")`
  is a raw-text test and is also true of a row ending in a deliberate
  `\|`. Stripping it first deleted the author's pipe and left a stray
  backslash that `unescape` cannot restore. The delimiter is now
  identified during the scan. Measured: 0 rows in the corpus end that
  way, and the exporter's output on every vault is unchanged.
- **The spec over the implementation, once.** `\\|` divides here: the
  backslash is itself escaped and no longer escapes the pipe. cmark-gfm,
  and therefore GitHub, renders it the other way — reported as
  github/cmark-gfm#277, unanswered and unfixed. Measured: 0 occurrences
  in seven vaults, so the choice is free; it is recorded because a later
  reader comparing against GitHub will otherwise think this is a bug.
- **Obsidian is the renderer, not GitHub.** The escape is not a
  GitHub-only convention this vault could ignore: obsidian.md documents
  `\|` as the pipe escape and requires it for aliased links and sized
  embeds inside tables.
- **Sharing is asserted by identity.** `validate_vault.split_cells is
  export_traceability.split_cells`, and the same for `is_separator`. A
  re-added local copy would satisfy every behavioural assertion in the
  suite and still be the defect this removes.
- **Measured before deciding, and measured again after.** The old and the
  new validator were run against one disk state at the same moment,
  because homelab drifts under Syncthing while a session runs: a baseline
  captured an hour earlier showed a phantom `link-budget` delta on
  `ARC_omarchy.md` that had nothing to do with this change.

## Consequences

### Accepted residuals (documented, not solved)

1. **A row whose only interior pipes are escaped is no longer a row.**
   It has one column, and two is the minimum both tools have always
   required. The data rows of GFM example 200 are exactly that shape, so
   the spec's own example is accepted by the splitter and refused by the
   row predicate. Measured: 0 such rows in seven vaults.
2. **A four-column REQ table containing an escaped pipe loses the
   coverage the defect gave it.** `check_req_table` skips a row shorter
   than five cells, and the mis-split used to inflate such a row to five,
   so `req-class` and `req-nnn` fired on a table that has never been
   canonical. The same table without an escaped pipe was unchecked before
   and after. This is the shape residual 1 of amendment 2026-08-01
   describes: an accident that covered one instance is gone. Measured: no
   REQ file in any of the seven vaults carries an escaped pipe.
3. **`unescape` stays in the exporter.** The validator has no consumer
   for it, and moving it now would be a helper kept in the file that owns
   the stop gate for a user that does not exist yet. Issue #23 needs it
   for wikilink targets and moves it together with that use.
4. **The fence rule still lives in two files.** Unifying it is not the
   same edit as unifying the splitter: `validate_vault.fence_mask` is
   1-based over `splitlines()` and `export_traceability.fenced_mask` is
   0-based over `split("\n")`, so one of the two signatures has to
   change. The corpus parity assertion keeps them honest until then.
5. **The two tools still read lines differently.** The exporter reads
   BOM-safe and splits on `\n` alone, the validator uses `splitlines()`,
   which also breaks on `\v`, `\f` and U+2028. One splitter therefore
   still does not mean one answer about what the rows of a file are.
   Measured: 0 files in seven vaults contain any of those characters, and
   the BOM half belongs to issue #21.

### Realization

- `validate_vault.py` — `split_cells` and `is_separator` added,
  `parse_table_row` reduced to the shared row predicate over them
- `export_traceability.py` — its local `split_cells` and `is_separator`
  removed and imported instead; `bound_tables` hands its column count to
  the splitter rather than padding and truncating by hand
- `tests/run.sh` — GFM examples 200 and 204 verbatim, both directions of
  the escape rule, the trailing escaped pipe, the escaped alias wikilink,
  a real homelab row whose code span holds a lone backslash before a
  delimiter, the two identity assertions, and a REQ file in the violation
  vault whose escaped pipe used to hide an empty acceptance criterion;
  153 to 156 assertions

Measured after the change, all seven vaults on this machine, old code and
new code against one disk state at the same moment, as finding sets
rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| homelab | 9 | 115 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| template | 0 | 9 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| PMDE | 398 | 102 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |

The exported graph is unchanged too: `traceability.json` is identical on
the template vault, on homelab and on PMDE apart from the provenance line
that records the output directory.

The template vault is unchanged at 0 errors and 9 warnings, and
`tests/run.sh` runs 156 assertions with 0 failures.
