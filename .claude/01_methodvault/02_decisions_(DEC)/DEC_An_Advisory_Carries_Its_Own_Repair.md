---
domain: DEC
id: DEC-MTH-066
created: 2026-10-18
last-verified: 2026-10-18
---
Date: 2026-10-18
Status: Accepted

## Context

**Where the repair of a git-aware advisory is written, so that an agent
in a derived project can act on it.** The three advisories of
[[DEC_Git_History_Says_Which_Notes_To_Reverify]] (DEC-MTH-060) -
`pointer-drift`, `ref-unresolved`, `pending-stale` - are printed by
`validate_vault.py`. Two of their messages pointed at the template's
conventions file for the repair: `pointer-drift` with "(conventions file,
pointer-drift)", `ref-unresolved` with "marked as it is in the conventions
file" for the forms a kept historical id may take.

A derived project carries its own conventions file and its own copy of the
skill. It updates them separately, by copying files across
(CONTRIBUTING.md, "Versioning"). The docs-4 A/B AB-T2 (2026-10-17) ran on the
kernel vault at `kernel@e94b917`: the validator there is the template's newest, and
the vault's conventions file has no `pointer-drift` passage at all (0
matches). An agent that followed the pointer found nothing. The three
treatment arms acted on the message alone; none looked the passage up.

## Options

- **A - Keep the pointer.** The conventions file stays the only place that
  states the repair. In a derived vault the pointer dangles until someone
  copies the passage across.
- **B - The message carries the repair and the accepted forms; the
  conventions file keeps the full statement.** What the validator accepts
  is written where the validator is.
- **C - Point at the skill's `REFERENCE.md`, which travels with the
  validator.** The pointer resolves everywhere, but the rule moves into the
  skill's files and the project's conventions file no longer states it.

## Decision

B. Each advisory message states its repair completely; no advisory message
points at the conventions file. The conventions file's quick reference
keeps the full statement for the human reader.

## Justification

- The message is what the agent reads at the moment it repairs. In AB-T2
  each treatment arm's next tool call after the first advisory went to the
  cited change, not to a document.
- The accepted historical-id forms are the validator's own acceptance rule
  (`marked_old`). Stated in the message, they change in the same commit as
  the code, and a test pins the text. A conventions passage can lag the
  validator by as long as a project goes without copying it.
- C keeps one owner for the text but removes the rule from the project's
  own documentation. The project vault is where its writers look for its
  conventions.
- A costs nothing in the template and fails exactly where the advisory is
  needed: in a project whose conventions file predates the advisory.

## Consequences

- `validate_vault.py`: the `pointer-drift` message drops the pointer, since
  its text already names the repair. The `ref-unresolved` message names the
  four marks and the two alternative event words.
- `tests/run.sh` pins both messages. It also checks that no advisory line
  names the conventions file; each was watched failing under the old text.
- DEC-MTH-060's statement that the repair and the forms "are the conventions
  file's" no longer holds alone. It carries a `Corrected by:` line pointing
  here.
- `pending-stale`'s message ("remove the marker or update the line") already
  carried its repair and is unchanged.
- Residual: the message and the conventions passage now state the forms
  twice. A change to `marked_old` must update both; the test catches the
  message, not the passage.
