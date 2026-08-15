---
domain: DEC
id: DEC-MTH-047
created: 2026-08-15
last-verified: 2026-08-15
---
Date: 2026-08-15
Status: Accepted

## Context

`check_paths` promotes a dead artifact path to ERROR under an H2 whose
lowercase contains `reference` or `source`, scans fenced and backticked
content there, and ignores the pending/planned/TBD markers; `check_leaks`
exempts the same headings from the leak scan.
[[DEC_One_Project_Path_Definition_In_Both_Zones]] (DEC-MTH-007) built the
zones and left the heading names as hardcoded English substrings —
follow-up 5, a decided residual. The German template sections
(`Referenzen`, `Verweise`, `Quelle(n)`, `Kanonische Quelle`) therefore
never opened the zone: in every German vault the pointer-densest
sections carried dead paths at WARN, silenceable by a pending marker,
with fenced pointers unscanned — and the leak scan ran inside their
source sections where the English equivalent is exempt. Measured on a
German production vault on 2026-08-15: a dead path under `## Verweise`
reported `WARN path-missing` where SKILL.md promises ERROR.

## Options

- **A — Leave it dark and rename the sections to English.** The rename
  closes the gap for one vault at the price of translating every German
  vault's headings; the tooling promise ("the validator never drifts
  from the templates a project actually ships") stays broken for anyone
  who does not rename.
- **B — Extend the token tuple (chosen).** One constant,
  `REF_SECTION_TOKENS = ("reference", "source", "referenz", "verweis",
  "quelle")`, and one predicate `is_ref_section()` used by both zones —
  TEMPLATE_MARKERS' pattern, applied to headings. `referenz` is included
  now rather than deferred: it is the German template spelling itself,
  and shipping the tuple without it would fix the homelab spelling
  while leaving the template's own dark.
- **C — Derive the section names from each vault's own templates**, the
  way required sections already are. The principled endgame: it
  dissolves the token list entirely, but it changes which sections are
  strict per project and is a method change of its own scale. Not built
  here; recorded as the direction if the substring tuple ever misfires.

## Decision

Option B. One predicate for both zones, English and German spellings in
one tuple, one decision — no second migration announcement later.

## Justification

- The substring semantics are unchanged, only the vocabulary grew:
  `Resources` has always matched `source`; `Querverweise` and
  `Fehlerquellen` now match the same way. Loose on purpose — a heading
  that names sources is a sources section at any scope.
- One predicate is DEC-MTH-007's own argument one level up: two zones
  asking the question differently would disagree exactly where the
  pointer rules matter most.

## Consequences

- A German vault that was clean apart from `path-missing` WARNs in its
  reference sections gains ERRORs: the severity moves, fenced and
  backticked pointers there are scanned for the first time, and the
  pending/planned/TBD escape no longer applies. The stop gate's
  blocking set grows — the inversion of DEC-MTH-007's "the blocking set
  only shrinks"; pre-existing findings stay non-blocking through the
  per-file HEAD baseline.
- German ARC/DEC files lose `impl-leak` findings inside their
  reference/source sections — the exemption English sections always had.
- By the versioning table this is an existing WARN raised to ERROR:
  MAJOR, recorded as MINOR while the repository is at 0.x.
- Closes follow-up 5 of [[DEC_One_Project_Path_Definition_In_Both_Zones]].
- `tests/run.sh` pins `## Referenzen` in both twins, `## Verweise` with
  a pending marker, and the `## Quelle(n)` leak exemption.
