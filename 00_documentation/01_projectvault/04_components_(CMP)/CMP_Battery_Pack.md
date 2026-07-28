---
domain: CMP
status: active
created: 2026-07-28
last-verified: 2026-07-28
id: CMP-BAT-001
---
## Source(s)

- Design values below are reported by the pack itself through the Linux
  power supply class; unit convention (microvolts, microwatt-hours)
  documented at https://www.kernel.org/doc/html/latest/power/power_supply_class.html
- A manufacturer datasheet for this pack is not available to the project.
  Every value in this profile therefore names the pack's own reported
  data as its source, and no value is stated that the pack does not
  report.

## Context

Rechargeable lithium-polymer battery pack of the host machine, and the
supply endpoint of [[IFC_PWR_DC_LiPo_Pack]] (IFC-BAT-001) inside the
module [[ARC_Battery_Monitoring]] (ARC-BAT-001). It is a leaf component:
the project does not decompose it further and documents no internals.
The telemetry recorded from it is evaluated in
[[TAE_Battery_Log_Acceptance]] (TAE-BAT-001).

## General Overview

| Attribute            | Value                                    |
| -------------------- | ---------------------------------------- |
| Type                 | Battery pack                             |
| Manufacturer         | Sunwoda                                  |
| Model                | 5B10W13975                               |
| Revision/Variant     | not reported by the pack                 |
| Technology           | Li-poly                                  |
| Design voltage       | 15.44 V                                  |
| Design energy        | 57 Wh                                    |
