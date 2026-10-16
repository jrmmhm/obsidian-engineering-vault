---
domain: DEC
id: DEC-MTH-060
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Accepted

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
Python because they decide what is read at all.

- **`pointer-drift`** — a project file a note names (the file-shaped token
  `check_paths` reads, here also inside inline code and inside fenced
  blocks other than those declaring `host=`) was last changed after
  the note's `last-verified`. Changed means: on the first-parent line of
  the vault's own repository, so a branch merged after the date counts on
  the merge day; and not in the same commit as the note itself, so a note
  committed the day after it was written is not its own drift. Notes of the
  roles that record a point in time (TAE, DEC) are not asked. Bumping
  `last-verified` is the clear action - Doorstop's "clear", with the stamp
  the method already has.
- **`ref-unresolved`** — a commit id in an IMP, TAE or DEC note resolves to
  no object in the vault's repository nor in a git clone directly below a
  folder the schema lists as a clone parent. An id is a backtick span of
  lowercase hex or a hex word after "commit", 7-16 or 40 characters with
  at least one letter: capitals (Xcode object ids), digits only (CI run
  ids) and 17-39 characters (syzbot ids, md5) are not read. Any object
  type resolves it, an ambiguous abbreviation too.
- **`pending-stale`** — a pending/planned/TBD/not-yet marker within a short
  window after a path that exists, files and directories alike.

A note marked superseded or deprecated is asked none of the three: marking
it is the repair the method names for a stale note. An id of a repository
this project does not hold is written `repo@id`, the way a foreign path
names its host; the conventions file states the rule.

## Justification

- A leaves the measured failure classes invisible.
- C cannot be right: none of the three can tell a mistake from an intention
  (a comment-only commit, an id of a repository this project does not
  hold), and what cannot tell those apart never blocks here.
- D adds stored state to every link; `last-verified` already is the stamp a
  writer sets when re-checking a note.
- The two checks that read git say nothing rather than guess where git
  cannot answer (pending-stale reads only the disk): no
  repository, a shallow one (its boundary commit carries every file, and
  'missing' there proves nothing), a failing call. One query per
  repository and run: one first-parent `git log` restricted to the cited
  files and the notes, one `cat-file --batch-check` per repository.
- No network, ever. A blob:none partial clone fetched a missing object
  from its remote on demand when asked for an unknown full id; every query
  runs with `GIT_NO_LAZY_FETCH=1` and `protocol.allow=never`, the second
  for a git too old to know the first. The suite pins it with a partial
  clone whose promisor holds the object.
- Measured on the two working vaults at their current heads, read-only:
  opensource gains one finding, kernel ten. pointer-drift flags three notes
  (prototype: fourteen with five false) - all three hold a stale claim on
  re-reading, one of them caused by the flagged change itself. Of the five
  notes the audit confirmed stale, pointer-drift flags three; the clone
  root it no longer reads leaves ARC_Linux_Kernel to pending-stale, and
  IMP_Repository_Split's directory pointer to nobody.
  ref-unresolved flags four: two are the id a history rewrite killed, two
  are foreign or pre-rewrite ids that `repo@id` qualifies. pending-stale
  flags four markers, all on paths that exist. The template vault stays at
  zero findings; the method vault gains none once its one foreign id is
  qualified. The added cost was about a twentieth of a second per run on
  either vault, full audit and stop hook alike.

## Consequences

- `validate_vault.py`: `git_read`, `git_complete`, `advisory_notes`,
  `artifact_readings` and the three checks, called through
  `git_advisories`, which keeps one failing check from dropping the
  others. `check_paths` shares the shape predicate `artifact_shaped`.
- `vault_schema.json`: the `git_advisories` block, twinned in
  `FALLBACK_SCHEMA`, and a new `schema_version`.
- `tests/run.sh`: dated fixture repositories pin each check, its clear
  rule and each silence, including the merge, the shallow clone, the
  repository split and the network block; every rule was watched failing
  under a mutant before it passed.
- [[DEC_Safety_Standard_Correspondence_Is_Structural]] writes its StrictDoc
  commit as `strictdoc@5a9b679`, declared on its Migrated line.
- `SKILL.md` names the three codes in its description of the stop report,
  with the clear action for `pointer-drift`. Its invalidation-sweep step
  keeps its full text rather than shrinking to a pointer at this report:
  an A/B comparison of a slimmed SKILL.md (2026-10-16) rejected cutting
  its explanatory prose, and the report covers only the pointers git can
  see, not the sweep's search for every note a change falsifies.
- Residual: a rebase that rewrites a file's commit date while the note was
  re-verified in a separate commit reads as drift until `last-verified` is
  bumped again. A clone nested deeper than one level below a clone parent
  is not asked, and an id only it holds is reported.
- Follow-up, not built: R5 F19 `verifies-suspect` - a REQ file changed
  after the `last-verified` of a TAE that verifies it - is one more pair on
  the same walk.
- Follow-up, not built: the git reads that predate this decision run
  without the network block - `git_head_content` (`git show HEAD:<path>`,
  the stop gate's baseline) and `head_identifiers` (`git grep` at HEAD, the
  full audit's `id-vanished`) - and can make a partial vault repository
  fetch a blob on demand.
