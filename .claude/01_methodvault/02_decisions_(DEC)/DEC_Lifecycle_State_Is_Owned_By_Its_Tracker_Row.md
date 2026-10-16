---
domain: DEC
id: DEC-MTH-059
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Draft

## Context

**This note decides where lifecycle state is written in a project vault of
this method** — the state of an external action or of a plan step after
the work itself is done: sent, pushed, merged, published head, approved, a
phase or round state. It extends the volatile-fact rule of
[[DEC_A_Volatile_Fact_Has_One_Owning_File]] (DEC-MTH-048), whose list names
paths, versions, flags, values with a unit, unit and service names,
function and file names, ports and hostnames, and no state.

A truth audit of the two working project vaults of this method, code-named
kernel and opensource, checked 64 load-bearing claims against their
repositories on 2026-10-15: 32 were true. Of the 30 that were not, 17 were
lifecycle state written in several notes and updated in one. Code-level
claims — commit ids, line citations, constants — were the most reliable
part of both vaults; the rule targeted the part that was already fine.

The worked example is one send event. A kernel patch was sent on
2026-10-01. The commits recording it touched the upstream tracker in ADM
and nothing else in the vault. Afterwards a TAE said in three places that
nothing had been sent, a second TAE still called the next revision a draft,
the candidate register said the item was not cleared for sending, an IMP
named a branch the patch no longer came from, and a plan row was half
current while its `last-verified` date was newer than the send. Each of
those notes was correct when written; none was wrong by the rule as it
stood.

The same audit found the opposite case. One formatter version appears in
the Test Conditions of eight TAE notes, every copy consistent: each TAE
records the condition of its own run, a historical observation. Read
literally, DEC-MTH-048 calls that a duplicate.

## Options

- **A — The ADM tracker row owns lifecycle state (chosen).** One row per
  tracked item; every other note links the tracker and states the role the
  state plays, never the state word.
- **B — The TAE of the event owns it.** Rejected. A TAE answers "did it
  work?" on a slow timeline and records a run; a send, a review and a merge
  happen after the run and keep changing. Plan phases and publication
  drafts have no TAE at all, so a second owner would be needed for them.
- **C — No owner; detect restated state mechanically.** Rejected on
  precision: the state words (sent, merged, approved, pushed) are ordinary
  technical vocabulary, and a search for them reports packets sent and
  branches merged as often as the state of a contribution.
- **D — Leave the volatile-fact list as it is.** Rejected: the measured
  failure class is the largest one, and nothing in the method names it.

## Decision

Option A, chosen by the operator on 2026-10-16.

1. Lifecycle state is a volatile fact. Its owner is the row of the ADM
   tracker that tracks the item; the shape of that row and the place a
   finished row goes are [[DEC_A_Tracker_Row_Holds_Current_State_Only]]
   (DEC-MTH-058).
2. TAE, ARC, IMP and DEC notes link the tracker for what happened next. A
   TAE states what was tested and what it showed; it does not state whether
   its result was sent, accepted or merged.
3. An item has exactly one live row across all trackers. When an item
   moves from one tracker to another — a candidate becomes a contribution —
   its old row moves to the old tracker's closed sibling, carrying the
   state `promoted` and a link to the new tracker.
4. A note's own status is not lifecycle state of an external action and
   stays where the method requires it: the frontmatter `status`, a DEC's
   `Status:` line, the status column of an ARC allocation row, and the
   follow-ups a DEC lists in its own Consequences.
5. A TAE's Test Conditions are exempt from detail ownership: a version or
   setting recorded there is an observation of that run, not an owned fact.
   The section may carry whatever title the vault's TAE template gives it.

## Justification

- The failure is measured, not inferred, and it is the largest single class
  in the audit; the existing list covered the smallest.
- ADM is the domain whose question is project logistics and whose timeline
  is medium — the rate at which a contribution changes state. A TAE's slow
  timeline is the reason it should not carry that state.
- Restated state is not mechanically detectable with useful precision, so
  the lever is the written rule plus a place that makes the rule cheap to
  follow: one row, linked from everywhere else.
- The exemption removes a rule violation nobody can repair: deleting the
  conditions of a past run from its evidence note would destroy evidence
  to satisfy a rule written for facts that move.

## Consequences

- `SKILL.md` gains the state in its volatile-fact list, the owner and the
  exemption in one clause each; the conventions file and the ADM README of
  the template vault carry the rule for readers of the vault.
- DEC-MTH-048 receives a `Corrected by:` line naming this note and
  DEC-MTH-058; its Status stays Accepted.
- Whether the rule changes what an agent writes is a behavioural question
  the suite cannot answer. It is measured by an A/B replay of the send
  event: the number of notes left contradicting the tracker after the pass.
- The two measured vaults are not corrected here; their 17 stale state
  claims are a later batch per repository.
