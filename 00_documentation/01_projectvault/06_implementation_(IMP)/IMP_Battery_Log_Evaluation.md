---
domain: IMP
status: active
created: 2026-07-28
last-verified: 2026-07-28
id: IMP-BAT-001
---
## Context

Concrete realization of the battery telemetry chain of
[[ARC_Battery_Monitoring]] (ARC-BAT-001): one script that records a log
from the pack and one that decides the acceptance criteria of
[[REQ_Battery_Monitoring (BAT)]] (REQ-BAT-000) against such a log. Both
follow [[DEC_Battery_Log_Acceptance_Check]] (DEC-BAT-001) and use only
the Python standard library.

## References

External artifacts that represent or contain the implementation. Only
file paths relative from project folder. Do not copy content.

- Collector: 20_software/data_analysis/collect_battery_log.py
- Evaluator: 20_software/data_analysis/eval_battery_log.py
- Recorded log: 30_testdata/31_testdata_raw/2026-07-28_battery_monitoring/battery_log.csv
- Negative control: 30_testdata/32_testdata_processed/2026-07-28_battery_monitoring/battery_log_negative_control.csv

## Implementation

- The pack is located by scanning the power supply class for the first
  device whose `type` attribute reads `Battery`. A device index is
  deliberately not used: the enumeration order differs between machines
  and between boots, so an index would sample a different device
  elsewhere.
- Voltage and energy are read from `voltage_now` and `energy_now` and
  divided by one million, because the power supply class reports
  microvolts and microwatt-hours.
- Sample timestamps come from the monotonic clock, relative to the first
  sample, so a wall-clock adjustment during a run cannot reorder samples.
- The log header carries `manufacturer`, `model_name`, `technology`,
  `voltage_min_design`, `nominal_interval_s` and `sample_count` as `#`
  comment lines ahead of the CSV header row. Serial numbers are
  deliberately not recorded.
- The evaluator mirrors the operating range of
  [[IFC_PWR_DC_LiPo_Pack]] (IFC-BAT-001) in two constants and names that
  note as their owner; the gap limit is twice the nominal interval read
  from the log header.
- Exit code is zero only when all three requirements pass, so the check
  is usable as a continuous integration step.
