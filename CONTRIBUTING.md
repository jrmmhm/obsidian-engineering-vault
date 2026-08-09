# Contributing

Two kinds of change reach this repository, and they are not the same kind of
thing. One fixes a tool: the validator misreads a table, the exporter drops an
edge, a script has the wrong path in it. The other changes **the method** — what
a domain means, which sections a note must have, what counts as an identifier,
which rule the validator turns into an ERROR. The first costs a reviewer half an
hour. The second costs every project that was ever derived from this template,
because those projects cannot pull an update; they copy it in by hand and then
live with it.

That is the distinction this file exists to make operational: how each kind is
proposed, how it is reviewed, and how the version number tells an existing
project what an update will cost.

> **In a project made from this template**, this file describes the template and
> not your project. Replace it with your own rules or delete it — the same holds
> for [CHANGELOG.md](CHANGELOG.md) and the `.github/` directory.

---

## Before you start

Read in this order. Each answers something the next one assumes.

1. **[README.md](README.md)** — what the method is and what the tools do.
2. **[STRUCTURE.md](STRUCTURE.md)** — which folder holds which kind of artifact.
3. **`00_documentation/01_projectvault/00_documentation_file_creation_and_conventions.md`**
   — the rules a note follows. This is the authority on the method, above any
   summary of it elsewhere.
4. **`.claude/01_methodvault/system_overview.md`** — why the tools work the way
   they do. One DEC note per decision; start at the overview and read the note
   that touches your area. Most "why does the validator do *that*" questions are
   already answered there, usually with the alternatives that were rejected and
   the reason. Until 2026-08-05 this record was one appended file,
   `.claude/skills/mechatronics-docs/DECISIONS.md`; that file now forwards here
   and maps every amendment date to its note.

---

## Running the checks locally

Everything CI runs, you can run. The validator and the exporter are
standard-library Python 3 — there is nothing to install, no virtualenv, no
lockfile.

**The test suite.** This is the one that has to be green before anything else
matters.

```bash
bash .claude/skills/mechatronics-docs/tests/run.sh
# -> <n> tests, 0 failure(s)
#    ALL TESTS PASSED
```

The count climbs every time somebody pins a behaviour, so do not read anything
into the number — `0 failure(s)` and the last line are the whole signal. It is
left as `<n>` here for the same reason: a number quoted in prose is a number
that goes stale, and this one has already done so once.

**The template vault audit.** CI runs this by name, so that the check cannot
silently skip if the layout ever moves.

```bash
python3 .claude/skills/mechatronics-docs/validate_vault.py 00_documentation/01_projectvault
```

It is not silent, and that is expected:

```
WARN .../00_documentation/01_projectvault/README.md [duplicate-basename] 'README' exists 2x under 00_documentation - wikilinks to it are ambiguous
-- 0 error(s), 1 warning(s), 0 near miss(es)
```

Exit code 0. **Zero ERRORs is the gate; that one WARN is the known state of the
shipped vault**, not something you broke. If your run shows an ERROR, or a
second warning you did not expect, that is yours.

**The export is deterministic.** Only relevant if you touched the exporter, but
it is the property itself rather than a proxy for it — unsorted iteration is
what made comparable tools' JSON output undiffable until they fixed it.

```bash
python3 .claude/skills/mechatronics-docs/export_traceability.py \
        00_documentation/01_projectvault --output-dir /tmp/tr --no-timestamp
cp -r /tmp/tr /tmp/tr-ref
python3 .claude/skills/mechatronics-docs/export_traceability.py \
        00_documentation/01_projectvault --output-dir /tmp/tr --no-timestamp
diff -r /tmp/tr-ref /tmp/tr    # -> no output
```

Twice into the *same* directory on purpose: two different directories would
differ in the provenance block's command line, which is a true record and not a
determinism defect.

**The README's generated blocks still match the vault.** `README.md` stores
three pieces of the export's own output, each between a pair of marker
comments, so a change to the worked example has to reach them in the same pull
request. One run produces all three:

```bash
python3 .claude/skills/mechatronics-docs/export_traceability.py \
        00_documentation/01_projectvault --output-dir /tmp/tr --no-timestamp \
    | grep -E '^(requirements|objects):'   # -> traceability-counts
cat /tmp/tr/traceability_graph.mmd         # -> traceability-graph
sed -n '/^## Objects/,$p' /tmp/tr/traceability_index.md   # -> traceability-excerpt
```

Paste each into the fence between its own `<!-- <marker>:start -->` and `end`
comment — the graph into a ` ```mermaid ` fence, the other two into ` ```text `.
Everything above `## Objects` in the index stays out: the absolute vault path,
the file count and the digest differ per machine, and comparing them would fail
on every runner. `traceability_graph.mmd` carries none of the three, which is
why it is stored whole.

CI checks every marker pair the file carries, not a list of names it was given,
so adding a fourth block means adding markers and nothing else — and removing
the check for one is a red pipeline rather than a quiet gap. The reasoning is
[`DEC_Generated_Content_Is_Stored_Only_Where_CI_Proves_It`](.claude/01_methodvault/02_decisions_(DEC)/DEC_Generated_Content_Is_Stored_Only_Where_CI_Proves_It.md),
widened to three blocks by
[`DEC_The_Export_Draws_The_Graph_It_Reads`](.claude/01_methodvault/02_decisions_(DEC)/DEC_The_Export_Draws_The_Graph_It_Reads.md).

**The evidence chains are closed.** The one check that is stricter than a
working session, so it is also the one most likely to surprise you: locally the
validator leaves an open REQ→TAE loop at `req-uncovered` (a WARN, by measured
decision), and CI refuses it.

```bash
python3 .claude/skills/mechatronics-docs/export_traceability.py \
        00_documentation/01_projectvault --output-dir /tmp/tr-armed \
        --no-timestamp --fail-on not-allocated,no-evidence-note
# -> exit 0. Nonzero names the class and the requirements on stderr,
#    and /tmp/tr-armed still holds the full export.
```

If you added a requirement, this is the step that asks you for its allocation
row and its evidence note. Run it before you push and you will not meet it as a
red check.

**The worked example still proves what it claims.** The evidence in
`TAE_Battery_Log_Acceptance` is the verbatim output of this command, so the
command has to keep producing it — and the negative control has to keep failing.

```bash
python3 20_software/data_analysis/eval_battery_log.py \
        30_testdata/31_testdata_raw/2026-07-28_battery_monitoring/battery_log.csv
python3 20_software/data_analysis/eval_battery_log.py \
        30_testdata/32_testdata_processed/2026-07-28_battery_monitoring/battery_log_negative_control.csv
# the second must exit non-zero - a check that cannot fail proves nothing
```

---

## Changing a tool

A defect here is the gap between what a document states and what a tool does, so
a fix has three parts and they belong in three commits:

1. **The fix.** The smallest change that closes the gap.
2. **The assertion that would have caught it**, in
   `.claude/skills/mechatronics-docs/tests/run.sh`. The suite builds ephemeral
   fixture vaults at runtime; add your case to the fixture that already covers
   the nearest shape rather than inventing a new one.
3. **The documentation that asserted the old behaviour**, corrected. A fix that
   leaves a sentence somewhere still describing the bug has moved the defect,
   not removed it.

If the fix changed how a tool behaves, or you chose between designs on the way,
it also earns a DEC note in the method vault — see below.

Where a check lives is written down:
[`.claude/skills/mechatronics-docs/ARCHITECTURE.md`](.claude/skills/mechatronics-docs/ARCHITECTURE.md)
maps the validator's three stages and their five entry points onto the
functions that own them, and indexes every finding code. Read it before you go
looking, and add a row to its index when you add a code — the test suite fails
if you forget, and tells you which code is missing.

---

## Proposing a change to the method

**The method is the part a derived project cannot simply re-run.** Concretely:

- the nine domain definitions and what each one answers,
- the sections a domain's file template requires,
- the frontmatter field schema — which fields exist, which are required, what
  values they take,
- the identifier scheme and its scope rules,
- the typed relations declared in `vault_schema.json` and where each is
  authored,
- which rules the validator reports, and at which severity,
- the fields and columns the exporter writes.

A change to any of those goes through an issue **before** a pull request, using
the *Method change proposal* form. The form asks for five things, and they are
the five a reviewer cannot supply for you: the rule as it stands today with the
file it lives in, what should hold instead, a concrete case where the current
rule decides wrongly, what the change costs a project that already adopted the
current rule, and which version tier you think it lands in.

The reason for the issue-first order is that a method change is cheap to write
and expensive to withdraw. By the time it is a pull request it has templates,
tests, a schema entry and a vault migration hanging off it.

**A merged method change carries its own DEC note in
`.claude/01_methodvault/02_decisions_(DEC)/`** — Context, Options, Decision,
Justification, Consequences, the sections that domain's template requires, plus
the frontmatter every note in a vault carries. Read a recent note for the
format and add the file to `system_overview.md`. The Options section is not
decoration: it records what was rejected and why, which is the part that stops
the same argument being had again in six months. Where a review changed the plan
before implementation, say so — several notes do, and they are the more useful
ones.

---

## How the vault conventions apply to a contribution

A contribution that touches `00_documentation/01_projectvault/` is not a
contribution *about* the method — it is written *under* it, and the same rules
apply to it as to any note:

- **One question per file.** If a title needs "and", the file should be two.
- **Link by exact filename**, `[[REQ_Measurement_(MEG)]]`. Aliases are fine, the
  target is not negotiable — retrieval matches exact names, so a link that
  depends on context reads as a dead end.
- **The first lines of a Context section stand alone** — what the thing is,
  which module it belongs to, spelled out with real component names and IDs.
- **`last-verified` moves when you confirm a file still holds.** A stale file
  with a fresh date is worse than no file at all.
- **An allocation row reaches `Verified` only once a TAE link exists** and its
  evidence is written down. `Draft` and `Approved` are the honest states until
  then.
- **Edit vault files with an editor, not a stream.** The validation hooks
  observe `Edit`, `Write` and `MultiEdit` and nothing else — a `sed -i` or a
  heredoc writes an unvalidated file that looks identical in review.

And the hard gate: **the template vault must come out of your change with zero
validator ERRORs.** CI audits it by path, so this is not a matter of opinion.

---

## Versioning: what a breaking change means here

A repository created from this template starts with a single commit and shares
no history with it. There is no upstream to pull from and no merge to resolve —
an update is somebody reading the changelog, deciding it is worth it, and
copying files across. The version number is the only thing that tells them what
that will cost, which is why the classification below is about **consequence for
an existing vault**, not about how large the diff was.

The question that decides the tier is: **does the set of rules itself move?**

### MAJOR — the standard moved

A vault that was clean *and correct* is no longer conforming, because what
counts as correct changed.

- A domain is added, removed, renamed or redefined.
- A section a file template requires is added, removed or renamed.
- A frontmatter field becomes required, or the values it accepts change.
- The identifier pattern or a scope rule changes.
- A typed relation is added, removed, or changes where it is authored.
- A rule is newly introduced, or an existing WARN is raised to ERROR.
- A field in `traceability.json`, or a column in either CSV, is renamed,
  removed, or changes meaning. *Adding* one is not — `EXPORT_SCHEMA_VERSION`
  carries its own minor number for exactly that case.

### MINOR — new capability, existing vaults stay clean

- A new WARN.
- An additional exporter output.
- A new *optional* frontmatter field.
- A new template that nothing requires.
- New or corrected documentation.

### PATCH — the rules did not move, a tool started applying them correctly

Every `fix(validator)` and `fix(exporter)` whose whole effect is that a tool
stops being wrong about an input it already had an opinion on.

Said plainly, because it is the part people get bitten by: **a PATCH can still
make your vault report findings it never reported before.** Those findings were
always true; the tool was blind to them. That is the honest trade, and the
compensation is a rule: **a PATCH entry in the changelog names the finding
code**, so you can grep your own vault for it before you decide to update.

Whether the rule was *documented* does not enter into this. Several rules are
enforced today that no document states; that is a documentation defect with its
own issue, not a versioning question.

### Two more rules that make the table usable

**Highest tier wins.** A change often lands on more than one line. The most
recent example: the pull request that gave `contains` and `test-object` a
working source both added an optional frontmatter field (MINOR) and changed
where two typed relations are authored (MAJOR). It is MAJOR.

**A template change is MAJOR here, but it does not hit a derived project
passively.** The validator derives the required sections from *each project's
own* `00_*file_template*` files, so a project that keeps its old templates keeps
its old required sections and stays clean. The MAJOR tier prices what adopting
the change costs — it does not announce a break that happens to anyone who does
nothing. This is the one place where the tier is a warning about the future
rather than a description of the present, and it is deliberate.

### Two worked examples

Both are in this repository's own history, and they are the clearest short
statement of what the tiers mean.

**Coverage moved from a mention to the graph — MAJOR.** The validator used to
count a requirement as covered when its ID appeared anywhere in ARC or TAE
prose; it now decides on the allocation row and the `verifies:` field. That is a
rule redefined, so a vault that was clean under the old reading can report
`req-uncovered` under the new one — through no change of its own and with the
notes untouched. Nothing in it broke; what counts as proof got stricter. MAJOR
is the honest label, and the changelog entry says which finding code to grep
for.

**The exporter gained a fifth artifact — MINOR.** `traceability_index.md` is
new output, and the `summaries` key is a new field in `traceability.json`;
`EXPORT_SCHEMA_VERSION` went from 1.0 to 1.1. Nothing that read the old JSON
stops working, and no vault gains a finding. New capability, existing vaults
clean: MINOR.

### Three version numbers, and which one you read

| Number | Where | What it tracks |
| ------ | ----- | -------------- |
| The repository version | git tag, `CHANGELOG.md` | The method as a whole. **This is the one a derived project reads.** |
| `schema_version` | `vault_schema.json` | The data model — domains, identifiers, fields, relations. |
| `EXPORT_SCHEMA_VERSION` | `export_traceability.py`, written into `traceability.json` | The shape of the exported artifact, for whatever consumes it downstream. |

The lower two move independently and on their own schedules. A documentation
release moves neither; a change to either is at least MINOR and usually MAJOR
for the repository version.

### While the repository is at 0.x

Semantic Versioning says major version zero is for initial development and
anything may change at any time. This repository classifies every release by the
table above anyway, and raises MINOR where the table says MAJOR. The tiers are
therefore already meaningful, and the changelog does not have to be re-read
differently on the day 1.0.0 arrives.

---

## Commits and pull requests

[Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`,
`docs:`, `refactor:`, `test:`, `chore:`, `ci:`, `perf:`. A scope is encouraged —
`fix(validator):`, `docs(templates):`. Imperative mood, subject under 72
characters, and the body only when the "why" is not obvious from the diff.

One concern per commit — not one file per commit, and not one session per
commit. Code, tests and documentation go in separate commits, because `git
bisect` and `git revert` only work as advertised on atomic ones. The existing
history is the reference: a fix, then the test that pins it, then the DEC note
that explains it.

The pull request template's checklist is the set of gates a reviewer would
otherwise have to re-derive. Fill it honestly — a checked box that is not true
costs more than an unchecked one.

---

## Cutting a release

For whoever holds the tag. The changelog is written continuously in
`Unreleased`; a release is mostly a rename.

1. Classify everything under `Unreleased` by the table above and pick the tier
   from the highest single entry.
2. Rename the heading to `## [X.Y.Z] - YYYY-MM-DD` with today's date, ISO 8601,
   ASCII hyphen — that exact shape is what changelog parsers match.
3. Open a fresh, empty `## [Unreleased]` above it.
4. Update the link definitions at the bottom: point `[Unreleased]` at
   `compare/vX.Y.Z...HEAD` and add `[X.Y.Z]` pointing at `releases/tag/vX.Y.Z`.
   Do not add a tag link before the tag exists — a changelog that ships a 404 is
   an odd advertisement for a repository that enforces link integrity.
5. Commit, then tag `vX.Y.Z` on that commit.
6. Publish the GitHub release using that changelog section as its body, so the
   two cannot drift.
