---
domain: DEC
id: DEC-MTH-035
created: 2026-08-08
last-verified: 2026-08-08
---
Date: 2026-08-08
Status: Accepted

## Context

Issue #74. "Amendment 2026-07-28g" was cited four times — twice in the
tool sources (`validate_vault.py`, the `git_head_content` docstring, and
`tests/run.sh`, the comment above the UTF-16-at-HEAD gate fixture) and
twice inside [[DEC_A_Non_UTF8_File_Says_Which_Encoding]] (option I, and
the "both halves were measured" design point) — always for one
statement: the condition under which `section-mismatch` became the
first ERROR to enter the stop gate's blocking set, namely that the new
code has to appear in the HEAD baseline as well, or the gate blocks a
session on a file nobody touched. The date resolves to nothing: no
amendment of the appended log carried it, and no DEC note does.

The record that actually states the condition is amendment 2026-07-31
([[DEC_A_Near_Miss_Is_Not_An_Absence]]), which introduced
`section-mismatch`. Verified against the record before any edit: its
design point "The new ERROR code is safe against the ratchet" states
the baseline condition, and its realization names the git-backed
assertion that a pre-existing `section-mismatch` does not block the
stop gate — the test the second citation calls "the test it asked for,
in the form it asked for it".

The migration audit found the phantom on first contact and carried it
as residual 5 of [[DEC_The_Decision_Log_Moves_Into_A_Vault]], leaving
all four citations standing: correcting the two inside a record would
have been editing the record mid-migration, and the two in the code
were outside that change's scope. The forwarding map named the defect
instead. What was missing was not knowledge but a decided correction.

## Options

- **A — leave all four standing, documented as a known defect.** The
  migration's own choice, and right for a pass whose fidelity rule
  forbade edits. Wrong as an end state: a citation that resolves to
  nothing sends every future reader through the forwarding map only to
  learn that there is nothing to find — while the true source exists
  and is one row away.
- **B — retarget in date form, `2026-07-28g` becomes `2026-07-31`
  (chosen).** All four citations then point at the record the statement
  stems from, resolvable through the forwarding map like every other
  dated citation in the tools. Inside the corrected record, the first
  occurrence additionally carries the migration's inserted-wikilink
  shape and the second stays a bare date, which is how migrated records
  cite throughout the corpus.
- **C — retarget to the DEC filename in the tool sources too.** The
  cleaner end state, but residual 8 of the migration decision already
  decided that the tool sources keep date form until the batch rewrite
  (issue #71); rewriting two citations alone would leave the remaining
  dated citations inconsistent and pre-empt that issue's scope.

## Decision

B. All four citations read `amendment 2026-07-31`. The correction is
recorded forward at every site that documented the phantom: the
forwarding-map paragraph in `DECISIONS.md`, residual 5 of the migration
decision, and the corrected record itself, which declares the deviation
from its migration source above its Context and points here with a
`Corrected by:` line.

## Justification

- **The retarget target is an empirical fact, established before
  editing.** The statement was located in the 2026-07-31 record and
  matched clause for clause against all four citation sites; had it not
  been there, the correction would have stopped rather than guessed.
- **History is corrected forward, never rewritten silently.** The text
  of a migrated record changes only together with an in-file
  declaration of the change — the precedent is the migration's declared
  backtick fix, where the corrected file says so above its Context. The
  sites that described the defect as open now describe the correction,
  with its date; none of them merely fall silent.
- **Date form is the standing convention for the tool sources.**
  Residual 8 keeps every citation there resolvable through the
  forwarding map until issue #71 rewrites them together; option B is
  the only form that fixes the defect without moving that boundary.
- **One id was coordinated, not derived.** DEC-MTH-033 and DEC-MTH-034
  were claimed by concurrent work when this note was written, so its id
  was fixed externally as DEC-MTH-035 rather than counted from the
  folder — gaps are legal, a collision is not.

## Consequences

- `validate_vault.py` and `tests/run.sh` — one comment retargeted each;
  no behaviour changes, the suite pins none of the wording.
- `DEC_A_Non_UTF8_File_Says_Which_Encoding` — both citations
  retargeted, the first with the inserted-wikilink shape; the Migrated
  line declares the post-migration change and a `Corrected by:` line
  points here. Its text now deviates from the appended log's record in
  these two citations, deliberately and declaredly.
- `DEC_The_Decision_Log_Moves_Into_A_Vault` — residual 5 closes with a
  sentence recording the retarget and this note; its fidelity passage
  ("one byte-level change") stays as the measurement of the migration
  pass it was, the residual now names the second, later deviation.
- `DECISIONS.md` — the "one date resolves to nothing" paragraph becomes
  the record of the correction: what was cited, where the statement
  stems from, and when it was retargeted. After it, every date cited in
  the tools resolves to a record.
- `STRUCTURE.md` — the note count in "These 32 notes each are." becomes
  numberless; this note falsified the figure, and a figure copied into
  prose is wrong from the next merge onward.
- `CHANGELOG.md` — recorded under Unreleased as corrected
  documentation, MINOR.
