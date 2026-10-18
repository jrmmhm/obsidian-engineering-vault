---
domain: DEC
id: DEC-MTH-060
created: 2026-10-16
last-verified: 2026-10-18
---
Date: 2026-10-16
Status: Accepted
Corrected by: [[DEC_An_Advisory_Carries_Its_Own_Repair]] – each advisory message now carries its repair and forms; the conventions file no longer owns them alone

## Context

**Which notes the validator flags because git says what they point at has
changed or vanished since they were last verified.** Every check of
`validate_vault.py` was structural: a path either exists or it does not, a
link resolves or it does not. None compared a note with the history of what
it points at, and `last-verified` was only checked for its date format. A
truth audit of the two project vaults in active use (RESEARCH-R7) found half
of their sampled load-bearing claims wrong and no current gate able to see
any of them. Three of the failure classes leave a trace git can read: a file
a note names was committed after the note's `last-verified`; a commit id a
note cites no longer resolves after a history rewrite; and a
pending/planned marker keeps silencing the path check after the artifact
exists. A prototype of the first check flagged a third of its hits falsely,
all of them test records citing a script that a one-line commit touched.

An A/B run of six documentation sessions against the first version of this
record (docs-2 AB-T2, 2026-10-16) found two rules pushing agents towards the
wrong repair. Control sessions kept a rewritten id beside its successor,
marked as the one from before the history rewrite; `ref-unresolved`
reported that line, and every treatment session deleted the old id. And
`pointer-drift` cleared once `last-verified` was bumped, its message
offering the bump as one repair: one session credited the bump with
removing the warning. Both rules were replaced on 2026-10-17, unmerged.

## Options

- A: do nothing mechanical; rely on the invalidation sweep in SKILL.md.
- B: three advisory checks in the vault-wide pass, read from git with one
  bounded query per repository, never blocking.
- C: the same three as ERRORs in the per-file pass, so the stop gate blocks
  on them.
- D: Doorstop-style fingerprints stored per link, cleared by a command.

## Decision

B — three WARNs in `validate_vault_wide`, shown in the full audit and in the
stop report's vault-wide block, never in the gate's block decision. What
each reads, and the lists they read it with, are owned by the
`git_advisories` block of `vault_schema.json`; the shapes below stay in
Python because they decide what is read at all. The repair each finding
asks for, and the forms it accepts, are the conventions file's.

- **`pointer-drift`** — a project file a note names (the file-shaped token
  `check_paths` reads, here also inside inline code and inside fenced
  blocks other than those declaring `host=`) was last changed on the
  first-parent line of the vault's own repository, so a branch merged
  later counts on the merge day, and not in the same commit as the note.
  It is reported when that change is dated after `last-verified`, and
  also, so that a date alone clears nothing, while the note's text apart
  from `last-verified` is what it was at the change, or while the newest
  change of `last-verified` since then came without a change of the text.
  Notes of the roles that record a point in time (TAE, DEC) are not asked.
- **`ref-unresolved`** — a commit id in an IMP, TAE or DEC note resolves to
  no object in the vault's repository nor in a git clone directly below a
  folder the schema lists as a clone parent. An id is a backtick span of
  lowercase hex or a hex word after "commit", 7-16 or 40 characters with
  at least one letter: capitals (Xcode object ids), digits only (CI run
  ids) and 17-39 characters (syzbot ids, md5) are not read. Any object
  type resolves it, an ambiguous abbreviation too. A dead id is not
  reported where each sentence or table cell citing it keeps it as the
  history of an id that resolves, in a form bound to the side the old id
  stands on. While the vault names a path inside a clone that is absent
  and ignored by git, the dead ids are counted in one line instead.
- **`pending-stale`** — a pending/planned/TBD/not-yet marker within a short
  window after a path that exists, files and directories alike.

A note marked superseded or deprecated is asked none of the three: marking
it is the repair the method names for a stale note. An id of a repository
this project does not hold is written `repo@id`, the way a foreign path
names its host.

## Justification

- A leaves the measured failure classes invisible.
- C cannot be right: none of the three can tell a mistake from an intention
  (a comment-only commit, an id of a repository this project does not
  hold), and what cannot tell those apart never blocks here.
- D adds stored state to every link; `last-verified` already is the stamp a
  writer sets when re-checking a note.
- The two checks that read git say nothing rather than guess where git
  cannot answer (pending-stale reads only the disk): no repository, a
  shallow one (its boundary commit carries every file, and 'missing' there
  proves nothing), a failing call. One walk per run: one first-parent
  `git log` over the cited files and the notes, one `cat-file` for the
  notes' earlier text, one `cat-file --batch-check` per repository.
- No network, ever: a blob:none partial clone fetched a missing object on
  demand, so every query runs with `GIT_NO_LAZY_FETCH=1` and
  `protocol.allow=never`, the second for a git too old to know the first.
- The note's own text, not its date, says it was re-checked, and needs no
  stored state. Requiring the note to name the changed commit instead
  would have reported eight kernel and three opensource notes that were
  edited after the change and never named it, against none. The rule on
  the newest date change exists because the A/B target note had been
  edited for another reason after the change: compared with its text at
  the change alone, a later bare bump cleared it again.
- A stale claim is corrected or marked, never dropped; the old reporting
  turned a correct mark into a deletion. Accepted are the forms sessions
  wrote ("split" and "rewrote" since docs-4), bound to direction: a
  looser marker silences a stale id beside an unrelated live one.
- For an absent clone, silence would hide that the check did not run, and
  a per-id finding asks to replace a correct upstream id. A clone counts
  as expected only when the vault names a path inside it: the kernel vault
  names one clone folder to say it is not used.
- Measured read-only at the vaults' heads on 2026-10-17: kernel one
  `pointer-drift`, two `ref-unresolved`, four `pending-stale`; opensource,
  the template and the method vault none. On the kernel vault as the A/B
  saw it, without its clones, the dead ids are one count line. The added
  cost stays near a twentieth of a second per run.

## Consequences

- `validate_vault.py`: `git_read`, `git_complete`, `advisory_notes`,
  `artifact_readings`, `id_units`, `marked_old`, `absent_clones`,
  `drift_kind` and the three checks, called through `git_advisories`,
  which keeps one failing check from dropping the others. `check_paths`
  shares the shape predicate `artifact_shaped`.
- `vault_schema.json`: the `git_advisories` block, twinned in
  `FALLBACK_SCHEMA`, and a new `schema_version`.
- `tests/run.sh`: dated fixture repositories pin each check, its clear
  rule, each accepted and each rejected historical form, the absent-clone
  line and each silence; every rule was watched failing under a mutant.
- [[DEC_Safety_Standard_Correspondence_Is_Structural]] writes its StrictDoc
  commit as `strictdoc@5a9b679`, declared on its Migrated line.
- `SKILL.md` names the three codes in its description of the stop report,
  points at the message and the conventions file for the repair, and says
  a bare `last-verified` bump is never it. Its invalidation-sweep step
  keeps its full text, since the report covers only what git can see.
- Residual, accepted because the checks are advisory and read one walk: a
  rebase that rewrites a file's commit date reads as drift; a clone nested
  deeper than one level below a clone parent is not asked; an edit for
  another reason in the same write as the bump clears it; a commit that
  changes the cited file and only the note's date counts as written
  together; a renamed note reads as written after the change; a partial
  clone, lacking the note's earlier text, leaves the date unquestioned.
- Follow-up, not built: R5 F19 `verifies-suspect` (a REQ changed after the
  `last-verified` of a TAE verifying it), one more pair on the same walk.
- Follow-up, not built: the git reads that predate this decision -
  `git_head_content` and `head_identifiers` - run without the network
  block and can make a partial vault repository fetch a blob on demand.
