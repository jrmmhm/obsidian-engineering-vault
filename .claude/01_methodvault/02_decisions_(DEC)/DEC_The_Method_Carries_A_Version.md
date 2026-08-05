---
domain: DEC
id: DEC-MTH-029
created: 2026-08-05
last-verified: 2026-08-05
---
Date: 2026-08-05
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-05h — The method carries a version, and a breaking change is defined (Accepted)".

## Context

The method is versioned in two places and as a whole in none.
`vault_schema.json` declares `schema_version: 0.3`, and
`export_traceability.py` declares `EXPORT_SCHEMA_VERSION = "1.1"`. Neither
answers the question a reader of this repository actually has, which is
whether the method they adopted six months ago still means what it meant.

That question is not academic here, because of how the template is
consumed. A repository created from a GitHub template starts with a single
commit and shares no history with the template — unlike a fork, which
carries the whole commit history. There is no upstream to pull from and no
merge to resolve. An update is somebody reading a changelog, deciding it is
worth it, and copying files across.

Under those mechanics a version number is not decoration; it is the only
channel through which this repository can tell an existing project what a
change will cost it. Until now the repository carried no tags, no releases
and no changelog at all (issue #5).

## Options

- **A — Do not version; point at the git log.** Rejected on the mechanics
  above: a derived project does not have this log. `git log` is exactly the
  artifact a template-created repository does not inherit, so the one
  audience that needs the information is the one audience that cannot read
  it.
- **B — Promote `schema_version` to the repository version.** Rejected.
  The two measure different things and move on different schedules: a
  documentation release moves the method without touching the data model,
  and `EXPORT_SCHEMA_VERSION` would still be a third number with no
  relation to either. Collapsing them would force a schema bump for changes
  that do not touch the schema, which makes the schema number stop meaning
  anything.
- **C — Classify by intent: a documented rule that starts firing correctly
  is a PATCH, a new rule is a MAJOR.** Rejected during review, and it is
  worth recording why, because it was the plan. Issue #51 documents seven
  rules the validator enforces that no document in the repository states
  (`stub`, `structure`, `duplicate-basename`, `link-repeat`,
  `encoding-not-utf8`, `id-scope-mismatch`, `orphan`). For every one of
  them the criterion returns no answer. Worse, the answer would depend on
  whether the pull request that documents them lands first — a versioning
  rule whose outcome depends on merge order is not a rule.
- **D — Classify by consequence for an existing vault (chosen).**

## Decision

**Semantic Versioning applies to the method, and the tier is decided by one
question: does the set of rules itself move?**

MAJOR is a vault that was clean *and correct* no longer conforming, because
what counts as correct changed — a domain added, removed, renamed or
redefined; a template-required section changed; a frontmatter field made
required or its value set changed; the identifier pattern or a scope rule
changed; a typed relation added, removed or re-sourced; a rule newly
introduced or a WARN raised to ERROR; a field in `traceability.json` or a
column in either CSV renamed, removed or given a new meaning.

MINOR is new capability that leaves existing vaults clean. PATCH is the
rules staying put while a tool starts applying them correctly.

**A PATCH may still make a vault report findings it never reported.** Those
findings were always true and the tool was blind to them. Rather than
hiding that behind a tier, the compensating rule is that a PATCH entry in
the changelog **names the finding code**, so a reader can grep their own
vault before deciding to update. Whether a rule was documented does not
enter into the classification at all; that is the subject of issue #51 and
a documentation defect, not a versioning question.

**Highest tier wins on a multiple hit.** Amendment 2026-08-05d is the
worked case: it added an optional frontmatter field (MINOR) and changed
where two typed relations are authored (MAJOR) in one change. Without this
rule the most recent real merge in this repository is classified two ways.

**A template-section change is MAJOR, and it does not hit a derived project
passively.** `check_sections` derives the required sections from each
project's own `00_*file_template*` files, so a project keeping its old
templates keeps its old required sections and stays clean. The tier prices
what adopting costs; it does not announce a break that happens to somebody
who does nothing. This is the one tier in the table that is a statement
about the future rather than the present, and it is deliberate.

**The first release is 0.1.0, and it is not cut by this change.** SemVer
reserves major version zero for initial development; `schema_version` is at
0.3; and the open roadmap issues that would remap object and relation types
(#6) and move the decision log into the vault (#53) are MAJOR under the
table above. A 1.0.0 now would be a 2.0.0 within weeks, which is the one
thing a version number cannot survive.

## Justification

### Rejected by review, before implementation

An adversarial review of the plan killed four factual claims that would
have shipped in the changelog, each verified against the source: that the
schema declares nine typed relations (it declares eight — the ninth
`relations` key is `note`, a prose explanation, and this file already said
"eight" in amendment 2026-08-05d); that the skill ships two hooks (`hooks/`
holds three, and the README sentence claiming two is issue #52); that
frontmatter carries `domain, status, created, last-verified` on every note
(DEC carries no `status` — issue #52 again); and that 26 pull requests were
merged since 2026-01-22 (the first commit is from that date, the earliest
merged pull request is #7 from 2026-07-28). The review also rejected the
intent-based tier criterion recorded as option C, found that no tier
covered the exporter's output contract, and rejected a changelog heading of
`## [0.1.0] — unreleased` as unparseable under the format the file's own
header claims to follow — an em dash where Keep a Changelog specifies an
ASCII hyphen, a version heading with no date, and two sections that both
mean "unreleased". The release notes are therefore drafted inside
`## [Unreleased]`, which is the shape every changelog parser already knows.

## Consequences

### Realization

- `CHANGELOG.md` — Keep a Changelog 1.1.0 form, the 0.1.0 notes drafted
  under `## [Unreleased]`, one link definition that resolves today
  (`commits/main`); the tag link is added when the tag is cut
- `CONTRIBUTING.md` — the tool-versus-method split, the local check
  commands with their real output including the known `duplicate-basename`
  WARN, the method-change route through an issue, how the vault conventions
  bind a contribution, the tier table above, the three version numbers and
  which one a derived project reads, and the release procedure
- `.github/ISSUE_TEMPLATE/bug_report.yml`,
  `.github/ISSUE_TEMPLATE/method_change.yml`,
  `.github/ISSUE_TEMPLATE/config.yml`,
  `.github/pull_request_template.md` — the method-change form asks for the
  cost to a project that already adopted the current rule and for the
  expected tier, because those are the two a reviewer cannot supply
- `README.md` — a Contributing section, and `.github/` added to the
  repository layout block it was missing from
- `STRUCTURE.md` — a `## .github` section, and the note in `60_releases`
  that a project's baseline trail is not the template's changelog

No tag is created and no GitHub release is published by this change. The
version number is chosen and justified; cutting it is a separate act,
described in `CONTRIBUTING.md` under *Cutting a release*.

### Aligned on integration

Rebased onto amendments 2026-08-05e (coverage on the graph) and 05f/05g (the
generated index and the `AGENTS.md` forwarder); this amendment moved from
suffix `e` to `h`. Both of those changes then became the tier table's worked
examples, because they are the two ends of it: coverage moving from a prose
mention to the allocation row and `verifies:` is a rule redefined, so a
previously clean vault can report `req-uncovered` with its notes untouched —
MAJOR. The fifth export artifact and the additive `summaries` key, with
`EXPORT_SCHEMA_VERSION` at 1.1, break no reader and dirty no vault — MINOR. A
policy stated against two changes that already happened is harder to argue
with than one stated in the abstract.
