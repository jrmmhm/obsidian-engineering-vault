---
domain: IFC
status: active
created: 2026-07-28
last-verified: 2026-07-28
id: IFC-BAT-001
---
## Context

DC power contract of a four-cell lithium-polymer pack: the voltage range
a consumer of this contract must tolerate, and the range within which a
recorded pack voltage is considered valid. Contract type only — the
endpoints that use it are assigned in
[[ARC_Battery_Monitoring]] (ARC-BAT-001), and the way a voltage is read
is implementation and lives in
[[IMP_Battery_Log_Evaluation]] (IMP-BAT-001).

## Specifications

### Signal/Line Type
- Type: Power DC
- Direction: A→B (pack supplies the consumer)
- Default state: unpowered pack presents no output

### Electrical Parameters
- Nominal voltage: 15.44 V, the design voltage reported by
  [[CMP_Battery_Pack]] (CMP-BAT-001)
- Operating range: 12.00 V to 17.40 V
- Range derivation: four cells at 3.00 V to 4.35 V each. The cell count
  is inferred from the nominal voltage, since 15.44 V is four times the
  3.86 V nominal of a lithium-polymer cell; the pack does not report a
  cell count *(unverified)*.
- Isolation / reference potential: GND-referenced, not isolated

### Connection
- Connection type: internal pack connector
- Shielding / cable length: not relevant for this contract
