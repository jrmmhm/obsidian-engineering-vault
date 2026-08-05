---
domain: DEC
id: DEC-MTH-022
created: 2026-08-05
last-verified: 2026-08-05
---
Date: 2026-08-05
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-05 — The gate says which code stopped firing (Accepted)".

## Context

Issue #26, residual 2 of amendment 2026-08-01. `hook_stop` compares each
finding of the current run against the file's git HEAD baseline and
blocks on `cur[f.code] > base.get(f.code, 0)`. The loop iterates the
findings that *exist*. A code standing in the baseline that produces no
finding at all is therefore never reached by it — not to block, and not
to be mentioned either, because the pre-existing branch below it
(`elif f.sev == "ERROR"`) is equally unreachable for a code that no
longer fires.

Reproduced before touching anything: an ARC file committed with `##
Kontext` carries `template-sections` in its baseline; the session repairs
the heading; the stop gate emits a report that does not contain the code,
the file, or any hint that something changed. The session ends green and
silent.

That is correct for the case it was built for — repairing a defect must
not block — but the same silence covers a change that makes a check stop
*reaching* the file. Amendment 2026-08-01 removed the concrete instance
(a stray fence marker silencing `req-nnn`); this is why that instance was
invisible rather than merely wrong, and the blind spot survived the fix.

## Options

**Whether the report blocks.**

- **A — block, treating a vanished code as suspicious until explained.**
  Rejected. From counts alone a repaired defect and an unreachable check
  are the same absence, and this layer's standing rule is to report
  wherever it cannot tell a mistake from an intention — the same ground
  on which the vault-wide findings never block. Blocking would punish
  precisely the session that fixed the ERROR the gate asked it to fix.
- **B — report (chosen).** What the issue argues for.

**What counts as "stopped firing".**

- **C — every decrease, `base > cur`.** Rejected on measurement.
  `link-unresolved` is an ERROR under `strict=True` (`check_links`), the
  baseline and the stop run are both strict, and links resolve against
  the *worktree*. A session that creates any link target anywhere lowers
  the count in a file nobody edited: measured `{'link-unresolved': 2}` →
  `{'link-unresolved': 1}` on a committed file whose content was
  untouched. Under the phased creation order that is the ordinary
  mid-pass state, so the channel would be noise on arrival — the same
  noise the aggregated link WARN of amendment 2026-07-28f exists to
  suppress one layer up.
- **D — full disappearance only, `n → 0` (chosen).** Asks a yes/no
  instead of comparing counts, for the reason `has_domain_files` does:
  a count changes at whatever unrelated edit tips it, while "does this
  code still fire" is the question the session can actually answer.

**Where the report is emitted.**

- **E — into `summary` before the blocking branch**, so a blocking
  session sees it too. Rejected: `summary` is appended to the block
  reason, and a block reason carries one obligation. A second,
  non-blocking observation inside it spends one of the two allowed block
  attempts on legacy drift — the same finding an adversarial review made
  about vault-wide ERROR lines in amendment 2026-07-28f.
- **F — after the blocking branch, beside the vault-wide advisory
  (chosen).** The branch returns before reaching it, so the report is
  structurally incapable of entering a block reason. No rule has to be
  remembered for it to hold.

**Which fixture proves it.**

- **G — reuse the existing encoding-repair session (`SIDF`)**, which
  already contains a real `1 → 0`. Rejected on measurement: that file's
  baseline carries three codes, not two — `{'encoding-not-utf8': 1,
  'frontmatter-missing': 1, 'template-sections': 1}` — and
  `frontmatter-missing` disappears as an artifact of the misread rather
  than as a fix. The fixture would also bind issue #26's only positive
  test to issue #31's fixture, so re-committing that file as UTF-8 would
  silently retire it.
- **H — an own committed file and an own session (chosen).** Eight lines
  in the git-backed identity vault, which already exists.

## Decision

B, D, F and H. `hook_stop` collects, per touched file, the baseline codes
with `cur[c] == 0`, and appends one line per file to the non-blocking
session report after the blocking branch, capped at 15 lines like the
vault-wide block. `SIDF` keeps its original assertion in a form that
still fails against the regression it was written for.

## Justification

### Design points

- **Neither the header nor the lines begin with `ERROR` or `WARN`.** A
  rendered `Finding` and a code being reported as gone would otherwise be
  indistinguishable to a reader and to every assertion in the suite,
  which is how the old `SIDF` assertion came to forbid exactly what this
  issue requires.
- **The assertion that broke is the interesting one.** `SIDF` asserted
  `! contains "$fout" "encoding-not-utf8"` — the repaired file must not
  still be reported as non-UTF-8. Since this change the code name also
  appears in the report of what stopped firing, so the assertion had to
  move to the finding's *message* (`this vault is UTF-8`), which no
  disappearance line carries. It was not anchored to `^ERROR` instead,
  although that was the first proposal: a blocking stop hook emits one
  `json.dumps` line with escaped newlines, where `^` can never match, so
  the anchored form would have passed vacuously on the issue #31
  regression it exists to catch. The adversarial review found this; it
  was measured against a real block line before the wording changed.
- **Three wrong implementations, three distinct assertions that kill
  them.** Verified by mutation, each run against the full suite: the
  feature removed entirely fails the two positive assertions; echoing the
  whole baseline fails the unchanged-file control (`SIDR`); reporting
  decreases as well as disappearances fails the partial-decrease control
  (`SIDH`). A negative control that no mutant can kill is decoration, and
  the first version of `SIDH` was exactly that.
- **The partial-decrease fixture asserts its own baseline first.**
  `hook_post` validates the HEAD *content* against the *current* file
  set, so a link target created before the baseline is taken never counts
  as unresolved in it. Written in the natural order — create the target,
  then touch the file — the baseline is already 1 and the fixture proves
  nothing. It now pins `"link-unresolved": 2` in the state file before
  creating anything.
- **No `try/except` shield, unlike the vault-wide block.** The collection
  is dict arithmetic on data the loop has already loaded plus the same
  `relative_to`-with-fallback that both `hook_post` and `Finding.render`
  perform on every line. It adds no I/O and therefore no new way for an
  advisory to crash the gate into exit 2, which would release it.
- **The wording asks, and says why the answer is not free.** "say which
  of them you fixed; a check that became unreachable looks exactly the
  same" — a bare list invites the reader to assume the good case, which
  is the assumption that made this defect invisible for the whole of
  amendment 2026-08-01.

## Consequences

### Accepted residuals (documented, not solved)

1. **The report may reach nobody at all** — issue #44. The current hook
   documentation states that plain stdout of a Stop hook exiting 0 goes
   to the debug log and is shown neither in the transcript nor to Claude.
   `hook_stop` emits its entire session report that way, and
   `stop_gate.sh` passes it through. If that is accurate, this amendment
   adds one more line to a channel that already carried the fail-open
   ERROR report and the vault-wide advisory unread. It is deliberately
   not fixed here: the defect predates issue #26, affects every advisory
   the gate emits, and amendment 2026-07-28f recorded the opposite as a
   verified fact — which means the question needs a live probe, not a
   third reading of the docs.
2. **Deletion, rename and move stay invisible.** A file deleted this
   session is skipped by `if not path.exists(): continue`; a renamed one
   arrives under a new key, has no blob at HEAD, and is recorded as
   `new: True` with an empty baseline. Neither operation fires the
   PostToolUse hook at all, whose matcher is `Edit|Write|MultiEdit`. The
   likeliest ways to make a check unreachable are therefore still the
   ways this report cannot see, and `id-vanished` remains the only signal
   for the identifier half of it.
3. **The baseline is HEAD, not the start of the session.** In a dirty
   worktree — an unpushed branch, a Syncthing peer mid-sync — the first
   touch of a legacy file reports every code an *earlier* session already
   repaired as though this one had done it. The same baseline already
   carries the blocking decision, so this is a property of the ratchet
   rather than of this report, but the report is the first thing to state
   it out loud.
4. **A code can disappear for a reason that lies in another file.**
   `Vault.templates_for` reads the templates of every folder of an
   abbreviation, so creating a second domain folder can retire
   `template-sections` in a file nobody edited; `verifies-unknown-req`
   depends on the worktree's requirement index the same way. Choosing
   `n → 0` removes the frequent instance of this class, not the class.
5. **Counts are not the only possible signal.** Whether a check still
   *reached* the file is mechanically knowable — `check_sections` returns
   early when a domain has no readable template, and that is one of the
   real unreachability paths. Carrying a reachability flag out of the
   checks would answer the question this report can only ask, and it
   costs a return-value change in `check_sections` and `check_req_table`.
   Out of scope under "minimum change"; named here so the next reader
   does not have to rediscover that counts were a deliberate floor.
6. **Only files in `touched` are examined**, which is the secondary half
   of issue #26 and unchanged: an edit to a REQ file that invalidates a
   `verifies:` entry on a TAE file still surfaces only in the next full
   run.

### Realization

- `validate_vault.py` — `hook_stop` collects `resolved` per file and
  emits it after the blocking branch; nothing else changed, and the CLI
  is untouched (the shipped template vault stays at 0 errors and 9
  warnings)
- `tests/run.sh` — two committed files in the identity vault
  (`ARC_Resolved.md`, `ARC_Linker.md`), sessions `SIDG` and `SIDH`, the
  unchanged-file control on `SIDR`, the naming assertion on `SIDF` and
  its rewritten encoding assertion; 226 to 232 assertions
- `SKILL.md` — the enforcement section names the new report line

Observed at the real entry point, on a throwaway repository whose HEAD
carries the defect:

    baseline recorded from git HEAD: {'codes': {'template-sections': 1}, 'new': False}

    vault validator session report:
    codes that stood at HEAD and did not fire this session (say which of
    them you fixed; a check that became unreachable looks exactly the same):
    00_documentation/01_projectvault/03_architecture_(ARC)/ARC_Demo.md [template-sections]

The same session against the code before this branch prints an advisory
block about a stub and nothing else.
