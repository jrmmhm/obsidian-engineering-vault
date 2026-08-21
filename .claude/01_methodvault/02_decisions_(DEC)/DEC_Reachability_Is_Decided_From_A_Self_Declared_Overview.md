---
domain: DEC
id: DEC-MTH-051
created: 2026-08-21
last-verified: 2026-08-21
---
Date: 2026-08-21
Status: Accepted

## Context

**This note decides two instances of one defect, and either can be entered
from here.** The first is reachability: which file is the vault's entry
point, and what it takes for an ARC module to be reachable from it. The
second is the section contract: which template a file was written from, and
therefore which sections it owes — the half that
[[DEC_One_Abbreviation_One_Folder_By_Rule]] points at, decided under
*Decision*, "A file is held to every contract it claims", and priced in the
Consequences bullet on `check_sections`. In both the tool answered a
structural question by guessing, and where the guess failed it went quiet
instead of saying it could not tell. Both are answered the same way: the
guess is replaced by a declaration the file itself carries, and the case
that cannot be answered is given a voice.

[[DEC_Language_Independent_Recognition_And_VCS_Tier]] left
`system_overview.md` hardcoded twice as its residual 2 and named the fix as
follow-up 5. [[DEC_The_Strict_Zone_Opens_In_Every_Template_Language]] closed
the References/Sources half of that residual; the file-name half stayed open.

Measured on a derived German vault whose overview is `Systemuebersicht.md`:
16 ARC modules, 0 `arc-not-in-overview` findings, because the scan resolves
one literal path and returns when it does not exist. The hub link budget is
the same decision a second time. It costs that vault nothing today - its
overview carries six links - and it is live in this repository, where
`01_methodvault/system_overview.md` reports `51 outgoing links > 50` and owes
the 50 to its English file name.

The third defect was not in the issue. `arc-not-in-overview` demands that
every ARC file appear in the overview, while `vault_schema.json` declares
that ARC-to-ARC containment is authored in the submodule table of the
main-module template and nowhere else ([[DEC_Two_Declared_Relations_Get_A_Source]]).
The same vault adopted that table on 2026-08-21: `ARC_userver.md` carries
twelve submodules and the export shows twelve `contains` edges. Eleven of
them would be reported as documentation islands by a rule that reads the
overview alone - for modules whose parent lists them in the very table the
schema prescribes.

All three are one class: a check that opts out without a word. That is what
this note decides against, and the reason it adds two findings that say a
check did not run rather than letting silence stand for a clean result.

## Options

- **A - A tuple of spellings in the skill**, the pattern
  [[DEC_The_Strict_Zone_Opens_In_Every_Template_Language]] used for the
  reference sections. Rejected: a domain folder carries its abbreviation in
  parentheses and a template carries the Latin root `template`, so both are
  per-language vocabularies with a closed shape. An overview file name is a
  per-project choice - `Systemuebersicht.md`, `Overview.md`, `00_map.md` -
  and a derived project could only extend the tuple by forking the skill,
  which `discovery.rejected_override` reserves for a project that needs
  different rules.
- **B - A per-vault configuration file naming the overview.** This is the
  dominant practice elsewhere: Sphinx `root_doc`, Antora's `nav` key in
  `antora.yml`, Doorstop's `.doorstop.yml`, DITA's root map as the
  processor's input. Rejected on three grounds. This method has exactly one
  configuration artefact and `discovery.rejected_override` decided there is
  no project layer. That artefact is vendored byte-identically into every
  derived project, which `--check-install` and the re-vendoring procedure
  exist to keep true ([[DEC_A_Session_Runs_The_Skill_It_Loaded]]); a
  project-specific file name in it makes the copies differ by construction
  and the first re-vendoring that forgets one hand-edited line silently
  reverts another project's configuration. And in each of those tools the
  configuration is required to build at all, so it cannot quietly go stale -
  here it would point at a renamed file and rebuild this defect one level
  further out.
- **C - A marker in the file (chosen).** The frontmatter key `vault-role`
  with the value `system-overview`, on a file in the vault root. The method
  answers "what is this file" from inside the file everywhere else -
  `domain`, `id`, `verifies`, the DEC `Status` line - and the identifier
  scheme states the principle outright: identity lives in the file, not in
  its name. Sphinx's file-wide `orphan` field is the shipped precedent for a
  marker inside a document carrying a claim about its place in the
  navigation; StrictDoc's `ROOT` is the same form with a different meaning
  and is named here so it is not read as more support than it is.
- **D - One-hop membership**: reachable means named by the overview or named
  as a submodule by any ARC file. Rejected on the adversarial review's
  evidence: `build_graph` adds a submodule edge with no `dst != key` guard,
  so one row naming a file inside its own submodule table silences that
  file's finding forever, and two modules naming each other silence both.
  Sphinx ships exactly this rule - `check_consistency` compares against a
  flat set of every document any toctree names - and its documented
  consequence is that an unreachable subtree keeps its children quiet.
- **E - Any mention in the root layer, and any mention in any ARC file**,
  which needs no marker and no export. Rejected on two standing records:
  [[DEC_Coverage_Is_Decided_On_The_Graph]] removed exactly this reading from
  the coverage rule because a mention proves nothing, and
  [[DEC_Two_Declared_Relations_Get_A_Source]] separates an annotated peer
  link in a Context section from containment on purpose.

## Decision

**The system overview is the vault-root file that declares itself one.**
`vault-role: system-overview` in its frontmatter, exactly one such file per
vault; zero or several means the vault has no entry point this run.
`vault-role` and not `role`, because `role` already names the canonical
domain token in `Vault.role_of`, in `resolve_role_map` and in every graph
node.

**Reachability is transitive from that file** over ARC-to-ARC `contains`
edges. An ARC module is a documentation island when no chain of submodule
tables leads to it from the overview.

**A check that cannot run says so once.** `overview-unidentified` when no
root file carries the marker or several do; `arc-containment-unreadable`
when the containment source cannot be read at all. Both WARN and both
vault-wide. `overview-unidentified` is reported for EVERY vault, including
one whose ARC folder is still empty - the entry point decides the hub link
budget as well as the scan, so gating it on ARC content would keep a
smaller copy of the same silence. `arc-containment-unreadable` is reported
only where the scan would otherwise have run.

**The hub link budget follows the same identification** and the file name
leaves `check_links` entirely.

**A file is held to every contract it claims.** This is the second
instance, and the one the earlier record's `Corrected by:` line points
here for. `check_sections` scored a file against every template of
its domain and kept the best, which is a guess about which template the
author used; where that guess landed on a perfect match the file stopped
being measured against anything else, and an ARC file carrying the
main-module template's two sections could lose any of the seven the full
template requires in silence. A section exactly ONE template of the domain
requires is the author's own declaration of which template a file was
written from, so a file that satisfies one contract completely and carries
another's exclusive section is held to both. Only from a perfect match:
where the best template already reports, the file is measured against it
alone, as before. A domain whose templates require identical or nested
section sets has no exclusive section and is untouched - nothing there can
tell which of the two a file came from, and this note does not pretend
otherwise.

## Justification

- The three defects are one question asked three times, and a marker answers
  it once. A vault renames its overview by editing the file it renamed.
- Transitive costs nothing measurable and removes two ways to be wrong:
  measured on the derived vault, one-hop and transitive both report zero
  islands, and only transitive survives a self-naming row or a two-module
  cycle.
- The silences are the defect, not a detail of it. Measured: with the
  exporter missing beside the validator - the shape a project that vendored
  one file has - the derived vault reports the identical 118 warnings today,
  having lost a whole data source without a word.
- One WARN per vault is not the convention rollout refused by
  [[DEC_Language_Independent_Recognition_And_VCS_Tier]] and twice after it.
  Those priced 38 and 11 ERRORs demanded of files that never had the
  convention. Nothing here turns red, nothing blocks, and the remedy is one
  line in one file that the finding names.

## Consequences

- **An existing project migrates by adding one line** to its overview. Until
  it does, it gets `overview-unidentified` and no island scan, and its
  overview is measured against the ordinary link budget. The changelog entry
  names both.
- `FALLBACK_SCHEMA` declares no relations, so a vault read under it cannot
  see ARC-to-ARC containment. That is answered as "cannot say" -
  `arc-containment-unreadable` - and never as "contains nothing", which
  would report every submodule of a correctly nested vault behind a single
  `schema-unreadable` WARN.
- A vault that ships no main-module template has no place to author
  ARC-to-ARC containment, so every ARC module must be named in the overview.
  That is the rule for a vault without a hierarchy, not a regression.
- `discover_bindings` reads the templates of the winning ARC folder alone, so
  a vault mid-translation binds one spelling of the submodule section and
  reports the other spelling's submodules as islands. `domain-duplicate-folder`
  and `export-duplicate-role` already name that state
  ([[DEC_One_Abbreviation_One_Folder_By_Rule]]).
- Two ARC files sharing a basename are both counted reachable when one is
  named, and an ARC file excluded from the graph as a duplicate identifier
  looks unreachable. Both states are already reported as `duplicate-basename`
  and `id-duplicate`.
- The ARC scan builds the graph in a vault that has no requirements too,
  where only the coverage rule used to. Measured 0.12 s of a 0.68 s audit on
  a 398-file vault.
- `check_sections` holds a file to a second template of its domain only where
  the best-matching template scores `(0, 0)` - the state in which the check
  used to fall silent. This narrows, and thereby corrects, the sentence in
  `Vault.templates_for` and in [[DEC_One_Abbreviation_One_Folder_By_Rule]]
  that a template union can only be more permissive. Measured over four
  vaults and 455 domain files: no file changes its findings.

### Realization

- `validate_vault.py` - `overview_marker`, `Vault.overview_scan`,
  `Vault.overview`, `Vault.is_overview`, `export_analysis` shared by
  `allocation_index` and the new `arc_containment`, the reachability scan
  in `validate_vault_wide`, `exclusive_sections` and the rewritten
  `check_sections`, the corrected `templates_for` docstring, and the two
  literals removed from `check_links` and `validate_file`
- `vault_schema.json` - the `system_overview` entry with its two rejected
  options, `relations.contains.read_by_the_validator`, `schema_version`
  0.4 to 0.5; `FALLBACK_SCHEMA` carries the marker pair and deliberately
  not the relations block
- `tests/run.sh` - one fixture builder called in seven vault states and
  twice more against a validator without its exporter and against an
  unreadable schema, plus the twins carrying an overview each under two
  different names. Every assertion that pins a changed behaviour is red
  against the base commit, measured by running this file there
- `ARCHITECTURE.md` - the `root` row, the reachability entry of the
  vault-wide list, the contract-choice paragraph in stage 2, the shared
  export analysis, and both new codes in the index
- `SKILL.md`, the project vault's conventions file and its ARC README -
  the three places that stated the old rule
- `CHANGELOG.md` - three entries, each naming its codes, and the one line
  an existing project has to add

### This note stands above the length WARN, deliberately

It reports `length`, and it keeps doing so. The five options and the
measurements that rejected four of them are the reason the note is worth
having; a record that fits by dropping its alternatives has lost the part
CONTRIBUTING asks it to carry. Several notes in this vault already stand
above the threshold for the same reason. The threshold itself is written
in `validate_vault.py` and the count is what the validator prints, so
neither is repeated here ([[DEC_A_Volatile_Fact_Has_One_Owning_File]]).

- **A derived vault's local guard can go.** One vault wrote a guard in its
  own test suite standing in for this defect, asserting that a file
  carrying the main-module marker section also carries all seven sections
  of the full template, with a docstring saying to delete it rather than
  adapt it once the validator scores such a file against both contracts.
  It now does, and the guard is redundant for the shape it was written
  for - `ARC_userver.md` carries `Zuordnung und Verifikation`, exclusive
  to the full template, and losing any of its seven is an ERROR again
  (measured: silent before, one `template-sections` after). Its second
  assertion, that the vault must contain a main module at all, is covered
  from the other side: remove the submodule table and eleven
  `arc-not-in-overview` findings appear. What is deliberately NOT adopted
  is its stricter direction - a note that is only a main module owes two
  sections, not seven, which is what the ARC README defines and what the
  guard's own docstring calls deliberate over-strictness while the
  validator is blind. Deleting it is that vault's call to make.

### Accepted residuals (documented, not solved)

1. **The overview is read as text, not as links.** A module named in a
   sentence counts as named, which is what the check has always done and
   what its message says. Narrowing it to wikilinks would add findings and
   belongs to its own issue.
2. **`allocation_index` keeps its own silence.** It shares the one analysis
   this note caches, so the WARN above now explains its None as well - but
   the third answer it gives the coverage rule is unchanged and still says
   nothing on its own.
3. **`SKILL.md` still names the file three times.** Its rule 7 was
   corrected; a phase list, a checklist entry and a closing question still
   read "system_overview.md (new ARC modules)". They are understated
   rather than wrong - a submodule belongs in its parent's table - and the
   file was rewritten by another change on the same day, so the scope of
   this one was held to the single sentence that stated the rule. The
   remaining three are a follow-up, not a decision.
4. **The rule is keyed on the literal ARC abbreviation**, in
   `vault.domains.get("ARC")` and in the `hub` argument for a domain file.
   No language the alias map knows spells it differently, which is the
   same argument `check_fence` rests on and the same residual: an alias
   that ever mapped another token to ARC would switch this rule off
   without a word.
