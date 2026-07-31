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
cat > "$V/04_components_(CMP)/CMP_MCU_Board.md" <<'EOF'
---
domain: CMP
id: CMP-MEG-002
status: active
created: 2026-01-06
last-verified: 2026-07-01
tags: [hardware, adc]
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
| [[CMP_AD7175-2]] | REQ-MEG-001 | [[TAE_ADC_Linearity]] | Verified |
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

cat > "$W/07_testing_and_evidence_(TAE)/TAE_Bad.md" <<'EOF'
---
domain: TAE
status: banana
created: 2026-01-10
last-verified: 2026-07-01
verifies: [REQ-XXX-999]
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
if contains "$hout" "2 unresolved link target"; then ok x; else
  fail "post hook must aggregate unresolved links into one summary"; fi
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

rm -f "/tmp/claude-mechdocs/touched-$SID" "/tmp/claude-mechdocs/baseline-$SID" \
      "/tmp/claude-mechdocs/blocks-$SID"

echo "$TESTS tests, $FAILURES failure(s)"
if [ "$FAILURES" -eq 0 ]; then
  echo "ALL TESTS PASSED"
else
  exit 1
fi
