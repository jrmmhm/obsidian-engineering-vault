## Context
_What the module includes, AND what not. Link to relevant submodules. Max. 5-7 sentences. No implementation details._

## Module Scope

**Includes:**
- Point 1
- Point 2
- ...

**Excludes:**
- Point 1
- Point 2 
- ...

**Related Modules:**
- \[\[ARC_X]]: Where the module connects.

## Requirements (Files)
- \[\[REQ_X]]: Why relevant for this module (1 sentence).
- \[\[REQ_Y]]: Why relevant for this module (1 sentence).
- etc.
## Decisions (Files)
- \[\[DEC_X]]: Classification in architecture (1 sentence).
- \[\[DEC_Y]]: Classification in architecture (1 sentence).
- etc.
## Components (Files)
- \[\[CMP_X]]: Role in the module.
- \[\[CMP_Y]]: Role in the module.
- etc.
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
| \[\[CMP_CurrentSense]]     | REQ-MEG-002, REQ-EMV-003         | \[\[TAE_MeasBoard_I_Measurement]]                        | Draft  |
| \[\[IFC_SPI_ADC]]          | REQ-MEG-004, REQ-EMV-002         | \[\[TAE_SPI_Integrity]]                                  | Draft  |
| \[\[IFC_Safety_Interlock]] | REQ-SAE-005                      | \[\[TAE_Interlock_FaultInjection]]                       | Draft  |


