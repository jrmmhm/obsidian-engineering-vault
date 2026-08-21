---
domain: DEC
id: DEC-MTH-050
created: 2026-08-21
last-verified: 2026-08-21
---
Date: 2026-08-21
Status: Accepted

## Context

[[DEC_Requirement_Index_Follows_The_Role_Map]] made the coverage path
role-aware and drew a line: the four blocking row-grammar codes and the
requiredness of `verifies` stay on the literal English domains, because
"only checks that read what an author actually wrote gained reach". Three
per-file checks were left behind that line by the folder abbreviation
alone, and a fourth site was never named by any record. Measured against
three real derived German vaults spelling their folders
ANF/ENT/KMP/SST/TUE/BUN:

- `check_dec_status` is gated on the literal `DEC`, so 141 decision files
  across the three vaults were never checked for a Status line, its value
  or a successor link behind `Superseded`. No record ever decided that;
  [[DEC_Language_Independent_Recognition_And_VCS_Tier]] listed it as
  residual 1 and nothing closed it.
- `check_req_table` is gated on the literal `REQ`, so 289 requirement
  rows produced no row-grammar finding. This one WAS decided, twice, and
  is the part this note overturns.
- `Vault.fields_for` keys the schema's domain profiles by the folder
  abbreviation, so a translated evidence domain gets no `verifies`
  profile at all.
- `REQ_ID_RE` is a module constant spelling the English prefix, used by
  `check_field_value` for the item type `req-row-identifier`, while
  `check_tae_verifies` builds its pattern from the vault's own
  requirements abbreviation. In a vault carrying an English
  `07_testing_and_evidence_(TAE)` folder beside `01_Anforderungen_(ANF)`,
  every correctly spelled `ANF-BAK-001` is reported as malformed by the
  format check and resolved by the reference check in the same run - the
  validator contradicting itself, at ERROR severity.

The eight `dec-status` violations that opened issue #115 were real and
are gone: that vault found them by hand, by renaming its decisions folder
in a throwaway copy, and closed them on 2026-08-20. That a rule needs an
uncommitted manual probe to be applied at all is the argument for this
note, not against it.

## Options

- **A - Consult the role map at each call site**
  (`abbr == vault.roles().get("REQ")`). Rejected on measurement: in a
  vault mid-translation carrying both requirement folders, ANF sorts
  first and takes the role by [[DEC_One_Abbreviation_One_Folder_By_Rule]],
  so this form stops row-checking the English folder that is checked
  today. A fix that silently removes coverage is not a fix.
- **B - Normalise in `Vault.classify`**, so the whole chain receives the
  role instead of the abbreviation. Rejected: `filename-prefix` and the
  `folder-abbreviation` type behind `frontmatter-domain` need the folder
  abbreviation and nothing else. Normalising there would take a German
  vault exactly the two ERRORs that keep its file naming honest.
- **C - One rule, two questions (chosen).** `canonical_role` holds the
  per-abbreviation rule; `Vault.roles()` asks "which folder holds role X"
  and arbitrates, because the requirement index needs one key space;
  `Vault.role_of` asks "what does this folder mean" and does not
  arbitrate, because a check over a single file needs no winner.
  `validate_file` carries `abbr` and `role` side by side.
- **D - Ship the requiredness of `verifies` with it.** Rejected for the
  third time. Measured on one derived vault: 11 `frontmatter-key` ERRORs
  and 33 `verifies-empty` WARNs on a vault that never had the convention.
  [[DEC_Language_Independent_Recognition_And_VCS_Tier]] follow-up 4 and
  [[DEC_Requirement_Index_Follows_The_Role_Map]] both refuse it, and
  CONTRIBUTING classes a field becoming required as MAJOR. It is a
  convention rollout and belongs in its own issue.

## Decision

**The per-file domain checks decide by canonical role; the folder
abbreviation keeps deciding where it is the question.** `check_req_table`,
`check_dec_status` and `check_tae_verifies` are gated on `role`; every
other per-file check keeps receiving `abbr`, the architecture document
naming which and why.

**A folder whose abbreviation the identity list names means itself**,
even where another folder holds that role in the index. Both halves of a
vault mid-translation are therefore checked file by file, and neither
loses what it has today. The handoff stays visible where it always was,
as `domain-duplicate-folder` and `export-duplicate-role`.

**One requirement-row identifier pattern for both readers of
`verifies`.** `req_row_id_re` spells it with the vault's own requirements
abbreviation and both the format check and the reference check read it.
The canonical `REQ-` spelling is tolerated beside it **only while the
vault carries a literal `REQ` folder** - that is the mid-translation
state and its whole extent; in a vault that has finished translating, an
English-spelled entry names nothing and says so.

**The requiredness of `verifies` in a translated evidence domain stays
unshipped**, and `Vault.fields_for` therefore stays keyed by the folder
abbreviation.

## Justification

- The rule the earlier record drew is the right rule and this note keeps
  it: a check that reads what an author wrote may follow the map, a check
  that demands the author write something new may not. `check_dec_status`
  and the row-grammar checks read; the `verifies` requirement demands.
  What the earlier record got wrong was the cost estimate: the 38 ERRORs
  it priced were the demanding check alone, and were never measured for
  the reading ones. Measured now: the finding sets of all three derived
  vaults are identical before and after.
- Two readers of one vault must not disagree about what the vault
  contains - the argument of [[DEC_One_Cell_Splitter_For_Both_Tools]] and
  [[DEC_One_Fence_Definition_For_Both_Tools]], and the `verifies` format
  check against the reference check is the same defect one level down.
- Arbitration belongs to the index and nowhere else. Two folders meaning
  one domain is already a finding ([[DEC_Two_Folders_One_Domain_Is_A_Finding]]);
  making a per-file check pick a winner would add a second, quieter
  consequence to a state that is reported already.
- Doorstop keys an item's identifier on its own document's declared
  prefix rather than on a constant, and reports a disagreeing prefix
  rather than rejecting the identifier. The constant was the anomaly.

## Consequences

- The declared ERROR severity is kept rather than a one-time announcement
  stage. CONTRIBUTING's PATCH tier already answers this case and states
  the compensation - the changelog names the finding code - and the
  per-file HEAD ratchet in `hook_stop` already gives a derived vault the
  baseline behaviour that an announcement stage would hand-build:
  pre-existing ERRORs are reported and never block.
- **Tier per site.** `check_dec_status` following the role map is PATCH:
  no record ever decided otherwise, the tool was blind. `req_row_id_re`
  is PATCH: it removes a false ERROR. The row-grammar checks following
  the role map is the one that moves a decided rule, and it takes the
  tier its twin [[DEC_The_Strict_Zone_Opens_In_Every_Template_Language]]
  took - MAJOR by the table, recorded as MINOR while the repository is at
  0.x. The changelog entry names the codes for both tiers.
- A vault that uses an alias token for a different purpose - an `(ENT)`
  folder that is not decisions - now receives one `dec-status` ERROR per
  file. The alias map is data for exactly this reason: such a project
  removes the entry from its own `vault_schema.json`. The finding names
  the translation it applied, so the cause is readable from the finding.
- `check_dec_status` reads an English body key and an English value list.
  All 141 decision files measured write them; a vault that translates the
  Status line itself gains one ERROR per file, and naming that vocabulary
  the way [[DEC_The_Strict_Zone_Opens_In_Every_Template_Language]] named
  the reference sections is the direction if such a vault appears.
- In a vault carrying both evidence folders, `check_tae_verifies` now
  also reads the folder that lost the role. A dangling `verifies:` entry
  there is reported for the first time; this is intended and it is not a
  no-op. Symmetrically, a vault carrying both requirement folders
  row-checks both while only the winner's rows enter the index, so a row
  in the loser can be `req-duplicate` within its file and never
  `req-duplicate-global`. Both asymmetries follow from the index needing
  one key space and are named in the validator's architecture document
  rather than removed.
- `check_leaks` still decides by folder abbreviation, so a translated
  decisions domain keeps the blocking checks and loses the advisory leak
  scan - a new asymmetry inside one domain, not untouched legacy. It has
  a second lock of its own, the English `context` in the section title,
  and opening one without the other changes nothing, measured.
- Closes residual 1 of [[DEC_Language_Independent_Recognition_And_VCS_Tier]]
  for its REQ and DEC branches; its leak-scan branch stays open.

### Realization

- `validate_vault.py` - `canonical_role`, `Vault.role_of`, the `role`
  binding in `validate_file` and the three gates reading it,
  `req_row_id_re` shared by `check_field_value` and `check_tae_verifies`,
  the corrected `check_req_table_silence` docstring
- `vault_schema.json` - the alias note and the REQ row note, prose only;
  no field, value list or relation moved
- `tests/run.sh` - the twins carry a decisions domain and a file of
  defective rows, the mid-translation vault seeds a defective row in the
  folder that lost the role, three vaults pin the requirement-prefix rule
  in its three states, and one AST assertion states the invariant the
  fifth literal would break; 459 to 472 assertions
- `ARCHITECTURE.md` - the trigger column, the arbitration split, and
  `check_leaks` named as the one domain check left on the abbreviation
- `CHANGELOG.md` - two entries, one per tier, each naming its codes; the
  sentence of the issue #66 entry this note makes false is marked there
  rather than left to contradict it

### Accepted residuals (documented, not solved)

1. **The DEC side of `Vault.fields_for` stays untouched.** The refusal
   above was measured on the evidence half alone. The decisions half
   would only relax: a literal `DEC` folder is exempt from the
   frontmatter `status` key and a translated one is not, so translated
   decision files are held to a stricter contract than English ones.
   None of the three vaults shows it, because every decision file there
   carries the key.
2. **`check_dec_status` reads an English body key and value list**, so a
   vault translating the Status line itself is not covered by this note.
