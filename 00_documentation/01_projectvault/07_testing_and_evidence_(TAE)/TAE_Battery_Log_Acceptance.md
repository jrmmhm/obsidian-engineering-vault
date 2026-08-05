---
domain: TAE
status: active
created: 2026-07-28
last-verified: 2026-07-28
verifies: [REQ-BAT-001, REQ-BAT-002, REQ-BAT-003]
test-object: [CMP-BAT-001, IFC-BAT-001]
id: TAE-BAT-001
---
## Context

Acceptance check of a recorded battery telemetry log of the module
[[ARC_Battery_Monitoring]] (ARC-BAT-001) against all three requirements
of [[REQ_Battery_Monitoring (BAT)]] (REQ-BAT-000). The check decides
whether the recorded log is usable, not how the pack behaves
electrically.

The run is paired with a negative control: the same evaluator applied to
a deliberately altered copy of the log, which must fail every check. A
verification whose test cannot fail proves nothing, so both runs are
recorded here.

## Test Conditions

- Test object: [[CMP_Battery_Pack]] (CMP-BAT-001), read through the
  contract [[IFC_PWR_DC_LiPo_Pack]] (IFC-BAT-001)
- Test setup: host machine on AC power, pack at 80 percent, reported
  status "Not charging"; no external instrument involved
- Recording: 20 samples at 0.25 s nominal interval, written by the
  collector described in
  [[IMP_Battery_Log_Evaluation]] (IMP-BAT-001)
- Evaluation: the evaluator described in the same note, run once against
  the recorded log and once against the negative control
- Prerequisites: none beyond a Python 3 interpreter; both scripts use
  only the standard library

## References

_External artifacts that support or supplement the test. Only file paths
relative from project folder. Do not copy content._

- Recorded log: 30_testdata/31_testdata_raw/2026-07-28_battery_monitoring/battery_log.csv
- Campaign metadata: 30_testdata/31_testdata_raw/2026-07-28_battery_monitoring/metadata.txt
- Negative control: 30_testdata/32_testdata_processed/2026-07-28_battery_monitoring/battery_log_negative_control.csv

## Limitations

- The pack voltage did not change over the run. The battery gauge updates
  slowly, so the voltage criterion is exercised against a constant value
  and this run says nothing about behaviour under a changing load.
- One machine, one pack, one run. The result characterises the logging
  chain, not the population of packs.
- The negative control is a hand-derived file, not a second measurement.
  It proves that the three checks can fail; it proves nothing about the
  pack.

## Evidence

Recorded log, command and verbatim output:

```
$ python3 20_software/data_analysis/eval_battery_log.py \
    30_testdata/31_testdata_raw/2026-07-28_battery_monitoring/battery_log.csv
log: 30_testdata/31_testdata_raw/2026-07-28_battery_monitoring/battery_log.csv
samples: 20
REQ-BAT-001  PASS  max sample gap 0.259 s, limit 0.500 s (2 x nominal 0.25 s)
REQ-BAT-002  PASS  recorded 16.668 .. 16.668 V, contract 12.00 .. 17.40 V
REQ-BAT-003  PASS  pack identification present: Sunwoda / 5B10W13975
VERDICT: PASS (3/3)
$ echo $?
0
```

Negative control, same evaluator, verbatim output:

```
$ python3 20_software/data_analysis/eval_battery_log.py \
    30_testdata/32_testdata_processed/2026-07-28_battery_monitoring/battery_log_negative_control.csv
log: 30_testdata/32_testdata_processed/2026-07-28_battery_monitoring/battery_log_negative_control.csv
samples: 6
REQ-BAT-001  FAIL  max sample gap 0.900 s, limit 0.500 s (2 x nominal 0.25 s)
REQ-BAT-002  FAIL  recorded 16.668 .. 21.500 V, contract 12.00 .. 17.40 V
REQ-BAT-003  FAIL  missing pack identification: manufacturer, model_name
VERDICT: FAIL (0/3)
$ echo $?
1
```

## Conclusion

All three requirements are met by the recorded log. The negative control
fails all three, so each check is falsifiable rather than tautological.
Within the limitations above, the logging chain of the module is accepted.
