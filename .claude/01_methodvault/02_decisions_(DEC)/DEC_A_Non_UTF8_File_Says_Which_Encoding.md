---
domain: DEC
id: DEC-MTH-017
created: 2026-08-04
last-verified: 2026-08-05
---
Date: 2026-08-04
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-04c — A file that is not UTF-8 says which encoding it is (Accepted)".

## Context

Issue #31, residual 2 of amendment 2026-08-04. `read_text` decoded every
file with `errors="replace"`, so a file that is not UTF-8 was read
successfully and read wrongly. Reproduced against the validator as it
stood: an ARC note written as UTF-16LE — what Windows PowerShell 5.1
produces for `Out-File`, `>` and `>>`
(learn.microsoft.com/powershell/module/microsoft.powershell.core/about/
about_character_encoding) — yields `frontmatter-missing` and
`template-sections`, two ERRORs in the stop gate's blocking set, both
naming a cause that is written in the file, while `frontmatter_id`
returns None and the file drops out of the identifier checks.

The signature-less half is worse and the issue understates it. The same
shell writes the active ANSI code page for `Set-Content` and
`Add-Content`. Such a file keeps its frontmatter and its `## ` headings,
because those are ASCII; only the umlauts of its prose become U+FFFD.
Measured on a probe: **zero** findings. The file validates green while
its text is corrupted.

Measured across all nine vault roots on this machine: 1091 files, zero
that are not valid UTF-8, zero carrying any byte-order mark. The defect
is latent, like #21's, and what proves the change is therefore the
runtime behaviour rather than the corpus.

## Options

**What to detect.**

- **A — a leading byte-order mark, and nothing else**, which is what
  issue #31 asks for. Rejected as half the defect: the ANSI file above
  carries no signature and is exactly the case that produces no finding
  at all today.
- **B — the mark, plus one strict decode whose failure is reported by
  byte offset (chosen).** A mark is proof rather than a guess: `FF` and
  `FE` are not legal UTF-8 bytes anywhere, so no valid UTF-8 file can
  begin with one. Where no mark exists, "these bytes are not UTF-8, at
  this offset" is the strongest true statement available — a Latin-1
  file and a corrupted UTF-8 file cannot be told apart, and the message
  names the byte instead of claiming the encoding.
- **C — statistical charset detection** (chardet and its kin). Rejected:
  a dependency, a guess, and a guess that has to be right to be useful.

**What to do with the encoding once it is known.**

- **D — decode with it and check the file normally.** Rejected. Obsidian
  does not open such a file either, so a validator that understands it
  would bless a file that does not work in the tool the vault exists
  for; and `export_traceability.py`, which reads with its own reader,
  would begin carrying that file's requirement rows into the
  traceability graph.
- **E — name it, read on exactly as before (chosen).** `read_text`
  returns, for every input, byte-for-byte what it returned before this
  change. That is what leaves the exporter untouched and keeps the two
  tools reading one way, and it is asserted per shape rather than
  assumed.

**Whether the finding replaces the file's other findings.**

- **F — replace them**, which issue #31 argues for: every check below is
  reading replacement characters, so reporting their conclusions is
  reporting noise. Rejected on evidence. `hook_stop` compares each ERROR
  code against the count the same file carries at git HEAD. Replace, and
  a file committed as UTF-16 has a baseline of one code where the run
  used to report three — so the session that does what the finding asks
  and re-saves the file as UTF-8 produces `template-sections` against a
  baseline of 0 and is blocked for it. Measured: re-introducing the
  early return fails three assertions, one of them that repair path.
- **G — add it (chosen)**, first in the file's findings and saying in so
  many words that what follows are consequences of the encoding rather
  than defects of their own. The reader keeps the diagnosis; the ratchet
  keeps its symmetry.

**Severity.**

- **H — WARN**, on the argument that the producer of such a file is never
  the running session: `Write` and `Edit` emit UTF-8, so the file arrives
  from a Windows shell, a sync client or an export tool, and the blocking
  channel aims at a party that is not at the table. Rejected: this
  project's criterion is whether a check can tell a mistake from an
  intention, and a Markdown file of a UTF-8 vault written in UTF-16 is
  never anybody's intention. `template-unreadable` is the standing
  precedent for "cannot be read at all" being an ERROR.
- **I — ERROR (chosen)**, under the condition amendment 2026-07-28g
  stated when `section-mismatch` became the first ERROR to enter the
  blocking set: the code has to appear in the HEAD baseline as well, or
  the gate blocks a session on a file nobody touched. That is why
  `git_head_content` hands out the blob as bytes and why both halves
  ship in one commit.

## Decision

B, E, G and I. `decode_source` becomes the one place where bytes become
vault content, `read_source` its file-level form, and `read_text` a view
on it with its old contract intact. `validate_file` takes the raw bytes
of a revision rather than its text, and `encoding-not-utf8` (ERROR, line
1) joins the file's findings.

## Justification

### Design points

- **The signature table is ordered longest first, and that is the whole
  reason it is a table.** `FF FE 00 00` begins with the UTF-16LE mark, so
  a table tested in any other order calls every UTF-32LE file UTF-16LE.
  The four sequences and their byte orders are Microsoft's table
  (learn.microsoft.com/globalization/encoding/byte-order-mark), which
  states the Unicode standard's. The probe for that pair is the one
  assertion a reversed table fails.
- **The UTF-8 mark is deliberately not in the table.** It is stripped and
  the file is read on, which is what amendment 2026-08-04 settled; a file
  saved by a well-meaning Windows editor is not a file with a problem.
- **Both halves were measured by reverting each alone.** With only the
  working-tree half in place, a file committed as UTF-16 reports a code
  its own baseline does not carry and the gate blocks a session that
  touched nothing — one assertion catches it. This is the test amendment
  2026-07-28g asked for, in the form it asked for it.
- **The newline translation had to be restored explicitly.**
  `Path.read_text` opens in text mode and translates `\r\n` and a lone
  `\r`; decoding bytes does not, and 16 of the 1091 files carry CRLF.
  Every consumer splits with `splitlines()` and would never have noticed
  — but `read_text` is this module's public reader and the claim that its
  output is unchanged has to be true, not nearly true. The claim was
  wrong in the plan and the review caught it. Doing the two rewrites on
  every string cost a fifth of a full audit (homelab 0.32 s → 0.39 s), so
  a membership test skips them for the 1075 files without a CR.
- **`decode_source` never raises, including on a `str`.** It runs in both
  hook paths, where an exception exits 2 and fails the gate open. There
  is one producer of the bytes today and none tomorrow; a `TypeError`
  there would switch the enforcement layer off silently, which is too
  high a price for a type check the language does not enforce anyway.
- **Reviewed adversarially before implementation.** A fresh-context
  review returned thirteen findings; ten changed the plan and three were
  refuted with the code. The consequential ones: the ratchet inversion
  that killed the early return, the claim that `read_text`'s output would
  be byte-identical (false for 16 files), and two proposed assertions
  that would have passed against the unchanged validator. Refuted, with
  evidence: the alleged rule that no amendment may add to the blocking
  set — `section-mismatch` did exactly that and recorded the condition
  under which it is safe; that `content is None` would stop being a
  usable baseline signal, which only holds for a refactor this change
  does not make; and that pairing a positive assertion with "never a
  WARN" is worthless, which is the shape the suite already uses for
  `fence-record` and `id-vanished`.
- **The tests were measured against three wrong versions, not just the
  right one.** Five of the new assertions fail against the old
  validator, one against the fix with only its HEAD half reverted, and
  three against the fix with the early return re-introduced.

## Consequences

### Accepted residuals (documented, not solved)

1. **UTF-16 without a mark stays invisible.** ASCII text encoded as
   UTF-16LE is valid UTF-8 — every second byte is NUL, which decodes
   fine — so the strict decode does not fail and no signature exists to
   read. Windows PowerShell writes a mark for every Unicode encoding
   except UTF-7, so the source this was filed for is covered; a
   hand-crafted file is not.
2. **A doubled UTF-8 mark is still not reported.** `EF BB BF EF BB BF`
   remains valid UTF-8 after `utf-8-sig` strips one, so residual 1 of
   amendment 2026-08-04 stays open and this change must not be read as
   closing it. A probe asserts that it is still open.
3. **A template nobody can decode still empties its domain silently.**
   `Vault.templates_for` reads through `read_text`, `extract_h2` finds no
   `## ` line in the mojibake, and `check_sections` returns early for
   every file of that domain. The template's own `encoding-not-utf8` is
   the only message, which is at least a blocking one naming the cause.
   Unchanged from before this fix, and the same shape as the defect
   amendment 2026-08-04 closed for marks.
4. **The exporter reports nothing about encodings.** It shares the
   decoding — its reader applies the same `utf-8-sig` rule — but it has
   no finding channel for this and will read such a file as mojibake,
   contributing no rows. "One rule for both tools" holds for how the
   bytes are read, not for what is said about them.
5. **A REQ file in the wrong encoding takes its rows down with it.**
   `Vault.req_index` reads no rows out of mojibake, so every TAE file
   whose `verifies:` names those requirements gets `verifies-unknown-req`
   — a blocking ERROR on files that are not at fault, the failure shape
   `id-scope-mismatch` was introduced against. Pre-existing and
   unchanged; the cause is now named on the file that has it.
6. **`vault_schema.json` in another encoding is still reported as "not
   valid JSON".** The schema reader has its own path and its own WARN,
   and the message points at the parse rather than at the bytes.

### Realization

- `validate_vault.py` — `BOM_SIGNATURES`, `_universal_newlines`,
  `decode_source` and `read_source` added; `read_text` reduced to a view
  on `read_source`; `validate_file` documented as taking the raw bytes of
  a revision and emitting `encoding-not-utf8`; `git_head_content`
  returning the blob unfiltered; `head_identifiers` decoding through the
  shared reader
- `tests/run.sh` — a UTF-16LE and an ANSI fixture in the violation vault,
  each with a byte guard; probes at `decode_source` for the
  UTF-32-before-UTF-16 order, the truncated and the doubled mark, the
  `str` and empty-input paths, and `read_text`'s unchanged output across
  six shapes; in the git-backed fixture a committed UTF-16 file, an empty
  committed file and the repair path; 174 to 189 assertions
- no change to `00_documentation_file_creation_and_conventions.md`: an
  encoding is not something an author writes, so there is no convention
  to state — the same argument as amendment 2026-08-04
- `export_traceability.py` untouched, which is a consequence of decision
  E rather than an omission

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

Nine of nine byte-identical, which is the expected result for a defect no
file on this machine carries. Full-audit runtime, median of five:
homelab 0.32 → 0.35 s, PMDE 0.30 → 0.31 s, userver-nativclaw 0.70 →
0.73 s, template 0.13 → 0.12 s. `tests/run.sh` at 189 assertions, 0
failures.

What proves the change is the runtime check. On a throwaway vault holding
a UTF-16LE file and an ANSI file, the CLI reports `the file is UTF-16LE,
not UTF-8` and `the file is not valid UTF-8 (invalid start byte at byte
119)`, each on line 1 of its file, with the misread's consequences below
them. Through the hooks: the same file created this session blocks the
stop gate; committed at HEAD it does not block and is reported as
pre-existing; and after the session re-saves it as UTF-8 the gate stays
quiet while the section ERROR underneath becomes readable.

A note for whoever deploys this: `encoding-not-utf8` is an ERROR and does
enter the stop gate's blocking set. The per-file baseline in
`/tmp/claude-mechdocs` is recomputed from HEAD by the running validator,
so a session started after the swap is unaffected. A session already in
flight keeps a baseline written by the old code, where the code has no
entry and a pre-existing occurrence would count as introduced; baselines
expire after 7 days, and deleting the directory makes it immediate. A
vault whose files are UTF-8 — every vault measured here — sees no change
at all.
