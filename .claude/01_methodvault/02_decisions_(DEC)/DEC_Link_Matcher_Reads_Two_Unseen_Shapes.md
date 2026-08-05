---
domain: DEC
id: DEC-MTH-014
created: 2026-08-01
last-verified: 2026-08-05
---
Date: 2026-08-01
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-01d — The link matcher reads the two shapes it never saw (Accepted)". The source record opens without headings; its opening paragraphs are placed under the template's sections unchanged and unsplit.

## Context

`WIKILINK_RE` demanded at least one character before an anchor and read
its target greedily. Two documented Obsidian shapes fell through that,
in opposite directions.

A link into the file itself — `[[#Heading]]`, `[[#^blockid]]`, both
spelled out on obsidian.md/help/links — matched nothing at all and was
invisible to `check_links`: not resolved, not counted, not reported. And
a link written the way Obsidian *requires* inside a table, with the alias
pipe escaped, was matched with the backslash glued to its target. The
target `Note\` resolves against nothing, so `link-unresolved` fired — an
ERROR at turn end on a link that works. Obsidian states the escape as an
instruction, not a workaround: "If you want to use aliases, or to resize
an image in your table, you need to add a `\` before the vertical bar"
(obsidian.md/help/advanced-syntax), with the example
`[[Basic formatting syntax\|Markdown syntax]] | ![[Engelbart.jpg\|200]]`.
Both halves of that example were broken here.

Measured across all **nine** vault roots on this machine — enumerated
with `is_vault_root`, the tenth being a scratch fixture under
`/home/jerome/tmp/mechdocs-test/` that is named and excluded rather than
quietly skipped: 1090 files, 4609 links, **zero** same-file links and
**zero** escaped aliases. Both defects are latent, and the blast radius
of the correction is zero findings in either direction.

## Options

_The source record carries no section under this title; where it weighs a
rejected variant it does so inside the design points below — exempting
same-file links, moving `unescape` across the module boundary, and
reporting the empty `[[]]` are each named and refused there._

## Decision

_The source record carries no section under this title; it states what was
chosen inside the design points below, beginning with "Three quantifiers
do the whole job"._

## Justification

### Design points

- **The escape is handled at the alias boundary and nowhere else.** A
  legal link target cannot carry an escape at all: Obsidian forbids
  `[ ] # ^ |` in file names outright and `\` on Linux and macOS, so the
  only legal backslash inside `[[...]]` is the one in front of an alias
  or embed-size pipe. Three quantifiers do the whole job — `*` instead of
  `+` on the target, lazy target and anchor, and `\\?` in front of the
  alias pipe.
- **The anchor carried the same defect, one field over.** `[[Note#Head\|alias]]`
  used to yield the anchor `#Head\`. Nothing resolves anchors of other
  files, so it cost nothing — but it was the same bug, and it is fixed
  and asserted rather than left for the next reader to rediscover.
- **`unescape` stays in the exporter, and residual 3 of amendment
  2026-08-01b stays open.** That residual authorised the move *together
  with the use issue #23 would bring*. With the escape handled in the
  regex, the use does not exist: measured over the nine vaults, 4792
  targets contain not one backslash, and `unescape` cannot act on any
  target the new matcher can produce. Moving a helper across a module
  boundary for a call that provably changes nothing would be the
  decoration this document keeps refusing. The issue asked for it; the
  purpose behind it — a table-escaped alias must resolve — is delivered
  by the regex.
- **A same-file link is resolved, not exempted.** The issue asked for
  links "resolved against the containing file rather than the name
  index", and exempting them would have produced the same output for an
  anchor that exists and one invented on the spot — a fixture that cannot
  fail. `anchor_index` reads headings of every level and block
  identifiers, both outside fenced blocks, so a `# rebuild the image`
  line in a `bash` block resolves nobody's anchor. Headings compare
  folded, which is the tolerance `classify_sections` already grants.
- **Same-file links stay out of the link budget and the repeat counter.**
  The issue named the missing count as part of the defect; the shipped
  conventions say "under ~20 **outgoing** links per file", and "link the
  responsible file once" has no addressee when the target is the file the
  reader is already in. An ordinary table of contents would otherwise
  trip `link-repeat` at four entries and `link-budget` at twenty-one,
  with advice nobody can follow.
- **`[[]]` remains no link.** It is the one line in 81028 where the old
  and the new regex disagree, and the only occurrence on this machine is
  the REF template of a foreign archive vault — not of the vault this
  repository ships. Skipping it preserves exactly what the old regex did
  by not matching it; reporting the empty placeholder is a finding
  rollout of its own.
- **Reviewed adversarially before implementation.** A fresh-context
  review produced ten findings; nine were confirmed and changed the plan,
  including the two above that reverse the issue's own wording. The one
  refuted finding is residual 3 below.

## Consequences

### Accepted residuals (documented, not solved)

1. **An anchor into another file is still unchecked.** `[[Note#Heading]]`
   resolves as soon as `Note` exists; whether that heading is there is
   nobody's question yet. The asymmetry is deliberate — `check_links`
   holds the lines of the file it is checking and nothing else.
2. **A chained anchor is checked segment-wise, not as a path.**
   `[[#Chapter#Section]]` passes when both name headings, even if the
   second is not below the first. Obsidian resolves the path; this reads
   the set.
3. **`check_links` is quadratic in line length, and this change makes it
   1.23× worse.** Measured on a single line of `n` opening brackets:
   503 ms old against 617 ms new at n=4000, quadrupling per doubling in
   both. `hook_post` runs it on every write, so one pasted single-line
   blob stalls the hook rather than failing it. The obvious guard
   (`if "[[" not in line: continue`) does not touch this case — the
   pathological line contains `[[` — it only spares link-free lines
   (0.07 ms → 0.002 ms). Pre-existing, out of scope here, worth its own
   issue.
4. **`[[A\\|B]]` yields the target `A\`.** The escaped backslash no
   longer escapes the pipe, so `split_cells` divides the cell there
   (amendment 2026-08-01b) while the link matcher keeps the backslash.
   Degenerate in both readings — the target is illegal either way, and
   the shape occurs zero times.

### Realization

- `validate_vault.py` — `WIKILINK_RE` rewritten with the three
  quantifiers documented inline; `HEADING_RE` and `BLOCK_ID_RE` added;
  `anchor_index` and `anchor_resolves` added; `check_links` given the
  same-file branch, the empty-link skip and the counter exclusion
- `tests/run.sh` — fourteen matcher assertions (six verified to fail
  against the previous `WIKILINK_RE`, two negative controls), nine
  assertions on `anchor_index`/`anchor_resolves` including the fenced
  shell comment, four on `check_links` primitives including the
  budget-exclusion pair, a resolving anchor pair and an escaped alias in
  the precision fixture, a reported pair in the violation fixture, and
  the post hook's aggregation count moved 2 → 4 with a by-name
  assertion; 159 to 164 assertions
- `00_documentation_file_creation_and_conventions.md` — the table escape
  and the same-file anchor named in the Wikilinks section

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
change whose two shapes occur nowhere. What proves the change works is
therefore the runtime check rather than the corpus: on a throwaway vault
carrying all four shapes, the old code reports
`[[CMP_Converter\]] does not resolve to any file` on a working link and
says nothing about two anchors pointing at nothing, while the new code
stays silent on the link and names both anchors.

A note for whoever deploys this: no finding code was renamed and no code
was added to the blocking set, so a stale per-session baseline in
`/tmp/claude-mechdocs` stays valid. Nothing in any measured vault changes
severity or count.
