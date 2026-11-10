---
domain: DEC
id: DEC-MTH-067
created: 2026-11-10
last-verified: 2026-11-10
---
Date: 2026-11-10
Status: Accepted

## Context

**Where a fact about the software may be written down, so that it is still
there after the session that found it.** The mechatronics-docs skill
already says that a volatile fact has one owning file
([[DEC_A_Volatile_Fact_Has_One_Owning_File]], DEC-MTH-048). It did not say
that the owner itself must last. Agent sessions now run inside orchestrator
workspaces that hold batch records, verdicts, research notes, scratch
folders and git worktrees, and an agent cites what it has at hand.

In a project derived from this template, at `opensource@a2171c5`, 21
tracked files name a path inside the orchestrator's workspace under the
home directory: 7 vault notes (3 IMP, 2 TAE, 2 ADM), 2 test data scripts
and 12 handoff or prompt files of the project's administration folder.
Those workspaces are temporary by design. An orchestrator removes them when
a batch closes, `git worktree remove` deletes a worktree, and Claude Code
deletes its session transcripts after the period its `cleanupPeriodDays`
setting names (code.claude.com settings reference and git-scm.com
git-worktree, both read 2026-11-10). Each such path is a fact that leaves
with the workspace and a link that stays behind, dead.

The repository owner's decision (2026-11-10), in the owner's words: "Informationen über die
Software [leben] nur in der Dokumentation, in Büchern/Manuals, in Tests oder
im Code, nirgendwo sonst."

The conventions file already lets a note name an artifact on another
machine by an absolute or home-relative path with its host
(`~/.config/...`), and this vault names an installed copy of the skill
under the home directory ([[DEC_A_Replicated_Link_Is_Valid_Where_Written]]).
Those paths name the artifact itself. The rule has to keep them and still
exclude records about the work.

## Options

- **A: A validator check now.** Rejected for this change. A pattern for
  "hidden folder under the home directory" also matches the legitimate
  `~/.config/...` form. A named list of workspace roots is tool-specific and
  needs its own test, its own severity and a measured run against the
  derived vaults first.
- **B: The rule only in `CLAUDE.md` or the conventions file.** Rejected. A
  derived project copies those files by hand and keeps its old copy until
  it does. `SKILL.md` reaches a session as soon as the project takes the
  skill, the reason [[DEC_A_Criterion_Is_Never_Weakened_To_Reach_Verified]]
  (DEC-MTH-064) gives for its sentence in `SKILL.md`. The template's
  conventions file is also being renamed in parallel and is not edited here.
- **C: Archive the workspace records into the repository.** Rejected. A
  copied record has no owner and restates every fact it holds, the defect
  DEC-MTH-048 describes.
- **D: One rule in the Detail Ownership section of `SKILL.md`, and one
  question in its closing checklist (chosen).**

## Decision

Option D. Detail Ownership rule 6, "The owner outlives the session", names
the homes a fact may have (its owning vault note, a project document or a
source reference, a test, the code; a fact from outside the project by a
stable URL or a commit on a remote), names what is never a home (agent and
orchestrator workspaces, scratch and temp folders, worktrees, chat
transcripts, a branch no remote holds, any other record outside the
repository), and forbids anything in the repository to point into one. A
path that names an artifact itself (installed, deployed or kept on another
machine) is not such a record.
A fact that exists only in a workspace moves into its owning note, test or
code before the session or batch ends; a whole workspace record is never
copied in. Closing checklist item 5 asks the question once more.

## Justification

- The reason is stated with the rule: the place is deleted when the work
  ends, so the fact goes with it. [[DEC_The_Skill_Text_Keeps_The_Reasons_It_Steers_By]]
  (DEC-MTH-063) keeps the reasoning beside a rule because the one
  measurement there is found more defects where it was cut.
- The line runs between an artifact and a record about the work, not
  between inside and outside the repository. That keeps every path form the
  conventions file already allows.
- "A branch no remote holds" rather than "a local branch": a commit cited on
  the branch the note itself is committed on reaches the remote with it.
- The rule sits beside the owner rules because it is one: it says which
  files may be the owner at all.

## Consequences

- No validator, schema or exporter change; no finding moves. A note that
  pointed into a workspace already failed closing checklist item 5 ("all
  referenced artifact paths exist") on any other machine. Corrected
  documentation, MINOR by the versioning table in `CONTRIBUTING.md`.
- Derived projects gain the rule when they copy the skill; the changelog
  entry says so.

### Accepted residuals (documented, not solved)

- Nothing checks the rule. A path into a workspace passes every tool, as it
  did before: the validator never checks a path that starts at the
  filesystem root or at `~`.
- Two notes of this vault name a scratch location as the scope of a
  measurement, [[DEC_Every_Requirement_Table_Of_The_Bound_Section]] and
  [[DEC_Link_Matcher_Reads_Two_Unseen_Shapes]]. Both state the measured
  counts themselves; no fact lives in the scratch location, so they stand.

### Follow-ups

- A validator WARN for a path into a known workspace root, from a short
  list the schema carries, measured on the derived vaults before it is
  armed.
- One sentence in the template's conventions file, section "Paths and
  artifacts on other machines", once its rename has landed. Rule 6 then
  names that section and stops restating it, as DEC-MTH-063 asks of a
  rule a vault file owns.
- A pointer to rule 6 in the template's `CLAUDE.md`, for sessions that
  write handoffs without invoking the skill.
