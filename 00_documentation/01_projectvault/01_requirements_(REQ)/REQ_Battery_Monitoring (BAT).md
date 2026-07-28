---
domain: REQ
status: active
created: 2026-07-28
last-verified: 2026-07-28
id: REQ-BAT-000
---
## Context

Requirements on the battery monitoring chain of the module
[[ARC_Battery_Monitoring]] (ARC-BAT-001): recording pack telemetry into a
log and making that log evaluable. Covers the integrity of the recorded
log — sampling cadence, value range, pack identification. Excludes the
electrical behaviour of the pack itself, which is a property of
[[CMP_Battery_Pack]] (CMP-BAT-001), and excludes any statement about
runtime or ageing.

This file carries the scope token `BAT`; its requirement rows are
addressed as `REQ-BAT-NNN`, the file itself as `REQ-BAT-000`.

**Requirement line ID:** REQ-_BAT_-_NNN_ (Explanation: [[00_REQ_README]])

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source / Justification (REF/DEC) |
| ------------- | --: | ------- | -------------------- | -------------------------------- |
| M | 001 | While logging is active, the battery monitor shall record consecutive samples without a gap larger than twice the nominal sample interval. | Pass if the evaluation reports a maximum sample gap at or below twice the nominal interval declared in the log header. | [[DEC_Battery_Log_Acceptance_Check]] (DEC-BAT-001) |
| M | 002 | The battery monitor shall record every pack voltage sample within the operating range of the DC power contract. | Pass if every recorded voltage lies inside the operating range declared in [[IFC_PWR_DC_LiPo_Pack]] (IFC-BAT-001). | [[DEC_Battery_Log_Acceptance_Check]] (DEC-BAT-001) |
| M | 003 | The battery monitor shall record the manufacturer and the model designation of the sampled pack in the log header. | Pass if the evaluation finds a non-empty manufacturer and a non-empty model designation in the log header. | [[DEC_Battery_Log_Acceptance_Check]] (DEC-BAT-001) |
