## Context
_What the module includes, and what not. Max. 5-7 bullet points. No implementation details._

**Includes:**
-
-

**Excludes:**
-
-

**Related Modules:**
- \[\[ARC_X]]: Where the module connects.

## Requirements (Files)
- \[\[REQ_X]]: Why relevant for this module (1 sentence).
- \[\[REQ_Y]]: Why relevant for this module (1 sentence).

## Decisions (Files)
- \[\[DEC_X]]: Classification in architecture (1 sentence).
- \[\[DEC_Y]]: Classification in architecture (1 sentence).

## Components (Files)
- \[\[CMP_X]]: Role in the module.
- \[\[CMP_Y]]: Role in the module.

## Interfaces
| Interface (IFC)   | Endpoint A          | Endpoint B       | Context          |
| ----------------- | ------------------- | ---------------- | ---------------- |
| \[\[IFC_SPI_ADC]] | \[\[CMP_ADC_Board]] | \[\[CMP_MCU_XY]] | ADC Data to MCU  |

## Implementation (Files)
- \[\[IMP_X]]: What is realized here.
- \[\[IMP_Y]]: What is realized here.

## Allocation and Verification
| Submodule (ARC/CMP/IFC)    | Allocated Requirements (REQ-IDs) | Verification (TAE)                                       | Status |
| -------------------------- | -------------------------------- | -------------------------------------------------------- | ------ |
| \[\[CMP_VoltageDivider]]   | REQ-MEG-001, REQ-SAE-001         | \[\[TAE_MeasBoard_U_Measurement]], \[\[TAE_TouchProtection]] | Draft  |
