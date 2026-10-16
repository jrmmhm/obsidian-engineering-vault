---
domain: DEC
id: DEC-MTH-053
created: 2026-10-16
last-verified: 2026-10-16
---
Date: 2026-10-16
Status: Accepted

## Context

**Which findings `validate_vault.py` stops emitting, and why none of them
was a defect report.** Run in full mode over six real vaults on 2026-10-16,
the validator printed 94 WARN lines and no ERROR. A classification of every
line (research report R6 of batch skills-1) found four of them true and
actionable; the rest were false positives or findings their owners had
already decided never to act on. A channel that is wrong most of the time
teaches its reader to skip it, and the reader here is an agent whose context
is a budget.

Five sources made most of the noise. The name index walked the file system
instead of the repository, so a vault whose index root is a home directory
indexed plugin caches and session memories: 27 of one vault's 28
`duplicate-basename` lines. That finding also reported every shared stem,
including the two README files every derived vault ships and nobody links.
The link budget counted the table rows the templates mandate - one
allocation row per requirement, one source cell per row - and links of a
note to itself: 11 of 14 link findings. `link-repeat` fired on the same rows
and was actionable in none of its ten measured lines. `req-uncovered`
repeated its rationale once per requirement, six near-identical lines for
one fact. And `path-missing` raised an ERROR for a gitignored path that
cannot exist on a fresh checkout, which one project answered by rewriting
its paths until the check no longer saw them.

## Options

- A: keep every rule and lower the noise by documentation - tell readers
  which findings to ignore.
- B: delete the noisy rules outright.
- C: keep each rule's defect class and narrow what it reads.

## Decision

Option C, except for `link-repeat`, which is deleted.

- **The name index.** Inside the vault the disk is walked as before - the
  same file set the full audit validates and the exporter reads, so a note
  written this session and a gitignored note both resolve. Outside the
  vault, where the index reaches into the documentation root, only what
  git counts as the project is indexed: tracked plus untracked files not
  ignored, a nested repository's folder walked. Without git, or when git
  cannot answer, the whole root is walked as before.
- **`duplicate-basename`** is reported only for a stem some wikilink
  targets, matched as a parsed link target outside fences and code spans.
  The finding names where the stem is linked from, every colliding file,
  and the one remedy: rename a file, because a path-qualified link does
  not resolve in this validator either.
- **The link budget** counts prose links only - a line whose first
  character is a table pipe and a link to the note itself are not counted.
  `link-repeat`, its threshold and the larger budget the overview and every
  ARC note had are deleted.
- **`req-uncovered`** is one finding per requirement file and kind of gap,
  listing the identifiers and naming the repairs. The three kinds stay
  apart because their repairs differ.
- **A missing artifact path** that the repository ignores and whose folder
  is absent too is a WARN, "unverifiable on this checkout". Asked of the
  project-relative reading of the path only.

## Justification

- Measured on the six vaults, full mode, before and after: 94 WARN lines
  to 17, no ERROR before or after. The before figure was taken before one
  of the six vaults became a git repository of its own the same day, which
  moved its own base from ten lines to nine.
- The 18 seeded defects of R6 are caught by the new validator exactly as
  by the old one: 16 caught, the same two missed by design, and every
  ERROR code each mutation raised is raised again.
- The briefing asked for the whole index from git. The adversarial review
  showed that this drops gitignored notes inside the vault from link
  resolution - a correct link would turn into a blocking ERROR - and
  that a case-only rename on a case-insensitive file system would stale
  the index. The disk inside the vault and git outside it keeps every
  noise source removed, since all of them lay outside the vault.
- Every remaining kept rule still names its defect; nothing that blocked
  before stops blocking.

## Consequences

- Residual: a gitignored file whose folder exists but whose file is absent
  - an ignored log in a tracked folder on a fresh clone - stays an ERROR.
  The author's checkout cannot tell that from a typo, and a typo matters
  more. The converse holds one level deeper: a typo in a subfolder of an
  ignored tree that does exist - a misspelled folder below a present clone
  directory - has no folder either and is reported as unverifiable.
- Residual: outside the vault, a case-only rename that git has not staged
  is indexed under its old name until it is.
- The template vault and every derived vault report no warning by default;
  `tools/new_project.py` predicts that, and its rename flag remains the way
  to make a `[[README]]` link unambiguous.
- The conventions file's quick reference and `ARCHITECTURE.md` describe
  the narrowed rules; the record of the acceptance mechanism is
  [[DEC_A_Known_Finding_Is_Counted_Not_Repeated]].
