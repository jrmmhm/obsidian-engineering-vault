#!/usr/bin/env bash
# Test suite for validate_vault.py. Builds ephemeral fixture vaults in
# mktemp dirs at runtime: a precision vault (realistic, correct content
# that must produce ZERO findings - guards against false-positive creep),
# a violation vault (~15 seeded rule violations that must each be
# detected), a German/English twin pair that must produce identical
# findings, plus hook-mode and crash-mode checks, plus a run against the
# real baseproject template vault (must contain no ERRORs), plus scratch
# HOMEs that pin what --check-install says about each shape the personal
# skill entry can take.
set -u
# -P resolves the ~/.claude/skills symlink to the repo. Without it
# REAL_VAULT points outside the repo and the template-vault check below
# silently skips - the guard that keeps the shipped vault at 0 errors.
SKILL_DIR=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
VALIDATOR="$SKILL_DIR/validate_vault.py"
# Skill lives at <repo>/.claude/skills/mechatronics-docs -> repo root is 3 levels up.
REAL_VAULT="$(cd -P -- "$SKILL_DIR/../../.." && pwd -P)/00_documentation/01_projectvault"
# The method's own decision record is a vault too, and is held to the same
# zero-ERROR bar. Same -P reasoning as above.
METHOD_VAULT="$(cd -P -- "$SKILL_DIR/../../.." && pwd -P)/.claude/01_methodvault"
FAILURES=0
TESTS=0

fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
ok() { :; }
check() { # check <description> <condition-result 0|1>
  TESTS=$((TESTS + 1))
  if [ "$2" -eq 0 ]; then ok "$1"; else fail "$1"; fi
}
contains() { printf '%s' "$1" | grep -q "$2"; }

# field <name> <stop-hook stdout> -> the named top-level JSON field, decoded.
#
# Every assertion about the stop gate goes through this. Asserting on the
# raw stdout cannot tell a channel that reaches someone from one that does
# not - the defect of issue #44 was invisible to 232 tests for exactly that
# reason. It also restores line semantics: json.dumps emits one line, where
# a grep pattern spanning '.*' silently reaches across findings that used to
# sit on separate lines.
#
# Missing field -> empty string, never an error: a negative assertion must
# be able to say "this text is NOT in reason".
field() {
  printf '%s' "$2" | python3 -c '
import json, sys
try:
    print(json.loads(sys.stdin.read()).get(sys.argv[1], ""), end="")
except ValueError:
    pass' "$1"
}

# has_key <name> <stop-hook stdout> -> 0 when the TOP-LEVEL key exists.
# Structural, not substring: json.dumps of the nested hookSpecificOutput
# form contains the literal '"decision": "block"' too, so every
# substring assertion in this file passes against a mutant that Claude
# Code 2.1.220 ignores entirely - a gate that blocks nothing, all green.
has_key() {
  printf '%s' "$2" | python3 -c '
import json, sys
try:
    sys.exit(0 if sys.argv[1] in json.loads(sys.stdin.read()) else 1)
except ValueError:
    sys.exit(1)' "$1"
}

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
|               |     |         |                      |                                  |
|               |     |         |                      |                                  |
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

# The IMP template, byte-identical to the copy above except for a leading
# byte-order mark. Its FIRST line is a heading, so this isolates the OTHER
# reader: extract_h2 tests l.startswith("## "), and '﻿## Context' fails
# that test. 'Context' then drops out of the required set of the whole
# domain, and both IMP near-miss assertions below - which exist precisely
# because 'Context' is required - stop firing. A template whose sections
# quietly shrink is the silent switch-off one layer above the file checks.
{ printf '\xef\xbb\xbf'; cat "$V/06_implementation_(IMP)/00_IMP_file_template.md"; } \
  > "$W/06_implementation_(IMP)/00_IMP_file_template.md"

# A template is the file every new file is copied from, so an undeclared key
# in it propagates silently. Same H2 set as the copy it replaces, so section
# checks are unaffected. Its VALUES are placeholders and must stay unchecked -
# 'created: YYYY-MM-DD' may not become a frontmatter-date ERROR.
#
# Written WITH a byte-order mark (issue #21), which makes the 'squad'
# assertion below the positive control for read_lines in the infra branch:
# with a utf-8 reader parse_frontmatter returns (None, 0, None) there, and
# validate_file reports NEITHER template-unreadable (the malformed slot is
# empty) NOR the undeclared key (that branch needs fm) - the check stops
# checking without saying so. The mark sits in front of '---', so the H2 set
# of this template is unaffected and only the frontmatter path is isolated.
printf '\xef\xbb\xbf' > "$W/01_requirements_(REQ)/00_REQ_file_template.md"
cat >> "$W/01_requirements_(REQ)/00_REQ_file_template.md" <<'EOF'
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

cat > "$W/02_decisions_(DEC)/DEC_NoFrontmatter.md" <<'EOF'
No frontmatter here.

## Context
## Options
## Decision
## Justification
## Consequences
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

# Issue #25: the header latch could only be set by the template's own English
# wording, so a file whose real table drifted - translated here, which is what
# every German vault on this machine writes - and whose only canonical header
# sits inside a quoted example was read and then not checked at all. The
# broken row below is the assertion that carries the change; before it, this
# whole file produced zero row findings.
cat > "$W/01_requirements_(REQ)/REQ_Drift (DRF).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Requirement file documenting the canonical header while its own table
carries a translated one.

```markdown
| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| ------------- | --: | ------- | -------------------- | ------ |
| M | 001 | quoted example row | quoted | none |
```

| Klasse | Nr. | Inhalt | Kriterium | Quelle |
| ------ | --: | ------ | --------- | ------ |
| Z | 9 | drifted header, broken row | | keine |
| M | 002 | drifted header, sound row | Pass if measured | keine |
EOF

# A quoted example BETWEEN two tables. Reading a fenced line as absent rather
# than as a break merges them, and the second table's header becomes a body
# row: two blocking findings on a line the author wrote correctly.
cat > "$W/01_requirements_(REQ)/REQ_Split (SPL).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Requirement file whose two tables are separated by a quoted example.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| ------------- | --: | ------- | -------------------- | ------ |
| M | 001 | first table | Pass if measured | none |

```markdown
| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| ------------- | --: | ------- | -------------------- | ------ |
| Z | 9 | quoted between the tables | | none |
```

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| ------------- | --: | ------- | -------------------- | ------ |
| M | 002 | second table | Pass if measured | none |
EOF

# A second table that gained a column. The five positional roles are intact,
# so its rows stay requirement rows - otherwise one '| Comment |' in a header
# would buy an exemption from four blocking codes, which is the bypass
# amendment 2026-08-01 refused to sell for three backticks.
cat > "$W/01_requirements_(REQ)/REQ_Wide (WID).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Requirement file whose second table carries an extra column.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| ------------- | --: | ------- | -------------------- | ------ |
| M | 001 | narrow table | Pass if measured | none |

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source | Comment |
| ------------- | --: | ------- | -------------------- | ------ | ------- |
| Z | 002 | widened table, broken row | | none | tbd |
EOF

# The other direction: a five-column table that is not a requirement table at
# all. Nothing here may be an ERROR - the check cannot tell a revision log
# from a drifted requirement table - but the file carries no readable
# requirement table, and saying nothing is what issue #25 is about.
cat > "$W/01_requirements_(REQ)/REQ_Log (LOG).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Context
Requirement file whose only wide table is a revision history.

| Revision | Date | Author | Change | Review |
| -------- | ---- | ------ | ------ | ------ |
| r1 | 2026-01-05 | jm | initial | pending |
| r2 | 2026-02-05 | jm | reworded | pending |
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

# A domain file carrying a byte-order mark, and a twin without one claiming
# the same identity (issue #21). The collision is the positive control for
# the THIRD reader: check_identifiers compares nothing but the corpus that
# validate_vault_wide builds, so with a utf-8 corpus the marked file has no
# identifier, the collision does not exist and the check reports nothing at
# all. Naming the marked file as the first declarer is what says its
# frontmatter was actually read - the sort order makes that deterministic.
{ printf '\xef\xbb\xbf'
  printf -- '---\ndomain: ARC\nid: ARC-BOM-001\nstatus: active\ncreated: 2026-01-09\nlast-verified: 2026-07-01\n---\n'
  printf '## Context\nArchitecture note saved by an editor that writes a byte-order mark.\n'
  printf 'Its frontmatter is here to be read, not to be reported as absent.\n'
} > "$W/03_architecture_(ARC)/ARC_Byte_Order_Mark.md"

cat > "$W/03_architecture_(ARC)/ARC_Byte_Order_Twin.md" <<'EOF'
---
domain: ARC
id: ARC-BOM-001
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Context
The same identity without a byte-order mark. Two files claiming one
identifier is never legitimate, so this pair must be reported.
EOF

# Issue #31: the two files Windows PowerShell 5.1 writes without being
# asked. ARC_Powershell is what 'Out-File', '>' and '>>' produce - UTF-16LE
# with a mark - and it used to be reported as frontmatter-missing plus
# template-sections, two blocking ERRORs naming a cause that is sitting
# right there in the file. ARC_Ansi is what 'Set-Content' produces on a
# German system: structurally intact, ASCII frontmatter and headings, and
# every umlaut silently replaced. It produced NOTHING at all before.
python3 - "$W/03_architecture_(ARC)" <<'PY'
import codecs, sys
from pathlib import Path
d = Path(sys.argv[1])
utf16 = (
    "---\ndomain: ARC\nstatus: active\ncreated: 2026-01-09\n"
    "last-verified: 2026-07-01\n---\n"
    "## Context\n"
    "Architecture note saved by a shell that writes UTF-16 by default.\n"
    "Its frontmatter is here and its required heading is here; neither\n"
    "survives being decoded as UTF-8, which is what made the findings\n"
    "about them name the wrong cause.\n")
(d / "ARC_Powershell.md").write_bytes(codecs.BOM_UTF16_LE + utf16.encode("utf-16-le"))
ansi = (
    "---\ndomain: ARC\nstatus: active\ncreated: 2026-01-09\n"
    "last-verified: 2026-07-01\n---\n"
    "## Context\n"
    "Architekturnotiz, gespeichert in der ANSI-Codepage dieses Systems.\n"
    "Sie trägt keine Signatur, an der die Kodierung zu erkennen wäre.\n"
    "Frontmatter und Überschrift sind ASCII und überleben; nur die\n"
    "Umlaute dieser Sätze werden still zu Ersatzzeichen.\n"
    "Genau deshalb blieb diese Datei ohne jeden Befund.\n")
(d / "ARC_Ansi.md").write_bytes(ansi.encode("cp1252"))
PY
# Byte guards. Every assertion below is silently satisfied by a fixture
# that has become UTF-8 on the way in - a file that decodes cleanly cannot
# tell "read correctly" from "never broken" - so the bytes are asserted
# first, the way the byte-order-mark fixtures above are.
TESTS=$((TESTS + 1))
if contains "$(head -c 2 "$W/03_architecture_(ARC)/ARC_Powershell.md" | od -An -tx1)" "ff fe"; then
  ok x; else fail "the UTF-16 fixture lost its byte-order mark"; fi
TESTS=$((TESTS + 1))
if python3 - "$W/03_architecture_(ARC)/ARC_Ansi.md" <<'PY'
import sys
raw = open(sys.argv[1], "rb").read()
try:
    raw.decode("utf-8")
except UnicodeDecodeError:
    sys.exit(0)
sys.exit(1)
PY
then ok x; else fail "the ANSI fixture is valid UTF-8 - it proves nothing"; fi

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
dec_missing=$(printf '%s' "$out" | grep "DEC_NoFrontmatter.*frontmatter-missing") || true
if [ -n "$dec_missing" ] && ! contains "$dec_missing" "status"; then ok x; else
  fail "DEC frontmatter-missing must not name the frontmatter status field"; fi
TESTS=$((TESTS + 1))
if [ $rc -eq 1 ]; then ok x; else fail "violation vault must exit 1, got $rc"; fi
for code in filename-prefix frontmatter-missing frontmatter-malformed \
    frontmatter-domain frontmatter-date frontmatter-status template-sections \
    length code-fence impl-leak link-unresolved req-class req-nnn \
    req-duplicate req-criterion req-duplicate-global req-table-unrecognized \
    encoding-not-utf8 verifies-unknown-req \
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

# Issue #25: a table whose header drifted is still a requirement table. All
# three assertions name the line, because the defect was that this row - the
# only broken one in the file - produced nothing at all.
for code in req-class req-nnn req-criterion; do
  TESTS=$((TESTS + 1))
  if contains "$out" "REQ_Drift (DRF)\.md:19 \[$code\]"; then ok x; else
    fail "a drifted header must not switch the row check off: [$code] missing"
    printf '%s\n' "$out" | grep "REQ_Drift" | sed 's/^/    /'
  fi
done
# ... and the header the file only QUOTES must still be invisible, in the
# finding stream and in the index alike. Otherwise the assertions above are
# also satisfied by a check that stopped skipping fenced blocks.
TESTS=$((TESTS + 1))
if ! contains "$out" "REQ_Drift (DRF)\.md:14"; then ok x; else
  fail "the quoted example row must produce nothing"; fi
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" "$W" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import validate_vault as vv
from pathlib import Path
idx = vv.Vault(Path(sys.argv[2])).req_index()
assert "REQ-DRF-002" in idx, "the sound row under the drifted header must be indexed"
assert "REQ-DRF-001" not in idx, "the quoted row must not enter the requirement index"
PY
then ok x; else fail "the drifted table's rows must reach the requirement index"; fi

# A quoted example BETWEEN two tables must not merge them. The second table's
# header is the line that pays: merged, it is read as a body row and produces
# two blocking findings on correct content.
TESTS=$((TESTS + 1))
n=$(printf '%s' "$out" | grep -cE "REQ_Split \(SPL\)\.md.*\[(req-class|req-nnn|req-criterion|req-duplicate|req-table-unrecognized)\]") || true
if [ "$n" -eq 0 ]; then ok x; else
  fail "a fence between two tables must not merge them, got $n finding(s)"
  printf '%s\n' "$out" | grep "REQ_Split" | sed 's/^/    /'
fi

# A table one column wider is still a requirement table: the five positional
# roles are intact, and treating it as unrecognised would sell an exemption
# from four blocking codes for one header cell.
for code in req-class req-criterion; do
  TESTS=$((TESTS + 1))
  if contains "$out" "REQ_Wide (WID)\.md:16 \[$code\]"; then ok x; else
    fail "a widened requirement table must still be checked: [$code] missing"; fi
done
TESTS=$((TESTS + 1))
if ! contains "$out" "REQ_Wide (WID)\.md.*\[req-table-unrecognized\]"; then ok x; else
  fail "a widened table that IS read must not also be reported as unread"; fi

# The other half of issue #25: a REQ file whose only wide table is not a
# requirement table says so - once, and never as an ERROR, because nothing
# here can tell a revision log from a table that drifted out of readability.
TESTS=$((TESTS + 1))
if contains "$out" "^WARN .*REQ_Log (LOG)\.md:10 \[req-table-unrecognized\]"; then
  ok x; else fail "a REQ file with no readable requirement table must WARN"
  printf '%s\n' "$out" | grep "REQ_Log" | sed 's/^/    /'
fi
TESTS=$((TESTS + 1))
n=$(printf '%s' "$out" | grep -c "REQ_Log (LOG)\.md.*\[req-table-unrecognized\]") || true
if [ "$n" -eq 1 ]; then ok x; else
  fail "req-table-unrecognized is one grouped finding per file, got $n"; fi
TESTS=$((TESTS + 1))
if ! contains "$out" "^ERROR .*\[req-table-unrecognized\]"; then ok x; else
  fail "req-table-unrecognized must never be an ERROR"; fi
# The positive control the WARN needs: the revision log's own rows must NOT
# be read as requirement rows. A check that reported nothing at all would
# satisfy the assertion above just as well.
TESTS=$((TESTS + 1))
if ! contains "$out" "REQ_Log (LOG)\.md.*\[req-class\]"; then ok x; else
  fail "a revision-history table must not be checked as a requirement table"; fi

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

# Byte-order marks (issue #21). Every assertion that follows is silently
# satisfied by a fixture that lost its mark - a zero-findings vault cannot
# tell "read correctly" from "never marked" - so the bytes themselves are
# asserted first, the way the CSV export's BOM already is further below.
for f in "$W/01_requirements_(REQ)/00_REQ_file_template.md" \
         "$W/06_implementation_(IMP)/00_IMP_file_template.md" \
         "$W/03_architecture_(ARC)/ARC_Byte_Order_Mark.md"; do
  TESTS=$((TESTS + 1))
  if contains "$(head -c 3 "$f" | od -An -tx1)" "ef bb bf"; then ok x; else
    fail "fixture lost its byte-order mark: $f"; fi
done

# The marked domain file takes part in the identifier checks, which reach
# them through the corpus and not through read_lines. Naming it as the file
# that declared the identifier first is the assertion: without a BOM-safe
# corpus it has no identifier, and the collision below does not exist.
TESTS=$((TESTS + 1))
if contains "$out" "ARC_Byte_Order_Twin\.md.*\[id-duplicate\].*ARC-BOM-001.*already declared in ARC_Byte_Order_Mark\.md"; then
  ok x; else fail "a marked file must reach the identifier checks like any other:"
  printf '%s\n' "$out" | grep -E "ARC_Byte_Order" | sed 's/^/    /'
fi
# ... and it must not be accused of the defect the mark used to fake.
TESTS=$((TESTS + 1))
if ! contains "$out" "ARC_Byte_Order_Mark\.md.*frontmatter-missing"; then ok x; else
  fail "a byte-order mark must not be reported as missing frontmatter"; fi

# A file that is not UTF-8 at all (issue #31). The finding names the
# encoding, on line 1, as an ERROR - a Markdown vault file in UTF-16 is
# never something anybody meant, which is this project's own criterion for
# blocking versus reporting.
TESTS=$((TESTS + 1))
if contains "$out" "^ERROR .*ARC_Powershell\.md:1 \[encoding-not-utf8\].*UTF-16LE"; then
  ok x; else fail "a UTF-16 file must be reported as UTF-16, naming the encoding:"
  printf '%s\n' "$out" | grep "ARC_Powershell" | sed 's/^/    /'
fi
# The signature-less half. This file produced NOT ONE finding before, which
# is why its assertion is the presence of the new one rather than the
# absence of the old ones: there were none to be absent.
TESTS=$((TESTS + 1))
if contains "$out" "^ERROR .*ARC_Ansi\.md:1 \[encoding-not-utf8\].*not valid UTF-8"; then
  ok x; else fail "an undecodable file without a mark must be reported by its byte:"
  printf '%s\n' "$out" | grep "ARC_Ansi" | sed 's/^/    /'
fi
# Never a WARN - paired with the positive assertions above, because a
# negative alone also passes against code that does not know the string.
TESTS=$((TESTS + 1))
if ! contains "$out" "^WARN .*\[encoding-not-utf8\]"; then ok x; else
  fail "encoding-not-utf8 must never be a WARN"; fi
# The finding is ADDED, not substituted. Issue #31 proposed replacing the
# file's other findings; the per-file ratchet is why that was refused, and
# this is the assertion that keeps someone from quietly reintroducing it:
# the codes below have to stay in the run, so they stay in the git-HEAD
# baseline, so repairing the encoding cannot look like introducing them.
for code in frontmatter-missing template-sections; do
  TESTS=$((TESTS + 1))
  if contains "$out" "ARC_Powershell\.md.*\[$code\]"; then ok x; else
    fail "the consequences of the misread must stay reported: [$code] gone"; fi
done

# ==========================================================================
# Fixture 3: German/English twin vaults - byte-identical content, differing
# only in domain folder names and template FILE names. Everything the
# language-independence fix governs must behave identically in both, so the
# finding-code multisets are compared directly.
#
# ARC, IMP and REF keep the same (ABBR) in both languages, which isolates
# the file-naming variable. Since issue #66 the coverage path resolves the
# requirements and evidence roles through the schema's alias map, so the
# twins also carry a requirements domain (REQ / ANF) and an evidence
# domain (TAE / TUE), identical up to those tokens: req-uncovered,
# verifies-unknown-req and req-duplicate-global must fire identically in
# both, which the multiset assertion below and the issue #66 block at the
# end of this file pin. Still out of scope by decision: the row-grammar
# checks (req-class/req-nnn/req-criterion/req-duplicate) stay on the
# literal REQ folder, and the English-only heuristics (system_overview.md,
# "References"/"Sources" section names) stay dark - the twins therefore
# carry no overview file, and both are equally unaffected.
#
# Separate mktemp roots on purpose: check_paths probes project_root.parent,
# so a shared root would let one twin resolve the other twin's artifacts.
# ==========================================================================
DE_TMP=$(mktemp -d)
EN_TMP=$(mktemp -d)
trap 'rm -rf "$TMP" "$DE_TMP" "$EN_TMP"' EXIT

build_twin() { # build_twin <vault_dir> <arc_dir> <imp_dir> <ref_dir> <template_infix>
               #            <req_dir> <tae_dir> <req_abbr> <tae_abbr>
  local V="$1" A="$2" I="$3" R="$4" T="$5" RQ="$6" TA="$7" P="$8" EV="$9"
  mkdir -p "$V/$A" "$V/$I" "$V/$R" "$V/$RQ" "$V/$TA"

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

  # Requirements and evidence domain (issue #66): identical content up to
  # the domain tokens. Seeded: verifies-unknown-req (id 999), req-uncovered
  # (row 002), req-duplicate-global (row 001 defined again in *_Doppelt,
  # which sorts FIRST and takes the index slot - the finding fires at
  # *_Messung naming it). Constraints that keep the twin finding multisets
  # identical: every row stays well-formed with a three-digit number (the
  # row-grammar checks run only on the English side), no file here carries
  # a frontmatter id (an English REQ-MES-000 would enter the identifier
  # checks while a German ANF-MES-000 would not), and 'verifies' is present
  # and non-empty (its requiredness, format and empty-list WARN are
  # enforced only in the English TAE domain).
  printf '## Kontext\n\n| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n| --- | --: | --- | --- | --- |\n|  |  |  |  |  |\n' \
    > "$V/$RQ/00_${P}_$T.md"
  printf '## Kontext\n' > "$V/$TA/00_${EV}_$T.md"

  cat > "$V/$RQ/${P}_Messung (MES).md" <<EOF
---
domain: $P
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Kontext
Anforderungen der Messkette: eine gedeckte und eine ungedeckte Zeile.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| --- | --: | --- | --- | --- |
| M | 001 | Gedeckte Anforderung | Pass wenn gemessen | keine |
| M | 002 | Ungedeckte Anforderung | Pass wenn gemessen | keine |
EOF

  cat > "$V/$RQ/${P}_Doppelt (MES).md" <<EOF
---
domain: $P
status: active
created: 2026-01-05
last-verified: 2026-07-01
---
## Kontext
Zweite Anforderungsdatei desselben Geltungsbereichs. Ihre Zeile 001
kollidiert absichtlich mit der Zeile 001 der Messungsdatei.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |
| --- | --: | --- | --- | --- |
| M | 001 | Doppelt vergebene Nummer | Pass wenn gemessen | keine |
EOF

  cat > "$V/$TA/${EV}_Nachweis.md" <<EOF
---
domain: $EV
status: active
created: 2026-01-10
last-verified: 2026-07-01
verifies: [$P-MES-001, $P-MES-999]
---
## Kontext
Nachweis der Messkette: er loest eine Anforderung auf und nennt eine,
die nirgends definiert ist. Die gedeckte Zeile 001 bleibt dadurch ohne
Befund, Zeile 002 wird als ungedeckt gemeldet, und die unbekannte
Nummer 999 ist der gesaete verifies-unknown-req.
EOF
}

DE_V="$DE_TMP/Deproj/00_Dokumentation/01_Projektvault"
EN_V="$EN_TMP/Enproj/00_documentation/01_projectvault"
build_twin "$DE_V" "03_Architektur_(ARC)" "06_Implementierung_(IMP)" \
           "09_Referenzen_(REF)" "Dateitemplate" \
           "01_Anforderungen_(ANF)" "07_Test_und_Evidenz_(TUE)" "ANF" "TUE"
build_twin "$EN_V" "03_architecture_(ARC)" "06_implementation_(IMP)" \
           "09_references_(REF)" "file_template" \
           "01_requirements_(REQ)" "07_testing_and_evidence_(TAE)" "REQ" "TAE"

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

# The git half of issue #21. Committed WITH a byte-order mark, so its
# identifier can only be recovered from git HEAD - which git_head_content
# decodes, not read_lines. Deleted from the worktree further below together
# with ARC_Thermal.md: the identifier of a marked file must vanish exactly
# like anyone else's. While it is still present, the clean-worktree
# assertion above covers the other direction - an unmarked corpus would
# report it as vanished although the file is lying right there.
{ printf '\xef\xbb\xbf'
  printf -- '---\ndomain: ARC\nid: ARC-BOM-001\nstatus: active\ncreated: 2026-01-09\nlast-verified: 2026-07-01\n---\n'
  printf '## Context\nArchitecture note committed with a byte-order mark, so that HEAD and\n'
  printf 'the working tree have to be read under one rule.\n'
} > "$I/03_architecture_(ARC)/ARC_Byte_Order_Mark.md"
TESTS=$((TESTS + 1))
if contains "$(head -c 3 "$I/03_architecture_(ARC)/ARC_Byte_Order_Mark.md" | od -An -tx1)" "ef bb bf"; then
  ok x; else fail "identity fixture lost its byte-order mark"; fi

# Issue #31, the git half. Committed as UTF-16, so its encoding is part of
# the state the per-file baseline is computed from - which is only true if
# git_head_content hands out the blob as bytes. Its heading is German and
# the template requires 'Context', so the file carries a template-sections
# ERROR in BOTH readings: mojibake has no '## Context' either. That
# symmetry is what the repair assertion below measures.
python3 - "$I/03_architecture_(ARC)" <<'PY'
import codecs, sys
from pathlib import Path
body = ("---\ndomain: ARC\nstatus: active\ncreated: 2026-01-09\n"
        "last-verified: 2026-07-01\n---\n"
        "## Kontext\n"
        "Architekturnotiz, committet in UTF-16. Ihre Sektion heisst nicht\n"
        "wie im Template, in beiden Lesarten.\n")
p = Path(sys.argv[1]) / "ARC_Powershell.md"
p.write_bytes(codecs.BOM_UTF16_LE + body.encode("utf-16-le"))
PY
TESTS=$((TESTS + 1))
if contains "$(head -c 2 "$I/03_architecture_(ARC)/ARC_Powershell.md" | od -An -tx1)" "ff fe"; then
  ok x; else fail "the committed UTF-16 fixture lost its byte-order mark"; fi

# An empty committed file. git show returns b'' for it, which is falsy and
# not None - and hook_post asks 'is not None' on purpose, because a
# truthiness test would call a file that has been in the repository for
# years a file this session created.
: > "$I/03_architecture_(ARC)/ARC_Empty.md"

# Issue #26. Committed with a heading the template does not know, so
# template-sections stands in this file's git HEAD baseline. The session
# further below repairs it and the code stops firing - the case the stop
# gate could not see at all, because its comparison iterates the findings
# that exist and a code producing none is never reached.
cat > "$I/03_architecture_(ARC)/ARC_Resolved.md" <<'EOF'
---
domain: ARC
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Kontext
Architecture note committed with a heading the template does not know, so
that its template-sections ERROR is part of the state the per-file baseline
is computed from. The session repairs the heading and nothing else, which
is the honest half of the ambiguity: the code stops firing because the
defect is gone. A check made unreachable is indistinguishable from here,
which is why the gate reports this rather than blocking on it.
EOF

# The counter-case, and the reason the report asks a yes/no instead of
# comparing counts. Both targets are missing at HEAD; the session creates
# exactly one of them, so link-unresolved falls from 2 to 1 in a file whose
# content nobody touched. Under the phased creation order that is the
# ordinary mid-pass state, and reporting it would make the channel noise.
cat > "$I/03_architecture_(ARC)/ARC_Linker.md" <<'EOF'
---
domain: ARC
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Kontext
Architecture note committed with two links whose targets do not exist yet.
Creating one of them elsewhere in a session lowers this file's
link-unresolved count without anyone editing this file, which is exactly
the movement a count-based report would blame on the session:
[[ARC_Missing_One]] and [[ARC_Missing_Two]].
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
rmsg=$(field systemMessage "$rout")
TESTS=$((TESTS + 1))
if ! has_key decision "$rout"; then ok x; else
  fail "a pre-existing section-mismatch must not block the stop gate:"
  printf '%s\n' "$rout" | sed 's/^/    /'
fi
# The negative control for issue #26 across a whole session: this file's
# baseline code still fires, so nothing stopped firing and the section must
# be absent entirely. An implementation that simply echoes the baseline
# passes every positive assertion and fails this one.
TESTS=$((TESTS + 1))
if ! contains "$rmsg" "did not fire this session"; then ok x; else
  fail "an unchanged pre-existing ERROR must not be reported as resolved:"
  printf '%s\n' "$rmsg" | sed 's/^/    /'
fi
# The channel itself, on a session that reports without blocking: the
# report must arrive as systemMessage and nowhere else. A bare print()
# satisfies every assertion above and reaches nobody (issue #44).
TESTS=$((TESTS + 1))
if has_key systemMessage "$rout" && contains "$rmsg" "vault validator session report"; then ok x; else
  fail "a non-blocking session report must travel as systemMessage:"
  printf '%s\n' "$rout" | sed 's/^/    /'
fi
TESTS=$((TESTS + 1))
if ! contains "$rout" "^vault validator session report"; then ok x; else
  fail "the report must not also be emitted as bare stdout:"
  printf '%s\n' "$rout" | sed 's/^/    /'
fi
rm -f "/tmp/claude-mechdocs/touched-$SIDR" "/tmp/claude-mechdocs/baseline-$SIDR" \
      "/tmp/claude-mechdocs/blocks-$SIDR"

# Issue #31 at the gate. A file that was already UTF-16 at HEAD must not
# block the session that opens it: its baseline is computed from the blob
# by the running validator, so encoding-not-utf8 stands in baseline and
# current run alike - the condition amendment 2026-07-31 stated when
# section-mismatch became the first ERROR to enter the blocking set.
# Asserting "does not block" alone would pass against the old code too
# (which knows no such code at all), so the report has to NAME it as
# pre-existing; that fails against the old code and against a version
# that decodes the blob before the baseline is taken.
SIDE="testsession-encoding-$$"
rm -f "/tmp/claude-mechdocs/touched-$SIDE" "/tmp/claude-mechdocs/baseline-$SIDE" \
      "/tmp/claude-mechdocs/blocks-$SIDE"
for f in ARC_Powershell.md ARC_Empty.md; do
  printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' "$SIDE" \
    "$I/03_architecture_(ARC)/$f" | python3 "$VALIDATOR" --hook post >/dev/null 2>&1
done
eout=$(printf '{"session_id":"%s"}' "$SIDE" | python3 "$VALIDATOR" --hook stop 2>&1)
emsg=$(field systemMessage "$eout")
TESTS=$((TESTS + 1))
if ! has_key decision "$eout"; then ok x; else
  fail "a file that was already UTF-16 at HEAD must not block the gate:"
  printf '%s\n' "$eout" | sed 's/^/    /'
fi
# Read through field(): the pattern spans '.*' and needs the code and the
# tag on ONE finding line. Against the raw json.dumps output the whole
# report is one line, so '.*' would reach across findings and the
# assertion would pass while encoding-not-utf8 was reported as NEW.
TESTS=$((TESTS + 1))
if contains "$emsg" "\[encoding-not-utf8\].*(pre-existing, non-blocking)"; then ok x; else
  fail "the pre-existing encoding ERROR must be named as pre-existing:"
  printf '%s\n' "$emsg" | sed 's/^/    /'
fi
# ... and the empty committed file must not be reported as created this
# session. b'' is falsy; only 'is not None' tells it from "no such blob".
TESTS=$((TESTS + 1))
if ! contains "$emsg" "files created this session"; then ok x; else
  fail "an empty COMMITTED file must not count as created this session:"
  printf '%s\n' "$emsg" | sed 's/^/    /'
fi
rm -f "/tmp/claude-mechdocs/touched-$SIDE" "/tmp/claude-mechdocs/baseline-$SIDE" \
      "/tmp/claude-mechdocs/blocks-$SIDE"

# The repair path, which is the reason encoding-not-utf8 is added to a
# file's findings instead of replacing them. The session does exactly what
# the finding asks - re-saves the file as UTF-8 - and the section ERROR
# that was hidden underneath becomes readable. It stood in the baseline
# too, because the misread produced it as well, so the gate stays quiet.
# Replace the other findings and the baseline knows one code instead of
# three: the session that repairs the file gets blocked for its trouble.
python3 - "$I/03_architecture_(ARC)" <<'PY'
import sys
from pathlib import Path
body = ("---\ndomain: ARC\nstatus: active\ncreated: 2026-01-09\n"
        "last-verified: 2026-07-01\n---\n"
        "## Kontext\n"
        "Dieselbe Notiz, neu gespeichert als UTF-8. Die Sektion heisst\n"
        "weiterhin nicht wie im Template - das war vorher schon so.\n")
(Path(sys.argv[1]) / "ARC_Powershell.md").write_text(body, encoding="utf-8")
PY
SIDF="testsession-encfix-$$"
rm -f "/tmp/claude-mechdocs/touched-$SIDF" "/tmp/claude-mechdocs/baseline-$SIDF" \
      "/tmp/claude-mechdocs/blocks-$SIDF"
printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' "$SIDF" \
  "$I/03_architecture_(ARC)/ARC_Powershell.md" | python3 "$VALIDATOR" --hook post >/dev/null 2>&1
fout=$(printf '{"session_id":"%s"}' "$SIDF" | python3 "$VALIDATOR" --hook stop 2>&1)
fmsg=$(field systemMessage "$fout")
TESTS=$((TESTS + 1))
if ! has_key decision "$fout"; then ok x; else
  fail "repairing the encoding must not block the session that did it:"
  printf '%s\n' "$fout" | sed 's/^/    /'
fi
# Asserted on the finding's MESSAGE, not on its code: since issue #26 the
# code name also appears in the report of what stopped firing, and a
# code-only assertion would fail on the very report that proves the repair.
# Still unanchored, although field() restores the line structure: the
# positive assertion below is what proves the field is non-empty, and a
# negative assertion on a field that could silently vanish is exactly the
# vacuous shape this suite keeps rediscovering (issue #31, issue #44).
TESTS=$((TESTS + 1))
if ! contains "$fmsg" "this vault is UTF-8"; then ok x; else
  fail "the repaired file must not still be reported as non-UTF-8"; fi
# The other half: the repair has to be NAMED, which is the whole point of
# issue #26. Both codes the misread produced are gone from the current run,
# so both are listed - encoding-not-utf8 because the file was re-saved, and
# frontmatter-missing because a decodable file has readable frontmatter
# again. template-sections is absent from the list on purpose: it stood at
# HEAD and still fires, so it is not something this session resolved.
TESTS=$((TESTS + 1))
if contains "$fmsg" "ARC_Powershell\.md \[encoding-not-utf8, frontmatter-missing\]"; then
  ok x; else fail "the repair must be named as a code that stopped firing:"
  printf '%s\n' "$fmsg" | sed 's/^/    /'
fi
rm -f "/tmp/claude-mechdocs/touched-$SIDF" "/tmp/claude-mechdocs/baseline-$SIDF" \
      "/tmp/claude-mechdocs/blocks-$SIDF"

# The object disappears from the worktree while HEAD still carries it.
rm -f "$I/03_architecture_(ARC)/ARC_Thermal.md" \
      "$I/03_architecture_(ARC)/ARC_Byte_Order_Mark.md"
out=$(python3 "$VALIDATOR" "$I" 2>&1); rc=$?
TESTS=$((TESTS + 1))
if contains "$out" "^WARN .*\[id-vanished\].*ARC-THM-001"; then ok x; else
  fail "deleted object must report its identifier as vanished:"
  printf '%s\n' "$out" | sed 's/^/    /'
fi
# The same, for the file that carried a byte-order mark. This is the only
# assertion in the suite that reads a marked file through git rather than
# from disk: head_identifiers decodes git show's output, and with the old
# text=True the mark survived, frontmatter_id returned None and the
# identifier was never in the HEAD set to begin with (issue #21).
TESTS=$((TESTS + 1))
if contains "$out" "^WARN .*\[id-vanished\].*ARC-BOM-001"; then ok x; else
  fail "a marked file's identifier must be read from git HEAD too:"
  printf '%s\n' "$out" | grep -E "id-vanished|ARC-BOM" | sed 's/^/    /'
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

# Issue #26, the positive control. The session repairs the heading of a file
# whose template-sections ERROR was committed, so the code stops firing.
# Nothing in the old gate reached that state: it compares cur > base while
# iterating the findings that exist, and this file now produces none of that
# code. The session ended green and silent, which is the same free pass a
# change that makes a check UNREACHABLE would have got.
python3 - "$I/03_architecture_(ARC)" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1]) / "ARC_Resolved.md"
p.write_text(p.read_text(encoding="utf-8").replace("## Kontext", "## Context"),
             encoding="utf-8")
PY
SIDG="testsession-resolved-$$"
rm -f "/tmp/claude-mechdocs/touched-$SIDG" "/tmp/claude-mechdocs/baseline-$SIDG" \
      "/tmp/claude-mechdocs/blocks-$SIDG"
printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' "$SIDG" \
  "$I/03_architecture_(ARC)/ARC_Resolved.md" | python3 "$VALIDATOR" --hook post >/dev/null 2>&1
gout=$(printf '{"session_id":"%s"}' "$SIDG" | python3 "$VALIDATOR" --hook stop 2>&1)
gmsg=$(field systemMessage "$gout")
TESTS=$((TESTS + 1))
if contains "$gmsg" "ARC_Resolved\.md \[template-sections\]"; then ok x; else
  fail "a code that stopped firing must be named in the session report:"
  printf '%s\n' "$gmsg" | sed 's/^/    /'
fi
# Reporting, not blocking: from counts alone a repair and an unreachable
# check are the same absence, and this layer never blocks on an ambiguity
# it cannot resolve. Blocking here would punish exactly the session that
# fixed the defect the gate asked it to fix.
TESTS=$((TESTS + 1))
if ! has_key decision "$gout"; then ok x; else
  fail "a code that stopped firing must not block the session that fixed it:"
  printf '%s\n' "$gout" | sed 's/^/    /'
fi
rm -f "/tmp/claude-mechdocs/touched-$SIDG" "/tmp/claude-mechdocs/baseline-$SIDG" \
      "/tmp/claude-mechdocs/blocks-$SIDG"

# ... and the decision that the report asks a yes/no rather than comparing
# counts, pinned so the next refactor cannot quietly widen it. The session
# creates one of two missing link targets, which lowers ARC_Linker.md's
# link-unresolved from 2 to 1 without anyone editing that file. A report on
# decreasing counts would name it and ask what was fixed there; under the
# phased creation order that is the ordinary mid-pass state of every vault.
# The order is load-bearing and mirrors a real session: the file is touched
# first, so hook_post records its baseline, and the target is created
# afterwards. Creating it first would prove nothing - hook_post validates
# the HEAD CONTENT against the CURRENT file set, so a target that already
# exists when the baseline is taken never counts as unresolved in it, and
# the assertion below would pass against any implementation at all.
SIDH="testsession-partial-$$"
rm -f "/tmp/claude-mechdocs/touched-$SIDH" "/tmp/claude-mechdocs/baseline-$SIDH" \
      "/tmp/claude-mechdocs/blocks-$SIDH"
printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' "$SIDH" \
  "$I/03_architecture_(ARC)/ARC_Linker.md" | python3 "$VALIDATOR" --hook post >/dev/null 2>&1
TESTS=$((TESTS + 1))
if contains "$(cat "/tmp/claude-mechdocs/baseline-$SIDH")" '"link-unresolved": 2'; then
  ok x; else fail "the partial-decrease fixture needs both links unresolved at baseline:"
  printf '%s\n' "$(cat "/tmp/claude-mechdocs/baseline-$SIDH")" | sed 's/^/    /'
fi
cat > "$I/03_architecture_(ARC)/ARC_Missing_One.md" <<'EOF'
---
domain: ARC
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Context
One of the two targets ARC_Linker.md points at, created in this session so
that the other file's unresolved-link count falls without its content
changing. The file itself is unremarkable on purpose.
EOF
pout=$(printf '{"session_id":"%s"}' "$SIDH" | python3 "$VALIDATOR" --hook stop 2>&1)
pmsg=$(field systemMessage "$pout")
TESTS=$((TESTS + 1))
if ! contains "$pmsg" "ARC_Linker\.md \[link-unresolved\]"; then ok x; else
  fail "a code that merely fires less often must not be reported as resolved:"
  printf '%s\n' "$pmsg" | sed 's/^/    /'
fi
rm -f "/tmp/claude-mechdocs/touched-$SIDH" "/tmp/claude-mechdocs/baseline-$SIDH" \
      "/tmp/claude-mechdocs/blocks-$SIDH"

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
#
# Written WITH a byte-order mark (issue #21), which makes every assertion in
# this block the positive control for the schema reader as well: json.loads
# rejects a leading BOM outright, so an unmarked-only reader drops to
# FALLBACK_SCHEMA behind one WARN - 'owner' becomes undeclared again and the
# vault is validated against a vocabulary nobody chose.
mkdir -p "$SC_TMP/declared"
cp "$VALIDATOR" "$SC_TMP/declared/validate_vault.py"
python3 - "$SKILL_DIR/vault_schema.json" "$SC_TMP/declared/vault_schema.json" <<'PY'
import json, sys
s = json.load(open(sys.argv[1]))
s["domain_defaults"]["fields"]["owner"] = {
    "type": "enum", "values": ["nobody"], "required": False,
    "code": "frontmatter-owner", "enforced": "schema-driven"}
json.dump(s, open(sys.argv[2], "w", encoding="utf-8-sig"))
PY
TESTS=$((TESTS + 1))
if contains "$(head -c 3 "$SC_TMP/declared/vault_schema.json" | od -An -tx1)" "ef bb bf"; then
  ok x; else fail "the declared schema fixture lost its byte-order mark"; fi
out2=$(python3 "$SC_TMP/declared/validate_vault.py" "$W" 2>&1)
TESTS=$((TESTS + 1))
if ! contains "$out2" "\[schema-unreadable\]"; then ok x; else
  fail "a byte-order mark must not make the schema unreadable"; fi
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
# read_lines and the byte-order mark (issue #21)
# ==========================================================================
# Asserted at the reader, because no vault-level finding can express the
# claim: what has to hold is that a marked file and an unmarked one yield
# the SAME lines. A fixture can only show that neither produces a finding,
# which is equally true of two files read wrongly in the same way. The
# probes are written into $TMP, outside every vault root, so they reach the
# reader assertions here and the reader-parity assertion at the end of this
# file without adding a finding anywhere.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" "$TMP" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from pathlib import Path
import validate_vault as vv

tmp = Path(sys.argv[2])
body = "---\ndomain: ARC\nid: ARC-PRB-001\n---\n## Context\nprobe file\n"
marked, plain = tmp / "bom_probe.md", tmp / "plain_probe.md"
marked.write_bytes(b"\xef\xbb\xbf" + body.encode("utf-8"))
plain.write_text(body, encoding="utf-8")
assert marked.read_bytes()[:3] == b"\xef\xbb\xbf", "the probe lost its mark"

# The comparison parse_frontmatter makes, and the two consumers that used
# to fail silently behind it.
assert vv.read_lines(marked)[0] == "---", repr(vv.read_lines(marked)[0])
assert vv.read_lines(marked) == vv.read_lines(plain), "a mark must be the only difference"
assert vv.parse_frontmatter(vv.read_lines(marked))[0] == {
    "domain": "ARC", "id": "ARC-PRB-001"}
assert vv.frontmatter_id(vv.read_lines(marked)) == "ARC-PRB-001"

# Only a LEADING mark is a signature. One inside the text is an ordinary
# character (Unicode FAQ) and must survive, or the reader would be editing
# content rather than decoding it.
mid = tmp / "mid_probe.md"
mid.write_text("---\ndomain: ARC\ntags: [a﻿b]\n---\n", encoding="utf-8")
assert vv.parse_frontmatter(vv.read_lines(mid))[0]["tags"] == ["a﻿b"]
PY
then ok x; else fail "read_lines must strip a leading byte-order mark and nothing else"; fi

# ==========================================================================
# decode_source: which encoding a file is in, and what the reader does with
# that (issue #31)
# ==========================================================================
# At the reader again, and for the same reason as the block above: the
# claims are equalities between two spellings, and the load-bearing one -
# that naming an encoding does not change a single character the reader
# hands out - has no finding that could express it. The vaults on this
# machine contain zero such files, so these probes are the only guard.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" "$TMP" <<'PY'
import codecs, sys
sys.path.insert(0, sys.argv[1])
from pathlib import Path
import validate_vault as vv

body = "---\ndomain: ARC\nid: ARC-PRB-002\n---\n## Context\nprobe file\n"

# Every mark is named, and UTF-32LE is not called UTF-16LE. FF FE 00 00
# begins with the UTF-16LE mark, so this pair is the whole reason the
# signature table is ordered longest-first; a reversed table passes every
# other assertion in this file.
for name, bom, enc in (
        ("UTF-16LE", codecs.BOM_UTF16_LE, "utf-16-le"),
        ("UTF-16BE", codecs.BOM_UTF16_BE, "utf-16-be"),
        ("UTF-32LE", codecs.BOM_UTF32_LE, "utf-32-le"),
        ("UTF-32BE", codecs.BOM_UTF32_BE, "utf-32-be")):
    text, problem = vv.decode_source(bom + body.encode(enc))
    assert problem and name in problem, f"{name} reported as {problem!r}"

# An ordinary file, and the two UTF-8 shapes issue #21 settled: a leading
# mark is stripped and is not a finding, one inside the text is a character.
assert vv.decode_source(body.encode("utf-8")) == (body, None)
assert vv.decode_source(codecs.BOM_UTF8 + body.encode("utf-8")) == (body, None)
mid = "---\ntags: [a﻿b]\n---\n"
assert vv.decode_source(mid.encode("utf-8")) == (mid, None)

# A truncated mark is not a mark: 'ef bb' alone is undecodable, and lands
# in the same channel as any other broken byte (amendment 2026-08-04 names
# it as the same class).
text, problem = vv.decode_source(b"\xef\xbb" + body.encode("utf-8"))
assert problem and "not valid UTF-8" in problem, problem

# A DOUBLED mark stays valid UTF-8 and is deliberately NOT reported here -
# residual 1 of amendment 2026-08-04 stays open, and this asserts that it
# is still open rather than letting a later reader assume it was closed.
text, problem = vv.decode_source(codecs.BOM_UTF8 * 2 + body.encode("utf-8"))
assert problem is None and text.startswith("﻿"), (problem, text[:2])

# Never raises, whatever it is handed: an exception here exits 2 and both
# hooks fail open, which switches the enforcement layer off silently.
assert vv.decode_source("already text") == ("already text", None)
assert vv.decode_source(b"") == ("", None)

# The property the whole design rests on: the encoding is NAMED, never
# honoured. read_text hands out exactly what it handed out before this
# change, for every shape above - which is what keeps the exporter, whose
# reader was not touched, reading the same bytes the same way.
tmp = Path(sys.argv[2])
for i, raw in enumerate((
        body.encode("utf-8"),
        codecs.BOM_UTF8 + body.encode("utf-8"),
        codecs.BOM_UTF16_LE + body.encode("utf-16-le"),
        b"\xef\xbb" + body.encode("utf-8"),
        body.replace("\n", "\r\n").encode("utf-8"),   # 16 real files carry CRLF
        "Gr\xf6\xdfe".encode("cp1252"))):             # no mark, undecodable
    p = tmp / f"enc_probe_{i}.md"
    p.write_bytes(raw)
    assert vv.read_text(p) == p.read_text(encoding="utf-8-sig", errors="replace"), \
        f"read_text changed for probe {i}"
    p.unlink()
PY
then ok x; else fail "decode_source must name the encoding without changing what is read"; fi

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
if has_key decision "$sout" && [ "$(field decision "$sout")" = "block" ]; then ok x; else
  fail "stop hook must block on new ERRORs (1st attempt)"; fi
# The form of the block, not just its presence. Claude Code 2.1.220 reads
# Stop decisions from the TOP LEVEL only; wrapped in hookSpecificOutput -
# the shape every other event uses, and the tidier-looking one - the hook
# is accepted, reported as success, and blocks nothing. json.dumps of that
# mutant still contains the substring '"decision": "block"', so the whole
# suite stayed green against a gate that had silently stopped gating.
TESTS=$((TESTS + 1))
if ! has_key hookSpecificOutput "$sout"; then ok x; else
  fail "a Stop decision inside hookSpecificOutput is ignored by Claude Code:"
  printf '%s\n' "$sout" | sed 's/^/    /'
fi
# The obligation and the advisory travel in different fields, to different
# readers: reason reaches Claude, systemMessage reaches the user. A block
# reason carries one obligation - the vault-wide section is legacy state
# and would spend a block attempt on it.
TESTS=$((TESTS + 1))
if ! contains "$(field reason "$sout")" "vault-wide"; then ok x; else
  fail "block reason must not carry the vault-wide advisory section"; fi
TESTS=$((TESTS + 1))
if contains "$(field systemMessage "$sout")" "vault validator blocked the turn end"; then ok x; else
  fail "a blocking turn must tell the user who blocked it:"
  printf '%s\n' "$sout" | sed 's/^/    /'
fi
sout=$(printf '{"session_id":"%s","stop_hook_active":true}' "$SID" | python3 "$VALIDATOR" --hook stop 2>&1)
TESTS=$((TESTS + 1))
if [ "$(field decision "$sout")" = "block" ]; then ok x; else fail "stop hook must block on 2nd attempt"; fi
sout=$(printf '{"session_id":"%s","stop_hook_active":true}' "$SID" | python3 "$VALIDATOR" --hook stop 2>&1)
smsg=$(field systemMessage "$sout")
# The fail-open report goes to the user and NOT to the model. The gate has
# demanded these fixes twice already; a third automatic attempt is the
# user's call. Asserting the field is what separates the two - the text
# occurs in the output either way.
TESTS=$((TESTS + 1))
if contains "$smsg" "UNRESOLVED"; then ok x; else
  fail "the fail-open report must reach the user as systemMessage:"
  printf '%s\n' "$sout" | sed 's/^/    /'
fi
TESTS=$((TESTS + 1))
if ! contains "$(field reason "$sout")" "UNRESOLVED"; then ok x; else
  fail "the fail-open report must not be handed back to the model as a reason"; fi
TESTS=$((TESTS + 1))
if ! has_key decision "$sout"; then ok x; else fail "stop hook must not block a 3rd time"; fi
TESTS=$((TESTS + 1))
if contains "$smsg" "vault-wide findings (advisory" && contains "$smsg" "req-uncovered"; then ok x; else
  fail "fail-open report must carry vault-wide advisory incl. req-uncovered"; fi
# The whole report is one systemMessage, and Claude Code replaces any hook
# output string over 10000 characters with a file path plus a 2 KB preview
# (measured on 2.1.220). This is the fail-open report of a vault carrying
# every seeded violation there is - if it does not stay under the ceiling,
# nothing here does.
TESTS=$((TESTS + 1))
n=$(printf '%s' "$smsg" | wc -c)
if [ "$n" -lt 10000 ]; then ok x; else
  fail "the session report must stay under the 10000-character hook cap, got $n"; fi

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
if ! contains "$(field systemMessage "$sout")" "vault-wide"; then ok x; else
  fail "clean vault stop report must not add a vault-wide section"; fi
rm -f "/tmp/claude-mechdocs/touched-$SID2" "/tmp/claude-mechdocs/baseline-$SID2" \
      "/tmp/claude-mechdocs/blocks-$SID2"

# Nothing to say -> say nothing. The report now renders in the transcript,
# so an empty one is not a harmless newline any more: it would print
# "Stop says: vault validator session report:" at the end of every single
# turn. The file is touched and then removed, which is the shortest way to
# a session whose every section is empty (the stop pass skips a file that
# no longer exists, so no vault root is ever collected either).
SID3="testsession3-$$"
rm -f "/tmp/claude-mechdocs/touched-$SID3" "/tmp/claude-mechdocs/baseline-$SID3" \
      "/tmp/claude-mechdocs/blocks-$SID3"
cp "$V/06_implementation_(IMP)/IMP_MainBoard_ADC.md" \
   "$V/06_implementation_(IMP)/IMP_Transient.md"
printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' "$SID3" \
  "$V/06_implementation_(IMP)/IMP_Transient.md" | python3 "$VALIDATOR" --hook post >/dev/null 2>&1
rm -f "$V/06_implementation_(IMP)/IMP_Transient.md"
sout=$(printf '{"session_id":"%s"}' "$SID3" | python3 "$VALIDATOR" --hook stop 2>&1); rc=$?
TESTS=$((TESTS + 1))
if [ $rc -eq 0 ] && [ -z "$sout" ]; then ok x; else
  fail "an empty session report must print nothing at all, got rc=$rc:"
  printf '%s\n' "$sout" | sed 's/^/    /'
fi
rm -f "/tmp/claude-mechdocs/touched-$SID3" "/tmp/claude-mechdocs/baseline-$SID3" \
      "/tmp/claude-mechdocs/blocks-$SID3"

# ==========================================================================
# Fixture 8: the advisory cap. The whole report travels as one
# systemMessage, and Claude Code replaces any hook output string above
# 10000 characters with a file path plus a 2 KB preview - a report that
# outgrows the ceiling is back on a channel nobody reads, which is the
# defect of issue #44 in a new costume.
#
# Its own vault, because the assertion is arithmetic: twenty notes, one
# advisory finding each, and every other finding class deliberately
# absent. In the violation vault the same session would drag along
# whatever else is seeded there and the count would stop being a count.
# ==========================================================================
CAP_TMP=$(mktemp -d)
trap 'rm -rf "$TMP" "$DE_TMP" "$EN_TMP" "$ID_TMP" "$CAP_TMP"' EXIT
P="$CAP_TMP/Capproj/00_documentation/01_projectvault"
mkdir -p "$P/01_requirements_(REQ)" "$P/03_architecture_(ARC)" \
         "$P/07_testing_and_evidence_(TAE)"
printf '## Context\n' > "$P/01_requirements_(REQ)/00_REQ_file_template.md"
printf '## Context\n' > "$P/03_architecture_(ARC)/00_ARC_file_template.md"
printf '## Context\n## Evidence\n' > "$P/07_testing_and_evidence_(TAE)/00_TAE_file_template.md"
i=1
while [ $i -le 20 ]; do
  cat > "$P/03_architecture_(ARC)/ARC_Filler_$i.md" <<EOF
---
domain: ARC
status: active
created: 2026-01-09
last-verified: 2026-07-01
---
## Context
Filler note number $i of the advisory-cap fixture. It exists so that one
session produces more advisory findings than the report may carry, and it
contributes exactly one of its own: the artifact it points at,
20_software/filler_$i/build_$i.py, is not in the tree. Everything else about
this note is deliberately correct, so no second finding can enter the
report from here and the count stays arithmetic.
EOF
  i=$((i + 1))
done
SIDC="testsession-cap-$$"
rm -f "/tmp/claude-mechdocs/touched-$SIDC" "/tmp/claude-mechdocs/baseline-$SIDC" \
      "/tmp/claude-mechdocs/blocks-$SIDC"
i=1
while [ $i -le 20 ]; do
  printf '{"session_id":"%s","tool_input":{"file_path":"%s"}}' "$SIDC" \
    "$P/03_architecture_(ARC)/ARC_Filler_$i.md" | python3 "$VALIDATOR" --hook post >/dev/null 2>&1
  i=$((i + 1))
done
cout=$(printf '{"session_id":"%s"}' "$SIDC" | python3 "$VALIDATOR" --hook stop 2>&1)
cmsg=$(field systemMessage "$cout")
TESTS=$((TESTS + 1))
n=$(printf '%s' "$cmsg" | grep -c 'path-missing')
if [ "$n" -eq 15 ]; then ok x; else
  fail "the advisory section must be capped at 15 lines, got $n of 20"; fi
TESTS=$((TESTS + 1))
if contains "$cmsg" "advisory findings:" && contains "$cmsg" "\.\.\. +5 more"; then ok x; else
  fail "the capped advisory section must say how many lines it dropped:"
  printf '%s\n' "$cmsg" | sed 's/^/    /'
fi
# The ceiling itself, on the session this fixture was built to be the worst
# case of. A cap that leaves the report above 10000 characters buys nothing.
TESTS=$((TESTS + 1))
n=$(printf '%s' "$cmsg" | wc -c)
if [ "$n" -lt 10000 ]; then ok x; else
  fail "the session report must stay under the 10000-character hook cap, got $n"; fi

# The other half of the cap, and the only one no vault fixture can reach:
# ERROR-severity lines are exempt from it. A session needs more than
# fifteen PRE-EXISTING ERRORs in one report to tell the two implementations
# apart - below that, sorted() puts every ERROR line ahead of every WARN
# line and a plain lines[:15] agrees with the exempting one by accident.
# Asserted on the function, because a fixture proving one boolean would
# have to commit sixteen broken files to do it.
TESTS=$((TESTS + 1))
if python3 -c '
import sys; sys.path.insert(0, sys.argv[1])
from validate_vault import cap_report_lines
lines = ["ERROR f%d" % i for i in range(20)] + ["WARN f%d" % i for i in range(20)]
out = cap_report_lines(lines)
assert len([l for l in out if l.startswith("ERROR")]) == 20, "ERROR lines were dropped"
assert len([l for l in out if l.startswith("WARN")]) == 0, "WARNs must yield to ERRORs"
assert out[-1] == "... +20 more", out[-1]
assert cap_report_lines(["WARN a", "ERROR b"]) == ["ERROR b", "WARN a"]
assert cap_report_lines([]) == []
' "$SKILL_DIR" 2>/dev/null; then ok x; else
  fail "the report cap must never drop an ERROR line"; fi
rm -f "/tmp/claude-mechdocs/touched-$SIDC" "/tmp/claude-mechdocs/baseline-$SIDC" \
      "/tmp/claude-mechdocs/blocks-$SIDC"

# ==========================================================================
# Crash mode and real template vault
# ==========================================================================
python3 "$VALIDATOR" /nonexistent_vault_root >/dev/null 2>&1; rc=$?
TESTS=$((TESTS + 1))
if [ $rc -eq 2 ]; then ok x; else fail "invalid root must exit 2, got $rc"; fi

# The gate releasing itself is the one message that must never be quiet: it
# says the vault rules are not being enforced right now. It used to go to
# stderr, which for a hook exiting 0 is the same dead channel as plain
# stdout. Unparsable stdin is the shortest real crash - json.load raises
# before any vault is touched.
gout=$(printf 'not json at all' | bash "$SKILL_DIR/hooks/stop_gate.sh" 2>/dev/null); rc=$?
TESTS=$((TESTS + 1))
if [ $rc -eq 0 ]; then ok x; else fail "a validator crash must release the gate, got rc=$rc"; fi
TESTS=$((TESTS + 1))
if contains "$(field systemMessage "$gout")" "stop gate released"; then ok x; else
  fail "a validator crash must reach the user as systemMessage:"
  printf '%s\n' "$gout" | sed 's/^/    /'
fi

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

# The method vault carries the decision record of this skill. It is audited by
# name in CI; this assertion says the same thing locally. Its length WARNs are
# the measured result of migrating 31 real decisions and are not an ERROR.
TESTS=$((TESTS + 1))
if [ -d "$METHOD_VAULT" ]; then
  out=$(python3 "$VALIDATOR" "$METHOD_VAULT" 2>&1); rc=$?
  if [ $rc -eq 0 ]; then ok x; else
    fail "method vault must contain no ERRORs:"; printf '%s\n' "$out" | grep '^ERROR' | sed 's/^/    /'
  fi
else
  fail "method vault not found at $METHOD_VAULT"
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

  # The ARC body carries the four shapes an annotated link comes in. Only the
  # first is a relation; the other three are the ways this mechanism used to
  # fail silently, and each must now be visible in the output.
  {
    printf -- '---\ndomain: ARC\nstatus: active\ncreated: 2026-07-31\nlast-verified: 2026-07-31\n---\n'
    printf '## %s\n\nThe module under export.\n\n' "$CTX"
    printf -- '- [[%s_Export (EXP)]] (%s-EXP-000): annotated, so this is a relation.\n' "$P" "$P"
    printf -- '- [[%s_Shadowed (SHD)]] (%s-EXP-000): annotated with the wrong id.\n' "$P" "$P"
    printf -- '- [[%s_Loose (LSE)]]: no annotation, so no relation - but a finding.\n' "$P"
    printf -- '- [[ARC_Top]] (ARC-EXP-001): a peer module is navigation, not containment.\n'
    printf 'A quoted example must not become an edge:\n\n'
    printf '```markdown\n- [[%s_Fenced (FNC)]] (%s-EXP-000): quoted\n```\n\n' "$P" "$P"
    printf '## %s\n| Submodule | Allocated | Verification | Status |\n' "$ALLOC"
    printf '| --- | --- | --- | --- |\n'
    printf '| [[ARC_Export]] | %s-EXP-001 | [[%s_Export]] | Verified |\n' "$P" "$EV"
    printf '| Tailnet resolver port 53 | %s-EXP-002 | [[%s_Export]] | Verified (Rebuild: Draft) |\n' "$P" "$EV"
    printf '| ranged | %s-EXP-003 bis %s-EXP-005 | [[%s_Export]] | Verified |\n' "$P" "$P" "$EV"
    printf '| continued | %s-EXP-001, 002 | [[%s_Export]] | Verified |\n' "$P" "$EV"
    printf '| ghost | %s-EXP-900 | prose only | Verified |\n' "$P"
    printf '| too wide | %s-EXP-004 bis %s-EXP-008 | [[%s_Export]] | Verified |\n' "$P" "$P" "$EV"
  } > "$V/$AR/ARC_Export.md"

  # The id makes this file addressable by identifier, which is what a
  # test-object field names. Without one its key is its filename and no
  # frontmatter field could reach it.
  {
    printf -- '---\ndomain: ARC\nstatus: active\ncreated: 2026-07-31\nlast-verified: 2026-07-31\n'
    printf 'id: ARC-EXP-001\n---\n'
    # The abbreviation is the index's sentence rule under test: a dot whose
    # next word continues in lower case does not end the sentence.
    printf '## %s\n\nTop module, e.g. the one every submodule hangs from. A second sentence the index must not carry.\n\n' "$CTX"
    printf '## %s\n| Submodule | Description |\n| --- | --- |\n' "$SUB"
    printf '| [[ARC_Export]] | the module under export |\n'
  } > "$V/$AR/ARC_Top.md"

  {
    printf -- '---\ndomain: %s\nstatus: active\ncreated: 2026-07-31\nlast-verified: 2026-07-31\n' "$EV"
    printf 'verifies: [%s-EXP-001, %s-EXP-002]\n' "$P" "$P"
    printf 'test-object: [ARC-EXP-001, ARC-EXP-900]\n---\n'
    # A context paragraph that never reaches a sentence terminator, so the
    # index has to apply its own ceiling to it.
    printf '## %s\n\nEvidence for the export example, recorded on a bench with a deliberately unpunctuated description that runs well past the two hundred and forty character ceiling the index applies, so the cap and its ellipsis are exercised by a file and not by a unit test alone\n' "$CTX"
  } > "$V/$TA/${EV}_Export.md"

  # The three shapes in which a requirement row leaves no trace in the graph
  # (issue #34). None of them contributes a row to it, so the counts asserted
  # below stay what they were; what they must contribute is a finding.

  # 1. A table under a section no template declares - the shape the issue was
  #    filed for, and the one nativclaw carries seven times.
  {
    printf -- '---\ndomain: %s\nstatus: active\ncreated: 2026-08-04\nlast-verified: 2026-08-04\n---\n' "$P"
    printf '## %s\n\nRequirements under a heading of this file own making.\n\n' "$CTX"
    printf '## Detached layer\n'
    printf '| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n'
    printf '| --- | --: | --- | --- | --- |\n'
    printf '| M | 001 | detached requirement | pass if reported | none |\n'
  } > "$V/$RQ/${P}_Loose (LSE).md"

  # 2. The same, in a file whose rows cannot be addressed at all. Every REQ
  #    file of the nativclaw vault is this file: if the check runs after the
  #    export-no-scope return, it never sees one of them.
  {
    printf -- '---\ndomain: %s\nstatus: active\ncreated: 2026-08-04\nlast-verified: 2026-08-04\n---\n' "$P"
    printf '## %s\n\nNeither a conforming id nor a scope token in the name.\n\n' "$CTX"
    printf '## Detached layer\n'
    printf '| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n'
    printf '| --- | --: | --- | --- | --- |\n'
    printf '| M | 001 | unaddressable requirement | pass if reported | none |\n'
  } > "$V/$RQ/${P}_Unscoped.md"

  # 3. Requirements written a layer at a time in the bound section, behind a
  #    five-column revision history. This is homelab's shape - 78 of its
  #    requirement rows sit in the second to tenth table of one '## Kontext',
  #    separated by '###' subheadings. Since issue #37 all of them are read,
  #    and the revision row is what proves the row predicate still holds: its
  #    second cell carries a date, so it defines no requirement.
  {
    printf -- '---\ndomain: %s\nstatus: active\ncreated: 2026-08-04\nlast-verified: 2026-08-04\n' "$P"
    printf 'id: %s-SHD-000\n---\n' "$P"
    printf '## %s\n\n' "$CTX"
    printf '| Version | Date | Author | Change | Review |\n'
    printf '| --- | --- | --- | --- | --- |\n'
    printf '| 1.0 | 2026-08-04 | jm | initial | ok |\n\n'
    printf '| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n'
    printf '| --- | --: | --- | --- | --- |\n'
    printf '| M | 001 | shadowed requirement | pass if exported | none |\n\n'
    printf '### Second layer\n'
    printf '| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n'
    printf '| --- | --: | --- | --- | --- |\n'
    printf '| M | 002 | requirement behind a subheading | pass if exported | none |\n'
  } > "$V/$RQ/${P}_Shadowed (SHD).md"
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
   [ -f "$EN_OUT/traceability_edges.csv" ] && \
   [ -f "$EN_OUT/traceability_graph.mmd" ]; then ok x; else
  fail "exporter must write json, html, both csv views and the graph"; fi

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
if [ "$en_counts" = "7 4 18" ]; then ok x; else
  fail "expected 7 requirements, 4 proven, 18 edges; got '$en_counts'"; fi

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
if [ "$(exq 'any(e["kind"]=="contains" and e["source"]=="ARC-EXP-001" for e in d["edges"])')" = "True" ]; then ok x; else
  fail "the main-module submodule table must yield an ARC-to-ARC edge"; fi

# Issue #49: both relations were declared and produced nothing. Every
# assertion in this block fails on the code that shipped before the fix.
TESTS=$((TESTS + 1))
if [ "$(exq 'any(e["kind"]=="contains" and e["target"]=="REQ:REQ_Export (EXP)" for e in d["edges"])')" = "True" ]; then
  ok x; else fail "an annotated link in the ARC body must yield a contains edge"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'sum(1 for e in d["edges"] if e["kind"]=="test-object")')" = "1" ]; then
  ok x; else fail "a test-object frontmatter field must yield exactly its resolvable edge"; fi
# The three shapes that must NOT become containment.
TESTS=$((TESTS + 1))
if [ "$(exq 'any(e["kind"]=="contains" and e["target"]=="ARC-EXP-001" for e in d["edges"])')" = "False" ]; then
  ok x; else fail "an annotated peer-module link in the ARC body must stay navigation"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'any("Loose" in e["target"] for e in d["edges"] if e["kind"]=="contains")')" = "False" ]; then
  ok x; else fail "an unannotated link must not become a relation"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'any("Fenced" in str(e["target"]) for e in d["edges"])')" = "False" ]; then
  ok x; else fail "an annotated link quoted in a code fence must not become an edge"; fi
# ... and each of them says so, rather than leaving the graph quietly short.
TESTS=$((TESTS + 1))
if [ "$(exq 'any(f["code"]=="export-unannotated-link" and "Loose" in f["message"] for f in d["findings"])')" = "True" ]; then
  ok x; else fail "a link that could have been a relation must be reported when unannotated"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'any(f["code"]=="export-annotation-mismatch" for f in d["findings"])')" = "True" ]; then
  ok x; else fail "an annotation contradicting the linked file's own id must be reported"; fi
TESTS=$((TESTS + 1))
if [ "$(exq 'any(f["code"]=="export-unknown-test-object" and "900" in f["message"] for f in d["findings"])')" = "True" ]; then
  ok x; else fail "a test-object naming no file in the vault must be reported"; fi
TESTS=$((TESTS + 1))
if [ "$(exq '"no-evidence-note" in d["coverage"]["REQ-EXP-005"]["open_questions"]')" = "True" ]; then
  ok x; else fail "a requirement no evidence note names must carry that open question"; fi

# Issue #34: a requirement row the graph does not contain is a finding, not an
# absence. Each assertion below fails on the code that shipped before it.
TESTS=$((TESTS + 1))
if [ "$(exq 'any(f["code"]=="export-unbound-table" and "Loose" in (f["file"] or "") for f in d["findings"])')" = "True" ]; then
  ok x; else fail "a requirement table under an undeclared section must be reported"; fi
# The ordering with export-no-scope, which is the whole of the fix's effect on
# the corpus that motivated it: after the return this assertion fails alone.
TESTS=$((TESTS + 1))
if [ "$(exq 'sorted(f["code"] for f in d["findings"] if "Unscoped" in (f["file"] or ""))')" = "['export-no-scope', 'export-unbound-table']" ]; then
  ok x; else fail "a file whose rows cannot be addressed must report BOTH its scope and its lost rows"; fi
# Issue #37 turns this fixture around: the table behind the revision history
# is now read, so the rows arrive and there is nothing left to report. Both
# assertions fail on the code that shipped before the ingestion change.
TESTS=$((TESTS + 1))
if [ "$(exq 'sum(1 for f in d["findings"] if "Shadowed" in (f["file"] or ""))')" = "0" ]; then
  ok x; else fail "a requirement table behind another table in the bound section must be read, not reported"; fi
TESTS=$((TESTS + 1))
if [ "$(exq '"REQ-SHD-001" in d["requirements"]')" = "True" ]; then
  ok x; else fail "the shadowed fixture must gain its row"; fi
# The third table sits behind a '###' subheading, which is homelab's shape and
# not a section boundary - a heading of that depth must not end the binding.
TESTS=$((TESTS + 1))
if [ "$(exq '"REQ-SHD-002" in d["requirements"]')" = "True" ]; then
  ok x; else fail "a requirement table behind a '###' subheading must still be read"; fi
# ... and the five-column revision history in front of both must NOT contribute:
# its second cell carries a date, which is the predicate that keeps them apart.
TESTS=$((TESTS + 1))
if [ "$(exq 'sum(1 for r in d["requirements"] if r.startswith("REQ-SHD"))')" = "2" ]; then
  ok x; else fail "the revision history above the requirement tables must contribute no requirement"; fi
# The counter-assertion: a table that IS bound stays unreported.
TESTS=$((TESTS + 1))
if [ "$(exq 'any(f["code"]=="export-unbound-table" and (f["file"] or "").endswith("REQ_Export (EXP).md") for f in d["findings"])')" = "False" ]; then
  ok x; else fail "the bound requirement table must not be reported as lost"; fi
# The German twin sees the same defects. en_counts=de_counts covers the graph
# and not the findings, so without this the DE half of the fixture asserts
# nothing at all.
de_codes=$(python3 - "$DE_OUT/traceability.json" <<'PY'
import json, sys
print(sorted(f["code"] for f in json.load(open(sys.argv[1]))["findings"]))
PY
)
en_codes=$(exq 'sorted(f["code"] for f in d["findings"])')
TESTS=$((TESTS + 1))
if [ "$de_codes" = "$en_codes" ]; then ok x; else
  fail "German and English twin must report the same finding codes:"
  printf '    en: %s\n    de: %s\n' "$en_codes" "$de_codes"; fi

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

# Issue #53: the index an agent reads first. It is a default format, so the
# determinism assertion below and the CI step that runs the exporter twice
# both cover it without knowing about it.
IDX="$EN_OUT/traceability_index.md"
TESTS=$((TESTS + 1))
if [ -f "$IDX" ]; then ok x; else
  fail "the default formats must write traceability_index.md"; fi

TESTS=$((TESTS + 1))
if python3 - "$IDX" "$EN_OUT/traceability.json" <<'PY'
import json, sys
rows = [l for l in open(sys.argv[1], encoding="utf-8").read().splitlines()
        if l.startswith("- `")]
d = json.load(open(sys.argv[2]))
assert len(rows) == len(d["nodes"]) + len(d["requirements"]), \
    f"{len(rows)} rows for {len(d['nodes'])} objects and {len(d['requirements'])} requirements"
for key in list(d["nodes"]) + list(d["requirements"]):
    assert any(l.startswith(f"- `{key}` ") for l in rows), f"no index line for {key}"
PY
then ok x; else fail "the index must carry one line per object and per requirement"; fi

sumq() { python3 - "$1" "$2" <<'PY'
import json, sys
print(json.load(open(sys.argv[1]))["summaries"].get(sys.argv[2], ""), end="")
PY
}
TESTS=$((TESTS + 1))
if [ "$(sumq "$EN_OUT/traceability.json" "ARC:ARC_Export")" = "The module under export." ]; then
  ok x; else fail "the sentence must be the first sentence of the bound section, got '$(sumq "$EN_OUT/traceability.json" "ARC:ARC_Export")'"; fi
# The rule the plan for this feature first got wrong: a dot whose next word
# continues in lower case does not end a sentence.
TESTS=$((TESTS + 1))
if [ "$(sumq "$EN_OUT/traceability.json" "ARC-EXP-001")" = "Top module, e.g. the one every submodule hangs from." ]; then
  ok x; else fail "an abbreviation must not cut the sentence, got '$(sumq "$EN_OUT/traceability.json" "ARC-EXP-001")'"; fi
TESTS=$((TESTS + 1))
if python3 - "$EN_OUT/traceability.json" <<'PY'
import json, sys
s = json.load(open(sys.argv[1]))["summaries"]["TAE:TAE_Export"]
assert s.endswith("…"), s
assert len(s) <= 241, len(s)
PY
then ok x; else fail "a paragraph without a sentence end must be capped with an ellipsis"; fi

# A section carrying only tables is a legitimate shape - the object keeps its
# line, the head counts it, and nothing is reported. The Shadowed fixture is
# asserted at zero findings above, which this must not change.
TESTS=$((TESTS + 1))
if python3 - "$EN_OUT/traceability.json" "$IDX" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
text = open(sys.argv[2], encoding="utf-8").read()
assert "REQ-SHD-000" in d["nodes"], "the shadowed fixture must be an object"
assert "REQ-SHD-000" not in d["summaries"], "a table-only section yields no sentence"
line = [l for l in text.splitlines() if l.startswith("- `REQ-SHD-000` ")][0]
assert line.endswith("·"), repr(line)
assert "objects without a sentence: 1 of" in text, text.split("\n\n")[2]
PY
then ok x; else fail "an object without a sentence must keep its line and be counted, not reported"; fi

# Markdown carries raw HTML, so the payload the report escapes must not walk
# into the index unescaped either.
TESTS=$((TESTS + 1))
if contains "$(cat "$IDX")" '&lt;script&gt;alert' && \
   ! contains "$(cat "$IDX")" '<script>alert'; then ok x; else
  fail "a script tag from the vault must reach the index escaped, not raw"; fi

# The German twin binds its own section and loses nothing.
DE_IDX="$DE_OUT/traceability_index.md"
en_rows=$(grep -c '^- `' "$IDX"); de_rows=$(grep -c '^- `' "$DE_IDX")
TESTS=$((TESTS + 1))
if [ "$en_rows" = "$de_rows" ]; then ok x; else
  fail "German and English twin must yield the same index rows: $en_rows vs $de_rows"; fi
TESTS=$((TESTS + 1))
if contains "$(cat "$DE_IDX")" '`## Kontext`'; then ok x; else
  fail "the German twin must bind its own context section"; fi

# The index is a format; the sentences are part of the graph document and
# marked as derived, because a located and truncated sentence is not authored.
python3 "$EXPORTER" "$EN_V" --output-dir "$EX_TMP/out-json" --no-timestamp \
  --formats json >/dev/null 2>&1
TESTS=$((TESTS + 1))
if [ ! -f "$EX_TMP/out-json/traceability_index.md" ] && \
   [ -f "$EX_TMP/out-json/traceability.json" ]; then ok x; else
  fail "--formats json must write the graph and no index"; fi
TESTS=$((TESTS + 1))
if python3 - "$EX_TMP/out-json/traceability.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert "summaries" in d["field_types"]["derived"], d["field_types"]
assert "summaries" not in d["field_types"]["authored"], d["field_types"]
assert all("summary" not in n for n in d["nodes"].values()), "authored nodes gained a derived field"
PY
then ok x; else fail "summaries must be declared derived and never written onto a node"; fi

# --------------------------------------------------------------------------
# Issue #99 / DEC-MTH-043: the drawn graph. There is no Mermaid parser in a
# stdlib-only repository, so the substitute is a structural self-check -
# every emitted line has to be one of four shapes, and no label may carry a
# character that would end the label or the diagram. A currency check alone
# (the CI diff) would happily keep a syntactically dead diagram current.
# --------------------------------------------------------------------------
MMD="$EN_OUT/traceability_graph.mmd"

TESTS=$((TESTS + 1))
if python3 - "$MMD" <<'PY'
import re, sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
assert lines and lines[0] == "flowchart LR", lines[:1]
NODE = re.compile(r'^  [A-Za-z_][A-Za-z0-9_]*(\["[^"]*"\]|\("[^"]*"\))$')
EDGE = re.compile(r'^  [A-Za-z_][A-Za-z0-9_]*'
                  r' -->\|"[^"|]*"\| [A-Za-z_][A-Za-z0-9_]*$')
for i, line in enumerate(lines[1:], start=2):
    assert line.startswith("  %% ") or NODE.match(line) or EDGE.match(line), \
        f"line {i} is none of the four shapes: {line!r}"
# The labels, read back out and checked for what must never survive in one.
# '<br>' is the one piece of markup the writer authors itself; every other
# angle bracket would be vault content that reached the label unescaped.
for label in re.findall(r'"([^"]*)"', "\n".join(lines)):
    for bad in ("|", "&", "`", "{", "}"):
        assert bad not in label, f"unescaped {bad!r} in label {label!r}"
    rest = label.replace("<br>", "")
    assert "<" not in rest and ">" not in rest, f"raw markup in label {label!r}"
PY
then ok x; else fail "every line of the graph must be a shape Mermaid accepts"; fi

# The scope is stated in the artifact, not only in a decision record: a
# reader of the file has to be able to see that four relations are not in it.
TESTS=$((TESTS + 1))
if contains "$(cat "$MMD")" "traceability_edges.csv" && \
   contains "$(cat "$MMD")" "allocates,"; then ok x; else
  fail "the graph must name its own scope and where the full edge set is"; fi

# Only the coverage relations, and every one of them. Read against the JSON
# so the two cannot drift: an edge kind added to GRAPH_KINDS without a test
# still has to survive the shape check above.
TESTS=$((TESTS + 1))
if python3 - "$MMD" "$EN_OUT/traceability.json" <<'PY'
import json, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
d = json.load(open(sys.argv[2]))
drawn = {m.split(":")[0].strip() for m in re.findall(r'-->\|"([^"]*)"\|', text)}
assert drawn == {"allocates", "evidence", "verifies"}, drawn
# Every distinct coverage edge of the graph reaches the picture exactly once,
# and a repeated one is collapsed rather than stacked.
want = {(e["kind"], e["source"], e["target"], e["qualifier"])
        for e in d["edges"] if e["kind"] in ("allocates", "evidence", "verifies")}
assert len(re.findall(r"-->", text)) == len(want), \
    f"{len(re.findall(r'-->', text))} arrows for {len(want)} distinct edges"
PY
then ok x; else fail "the graph must draw each distinct coverage edge exactly once"; fi

# The state the count line reports, on the node it belongs to. The fixture's
# EXP-002 is allocated 'Verified (Rebuild: Draft)' - qualified, not proven -
# so the picture must not read like the word in the cell.
TESTS=$((TESTS + 1))
if python3 - "$MMD" "$EN_OUT/traceability.json" <<'PY'
import json, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
cov = json.load(open(sys.argv[2]))["coverage"]
seen = dict(re.findall(r'\("([A-Z]{2,4}-[A-Z]{2,4}-\d{3})<br>(proven|not proven)"\)', text))
assert seen, "no requirement node carried a proven state"
for rid, state in seen.items():
    want = "proven" if cov[rid]["proven"] else "not proven"
    assert state == want, f"{rid}: node says {state!r}, coverage says {want!r}"
assert seen.get("REQ-EXP-002") == "not proven", seen.get("REQ-EXP-002")
PY
then ok x; else fail "a requirement node must carry the coverage verdict, not the cell's word"; fi

# The file is a picture and nothing else: no vault path, no digest, no time.
# TUTORIAL.md prints its commands without --no-timestamp, so the graph it
# quotes only stays true while this holds.
python3 "$EXPORTER" "$EN_V" --output-dir "$EX_TMP/out-stamped" >/dev/null 2>&1
TESTS=$((TESTS + 1))
if cmp -s "$MMD" "$EX_TMP/out-stamped/traceability_graph.mmd"; then ok x; else
  fail "the graph must be byte-identical with and without --no-timestamp"; fi

# A vault the coverage chain is absent from says so in the artifact. An
# empty diagram is a parse error, which is a red box where a reader was
# promised a picture - the same posture the index takes with an empty vault.
TESTS=$((TESTS + 1))
if [ -d "$METHOD_VAULT" ]; then
  python3 "$EXPORTER" "$METHOD_VAULT" --output-dir "$EX_TMP/out-nograph" \
    --no-timestamp --formats mermaid >/dev/null 2>&1
  if contains "$(cat "$EX_TMP/out-nograph/traceability_graph.mmd")" \
       "none of the coverage chain could be drawn" && \
     [ "$(grep -c -- '-->' "$EX_TMP/out-nograph/traceability_graph.mmd")" = "0" ]; then
    ok x; else fail "a vault without a coverage chain must say so in the diagram"; fi
else
  fail "method vault not found at $METHOD_VAULT"
fi

# The negative control, and the three rules a real vault cannot reach from
# here. write_mermaid is called directly, because a status cell carrying a
# '|', a requirements file carrying the identifier of one of its own rows,
# and two keys sanitising to one id are each legal and each absent from the
# fixtures above. Without the escaping the first alone kills the diagram.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" "$EX_TMP/unit.mmd" <<'PY'
import re, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
import export_traceability as ex

g = ex.Graph()
# 'REQ-UNI-001' is BOTH a file object and a requirement row - legal, and a
# single id namespace would silently merge them.
g.nodes["REQ-UNI-001"] = {"key": "REQ-UNI-001", "role": "REQ", "domain": "REQ",
                          "name": "REQ_Unit (UNI)", "file": "r.md",
                          "id_source": "frontmatter", "status": None,
                          "last_verified": None}
# A filename-keyed object: its key already carries the name, so the label
# must not repeat it.
g.nodes["ARC:ARC_Unit"] = {"key": "ARC:ARC_Unit", "role": "ARC", "domain": "ARC",
                           "name": "ARC_Unit", "file": "a.md",
                           "id_source": "filename", "status": None,
                           "last_verified": None}
# Sanitises to the same characters as the key above - the counter has to
# keep them apart.
g.nodes["ARC-ARC-Unit"] = {"key": "ARC-ARC-Unit", "role": "ARC", "domain": "ARC",
                           "name": "ARC_Unit_Two", "file": "a2.md",
                           "id_source": "frontmatter", "status": None,
                           "last_verified": None}
g.nodes["TAE:TAE_Unit"] = {"key": "TAE:TAE_Unit", "role": "TAE", "domain": "TAE",
                           "name": "TAE_Unit", "file": "t.md",
                           "id_source": "filename", "status": None,
                           "last_verified": None}
g.requirements["REQ-UNI-001"] = {"id": "REQ-UNI-001", "file": "r.md", "line": 9}
# The status cell that ends the diagram if it is not escaped. '\|' in a
# table cell is a real spelling and unescape() hands it over as a bare '|'.
nasty = 'Verified | Draft <b>#1</b> & "quoted"'
g.add_edge("allocates", "ARC:ARC_Unit", "REQ-UNI-001", "a.md", 12, qualifier=nasty)
g.add_edge("evidence", "ARC:ARC_Unit", "TAE:TAE_Unit", "a.md", 12, qualifier=nasty)
# The same edge a second time, as a second allocation row would author it.
g.add_edge("evidence", "ARC:ARC_Unit", "TAE:TAE_Unit", "a.md", 30, qualifier=nasty)
g.add_edge("verifies", "TAE:TAE_Unit", "REQ-UNI-001", "t.md", 1)
# Draws the second colliding key and the REQ FILE object, so the id rules
# are exercised rather than skipped: an object nothing connects is not part
# of the coverage chain and is correctly left out of the picture.
g.add_edge("evidence", "ARC-ARC-Unit", "REQ-UNI-001", "a2.md", 5)

out = Path(sys.argv[2])
ex.write_mermaid(out, g, {"REQ-UNI-001": {"proven": False}})
text = out.read_text(encoding="utf-8")

# Nothing structural survived inside a label.
labels = re.findall(r'"([^"]*)"', text)
assert labels, text
for label in labels:
    for bad in ("|", "&", "`"):
        assert bad not in label, f"unescaped {bad!r} in {label!r}"
    assert "<" not in label.replace("<br>", ""), f"raw markup in {label!r}"
assert "#124;" in text and "#60;" in text and "#38;" in text and "#quot;" in text, text
assert "#35;1" in text, "'#' must be escaped before the other entities"

# The two namespaces stay apart: the same string is a file object and a
# requirement row, and each keeps its own node.
assert 'o_REQ_UNI_001["REQ-UNI-001<br>REQ_Unit (UNI)"]' in text, text
assert 'r_REQ_UNI_001("REQ-UNI-001<br>not proven")' in text, text
# Two keys sanitising to one id keep their own too, numbered in sorted key
# order - 'ARC-ARC-Unit' sorts before 'ARC:ARC_Unit'.
assert 'o_ARC_ARC_Unit["ARC-ARC-Unit<br>ARC_Unit_Two"]' in text, text
# A filename-keyed object does not repeat its own name; its key carries it.
assert 'o_ARC_ARC_Unit_2["ARC:ARC_Unit"]' in text, text
# The duplicated evidence edge is collapsed; four distinct ones remain.
assert text.count("-->") == 4, text
PY
then ok x; else fail "the graph must survive a status cell that would otherwise end it"; fi

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

# Issue #38: two folders of one vault meaning one domain. Which one the
# graph keeps does not change - the sorted-first abbreviation, as before -
# so what is asserted here is that the choice stops being silent. Both
# spellings of the defect are built, because a vault mid-translation
# carries both: two abbreviations for one role (ANF beside REQ), and one
# abbreviation twice (German and English spell ARC identically, and that
# pair is collapsed by Vault.domains before any role is resolved).
#
# The added folder carries the same five-column template as the vault's
# own. A stub template would leave req_table bound to nothing, and the
# row assertions below would then pass because NOTHING was exported.
dup_req_folder() { # <vault> <folder> <abbr> <template suffix> <section>
  mkdir -p "$1/$2"
  printf '## %s\n\n| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n| --- | --: | --- | --- | --- |\n|  |  |  |  |  |\n' \
    "$5" > "$1/$2/00_$3_$4.md"
  {
    printf -- '---\ndomain: %s\nstatus: active\ncreated: 2026-08-04\nlast-verified: 2026-08-04\n---\n' "$3"
    printf '## %s\n\nThe translated twin of the requirements folder.\n\n' "$5"
    printf '| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n'
    printf '| --- | --: | --- | --- | --- |\n'
    printf '| M | 001 | translated requirement | pass if exported | none |\n'
  } > "$1/$2/$3_Export (EXP).md"
}
dup_req_folder "$EN_V" "01_Anforderungen_(ANF)" "ANF" "file_template" "Context"
dup_req_folder "$DE_V" "01_requirements_(REQ)" "REQ" "Dateitemplate" "Kontext"
# The ARC twin gets the same templates as its namesake, so the bindings are
# the same whichever of the two readdir hands to Vault - the export must be
# deterministic here even though the folder it reads is not chosen by a rule.
mkdir -p "$EN_V/03_Architektur_(ARC)"
cp "$EN_V/03_architecture_(ARC)/00_ARC_"*.md "$EN_V/03_Architektur_(ARC)/"

python3 "$EXPORTER" "$EN_V" --output-dir "$EX_TMP/out-dup-en" --no-timestamp \
  >/dev/null 2>&1
python3 "$EXPORTER" "$DE_V" --output-dir "$EX_TMP/out-dup-de" --no-timestamp \
  >/dev/null 2>&1
dupq() { python3 - "$1" "$2" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(eval(sys.argv[2], {"d": d, "sorted": sorted, "len": len, "any": any,
                         "all": all, "sum": sum}))
PY
}

TESTS=$((TESTS + 1))
if [ "$(dupq "$EX_TMP/out-dup-en/traceability.json" 'any(f["code"]=="export-duplicate-role" and f["file"]=="01_requirements_(REQ)" and "01_Anforderungen_(ANF)" in f["message"] for f in d["findings"])')" = "True" ]; then
  ok x; else fail "a second folder for one role must be reported, naming both"; fi
# The same-abbreviation pair: exactly one of the two is excluded, and which
# one is readdir's business - so the assertion is on the count and on both
# names being in the message, never on which one the file column shows.
TESTS=$((TESTS + 1))
if [ "$(dupq "$EX_TMP/out-dup-en/traceability.json" 'sum(1 for f in d["findings"] if f["code"]=="export-duplicate-role" and "(ARC)" in (f["file"] or "") and "03_architecture_(ARC)" in f["message"] and "03_Architektur_(ARC)" in f["message"])')" = "1" ]; then
  ok x; else fail "two folders sharing one abbreviation must be reported once, naming both"; fi
# The next two pin the DECISION rather than the fix: both hold on the code
# that shipped before this finding existed. They are what makes the finding
# above verifiable - the loss it names is real and it is this large.
TESTS=$((TESTS + 1))
if [ "$(dupq "$EX_TMP/out-dup-en/traceability.json" 'sum(1 for r in d["requirements"] if r.startswith("REQ-"))')" = "0" ]; then
  ok x; else fail "the excluded folder's requirements must be absent from the graph"; fi
TESTS=$((TESTS + 1))
if [ "$(dupq "$EX_TMP/out-dup-en/traceability.json" '"ANF-EXP-001" in d["requirements"]')" = "True" ]; then
  ok x; else fail "the kept folder's requirements must be in the graph"; fi
# The German twin loses the ADDED folder instead of its own, because the rule
# is the sorted abbreviation and not the vault's language: same code, and a
# graph that still carries its own rows.
TESTS=$((TESTS + 1))
if [ "$(dupq "$EX_TMP/out-dup-de/traceability.json" 'any(f["code"]=="export-duplicate-role" and f["file"]=="01_requirements_(REQ)" for f in d["findings"]) and "ANF-EXP-001" in d["requirements"]')" = "True" ]; then
  ok x; else fail "the German twin must report the same code and keep its own rows"; fi
# Determinism across the readdir-dependent pair, on one disk state. Into the
# SAME output directory as the run above, because provenance records the
# output path and two directories can never compare equal.
cp -r "$EX_TMP/out-dup-en" "$EX_TMP/out-dup-en-ref"
python3 "$EXPORTER" "$EN_V" --output-dir "$EX_TMP/out-dup-en" --no-timestamp \
  >/dev/null 2>&1
TESTS=$((TESTS + 1))
if diff -r "$EX_TMP/out-dup-en-ref" "$EX_TMP/out-dup-en" >/dev/null 2>&1; then ok x; else
  fail "two runs over a vault with duplicate domain folders must still agree"; fi
# The counter-assertion: a vault with one folder per role reports none of it.
TESTS=$((TESTS + 1))
if [ "$(dupq "$EN_OUT/traceability.json" 'any(f["code"]=="export-duplicate-role" for f in d["findings"])')" = "False" ]; then
  ok x; else fail "a vault with one folder per role must carry no duplicate-role finding"; fi

rm -rf "$EN_V/01_Anforderungen_(ANF)" "$EN_V/03_Architektur_(ARC)" \
       "$DE_V/01_requirements_(REQ)"

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
# Since issue #34 the exporter groups a REQ file's rows into tables with the
# validator's own reader, so the two tools cannot disagree about how many
# requirement rows a file has - only about which of them reached the graph.
assert vv.req_tables is ex.req_tables, "the exporter re-declared req_tables"

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

# req_tables against the same spec. The header is the row above a delimiter
# row of the SAME width - "if the header row does not match the delimiter row
# in the number of cells ... a table will not be recognized" - which is what
# makes a header identifiable without reading its words (issue #25).
t = vv.req_tables(['| a | b | c |', '| --- | --- | --- |', '| 1 | 2 | 3 |'])
assert len(t) == 1 and t[0][0] == ['a', 'b', 'c'] and t[0][1] == 1
assert t[0][2] == [(3, ['1', '2', '3'])]
# Widths disagree: no table at all, so the first row stays a row and no
# caller may read it as a header.
t = vv.req_tables(['| a | b | c |', '| --- | --- |', '| 1 | 2 | 3 |'])
assert len(t) == 1 and t[0][0] is None, t
assert [line for line, _ in t[0][2]] == [1, 3]
# A fenced line ENDS a group. Merged, the second header becomes a body row.
t = vv.req_tables(['| a | b |', '| --- | --- |', '| 1 | 2 |',
                   '```', '| x | y |', '```',
                   '| a | b |', '| --- | --- |', '| 3 | 4 |'])
assert len(t) == 2 and t[0][1] == 1 and t[1][1] == 7, t
assert t[1][2] == [(9, ['3', '4'])]
# The empty placeholder rows this project's own REQ template ships are
# is_separator-shaped. Only the row directly after a group's first row can
# become the delimiter, so they promote nothing and stay out of the rows.
t = vv.req_tables(['| Class (M/S/O) | NNN |', '| --- | --- |',
                   '|      |     |', '| M | 001 |'])
assert len(t) == 1 and t[0][0] == ['Class (M/S/O)', 'NNN']
assert t[0][2] == [(4, ['M', '001'])], t[0][2]
# req_rows is the flat view of it, and every row it yields is a row by the
# shared predicate above - the two must not drift into disagreeing.
lines = ['| a | b |', '| --- | --- |', '| 1 | 2 |', 'prose', '| c | d |']
assert list(vv.req_rows(lines)) == [(3, ['1', '2']), (5, ['c', 'd'])]
assert all(row(lines[i - 1]) == cells for i, cells in vv.req_rows(lines))
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
# file every fixture in this suite builds, plus the shipped vault and the
# method vault - the latter is 32 hand-migrated notes carrying fenced blocks,
# indented blocks and quoted wikilinks, which is exactly the corpus a fence
# reader gets wrong.
# ==========================================================================
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" "$TMP" "$DE_TMP" "$EN_TMP" "$EX_TMP" "$REAL_VAULT" "$METHOD_VAULT" <<'PY'
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
        # The masks can only agree about a file the two tools read alike.
        # Until issue #21 they did not: the exporter read BOM-safe and the
        # validator did not, so line 1 of a marked file was '---' in one
        # tool and '﻿---' in the other - and this harness, reading by
        # a third rule of its own, could not see it.
        a, b = vv.read_lines(f), ex.read_lines(f)
        assert (a[0] if a else "") == (b[0] if b else ""), \
            f"the two readers disagree about line 1 of {f}"
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

# ==========================================================================
# Issue #42: two folders under ONE abbreviation. German and English spell
# ARC, IMP and REF identically, so a vault mid-translation carries the pair
# whether anyone meant to or not, and Vault used to index whichever readdir
# returned last. The two folders here carry DIFFERENT templates on purpose:
# with identical ones every run would agree trivially and nothing below
# would prove which folder was read.
# ==========================================================================
DUP_TMP=$(mktemp -d)
trap 'rm -rf "$TMP" "$DE_TMP" "$EN_TMP" "$EX_TMP" "$DUP_TMP"' EXIT

dup_arc_en() { # <vault root>
  mkdir -p "$1/03_architecture_(ARC)"
  printf '## Context\n' > "$1/03_architecture_(ARC)/00_ARC_file_template.md"
  {
    printf -- '---\ndomain: ARC\nstatus: active\ncreated: 2026-08-04\nlast-verified: 2026-08-04\n---\n'
    printf '## Context\n\nThe English architecture note of this vault.\n'
    printf 'It answers one question and names no concrete value.\n'
    printf 'Written under the English template, in the English folder.\n'
  } > "$1/03_architecture_(ARC)/ARC_Module.md"
}

dup_arc_de() { # <vault root> <full|stub>
  mkdir -p "$1/03_Architektur_(ARC)"
  printf '## Kontext\n' > "$1/03_Architektur_(ARC)/00_ARC_Dateitemplate.md"
  [ "$2" = "full" ] || return 0
  {
    printf -- '---\ndomain: ARC\nstatus: active\ncreated: 2026-08-04\nlast-verified: 2026-08-04\n---\n'
    printf '## Kontext\n\nDie deutsche Architekturnotiz dieses Vaults.\n'
    printf 'Sie beantwortet eine Frage und nennt keinen konkreten Wert.\n'
    printf 'Geschrieben unter dem deutschen Template, im deutschen Ordner.\n'
  } > "$1/03_Architektur_(ARC)/ARC_Modul.md"
}

dup_vault() { # <vault root> <en-first|de-first> <full|stub>
  mkdir -p "$1/01_requirements_(REQ)" "$1/02_decisions_(DEC)"
  printf '## Context\n' > "$1/01_requirements_(REQ)/00_REQ_file_template.md"
  printf '## Context\n' > "$1/02_decisions_(DEC)/00_DEC_file_template.md"
  # The creation order is the point: on ext4 it is the order readdir hands
  # the entries back, so two vaults built the two ways are the two disk
  # states one vault can have on two machines.
  if [ "$2" = "en-first" ]; then
    dup_arc_en "$1"; dup_arc_de "$1" "$3"
  else
    dup_arc_de "$1" "$3"; dup_arc_en "$1"
  fi
}

DUP_A="$DUP_TMP/a/00_documentation/01_projectvault"
DUP_B="$DUP_TMP/b/00_documentation/01_projectvault"
dup_vault "$DUP_A" en-first full
dup_vault "$DUP_B" de-first full
dup_a=$(python3 "$VALIDATOR" "$DUP_A" 2>&1 | sed "s|$DUP_TMP/a||g")
dup_a2=$(python3 "$VALIDATOR" "$DUP_A" 2>&1 | sed "s|$DUP_TMP/a||g")
dup_b=$(python3 "$VALIDATOR" "$DUP_B" 2>&1 | sed "s|$DUP_TMP/b||g")

TESTS=$((TESTS + 1))
if [ "$(printf '%s\n' "$dup_a" | grep -c 'domain-duplicate-folder')" = "1" ] \
   && contains "$dup_a" "both carry the ARC domain" \
   && contains "$dup_a" "03_Architektur_(ARC)" \
   && contains "$dup_a" "03_architecture_(ARC)"; then
  ok x; else fail "two folders under one abbreviation must be reported once, naming both:"
  printf '%s\n' "$dup_a" | grep domain-duplicate | sed 's/^/    /'
fi
# The rule, not the file system: both folders hold ARC_* files, so the
# sorted-first one wins - and a capital letter sorts first.
TESTS=$((TESTS + 1))
if contains "$dup_a" "'03_Architektur_(ARC)' is the one this vault reads"; then
  ok x; else fail "the kept folder must be the sorted-first one holding domain files"; fi
# Every folder of the abbreviation contributes its templates, so the file
# below the folder that lost is not measured against the winner's sections.
TESTS=$((TESTS + 1))
if ! contains "$dup_a" "template-sections" && contains "$dup_a" "0 error(s)"; then
  ok x; else fail "neither ARC file may lose its required sections to the other folder:"
  printf '%s\n' "$dup_a" | grep -E 'ERROR|error\(s\)' | sed 's/^/    /'
fi
TESTS=$((TESTS + 1))
if [ "$dup_a" = "$dup_a2" ]; then ok x; else
  fail "two runs over a vault with two folders under one abbreviation must agree"; fi
# The property issue #42 was filed for: same content, opposite creation
# order, every line of the report identical - the duplicate-basename WARNs
# the second folder produces included.
TESTS=$((TESTS + 1))
if [ "$dup_a" = "$dup_b" ]; then ok x; else
  fail "the two creation orders must produce the same report:"
  diff <(printf '%s\n' "$dup_a") <(printf '%s\n' "$dup_b") | sed 's/^/    /'
fi

# A folder holding nothing but its template does not take the domain. That
# is the shape a finished translation leaves behind, and sorted-first alone
# would hand it the vault deterministically.
DUP_C="$DUP_TMP/c/00_documentation/01_projectvault"
dup_vault "$DUP_C" de-first stub
dup_c=$(python3 "$VALIDATOR" "$DUP_C" 2>&1 | sed "s|$DUP_TMP/c||g")
TESTS=$((TESTS + 1))
if contains "$dup_c" "'03_architecture_(ARC)' is the one this vault reads" \
   && contains "$dup_c" "domain-duplicate-folder"; then
  ok x; else fail "a template-only folder must not take the domain from the one holding it:"
  printf '%s\n' "$dup_c" | grep domain-duplicate | sed 's/^/    /'
fi

# A compatibility symlink left behind by a rename is ONE directory, and
# telling the author to remove a folder that does not exist is worse than
# saying nothing. is_dir() follows the link; rglob does not descend it.
DUP_D="$DUP_TMP/d/00_documentation/01_projectvault"
mkdir -p "$DUP_D/01_requirements_(REQ)" "$DUP_D/02_decisions_(DEC)"
printf '## Context\n' > "$DUP_D/01_requirements_(REQ)/00_REQ_file_template.md"
printf '## Context\n' > "$DUP_D/02_decisions_(DEC)/00_DEC_file_template.md"
dup_arc_en "$DUP_D"
ln -s "03_architecture_(ARC)" "$DUP_D/03_Architektur_(ARC)"
dup_d=$(python3 "$VALIDATOR" "$DUP_D" 2>&1)
TESTS=$((TESTS + 1))
if ! contains "$dup_d" "domain-duplicate-folder"; then ok x; else
  fail "a symlink to a domain folder is not a second folder:"
  printf '%s\n' "$dup_d" | grep domain-duplicate | sed 's/^/    /'
fi

# The counter-assertion: a vault with one folder per domain says none of it.
TESTS=$((TESTS + 1))
if ! contains "$(python3 "$VALIDATOR" "$V" 2>&1)" "domain-duplicate-folder"; then
  ok x; else fail "a vault with one folder per domain must carry no duplicate-folder finding"; fi

# ==========================================================================
# Fixture 9: --check-install. The entry under ~/.claude/skills is the only
# piece of this skill that lives outside the repository, and a symlink there
# carries a path rather than an identity: replicate it across hosts and it
# is valid only where it was written (issue #40). The failure is silent -
# the entry stays in the skill listing and only the invocation fails - so
# what is asserted here is that each shape says which shape it is.
#
# HOME is moved per command with env, never globally: the suite neutralises
# git the same way and deliberately leaves HOME alone, because a global
# override would change python's user site and git's identity for every
# test after it. It also keeps the real ~/.claude out of the suite, which
# on a CI runner does not exist at all.
#
# The trap lists every fixture directory: bash replaces the handler rather
# than adding to it, so the last one written is the only one that runs.
# ==========================================================================
CI_TMP=$(mktemp -d)
trap 'rm -rf "$TMP" "$DE_TMP" "$EN_TMP" "$ID_TMP" "$SC_TMP" "$PF_TMP" \
      "$CAP_TMP" "$EX_TMP" "$DUP_TMP" "$CI_TMP"' EXIT

# Sets ci_out/ci_rc in the caller - a command substitution would run the
# assignment in a subshell and lose the exit code.
ci() { ci_out=$(env HOME="$1" python3 "$VALIDATOR" --check-install 2>&1); ci_rc=$?; }

# No entry at all. Legitimate: the template ships the skill inside the
# project, where nothing has to be installed. Not a defect.
CI_A="$CI_TMP/a"; mkdir -p "$CI_A/.claude/skills"
ci "$CI_A"
TESTS=$((TESTS + 1))
if [ $ci_rc -eq 0 ] && contains "$ci_out" "absent"; then ok x; else
  fail "a missing personal entry is a setup, not a defect:"
  printf '%s\n' "$ci_out" | sed 's/^/    /'
fi

# The entry reaches this copy.
CI_B="$CI_TMP/b"; mkdir -p "$CI_B/.claude/skills"
ln -s "$SKILL_DIR" "$CI_B/.claude/skills/mechatronics-docs"
ci "$CI_B"
TESTS=$((TESTS + 1))
if [ $ci_rc -eq 0 ] && contains "$ci_out" "OK - the entry reaches this copy"; then
  ok x; else fail "a correct entry must pass:"
  printf '%s\n' "$ci_out" | sed 's/^/    /'
fi

# Issue #40 itself: the link carries a path this host does not have. The
# stored path must appear - it is what names the host that wrote it.
CI_C="$CI_TMP/c"; mkdir -p "$CI_C/.claude/skills"
ln -s "/nonexistent-host-path/obsidian-engineering-vault/.claude/skills/mechatronics-docs" \
      "$CI_C/.claude/skills/mechatronics-docs"
ci "$CI_C"
TESTS=$((TESTS + 1))
if [ $ci_rc -eq 1 ] && contains "$ci_out" "DANGLING" \
   && contains "$ci_out" "/nonexistent-host-path/"; then ok x; else
  fail "a dangling entry must fail and name the path it stored:"
  printf '%s\n' "$ci_out" | sed 's/^/    /'
fi

# ... and it is dangling, not a mismatch. -e is false for a dangling link,
# so a check that asks about existence before it asks about linkhood
# reports the wrong shape, or says nothing at all.
TESTS=$((TESTS + 1))
if ! contains "$ci_out" "MISMATCH"; then ok x; else
  fail "a dangling entry is not a mismatch:"
  printf '%s\n' "$ci_out" | sed 's/^/    /'
fi

# The link resolves, but to a second copy of the skill. Readability alone
# calls this green, and the session then runs a version nobody is editing.
CI_D="$CI_TMP/d"; mkdir -p "$CI_D/.claude/skills" "$CI_TMP/other-clone"
printf -- '---\nname: mechatronics-docs\n---\n' > "$CI_TMP/other-clone/SKILL.md"
ln -s "$CI_TMP/other-clone" "$CI_D/.claude/skills/mechatronics-docs"
ci "$CI_D"
TESTS=$((TESTS + 1))
if [ $ci_rc -eq 1 ] && contains "$ci_out" "MISMATCH" \
   && contains "$ci_out" "other-clone"; then ok x; else
  fail "an entry reaching a different copy must fail and name it:"
  printf '%s\n' "$ci_out" | sed 's/^/    /'
fi

# A real directory instead of a link - the shape that syncing the skill's
# content rather than a link to it produces on every peer.
CI_E="$CI_TMP/e"; mkdir -p "$CI_E/.claude/skills/mechatronics-docs"
printf -- '---\nname: mechatronics-docs\n---\n' \
  > "$CI_E/.claude/skills/mechatronics-docs/SKILL.md"
ci "$CI_E"
TESTS=$((TESTS + 1))
if [ $ci_rc -eq 1 ] && contains "$ci_out" "MISMATCH"; then ok x; else
  fail "a real directory in place of the entry must fail:"
  printf '%s\n' "$ci_out" | sed 's/^/    /'
fi

rm -f "/tmp/claude-mechdocs/touched-$SID" "/tmp/claude-mechdocs/baseline-$SID" \
      "/tmp/claude-mechdocs/blocks-$SID"

# ==========================================================================
# Fixture 10: coverage vault - what counts as coverage and what only looks
# like it (issue #50). Until then 'req-uncovered' was 'rid in text' over
# whole ARC and TAE files, so every shape below except the first passed as
# proof: the identifier appeared somewhere, and nothing asked in what role.
#
# The templates carry TABLES, unlike the precision vault's. That is not
# decoration: the allocation half of the rule is read from the section the
# project's OWN ARC template declares, and a template without tables binds
# nothing - which is exactly the second variant below, asserted rather than
# assumed.
#
# Every must-not-count row is paired with a grep against the fixture: an
# assertion that a finding EXISTS proves nothing about the old rule unless
# the identifier really is written in an ARC or TAE file, which is what the
# old rule would have accepted.
# ==========================================================================
CV_TMP=$(mktemp -d)
trap 'rm -rf "$TMP" "$DE_TMP" "$EN_TMP" "$ID_TMP" "$SC_TMP" "$PF_TMP" \
      "$CAP_TMP" "$EX_TMP" "$DUP_TMP" "$CI_TMP" "$CV_TMP"' EXIT

build_coverage_vault() { # build_coverage_vault <vault_dir>
  local C="$1"
  mkdir -p "$C/01_requirements_(REQ)" "$C/03_architecture_(ARC)" \
           "$C/07_testing_and_evidence_(TAE)"

  {
    printf '## Context\n\n'
    printf '| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n'
    printf '| --- | --: | --- | --- | --- |\n'
    printf '|  |  |  |  |  |\n'
  } > "$C/01_requirements_(REQ)/00_REQ_file_template.md"

  {
    printf '## Context\n\n'
    printf '## Allocation and Verification\n'
    printf '| Submodule (ARC/CMP/IFC) | Allocated Requirements (REQ-IDs) | Verification (TAE) | Status |\n'
    printf '| --- | --- | --- | --- |\n'
    printf '|  |  |  | Draft |\n'
  } > "$C/03_architecture_(ARC)/00_ARC_file_template.md"

  printf '## Context\n' > "$C/07_testing_and_evidence_(TAE)/00_TAE_file_template.md"

  # 001 closed loop; 002-004 mentioned only; 005 allocated only; 006
  # verified only; 007 closed loop in a table under a heading of this
  # file's own making, which the graph does not carry at all.
  {
    printf -- '---\ndomain: REQ\nstatus: active\ncreated: 2026-08-05\nlast-verified: 2026-08-05\n---\n'
    printf '## Context\nRequirements of the coverage example.\n\n'
    printf '| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n'
    printf '| --- | --: | --- | --- | --- |\n'
    printf '| M | 001 | allocated and verified | pass if both hold | none |\n'
    printf '| M | 002 | named in architecture prose | pass if measured | none |\n'
    printf '| M | 003 | named in a heading | pass if measured | none |\n'
    printf '| M | 004 | named in evidence prose | pass if measured | none |\n'
    printf '| M | 005 | allocated, never verified | pass if measured | none |\n'
    printf '| M | 006 | verified, never allocated | pass if measured | none |\n\n'
    printf '## Detached layer\n'
    printf '| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n'
    printf '| --- | --: | --- | --- | --- |\n'
    printf '| M | 007 | closed loop outside the bound section | pass if silent | none |\n'
  } > "$C/01_requirements_(REQ)/REQ_Coverage (COV).md"

  {
    printf -- '---\ndomain: ARC\nstatus: active\ncreated: 2026-08-05\nlast-verified: 2026-08-05\n---\n'
    printf '## Context\n'
    printf 'The module under coverage. REQ-COV-002 was dropped from this\n'
    printf 'module and is named here for that reason alone.\n\n'
    printf '### REQ-COV-003 is still open\n'
    printf 'A heading naming a requirement is a table of contents entry.\n\n'
    printf '## Allocation and Verification\n'
    printf '| Submodule (ARC/CMP/IFC) | Allocated Requirements (REQ-IDs) | Verification (TAE) | Status |\n'
    printf '| --- | --- | --- | --- |\n'
    printf '| acquisition path | REQ-COV-001 | [[TAE_Coverage]] | Verified |\n'
    printf '| supply path | REQ-COV-005 | measured during bring-up | Draft |\n'
  } > "$C/03_architecture_(ARC)/ARC_Coverage.md"

  {
    printf -- '---\ndomain: TAE\nstatus: active\ncreated: 2026-08-05\nlast-verified: 2026-08-05\n'
    printf 'verifies: [REQ-COV-001, REQ-COV-006, REQ-COV-007]\n---\n'
    printf '## Context\n'
    printf 'Evidence for the coverage example. REQ-COV-004 is named here as an\n'
    printf 'open point and is not among the requirements this note verifies.\n'
  } > "$C/07_testing_and_evidence_(TAE)/TAE_Coverage.md"
}

CV="$CV_TMP/Covproj/00_documentation/01_projectvault"
build_coverage_vault "$CV"

# The fixture only proves something if the identifiers really are written
# where the old rule looked.
TESTS=$((TESTS + 1))
if grep -q "REQ-COV-002" "$CV/03_architecture_(ARC)/ARC_Coverage.md" && \
   grep -q "^### REQ-COV-003" "$CV/03_architecture_(ARC)/ARC_Coverage.md" && \
   grep -q "REQ-COV-004" "$CV/07_testing_and_evidence_(TAE)/TAE_Coverage.md"; then
  ok x; else fail "the must-not-count identifiers are not in the fixture at all"; fi

cv_out=$(python3 "$VALIDATOR" "$CV" 2>&1)
uncovered() { contains "$cv_out" "\[req-uncovered\] $1"; }

# The closed loop: silent. Paired with the five below, so a check that
# stopped running cannot pass as a pass.
TESTS=$((TESTS + 1))
if ! uncovered "REQ-COV-001"; then ok x; else
  fail "an allocated and verified requirement must not be reported:"
  printf '%s\n' "$cv_out" | grep "REQ-COV-001" | sed 's/^/    /'; fi

for rid in 002 003 004 005 006; do
  TESTS=$((TESTS + 1))
  if uncovered "REQ-COV-$rid"; then ok x; else
    fail "REQ-COV-$rid must be reported as uncovered"; fi
done

# The finding has to name which half of the loop is missing, or it cannot
# be acted on. Three shapes, three sentences.
TESTS=$((TESTS + 1))
if contains "$cv_out" "\[req-uncovered\] REQ-COV-002 has no allocation row naming it and no TAE"; then
  ok x; else fail "a mention-only requirement must be reported as missing BOTH halves"; fi
TESTS=$((TESTS + 1))
if contains "$cv_out" "\[req-uncovered\] REQ-COV-005 is named by no TAE in 'verifies'"; then
  ok x; else fail "an allocated requirement must be reported as missing the evidence half"; fi
TESTS=$((TESTS + 1))
if contains "$cv_out" "\[req-uncovered\] REQ-COV-006 is verified by TAE_Coverage but no allocation row"; then
  ok x; else fail "a verified requirement must be reported as missing the allocation half"; fi

# A requirement row the graph does not carry - here one under a heading of
# the file's own making, the shape REQ_Loose (LSE) is built for above and
# the one nativclaw carries seven times. Its loop IS closed; only the
# exporter cannot see the row. Holding the allocation half against it would
# report a correct requirement as a gap.
TESTS=$((TESTS + 1))
if ! uncovered "REQ-COV-007"; then ok x; else
  fail "a requirement outside the bound section must not lose its coverage:"
  printf '%s\n' "$cv_out" | grep "REQ-COV-007" | sed 's/^/    /'; fi

# Coverage never blocks: these are vault-wide WARNs and the vault carries
# no ERROR, so the audit exits 0.
TESTS=$((TESTS + 1))
if [ -z "$(printf '%s' "$cv_out" | grep '^ERROR')" ]; then ok x; else
  fail "the coverage fixture must carry no ERROR:"
  printf '%s\n' "$cv_out" | grep '^ERROR' | sed 's/^/    /'; fi

# (b) A project whose own ARC template declares no allocation table. No row
# can be read, so the allocation half falls silent and the verification
# half alone decides - REQ-COV-006 stops being a finding, the four that
# nothing verifies stay findings. The degradation is asserted, not assumed:
# it is the difference between a check that lost reach and one that lost
# its voice.
CV_B="$CV_TMP/NoAlloc/00_documentation/01_projectvault"
build_coverage_vault "$CV_B"
printf '## Context\n\n## Allocation and Verification\n' \
  > "$CV_B/03_architecture_(ARC)/00_ARC_file_template.md"
cvb_out=$(python3 "$VALIDATOR" "$CV_B" 2>&1)
TESTS=$((TESTS + 1))
if ! contains "$cvb_out" "\[req-uncovered\] REQ-COV-006"; then ok x; else
  fail "without an allocation binding the allocation half must not be held against a REQ"; fi
TESTS=$((TESTS + 1))
if contains "$cvb_out" "\[req-uncovered\] REQ-COV-002" && \
   contains "$cvb_out" "\[req-uncovered\] REQ-COV-005"; then ok x; else
  fail "without an allocation binding the verification half must still be enforced"; fi

# (c) The exporter missing beside the validator - what a project that
# vendored one file has, and what the schema fixtures above build twice.
# The graph cannot be built at all; the rule keeps its verification half
# and the run must not exit 2, which is the code both hooks fail open on.
mkdir -p "$CV_TMP/noexp"
cp "$VALIDATOR" "$SKILL_DIR/vault_schema.json" "$CV_TMP/noexp/"
cve_out=$(python3 "$CV_TMP/noexp/validate_vault.py" "$CV" 2>&1); cve_rc=$?
TESTS=$((TESTS + 1))
if [ $cve_rc -ne 2 ]; then ok x; else
  fail "a missing exporter must not crash the validator"; fi
TESTS=$((TESTS + 1))
if contains "$cve_out" "\[req-uncovered\] REQ-COV-002" && \
   ! contains "$cve_out" "\[req-uncovered\] REQ-COV-006"; then ok x; else
  fail "without the exporter the verification half must still decide alone"; fi

# (d) A vault mid-translation: the requirements folder exists twice, and
# 'ANF' sorts before 'REQ', so the role map gives the REQ role to the
# German folder and excludes the English one - for BOTH tools, because the
# validator's index follows the same derivation since issue #66. The
# English rows leave the coverage path together with the role, so a state
# this project explicitly supports must not turn into a vault-wide sweep
# of findings on correct requirements; the handoff itself stays visible as
# the exporter's export-duplicate-role finding. The issue #66 block at the
# end of this file pins both halves of that statement.
CV_D="$CV_TMP/Trans/00_documentation/01_projectvault"
build_coverage_vault "$CV_D"
mkdir -p "$CV_D/01_Anforderungen_(ANF)"
cp "$CV_D/01_requirements_(REQ)/00_REQ_file_template.md" \
   "$CV_D/01_Anforderungen_(ANF)/00_ANF_Dateitemplate.md"
{
  printf -- '---\ndomain: ANF\nstatus: active\ncreated: 2026-08-05\nlast-verified: 2026-08-05\n---\n'
  printf '## Context\nDie uebersetzte Zwillingsdatei der Anforderungen.\n\n'
  printf '| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source |\n'
  printf '| --- | --: | --- | --- | --- |\n'
  printf '| M | 001 | uebersetzte Anforderung | pass if measured | none |\n'
} > "$CV_D/01_Anforderungen_(ANF)/ANF_Abdeckung (COV).md"
cvd_out=$(python3 "$VALIDATOR" "$CV_D" 2>&1); cvd_rc=$?
TESTS=$((TESTS + 1))
if [ $cvd_rc -ne 2 ]; then ok x; else
  fail "a vault carrying two requirement folders must not crash the validator"; fi
TESTS=$((TESTS + 1))
if ! contains "$cvd_out" "\[req-uncovered\] REQ-COV-001"; then ok x; else
  fail "a mid-translation vault must not lose the coverage of a closed loop:"
  printf '%s\n' "$cvd_out" | grep "REQ-COV-001" | sed 's/^/    /'; fi

# (e) The two tools must be ONE pair of modules even when the validator is
# the script. Run as one it lives in sys.modules as '__main__', and the
# exporter's own 'from validate_vault import ...' would load a second copy:
# two Vault classes, two schema caches, and the identity asserted between
# the tools above quietly false. The parity test there imports both
# normally and cannot see this at all.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" "$CV" <<'PY'
import contextlib, importlib.util, io, sys
from pathlib import Path
skill, vault_root = sys.argv[1], sys.argv[2]
sys.path.insert(0, skill)
spec = importlib.util.spec_from_file_location("__main__", skill + "/validate_vault.py")
mod = importlib.util.module_from_spec(spec)
sys.modules["__main__"] = mod
sys.argv = ["validate_vault.py", "--check-install"]
buf = io.StringIO()
try:
    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
        spec.loader.exec_module(mod)   # the CLI guard runs, as in a real script run
except SystemExit:
    pass
assert "validate_vault" not in sys.modules, "precondition: nothing has imported it yet"
alloc = mod.allocation_index(mod.Vault(Path(vault_root)))
# Every requirement the graph CARRIES, with the allocation question
# answered - and REQ-COV-007, whose row sits outside the bound section,
# absent rather than answered False. That distinction is the whole reason
# the index returns three states instead of two.
assert alloc == {"REQ-COV-001": True, "REQ-COV-002": False, "REQ-COV-003": False,
                 "REQ-COV-004": False, "REQ-COV-005": True,
                 "REQ-COV-006": False}, alloc
import export_traceability as ex
assert ex.Vault is mod.Vault, "the exporter bound a second copy of validate_vault"
assert ex.split_cells is mod.split_cells, "the two tools do not share one reader"
PY
then ok x; else fail "a script-mode validator must not load the exporter against a second copy of itself"; fi

# ==========================================================================
# Issue #67: assess reads the reverse key reverse_index derives from the
# schema - one derivation, so a schema rename cannot silently falsify the
# coverage report. A/B like fixture 5, but BOTH tools are copied beside the
# patched schema: the exporter imports the validate_vault.py at sys.path[0]
# and that copy resolves SCHEMA_PATH beside itself, so copying the
# validator alone would leave the shipped exporter reading the shipped
# schema and every assertion below would test nothing. EN_V, EN_OUT and CV
# are in their baseline states here (every mutation above is reverted),
# and everything below writes only into fresh directories.
# ==========================================================================
rk_patch() { # rk_patch <dir under EX_TMP> <one-line python patch of dict 's'>
  mkdir -p "$EX_TMP/$1"
  cp "$EXPORTER" "$VALIDATOR" "$EX_TMP/$1/"
  python3 - "$SKILL_DIR/vault_schema.json" "$EX_TMP/$1/vault_schema.json" "$2" <<'PY'
import json, sys
s = json.load(open(sys.argv[1]))
exec(sys.argv[3])
json.dump(s, open(sys.argv[2], "w"))
PY
}

# (a) reverse_key renamed: the edges move to the new name and the coverage
# report does not notice - the exact report a rename used to falsify.
rk_patch "sc-renamed" 's["relations"]["verifies"]["reverse_key"] = "proven_by"'
rn_out=$(python3 "$EX_TMP/sc-renamed/export_traceability.py" "$EN_V" \
  --output-dir "$EX_TMP/out-renamed" --no-timestamp 2>&1); rn_rc=$?
TESTS=$((TESTS + 1))
if [ $rn_rc -eq 0 ]; then ok x; else
  fail "a renamed reverse key must not break the export, got $rn_rc: $rn_out"; fi
TESTS=$((TESTS + 1))
if python3 - "$EX_TMP/out-renamed/traceability.json" "$EN_OUT/traceability.json" <<'PY'
import json, sys
ren = json.load(open(sys.argv[1])); base = json.load(open(sys.argv[2]))
assert sorted(ren["reverse"]["REQ-EXP-001"]["proven_by"]) == ["TAE:TAE_Export"], \
    ren["reverse"]["REQ-EXP-001"]
assert "verifies_back" not in ren["reverse"]["REQ-EXP-001"]
assert ren["coverage"] == base["coverage"], "coverage drifted under a renamed key"
PY
then ok x; else
  fail "a renamed reverse key must move the edges and leave the coverage identical"; fi

# (b) the whole relations block deleted: the minimal-schema path, which is
# also what FALLBACK_SCHEMA looks like - every kind falls back to
# '<kind>_back' and the coverage stays correct. Only the coverage is
# compared: deleting the block also empties the contains/test-object
# domain gates, so edges and findings legitimately change with it.
rk_patch "sc-norels" 'del s["relations"]'
nr_out=$(python3 "$EX_TMP/sc-norels/export_traceability.py" "$EN_V" \
  --output-dir "$EX_TMP/out-norels" --no-timestamp 2>&1); nr_rc=$?
TESTS=$((TESTS + 1))
if [ $nr_rc -eq 0 ]; then ok x; else
  fail "a schema without a relations block must fall back, got $nr_rc: $nr_out"; fi
TESTS=$((TESTS + 1))
if python3 - "$EX_TMP/out-norels/traceability.json" "$EN_OUT/traceability.json" <<'PY'
import json, sys
nor = json.load(open(sys.argv[1])); base = json.load(open(sys.argv[2]))
assert sorted(nor["reverse"]["REQ-EXP-001"]["verifies_back"]) == ["TAE:TAE_Export"]
assert nor["coverage"] == base["coverage"], "coverage drifted without a relations block"
PY
then ok x; else
  fail "without a relations block the '<kind>_back' convention must keep the coverage"; fi

# (c) relations present but the verifies entry deleted: the coverage report
# is defined on that relation, so the export is refused rather than built
# on a vocabulary nobody declared. mkdir runs before analyse, so the empty
# output directory exists - the artifact must not.
rk_patch "sc-dropped" 'del s["relations"]["verifies"]'
dr_out=$(python3 "$EX_TMP/sc-dropped/export_traceability.py" "$EN_V" \
  --output-dir "$EX_TMP/out-dropped" --no-timestamp 2>&1); dr_rc=$?
TESTS=$((TESTS + 1))
if [ $dr_rc -eq 2 ]; then ok x; else
  fail "a relations block without verifies must be refused with exit 2, got $dr_rc"; fi
TESTS=$((TESTS + 1))
if contains "$dr_out" "relations.verifies"; then ok x; else
  fail "the refusal must name relations.verifies, got: $dr_out"; fi
TESTS=$((TESTS + 1))
if [ ! -f "$EX_TMP/out-dropped/traceability.json" ]; then ok x; else
  fail "a refused export must not leave a traceability.json behind"; fi

# (d) a reverse_key that is declared but unusable: the old inline fallback
# silently overrode '' and null; a declared value is refused, not guessed.
rk_patch "sc-junk" 's["relations"]["verifies"]["reverse_key"] = ""'
jk_out=$(python3 "$EX_TMP/sc-junk/export_traceability.py" "$EN_V" \
  --output-dir "$EX_TMP/out-junk" --no-timestamp 2>&1); jk_rc=$?
TESTS=$((TESTS + 1))
if [ $jk_rc -eq 2 ]; then ok x; else
  fail "an empty reverse_key must be refused with exit 2, got $jk_rc"; fi
TESTS=$((TESTS + 1))
if contains "$jk_out" "relations.verifies.reverse_key"; then ok x; else
  fail "the refusal must name relations.verifies.reverse_key, got: $jk_out"; fi

# (f) the validator beside the refused schema: a fourth 'cannot say' state
# beside the three of fixture 10. The refusal must degrade the allocation
# half of req-uncovered, never crash the run - exit 2 is the code both
# hooks fail open on. Verification half still decides (REQ-COV-002);
# allocation half is not held against a REQ it cannot see (REQ-COV-006).
cvf_out=$(python3 "$EX_TMP/sc-dropped/validate_vault.py" "$CV" 2>&1); cvf_rc=$?
TESTS=$((TESTS + 1))
if [ $cvf_rc -ne 2 ]; then ok x; else
  fail "a refused schema must not crash the validator"; fi
TESTS=$((TESTS + 1))
if contains "$cvf_out" "\[req-uncovered\] REQ-COV-002" && \
   ! contains "$cvf_out" "\[req-uncovered\] REQ-COV-006"; then ok x; else
  fail "under a refused schema the verification half must still decide alone"; fi
# Issue #66: the coverage checks fire in translated vaults. Fixture 3's
# twin pair carries a requirements and an evidence domain since this
# issue; the multiset parity there already holds both twins to one set of
# finding codes, and the assertions here pin the German spellings - the
# codes must fire with the vault's OWN requirement prefix, which is what
# domain_aliases.requirement_id_prefix promises.
# ==========================================================================
TW_DE="$DE_TMP/Deproj/00_Dokumentation/01_Projektvault"
TW_EN="$EN_TMP/Enproj/00_documentation/01_projectvault"
de66_out=$(python3 "$VALIDATOR" "$TW_DE" 2>&1)
en66_out=$(python3 "$VALIDATOR" "$TW_EN" 2>&1)

TESTS=$((TESTS + 1))
if contains "$de66_out" "\[verifies-unknown-req\] ANF-MES-999 is not defined in any ANF file"; then ok x; else
  fail "a dangling 'verifies' id in a German vault must be reported with its own prefix:"
  printf '%s\n' "$de66_out" | grep -i "verifies" | sed 's/^/    /'; fi
TESTS=$((TESTS + 1))
if contains "$de66_out" "\[req-uncovered\] ANF-MES-002"; then ok x; else
  fail "an unverified requirement in a German vault must be reported as uncovered:"
  printf '%s\n' "$de66_out" | grep "ANF-MES" | sed 's/^/    /'; fi
TESTS=$((TESTS + 1))
if contains "$de66_out" "\[req-duplicate-global\].*ANF-MES-001"; then ok x; else
  fail "a requirement number defined in two German files must be reported"; fi
# The verified row stays silent - a check that fires on everything would
# also satisfy the three assertions above.
TESTS=$((TESTS + 1))
if ! contains "$de66_out" "\[req-uncovered\] ANF-MES-001"; then ok x; else
  fail "a verified requirement must not be reported as uncovered"; fi
# The English twin fires the same three codes under its own prefix; the
# fixture 3 multiset assertion compares the whole runs code by code.
TESTS=$((TESTS + 1))
if contains "$en66_out" "\[verifies-unknown-req\] REQ-MES-999" && \
   contains "$en66_out" "\[req-uncovered\] REQ-MES-002" && \
   contains "$en66_out" "\[req-duplicate-global\].*REQ-MES-001"; then ok x; else
  fail "the English twin must fire the same three codes under its own prefix"; fi

# Fixture 10(d) revisited: the validator's index follows the role map the
# graph is built from, so the mid-translation vault's requirements are the
# German folder's rows for both tools. The German row - verified by
# nothing the vault contains - is reported; the English rows left the
# index together with the role, so their old findings are gone. The
# handoff itself is the exporter's export-duplicate-role finding, and the
# absence asserted in fixture 10(d) still holds beside these.
TESTS=$((TESTS + 1))
if contains "$cvd_out" "\[req-uncovered\] ANF-COV-001"; then ok x; else
  fail "the mid-translation vault's own German row must be reported as uncovered:"
  printf '%s\n' "$cvd_out" | grep "ANF-COV" | sed 's/^/    /'; fi
TESTS=$((TESTS + 1))
if ! contains "$cvd_out" "\[req-uncovered\] REQ-COV-002"; then ok x; else
  fail "English rows of a mid-translation vault leave the coverage path with the role"; fi

# The fallback must not switch the role map off silently: FALLBACK_SCHEMA
# carries the alias map since issue #66, pinned against the packaged
# schema the same way the field profiles are pinned above.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import validate_vault as vv
from pathlib import Path
real, err = vv.load_schema(Path(sys.argv[1]) / "vault_schema.json")
assert err is None, err
assert real["domain_aliases"]["map"] == vv.FALLBACK_SCHEMA["domain_aliases"]["map"], \
    "alias map drift between vault_schema.json and FALLBACK_SCHEMA"
assert real["domain_aliases"]["identity"] == vv.FALLBACK_SCHEMA["domain_aliases"]["identity"], \
    "identity list drift between vault_schema.json and FALLBACK_SCHEMA"
PY
then ok x; else fail "FALLBACK_SCHEMA domain_aliases and vault_schema.json have drifted apart"; fi

# One derivation, two readers: the roles the exporter resolves for the
# German twin must be exactly what Vault.roles() says - and the German
# folders must actually hold the English role tokens.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" "$TW_DE" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import validate_vault as vv, export_traceability as ex
from pathlib import Path
v = vv.Vault(Path(sys.argv[2]))
assert ex.resolve_roles(v, v.schema(), []) == v.roles(), \
    "the two tools derive different role maps"
assert v.roles().get("REQ") == "ANF" and v.roles().get("TAE") == "TUE", v.roles()
PY
then ok x; else fail "validator and exporter must share one role derivation"; fi
# BEGIN tools/new_project.py - template derivation (issues #76 / #85).
# One self-contained block, appended last on purpose: concurrent branches
# append here too, and a fixed position at the end keeps the merges clean.
# Loud-fail guard like REAL_VAULT above: run through a symlinked skill in a
# project that has no derivation script, the block must say so, not skip.
# ==========================================================================
NP_ROOT="$(cd -P -- "$SKILL_DIR/../../.." && pwd -P)"
NP="$NP_ROOT/tools/new_project.py"
TESTS=$((TESTS + 1))
if [ -f "$NP" ]; then ok x; else fail "derivation script not found at $NP"; fi
if [ -f "$NP" ]; then
  NP_TMP=$(mktemp -d)
  ND="$NP_TMP/myproj"
  npout=$(python3 "$NP" "$ND" 2>&1); nprc=$?
  TESTS=$((TESTS + 1))
  if [ $nprc -eq 0 ]; then ok x; else
    fail "default derivation must exit 0, got $nprc:"
    printf '%s\n' "$npout" | tail -5 | sed 's/^/    /'
  fi

  # Exit 0 is not the whole signal. The script's own warnings - a REPLACEMENTS
  # or CUTS anchor whose text moved, a strip path that no longer exists - are
  # printed under a "WARNINGS" heading and then dropped: the success predicate
  # reads the VALIDATOR's warning count, not len(warnings). So a stale anchor
  # derives a project with template-only prose still in it, at exit 0, green.
  # This assertion is what pins every anchor the script carries, which the
  # comment above REPLACEMENTS claimed and nothing enforced (DEC-MTH-042).
  TESTS=$((TESTS + 1))
  if contains "$npout" "WARNINGS"; then
    fail "derivation printed warnings - an anchor or strip path went stale:"
    printf '%s\n' "$npout" | sed -n '/WARNINGS/,/^$/p' | sed 's/^/    /'
  else ok x; fi

  # Template-repo-only material and the worked example must be gone; the
  # method's tooling and the files STRUCTURE.md says travel must remain.
  for gone in "CONTRIBUTING.md" "CHANGELOG.md" "TUTORIAL.md" "tools" ".claude/01_methodvault" \
      ".github/ISSUE_TEMPLATE" ".github/pull_request_template.md" \
      ".claude/skills/mechatronics-docs/tests" "20_software/data_analysis" \
      "30_testdata/31_testdata_raw/2026-07-28_battery_monitoring" \
      "30_testdata/32_testdata_processed/2026-07-28_battery_monitoring" \
      "00_documentation/01_projectvault/03_architecture_(ARC)/ARC_Battery_Monitoring.md" \
      "00_documentation/01_projectvault/05_interfaces_(IFC)/IFC_PWR_DC_LiPo_Pack.md"; do
    TESTS=$((TESTS + 1))
    if [ ! -e "$ND/$gone" ]; then ok x; else fail "derived project still carries $gone"; fi
  done
  for kept in ".claude/skills/mechatronics-docs/validate_vault.py" \
      ".claude/skills/mechatronics-docs/export_traceability.py" \
      ".claude/skills/mechatronics-docs/hooks/stop_gate.sh" \
      ".claude/skills/mechatronics-docs/DECISIONS.md" \
      ".claude/skills/mechatronics-docs/SKILL.md" \
      ".claude/skills/mechatronics-docs/ARCHITECTURE.md" \
      ".github/workflows/validate-vault.yml" "IEC_61508_MAPPING.md" \
      "AGENTS.md" "CLAUDE.md" "STRUCTURE.md" "METHOD.md" "LICENSE" \
      "00_documentation/.obsidian/app.json"; do
    TESTS=$((TESTS + 1))
    if [ -e "$ND/$kept" ]; then ok x; else fail "derived project lost $kept"; fi
  done

  # METHOD.md ships because it argues the method a derived project inherits,
  # not the template (DEC-MTH-042). Two things have to hold for that: it may
  # carry no prose about stripped material, and something in the project has
  # to link it - a file nothing points at is left behind, not shipped.
  TESTS=$((TESTS + 1))
  if grep -q "tests/run.sh" "$ND/METHOD.md"; then
    fail "derived METHOD.md still points at the stripped test suite"; else ok x; fi
  TESTS=$((TESTS + 1))
  if grep -q "METHOD.md" "$ND/README.md" && grep -q "METHOD.md" "$ND/STRUCTURE.md"; then
    ok x; else fail "derived README.md and STRUCTURE.md must both name METHOD.md"; fi

  # The derived workflow is the #85 fix: no template self-test, no worked
  # example, but the vault audit still named by path.
  npwf=$(cat "$ND/.github/workflows/validate-vault.yml" 2>/dev/null)
  TESTS=$((TESTS + 1))
  if contains "$npwf" "eval_battery_log" || contains "$npwf" "tests/run.sh" \
      || contains "$npwf" "01_methodvault"; then
    fail "derived workflow still runs template-only steps"; else ok x; fi
  TESTS=$((TESTS + 1))
  if contains "$npwf" "validate_vault.py 00_documentation/01_projectvault"; then
    ok x; else fail "derived workflow lost the project vault audit"; fi

  # No prose in the derived tree may still point at the worked example or
  # the method vault - the leftover-link defect of issue #70.
  TESTS=$((TESTS + 1))
  if grep -rq "ARC_Battery_Monitoring" "$ND/00_documentation"; then
    fail "worked-example reference survives in the derived vault"; else ok x; fi
  TESTS=$((TESTS + 1))
  if grep -q "01_methodvault" "$ND/CLAUDE.md" "$ND/STRUCTURE.md" "$ND/.gitignore"; then
    fail "method-vault reference survives in CLAUDE.md/STRUCTURE.md/.gitignore"; else ok x; fi
  TESTS=$((TESTS + 1))
  if grep -q "new_project" "$ND/STRUCTURE.md" "$ND/README.md"; then
    fail "derivation-script reference survives in STRUCTURE.md/README.md"; else ok x; fi

  # The generated README carries the target's name and, on the default
  # path, the explanation of the one WARN the validator will keep showing.
  TESTS=$((TESTS + 1))
  if [ "$(head -n 1 "$ND/README.md")" = "# myproj" ]; then ok x; else
    fail "generated README must open with '# myproj'"; fi
  TESTS=$((TESTS + 1))
  if grep -q "duplicate-basename" "$ND/README.md"; then ok x; else
    fail "default derivation must explain the duplicate-basename WARN in README.md"; fi

  # The state the script predicts is the state the validator reports.
  npval=$(python3 "$ND/.claude/skills/mechatronics-docs/validate_vault.py" \
    "$ND/00_documentation/01_projectvault" 2>&1); npvrc=$?
  TESTS=$((TESTS + 1))
  if [ $npvrc -eq 0 ] && contains "$npval" "0 error(s), 1 warning(s)" \
      && contains "$npval" "duplicate-basename"; then ok x; else
    fail "derived vault must report exactly the known WARN:"
    printf '%s\n' "$npval" | sed 's/^/    /'
  fi

  # --rename-docs-readme resolves the collision: renamed file, patched
  # STRUCTURE.md reference, zero warnings, --name in the README.
  np2out=$(python3 "$NP" "$NP_TMP/renamed" --rename-docs-readme \
    --name "Renamed Proj" 2>&1); np2rc=$?
  TESTS=$((TESTS + 1))
  if [ $np2rc -eq 0 ]; then ok x; else fail "rename derivation must exit 0, got $np2rc"; fi
  TESTS=$((TESTS + 1))
  if [ -f "$NP_TMP/renamed/00_documentation/02_documents/00_documents_README.md" ] \
      && [ ! -e "$NP_TMP/renamed/00_documentation/02_documents/README.md" ]; then
    ok x; else fail "rename flag must rename the documents README"; fi
  TESTS=$((TESTS + 1))
  if grep -q "02_documents/00_documents_README.md" "$NP_TMP/renamed/STRUCTURE.md"; then
    ok x; else fail "STRUCTURE.md must point at the renamed README"; fi
  np2val=$(python3 "$NP_TMP/renamed/.claude/skills/mechatronics-docs/validate_vault.py" \
    "$NP_TMP/renamed/00_documentation/01_projectvault" 2>&1)
  TESTS=$((TESTS + 1))
  if contains "$np2val" "0 error(s), 0 warning(s)"; then ok x; else
    fail "renamed derivation must be warning-free:"
    printf '%s\n' "$np2val" | sed 's/^/    /'
  fi
  TESTS=$((TESTS + 1))
  if [ "$(head -n 1 "$NP_TMP/renamed/README.md")" = "# Renamed Proj" ]; then
    ok x; else fail "--name must set the generated README title"; fi

  # A non-empty target is refused, byte-untouched - the safety rule.
  mkdir -p "$NP_TMP/full"; printf 'keep' > "$NP_TMP/full/x"
  python3 "$NP" "$NP_TMP/full" >/dev/null 2>&1; np3rc=$?
  TESTS=$((TESTS + 1))
  if [ $np3rc -ne 0 ] && [ "$(cat "$NP_TMP/full/x")" = "keep" ] \
      && [ ! -e "$NP_TMP/full/README.md" ]; then ok x; else
    fail "non-empty target must be refused untouched (rc=$np3rc)"; fi

  rm -rf "$NP_TMP"
fi
# ==========================================================================
# END tools/new_project.py
# ==========================================================================

# ==========================================================================
# ARCHITECTURE.md - the finding-code index is complete in both directions
# ==========================================================================
# The map beside the validator is the only document naming which function
# owns which check (issue #81), and prose about code rots silently. The one
# part of it that can be derived from the source IS derived, on every run:
# a code the validator can emit and the map does not name fails here, and so
# does a code the map names that the validator can no longer emit - the
# second direction is what catches a rename, which is the likelier defect.
#
# The assertion is the exit status, not a parse of the output. A guard that
# prints nothing when it cannot read its input and is then compared against
# the empty string passes green on a deleted map - the switched-off gate
# this suite exists to prevent. Every failure path below exits non-zero.
TESTS=$((TESTS + 1))
if python3 - "$SKILL_DIR" <<'PY'
import ast, json, re, sys
from pathlib import Path

skill = Path(sys.argv[1])
# A finding code: lowercase words joined by hyphens. Drops the schema's own
# field_keys documentation sentences, which sit under the same "code" key.
SHAPE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
emitted, dynamic, opaque = set(), set(), []


def add(v):
    if isinstance(v, str) and SHAPE.match(v):
        emitted.add(v)


tree = ast.parse((skill / "validate_vault.py").read_text(encoding="utf-8-sig"))
for n in ast.walk(tree):
    if isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id == "Finding":
        arg = n.args[1] if len(n.args) >= 2 else None
        if isinstance(arg, ast.Constant) and isinstance(arg.value, str) and SHAPE.match(arg.value):
            emitted.add(arg.value)
        elif isinstance(arg, ast.Name):
            # Resolved below, out of the assignment to that name.
            dynamic.add(arg.id)
        else:
            # Keyword form, an f-string, a call - a shape this reader does not
            # follow. Reported, never skipped: a code that silently stops being
            # extracted makes the map look complete while it is not.
            opaque.append(f"validate_vault.py:{n.lineno}: the Finding() code argument is "
                          "neither a literal code nor a name this check can follow")
    if isinstance(n, ast.Dict):
        # FALLBACK_SCHEMA and any other descriptor written in Python.
        for k, v in zip(n.keys, n.values):
            if isinstance(k, ast.Constant) and k.value in ("code", "empty_code") \
                    and isinstance(v, ast.Constant):
                add(v.value)
for n in ast.walk(tree):
    # code = desc.get("code") or "frontmatter-value" - the literal is a direct
    # child of the BoolOp. Walking the whole assignment instead would pick up
    # the "code" string inside desc.get("code") as if it were a finding code.
    if isinstance(n, ast.Assign) and {t.id for t in n.targets if isinstance(t, ast.Name)} & dynamic:
        for s in ast.walk(n.value):
            if isinstance(s, ast.BoolOp):
                for o in s.values:
                    if isinstance(o, ast.Constant):
                        add(o.value)


def walk(x):
    if isinstance(x, dict):
        for k, v in x.items():
            if k in ("code", "empty_code"):
                add(v)
            if k == "codes" and isinstance(v, dict):
                add_keys = v.keys()      # code_fences.codes names its codes as keys
                for c in add_keys:
                    add(c)
            walk(v)
    elif isinstance(x, list):
        for v in x:
            walk(v)


walk(json.loads((skill / "vault_schema.json").read_text(encoding="utf-8-sig")))

# The map's side: the first column of the table between the two markers.
# Deliberately NOT every code span in the region - the scope and severity
# columns carry backticked field names and scope words that are not codes.
region = re.search(r"<!-- finding-codes:begin -->(.*?)<!-- finding-codes:end -->",
                   (skill / "ARCHITECTURE.md").read_text(encoding="utf-8-sig"), re.S)
if region is None:
    sys.exit("ARCHITECTURE.md: the finding-codes markers are gone - the index cannot be read")
mapped = set(re.findall(r"^\|\s*`([a-z0-9-]+)`\s*\|", region.group(1), re.M))

bad = []
if emitted - mapped:
    bad.append("emitted by the validator, absent from ARCHITECTURE.md: "
               + " ".join(sorted(emitted - mapped)))
if mapped - emitted:
    bad.append("named in ARCHITECTURE.md, no longer emitted: "
               + " ".join(sorted(mapped - emitted)))
bad += opaque
if bad:
    sys.exit("\n".join(bad))
PY
then ok x; else fail "ARCHITECTURE.md and the validator disagree about the finding codes"; fi

# ==========================================================================
# BEGIN --fail-on: the exporter's gap classes as a blocking check (issue
# #68, DEC-MTH-039). Self-contained and appended last for the same reason
# the block above is: concurrent branches append here too.
#
# No new trap. Traps in this file OVERWRITE rather than accumulate, so a
# fresh one would have to re-list all eleven directories or silently drop
# them from cleanup. Everything below writes under $EX_TMP, which the last
# trap already covers.
#
# The two positive assertions are paired with negative halves on purpose.
# The fixture's gap sets are 002/003/004 = not-allocated + no-evidence-
# note, 005 = not-proven + no-evidence-note, 006 = not-allocated, 001 =
# none - so "names REQ-COV-006" alone passes against an implementation
# that ignores the armed set and prints every requirement carrying any
# gap. Only the exclusions tell the two apart.
# ==========================================================================
FO_OUT="$EX_TMP/fail-on"

# The clean template vault, armed exactly as CI arms it.
TESTS=$((TESTS + 1))
if [ -d "$REAL_VAULT" ]; then
  python3 "$EXPORTER" "$REAL_VAULT" --output-dir "$FO_OUT/real" --no-timestamp \
    --fail-on not-allocated,no-evidence-note >/dev/null 2>&1
  if [ $? -eq 0 ]; then ok x; else
    fail "the shipped template vault must survive the armed classes"; fi
else
  fail "real template vault not found at $REAL_VAULT"
fi

# not-allocated: 006 is the requirement nothing allocates. 005 IS allocated
# (its row carries prose instead of a link) and must not appear here.
fo_na=$(python3 "$EXPORTER" "$CV" --output-dir "$FO_OUT/na" --no-timestamp \
  --fail-on not-allocated 2>&1 >/dev/null); fo_na_rc=$?
TESTS=$((TESTS + 1))
if [ $fo_na_rc -eq 1 ]; then ok x; else
  fail "an armed run over an open evidence chain must exit 1, got $fo_na_rc"; fi
TESTS=$((TESTS + 1))
if contains "$fo_na" "REQ-COV-006"; then ok x; else
  fail "not-allocated must name REQ-COV-006:"
  printf '%s\n' "$fo_na" | sed 's/^/    /'; fi
TESTS=$((TESTS + 1))
if ! contains "$fo_na" "REQ-COV-005" && ! contains "$fo_na" "REQ-COV-001"; then
  ok x; else
  fail "not-allocated named a requirement of another class:"
  printf '%s\n' "$fo_na" | sed 's/^/    /'; fi

# no-evidence-note: the mirror image. 005 is named by no TAE; 006 is.
fo_ne=$(python3 "$EXPORTER" "$CV" --output-dir "$FO_OUT/ne" --no-timestamp \
  --fail-on no-evidence-note 2>&1 >/dev/null); fo_ne_rc=$?
TESTS=$((TESTS + 1))
if [ $fo_ne_rc -eq 1 ]; then ok x; else
  fail "no-evidence-note must exit 1 on the coverage fixture, got $fo_ne_rc"; fi
TESTS=$((TESTS + 1))
if contains "$fo_ne" "REQ-COV-005"; then ok x; else
  fail "no-evidence-note must name REQ-COV-005:"
  printf '%s\n' "$fo_ne" | sed 's/^/    /'; fi
TESTS=$((TESTS + 1))
if ! contains "$fo_ne" "REQ-COV-006" && ! contains "$fo_ne" "REQ-COV-001"; then
  ok x; else
  fail "no-evidence-note named a requirement of another class:"
  printf '%s\n' "$fo_ne" | sed 's/^/    /'; fi

# A run that blocks still hands over the evidence of why it blocked.
TESTS=$((TESTS + 1))
if [ -f "$FO_OUT/ne/traceability.json" ] && [ -f "$FO_OUT/ne/traceability.html" ]; then
  ok x; else fail "a blocking armed run must still write its artifacts"; fi

# The default contract, on the very vault the armed runs above fail on.
# This is the load-bearing assertion of the whole block: local behaviour
# is unchanged, and only a caller that asks for it ever gets blocked.
TESTS=$((TESTS + 1))
python3 "$EXPORTER" "$CV" --output-dir "$FO_OUT/plain" --no-timestamp >/dev/null 2>&1
if [ $? -eq 0 ]; then ok x; else
  fail "without --fail-on a gap must not change the exit code"; fi

# A class name this tool does not know is refused before anything is read:
# exit 2, the valid names printed (that message IS the recovery path), and
# no output directory created.
fo_bad=$(python3 "$EXPORTER" "$CV" --output-dir "$FO_OUT/typo" --no-timestamp \
  --fail-on no_evidence_note 2>&1); fo_bad_rc=$?
TESTS=$((TESTS + 1))
if [ $fo_bad_rc -eq 2 ]; then ok x; else
  fail "an unknown gap class must be refused with exit 2, got $fo_bad_rc"; fi
TESTS=$((TESTS + 1))
if contains "$fo_bad" "not-allocated" && contains "$fo_bad" "no-evidence-note" \
   && contains "$fo_bad" "evidence-disagrees" && contains "$fo_bad" "not-proven" \
   && contains "$fo_bad" "evidence-is-prose"; then ok x; else
  fail "the refusal must list every valid class name:"
  printf '%s\n' "$fo_bad" | sed 's/^/    /'; fi
TESTS=$((TESTS + 1))
if [ ! -e "$FO_OUT/typo" ]; then ok x; else
  fail "a refused --fail-on must not have written anything"; fi

# An empty or whitespace-only value arms nothing, which is the same
# switched-off gate as a typo and is refused the same way.
for fo_empty in "" "  ,  "; do
  TESTS=$((TESTS + 1))
  python3 "$EXPORTER" "$CV" --output-dir "$FO_OUT/empty" --no-timestamp \
    --fail-on "$fo_empty" >/dev/null 2>&1
  if [ $? -eq 2 ]; then ok x; else
    fail "--fail-on '$fo_empty' must be refused, not treated as unarmed"; fi
done

# Whitespace around a name is trimmed and a repeated name is read once.
TESTS=$((TESTS + 1))
python3 "$EXPORTER" "$REAL_VAULT" --output-dir "$FO_OUT/dedup" --no-timestamp \
  --fail-on "not-allocated, not-allocated , no-evidence-note" >/dev/null 2>&1
if [ $? -eq 0 ]; then ok x; else
  fail "--fail-on must trim and deduplicate its class list"; fi

# A gate over a graph with no requirement cannot fail, so it fails. The
# method vault is the shipped vault of exactly that shape.
TESTS=$((TESTS + 1))
if [ -d "$METHOD_VAULT" ]; then
  fo_empty_out=$(python3 "$EXPORTER" "$METHOD_VAULT" --output-dir "$FO_OUT/none" \
    --no-timestamp --fail-on not-allocated 2>&1 >/dev/null)
  if [ $? -eq 1 ] && contains "$fo_empty_out" "no requirement at all"; then
    ok x; else
    fail "an armed run over a graph without requirements must fail:"
    printf '%s\n' "$fo_empty_out" | sed 's/^/    /'; fi
else
  fail "method vault not found at $METHOD_VAULT"
fi

# Precedence: the flag is validated ahead of the vault-root refusal, so the
# message names the flag the caller got wrong rather than the next thing to
# fail. Both are exit 2, so only the message can tell them apart.
fo_prec=$(python3 "$EXPORTER" "$EX_TMP" --output-dir "$FO_OUT/prec" \
  --fail-on typo 2>&1); fo_prec_rc=$?
TESTS=$((TESTS + 1))
# Matched without the leading dashes: 'contains' passes the pattern to grep
# unguarded, and a pattern starting with '-' is read as an option there.
if [ $fo_prec_rc -eq 2 ] && contains "$fo_prec" "fail-on names no gap class"; then
  ok x; else
  fail "a bad --fail-on must be refused before the vault-root check:"
  printf '%s\n' "$fo_prec" | sed 's/^/    /'; fi
# ==========================================================================
# END --fail-on
# ==========================================================================

# ==========================================================================
# BEGIN --formats - a mistyped output name is refused, not written past
# (issue #98, DEC-MTH-043). Appended after the --fail-on block because it
# reuses its vault variables and takes the same shape: the refusal is the
# recovery path, so the message has to name the valid values.
# ==========================================================================
FMT_OUT=$(mktemp -d)

# An unknown name: exit 2, every valid format listed, nothing written. It
# weighs heavier than the --fail-on typo above - that one skipped a check,
# this one destroys the artifact the caller asked for.
fmt_bad=$(python3 "$EXPORTER" "$REAL_VAULT" --output-dir "$FMT_OUT/typo" \
  --no-timestamp --formats jsonn 2>&1); fmt_bad_rc=$?
TESTS=$((TESTS + 1))
if [ $fmt_bad_rc -eq 2 ]; then ok x; else
  fail "an unknown --formats name must be refused with exit 2, got $fmt_bad_rc"; fi
TESTS=$((TESTS + 1))
if contains "$fmt_bad" "jsonn" && contains "$fmt_bad" "json" \
   && contains "$fmt_bad" "csv" && contains "$fmt_bad" "html" \
   && contains "$fmt_bad" "index"; then ok x; else
  fail "the refusal must name the bad value and every valid format:"
  printf '%s\n' "$fmt_bad" | sed 's/^/    /'; fi
TESTS=$((TESTS + 1))
if [ ! -e "$FMT_OUT/typo" ]; then ok x; else
  fail "a refused --formats must not have written anything"; fi

# The measured shape of issue #98: exit 0 and an empty directory. Both must
# now be impossible, for an empty value as much as for a typo - falling back
# to the defaults would leave '--formats ""' writing nothing in silence.
for fmt_empty in "" "  ,  "; do
  TESTS=$((TESTS + 1))
  python3 "$EXPORTER" "$REAL_VAULT" --output-dir "$FMT_OUT/empty" \
    --no-timestamp --formats "$fmt_empty" >/dev/null 2>&1
  if [ $? -eq 2 ] && [ ! -e "$FMT_OUT/empty" ]; then ok x; else
    fail "--formats '$fmt_empty' must be refused and write nothing"; fi
done

# Precedence, pinned by message because both refusals are exit 2: --fail-on
# is checked first, so a caller who got both flags wrong is told about the
# gate before the output. The vault root is deliberately bad as well - all
# three refusals are in play and the first one still wins.
fmt_prec=$(python3 "$EXPORTER" "$EX_TMP" --output-dir "$FMT_OUT/prec" \
  --formats jsonn --fail-on typo 2>&1); fmt_prec_rc=$?
TESTS=$((TESTS + 1))
if [ $fmt_prec_rc -eq 2 ] && contains "$fmt_prec" "fail-on names no gap class"; then
  ok x; else
  fail "--fail-on must be refused ahead of --formats and the vault root:"
  printf '%s\n' "$fmt_prec" | sed 's/^/    /'; fi

# A bad --formats still beats the vault-root refusal, so the message names
# the flag rather than the next thing that fails.
fmt_root=$(python3 "$EXPORTER" "$EX_TMP" --output-dir "$FMT_OUT/root" \
  --formats jsonn 2>&1); fmt_root_rc=$?
TESTS=$((TESTS + 1))
if [ $fmt_root_rc -eq 2 ] && contains "$fmt_root" "formats names no output format"; then
  ok x; else
  fail "a bad --formats must be refused before the vault-root check:"
  printf '%s\n' "$fmt_root" | sed 's/^/    /'; fi

# A valid subset is unchanged: whitespace trimmed, a repeat read once, and
# only what was asked for on disk.
TESTS=$((TESTS + 1))
if python3 "$EXPORTER" "$REAL_VAULT" --output-dir "$FMT_OUT/subset" \
     --no-timestamp --formats " csv , csv " >/dev/null 2>&1 \
   && [ -f "$FMT_OUT/subset/traceability_requirements.csv" ] \
   && [ -f "$FMT_OUT/subset/traceability_edges.csv" ] \
   && [ ! -f "$FMT_OUT/subset/traceability.json" ]; then ok x; else
  fail "a valid --formats subset must write exactly what it names"; fi

rm -rf "$FMT_OUT"
# ==========================================================================
# END --formats
# ==========================================================================

# ==========================================================================
# BEGIN TUTORIAL.md - the tutorial is replayed, not reviewed (issue #77,
# DEC-MTH-040). Self-contained and appended last for the same reason the
# two blocks above are: concurrent branches append here too.
#
# The document IS the fixture. Every file the tutorial tells a reader to
# create is extracted from TUTORIAL.md itself and written to the path its
# marker names, so a second copy cannot drift against what the page shows.
# Then the tutorial's own commands run, in its own order, and its own
# quoted output is diffed against what they printed.
#
# No new trap: traps in this file OVERWRITE rather than accumulate, so a
# fresh one would silently drop the eleven roots the last one covers.
# Everything below lives under $TUT_TMP and is removed explicitly at the
# end of the block, the way the new_project.py block does it.
#
# The substrate is a DERIVED project, not this clone. That is not a
# convenience: three notes in this repository's own vault break the
# 'requirements: 3  proven: 3' assertion above and the README excerpt
# step in CI, which is exactly the red pipeline the tutorial must not
# hand a first-time reader.
# ==========================================================================
TUT_MD="$NP_ROOT/TUTORIAL.md"
TESTS=$((TESTS + 1))
if [ -f "$TUT_MD" ]; then ok x; else fail "tutorial not found at $TUT_MD"; fi

# tut <mode> [arg] - read TUTORIAL.md. Modes: count-files, path <i>,
# get-file <i>, get <marker>. The fence opener's length is matched, so a
# block containing a nested fence (the TAE note does) is read whole.
tut() {
  python3 - "$TUT_MD" "$@" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
mode = sys.argv[2]
FILE_RE = re.compile(r"^<!-- tutorial-file: (.+?) -->\n(`{3,})[^\n]*\n(.*?)^\2[ \t]*$",
                     re.S | re.M)
files = FILE_RE.findall(text)
if mode == "count-files":
    print(len(files))
elif mode in ("path", "get-file"):
    i = int(sys.argv[3])
    if i >= len(files):
        sys.exit("no tutorial-file block #%d" % i)
    sys.stdout.write(files[i][0] if mode == "path" else files[i][2])
elif mode == "get":
    m = re.search(r"^<!-- " + re.escape(sys.argv[3]) + r" -->\n(`{3,})[^\n]*\n(.*?)^\1[ \t]*$",
                  text, re.S | re.M)
    if not m:
        sys.exit("no block for marker: " + sys.argv[3])
    sys.stdout.write(m.group(2))
else:
    sys.exit("unknown mode: " + mode)
PY
}

# tut_diff <marker> <actual> <description> - the tutorial's quoted output
# against what the command printed. Trailing newlines are normalised on
# both sides; nothing else is.
tut_diff() {
  TESTS=$((TESTS + 1))
  _exp=$(tut get "$1")
  if [ "$_exp" = "$2" ]; then ok x; else
    fail "$3"
    diff <(printf '%s\n' "$_exp") <(printf '%s\n' "$2") | sed 's/^/    /'
  fi
}

if [ -f "$TUT_MD" ] && [ -f "$NP" ]; then
  TUT_TMP=$(mktemp -d)
  TUT_DIR="$TUT_TMP/my-first-project"
  TUT_VAULT="$TUT_DIR/00_documentation/01_projectvault"

  # The document's shape, asserted before anything is replayed: three
  # notes, and the third is the TAE. The order is load-bearing - the
  # tutorial measures between the second file and the third, and a
  # reshuffled document must fail here rather than silently test a
  # different lesson.
  TESTS=$((TESTS + 1))
  if [ "$(tut count-files)" = "3" ]; then ok x; else
    fail "TUTORIAL.md must carry exactly 3 tutorial-file blocks, found $(tut count-files)"; fi
  TESTS=$((TESTS + 1))
  case "$(tut path 2)" in
    07_testing_and_evidence_*) ok x ;;
    *) fail "the third tutorial-file block must be the TAE note, is '$(tut path 2)'" ;;
  esac

  # Step 0 of the tutorial, verbatim.
  TESTS=$((TESTS + 1))
  if python3 "$NP" "$TUT_DIR" >/dev/null 2>&1; then ok x; else
    fail "step 0 of the tutorial (deriving a project) failed"; fi

  if [ -d "$TUT_VAULT" ]; then
    # Steps 1 and 2: the first two notes, written where their markers say.
    for i in 0 1; do
      tut get-file "$i" > "$TUT_VAULT/$(tut path "$i")"
    done
    # Step 3: the module row replaces the placeholder row, by name.
    python3 - "$TUT_VAULT/system_overview.md" "$(tut get 'tutorial-row: overview')" <<'PY'
import sys
path, row = sys.argv[1], sys.argv[2].rstrip("\n")
old = "| *Add your modules here* | *Brief description of the module* |"
text = open(path, encoding="utf-8").read()
if text.count(old) != 1:
    sys.exit("placeholder row not found exactly once in system_overview.md")
open(path, "w", encoding="utf-8").write(text.replace(old, row))
PY
    TESTS=$((TESTS + 1))
    if grep -q "ARC_Documentation_Check" "$TUT_VAULT/system_overview.md"; then ok x; else
      fail "step 3 did not put the module row into system_overview.md"; fi

    # Step 4, in the tutorial's own spellings, from the project root.
    tv1=$(cd "$TUT_DIR" && python3 .claude/skills/mechatronics-docs/validate_vault.py \
      00_documentation/01_projectvault 2>&1)
    tv1sum=$(printf '%s\n' "$tv1" | tail -n 1)
    tut_diff "tutorial-output: validator-draft" "$tv1sum" \
      "the validator's summary line after step 3 is not what the tutorial shows"
    TESTS=$((TESTS + 1))
    if contains "$tv1" "req-uncovered"; then ok x; else
      fail "step 4 must show the reader the open req-uncovered warning:"
      printf '%s\n' "$tv1" | sed 's/^/    /'; fi

    te1=$(cd "$TUT_DIR" && python3 .claude/skills/mechatronics-docs/export_traceability.py \
      00_documentation/01_projectvault --output-dir ../traceability 2>&1)
    te1cmp=$(printf '%s\n' "$te1" | grep -v '^vault: ' | grep -v '^written to: ')
    tut_diff "tutorial-output: export-draft" "$te1cmp" \
      "the exporter's machine-independent lines after step 3 differ from the tutorial"

    # The evidence the tutorial's TAE carries must be the line the run above
    # actually printed. This is the assertion that keeps the tutorial from
    # teaching a reader to write down a result nobody obtained.
    TESTS=$((TESTS + 1))
    tae_ev=$(tut get-file 2 | grep '^-- .*error(s)')
    if [ "$tae_ev" = "$tv1sum" ]; then ok x; else
      fail "the TAE's quoted evidence is not the line step 4 printed:"
      printf '    TAE:  %s\n    run:  %s\n' "$tae_ev" "$tv1sum"; fi

    # Step 5: the TAE. Step 6: the allocation row, replaced by its prefix -
    # exactly one line of the ARC note starts with it.
    tut get-file 2 > "$TUT_VAULT/$(tut path 2)"
    python3 - "$TUT_VAULT/$(tut path 1)" "$(tut get 'tutorial-row: allocation')" <<'PY'
import sys
path, row = sys.argv[1], sys.argv[2].rstrip("\n")
prefix = "| [[ARC_Documentation_Check]] (ARC-DOC-001) |"
lines = open(path, encoding="utf-8").read().splitlines(True)
hits = [i for i, l in enumerate(lines) if l.startswith(prefix)]
if len(hits) != 1:
    sys.exit("allocation row not found exactly once in the ARC note")
lines[hits[0]] = row + "\n"
open(path, "w", encoding="utf-8").writelines(lines)
PY

    # Step 7: the same two commands, and the reader's own loop.
    tv2=$(cd "$TUT_DIR" && python3 .claude/skills/mechatronics-docs/validate_vault.py \
      00_documentation/01_projectvault 2>&1)
    tut_diff "tutorial-output: validator-final" "$(printf '%s\n' "$tv2" | tail -n 1)" \
      "the validator's summary line after step 6 is not what the tutorial shows"
    TESTS=$((TESTS + 1))
    if ! contains "$tv2" "req-uncovered"; then ok x; else
      fail "req-uncovered must be gone once the loop is closed"; fi

    te2=$(cd "$TUT_DIR" && python3 .claude/skills/mechatronics-docs/export_traceability.py \
      00_documentation/01_projectvault --output-dir ../traceability 2>&1)
    tut_diff "tutorial-output: export-final" \
      "$(printf '%s\n' "$te2" | grep -v '^vault: ' | grep -v '^written to: ')" \
      "the exporter's machine-independent lines after step 6 differ from the tutorial"
    tut_diff "tutorial-output: index" \
      "$(cd "$TUT_DIR" && grep -- -DOC- ../traceability/traceability_index.md)" \
      "the index lines the tutorial shows are not the ones the export wrote"

    # A reader who follows the tutorial and pushes must not meet a red
    # pipeline: the derived workflow's two steps, run here as CI runs them.
    TESTS=$((TESTS + 1))
    if (cd "$TUT_DIR" && python3 .claude/skills/mechatronics-docs/validate_vault.py \
        00_documentation/01_projectvault >/dev/null 2>&1); then ok x; else
      fail "a project that followed the tutorial must pass its own vault audit"; fi
    # The same output directory twice with the first run copied aside, as
    # the generated workflow does it: two different directories would
    # differ in the provenance block's command line, which is a true
    # record and not a determinism defect.
    TESTS=$((TESTS + 1))
    if (cd "$TUT_DIR" \
        && python3 .claude/skills/mechatronics-docs/export_traceability.py \
             00_documentation/01_projectvault --output-dir "$TUT_TMP/d" --no-timestamp >/dev/null 2>&1 \
        && cp -r "$TUT_TMP/d" "$TUT_TMP/d-ref" \
        && python3 .claude/skills/mechatronics-docs/export_traceability.py \
             00_documentation/01_projectvault --output-dir "$TUT_TMP/d" --no-timestamp >/dev/null 2>&1 \
        && diff -r "$TUT_TMP/d-ref" "$TUT_TMP/d" >/dev/null 2>&1); then ok x; else
      fail "a project that followed the tutorial must pass its export determinism step"; fi
  fi

  rm -rf "$TUT_TMP"
fi
# ==========================================================================
# END TUTORIAL.md
# ==========================================================================

# ==========================================================================
# BEGIN tools/new_project.py --minimal - the three-domain profile (issue #79)
# ==========================================================================
# A project starts with REQ, ARC and TAE, and the other six domain folders
# are MOVED to a parking folder beside the vault rather than deleted, so a
# domain joins later by moving its folder back with its template (DEC-MTH-041).
#
# Two assertions carry this block, and both can fail on a --minimal that does
# nothing: the reduced vault's domain folders are named exactly, and the
# tutorial's own closed loop - the three files a reader writes - is replayed
# INSIDE the reduced vault and must print the numbers TUTORIAL.md pins for the
# full profile. That is what makes "REQ, ARC and TAE are enough" a measurement
# rather than a claim. It reuses the tut helper of the block above, which is
# why this one comes after it and before the summary - and, like the block
# above, it cleans up with an explicit rm instead of a trap: traps in this
# file overwrite rather than accumulate.
# ==========================================================================
MIN_PARK="00_documentation/03_vault_domains_not_in_use"
if [ -f "$NP" ]; then
  MIN_TMP=$(mktemp -d)
  MD="$MIN_TMP/minproj"
  minout=$(python3 "$NP" "$MD" --minimal 2>&1); minrc=$?
  TESTS=$((TESTS + 1))
  if [ $minrc -eq 0 ]; then ok x; else
    fail "--minimal derivation must exit 0, got $minrc:"
    printf '%s\n' "$minout" | tail -5 | sed 's/^/    /'
  fi

  # The reduced vault, named exactly. A --minimal that parked nothing, or
  # parked the wrong folders, fails here and not three assertions later.
  minvault="$MD/00_documentation/01_projectvault"
  mindirs=$(ls -1 "$minvault" 2>/dev/null | grep '(' | tr '\n' ' ')
  TESTS=$((TESTS + 1))
  if [ "$mindirs" = "01_requirements_(REQ) 03_architecture_(ARC) 07_testing_and_evidence_(TAE) 98_administration_(ADM) 99_inbox_(INB) " ]; then
    ok x; else fail "minimal vault must carry REQ, ARC, TAE, ADM, INB - has: $mindirs"; fi

  for d in "02_decisions_(DEC)" "04_components_(CMP)" "05_interfaces_(IFC)" \
      "06_implementation_(IMP)" "08_operation_and_usage_(OAU)" "09_references_(REF)"; do
    TESTS=$((TESTS + 1))
    if [ -d "$MD/$MIN_PARK/$d" ] && [ ! -e "$minvault/$d" ]; then ok x; else
      fail "$d must be parked in $MIN_PARK, not in the vault"; fi
    # Parked WITH its template: a domain that returns without one has no
    # enforced sections, which is the whole reason this moves and not deletes.
    TESTS=$((TESTS + 1))
    if ls "$MD/$MIN_PARK/$d"/00_*file_template*.md >/dev/null 2>&1 \
        || ls "$MD/$MIN_PARK/$d"/00_*README*.md >/dev/null 2>&1; then ok x; else
      fail "$d was parked without its README and file template"; fi
  done

  # The parking lot's own marker must NOT be called README.md: a third README
  # stem under 00_documentation makes --rename-docs-readme's warning-free
  # state unreachable.
  TESTS=$((TESTS + 1))
  if [ -f "$MD/$MIN_PARK/00_domains_not_in_use_README.md" ] \
      && [ ! -e "$MD/$MIN_PARK/README.md" ]; then ok x; else
    fail "the parking folder's marker must be 00_domains_not_in_use_README.md"; fi
  TESTS=$((TESTS + 1))
  if grep -q "move the folder back" "$MD/$MIN_PARK/00_domains_not_in_use_README.md" 2>/dev/null \
      && grep -q "do not create a fresh folder" "$MD/$MIN_PARK/00_domains_not_in_use_README.md" 2>/dev/null; then
    ok x; else fail "the parking marker must say to move the folder back, not recreate it"; fi

  # The state the script predicts is the state the validator reports - the
  # same bar the default derivation is held to.
  minval=$(python3 "$MD/.claude/skills/mechatronics-docs/validate_vault.py" \
    "$minvault" 2>&1); minvrc=$?
  TESTS=$((TESTS + 1))
  if [ $minvrc -eq 0 ] && contains "$minval" "0 error(s), 1 warning(s)" \
      && contains "$minval" "duplicate-basename"; then ok x; else
    fail "minimal vault must report exactly the known WARN:"
    printf '%s\n' "$minval" | sed 's/^/    /'
  fi
  minexp=$(python3 "$MD/.claude/skills/mechatronics-docs/export_traceability.py" \
    "$minvault" --output-dir "$MIN_TMP/tr" --no-timestamp 2>&1)
  TESTS=$((TESTS + 1))
  if contains "$minexp" "findings: 0"; then ok x; else
    fail "the export of a minimal vault must carry no finding:"
    printf '%s\n' "$minexp" | sed 's/^/    /'
  fi

  # The prose that would be false in a three-domain project is corrected,
  # and the anchor it depends on is pinned by its result.
  TESTS=$((TESTS + 1))
  if grep -q "03_vault_domains_not_in_use" "$MD/STRUCTURE.md" \
      && ! grep -q "Two subfolders that share the same nine-domain" "$MD/STRUCTURE.md"; then
    ok x; else fail "STRUCTURE.md still describes a nine-domain vault in a minimal project"; fi
  TESTS=$((TESTS + 1))
  if grep -q "## Minimal profile" "$MD/README.md" \
      && grep -q "$MIN_PARK" "$MD/README.md"; then ok x; else
    fail "the generated README must explain the minimal profile and name the parking folder"; fi

  # The growth path: one move, no migration, same reported state - and the
  # folder is gone from the parking lot rather than copied out of it.
  mv "$MD/$MIN_PARK/02_decisions_(DEC)" "$minvault/" 2>/dev/null
  grownval=$(python3 "$MD/.claude/skills/mechatronics-docs/validate_vault.py" \
    "$minvault" 2>&1)
  TESTS=$((TESTS + 1))
  if [ -d "$minvault/02_decisions_(DEC)" ] && [ ! -e "$MD/$MIN_PARK/02_decisions_(DEC)" ] \
      && contains "$grownval" "0 error(s), 1 warning(s)"; then ok x; else
    fail "a domain moved back into the vault must need no migration:"
    printf '%s\n' "$grownval" | sed 's/^/    /'
  fi

  # The negative control, derived here because the block above removes its
  # own target: without --minimal nothing is parked and nothing is renamed.
  python3 "$NP" "$MIN_TMP/defctl" >/dev/null 2>&1
  TESTS=$((TESTS + 1))
  if [ -d "$MIN_TMP/defctl/00_documentation/01_projectvault/02_decisions_(DEC)" ] \
      && [ ! -e "$MIN_TMP/defctl/$MIN_PARK" ] \
      && ! grep -q "## Minimal profile" "$MIN_TMP/defctl/README.md"; then ok x; else
    fail "the default derivation must keep every domain folder in the vault"; fi

  # --minimal composes with the flags beside it.
  min2out=$(python3 "$NP" "$MIN_TMP/mr" --minimal --rename-docs-readme \
    --name "Tiny Rig" 2>&1); min2rc=$?
  min2val=$(python3 "$MIN_TMP/mr/.claude/skills/mechatronics-docs/validate_vault.py" \
    "$MIN_TMP/mr/00_documentation/01_projectvault" 2>&1)
  TESTS=$((TESTS + 1))
  if [ $min2rc -eq 0 ] && contains "$min2val" "0 error(s), 0 warning(s)" \
      && [ "$(head -n 1 "$MIN_TMP/mr/README.md")" = "# Tiny Rig" ]; then ok x; else
    fail "--minimal --rename-docs-readme --name must derive warning-free (rc=$min2rc):"
    printf '%s\n' "$min2val" | sed 's/^/    /'
  fi

  # A clone whose vault already documents something is refused BEFORE the
  # first write: parking a populated domain would take its notes out of the
  # vault the validator reads, and the validator would stay green.
  cp -r "$NP_ROOT" "$MIN_TMP/src" 2>/dev/null
  printf -- '---\ndomain: DEC\n---\n' \
    > "$MIN_TMP/src/00_documentation/01_projectvault/02_decisions_(DEC)/DEC_Mine.md"
  refout=$(python3 "$MIN_TMP/src/tools/new_project.py" "$MIN_TMP/refused" --minimal 2>&1)
  refrc=$?
  TESTS=$((TESTS + 1))
  if [ $refrc -ne 0 ] && contains "$refout" "DEC_Mine.md" \
      && [ ! -e "$MIN_TMP/refused" ]; then ok x; else
    fail "--minimal must refuse a populated domain folder before writing (rc=$refrc):"
    printf '%s\n' "$refout" | tail -3 | sed 's/^/    /'
  fi

  # The reduced profile can close the method's loop on day one: the
  # tutorial's own three files, replayed inside the minimal vault, must
  # print the numbers TUTORIAL.md pins for the full one.
  if [ -f "$TUT_MD" ]; then
    MTUT="$MIN_TMP/tutproj"
    python3 "$NP" "$MTUT" --minimal >/dev/null 2>&1
    MTV="$MTUT/00_documentation/01_projectvault"
    if [ -d "$MTV" ]; then
      for i in 0 1 2; do
        tut get-file "$i" > "$MTV/$(tut path "$i")"
      done
      python3 - "$MTV/system_overview.md" "$(tut get 'tutorial-row: overview')" <<'PY'
import sys
path, row = sys.argv[1], sys.argv[2].rstrip("\n")
old = "| *Add your modules here* | *Brief description of the module* |"
text = open(path, encoding="utf-8").read()
if text.count(old) != 1:
    sys.exit("placeholder row not found exactly once in system_overview.md")
open(path, "w", encoding="utf-8").write(text.replace(old, row))
PY
      python3 - "$MTV/$(tut path 1)" "$(tut get 'tutorial-row: allocation')" <<'PY'
import sys
path, row = sys.argv[1], sys.argv[2].rstrip("\n")
prefix = "| [[ARC_Documentation_Check]] (ARC-DOC-001) |"
lines = open(path, encoding="utf-8").read().splitlines(True)
hits = [i for i, l in enumerate(lines) if l.startswith(prefix)]
if len(hits) != 1:
    sys.exit("allocation row not found exactly once in the ARC note")
lines[hits[0]] = row + "\n"
open(path, "w", encoding="utf-8").writelines(lines)
PY
      mtv=$(cd "$MTUT" && python3 .claude/skills/mechatronics-docs/validate_vault.py \
        00_documentation/01_projectvault 2>&1)
      tut_diff "tutorial-output: validator-final" "$(printf '%s\n' "$mtv" | tail -n 1)" \
        "a closed loop in a MINIMAL vault must report what the tutorial shows"
      mte=$(cd "$MTUT" && python3 .claude/skills/mechatronics-docs/export_traceability.py \
        00_documentation/01_projectvault --output-dir "$MIN_TMP/mtr" 2>&1)
      tut_diff "tutorial-output: export-final" \
        "$(printf '%s\n' "$mte" | grep -v '^vault: ' | grep -v '^written to: ')" \
        "a closed loop in a MINIMAL vault must export what the tutorial shows"
    else
      TESTS=$((TESTS + 1))
      fail "the minimal derivation for the tutorial replay produced no vault"
    fi
  fi

  rm -rf "$MIN_TMP"
fi
# ==========================================================================
# END tools/new_project.py --minimal
# ==========================================================================

echo "$TESTS tests, $FAILURES failure(s)"
if [ "$FAILURES" -eq 0 ]; then
  echo "ALL TESTS PASSED"
else
  exit 1
fi
