---
domain: DEC
id: DEC-MTH-021
created: 2026-08-04
last-verified: 2026-08-05
---
Date: 2026-08-04
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-04g — One abbreviation, one folder, chosen by a rule (Accepted)".

## Context

Issue #42, residual 1 of amendment 2026-08-04f ([[DEC_Two_Folders_One_Domain_Is_A_Finding]]). `Vault.__init__` writes
`self.domains[abbr] = s` while iterating `self.root.iterdir()`, so two
folders carrying one abbreviation — `03_architecture_(ARC)` beside
`03_Architektur_(ARC)` — collapse to the one the file system happens to
return last. Python states the order is arbitrary; on APFS it is hash
order, on ext4 insertion order. Two machines holding the same content
therefore index different folders, and the export measured `objects: 8`
under one creation order and `objects: 7` under the other.

German and English spell **ARC, IMP and REF identically**, so a vault
halfway through a translation carries three such pairs. This repository's
own German→English migration is exactly that state.

The exporter has reported the pair as `export-duplicate-role` since
2026-08-04f and says in the same breath that "no rule fixes it". This
amendment is that rule.

## Options

**Which of two same-abbreviation folders is the vault's.**

- **A — the first in sorted order**, the rule 2026-08-04f states for the
  two-abbreviation shape. Rejected here, and the measurement is why:
  `Architektur` sorts before `architecture` because a capital letter
  does, so in all three identically spelled abbreviations the folder a
  translation is moving *away from* wins — and a leftover folder holding
  nothing but templates wins over the folder holding the vault. Measured
  on a copy of the shipped template vault with a template-only German ARC
  folder beside the real one: `requirements 3 proven 3, relations 14`
  becomes `proven 0, relations 6`, with no finding beyond the one line
  that names the pair. Deterministically choosing the empty folder is
  worse than choosing arbitrarily.
- **B — the folder with more files.** Rejected in 2026-08-04f because it
  moves every identifier of the export a second time at whatever
  unrelated edit tips the count. The first half of that argument does not
  reach this shape: the same amendment states that one abbreviation twice
  "leaves the identifiers alone". The second half does — a count-based
  winner still oscillates on an ordinary edit.
- **C — the first in sorted order among the folders that carry at least
  one `ABBR_*.md` file; the first in sorted order overall when none does
  (chosen).** The predicate is `build_graph`'s own ingestion rule, which
  the exporter already counts with (`ingestible_count`). It flips only
  when a folder gains its first or loses its last content file — twice
  over a whole migration, at the two moments that mean something — so it
  buys B's outcome without B's instability.
- **D — index both and merge their files.** Rejected: it writes every
  already-translated file into the graph twice and reports its
  untranslated twin as uncovered, which is 2026-08-04f's option C one
  layer down.

**What the losing folder still costs.** `templates_for` reads the
templates of the indexed folder alone, so every file of the *other*
folder is checked against the winner's required sections. In the shape
this vault will actually have — German templates winning, English files
below the other folder — that is a `template-sections` ERROR on correct
files, measured as `0 errors → 1 error` on the template vault, and it
would both fail the CI audit and block the stop gate. Reading the
templates of every folder of an abbreviation removes the class outright:
`check_sections` already scores a file against each template of its
domain and keeps the best, so a union can only be more permissive.

**Severity of the new finding.** WARN. The conventions call two folders
a legitimate transitional state during a translation, and this project's
line is that a check which cannot tell a mistake from an intention
reports rather than blocks. An ERROR would also fail the CI audit
throughout this repository's own migration.

## Decision

C, plus the template union, plus a new vault-wide WARN
`domain-duplicate-folder`, one per folder that is not the vault's,
naming both folders, which one the vault reads and why, and what reading
only it costs. The rule is: **one abbreviation, one folder — the vault's
is the first in sorted order among those that carry files of that
domain.** The sort key is the NFC-normalized folder name with the raw
name as tie-break, because macOS stores a name decomposed where Linux
stores it composed, and folders reached through a symlink are deduped by
their resolved path.

## Justification

### Design points

- **The qualifier is what the adversarial review bought.** The plan under
  review said sorted-first, full stop — the rule 2026-08-04f states for
  the other shape. The review implemented it, measured it and produced
  the stub-wins case; the qualifier and the template union are both its
  findings, and both are in the fixture as assertions rather than as
  prose.
- **The template union removes an ERROR the rule would have caused.**
  `templates_for` used to read the indexed folder alone. Deterministic
  selection would then have measured every English file against the
  German templates in exactly the three abbreviations both languages
  spell alike — `template-sections` on correct files, which fails the CI
  audit and blocks the stop gate, since a newly created file has an empty
  HEAD baseline and every ERROR on it is net-new. `check_sections`
  already keeps the best-matching template of a domain, so a union can
  only be more permissive.
- **The name index is sorted for the same reason the folder index is.**
  `_build_name_index` walked `rglob` unsorted and `duplicate-basename`
  names `paths[0]`, so the finding named a different file depending on
  the file system's order — including in the shipped vault, where two
  files are called `README`. Measured across the eleven roots, this is
  the only behaviour that changed at all: four vaults report the same
  collisions on a different, now sorted-first, member of each pair.
- **A symlink is not a second folder.** `is_dir()` follows a symlink, so
  a compatibility link left behind by a rename would have been indexed
  and reported as a pair, telling the author to delete a folder that does
  not exist. `rglob` does not descend into it either, so there is no loss
  to report. Deduped by resolved path, per abbreviation: two
  abbreviations sharing one directory remain two names for one folder and
  stay visible as `export-duplicate-role`.
- **`has_domain_files` asks a yes/no, not a count.** That is what
  separates it from option B: a count changes at whatever unrelated edit
  tips it, while whether a folder holds the domain at all changes twice
  over a whole translation, at the first file moved in and the last one
  moved out.
- **One index, two tools.** `export_traceability.domain_dirs` existed to
  read the vault root a second time, because `Vault` had thrown the
  second folder away before any role was resolved. It now returns the
  Vault's index. The `OSError` fallback it carried was unreachable —
  `Vault.__init__` iterates the same root without a guard, so an
  unreadable root already exits 2 — and its removal closes the window in
  which the two reads could disagree.
- **WARN, and vault-wide.** The finding has no per-file HEAD baseline and
  therefore never enters the stop gate's blocking set. It is appended
  first in `validate_vault_wide` so it survives `hook_stop`'s 15-line cut
  of the advisory block: it is the explanation for the
  `duplicate-basename` and `orphan` findings a second domain folder
  produces around it.

## Consequences

### Accepted residuals (documented, not solved)

1. **`hook_post` still says nothing at the moment the second folder
   appears.** It reports per-file findings only — vault-wide checks are
   not run there at all — so the author learns about the pair at turn end
   or in the next full audit. Running the vault-wide pass on every write
   is the cost that decision was made against, and it has not changed.
2. **The exporter's binding discovery still reads one folder.**
   `discover_bindings` calls `template_files(vault.domains[abbr])`, so
   residual 2 of 2026-08-04f survives on the export side: the chosen
   folder's templates decide which section carries which table. It is now
   at least the folder holding the domain's files. Widening it would
   change what the graph binds, which is not this issue's question.
3. **`is_vault_root` counts folders, not abbreviations.** A directory
   with two real domains and one duplicate clears the `>= 3` bar. It
   predates this change and is unchanged by it; naming it here is the
   first time the shape is describable at all.
4. **Three or more folders under one abbreviation cost 2N−2 lines.** Each
   tool reports once per folder that is not the vault's. No vault has
   ever carried more than two.
5. **Still unmeasured on the corpus.** None of the eleven roots carries
   the shape, so the fixture and the constructed vault remain the only
   evidence that the rule does anything. The corpus measurement is a
   proof of absence.

### Realization

- `validate_vault.py` — `dir_sort_key`, `has_domain_files` and
  `pick_domain_dir` added; `Vault.__init__` keeps `domain_dirs` and
  derives `domains` from it; `templates_for` reads every folder of an
  abbreviation and labels a template with its folder where there is more
  than one; `_build_name_index` sorted; `check_domain_folders` added and
  called first from `validate_vault_wide`
- `export_traceability.py` — `domain_dirs` returns the Vault's index;
  `duplicate_role_finding` states the rule where it used to state its
  absence; the now-unused `DOMAIN_DIR_RE` import dropped
- `tests/run.sh` — the `dup_vault` fixture builds two ARC folders with
  DIFFERENT templates in both creation orders, plus the stub and symlink
  shapes; eight assertions, 217 to 225
- `vault_schema.json`, `SKILL.md`,
  `00_documentation_file_creation_and_conventions.md` — the rule where an
  agent, a reader and an author each meet it

Measured old code against new code, all **eleven** vault roots on this
machine, one disk state, as finding sets rather than counts:

| vault | findings old → new | gone | new |
| --- | --- | --- | --- |
| template | 9 → 9 | 0 | 0 |
| homelab | 123 → 123 | 0 | 0 |
| homelab/20_Software/userver-nativclaw/docs | 736 → 736 | 2 | 2 |
| PMDE | 500 → 500 | 0 | 0 |
| photon | 9 → 9 | 0 | 0 |
| htwsaar | 9 → 9 | 1 | 1 |
| realitypatches | 28 → 28 | 0 | 0 |
| verdantia | 9 → 9 | 0 | 0 |
| Archiv/Bachelor_Bruder | 100 → 100 | 3 | 3 |
| tmp/BA_Noah | 340 → 340 | 3 | 3 |
| tmp/mechdocs-test/testproject | 9 → 9 | 0 | 0 |

Every one of the nine differences is the same `duplicate-basename`
finding naming the sorted-first member of its pair instead of whichever
`rglob` reached first. No finding was added or lost anywhere, and no
vault carries a duplicate domain folder — which is why the constructed
vault below is the evidence that the rule works.

What proves the change is the runtime check. On a copy of the shipped
template vault with a template-only `03_Architektur_(ARC)` beside the
real folder, the validator prints:

    WARN .../03_Architektur_(ARC) [domain-duplicate-folder]
    '03_Architektur_(ARC)' and '03_architecture_(ARC)' both carry the ARC
    domain of this vault. '03_architecture_(ARC)' is the one this vault
    reads: the first in sorted order among the folders holding ARC_*
    files. [...] One domain, one folder: finish the translation, or
    remove the folder this vault no longer writes to

and with `Path.iterdir` forced into the adverse order, the two code
versions part company:

    old code, reversed readdir -> ARC folder used: 03_Architektur_(ARC)
    new code, reversed readdir -> ARC folder used: 03_architecture_(ARC)

The fixture shows the same thing from the other side: five of its eight
assertions fail against the code before this branch, and the two
creation orders report the `template-sections` ERROR on the German file
in one order and on the English file in the other — issue #42's
`objects: 8` versus `objects: 7`, reproduced.

The shipped template vault stays at 0 errors and 9 warnings and still
exports 3 of 3 requirements proven with no findings. `tests/run.sh` at
225 assertions, 0 failures.

A note for whoever deploys this: one finding code was added,
`domain-duplicate-folder`, nothing was renamed, and no severity changed.
A vault with one folder per domain sees exactly one difference — a
`duplicate-basename` finding may name the other file of a pair it was
already naming.
