---
domain: ARC
id: ARC-DOM-NNN
status: draft
created: YYYY-MM-DD
last-verified: YYYY-MM-DD
---
## Context
_What the module includes, and what not. Max. 5-7 bullet points. No implementation details._

**Includes:**
-
-

**Excludes:**
-
-

**Related Modules:**
_Not annotated: a peer module is navigation, not containment. ARC-to-ARC
containment is written in the submodule table of the main module template._
- \[\[ARC_X]]: Where the module connects.

## Requirements (Files)
_Each link carries the target's identifier after it. That annotation is what
makes the link a relation the traceability export can read._
- \[\[REQ_X]] (REQ-DOM-NNN): Why relevant for this module (1 sentence).
- \[\[REQ_Y]] (REQ-DOM-NNN): Why relevant for this module (1 sentence).

## Decisions (Files)
- \[\[DEC_X]] (DEC-DOM-NNN): Classification in architecture (1 sentence).
- \[\[DEC_Y]] (DEC-DOM-NNN): Classification in architecture (1 sentence).

## Components (Files)
- \[\[CMP_X]] (CMP-DOM-NNN): Role in the module.
- \[\[CMP_Y]] (CMP-DOM-NNN): Role in the module.

## Interfaces
| Interface (IFC)   | Endpoint A          | Endpoint B       | Context          |
| ----------------- | ------------------- | ---------------- | ---------------- |
| \[\[IFC_SPI_ADC]] | \[\[CMP_ADC_Board]] | \[\[CMP_MCU_XY]] | ADC Data to MCU  |

## Implementation (Files)
- \[\[IMP_X]] (IMP-DOM-NNN): What is realized here.
- \[\[IMP_Y]] (IMP-DOM-NNN): What is realized here.

## Allocation and Verification
| Submodule (ARC/CMP/IFC)    | Allocated Requirements (REQ-IDs) | Verification (TAE)                                       | Status |
| -------------------------- | -------------------------------- | -------------------------------------------------------- | ------ |
| \[\[CMP_VoltageDivider]]   | REQ-MEG-001, REQ-SAE-001         | \[\[TAE_MeasBoard_U_Measurement]], \[\[TAE_TouchProtection]] | Draft  |
