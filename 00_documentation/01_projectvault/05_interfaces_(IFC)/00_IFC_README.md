IFC notes define interfaces as contract types.
An IFC describes the parameters of a connection (electrical/logical/mechanical), without specifying concrete endpoints.
The assignment of which components use an IFC is done in ARC via the interface table [[00_ARC_README]].

## Goal
- Define interfaces electrically/mechanically unambiguously, without implementation or components
- Ensure interchangeability and traceability (same contract, different endpoints)

## Structure
### 1) Context
Type of interface (as contract type)

### 2) Specifications
relevant electrical/mechanical parameters


## Not included
- no endpoints (components/modules) and no topology
- no implementation details (pins, connector pinout, MCU instances like SPI1)
- no architecture or safety chain description

This information is in ARC (assignment/topology) or IMP (concrete implementation).

## Naming Convention (recommended)
IFC names must unambiguously describe which contract is meant.
Examples:
- IFC_SPI_ADC
- IFC_PWR_24VDC
- IFC_HV_IN
- IFC_RELAY_COIL_GND_SW
- IFC_DOOR_INTERLOCK_24V

Avoid:
- IFC_SPI (too generic)
- IFC_SPI1 (implementation instance, belongs in IMP)

---

## Specification Rules
- Only include parameters that are relevant for function, interchangeability or safety.
- Avoid values without source (reference sources via CMP/REF if necessary).
- If parameters are still unknown: set TBD and follow up status/verification later (via ARC/TAE).
