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

cat > "$V/04_components_(CMP)/CMP_MCU_Board.md" <<'EOF'
---
domain: CMP
status: active
created: 2026-01-06
last-verified: 2026-07-01
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
status: active
created: 2026-01-08
last-verified: 2026-07-01
---
## Context
Concrete realization of the ADC wiring and driver configuration on the
main board.

## References
- Schematic: Testproj/10_hardware/13_PCB/main_board.kicad_sch

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

## Allocation and Verification
| Submodule (ARC/CMP/IFC) | Allocated Requirements (REQ-IDs) | Verification (TAE) | Status |
| ----------------------- | -------------------------------- | ------------------ | ------ |
| [[CMP_AD7175-2]] | REQ-MEG-001 | [[TAE_ADC_Linearity]] | Verified |
| [[IFC_SPI_ADC]] | REQ-MEG-002 | [[TAE_ADC_Linearity]] | Verified |
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

cat > "$W/01_requirements_(REQ)/wrongname.md" <<'EOF'
no frontmatter, wrong name, no sections
line
line
line
line
EOF

cat > "$W/01_requirements_(REQ)/REQ_Power (PWR).md" <<'EOF'
---
domain: REQ
status: active
created: 2026-01-05
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

cat > "$W/02_decisions_(DEC)/DEC_Bad.md" <<'EOF'
---
domain: DEC
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

- [[Nonexistent_File]]: dead link target.
- [[Another_Missing]]: second dead link target.
EOF

{
  printf -- '---\ndomain: ARC\nstatus: active\ncreated: 2026-01-09\nlast-verified: 2026-07-01\n---\n'
  printf '## Context\n'
  printf '## Requirements (Files)\n## Decisions (Files)\n## Components (Files)\n'
  printf '## Interfaces\n## Implementation (Files)\n## Allocation and Verification\n'
  for i in $(seq 1 400); do printf 'filler line without any concrete values here\n'; done
} > "$W/03_architecture_(ARC)/ARC_Long.md"

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
    inb-age duplicate-basename orphan; do
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

  # seeded: code-fence + impl-leak + link-unresolved
  cat > "$V/$A/ARC_Messkette.md" <<'EOF'
---
domain: ARC
status: active
created: 2026-01-09
last-verified: 2026-07-01
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

  # seeded: template-sections (missing "Zuordnung und Verifikation")
  cat > "$V/$A/ARC_Unvollstaendig.md" <<'EOF'
---
domain: ARC
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
