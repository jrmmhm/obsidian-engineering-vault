---
domain: DEC
id: DEC-MTH-011
created: 2026-08-01
last-verified: 2026-08-05
---
Date: 2026-08-01
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-01 — One fence definition for both tools (Accepted)".

## Context

Issue #20. `check_req_table` iterated every line of a REQ file and called
`parse_table_row` on it with nothing tracking fence state, so a
requirement table quoted inside a ```` ```markdown ```` block — the
ordinary way to show a reader what a malformed row looks like — was read
as data. Reproduced on a REQ file documenting its own table format: three
blocking ERRORs about the quoted row, and a fourth, `req-duplicate`,
blaming the real requirement below it for colliding with the quotation.

Two more readers count requirement rows the same way, which the issue did
not name: `Vault.req_index`, whose result decides `verifies-unknown-req`
and `req-uncovered`, and the global duplicate scan in
`validate_vault_wide`. Measured on the same file, the index resolved
`REQ-DOC-001` to the line inside the fence rather than to the real row,
so a quoted example could satisfy a TAE `verifies:` entry and mask a
genuine ERROR.

This is residual 1 of amendment 2026-07-31b — the exporter and the
validator disagreeing about how many requirement rows a vault has —
observed from the other side.

## Options

**Which fence definition the requirement-row readers use.**

- **A — the toggle `fence_info` already provided.** What issue #20 asks
  for literally, and cheap. Rejected on measurement: it moves the
  boundary on a four-backtick block and on a ` ``` ` inside a `~~~`
  block, which are exactly the shapes a file documenting fenced content
  contains. This repository's own conventions file carries the first one,
  so the fix would have failed on the corpus it ships with.
- **B — a second, CommonMark-correct tracker local to the requirement
  readers.** Rejected: two definitions inside one tool is the defect
  being fixed, restated one level down.
- **C — the exporter's rule as the one primitive every check uses
  (chosen).** `export_traceability.fenced_mask` already implements
  CommonMark 0.31.2 correctly. Promoting it makes "no two checks can
  disagree about where a block starts" true across both tools rather
  than within one, which is the only reading under which residual 1
  closes.

**How much of the validator changes.**

- **D — `check_req_table` alone**, the issue's literal deliverable.
  Rejected on measurement: it removes the four findings and leaves the
  index pointing into a fenced block.
- **E — every place a requirement row is counted (chosen).** One reader,
  `req_rows`, for `check_req_table`, `Vault.req_index` and the global
  duplicate scan.

**What an unclosed fence means for a requirement table.**

- **F — treat the block as running to EOF and drop the rows**, which is
  what the mask says. Rejected, and measured before rejecting: three
  backticks anywhere above a table then buy unconditional exemption from
  `req-class`, `req-nnn`, `req-criterion` and `req-duplicate`, all four
  of which reach the stop gate's blocking set. `check_leaks` already
  refused this trade in writing.
- **G — read the file as if it carried no fence at all (chosen).** The
  quoted rows are reported again, which is a loud false positive rather
  than a silent loss, and the file renders visibly broken in Obsidian
  either way.

## Decision

C, E and G. `fence_blocks` returns every block as `(open_line, info,
body_lines, close_line|None)`, `fence_mask` derives per-line flags from
it, and `check_leaks`, `check_links`, `check_paths` and `req_rows` are
its only consumers. `fence_info` is gone; `fence_host` still reads the
info string the block records.

## Justification

### Design points

- **Measured before deciding, in both directions.** Across all seven
  vaults on this machine (726 Markdown files), the old and the new fence
  definition disagree about exactly one line — line 196 of this
  repository's own `00_documentation_file_creation_and_conventions.md`,
  inside the four-backtick block that documents the `host=` syntax — and
  no finding hangs on it. Running both validators over all seven vaults
  at the same moment produces identical finding *sets*, not merely
  identical counts: 0 gone, 0 new, everywhere. The change is neutral on
  what exists and only removes a failure mode that nothing bounded.
- **Parity is asserted, not intended.** Two copies of one rule drift;
  that is what residual 1 was. `tests/run.sh` now compares
  `validate_vault.fence_mask` against `export_traceability.fenced_mask`
  on every Markdown file every fixture builds plus the shipped vault, and
  refuses to pass if the fixtures shrink below 50 files.
- **The unclosed fence is answered differently in two places, on
  purpose.** `check_leaks` judges such a block on its body to EOF, because
  the question there is whether a long copy exists. `req_rows` ignores
  fences entirely, because the question there is whether a requirement
  exists, and the answer must not become "no" by accident.
- **The positive control is the assertion that matters.** Asserting that
  a quoted row produces no finding is also satisfied by a check that
  stopped working, so the same rows appear unfenced in a second file and
  must produce all four findings.

## Consequences

### Accepted residuals (documented, not solved)

1. **`check_req_table` switches itself off when the canonical header only
   appears quoted** — issue #25. `header_ok` is set by the header row and
   by nothing else, so a REQ file whose real table drifted from the
   template header and whose only canonical header sits inside a quoted
   block is now read and then not checked. Measured: no REQ file in any
   of the seven vaults depends on this today. The same file without the
   quoted block was equally unchecked before this change; what is new is
   that the accident which covered one instance is gone.
2. **The stop gate does not notice when a session makes ERRORs
   disappear** — issue #26. `hook_stop` blocks on `cur > base` with no
   lower bound, so a file whose findings stop firing ends the session
   green and unmentioned. That is why residual 1 and option F would have
   been invisible rather than merely wrong.
3. **The rule still lives in two files.** The parity assertion makes
   drift a test failure rather than a silent divergence, but the
   exporter importing the primitive from the validator was not done here:
   amendment 2026-07-31b states that the exporter imports from the
   validator and is never imported by it, and reversing that direction is
   not this issue's to decide.

### Realization

- `validate_vault.py` — `FENCE_RE` to the CommonMark shape, `fence_blocks`,
  `fence_mask`, `req_rows`; `fence_info` removed; `check_leaks`,
  `check_links`, `check_paths`, `check_req_table`, `Vault.req_index` and
  the duplicate scan in `validate_vault_wide` converted to them
- `tests/run.sh` — three REQ files in the violation vault (a quoted
  table, the unfenced positive control, a stray unclosed fence), the
  index assertion that the real row is the one addressed, the cross-tool
  mask parity assertion, and the assertion that fixture 7's quoted row is
  invisible to the validator and the exporter reading the same vault;
  144 to 153 assertions

Measured after the change, all seven vaults on this machine at the same
moment, as finding sets rather than counts:

| vault | errors | warnings | findings gone | findings new |
| --- | --- | --- | --- | --- |
| homelab | 9 | 115 | 0 | 0 |
| htwsaar | 0 | 9 | 0 | 0 |
| template | 0 | 9 | 0 | 0 |
| photon | 0 | 9 | 0 | 0 |
| PMDE | 398 | 102 | 0 | 0 |
| realitypatches | 13 | 15 | 0 | 0 |
| verdantia | 0 | 9 | 0 | 0 |

The template vault is unchanged at 0 errors and 9 warnings, and
`tests/run.sh` runs 153 assertions with 0 failures.
