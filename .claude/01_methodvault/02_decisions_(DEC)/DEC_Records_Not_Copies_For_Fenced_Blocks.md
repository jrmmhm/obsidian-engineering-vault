---
domain: DEC
id: DEC-MTH-008
created: 2026-07-28
last-verified: 2026-08-05
---
Date: 2026-07-28
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-07-28f — Records, not copies: fenced blocks whose source is not a file here (Accepted)".

## Context

`check_leaks` reported every fenced block in `IMP` or `ARC` as an ERROR.
The rule it enforces is stated three times in the method — `SKILL.md`
rule 4, the content-boundary table, and `00_IMP_README.md` — and it
protects a real, measured property: 28.9 % of the 1000 most popular
GitHub projects carry at least one outdated code reference in their
documentation (arXiv 2307.04291), most of 3000+ projects do at some
point in their history (arXiv 2212.01479), and inconsistent code/comment
changes are ~1.5× more likely to lead to a bug-introducing commit
(arXiv 2409.10781). A copied snippet drifts against its original; a path
cannot.

The rule was written for a project whose artifacts are files in the same
repository — `00_IMP_README.md` illustrates it with `Messplatine.kicad_sch`
and `Gehäuse.step`. A vault documenting a distributed system has
artifacts that are not files here and never will be. Measured on the
homelab vault: 185 fenced blocks in 43 `IMP` notes and one `ARC` note,
1282 content lines, most of them a single operator command against a
host under a comment saying what it establishes or proves, plus
directory trees and command output — the state of a filesystem on
another machine. About five are genuine excerpts from a script.

For those the rule has no destination, so every route out of it costs
something: pointing at a source file works only where one exists;
moving the command to `OAU` splits one fact from its proof; indenting by
four spaces or converting to inline code renders identically and evades
the rule while remaining a copy; deleting removes the operational
knowledge the vault exists to hold. The downstream vault decided this
locally (`ENT_IMP_Betriebskommandos`, Accepted 2026-07-28, option C)
with an explicit clause to re-evaluate if this repository decided
otherwise. It now has.

This is the content half of the assumption whose path half was amendment
2026-07-28e: that everything a note refers to is an artifact of this
project, resolvable under `project_root`.

## Options

- **A — Lift the ban in `IMP`, keep it in `ARC`.** Cheapest. Rejected:
  it discards the measured property outright and legalises exactly the
  five genuine script excerpts, which are the blocks that can actually
  drift.
- **B — A declared exemption alone** (`host=<machine>` on any block,
  the ban otherwise unchanged). Rejected after an adversarial review
  measured what it would do to the corpus: appending the attribute is
  the cheapest possible response to every one of the 127 remaining
  ERRORs, so the first users of the exemption would be the copies —
  `IMP_userver_YT-DLP_Del_Script.md:40`, 23 lines of CLI against a
  script named two sections above it, is the concrete case. An exemption
  that is the path of least resistance for everyone documents nothing.
- **C — Length decides whether the question is asked, a declaration
  answers it (chosen).** Up to `FENCE_RECORD_MAX` content lines a block
  is a single observation and is silent. Above it, the block either
  gives way to a path (ERROR `code-fence`) or names the machine it is
  true on (WARN `fence-record`). Length is the only signal correlating
  with drift risk that costs the author nothing, and it makes the
  declaration rare enough to be conspicuous: 9 blocks vault-wide rather
  than 127.
- **D — A tenth domain owning operator records.** Rejected: a convention
  rollout across two production vaults, and every authoritative
  definition of a runbook (AWS Well-Architected "a series of steps … to
  achieve a specific outcome", Google SRE's per-alert playbook, Azure
  WAF, PagerDuty) makes a single command not a procedure. Google's own
  style guide states that a one-step procedure is not formatted as a
  procedure at all.

## Decision

Option C. The ban is expressed as drift against a named source rather
than as a syntax ban on fences, and a block whose subject is a machine
this project does not own is classified as a **record**, not a copy —
ISO 9000:2015 3.8.10, "document stating results achieved or providing
evidence of activities performed", whose Note 2 states that records
"generally need not be under revision control". The same artifact class
appears as *report* in ISO/IEC/IEEE 15289 ("describes the results of …
investigations, observations, assessments, or tests"), as *snapshot* in
ITIL ("the current state of a configuration item … recorded at a
specific point in time"), and as *observation* in NIST OSCAL, which
makes its `collected` timestamp mandatory.

`OAU` keeps procedures and gains nothing here: a repeatable multi-step
workflow is a runbook, a single verification command is not, and Red
Hat's modular-documentation standard states the carve-out this needs
verbatim — a reference module may carry an action when it is "simple,
are highly dependent on the context of the module, and have no place in
any procedure module".

## Justification

### Design points

- **The threshold is measured, not chosen.** The smallest genuine script
  excerpt across both German production vaults has 16 content lines, so
  15 is the largest value that still catches every measured copy. At
  that value homelab's `code-fence` count goes 127 → 9 and PMDE's
  17 → 7; the nine survivors are the four real copies plus five
  directory trees between 17 and 77 lines, which are exactly the case
  where a declaration carries information instead of being routine.
- **The exemption is a WARN, never silence.** This project's rule is
  that a visible marker may soften a WARN and never an ERROR
  (`status: draft` relaxes nothing; `pending/planned/TBD` never silences
  the References zone). `fence-record` keeps the claim visible,
  greppable and countable. It is not an ERROR because the check cannot
  distinguish a legitimate record from a disguised copy, which is
  Clippy's stated disqualification for its deny-by-default `correctness`
  group ("should be free of false positives") and Google Tricorder's for
  a blocking check ("produce no effective false positives").
- **The declaration is read at any token position.** 23 of 127 blocks in
  homelab and 14 of 17 in PMDE carry no language at all, so "language
  first, host second" would have had no spelling for 18 % and 82 % of
  the two corpora.
- **The info string is the spec-sanctioned place.** CommonMark 0.31.2:
  the first word is typically the language, but "this spec does not
  mandate any particular treatment of the info string"; GFM discards
  further tokens and keeps the language class (spec example 113), and
  Obsidian registers code-block processors on the first word alone.
  Pandoc's braced form was rejected because `{bash}` costs syntax
  highlighting in Obsidian, which is the rendering target here.
  Verified: neither vault has any community plugin installed, so the
  plugins that parse `=` as their own parameter separator are absent.
- **Two cheaper ways out closed with it.** A tilde fence was invisible to
  every fence-keyed rule — and worse, `check_links` and `check_paths`
  then read the block's content as prose, producing two WRONG findings
  per block. An unclosed fence silenced everything below it. Both are
  now handled through one `fence_info()` definition shared by all three
  checks. Measured cost: zero tilde fences exist in either vault.
- **`check_paths` reads the declaration.** In the References zone fenced
  content is scanned and no marker suppresses anything; a declared block
  containing `deploy/20_software/...` was therefore reported as a stale
  project pointer. It is now skipped there, which is the ownership rule
  of amendment 2026-07-28e — reachable for the first time because the
  block says so instead of the validator guessing.
- **The baseline argument, stated correctly.** `hook_post` computes the
  per-file baseline at runtime from `git show HEAD:<file>` with the
  *current* validator, so a new code can perfectly well appear in a
  baseline. A stale session baseline still stays valid here for a
  different reason: the `host=` syntax cannot occur in any HEAD revision
  written before this change, and `code-fence` only ever shrinks.

## Consequences

### Accepted residuals (documented, not solved)

1. **Nothing verifies that a declared block truly has no source file.**
   The declaration is an author's claim; the validator can see neither
   the other machine nor the absence of a local original. This is
   follow-up 2 of the 2026-07-25 decision (doc-claim grep check), and it
   is why the exemption reports rather than stays silent.
2. **The machine name is validated against nothing.** Ruff's split is
   the model — RUF100 stays permissive while RUF102 checks codes against
   a declared registry, and Ansible reports an uninventoried host as a
   warning by default — but a host list is per project, and amendment
   2026-07-28d rejected the per-project schema override as a silent
   off-switch. There is no home for the registry yet; see follow-up 9.
3. **A copy short enough stays silent.** A 10-line excerpt of a file in
   `20_software/` produces no finding. Precision over recall, the same
   trade as the body path scan of amendment 2026-07-27.
4. **The four-space indented block still evades every fence rule.**
   Closing it would mean judging every indented line inside every list,
   which is a false-positive surface this project has consistently
   refused. It remains the bypass named in the 2026-07-25 residuals.
5. **`last-verified` is only a lower bound for a block's age.** With N
   records under one date, that date says when the note was confirmed,
   not when each observation was made. A per-block `captured=` was
   considered and rejected: no surveyed documentation system stamps a
   block with a date, and every freshness convention that exists
   (Microsoft `ms.date`, Google g3doc `reviewed:`, Kubernetes
   `evergreen`) keeps exactly one dated place per document. OSCAL's
   split — mandatory `collected`, optional `expires` — is the model if
   it is ever needed.
6. **`host="lab host"` is cut at the space** and yields `"lab`. Accepted
   rather than parsed: machine names do not contain spaces, and the
   value is reported in the finding, so the mistake is visible.
7. **Case-sensitive.** `HOST=` is not recognised, consistently, like the
   identifier reader of amendment 2026-07-28c.
8. **This partially adopts option C of amendment 2026-07-28e** (an
   explicit foreign-artifact syntax in the vault), for fenced blocks
   only. The 37 foreign paths written relative, residual 3 there, stay
   exactly as they were: they carry no fence and no declaration.

### Follow-ups

9. Validate the declared machine name against an inventory once a
   per-project registry has a home that is not the packaged schema —
   most likely the vault documenting its own hosts. Prior art for the
   shape: a separate, independently switchable rule (Ruff RUF102),
   warning severity (Ansible `HOST_PATTERN_MISMATCH`), and an empty
   registry meaning "passes" (commitlint `scope-enum`).
10. Re-measure the threshold when the German vaults have finished their
    fence work. It is calibrated on a corpus that is being actively
    restructured, and the smallest genuine excerpt may move.

### Realization

- `validate_vault.py` — `FENCE_RE`, `FENCE_HOST_RE`, `FENCE_RECORD_MAX`,
  `FENCE_BANNED_DOMAINS`, `FENCE_EXEMPT_DOMAINS`, `fence_info()`,
  `fence_host()`, new `check_fence()`; `check_leaks` restructured to
  measure a block instead of reporting its opening line, and to evaluate
  an unclosed fence to EOF; `check_links` and `check_paths` share the
  one fence definition, and `check_paths` skips a declared block in the
  References zone
- `tests/run.sh` — now 101 assertions: the precision vault gains an IMP
  note whose artifacts live on another machine (its zero-findings
  assertion is what proves both the silence of short blocks and the
  References-zone skip); the violation vault gains a long bare block, an
  empty `host=`, a declared long block with the file-scoped negative
  that it produces no `code-fence`, a tilde fence, an unclosed fence,
  and a second, declared fence in `ARC_Leaky.md` that must still fail
- `vault_schema.json` — `code_fences` with the domain lists, the
  threshold and its provenance, the declaration form and its spec
  basis, the three codes with their severities, and what stays
  unenforced
- `SKILL.md` rule 4 and the content-boundary table,
  `00_IMP_README.md` (new section "Artifacts on Other Machines"),
  `00_documentation_file_creation_and_conventions.md` (the content half
  beside the path half)

Measured after the change, old vs new validator in the same run pair:
template vault unchanged at 0 errors / 9 warnings; homelab 127 → 9
errors with all 112 warnings and every other finding code identical;
PMDE 414 → 404 errors, `code-fence` 17 → 7, warnings unchanged at 96.
`code-fence` is the only code that moves anywhere. `tests/run.sh` at
101 tests, 0 failures.
