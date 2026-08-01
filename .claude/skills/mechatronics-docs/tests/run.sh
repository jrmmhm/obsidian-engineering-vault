#!/usr/bin/env bash
# Test suite for validate_vault.py. Builds ephemeral fixture vaults in
# mktemp dirs at runtime: a precision vault (realistic, correct content
# that must produce ZERO findings - guards against false-positive creep),
# a violation vault (~15 seeded rule violations that must each be
# detected), a German/English twin pair that must produce identical
# findings, plus hook-mode and crash-mode checks, plus a run against the
# real baseproject template vault (must contain no ERRORs).
set -u
# -P resolves the ~/.claude/skills symlink to the repo. Without it
# REAL_VAULT points outside the repo and the template-vault check below
# silently skips - the guard that keeps the shipped vault at 0 errors.
SKILL_DIR=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
VALIDATOR="$SKILL_DIR/validate_vault.py"
# Skill lives at <repo>/.claude/skills/mechatronics-docs -> repo root is 3 levels up.
REAL_VAULT="$(cd -P -- "$SKILL_DIR/../../.." && pwd -P)/00_documentation/01_projectvault"
FAILURES=0
TESTS=0

fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
ok() { :; }
check() { # check <description> <condition-result 0|1>
  TESTS=$((TESTS + 1))
  if [ "$2" -eq 0 ]; then ok "$1"; else fail "$1"; fi
}
contains() { printf '%s' "$1" | grep -q "$2"; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ==========================================================================
# Fixture 1: precision vault - realistic correct content, expect 0 findings
# ==========================================================================
P="$TMP/Testproj"
V="$P/00_documentation/01_projectvault"
mkdir -p "$V/01_requirements_(REQ)" "$V/02_decisions_(DEC)" \
  "$V/03_architecture_(ARC)" "$V/04_components_(CMP)" "$V/05_interfaces_(IFC)" \
  "$V/06_implementation_(IMP)" "$V/07_testing_and_evidence_(TAE)" \
  "$V/09_references_(REF)" "$V/99_inbox_(INB)" \
  "$P/10_hardware/13_PCB" "$P/30_testdata/31_testdata_raw/2026-01-10_adc_linearity" \
  "$P/50_sources/01_datasheets/electronics"
touch "$P/10_hardware/13_PCB/main_board.kicad_sch"
touch "$P/30_testdata/31_testdata_raw/2026-01-10_adc_linearity/run1.csv"
touch "$P/50_sources/01_datasheets/electronics/AnalogDevices__AD7175-2__datasheet__rev-F.pdf"

# minimal templates (H2 sets mirror the real baseproject templates)
cat > "$V/01_requirements_(REQ)/00_REQ_file_template.md" <<'EOF'
## Context
_Description_
EOF
cat > "$V/02_decisions_(DEC)/00_DEC_file_template.md" <<'EOF'
## Context
## Options
## Decision
## Justification
## Consequences
EOF
cat > "$V/03_architecture_(ARC)/00_ARC_file_template.md" <<'EOF'
## Context
## Requirements (Files)
## Decisions (Files)
## Components (Files)
## Interfaces
## Implementation (Files)
## Allocation and Verification
EOF
cat > "$V/04_components_(CMP)/00_CMP_individual_part_file_template.md" <<'EOF'
## Source(s)
## Context
## General Overview
EOF
cat > "$V/05_interfaces_(IFC)/00_IFC_file_template.md" <<'EOF'
## Context
## Specifications
EOF
cat > "$V/06_implementation_(IMP)/00_IMP_file_template.md" <<'EOF'
## Context
## References
## Implementation
EOF
cat > "$V/07_testing_and_evidence_(TAE)/00_TAE_file_template.md" <<'EOF'
## Context
## Test Conditions
## References
## Limitations
## Evidence
## Conclusion
EOF
cat > "$V/09_references_(REF)/00_REF_file_template.md" <<'EOF'
## Source(s)
## Context
## Content
EOF

cat > "$V/system_overview.md" <<'EOF'
## Context
This file lists the top-level modules.

## System Modules (ARC)
| Module (ARC) | Brief Description |
| ------------ | ----------------- |
| [[ARC_Data_Acquisition]] | Acquires and digitizes analog measurement data |
EOF

cat > "$V/01_requirements_(REQ)/REQ_Measurement (MEG).md" <<'EOF'
---
domain: REQ
id: REQ-MEG-000
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Requirements on the analog measurement chain of the data acquisition
module. Covers acquisition accuracy and sampling; excludes power supply
requirements. Sources are listed per row.

**Requirement line ID:** REQ-MEG-NNN

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source / Justification (REF/DEC) |
| ------------- | --: | ------- | -------------------- | -------------------------------- |
| M | 001 | ADC linearity error stays within 0.1 percent FSR | Pass if max INL over full range is below 0.1 percent FSR | [[REF_AD7175_Datasheet]] |
| M | 002 | Sampling rate reaches at least 1 kS per second per channel | Pass if sustained logging shows 1000 samples per second | [[DEC_ADC_Selection]] |
EOF

cat > "$V/02_decisions_(DEC)/DEC_ADC_Selection.md" <<'EOF'
---
domain: DEC
id: DEC-MEG-001
created: 2026-01-06
last-verified: 2026-07-01
---
Date: 2026-01-06
Status: Accepted

## Context
The measurement chain needs a precision sigma-delta converter. The choice
constrains layout, firmware drivers and the achievable accuracy of the
whole acquisition module.

## Options
- Option A: AD7175-2, 24 bit, 250 kS/s, established driver support
- Option B: ADS1262, 32 bit, 38 kS/s, slower but higher resolution
- Option C: integrated MCU ADC, 12 bit, no extra part cost

## Decision
Option A (AD7175-2).

## Justification
- Meets the sampling requirement with margin
- Reference designs available, reduces layout risk
- Resolution sufficient for the accuracy requirement

## Consequences
- SPI interface contract needed, see [[IFC_SPI_ADC]]
- Driver implementation documented in [[IMP_MainBoard_ADC]]
EOF

cat > "$V/04_components_(CMP)/CMP_AD7175-2.md" <<'EOF'
---
domain: CMP
id: CMP-MEG-001
status: active
created: 2026-01-06
last-verified: 2026-07-01
---
## Source(s)
- Datasheet: Testproj/50_sources/01_datasheets/electronics/AnalogDevices__AD7175-2__datasheet__rev-F.pdf

## Context
Precision 24-bit sigma-delta ADC used as the central converter of the
data acquisition module. Selected in [[DEC_ADC_Selection]].

## General Overview
| Attribute | Value |
| --------- | ----- |
| Type | ADC |
| Manufacturer | Analog Devices |
| Model | AD7175-2 |
| Resolution | 24 bit |
| Max rate | 250 kS/s |
EOF

# Editor-owned frontmatter keys. They carry no vault semantics, and the
# undeclared-field check must not report them - a plugin's own field is not
# a defect. Seeded in the PRECISION fixture on purpose: this file must stay
# at zero findings, so the tolerance is asserted by the zero-findings check
# itself rather than by a pattern that could silently stop matching.
#
# Both list spellings sit in this one file: 'tags' inline and 'aliases' as
# the unindented block sequence the Obsidian documentation shows and its
# properties editor writes. Before issue #24 the second one alone made this
# file frontmatter-malformed, so the zero-findings check is what guards it.
cat > "$V/04_components_(CMP)/CMP_MCU_Board.md" <<'EOF'
---
domain: CMP
id: CMP-MEG-002
status: active
created: 2026-01-06
last-verified: 2026-07-01
tags: [hardware, adc]
aliases:
- MCU Board
- Main Board
excalidraw-plugin: parsed
---
## Source(s)
- Datasheet: Testproj/50_sources/01_datasheets/electronics/AnalogDevices__AD7175-2__datasheet__rev-F.pdf

## Context
Controller board that reads the ADC via SPI and streams samples to the
host. Acts as SPI master of [[IFC_SPI_ADC]].

## General Overview
| Attribute | Value |
| --------- | ----- |
| Type | MCU board |
| Manufacturer | ST |
| Model | Nucleo-F446RE |
EOF

cat > "$V/05_interfaces_(IFC)/IFC_SPI_ADC.md" <<'EOF'
---
domain: IFC
id: IFC-MEG-001
status: active
created: 2026-01-07
last-verified: 2026-07-01
---
## Context
SPI contract between the ADC and the controller as a reusable contract
type without concrete endpoints.

## Specifications
### Signal/Line Type
- Type: Digital Bus
- Direction: bidirectional

### Timing/Protocol Parameters
- Protocol / Mode: SPI Mode 3
- Clock (max.): 5 MHz
EOF

cat > "$V/06_implementation_(IMP)/IMP_MainBoard_ADC.md" <<'EOF'
---
domain: IMP
id: IMP-MEG-001
status: active
created: 2026-01-08
last-verified: 2026-07-01
---
## Context
Concrete realization of the ADC wiring and driver configuration on the
main board.

## References
- Schematic: Testproj/10_hardware/13_PCB/main_board.kicad_sch
- Host config: /etc/udev/rules.d/99-adc.rules
- Operator home: ~/.config/adc-logger/logger.conf
- Host qualified: `labhost:~/.config/Code - OSS/User/settings.json`
- Git remote: git@github.com:example/adc-firmware.git
- Env-rooted: $HOME/.local/state/adc/last_run.json
- Datasheet online: https://www.analog.com/media/en/AD7175-2.pdf

## Implementation
- SPI clock fixed at 5 MHz
- ADC sync pin tied high
- Default state at reset: conversion stopped
- Firmware source (pending commit): Testproj/20_software/fw/main.c
- Ratio notation 3.3V/1.8V and heise.de/news/adc.html must never flag
EOF

cat > "$V/07_testing_and_evidence_(TAE)/TAE_ADC_Linearity.md" <<'EOF'
---
domain: TAE
id: TAE-MEG-001
status: active
created: 2026-01-10
last-verified: 2026-07-01
verifies: [REQ-MEG-001, REQ-MEG-002]
---
## Context
Linearity and sampling-rate verification of the assembled acquisition
chain against the measurement requirements.

## Test Conditions
- Test object: [[CMP_AD7175-2]] on the assembled main board
- Reference: calibrated 6.5-digit multimeter
- Room temperature, supply from lab PSU

## References
- Raw data: Testproj/30_testdata/31_testdata_raw/2026-01-10_adc_linearity/run1.csv

## Limitations
- Single board tested, no temperature sweep

## Evidence
| Quantity | Value |
| -------- | ----- |
| Max INL | 0.04 percent FSR |
| Sustained rate | 1042 samples per second |

## Conclusion
Both allocated requirements are met with margin on the tested board.
EOF

cat > "$V/09_references_(REF)/REF_AD7175_Datasheet.md" <<'EOF'
---
domain: REF
id: REF-MEG-001
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Source(s)
- Datasheet: Testproj/50_sources/01_datasheets/electronics/AnalogDevices__AD7175-2__datasheet__rev-F.pdf

## Context
Manufacturer datasheet of the AD7175-2. Relevant as the source of the
linearity specification used by the measurement requirements.

## Content
### Specifications chapter
- INL specification supports the acquisition accuracy requirement
- Recommended layout notes used for the main board
EOF

cat > "$V/03_architecture_(ARC)/ARC_Data_Acquisition.md" <<'EOF'
---
domain: ARC
id: ARC-MEG-001
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Context
**Includes:**
- Analog acquisition chain from input terminal to digital samples
- ADC and its controller-side driver contract

**Excludes:**
- Power distribution and host-side data storage

Allocation is recorded in [[#Allocation and Verification]] and the
contracts in [[#Interfaces]]; this paragraph is the scope statement of
the module and is referenced as [[#^module-scope]]. ^module-scope

## Requirements (Files)
- [[REQ_Measurement (MEG)]]: Defines accuracy and rate targets for this module.

## Decisions (Files)
- [[DEC_ADC_Selection]]: Fixes the central converter part of the module.

## Components (Files)
- [[CMP_AD7175-2]]: Central analog-to-digital converter.
- [[CMP_MCU_Board]]: SPI master and sample transport.

## Interfaces
| Interface (IFC) | Endpoint A | Endpoint B | Context |
| --- | --- | --- | --- |
| [[IFC_SPI_ADC]] | [[CMP_AD7175-2]] | [[CMP_MCU_Board]] | ADC data to controller |

## Implementation (Files)
- [[IMP_MainBoard_ADC]]: Wiring and driver configuration on the main board.
- [[IMP_Labhost_Backup]]: Log archival on the lab host.

## Allocation and Verification
| Submodule (ARC/CMP/IFC) | Allocated Requirements (REQ-IDs) | Verification (TAE) | Status |
| ----------------------- | -------------------------------- | ------------------ | ------ |
| [[CMP_AD7175-2]] | REQ-MEG-001 | [[TAE_ADC_Linearity\|linearity proof]] | Verified |
| [[IFC_SPI_ADC]] | REQ-MEG-002 | [[TAE_ADC_Linearity]] | Verified |
EOF

# An IMP note whose artifacts are files on ANOTHER machine - the case the
# pointer rule had no destination for (issue #11). Everything here must be
# silent, and the zero-findings assertion below is what proves it: short
# blocks are single observations, and the declared block in References must
# NOT have its paths resolved against project_root, although
# 'deploy/20_software/...' is shaped exactly like a project artifact.
cat > "$V/06_implementation_(IMP)/IMP_Labhost_Backup.md" <<'EOF'
---
domain: IMP
id: IMP-MEG-002
status: active
created: 2026-01-08
last-verified: 2026-07-01
---
## Context
Log archival for the acquisition chain, running on the lab host. Its unit
file and its target directory are files on that machine and are never
artifacts of this repository.

## References
- Service unit: labhost:/etc/systemd/system/lab-backup.service
```text host=labhost
deploy/20_software/archive/run.sh
/srv/backup/adc/latest
```

## Implementation
- Retention: 7 daily, 4 weekly
```bash host=labhost
systemctl --user status lab-backup.timer
```
- The same fact without a declaration, short enough to be one observation:
```
readlink -f /srv/backup/adc/latest
```
EOF

out=$(python3 "$VALIDATOR" "$V" 2>&1); rc=$?
check "precision vault exits 0" $rc
n=$(printf '%s' "$out" | grep -c '^\(ERROR\|WARN\)') || true
TESTS=$((TESTS + 1))
if [ "$n" -eq 0 ]; then ok x; else
  fail "precision vault must produce zero findings, got $n:"; printf '%s\n' "$out" | sed 's/^/    /'
fi

# ==========================================================================
# Fixture 2: violation vault - every seeded violation must be detected
# ==========================================================================
W="$TMP/Badproj/00_documentation/01_projectvault"
mkdir -p "$W/01_requirements_(REQ)" "$W/02_decisions_(DEC)" \
  "$W/03_architecture_(ARC)" "$W/06_implementation_(IMP)" \
  "$W/07_testing_and_evidence_(TAE)" "$W/99_inbox_(INB)"
for d in "01_requirements_(REQ)" "02_decisions_(DEC)" "03_architecture_(ARC)" \
         "06_implementation_(IMP)" "07_testing_and_evidence_(TAE)"; do
  cp "$V/$d/"00_*file_template*.md "$W/$d/" 2>/dev/null || true
done

# A template is the file every new file is copied from, so an undeclared key
# in it propagates silently. Same H2 set as the copy it replaces, so section
# checks are unaffected. Its VALUES are placeholders and must stay unchecked -
# 'created: YYYY-MM-DD' may not become a frontmatter-date ERROR.
cat > "$W/01_requirements_(REQ)/00_REQ_file_template.md" <<'EOF'
---
domain: REQ
created: YYYY-MM-DD
squad: nobody
---
## Context
_Description_
EOF

cat > "$W/01_requirements_(REQ)/wrongname.md" <<'EOF'
no frontmatter, wrong name, no sections
line
line
line
line
EOF

# 'crated' is the silent defect class the undeclared check exists for: the
# key looks present and takes effect nowhere. 'owner' is a deliberate-looking
# foreign field. Both must be named, and in ONE line - a file with several
# stray keys must not produce several findings.
cat > "$W/01_requirements_(REQ)/REQ_Power (PWR).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
crated: 2026-01-05
owner: nobody
last-verified: 2026-07-01
---
## Context
Power requirements with several seeded table violations for the test
suite. Content is intentionally broken.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source / Justification (REF/DEC) |
| ------------- | --: | ------- | -------------------- | -------------------------------- |
| X | 001 | bad class row | Pass if measured | none |
| M | 01 | two digit id | Pass if measured | none |
| M | 001 | duplicate id row | Pass if measured | none |
| M | 003 | empty criterion row | | none |
EOF

cat > "$W/01_requirements_(REQ)/REQ_Power2 (PWR).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Second power requirement file reusing an already occupied full ID to
trigger the global duplicate check.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source / Justification (REF/DEC) |
| ------------- | --: | ------- | -------------------- | -------------------------------- |
| M | 001 | duplicate across files | Pass if measured | none |
EOF

cat > "$W/01_requirements_(REQ)/REQ_Thermal (THM).md" <<'EOF'
---
domain: REQ
id: REQ-XYZ-000
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Third requirement file whose frontmatter id declares a scope token that
contradicts the token in its own filename. The id wins, so this file's rows
are addressed as REQ-XYZ-NNN - which is exactly the silent rekeying the
scope-mismatch check exists to surface.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source / Justification (REF/DEC) |
| ------------- | --: | ------- | -------------------- | -------------------------------- |
| M | 001 | scope mismatch row | Pass if measured | none |
EOF

# A REQ file that documents its own table format. The quoted row is a
# defect by every rule the real table below is held to, and it must produce
# nothing: it is documentation, not data. Before the fence tracker reached
# check_req_table this cost three blocking ERRORs plus a req-duplicate
# blaming the REAL row below for colliding with the quoted one (issue #20).
cat > "$W/01_requirements_(REQ)/REQ_Quoted (QTD).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Requirement file whose Context quotes one malformed row as documentation.

A malformed row looks like this:

```markdown
| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| ------------- | --: | ------- | -------------------- | ------ |
| Z | 9 | quoted class and id | | none |
| M | 001 | quoted duplicate | quoted | none |
```

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| ------------- | --: | ------- | -------------------- | ------ |
| M | 001 | the only real requirement here | Pass if measured | none |
EOF

# The positive control. Byte-identical rows, no fence: every finding the
# quoted file must NOT produce, this file must. Without it the assertions
# above are also satisfied by a check that stopped working.
cat > "$W/01_requirements_(REQ)/REQ_Unquoted (UNQ).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
The same rows as the quoted file, with the fence removed.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| ------------- | --: | ------- | -------------------- | ------ |
| Z | 9 | quoted class and id | | none |
| M | 001 | quoted duplicate | quoted | none |
| M | 001 | the only real requirement here | Pass if measured | none |
EOF

# One unpaired marker must not switch a blocking check off for everything
# below it - the cheapest bypass a fence rule can have, and the reason
# check_leaks evaluates an unclosed block to EOF. A file left inside an open
# fence is read as if it carried no fence at all.
cat > "$W/01_requirements_(REQ)/REQ_Stray (STR).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Requirement file carrying one stray, never closed fence marker.

```

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| ------------- | --: | ------- | -------------------- | ------ |
| Q | 007 | stray fence must not hide this | Pass if measured | none |
EOF

# A pipe inside a cell, escaped the way Obsidian requires inside a table.
# Splitting on it shifts every column behind it, which is how the empty
# acceptance criterion below used to disappear: the next column moved into
# it and req-criterion - a blocking code - stopped firing (issue #22). The
# second row carries the escape inside a code span, where GFM keeps it just
# as much, and must stay free of findings.
cat > "$W/01_requirements_(REQ)/REQ_Escaped (ESC).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Requirement file whose rows carry a pipe inside a cell.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| ------------- | --: | ------- | -------------------- | ------ |
| M | 001 | value a \| b in one cell | | none |
| M | 002 | `ss -tlnp \| grep :8097` | Pass if the port listens | none |
EOF

cat > "$W/02_decisions_(DEC)/DEC_Bad.md" <<'EOF'
---
domain: DEC
id: DEC-PWR-001
created: 01.02.2026
last-verified: 2026-07-01
---
Date: 2026-01-06
Status: Maybe

## Context
Decision with an invalid status value and a broken created date.
Context text line for stub avoidance.

## Options
- Option A

## Decision
Option A.

## Justification
- seeded

## Consequences
- seeded
EOF

cat > "$W/02_decisions_(DEC)/DEC_Superseded_NoLink.md" <<'EOF'
---
domain: DEC
id: DEC-PWR-001
created: 2026-01-06
last-verified: 2026-07-01
---
Date: 2026-01-06
Status: Superseded

## Context
Superseded decision without the mandatory successor link.

## Options
- Option A

## Decision
Option A.

## Justification
- seeded

## Consequences
- seeded
EOF

cat > "$W/03_architecture_(ARC)/ARC_Leaky.md" <<'EOF'
---
domain: CMP
id: ARC-DOM-NNN
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Context
The voltage divider outputs 3.3 V into the ADC input stage and the
relay coil is driven with 24 V from the supply rail.

```c
int leak = 1;
```

```bash host=labhost
uptime
```

- [[Nonexistent_File]]: dead link target.
- [[Another_Missing]]: second dead link target.
- [[#Context]]: same-file anchor naming a heading this file carries.
- [[#^leaky-scope]]: same-file anchor naming a block this file carries. ^leaky-scope
- [[#No Such Heading]]: same-file anchor naming nothing.
- [[#^no-such-block]]: same-file block anchor naming nothing.
EOF

{
  # same unfilled placeholder as ARC_Leaky.md: two files freshly copied from
  # one template are not two objects claiming one identity - must NOT collide
  printf -- '---\ndomain: ARC\nid: ARC-DOM-NNN\nstatus: active\ncreated: 2026-01-09\nlast-verified: 2026-07-01\n---\n'
  printf '## Context\n'
  printf '## Requirements (Files)\n## Decisions (Files)\n## Components (Files)\n'
  printf '## Interfaces\n## Implementation (Files)\n## Allocation and Verification\n'
  for i in $(seq 1 400); do printf 'filler line without any concrete values here\n'; done
} > "$W/03_architecture_(ARC)/ARC_Long.md"

# A list-valued scalar field. 'x not in <set>' hashes its left operand, so an
# unnormalised list raised TypeError -> exit 2 -> both hooks fail open, i.e. one
# such file silently disabled the entire enforcement layer. It must be an
# ordinary ERROR, and the vault must still exit 1 rather than 2.
cat > "$W/03_architecture_(ARC)/ARC_ListStatus.md" <<'EOF'
---
domain: ARC
status: [active]
created: 2026-01-09
last-verified: 2026-07-01
---
## Context
Architecture note whose status is written as a YAML list instead of a
scalar. The value is wrong either way; the point is that it is reported
rather than crashing the validator.

## Requirements (Files)
- None allocated in this seeded fixture.
EOF

cat > "$W/06_implementation_(IMP)/IMP_Bad.md" <<'EOF'
---
domain: IMP
status: active
created: 2026-01-08
: broken frontmatter line
---
## Context
Implementation note with seeded violations.

## References
- Schematic: Badproj/10_hardware/13_PCB/does_not_exist.kicad_sch
- Markdown link: [board](Badproj/10_hardware/13_PCB/linked_missing.kicad_sch)
- Repo anchored: /10_hardware/13_PCB/anchored_missing.kicad_sch
- Host path: /etc/badproj/does_not_exist.conf
- Operator home: ~/.config/badproj/missing.conf
```text
Badproj/10_hardware/13_PCB/fenced_missing.sch
```

## Implementation
- Driver source: Badproj/20_software/missing_driver.c
```python
print("code does not belong here")
```
EOF

# 'verifies' as a block sequence, on purpose. The precision fixture and the
# identifier fixture both spell it inline, so this file is where the block
# form has to reach check_tae_verifies as a LIST: if the parser folded it
# into a string - or rejected the file as malformed - verifies-unknown-req
# would disappear and the assertion below would fail. Absence of a finding
# would prove nothing here, presence of the right one does.
cat > "$W/07_testing_and_evidence_(TAE)/TAE_Bad.md" <<'EOF'
---
domain: TAE
status: banana
created: 2026-01-10
last-verified: 2026-07-01
verifies:
  - REQ-XXX-999
---
## Context
Test evidence referencing a requirement that does not exist.

## Test Conditions
- seeded

## References
- none

## Limitations
- seeded

## Evidence
| Quantity | Value |
| -------- | ----- |
| x | 1 |

## Conclusion
Seeded conclusion.
EOF

cat > "$W/07_testing_and_evidence_(TAE)/TAE_Dup.md" <<'EOF'
---
domain: TAE
status: active
created: 2026-01-10
last-verified: 2026-07-01
verifies: []
---
## Context
Duplicate basename fixture, first instance.

## Test Conditions
- seeded

## References
- none

## Limitations
- seeded

## Evidence
| Quantity | Value |
| -------- | ----- |
| x | 1 |

## Conclusion
Seeded conclusion.
EOF
cp "$W/07_testing_and_evidence_(TAE)/TAE_Dup.md" "$W/02_decisions_(DEC)/TAE_Dup.md"

# Fenced blocks past the record threshold. IMP_Host_Copy carries a bare one
# (a copy - ERROR) and a declaration that names nothing (not a declaration -
# ERROR). IMP_Host_Record carries the same length WITH a machine named, which
# must be a WARN and must NOT be a code-fence: that negative is the whole
# point of the change and is asserted file-scoped below, because the violation
# vault produces code-fence findings from other files anyway.
{
  printf -- '---\ndomain: IMP\nstatus: active\ncreated: 2026-01-08\nlast-verified: 2026-07-01\n---\n'
  printf '## Context\nCopy of a script that lives in this repository.\n\n'
  printf '## References\n- Driver source: Badproj/20_software/driver.c\n\n'
  printf '## Implementation\n'
  printf '```bash\n'
  for i in $(seq 1 20); do printf 'echo "copied line %d"\n' "$i"; done
  printf '```\n'
  printf '```bash host=\n'
  printf 'systemctl status nothing\n'
  printf '```\n'
} > "$W/06_implementation_(IMP)/IMP_Host_Copy.md"

{
  printf -- '---\ndomain: IMP\nstatus: active\ncreated: 2026-01-08\nlast-verified: 2026-07-01\n---\n'
  printf '## Context\nDirectory layout of a host this project does not own.\n\n'
  printf '## References\n- Host: labhost\n\n'
  printf '## Implementation\n'
  printf '```text host=labhost\n'
  for i in $(seq 1 20); do printf '/srv/data/dir_%d\n' "$i"; done
  printf '```\n'
} > "$W/06_implementation_(IMP)/IMP_Host_Record.md"

# A tilde fence is a fence (CommonMark: "at least three consecutive backtick
# characters or tildes"). Recognising only backticks made '~~~' the cheaper
# way out of this rule AND made check_links/check_paths read the block as
# prose. An unclosed fence is evaluated to EOF for the same reason: one
# unclosed marker must not silence everything below it.
{
  printf -- '---\ndomain: IMP\nstatus: active\ncreated: 2026-01-08\nlast-verified: 2026-07-01\n---\n'
  printf '## Context\nSame copy behind a tilde fence and behind an unclosed one.\n\n'
  printf '## References\n- none\n\n'
  printf '## Implementation\n'
  printf '~~~bash\n'
  for i in $(seq 1 20); do printf 'echo "tilde line %d"\n' "$i"; done
  printf '~~~\n'
  printf '```bash\n'
  for i in $(seq 1 20); do printf 'echo "unclosed line %d"\n' "$i"; done
} > "$W/06_implementation_(IMP)/IMP_Host_Tilde.md"

# Headings the author DID write, under a title the template does not carry.
# Before the near-miss classes these were reported exactly like a section
# nobody ever wrote, naming a string that is not in the file (issue #10).
cat > "$W/06_implementation_(IMP)/IMP_Case_Drift.md" <<'EOF'
---
domain: IMP
status: active
created: 2026-01-08
last-verified: 2026-07-01
---
## context
Implementation note whose first heading differs from the template in case
alone. The section exists by any reading, so it must not be reported as
missing - and the case drift must still be visible.

## References
- none

## Implementation
- Seeded near miss above.
EOF

# Two headings extend the same required one: the finding must name a
# reproducible pair, not whichever the set iteration happened to yield.
cat > "$W/06_implementation_(IMP)/IMP_Qualifier.md" <<'EOF'
---
domain: IMP
status: active
created: 2026-01-08
last-verified: 2026-07-01
---
## Context
Implementation note carrying a qualifier on a required heading, twice.

## References
- none

## Implementation - Iteration 0
- First scoped variant of the required section.

## Implementation (Nachtrag)
- Second scoped variant of the same required section.
EOF

# The negative control of the boundary rule: a longer WORD is not a
# qualifier, so this stays a genuine absence.
cat > "$W/06_implementation_(IMP)/IMP_Word_Extension.md" <<'EOF'
---
domain: IMP
status: active
created: 2026-01-08
last-verified: 2026-07-01
---
## Contexts
Implementation note whose heading is a different word, not a scoped
variant of the required one.

## References
- none

## Implementation
- Seeded absence above.
EOF

# The other direction: the file's title is SHORTER than the template's.
# 'Allocation' is not 'Allocation and Verification', and reporting the
# latter as never written is the same unusable diagnosis.
cat > "$W/03_architecture_(ARC)/ARC_Reverse.md" <<'EOF'
---
domain: ARC
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Context
Architecture note whose last heading is a shortened form of the one the
template declares. Every other section is written exactly.

## Requirements (Files)
- None allocated in this seeded fixture.

## Decisions (Files)
- None recorded in this seeded fixture.

## Components (Files)
- None assigned in this seeded fixture.

## Interfaces
- None declared in this seeded fixture.

## Implementation (Files)
- None linked in this seeded fixture.

## Allocation
| Submodule | Allocated Requirements | Verification | Status |
| --- | --- | --- | --- |
| none | none | none | Draft |
EOF

echo "old inbox note" > "$W/99_inbox_(INB)/old_note.md"
touch -t 202601010000 "$W/99_inbox_(INB)/old_note.md"

out=$(python3 "$VALIDATOR" "$W" 2>&1); rc=$?
TESTS=$((TESTS + 1))
if [ $rc -eq 1 ]; then ok x; else fail "violation vault must exit 1, got $rc"; fi
for code in filename-prefix frontmatter-missing frontmatter-malformed \
    frontmatter-domain frontmatter-date frontmatter-status template-sections \
    length code-fence impl-leak link-unresolved req-class req-nnn \
    req-duplicate req-criterion req-duplicate-global verifies-unknown-req \
    verifies-empty dec-status dec-superseded path-missing req-uncovered \
    inb-age duplicate-basename orphan id-duplicate id-scope-mismatch \
    fence-host fence-record section-near-miss section-mismatch; do
  TESTS=$((TESTS + 1))
  if contains "$out" "\[$code\]"; then ok x; else fail "violation vault: [$code] not detected"; fi
done
# The block-form 'verifies' must name the very requirement its item carries.
# Asserting the code alone would also pass if the parser produced a list of
# something else entirely.
TESTS=$((TESTS + 1))
if contains "$out" "\[verifies-unknown-req\].*REQ-XXX-999"; then ok x; else
  fail "a block-sequence 'verifies' must reach check_tae_verifies item by item"; fi

# A link into the file itself is resolved against that file, not against the
# name index (issue #23). Asserting only that it produces nothing would also
# pass for a check that exempts every anchor instead of reading it, so both
# directions are asserted on one file: the two anchors that name something
# stay silent, the two that name nothing are reported by name.
TESTS=$((TESTS + 1))
if contains "$out" "\[link-unresolved\] \[\[#No Such Heading\]\]"; then ok x; else
  fail "a same-file anchor naming no heading must be reported"; fi
TESTS=$((TESTS + 1))
if contains "$out" "\[link-unresolved\] \[\[#\^no-such-block\]\]"; then ok x; else
  fail "a same-file anchor naming no block identifier must be reported"; fi
TESTS=$((TESTS + 1))
if contains "$out" "\[\[#Context\]\]" || contains "$out" "\[\[#\^leaky-scope\]\]"; then
  fail "a same-file anchor that resolves must produce nothing"; else ok x; fi

# body-wide dead-path scan: WARN outside References, ERROR inside stays,
# fenced content inside References stays covered
TESTS=$((TESTS + 1))
if contains "$out" "^WARN .*missing_driver\.c" ; then ok x; else
  fail "unmarked dead body path must WARN [path-missing]"; fi
TESTS=$((TESTS + 1))
if contains "$out" "^ERROR .*does_not_exist\.kicad_sch"; then ok x; else
  fail "dead path in References must stay ERROR"; fi
TESTS=$((TESTS + 1))
if contains "$out" "^ERROR .*fenced_missing\.sch"; then ok x; else
  fail "fenced dead path inside References must stay ERROR"; fi

# The References zone checks the same thing the body does: a token shaped like
# a project artifact. Two forms reach the shape gate through a leading
# character the path regex cannot consume, and both must survive - a Markdown
# link matches only from its second segment, and a repo-anchored path starts
# with a slash. They are the guard against "fix the false positives by
# switching the zone off".
TESTS=$((TESTS + 1))
if contains "$out" "^ERROR .*linked_missing\.kicad_sch"; then ok x; else
  fail "dead project path inside a Markdown link must stay ERROR"; fi
TESTS=$((TESTS + 1))
if contains "$out" "^ERROR .*anchored_missing\.kicad_sch"; then ok x; else
  fail "repo-anchored dead project path must stay ERROR"; fi
# ... while a path this project cannot own is not a stale pointer, in either
# zone. Reported here as the explicit negative, and by the precision vault's
# zero-findings assertion for the remaining foreign forms.
TESTS=$((TESTS + 1))
if ! contains "$out" "etc/badproj" && ! contains "$out" "config/badproj"; then ok x; else
  fail "foreign host paths in References must produce no finding"; fi

# Fenced blocks are judged by drift risk, not by syntax. Every assertion here
# is file-scoped: the violation vault produces code-fence findings from ARC
# anyway, so a bare "contains [code-fence]" would prove nothing about any
# single case.
TESTS=$((TESTS + 1))
if contains "$out" "IMP_Host_Copy\.md.*\[code-fence\]"; then ok x; else
  fail "a block past the record threshold without a declaration must be ERROR"; fi
TESTS=$((TESTS + 1))
if contains "$out" "IMP_Host_Copy\.md.*\[fence-host\]"; then ok x; else
  fail "'host=' naming no machine must be ERROR [fence-host]"; fi
TESTS=$((TESTS + 1))
if contains "$out" "^WARN .*IMP_Host_Record\.md.*\[fence-record\]"; then ok x; else
  fail "a declared long block must be WARN [fence-record]"; fi
# The negative that carries the whole change: the declaration lifts the ERROR,
# and it is the only thing that does.
TESTS=$((TESTS + 1))
if ! contains "$out" "IMP_Host_Record\.md.*\[code-fence\]"; then ok x; else
  fail "a declared block must not produce [code-fence]"; fi
TESTS=$((TESTS + 1))
if ! contains "$out" "^ERROR .*\[fence-record\]"; then ok x; else
  fail "fence-record must never be an ERROR - it cannot prove a source is absent"; fi
# Short blocks are single observations and stay silent - IMP_Bad.md carries a
# two-line and a one-line fence that were ERRORs before this rule.
TESTS=$((TESTS + 1))
if ! contains "$out" "IMP_Bad\.md.*\[code-fence\]"; then ok x; else
  fail "a block within the record threshold must be silent"; fi
# A tilde fence is a fence, and an unclosed fence is evaluated to EOF -
# otherwise both are cheaper ways out of the rule than the declaration.
TESTS=$((TESTS + 1))
n=$(printf '%s' "$out" | grep -c "IMP_Host_Tilde\.md.*\[code-fence\]") || true
if [ "$n" -eq 2 ]; then ok x; else
  fail "tilde fence and unclosed fence must both be ERROR, got $n of 2"; fi
# ARC is a map and stores nothing: a declaration does not lift its ban.
TESTS=$((TESTS + 1))
n=$(printf '%s' "$out" | grep -c "ARC_Leaky\.md.*\[code-fence\]") || true
if [ "$n" -eq 2 ]; then ok x; else
  fail "every ARC fence must be ERROR, declared or not, got $n of 2"; fi

# A requirement table quoted as documentation is not data (issue #20). Every
# assertion here is file-scoped for the same reason the fence assertions above
# are: the violation vault produces every one of these codes anyway.
TESTS=$((TESTS + 1))
n=$(printf '%s' "$out" | grep -cE "REQ_Quoted \(QTD\)\.md.*\[(req-class|req-nnn|req-criterion|req-duplicate)\]") || true
if [ "$n" -eq 0 ]; then ok x; else
  fail "a quoted requirement table must produce no row finding, got $n"; fi
# The positive control: the same rows without the fence must produce all four.
for code in req-class req-nnn req-criterion req-duplicate; do
  TESTS=$((TESTS + 1))
  if contains "$out" "REQ_Unquoted (UNQ)\.md.*\[$code\]"; then ok x; else
    fail "positive control: unfenced rows must still produce [$code]"; fi
done
# One stray marker must not buy an exemption from a blocking check.
TESTS=$((TESTS + 1))
if contains "$out" "REQ_Stray (STR)\.md.*\[req-class\]"; then ok x; else
  fail "an unclosed fence must not silence req-class below it"; fi

# An escaped pipe must not shift the columns behind it (issue #22). The row
# with the empty acceptance criterion is the assertion that carries the
# change: while the split moved the next column into it, the criterion was
# never empty and this blocking finding did not exist.
TESTS=$((TESTS + 1))
if contains "$out" "REQ_Escaped (ESC)\.md:12 \[req-criterion\]"; then ok x; else
  fail "an escaped pipe must not fill an empty acceptance criterion:"
  printf '%s\n' "$out" | grep "REQ_Escaped" | sed 's/^/    /'
fi
# ... and the row whose criterion IS written must stay free of row findings,
# escape inside a code span included. Otherwise the assertion above is also
# satisfied by a splitter that reports every row.
TESTS=$((TESTS + 1))
n=$(printf '%s' "$out" | grep -cE "REQ_Escaped \(ESC\)\.md:13 \[(req-class|req-nnn|req-criterion|req-duplicate)\]") || true
if [ "$n" -eq 0 ]; then ok x; else
  fail "a complete row carrying an escaped pipe must produce no row finding, got $n"; fi
# The row the quoted block declares must not exist as a requirement at all -
# not as a finding, and not in the index every TAE 'verifies:' is checked
# against. Indexing it would let a quoted example prove a real requirement.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" "$W" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import validate_vault as vv
from pathlib import Path
idx = vv.Vault(Path(sys.argv[2])).req_index()
assert "REQ-QTD-001" in idx, "the real row below the quoted block must be indexed"
f, line = idx["REQ-QTD-001"]
text = f.read_text(encoding="utf-8").splitlines()[line - 1]
assert "the only real requirement here" in text, f"indexed the quoted row instead: {text!r}"
assert "REQ-QTD-009" not in idx, "a quoted row must not enter the requirement index"
PY
then ok x; else fail "req_index must resolve the real row, not the quoted one"; fi

# Near misses: a heading the author DID write under a title the template
# does not carry. Every assertion is file-scoped and names the LINE, because
# the defect being fixed is precisely that the old message named a string
# the author could not find in the file.
TESTS=$((TESTS + 1))
if contains "$out" "^WARN .*IMP_Case_Drift\.md:7 \[section-near-miss\].*template 'Context' vs 'context' (line 7)"; then
  ok x; else fail "a case-only heading must WARN [section-near-miss] naming both spellings and the line"; fi
# ... and must NOT be reported as an unwritten section, which is the whole point
TESTS=$((TESTS + 1))
if ! contains "$out" "IMP_Case_Drift\.md.*\[template-sections\]"; then ok x; else
  fail "a case-only heading must not be reported as a missing section"; fi
TESTS=$((TESTS + 1))
if ! contains "$out" "^ERROR .*\[section-near-miss\]"; then ok x; else
  fail "section-near-miss must never be an ERROR - the section is present"; fi

# A qualifier is a differently scoped section: still unmet, but diagnosable.
TESTS=$((TESTS + 1))
if contains "$out" "^ERROR .*IMP_Qualifier\.md:13 \[section-mismatch\].*template 'Implementation' vs 'Implementation - Iteration 0' (line 13)"; then
  ok x; else fail "a qualifier heading must ERROR [section-mismatch] naming both spellings and the line"; fi
TESTS=$((TESTS + 1))
if ! contains "$out" "IMP_Qualifier\.md.*\[template-sections\]"; then ok x; else
  fail "a heading present under a qualifier must not also be listed as never written"; fi
# One grouped finding per file per class - the aggregation convention of
# amendment 2026-07-27, and what keeps the per-file ratchet counts in {0,1}.
TESTS=$((TESTS + 1))
n=$(printf '%s' "$out" | grep -c "IMP_Qualifier\.md.*\[section-mismatch\]") || true
if [ "$n" -eq 1 ]; then ok x; else
  fail "two qualifier headings must produce exactly ONE finding, got $n"; fi

# The other direction: the file's title is shorter than the template's.
TESTS=$((TESTS + 1))
if contains "$out" "^ERROR .*ARC_Reverse\.md:26 \[section-mismatch\].*template 'Allocation and Verification' vs 'Allocation' (line 26)"; then
  ok x; else fail "a shortened heading must ERROR [section-mismatch] naming both spellings and the line"; fi
TESTS=$((TESTS + 1))
if ! contains "$out" "ARC_Reverse\.md.*\[template-sections\]"; then ok x; else
  fail "a heading present in shortened form must not be listed as never written"; fi

# The boundary rule's negative control: a longer WORD is a different word,
# not a scoped variant, and stays a genuine absence.
TESTS=$((TESTS + 1))
if contains "$out" "IMP_Word_Extension\.md.*\[template-sections\].*'Context'"; then ok x; else
  fail "'Contexts' must stay a genuine absence of 'Context'"; fi
TESTS=$((TESTS + 1))
if ! contains "$out" "IMP_Word_Extension\.md.*section-mismatch" \
   && ! contains "$out" "IMP_Word_Extension\.md.*section-near-miss"; then ok x; else
  fail "'Contexts' must not be classified as a near miss of 'Context'"; fi

# Which spelling and which line a near miss names must not depend on set
# iteration order - two headings extend the same requirement here, and the
# hash seed is what used to decide the winner.
a=$(PYTHONHASHSEED=0 python3 "$VALIDATOR" "$W" 2>&1 | grep "IMP_Qualifier\.md.*section-mismatch")
b=$(PYTHONHASHSEED=1 python3 "$VALIDATOR" "$W" 2>&1 | grep "IMP_Qualifier\.md.*section-mismatch")
TESTS=$((TESTS + 1))
if [ "$a" = "$b" ] && [ -n "$a" ]; then ok x; else
  fail "the near-miss finding must be identical under different hash seeds"; fi

# Near misses are counted separately in the run summary, so that formatting
# drift across a domain does not read as a batch of unwritten sections.
near_n=$(printf '%s' "$out" | grep -cE '\[(section-near-miss|section-mismatch)\]') || true
sum_n=$(printf '%s' "$out" | sed -n 's/^-- .*, \([0-9][0-9]*\) near miss(es)$/\1/p')
TESTS=$((TESTS + 1))
if [ -n "$sum_n" ] && [ "$sum_n" = "$near_n" ] && [ "$near_n" -gt 0 ]; then ok x; else
  fail "summary must count near misses separately, got '$sum_n' vs $near_n findings"; fi

# undeclared frontmatter keys: reported, grouped into ONE line, and naming
# every unknown key. WARN and never ERROR - the check cannot tell a typo from
# a deliberate plugin field, which disqualifies it from blocking.
TESTS=$((TESTS + 1))
if contains "$out" "REQ_Power (PWR)\.md.*\[frontmatter-undeclared\].*'crated'.*'owner'"; then
  ok x; else fail "undeclared keys must be reported in one line naming both"; fi
TESTS=$((TESTS + 1))
n=$(printf '%s' "$out" | grep -c "REQ_Power (PWR)\.md.*frontmatter-undeclared") || true
if [ "$n" -eq 1 ]; then ok x; else
  fail "two stray keys must produce exactly ONE finding, got $n"; fi
TESTS=$((TESTS + 1))
if ! contains "$out" "^ERROR .*frontmatter-undeclared"; then ok x; else
  fail "frontmatter-undeclared must never be an ERROR"; fi

# templates are checked for vocabulary but never for values: the propagation
# source is worth catching, its placeholders are not defects
TESTS=$((TESTS + 1))
if contains "$out" "00_REQ_file_template\.md.*\[frontmatter-undeclared\].*'squad'"; then
  ok x; else fail "an undeclared key in a template must be reported"; fi
TESTS=$((TESTS + 1))
if ! contains "$out" "00_REQ_file_template\.md.*frontmatter-date"; then ok x; else
  fail "template placeholder values must not be value-checked"; fi

# a list-valued status must be reported, not crash the validator. The exit-1
# assertion above is the other half: a crash would have made it exit 2.
TESTS=$((TESTS + 1))
if contains "$out" "ARC_ListStatus\.md.*\[frontmatter-status\]"; then ok x; else
  fail "list-valued status must produce frontmatter-status, not a crash"; fi

# identifier collision: ERROR, and it must name BOTH locations. The reported
# file is the second one in sorted order, so the message is reproducible -
# without the sort it would depend on filesystem iteration order.
TESTS=$((TESTS + 1))
if contains "$out" "DEC_Superseded_NoLink\.md.*\[id-duplicate\].*DEC-PWR-001.*already declared in DEC_Bad\.md"; then
  ok x; else fail "id-duplicate must name both locations deterministically"; fi
# unfilled template placeholders share one value by construction and must
# never be read as an identity collision (they fail the identifier pattern)
TESTS=$((TESTS + 1))
if ! contains "$out" "ARC-DOM-NNN"; then ok x; else
  fail "unfilled placeholder id must never produce a finding"; fi
# a scope token that contradicts the filename rekeys every row of that file
TESTS=$((TESTS + 1))
if contains "$out" "REQ_Thermal.*\[id-scope-mismatch\].*'XYZ'.*'THM'"; then ok x; else
  fail "id-scope-mismatch must name both the id scope and the filename token"; fi

# ==========================================================================
# Fixture 3: German/English twin vaults - byte-identical content, differing
# only in domain folder names and template FILE names. Everything the
# language-independence fix governs must behave identically in both, so the
# finding-code multisets are compared directly.
#
# Only ARC, IMP and REF are used: those three keep the same (ABBR) in both
# languages, which isolates the file-naming variable. Deliberately NOT
# covered here, because they are out of scope by decision (DECISIONS.md,
# amendment 2026-07-28): German domain abbreviations (ANF/ENT/KMP/SST/TUE/
# BUN) never reach the REQ/DEC/TAE checks, and the English-only heuristics
# (system_overview.md, "References"/"Sources" section names) stay dark - the
# twins therefore carry no overview file, and both are equally unaffected.
#
# Separate mktemp roots on purpose: check_paths probes project_root.parent,
# so a shared root would let one twin resolve the other twin's artifacts.
# ==========================================================================
DE_TMP=$(mktemp -d)
EN_TMP=$(mktemp -d)
trap 'rm -rf "$TMP" "$DE_TMP" "$EN_TMP"' EXIT

build_twin() { # build_twin <vault_dir> <arc_dir> <imp_dir> <ref_dir> <template_infix>
  local V="$1" A="$2" I="$3" R="$4" T="$5"
  mkdir -p "$V/$A" "$V/$I" "$V/$R"

  cat > "$V/$A/00_ARC_$T.md" <<'EOF'
## Kontext
## Komponenten (Dateien)
## Zuordnung und Verifikation
EOF
  cat > "$V/$I/00_IMP_$T.md" <<'EOF'
## Kontext
## Referenzen
## Implementierung
EOF
  cat > "$V/$R/00_REF_$T.md" <<'EOF'
## Quelle(n)
## Kontext
## Inhalt
EOF

  # seeded: code-fence + impl-leak + link-unresolved + id-duplicate (with
  # ARC_Unvollstaendig below). Identifiers go through this one function on
  # purpose: both twins must stay byte-identical in content.
  cat > "$V/$A/ARC_Messkette.md" <<'EOF'
---
domain: ARC
id: ARC-MES-001
status: active
created: 2026-01-09
last-verified: 2026-07-01
zustaendig: niemand
---
## Kontext
Die Messkette digitalisiert die analogen Eingangssignale des Moduls.
Der Teiler liefert 3,3 V an die Wandlerstufe.

## Komponenten (Dateien)
- [[KMP_Fehlt_Absichtlich]]: absichtlich totes Linkziel.

```c
int leak = 1;
```

## Zuordnung und Verifikation
| Teilmodul | Anforderungen | Verifikation | Status |
| --- | --- | --- | --- |
| Wandler | keine | keine | Draft |
EOF

  # seeded: template-sections (missing "Zuordnung und Verifikation") +
  # the second half of the id-duplicate pair
  cat > "$V/$A/ARC_Unvollstaendig.md" <<'EOF'
---
domain: ARC
id: ARC-MES-001
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Kontext
Zweites Architekturmodul, dem eine vom Template geforderte Sektion fehlt.
Der Rest des Inhalts ist bewusst unauffaellig gehalten.

## Komponenten (Dateien)
- Keine Komponenten diesem Modul zugeordnet.
- Zweite Zeile gegen die Stub-Warnung.
EOF

  # seeded: frontmatter-missing + path-missing
  cat > "$V/$I/IMP_Messkette.md" <<'EOF'
## Kontext
Konkrete Realisierung der Messkette ohne jede Frontmatter.

## Referenzen
- Datenblatt: 50_Quellen/fehlt_absichtlich.pdf

## Implementierung
- Abtastung fest eingestellt
- Zweite Zeile gegen die Stub-Warnung
EOF

  # clean file: contributes only the vault-wide orphan warning
  cat > "$V/$R/REF_Datenblatt.md" <<'EOF'
---
domain: REF
id: REF-MES-001
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Quelle(n)
- Herstellerdatenblatt des Wandlers

## Kontext
Externe Quelle zur Linearitaetsangabe der Wandlerstufe.

## Inhalt
### Kapitel Spezifikationen
- Linearitaetsangabe stuetzt die Genauigkeitsforderung
EOF
}

DE_V="$DE_TMP/Deproj/00_Dokumentation/01_Projektvault"
EN_V="$EN_TMP/Enproj/00_documentation/01_projectvault"
build_twin "$DE_V" "03_Architektur_(ARC)" "06_Implementierung_(IMP)" \
           "09_Referenzen_(REF)" "Dateitemplate"
build_twin "$EN_V" "03_architecture_(ARC)" "06_implementation_(IMP)" \
           "09_references_(REF)" "file_template"

# 02_Dokumente mirror: same German domain folder names, NO template files.
# It must stay unrecognized - link resolution depends on that distinction.
DE_MIRROR="$DE_TMP/Deproj/00_Dokumentation/02_Dokumente"
mkdir -p "$DE_MIRROR/03_Architektur_(ARC)" "$DE_MIRROR/06_Implementierung_(IMP)" \
         "$DE_MIRROR/09_Referenzen_(REF)"
echo "Export ohne Template" > "$DE_MIRROR/03_Architektur_(ARC)/Export.md"

de_out=$(python3 "$VALIDATOR" "$DE_V" 2>&1); de_rc=$?
en_out=$(python3 "$VALIDATOR" "$EN_V" 2>&1); en_rc=$?

# recognized at all: exit 1 (findings), never 2 ("could not run")
TESTS=$((TESTS + 1))
if [ $de_rc -eq 1 ]; then ok x; else
  fail "German vault must be recognized and exit 1, got $de_rc:"; printf '%s\n' "$de_out" | sed 's/^/    /'
fi
TESTS=$((TESTS + 1))
if [ $en_rc -eq 1 ]; then ok x; else fail "English twin must exit 1, got $en_rc"; fi

# template sections derived from 00_*Dateitemplate.md - check_sections
# returns early when no template was found, so this code cannot fire unless
# the German template files were actually parsed.
TESTS=$((TESTS + 1))
if contains "$de_out" "\[template-sections\]"; then ok x; else
  fail "German vault must derive template sections (no [template-sections] finding)"; fi
TESTS=$((TESTS + 1))
if contains "$de_out" "Zuordnung und Verifikation"; then ok x; else
  fail "German template section name must appear in the template-sections message"; fi

# identical findings for identical content
codes_of() { printf '%s\n' "$1" | grep -E '^(ERROR|WARN) ' | awk '{print $1, $3}' | sort; }
TESTS=$((TESTS + 1))
if [ "$(codes_of "$de_out")" = "$(codes_of "$en_out")" ]; then ok x; else
  fail "German and English twin must produce identical findings:"
  diff <(codes_of "$de_out") <(codes_of "$en_out") | sed 's/^/    /'
fi

# the identifier scheme is language-independent by construction: the id is
# neither a folder name nor a section heading, so it must be detected in the
# German twin exactly as in the English one
TESTS=$((TESTS + 1))
if contains "$de_out" "\[id-duplicate\].*ARC-MES-001"; then ok x; else
  fail "German twin must detect the seeded id collision"; fi
# neither twin lives in a repository: the vanished check must skip silently
TESTS=$((TESTS + 1))
if ! contains "$de_out" "id-vanished" && ! contains "$en_out" "id-vanished"; then ok x; else
  fail "vault outside version control must not report vanished identifiers"; fi

# the mirror without template files stays unrecognized, via both entry points
python3 "$VALIDATOR" "$DE_MIRROR" >/dev/null 2>&1; rc=$?
TESTS=$((TESTS + 1))
if [ $rc -eq 2 ]; then ok x; else
  fail "German 02_Dokumente mirror must not be a vault root, got $rc"; fi
python3 "$VALIDATOR" --file "$DE_MIRROR/03_Architektur_(ARC)/Export.md" >/dev/null 2>&1; rc=$?
TESTS=$((TESTS + 1))
if [ $rc -eq 2 ]; then ok x; else
  fail "--file inside the German mirror must find no vault root, got $rc"; fi

# --file auto-detects the German vault root by walking upward
out=$(python3 "$VALIDATOR" --file "$DE_V/03_Architektur_(ARC)/ARC_Unvollstaendig.md" 2>&1); rc=$?
TESTS=$((TESTS + 1))
if [ $rc -ne 2 ] && contains "$out" "\[template-sections\]"; then ok x; else
  fail "--file must auto-detect the German vault root, got rc=$rc"; fi

# ==========================================================================
# Fixture 4: identity vault UNDER version control - the only fixture with a
# real repository. Two behaviours need one: the vanished-identifier check
# reads git HEAD, and rename survival needs a committed state to survive.
#
# The violation vault deliberately stays outside version control: a populated
# HEAD baseline there would make every seeded ERROR pre-existing, and both
# "stop hook must block" assertions would invert.
#
# Hermetic git on purpose. A CI runner has no user identity configured
# ("Author identity unknown", exit 128), and ambient global config can inject
# hooks, a template dir or gpg signing - the last of which hangs on a
# passphrase prompt rather than failing.
# ==========================================================================
ID_TMP=$(mktemp -d)
trap 'rm -rf "$TMP" "$DE_TMP" "$EN_TMP" "$ID_TMP"' EXIT

# Every other fixture assumes mktemp dirs lie outside any repository - the
# whole "not under version control" branch depends on it. Make it explicit.
TESTS=$((TESTS + 1))
if ! git -C "$ID_TMP" rev-parse --show-toplevel >/dev/null 2>&1; then ok x; else
  fail "TMPDIR lies inside a git repository - fixture isolation is void"; fi

hgit() { # git, independent of whatever this machine has configured globally
  env GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null \
      GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
      GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t \
      git -C "$ID_TMP/Idproj" "$@"
}

I="$ID_TMP/Idproj/00_documentation/01_projectvault"
mkdir -p "$I/01_requirements_(REQ)" "$I/03_architecture_(ARC)" \
         "$I/07_testing_and_evidence_(TAE)"
printf '## Context\n' > "$I/01_requirements_(REQ)/00_REQ_file_template.md"
printf '## Context\n' > "$I/03_architecture_(ARC)/00_ARC_file_template.md"
printf '## Context\n## Evidence\n' > "$I/07_testing_and_evidence_(TAE)/00_TAE_file_template.md"

# NO parenthesised scope token in the filename: the scope comes from the id
# alone. This is the rename-survival case issue #3 describes.
cat > "$I/01_requirements_(REQ)/REQ_Thermal.md" <<'EOF'
---
domain: REQ
id: REQ-THM-000
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Thermal requirements of the module. This file carries no scope token in its
filename; its rows are addressed as REQ-THM-NNN because the frontmatter id
says so, which is what makes a rename harmless.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source / Justification (REF/DEC) |
| ------------- | --: | ------- | -------------------- | -------------------------------- |
| M | 001 | Case temperature stays below the limit | Pass if measured below the limit | none |
EOF

# The mirror image: scope token in the filename, no id at all - the state
# every vault predating the identifier scheme is in.
cat > "$I/01_requirements_(REQ)/REQ_Power (PWR).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Power requirements. No frontmatter id at all, so the scope token can only
come from the parentheses in the filename - the fallback that keeps every
legacy vault working unchanged.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source / Justification (REF/DEC) |
| ------------- | --: | ------- | -------------------- | -------------------------------- |
| M | 001 | Idle current stays below the budget | Pass if measured below the budget | none |
EOF

cat > "$I/07_testing_and_evidence_(TAE)/TAE_Thermal.md" <<'EOF'
---
domain: TAE
id: TAE-THM-001
status: active
created: 2026-01-10
last-verified: 2026-07-01
verifies: [REQ-THM-001, REQ-PWR-001]
---
## Context
Verifies one requirement resolved through the frontmatter id and one through
the filename fallback. If either resolution path breaks, the corresponding
id turns into a verifies-unknown-req ERROR - so the ABSENCE of that code is
the assertion.

## Evidence
| Quantity | Value |
| -------- | ----- |
| Case temperature | below limit |
EOF

cat > "$I/03_architecture_(ARC)/ARC_Thermal.md" <<'EOF'
---
domain: ARC
id: ARC-THM-001
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Context
Thermal module. Deleted from the worktree further below, after being
committed, so that its identifier is the one that vanishes.
EOF

# Committed WITH its qualifier heading, so the near-miss ERROR is part of
# this file's git HEAD state. The stop gate must therefore not treat it as
# introduced this session - the ratchet is what keeps a new finding class
# from blocking on legacy content.
cat > "$I/03_architecture_(ARC)/ARC_Qualifier.md" <<'EOF'
---
domain: ARC
id: ARC-THM-002
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Context (draft)
Architecture note whose required heading carries a qualifier, committed in
that state. Its section-mismatch ERROR is pre-existing, not introduced.
EOF

# Unborn HEAD: a repository without a single commit must not crash the
# validator. Exit 2 would make both hooks fail open - enforcement silently off.
hgit init -q
out=$(python3 "$VALIDATOR" "$I" 2>&1); rc=$?
TESTS=$((TESTS + 1))
if [ $rc -ne 2 ] && ! contains "$out" "id-vanished"; then ok x; else
  fail "unborn HEAD must neither crash nor report vanished ids, got rc=$rc"; fi

# Both resolution paths at once: REQ-THM-001 can only resolve through the id,
# REQ-PWR-001 only through the filename token.
TESTS=$((TESTS + 1))
if ! contains "$out" "verifies-unknown-req"; then ok x; else
  fail "REQ scope must resolve from the id AND from the filename:"
  printf '%s\n' "$out" | grep verifies-unknown-req | sed 's/^/    /'
fi

hgit add -A >/dev/null 2>&1
hgit commit -q --no-verify --no-gpg-sign -m "identity fixture baseline" >/dev/null 2>&1
TESTS=$((TESTS + 1))
if hgit rev-parse --verify --quiet HEAD >/dev/null 2>&1; then ok x; else
  fail "hermetic commit failed - fixture 4 cannot run"; fi

# Clean tree: HEAD and worktree agree, nothing may be reported as vanished.
out=$(python3 "$VALIDATOR" "$I" 2>&1); rc=$?
TESTS=$((TESTS + 1))
if [ $rc -ne 2 ] && ! contains "$out" "id-vanished"; then ok x; else
  fail "clean worktree must report no vanished identifier, got rc=$rc"; fi

# A pre-existing near-miss ERROR must not block the stop gate. The baseline
# is recomputed from git HEAD by the running validator, so a finding class
# that did not exist when the file was committed still lands in the baseline
# - this asserts that mechanism rather than assuming it.
SIDR="testsession-ratchet-$$"
rm -f "/tmp/claude-mechdocs/touched-$SIDR" "/tmp/claude-mechdocs/baseline-$SIDR" \
      "/tmp/claude-mechdocs/blocks-$SIDR"
printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' "$SIDR" \
  "$I/03_architecture_(ARC)/ARC_Qualifier.md" | python3 "$VALIDATOR" --hook post >/dev/null 2>&1
rout=$(printf '{"session_id":"%s"}' "$SIDR" | python3 "$VALIDATOR" --hook stop 2>&1)
TESTS=$((TESTS + 1))
if ! contains "$rout" '"decision": "block"'; then ok x; else
  fail "a pre-existing section-mismatch must not block the stop gate:"
  printf '%s\n' "$rout" | sed 's/^/    /'
fi
rm -f "/tmp/claude-mechdocs/touched-$SIDR" "/tmp/claude-mechdocs/baseline-$SIDR" \
      "/tmp/claude-mechdocs/blocks-$SIDR"

# The object disappears from the worktree while HEAD still carries it.
rm -f "$I/03_architecture_(ARC)/ARC_Thermal.md"
out=$(python3 "$VALIDATOR" "$I" 2>&1); rc=$?
TESTS=$((TESTS + 1))
if contains "$out" "^WARN .*\[id-vanished\].*ARC-THM-001"; then ok x; else
  fail "deleted object must report its identifier as vanished:"
  printf '%s\n' "$out" | sed 's/^/    /'
fi
# WARN and never ERROR: retirement, rename and accidental loss cannot be told
# apart, and a gate that blocks on all three teaches its user to ignore it.
TESTS=$((TESTS + 1))
if ! contains "$out" "^ERROR .*id-vanished"; then ok x; else
  fail "id-vanished must never be an ERROR"; fi
# Identifiers that are still present must not be swept up by the diff.
TESTS=$((TESTS + 1))
if ! contains "$out" "id-vanished.*REQ-THM-000" && ! contains "$out" "id-vanished.*TAE-THM-001"; then
  ok x; else fail "surviving identifiers must not be reported as vanished"; fi

# The promise of the whole scheme: renaming a file changes neither its own
# identifier nor the identity of the rows it carries.
mv "$I/01_requirements_(REQ)/REQ_Thermal.md" \
   "$I/01_requirements_(REQ)/REQ_Thermal_Chain.md"
out=$(python3 "$VALIDATOR" "$I" 2>&1); rc=$?
TESTS=$((TESTS + 1))
if [ $rc -ne 2 ] && ! contains "$out" "REQ-THM-000" && ! contains "$out" "verifies-unknown-req"; then
  ok x; else
  fail "a renamed REQ file must keep its identifier and its row identities:"
  printf '%s\n' "$out" | grep -E "REQ-THM|verifies-unknown-req" | sed 's/^/    /'
fi

# ==========================================================================
# Fixture 5: the schema itself. The validator reads vault_schema.json from
# beside its own file, so a copy of the validator into a directory holding a
# different schema is a full A/B test of "is this actually data-driven?" -
# without touching a single line of Python.
# ==========================================================================
SC_TMP=$(mktemp -d)
trap 'rm -rf "$TMP" "$DE_TMP" "$EN_TMP" "$ID_TMP" "$SC_TMP"' EXIT

# (a) unreadable schema: must WARN, must fall back, must NOT exit 2. Exit 2 is
# reserved for a real crash, and both hooks swallow it - a schema typo that
# silently disabled enforcement would be the worst possible failure mode.
mkdir -p "$SC_TMP/broken"
cp "$VALIDATOR" "$SC_TMP/broken/validate_vault.py"
printf '{ this is not json' > "$SC_TMP/broken/vault_schema.json"
out=$(python3 "$SC_TMP/broken/validate_vault.py" "$W" 2>&1); rc=$?
TESTS=$((TESTS + 1))
if [ $rc -eq 1 ]; then ok x; else fail "unreadable schema must exit 1, not $rc"; fi
TESTS=$((TESTS + 1))
if contains "$out" "\[schema-unreadable\]"; then ok x; else
  fail "unreadable schema must be reported, not silently ignored"; fi
TESTS=$((TESTS + 1))
n=$(printf '%s' "$out" | grep -c "schema-unreadable") || true
if [ "$n" -eq 1 ]; then ok x; else
  fail "schema-unreadable must be reported once per vault, got $n"; fi
# the fallback must still enforce: the seeded violations stay detected
TESTS=$((TESTS + 1))
if contains "$out" "\[frontmatter-status\]" && contains "$out" "\[req-class\]" \
   && contains "$out" "\[dec-status\]"; then ok x; else
  fail "the built-in fallback must keep enforcing the essentials"; fi

# (b) a schema that DECLARES the stray key: the very same vault, the very same
# Python, one datum changed - and the finding disappears. This is the whole
# claim of issue #4 in one assertion.
mkdir -p "$SC_TMP/declared"
cp "$VALIDATOR" "$SC_TMP/declared/validate_vault.py"
python3 - "$SKILL_DIR/vault_schema.json" "$SC_TMP/declared/vault_schema.json" <<'PY'
import json, sys
s = json.load(open(sys.argv[1]))
s["domain_defaults"]["fields"]["owner"] = {
    "type": "enum", "values": ["nobody"], "required": False,
    "code": "frontmatter-owner", "enforced": "schema-driven"}
json.dump(s, open(sys.argv[2], "w"))
PY
out2=$(python3 "$SC_TMP/declared/validate_vault.py" "$W" 2>&1)
TESTS=$((TESTS + 1))
if ! contains "$out2" "\[frontmatter-undeclared\].*'owner'"; then ok x; else
  fail "declaring a field in the schema must stop it being undeclared"; fi
TESTS=$((TESTS + 1))
if contains "$out2" "\[frontmatter-undeclared\].*'crated'"; then ok x; else
  fail "declaring 'owner' must not silence the other stray key"; fi
# and the newly declared field is now value-checked, from data alone
TESTS=$((TESTS + 1))
if ! contains "$out2" "frontmatter-owner"; then ok x; else
  fail "'owner: nobody' matches the declared value list and must not be flagged"; fi

# (c) a schema that parses but declares nonsense must not crash a consumer.
# check_dec_status and check_req_table read nested keys; a scalar where an
# object belongs would raise TypeError -> exit 2 -> hooks fail open.
mkdir -p "$SC_TMP/nonsense"
cp "$VALIDATOR" "$SC_TMP/nonsense/validate_vault.py"
printf '{"domain_defaults": 5, "domains": {"DEC": {"body_fields": {"Status": 7}}, "REQ": {"rows": []}}, "editor_fields": null}' \
  > "$SC_TMP/nonsense/vault_schema.json"
python3 "$SC_TMP/nonsense/validate_vault.py" "$W" >/dev/null 2>&1; rc=$?
TESTS=$((TESTS + 1))
if [ $rc -ne 2 ]; then ok x; else
  fail "a structurally invalid schema must not crash the validator"; fi

# (d) drift guards. The identifier patterns stay Python constants on purpose
# (they decide what is compared against git HEAD), so nothing but a test keeps
# them in step with the patterns this schema declares.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" <<'PY'
import json, re, sys
sys.path.insert(0, sys.argv[1])
import validate_vault as vv
s = json.load(open(sys.argv[1] + "/vault_schema.json"))
ident = re.compile(s["identifier"]["pattern"])
req = re.compile(s["domains"]["REQ"]["rows"]["id_pattern"])
samples = ["REQ-BAT-001", "ARC-MEG-010", "REQ-B-1", "arc-bat-001", "REQ-BATTERY-001",
           "ARC-DOM-NNN", "REQ-BAT-0001", "", "REQ-BAT-00"]
for x in samples:
    assert bool(ident.match(x)) == bool(vv.ID_RE.match(x)), f"identifier.pattern vs ID_RE: {x!r}"
    assert bool(req.fullmatch(x)) == bool(vv.REQ_ID_RE.fullmatch(x)), f"rows.id_pattern vs REQ_ID_RE: {x!r}"
assert s["identifier"]["excluded_domains"] == list(vv.ID_EXCLUDED_DOMAINS), "excluded_domains drift"
PY
then ok x; else fail "schema patterns and validator constants have drifted apart"; fi

# The embedded fallback is the path taken exactly when nobody is looking, so
# it must agree with the shipped schema on what is required and permitted.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import validate_vault as vv
from pathlib import Path
real, err = vv.load_schema(Path(sys.argv[1]) / "vault_schema.json")
assert err is None, err
def profile(schema, abbr):
    out = {}
    for name, d in schema.get("domain_defaults", {}).get("fields", {}).items():
        out[name] = dict(d)
    for name, d in schema.get("domains", {}).get(abbr, {}).get("fields", {}).items():
        out[name] = {**out.get(name, {}), **d}
    return {k: (v.get("required"), v.get("enforced"), tuple(v.get("values", [])))
            for k, v in out.items()}
for abbr in ("REQ", "DEC", "TAE", "ARC", "ANF"):
    assert profile(real, abbr) == profile(vv.FALLBACK_SCHEMA, abbr), f"fallback drift in {abbr}"
PY
then ok x; else fail "FALLBACK_SCHEMA and vault_schema.json have drifted apart"; fi

# Every named domain must resolve to the same vocabulary as an unnamed one.
# The undeclared check is language-symmetric only as long as that holds; a
# future domain-exclusive field has to break this test and think about it.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import validate_vault as vv
from pathlib import Path
schema, _ = vv.load_schema(Path(sys.argv[1]) / "vault_schema.json")
base = set(schema["domain_defaults"]["fields"])
for abbr, entry in schema["domains"].items():
    extra = set(entry.get("fields", {})) - base
    assert not extra, f"{abbr} declares {extra} outside the shared vocabulary"
PY
then ok x; else fail "a domain-exclusive field breaks language symmetry of the undeclared check"; fi

# ==========================================================================
# parse_frontmatter: the two list spellings, and the lines that stay broken
# ==========================================================================
# Asserted at the parser rather than through a fixture vault, because the
# claim is an equality between two spellings and no finding can express it:
# a vault-level test can only show that neither spelling produces a finding,
# which is also true if both are parsed wrongly in the same way.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from validate_vault import parse_frontmatter as pf

def fm(body):
    return pf(("---\n" + body + "---\n").splitlines())

inline = fm("tags: [a, b]\n")
indented = fm("tags:\n  - a\n  - b\n")
flush = fm("tags:\n- a\n- b\n")          # the Obsidian documentation's own spelling
for name, got in (("indented", indented), ("unindented", flush)):
    assert got[0] == inline[0], f"{name} block list != inline list: {got[0]} vs {inline[0]}"
    assert got[2] is None, f"{name} block list reported malformed: {got[2]}"
assert inline[0] == {"tags": ["a", "b"]}, inline[0]

# quotes are stripped the way the inline path strips them, and neither a
# blank line nor a comment ends a sequence - both are true of YAML
assert fm('aliases:\n  - "Weekly review"\n')[0] == {"aliases": ["Weekly review"]}
assert fm("tags:\n\n  - a\n")[0] == {"tags": ["a"]}
assert fm("tags:\n  # a note\n  - a\n")[0] == {"tags": ["a"]}
# a following key closes the sequence, and two sequences do not bleed
assert fm("tags:\n  - a\nstatus: active\n")[0] == {"tags": ["a"], "status": "active"}
assert fm("tags:\n- a\naliases:\n- b\n")[0] == {"tags": ["a"], "aliases": ["b"]}
# a key with nothing under it keeps the empty string it has always had:
# '[]' would newly fire verifies-empty on files nobody touched
assert fm("verifies:\nstatus: active\n")[0] == {"verifies": "", "status": "active"}
# 'verifies' is what actually has to survive the fold
assert fm("verifies:\n  - REQ-MEG-001\n  - REQ-MEG-002\n")[0] == {
    "verifies": ["REQ-MEG-001", "REQ-MEG-002"]}
PY
then ok x; else fail "the inline and block spellings of a list must fold into one list"; fi

# Negative controls. Accepting one more spelling must not make the reader
# permissive, so each of these stays a malformed-frontmatter message. They
# are asserted as 'a message exists', never by its wording: freezing the
# text here would make every future rewording a test failure.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from validate_vault import parse_frontmatter as pf

def bad(body):
    fm, _, msg = pf(("---\n" + body + "---\n").splitlines())
    return fm is None and bool(msg)

assert bad("- a\ndomain: REQ\n"),        "a sequence at the top level is not a mapping"
assert bad("tags:\n-\ta\n"),             "a tab after the dash is not YAML"
assert bad("tags:\n\t- a\n"),            "a tab as indentation is not YAML"
assert bad("tags:\n  - key: value\n"),   "a mapping inside an item is not read by this reader"
assert bad("tags:\n  - a\n    - b\n"),   "an item indented differently is not a sibling"
assert bad("foo:\n  bar:\n  - x\n"),     "an indented key is a nested mapping"
assert bad("tags: [a]\n- b\n"),          "a sequence cannot follow an inline list"
assert bad("tags:\n-- a\n"),             "'--' does not open a list item"
assert bad("domain: IMP\n: broken\n"),   "a line without a key stays broken"
# a colon with no space after it is a plain scalar in YAML, and stays one here
assert pf("---\ntags:\n  - foo:bar\n---\n".splitlines())[0] == {"tags": ["foo:bar"]}

# Frontmatter without a closing marker is reported AND handed end_line 0, so
# check_leaks and check_paths still see the body. Returning the end of file
# instead would let one missing marker switch the body checks off - the same
# trap req_rows closes for an unclosed fence.
fm, end, msg = pf("---\ndomain: IMP\ntags:\n- hardware\n\n## Context\n\n- a bullet\n".splitlines())
assert fm is None and msg, "an unclosed frontmatter must still be reported"
assert end == 0, f"an unclosed frontmatter must not hide the body, got end_line {end}"
PY
then ok x; else fail "a genuinely malformed frontmatter line must still be reported"; fi

# ==========================================================================
# Fixture 6: a template whose own required headings are prefixes of each
# other. No vault has such a pair today (measured across all six), so only a
# fixture can keep the classification deterministic and sane: writing the
# longer section must not silently satisfy the shorter requirement.
# ==========================================================================
PF_TMP=$(mktemp -d)
trap 'rm -rf "$TMP" "$DE_TMP" "$EN_TMP" "$ID_TMP" "$SC_TMP" "$PF_TMP"' EXIT

PF="$PF_TMP/Prefixproj/00_documentation/01_projectvault"
mkdir -p "$PF/03_architecture_(ARC)" "$PF/06_implementation_(IMP)" \
         "$PF/09_references_(REF)"
printf '## Kontext\n## Kontext und Ziel\n' > "$PF/03_architecture_(ARC)/00_ARC_file_template.md"
printf '## Kontext\n' > "$PF/06_implementation_(IMP)/00_IMP_file_template.md"
printf '## Kontext\n' > "$PF/09_references_(REF)/00_REF_file_template.md"

cat > "$PF/03_architecture_(ARC)/ARC_Prefix.md" <<'EOF'
---
domain: ARC
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Kontext und Ziel
Architecture note carrying only the longer of two required headings whose
shorter form is a prefix of it. The shorter one is genuinely not written.
EOF

out=$(python3 "$VALIDATOR" "$PF" 2>&1); rc=$?
TESTS=$((TESTS + 1))
if [ $rc -ne 2 ]; then ok x; else
  fail "a template with prefix-related required headings must not crash the validator"; fi
TESTS=$((TESTS + 1))
if contains "$out" "ARC_Prefix\.md.*\[section-mismatch\].*template 'Kontext' vs 'Kontext und Ziel' (line 7)"; then
  ok x; else fail "the unwritten shorter requirement must be reported against the longer heading:"
  printf '%s\n' "$out" | grep ARC_Prefix | sed 's/^/    /'
fi
TESTS=$((TESTS + 1))
if ! contains "$out" "ARC_Prefix\.md.*\[template-sections\]"; then ok x; else
  fail "the longer heading is written exactly and must not be reported missing"; fi

# ==========================================================================
# Hook modes (violation vault, synthetic payloads)
# ==========================================================================
SID="testsession-$$"
rm -f "/tmp/claude-mechdocs/touched-$SID" "/tmp/claude-mechdocs/baseline-$SID" \
      "/tmp/claude-mechdocs/blocks-$SID"
payload() { printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' "$SID" "$1"; }

hout=$(payload "$W/03_architecture_(ARC)/ARC_Leaky.md" | python3 "$VALIDATOR" --hook post 2>&1); rc=$?
check "post hook exits 0" $rc
TESTS=$((TESTS + 1))
if contains "$hout" "impl-leak" && contains "$hout" "additionalContext"; then ok x; else
  fail "post hook must feed impl-leak back as additionalContext"; fi
TESTS=$((TESTS + 1))
if contains "$hout" "4 unresolved link target"; then ok x; else
  fail "post hook must aggregate unresolved links into one summary"; fi
# A same-file anchor reaches the aggregation by the same path as a file
# link: hook_post re-extracts the target out of the message text, and an
# anchor is the one target shape that carries a '#'.
TESTS=$((TESTS + 1))
if contains "$hout" "\[\[#No Such Heading\]\]"; then ok x; else
  fail "an unresolved same-file anchor must survive the aggregation by name"; fi
TESTS=$((TESTS + 1))
n=$(printf '%s' "$hout" | grep -o 'link-unresolved' | wc -l)
if [ "$n" -eq 1 ]; then ok x; else
  fail "post hook must emit exactly one link-unresolved line, got $n"; fi

sout=$(printf '{"session_id":"%s"}' "$SID" | python3 "$VALIDATOR" --hook stop 2>&1)
TESTS=$((TESTS + 1))
if contains "$sout" '"decision": "block"'; then ok x; else fail "stop hook must block on new ERRORs (1st attempt)"; fi
TESTS=$((TESTS + 1))
if ! contains "$sout" "vault-wide"; then ok x; else
  fail "block reason must not carry the vault-wide advisory section"; fi
sout=$(printf '{"session_id":"%s","stop_hook_active":true}' "$SID" | python3 "$VALIDATOR" --hook stop 2>&1)
TESTS=$((TESTS + 1))
if contains "$sout" '"decision": "block"'; then ok x; else fail "stop hook must block on 2nd attempt"; fi
sout=$(printf '{"session_id":"%s","stop_hook_active":true}' "$SID" | python3 "$VALIDATOR" --hook stop 2>&1)
TESTS=$((TESTS + 1))
if contains "$sout" "UNRESOLVED"; then ok x; else fail "stop hook must fail open with report on 3rd attempt"; fi
TESTS=$((TESTS + 1))
if ! contains "$sout" '"decision": "block"'; then ok x; else fail "stop hook must not block a 3rd time"; fi
TESTS=$((TESTS + 1))
if contains "$sout" "vault-wide findings (advisory" && contains "$sout" "req-uncovered"; then ok x; else
  fail "fail-open report must carry vault-wide advisory incl. req-uncovered"; fi

# post hook outside any vault: silent no-op
hout=$(payload "/tmp/not_a_vault_note.md" | python3 "$VALIDATOR" --hook post 2>&1); rc=$?
TESTS=$((TESTS + 1))
if [ $rc -eq 0 ] && [ -z "$hout" ]; then ok x; else fail "post hook outside vault must be a silent no-op"; fi

# clean precision file: post hook silent, stop report free of advisory noise
SID2="testsession2-$$"
rm -f "/tmp/claude-mechdocs/touched-$SID2" "/tmp/claude-mechdocs/baseline-$SID2" \
      "/tmp/claude-mechdocs/blocks-$SID2"
hout=$(printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' "$SID2" \
  "$V/06_implementation_(IMP)/IMP_MainBoard_ADC.md" | python3 "$VALIDATOR" --hook post 2>&1); rc=$?
check "post hook on clean file exits 0" $rc
TESTS=$((TESTS + 1))
if [ -z "$hout" ]; then ok x; else fail "post hook on clean file must stay silent"; fi
sout=$(printf '{"session_id":"%s"}' "$SID2" | python3 "$VALIDATOR" --hook stop 2>&1)
TESTS=$((TESTS + 1))
if ! contains "$sout" "vault-wide"; then ok x; else
  fail "clean vault stop report must not add a vault-wide section"; fi
rm -f "/tmp/claude-mechdocs/touched-$SID2" "/tmp/claude-mechdocs/baseline-$SID2" \
      "/tmp/claude-mechdocs/blocks-$SID2"

# ==========================================================================
# Crash mode and real template vault
# ==========================================================================
python3 "$VALIDATOR" /nonexistent_vault_root >/dev/null 2>&1; rc=$?
TESTS=$((TESTS + 1))
if [ $rc -eq 2 ]; then ok x; else fail "invalid root must exit 2, got $rc"; fi

TESTS=$((TESTS + 1))
if [ -d "$REAL_VAULT" ]; then
  out=$(python3 "$VALIDATOR" "$REAL_VAULT" 2>&1); rc=$?
  if [ $rc -eq 0 ]; then ok x; else
    fail "real template vault must contain no ERRORs:"; printf '%s\n' "$out" | grep '^ERROR' | sed 's/^/    /'
  fi
else
  # A missing REAL_VAULT used to pass silently, which hid the guard
  # entirely when run.sh was invoked through the ~/.claude/skills symlink.
  fail "real template vault not found at $REAL_VAULT"
fi

# ==========================================================================
# Fixture 7: the traceability exporter. One vault carrying every construct
# the production corpora actually contain - a range, a number continuation,
# a prose subject, a qualified status, an identifier that does not exist, a
# table quoted inside a code fence, an escaped pipe, a script tag and a
# spreadsheet formula - built twice, once in English and once in German.
#
# The two builds must produce the same numbers. That is the whole point of
# binding relations to the section the project's own template declares:
# measured on the real vaults, the header row drifts and the section title
# does not.
# ==========================================================================
EXPORTER="$SKILL_DIR/export_traceability.py"
EX_TMP=$(mktemp -d)
trap 'rm -rf "$TMP" "$DE_TMP" "$EN_TMP" "$EX_TMP"' EXIT

build_export_vault() { # <vault_dir> <req_dir> <arc_dir> <tae_dir> <tmpl> <ctx>
                       # <alloc_sec> <iface_sec> <sub_sec> <req_abbr> <tae_abbr>
  local V="$1" RQ="$2" AR="$3" TA="$4" T="$5" CTX="$6" ALLOC="$7" IFACE="$8" \
        SUB="$9" P="${10}" EV="${11}"
  mkdir -p "$V/$RQ" "$V/$AR" "$V/$TA"

  printf '## %s\n\n| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n| --- | --: | --- | --- | --- |\n|  |  |  |  |  |\n' \
    "$CTX" > "$V/$RQ/00_${P}_$T.md"
  printf '## %s\n\n## %s\n| Interface | Endpoint A | Endpoint B | Context |\n| --- | --- | --- | --- |\n| a | b | c | d |\n\n## %s\n| Submodule | Allocated | Verification | Status |\n| --- | --- | --- | --- |\n| a | b | c | Draft |\n' \
    "$CTX" "$IFACE" "$ALLOC" > "$V/$AR/00_ARC_$T.md"
  printf '## %s\n\n## %s\n| Submodule | Description |\n| --- | --- |\n| a | b |\n' \
    "$CTX" "$SUB" > "$V/$AR/00_ARC_main_$T.md"
  printf '## %s\n' "$CTX" > "$V/$TA/00_${EV}_$T.md"

  # Requirement rows 001-005. Row 002 carries an escaped pipe, row 003 a
  # script tag and row 004 a leading '=' - the three payloads whose handling
  # decides whether the HTML and the CSV are safe to hand to anyone.
  {
    printf -- '---\ndomain: %s\nstatus: active\ncreated: 2026-07-31\nlast-verified: 2026-07-31\n---\n' "$P"
    printf '## %s\n\nRequirements of the export example.\n\n' "$CTX"
    printf 'A table quoted as documentation must not become data:\n\n'
    printf '```markdown\n| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n'
    printf '| --- | --: | --- | --- | --- |\n| M | 900 | quoted | quoted | none |\n```\n\n'
    printf '| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n'
    printf '| --- | --: | --- | --- | --- |\n'
    printf '| M | 001 | plain requirement | pass if plain | none |\n'
    printf '| M | 002 | value a \\| b in one cell | pass if one cell | none |\n'
    printf '| M | 003 | <script>alert(1)</script> | pass if escaped | none |\n'
    printf '| M | 004 | formula cell | =1+1 | none |\n'
    printf '| M | 005 | last one | pass if last | none |\n'
  } > "$V/$RQ/${P}_Export (EXP).md"

  {
    printf -- '---\ndomain: ARC\nstatus: active\ncreated: 2026-07-31\nlast-verified: 2026-07-31\n---\n'
    printf '## %s\n\nThe module under export.\n\n' "$CTX"
    printf '## %s\n| Submodule | Allocated | Verification | Status |\n' "$ALLOC"
    printf '| --- | --- | --- | --- |\n'
    printf '| [[ARC_Export]] | %s-EXP-001 | [[%s_Export]] | Verified |\n' "$P" "$EV"
    printf '| Tailnet resolver port 53 | %s-EXP-002 | [[%s_Export]] | Verified (Rebuild: Draft) |\n' "$P" "$EV"
    printf '| ranged | %s-EXP-003 bis %s-EXP-005 | [[%s_Export]] | Verified |\n' "$P" "$P" "$EV"
    printf '| continued | %s-EXP-001, 002 | [[%s_Export]] | Verified |\n' "$P" "$EV"
    printf '| ghost | %s-EXP-900 | prose only | Verified |\n' "$P"
    printf '| too wide | %s-EXP-004 bis %s-EXP-008 | [[%s_Export]] | Verified |\n' "$P" "$P" "$EV"
  } > "$V/$AR/ARC_Export.md"

  {
    printf -- '---\ndomain: ARC\nstatus: active\ncreated: 2026-07-31\nlast-verified: 2026-07-31\n---\n'
    printf '## %s\n\nTop module.\n\n' "$CTX"
    printf '## %s\n| Submodule | Description |\n| --- | --- |\n' "$SUB"
    printf '| [[ARC_Export]] | the module under export |\n'
  } > "$V/$AR/ARC_Top.md"

  {
    printf -- '---\ndomain: %s\nstatus: active\ncreated: 2026-07-31\nlast-verified: 2026-07-31\n' "$EV"
    printf 'verifies: [%s-EXP-001, %s-EXP-002]\n---\n' "$P" "$P"
    printf '## %s\n\nEvidence for the export example.\n' "$CTX"
  } > "$V/$TA/${EV}_Export.md"
}

EN_V="$EX_TMP/En/00_documentation/01_projectvault"
DE_V="$EX_TMP/De/00_Dokumentation/01_Projektvault"
build_export_vault "$EN_V" "01_requirements_(REQ)" "03_architecture_(ARC)" \
  "07_testing_and_evidence_(TAE)" "file_template" "Context" \
  "Allocation and Verification" "Interfaces" "Submodules" "REQ" "TAE"
build_export_vault "$DE_V" "01_Anforderungen_(ANF)" "03_Architektur_(ARC)" \
  "07_Test_und_Evidenz_(TUE)" "Dateitemplate" "Kontext" \
  "Zuordnung und Verifikation" "Schnittstellen" "Submodule" "ANF" "TUE"

EN_OUT="$EX_TMP/out-en"
DE_OUT="$EX_TMP/out-de"
eout=$(python3 "$EXPORTER" "$EN_V" --output-dir "$EN_OUT" --no-timestamp 2>&1); erc=$?
check "exporter exits 0 on a well-formed vault" $erc
dout=$(python3 "$EXPORTER" "$DE_V" --output-dir "$DE_OUT" --no-timestamp 2>&1)

TESTS=$((TESTS + 1))
if [ -f "$EN_OUT/traceability.json" ] && [ -f "$EN_OUT/traceability.html" ] && \
   [ -f "$EN_OUT/traceability_requirements.csv" ] && \
   [ -f "$EN_OUT/traceability_edges.csv" ]; then ok x; else
  fail "exporter must write json, html and both csv views"; fi

# The German twin must not be a smaller graph. This is the assertion the
# header-signature binding would have failed on every production vault.
en_counts=$(python3 - "$EN_OUT/traceability.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(len(d["requirements"]), sum(1 for c in d["coverage"].values() if c["proven"]),
      len(d["edges"]))
PY
)
de_counts=$(python3 - "$DE_OUT/traceability.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(len(d["requirements"]), sum(1 for c in d["coverage"].values() if c["proven"]),
      len(d["edges"]))
PY
)
TESTS=$((TESTS + 1))
if [ "$en_counts" = "$de_counts" ]; then ok x; else
  fail "German and English twin must export the same graph: '$en_counts' vs '$de_counts'"; fi
TESTS=$((TESTS + 1))
if [ "$en_counts" = "5 4 15" ]; then ok x; else
  fail "expected 5 requirements, 4 proven, 15 edges; got '$en_counts'"; fi

exq() { python3 - "$EN_OUT/traceability.json" "$1" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(eval(sys.argv[2], {"d": d, "sorted": sorted, "len": len, "any": any,
                         "all": all, "sum": sum}))
PY
}

TESTS=$((TESTS + 1))
if [ "$(exq 'any(f["code"]=="export-unresolved-requirement" for f in d["findings"])')" = "True" ]; then
  ok x; else fail "an identifier that exists nowhere must be reported"; fi
TESTS=$((TESTS + 1))
if [ "$(exq '"REQ-EXP-900" in d["requirements"]')" = "False" ]; then ok x; else
  fail "a requirement row quoted inside a code fence must not enter the graph"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'd["requirements"]["REQ-EXP-002"]["text"]')" = "value a | b in one cell" ]; then
  ok x; else fail "an escaped pipe must stay inside one cell"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'sorted(d["reverse"]["REQ-EXP-001"]["verifies_back"])')" = "['TAE:TAE_Export']" ]; then
  ok x; else fail "the reverse direction must be computed for a verified requirement"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'd["coverage"]["REQ-EXP-002"]["proven"]')" = "False" ]; then ok x; else
  fail "a qualified status must not count as proven"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'any(a["status_reason"]=="Verified (Rebuild: Draft)" for a in d["coverage"]["REQ-EXP-002"]["allocations"])')" = "True" ]; then
  ok x; else fail "a qualified status must carry its verbatim text as the reason"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'all(f"REQ-EXP-{n:03d}" in d["requirements"] and d["coverage"][f"REQ-EXP-{n:03d}"]["allocations"] for n in (3,4,5))')" = "True" ]; then
  ok x; else fail "a range whose members all exist must be expanded"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'any("008" in f["message"] for f in d["findings"] if f["code"]=="export-unresolved-requirement")')" = "True" ]; then
  ok x; else fail "a range reaching past the last requirement must be refused, not invented"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'any(a["owner_text"].startswith("Tailnet") for a in d["coverage"]["REQ-EXP-002"]["allocations"])')" = "True" ]; then
  ok x; else fail "a prose subject must survive as the owner"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'any(e["kind"]=="contains" for e in d["edges"])')" = "True" ]; then ok x; else
  fail "the main-module submodule table must yield an ARC-to-ARC edge"; fi
TESTS=$((TESTS + 1))
if [ "$(exq '"no-evidence-note" in d["coverage"]["REQ-EXP-005"]["open_questions"]')" = "True" ]; then
  ok x; else fail "a requirement no evidence note names must carry that open question"; fi

# Safety of the two artifacts a human opens.
TESTS=$((TESTS + 1))
if contains "$(head -1 "$EN_OUT/traceability.html")" 'charset="utf-8"'; then ok x; else
  fail "the report must declare its charset in the first line"; fi
TESTS=$((TESTS + 1))
if ! contains "$(cat "$EN_OUT/traceability.html")" '<script>alert'; then ok x; else
  fail "a script tag from the vault must not reach the report unescaped"; fi
TESTS=$((TESTS + 1))
if contains "$(cat "$EN_OUT/traceability.html")" '&lt;script&gt;alert'; then ok x; else
  fail "a script tag must appear escaped, not dropped"; fi
TESTS=$((TESTS + 1))
if contains "$(head -c 3 "$EN_OUT/traceability_requirements.csv" | od -An -tx1)" "ef bb bf"; then
  ok x; else fail "the CSV must carry a BOM so a spreadsheet reads it as UTF-8"; fi
TESTS=$((TESTS + 1))
if contains "$(cat "$EN_OUT/traceability_requirements.csv")" '"=1+1"'; then ok x; else
  fail "a formula-shaped cell must be exported verbatim as a record"; fi

# Determinism: the property, not just the timestamp.
cp -r "$EN_OUT" "$EX_TMP/out-en-ref"
python3 "$EXPORTER" "$EN_V" --output-dir "$EN_OUT" --no-timestamp >/dev/null 2>&1
TESTS=$((TESTS + 1))
if diff -r "$EX_TMP/out-en-ref" "$EN_OUT" >/dev/null 2>&1; then ok x; else
  fail "two runs of the exporter must produce byte-identical artifacts"; fi

# Refusals.
python3 "$EXPORTER" "$EN_V" --output-dir "$EN_V/01_requirements_(REQ)" \
  >/dev/null 2>&1; rc=$?
TESTS=$((TESTS + 1))
if [ $rc -eq 2 ]; then ok x; else
  fail "writing the export into the vault must be refused, got $rc"; fi
python3 "$EXPORTER" "$EX_TMP" --output-dir "$EX_TMP/nope" >/dev/null 2>&1; rc=$?
TESTS=$((TESTS + 1))
if [ $rc -eq 2 ]; then ok x; else fail "a non-vault path must exit 2, got $rc"; fi

# A domain nobody declared is reported rather than quietly skipped.
mkdir -p "$EN_V/06_unknown_(XYZ)"
printf '## Context\n' > "$EN_V/06_unknown_(XYZ)/00_XYZ_file_template.md"
python3 "$EXPORTER" "$EN_V" --output-dir "$EX_TMP/out-unknown" --no-timestamp \
  >/dev/null 2>&1
TESTS=$((TESTS + 1))
if contains "$(cat "$EX_TMP/out-unknown/traceability.json")" "export-unknown-domain"; then
  ok x; else fail "a domain abbreviation the alias map does not know must be reported"; fi
rm -rf "$EN_V/06_unknown_(XYZ)"

# ==========================================================================
# The cell splitter against the GFM tables extension, which is the only
# authority either tool has for what a row is made of. Examples 200 and 204
# are quoted verbatim from the spec; the rest are the shapes the seven
# vaults on this machine actually contain. Sharing is asserted by identity,
# not by comparison: a re-added local copy in the exporter would pass every
# behavioural assertion below and still be the defect this fixes.
# ==========================================================================
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import validate_vault as vv, export_traceability as ex

assert vv.split_cells is ex.split_cells, "the exporter re-declared split_cells"
assert vv.is_separator is ex.is_separator, "the exporter re-declared is_separator"

sc, row, un = vv.split_cells, vv.parse_table_row, ex.unescape

# GFM example 200: an escaped pipe divides nothing, inside an inline span
# or outside one, and resolves to a literal pipe in the cell's text.
assert sc(r'| f\|oo  |') == [r'f\|oo']
assert sc(r'| b `\|` az |') == [r'b `\|` az']
assert sc(r'| b **\|** im |') == [r'b **\|** im']
assert un(sc(r'| f\|oo  |')[0]) == 'f|oo'
# ... and the other half of the same sentence: an UNESCAPED pipe divides
# even inside a code span. A splitter that merely skipped backticks would
# pass every line above and fail this one.
assert sc('| a `x|y` b |') == ['a `x', 'y` b']

# GFM example 204: a short body row is padded to the header's width, a long
# one is cut to it. ncols never turns a non-row into a row.
assert sc('| bar |', 2) == ['bar', '']
assert sc('| bar | baz | boo |', 2) == ['bar', 'baz']
assert sc('prose', 4) is None

# An escaped backslash no longer escapes the pipe, so the pipe divides.
# cmark-gfm renders this the other way (github/cmark-gfm#277, unanswered);
# the spec is what both tools follow.
assert sc(r'| a \\| b |') == [r'a \\', 'b']

# The closing delimiter is recognised, not cut off the raw text: a row
# ending in a deliberate escaped pipe keeps it.
assert sc(r'| a | b \|') == ['a', r'b \|']
# ... while a genuinely empty last column survives.
assert sc('| a | b |  |') == ['a', 'b', '']

# Obsidian requires the pipe of an aliased wikilink to be escaped inside a
# table (obsidian.md/help/advanced-syntax). The alias must stay in its cell.
assert un(sc(r'| [[TAE_X\|proof]] | REQ-BAT-001 | a | Verified |')[0]) \
    == '[[TAE_X|proof]]'

# A code span holding a lone backslash directly before a delimiter - a real
# row from the homelab vault, and the shape that decides whether the escape
# scan swallows the delimiter behind it.
assert sc(r'| Zeichen | `(` | `\` | `\|` | `~` |') == \
    ['Zeichen', '`(`', r'`\`', r'`\|`', '`~`']

# The row predicate is shared with the exporter. GFM leaves the trailing
# pipe optional, a separator row is no row, and a line whose only interior
# pipes are escaped has one column - which neither tool has ever read.
assert row('| a | b') == ['a', 'b']
assert row('| --- | --- |') is None and row('| :--- | ---: |') is None
assert row('|-- huart == &huart3?') is None
assert row(r'| f\|oo  |') is None
PY
then ok x; else fail "the shared cell splitter must follow the GFM tables extension"; fi

# ==========================================================================
# The wikilink matcher (issue #23). Nine vaults on this machine contain zero
# same-file links and zero table-escaped aliases, so NO corpus check can
# catch a regression here - dropping the two lazy quantifiers agrees with
# the old regex on all 81028 lines and silently breaks the escaped alias
# again. These assertions are the only guard, and every one of them was
# verified to fail against the previous WIKILINK_RE.
# ==========================================================================
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" "$V" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from pathlib import Path
import validate_vault as vv

def parts(s):
    m = vv.WIKILINK_RE.search(s)
    return None if not m else (m.group(1), m.group(2), m.group(3), m.group(4))

# Same-file links, both documented spellings (obsidian.md/help/links).
# The old target group required a character before the '#' and matched none.
assert parts('[[#Heading]]') == ('', '', '#Heading', None)
assert parts('[[#^abc123]]') == ('', '', '#^abc123', None)
assert parts('![[#Heading]]') == ('!', '', '#Heading', None)
# The alias pipe escaped the way Obsidian requires inside a table, for a
# link and for an embed size (obsidian.md/help/advanced-syntax). The target
# used to keep the backslash and was reported as unresolved.
assert parts(r'[[Note\|alias]]') == ('', 'Note', None, r'\|alias')
assert parts(r'![[Engelbart.jpg\|200]]') == ('!', 'Engelbart.jpg', None, r'\|200')
# ... and the anchor, one field over, carried the same defect.
assert parts(r'[[Note#Head\|alias]]') == ('', 'Note', '#Head', r'\|alias')
# Everything else must read exactly as it did before.
assert parts('[[A]]') == ('', 'A', None, None)
assert parts('[[A|b]]') == ('', 'A', None, '|b')
assert parts('[[A#B|c]]') == ('', 'A', '#B', '|c')
assert parts('[[A#B#C]]') == ('', 'A', '#B#C', None)   # chained subheadings
assert parts('[[REQ_Measurement (MEG)]]') == ('', 'REQ_Measurement (MEG)', None, None)
assert parts(r'[[a\b]]') == ('', r'a\b', None, None)
assert parts(r'[[a\]b]]') is None

# The anchor index reads headings of every level, and a fenced block is not
# a source of headings: a shell comment must not resolve anybody's anchor.
doc = ["## Context", "scope sentence ^blk-one", "```bash",
       "# not a heading", "echo hi ^not-a-block", "```", "### Deep Sub"]
heads, blocks = vv.anchor_index(doc, vv.fence_mask(doc))
assert heads == {vv.fold_key("Context"), vv.fold_key("Deep Sub")}, heads
assert blocks == {"blk-one"}, blocks
assert vv.anchor_resolves("#context", heads, blocks)          # folded, as elsewhere
assert vv.anchor_resolves("#Context#Deep Sub", heads, blocks) # every segment names one
assert vv.anchor_resolves("#^blk-one", heads, blocks)
assert not vv.anchor_resolves("#not a heading", heads, blocks)
assert not vv.anchor_resolves("#^not-a-block", heads, blocks)
assert not vv.anchor_resolves("#", heads, blocks)

# check_links itself, on primitives rather than on run output. A vault whose
# zero findings are the whole assertion cannot tell "resolved" from
# "exempted", which is what these four cases separate.
V = Path(sys.argv[2])
vault = vv.Vault(V)
p = V / "03_architecture_(ARC)" / "ARC_Data_Acquisition.md"
def links(lines, **kw):
    out = []
    vv.check_links(vault, p, lines, out, kw.pop("strict", True), **kw)
    return sorted({f.code for f in out})

# A link written the way a table requires resolves to the file it names.
assert links(["## Context", r"| [[CMP_AD7175-2\|the converter]] | x |"]) == []
# 60 same-file anchors trip neither counter: both are about OUTGOING links.
assert links(["## Context"] + ["see [[#Context]]"] * 60) == []
# ... and the positive control that says those counters still work at all.
assert links(["## Context"] + ["see [[CMP_AD7175-2]]"] * 60) == \
    ["link-budget", "link-repeat"]
# A link naming nothing is no link - the shape a REF template writes as a
# placeholder, and the one line in nine vaults where old and new disagree.
assert links(["## Context", "- [[]] -", "- [[#]]", "- [[|alias]]"]) == []
PY
then ok x; else fail "the wikilink matcher must read same-file links and the table escape"; fi

# ==========================================================================
# The two tools must agree about where a fenced block starts. Amendment
# 2026-07-31b carried that disagreement as residual 1: the exporter skipped
# fenced blocks and the validator did not, so they counted a vault's
# requirement rows differently wherever one quoted a table as documentation.
# The rule now lives in both, which is only worth anything if nothing lets
# the two copies drift apart again - so it is asserted on every Markdown
# file every fixture in this suite builds, plus the shipped vault.
# ==========================================================================
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" "$TMP" "$DE_TMP" "$EN_TMP" "$EX_TMP" "$REAL_VAULT" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import validate_vault as vv, export_traceability as ex
from pathlib import Path
n = 0
for root in sys.argv[2:]:
    for f in Path(root).rglob("*.md"):
        if ".obsidian" in f.parts:
            continue
        lines = f.read_text(encoding="utf-8", errors="replace").splitlines()
        assert vv.fence_mask(lines)[1:] == ex.fenced_mask(lines), f"fence masks differ: {f}"
        n += 1
assert n > 50, f"parity assertion covered only {n} files - fixtures moved?"
PY
then ok x; else fail "validator and exporter must mask the same lines as fenced"; fi

# ... and the property that disagreement produced: the row fixture 7 quotes
# inside a ```markdown block is invisible to the exporter (asserted above)
# and must be invisible to the validator reading the very same vault.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" "$EN_V" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import validate_vault as vv
from pathlib import Path
idx = vv.Vault(Path(sys.argv[2])).req_index()
assert "REQ-EXP-001" in idx, "the real rows of the export vault must be indexed"
assert "REQ-EXP-900" not in idx, "the quoted row must not be a requirement"
PY
then ok x; else fail "the quoted row must be invisible to both tools on one vault"; fi

# The shipped template vault must export cleanly - the same guard the
# validator has, for the artifact a visitor is most likely to look at.
TESTS=$((TESTS + 1))
if [ -d "$REAL_VAULT" ]; then
  rout=$(python3 "$EXPORTER" "$REAL_VAULT" --output-dir "$EX_TMP/out-real" \
    --no-timestamp 2>&1)
  if contains "$rout" "requirements: 3  proven: 3" && \
     contains "$rout" "findings: 0"; then ok x; else
    fail "template vault must export 3 of 3 requirements proven with no findings:"
    printf '%s\n' "$rout" | sed 's/^/    /'
  fi
else
  fail "real template vault not found at $REAL_VAULT"
fi

rm -f "/tmp/claude-mechdocs/touched-$SID" "/tmp/claude-mechdocs/baseline-$SID" \
      "/tmp/claude-mechdocs/blocks-$SID"

echo "$TESTS tests, $FAILURES failure(s)"
if [ "$FAILURES" -eq 0 ]; then
  echo "ALL TESTS PASSED"
else
  exit 1
fi
