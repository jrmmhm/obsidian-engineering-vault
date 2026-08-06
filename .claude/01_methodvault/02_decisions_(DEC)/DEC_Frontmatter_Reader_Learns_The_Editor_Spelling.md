---
domain: DEC
id: DEC-MTH-013
created: 2026-08-01
last-verified: 2026-08-05
---
Date: 2026-08-01
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-01c — The frontmatter reader learns the spelling the editor writes (Accepted)". The source record opens without headings; its opening paragraphs are placed under the template's sections unchanged and unsplit.
Migration note: "this document" in the Context below is the appended decision log this vault replaces; the claim it makes is about the records migrated from it, not about this file.

## Context

`parse_frontmatter` matched every frontmatter line against `key: value`
and reported anything else as `frontmatter-malformed` — an ERROR in the
stop gate's blocking set. A YAML block sequence has no key on its item
lines, so the spelling Obsidian's own properties editor produces was
rejected:

```
tags:
- hardware
```

`editor_fields` had tolerated `tags`, `aliases` and `cssclasses` in the
vocabulary since amendment 2026-07-28d ([[DEC_Schema_Driven_Field_Validation]]) while the parser rejected the form
the editor writes them in. That contradiction was recorded there as
residual 3 and deferred as follow-up 7, on the measured grounds that no
file anywhere carried the form. Both spellings now fold into one list.

**The measurement that deferred it was scoped wrongly, and the defect was
never latent.** Vaults had been enumerated by folder name
(`01_projectvault`, `01_Projektvault`); the validator defines a vault
through `is_vault_root`. Enumerating by the validator's own definition
finds **nine** vault roots on this machine, not seven —
`homelab/20_Software/userver-nativclaw/docs` and
`Documents/mind/Archiv/Bachelor_Bruder/00_Vault` were never measured. The
first of them holds fifteen files whose `related:` is a block sequence,
eleven of them domain files reporting `frontmatter-malformed` today. Every
"measured across all seven vaults" in this document is a claim about seven
of nine, and issue #24's own zero-occurrence finding inherits the same
error. The rule this leaves behind: a measurement over a population is
only as good as the predicate that enumerates it, and the predicate that
counts is the one the code uses.

What the eleven files gain is the point of the change. One
`frontmatter-malformed` is replaced by 37 `frontmatter-key`, 7
`frontmatter-status` and 11 grouped `frontmatter-undeclared` findings —
all true, all previously masked. The files carry no `domain`, no `created`
and no `last-verified`, and spell `status: Accepted`, which is not in the
vocabulary. A single parse failure had been standing in for five real
defects, which is the same shape as amendment 2026-08-01 ([[DEC_One_Fence_Definition_For_Both_Tools]])'s stop-gate blind
spot: a check that reports something is not the same as a check that
reports the truth.

## Options

_The source record carries no section under this title; where it weighs a
rejected variant it does so inside the design points below — issue #24's
literal wording for indented items, and the YAML library it does not take._

## Decision

_The source record carries no section under this title; it states its
choice in the opening account above — "Both spellings now fold into one
list."_

## Justification

### Design points

- **Items are accepted with or without indentation.** YAML 1.2 §8.2.1
  permits a block sequence at the indentation of its parent mapping key,
  and the Obsidian documentation writes it flush left. Issue #24 asked
  for "indented `- item` lines"; implementing that literally would have
  left the editor's own documented output rejected, which is the defect
  the issue was filed about.
- **The closing `---` is located before anything is parsed.** The reader
  used to stop at the first line it could not read, which put `end_line`
  wherever the parse happened to fail. With block sequences accepted, a
  file missing its closing marker would swallow the body's bullet lists
  into a value and push `end_line` to EOF — which is precisely where
  `check_leaks` and `check_paths` stop looking. Reproduced before the fix:
  a `path-missing` ERROR disappeared and `stub` fired on a full file. Such
  a file is now reported *and* handed `end_line` 0, so it is read as if it
  carried no frontmatter at all and the body checks still run. That is
  `req_rows`' rule for an unclosed fence, one layer up: one stray marker
  must not switch a check off.
- **One spelling more, not one rule less.** A tab anywhere in an item line
  (YAML forbids tab indentation, and `line.strip()` would hide it), a
  nested mapping inside an item (`- key: value`), an item indented
  differently from the first item of its sequence, an indented key line,
  and a sequence item belonging to no key all stay malformed. The
  indentation rule is stricter than PyYAML, which reads `- a` followed by
  a deeper `- b` as the single scalar `a - b`; being stricter than the
  reference implementation is honest where agreeing with it is not cheap.
  `- foo:bar` carries no space after the colon, is a plain scalar in YAML
  too, and stays one here.
- **A key with nothing under it keeps the empty string it always had.**
  `verifies:` alone still parses as `""`, not `[]`. The parser holds no
  schema and cannot know which keys are list-valued; `[]` would be wrong
  for `status:` and would newly fire `verifies-empty` on files nobody
  touched.
- **No YAML library.** The validator is stdlib-only, which the CI workflow
  states as the reason it needs no dependency step. Measured before
  deciding: the hand-written reader and PyYAML 6.0.3 agree on all 283
  frontmatter blocks in the corpus, so the reader is not the problem. The
  library would bring problems of its own — 540 date values would become
  `datetime.date` objects, `NO` and `yes` would become booleans (YAML 1.1,
  the Norway problem), and `created: 2026-13-45` raises `ValueError`,
  which does **not** inherit from `yaml.YAMLError` and would exit 2, which
  both hooks swallow. An optional import would be worse still: two parsers
  judging differently on different machines is the drift this project has
  refused three times already.

## Consequences

### Accepted residuals (documented, not solved)

1. **A trailing comment is part of the value.** `tags: # note` parses as
   the string `"# note"` and its items then belong to no key. This is not
   new — `status: active # temp` has always parsed as `active # temp` —
   and it is uniform across every line, but it means a comment above a
   working block list turns it into an ERROR.
2. **A bare `verifies:` still reports nothing.** `check_field_value` sees
   `""`, `isinstance("", list)` is false, and it returns. The honest home
   for that is the type-aware check, not the parser, and it is a finding
   rollout of its own.
3. **`-` with no value yields `[]`, where YAML yields `[None]`.** For a
   required list this makes `verifies-empty` fire, which is the right
   answer for the wrong reason.
4. **The nine-vault correction is not automated.** Nothing stops the next
   measurement from enumerating by folder name again.

### Realization

- `validate_vault.py` — `parse_frontmatter` rewritten around a located
  closing marker and one open-key state; `SEQ_ITEM_RE` and
  `SEQ_NESTED_RE` added
- `tests/run.sh` — the two spellings asserted equal at the parser, the
  unindented form seeded in the precision fixture that must stay at zero
  findings, `verifies` respelled as a block sequence in the violation
  fixture with an assertion that the finding names `REQ-XXX-999`, and
  nine negative controls plus the `end_line` 0 assertion; 156 to 159
  assertions
- `00_documentation_file_creation_and_conventions.md` — both list
  spellings named as equivalent

Measured after the change, all **nine** vault roots on this machine, old
code and new code against one disk state at the same moment, as finding
sets rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| template | 0 | 9 | 0 | 0 |
| homelab | 11 | 115 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 503 | 233 | 11 | 55 |
| PMDE | 398 | 102 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |
| Archiv/Bachelor_Bruder | 68 | 32 | 0 | 0 |

Eight of nine are byte-identical. The ninth is the vault the change was
written for, and its diff is the mask lifting: eleven parse failures out,
fifty-five true findings in. The template vault stays at 0 errors and 9
warnings, and `tests/run.sh` runs 159 assertions with 0 failures. All four
new parser assertions were verified to fail against the previous
`parse_frontmatter`, so the suite can still tell the two apart.

A note for whoever deploys this: no finding code was renamed and no code
was added to the blocking set, so a stale per-session baseline in
`/tmp/claude-mechdocs` stays valid. A full audit of
`homelab/20_Software/userver-nativclaw/docs` will report 44 more ERRORs
than before — all of them pre-existing and previously hidden behind the
parse failure, none of them introduced here.
