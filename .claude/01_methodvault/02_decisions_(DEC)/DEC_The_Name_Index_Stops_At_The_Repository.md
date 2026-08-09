---
domain: DEC
id: DEC-MTH-044
created: 2026-08-09
last-verified: 2026-08-09
---
Date: 2026-08-09
Status: Accepted

## Context

`Vault._build_name_index` builds the two indexes every wikilink is resolved
against, and the one `duplicate-basename` is decided on, by walking
`self.doc_root` — the parent of the vault root. In the canonical layout that
parent is `00_documentation`, it holds `01_projectvault` beside
`02_documents`, and the walk stays inside the repository working tree.

A derived project may version the vault alone, and then the vault root IS the
repository root. [[DEC_Language_Independent_Recognition_And_VCS_Tier]]
(DEC-MTH-003) already named that shape, and `git_root` was written for it. The
name index never learned it: `doc_root` is then whatever directory the
repository happens to sit in, and the walk leaves the working tree.

Measured on a real vault of that shape: run in place it indexes 378 files, 53
of them outside the repository. The same commit as an isolated clone indexes
322 files and none outside it. Same content, two different indexes — a link
resolves or fails depending on what sits next to the checkout, and in a
`git worktree` below a scratch directory the walk reaches that whole
directory.

Both findings the index feeds name a folder that only one of the two layouts
has: "does not resolve to any file under 00_documentation" and "exists Nx
under 00_documentation".

## Options

- **A — `git_root() or doc_root`.** Rejected on measurement. In the canonical
  layout the repository root is the *wider* directory: it holds `50_sources`,
  `20_software` and the rest beside `00_documentation`. The index there holds
  49 files today, all below `00_documentation`; option A raises that to 171
  and its `duplicate-basename` count from one to five. It closes the leak by
  opening a wider one.
- **B — Always the vault root.** Rejected: it drops the collision between
  `01_projectvault` and `02_documents` that the canonical layout reports
  today, and that `tests/run.sh` pins on the derived project as its one
  expected WARN. That collision is a feature — two files of one name, one of
  them not linkable.
- **C — Scope by `git ls-files` rather than by directory.** Rejected: it
  needs a subprocess per run, it answers nothing where there is no
  repository, and an untracked file in the working tree is a file Obsidian
  resolves links to. The boundary is the working tree, not the index.
- **D — The narrower of `doc_root` and the repository, falling back to the
  vault root (chosen).**

## Decision

The name index is scoped to `Vault.index_root()`: `doc_root` while the
repository contains it, `self.root` once it does not, and `doc_root` again
when there is no repository at all.

The second branch returns the vault root rather than the path git printed,
and that is deliberate. `doc_root` and the repository root are both ancestors
of the vault root, so they always lie on one chain: the only way the
repository can fail to contain `doc_root` is if it IS the vault root. In the
honest case the two are the same path, and in the dishonest one — `GIT_DIR`
or `GIT_WORK_TREE` set in the environment, a spelling git prints differently
from the resolved path this class holds — the fallback lands on the vault
itself instead of on a foreign tree. Subprocess output decides a branch here;
it never becomes a search root.

The boundary can therefore never be wider than `doc_root`, which is what
keeps the canonical layout exactly as it was.

`doc_root` and `project_root` are unchanged, and `check_paths` keeps
resolving artifact pointers against `project_root` and its parent as
[[DEC_One_Project_Path_Definition_In_Both_Zones]] (DEC-MTH-007) decided. A
pointer to `20_Software/...` names a real artifact of the project, and a
vault repository that does not carry it is not evidence that it is gone. That
is why an in-place audit and an isolated checkout of one commit still differ
in their `path-missing` findings — measured, 138 against 158 warnings, all 20
of the difference `path-missing`. What becomes location-independent here is
the name index, not the whole report.

Both messages name the boundary as a path relative to `project_root`. In the
canonical layout that renders `00_documentation`, so the sentence every piece
of shipped documentation quotes stays the sentence the validator prints; in
the other layout it renders the vault's own path instead of a folder the
project does not have.

## Justification

- A wikilink is a promise the repository has to keep. A file outside the
  working tree can be moved, renamed or never cloned, and a link resolved
  through it is resolved against something the next reader will not have.
- The defect was silent in both directions: a link that should have been
  reported stayed quiet, and a collision that existed only on one machine was
  reported as a defect of the vault.
- The boundary is never wider than before, so no vault can gain a
  `duplicate-basename` it did not have. It can lose links that only ever
  resolved through a neighbour of the checkout, which is the point.
- A message naming `00_documentation` in a vault that has no such folder
  sends the author to a directory that does not exist.

## Consequences

- `validate_vault.py` gains `Vault.index_root()`; `_build_name_index` walks
  it, and the two messages render it relative to `project_root`.
- A vault-at-repository-root project can gain `link-unresolved` findings for
  links into a neighbour of its checkout — an ERROR in a full run, because
  `run_full` reads links strictly. Measured on the vault of that shape this
  method is developed against: zero such links today. The same holds for the
  parking lot of [[DEC_A_Project_Starts_With_Three_Domains]] (DEC-MTH-041):
  it lives under `00_documentation` and stays inside the boundary in the
  canonical layout, and falls outside it only where the project versions the
  vault alone — where it is genuinely absent from a clone.
- Accepted residual: a vault-at-repository-root layout **outside** version
  control keeps the old boundary and can still walk a large parent tree.
  There is no repository to clamp to, and inferring one from directory names
  would undo DEC-MTH-003's language-independence. The VCS tier decides here,
  as it does for the HEAD baseline.
- Accepted residual, unchanged by this record: the boundary is a directory,
  not a tracked-file set, so git-ignored state inside the working tree stays
  in the index. This is residual 7 of
  [[DEC_The_Decision_Log_Moves_Into_A_Vault]] (DEC-MTH-032) for the method
  vault, whose `doc_root` is `.claude` and lies inside the repository.
- `export_traceability.py` is unaffected: it reads neither name index and
  neither root, and walks the vault root itself.
- `tests/run.sh` gains a fixture in the vault-at-repository-root layout, the
  first that depends on git recognition rather than on its absence.
