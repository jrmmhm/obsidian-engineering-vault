---
domain: DEC
id: DEC-MTH-058
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Draft

## Context

**This note decides how the administration domain (ADM) of a project vault
stays short and ordered as a project grows.** It is the companion of
[[DEC_Lifecycle_State_Is_Owned_By_Its_Tracker_Row]] (DEC-MTH-059), which
makes an ADM tracker row the one owner of lifecycle state. That owner is
only useful if it stays readable, and the trackers measured were not.

Measured on 2026-10-16 in the two working project vaults of this method,
code-named kernel and opensource (read-only, history from `git log`):

| Observation | Value |
| --- | --- |
| opensource upstream tracker, first commit to today | 27 to 99 lines, 2,273 to 44,805 bytes |
| Longest single table cell, kernel upstream tracker | 2,328 characters, written in one day |
| Share of the opensource tracker in appended "Follow-ups from ..." sections | 39 % |
| Share of the kernel hunt plan in its "Session log" section | 44 % |
| Rows in a final state (done, skipped, rejected, sent) still present | at least 21 |
| Rows or sections ever removed, apart from a repository split | none |

The added text of the ten largest diffs to these notes is roughly 40 %
current state, 16-20 % dated event narrative, 27-33 % evidence or rationale
that a TAE, DEC or IMP already holds, and 10 % repeated boilerplate. The
notes grow in bytes, not in lines: a "Next step" cell turns into a dated
log, and the line-based `length` check never sees it. The opensource
tracker passes it at 99 lines while carrying 6,145 words.

ADM had no rule against any of this. Its README listed recommended files
and nothing about their shape, and ADM has no template, so no section
contract applies to it either.

## Options

- **K1 — One ADM note per tracked thing, a status field, an index table.**
  Rejected. A hand-kept index restates every status a second time, which is
  the defect DEC-MTH-059 removes; a generated one is not committed under
  [[DEC_Generated_Content_Is_Stored_Only_Where_CI_Proves_It]], and the
  exporter skips ADM entirely, so a reader of the vault would see no index.
  Migration would split the measured trackers into some 35 notes.
- **K2 — A dated append-only log plus a generated current-state table.**
  Rejected. The log grows without bound and needs archiving anyway, the
  table again exists only after an export, and it needs a new table binding
  and parser in both tools. Keep a Changelog stays ordered only because it
  has one open section closed by a release; a follow-up log has no such
  event.
- **K3 — Tracker rows hold the current state only; detail lives in the
  owning DEC, TAE or IMP; history lives in git.** Removes the narrative, but
  finished rows stay, so the tracker still grows with every item ever
  tracked.
- **K4 — Archive by size or age** (GitHub Projects archives by state plus
  age, Wikipedia talk pages by age). Removes finished rows, but the 2,328
  character cell sits in an open row, and an archive under `99_archive/`
  lies outside the vault, where no wikilink resolves and no check runs.
- **K5 — K3 plus K4 inside ADM (chosen).** The tracker answers "where does
  each open item stand?"; a sibling note answers "how did each finished item
  end?". Two questions, two files.

## Decision

K5, chosen by the operator on 2026-10-16.

1. A tracker row carries the current state, the date it was reached, a
   next step of one sentence and a link to the note that holds the detail.
   A new state replaces the old one in the same cell; it is not appended.
2. No dated follow-up section and no session log in an ADM note. The
   history of a row is the git log of the commits that changed it; the
   evidence is the TAE, the reasoning the DEC.
3. A finished row leaves the tracker in the session that finishes it and
   moves, reduced to its final state, date and link, to a sibling note
   named `<Tracker>_Closed` in the same folder. The tracker's Context links
   that sibling. When the sibling reaches the length warning it is split
   by year.
4. No ADM template file. A template would make every existing ADM note owe
   its sections as a `template-sections` ERROR; the shape is taught by the
   ADM README instead.
5. Two advisory measures back the rule (Stage B, after the rebase onto the
   validator changes in flight): `length` also counts words, and a new
   `adm-cell-long` WARN names an ADM table cell longer than a set number of
   characters. Both thresholds live in `vault_schema.json`.

## Justification

- Every tool surveyed keeps state as one field with a link and puts the
  narrative elsewhere: DEP-3's `Forwarded` and `Applied-Upstream` headers,
  GitHub's issue `state`, an ADR's status line. K5 is that pattern in a
  Markdown table.
- Finished items leave the live view by a state rule in GitHub Projects and
  by an age rule in Wikipedia's archiving. K5 takes the state rule and
  keeps the archive inside the vault, where its links still resolve.
- Size is measured in words where reading cost is the concern (Wikipedia's
  article-size guideline counts readable prose, not bytes). The word count
  catches the note the line count passes; the cell length catches the
  growth at its source, one cell, before the note as a whole is long.
- [[DEC_A_Volatile_Fact_Has_One_Owning_File]] rejected per-domain length
  budgets as its Option B, because "a budget nobody measures is advice".
  The cell limit is a budget that is measured, holds in one domain only,
  and is aimed at a measured defect; it answers that objection rather than
  contradicting it.

## Consequences

- Not enforced, stated rather than implied, as
  [[DEC_A_Declared_Relation_Without_A_Check_Of_Its_Own]] does for its gap:
  that a finished row actually leaves, that no dated section is appended,
  and that an item has one live row. A WARN on dated headings was measured
  and refused — publication drafts legitimately carry a posting date in
  their heading.
- The existing trackers of the two measured vaults are not migrated here;
  that is a later batch per repository.
- The two measures are a rule the vault did not have before and two new
  WARNs: MAJOR by the versioning table in `CONTRIBUTING.md`, raised as
  MINOR while the repository is at 0.x, as that file prescribes.
