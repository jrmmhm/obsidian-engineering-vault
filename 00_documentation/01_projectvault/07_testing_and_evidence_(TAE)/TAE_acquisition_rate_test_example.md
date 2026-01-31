## Context
This file documents verification evidence for the data acquisition rate requirement. TAE files contain project-specific test results and measurements.

**Test Object:** [[ARC_data_acquisition_example]]

**Requirement Verified:** [[REQ_data_acquisition_example_(DAQ)]] REQ-DAQ-001 (10 Hz minimum acquisition rate)

**Test Date:** 2025-01-30 (example date)

**Test Engineer:** Template Example

---

## Test Objective
Verify that the data acquisition system samples sensor data at a rate of 10 Hz or higher during continuous operation.

---

## Test Setup

**Hardware:**
- Data acquisition board with [[CMP_microcontroller_example]]
- [[CMP_generic_sensor_example]] connected to ADC input
- Logic analyzer connected to GPIO pin (toggled each sample)
- USB connection to host PC for data logging

**Software:**
- Firmware version: v1.0.0-example
- Logic analyzer software: Saleae Logic 2
- Data logging script: Python 3.9 with pyserial

**Test Conditions:**
- Room temperature: 22°C
- Supply voltage: 5.0V ± 0.1V
- Test duration: 60 seconds continuous operation

---

## Test Procedure

1. Flash firmware to microcontroller (see [[IMP_firmware_structure_example]])
2. Connect logic analyzer to GPIO pin configured as "sample trigger"
3. Power on system and verify LED heartbeat
4. Start logic analyzer capture (60 second duration)
5. Start data logging script to capture UART output
6. Wait for test completion
7. Analyze captured data

**Expected Result:**
- Logic analyzer shows pulses spaced ≤100 ms apart (10 Hz = 100 ms period)
- UART log shows timestamps incrementing by ≤100 ms

---

## Test Results

### Logic Analyzer Capture

**File Location:** `30_testdata/32_testdata_processed/2025-01-30_acquisition_rate_test/logic_capture.sal`

**Analysis:**
- Total samples captured: 612 samples in 60.02 seconds
- Average sampling rate: **10.19 Hz** ✓ (meets ≥10 Hz requirement)
- Minimum interval: 97.8 ms
- Maximum interval: 102.3 ms
- Standard deviation: 1.2 ms

**Jitter Analysis:**
- 95% of intervals within 98-102 ms (±2%)
- No missed samples detected
- No double-samples detected

**Screenshot:** `02_documents/07_testing_and_evidence_(TAE)/logic_analyzer_10hz_verification.png`

### UART Data Log

**File Location:** `30_testdata/31_testdata_raw/2025-01-30_acquisition_rate_test/uart_log.txt`

**Sample excerpt:**
```
[000.000] Sample 0: ADC=512
[000.098] Sample 1: ADC=513
[000.198] Sample 2: ADC=514
[000.298] Sample 3: ADC=515
...
[060.000] Sample 612: ADC=525
```

**Analysis:**
- Timestamps confirm ~100 ms intervals
- No timestamp reversals (monotonic increasing)
- All samples received (no gaps in sequence numbers)

---

## Pass/Fail Criteria

| Criterion | Required | Measured | Status |
|---|---|---|---|
| Minimum sampling rate | ≥10 Hz | 10.19 Hz | **PASS** ✓ |
| Maximum jitter | ≤5 ms | 2.3 ms | **PASS** ✓ |
| No dropped samples | 0 drops | 0 drops | **PASS** ✓ |

**Overall Result: PASS** ✓

---

## Observations

**Positive:**
- Sampling rate stable and consistent
- Low jitter indicates good timer configuration
- No buffer overruns detected

**Issues:**
- Slight rate deviation (+1.9%) likely due to internal oscillator tolerance
- Could improve with external crystal (optional enhancement)

**Recommendations:**
- Current implementation satisfies requirement
- If tighter timing needed, consider external crystal or GPS time sync

---

## Test Artifacts

**Raw Data:**
- Logic analyzer file: `30_testdata/31_testdata_raw/2025-01-30_acquisition_rate_test/logic_capture.sal`
- UART log: `30_testdata/31_testdata_raw/2025-01-30_acquisition_rate_test/uart_log.txt`

**Processed Data:**
- Analysis spreadsheet: `30_testdata/32_testdata_processed/2025-01-30_acquisition_rate_test/timing_analysis.xlsx`
- Histogram plot: `30_testdata/32_testdata_processed/2025-01-30_acquisition_rate_test/interval_histogram.png`

**Documentation:**
- Screenshots: `02_documents/07_testing_and_evidence_(TAE)/logic_analyzer_10hz_verification.png`
- Test report PDF: `02_documents/07_testing_and_evidence_(TAE)/report__acquisition_rate_test__2025-01-30__rev-1.pdf`

---

## Related

- **Requirement:** [[REQ_data_acquisition_example_(DAQ)]] REQ-DAQ-001
- **Architecture:** [[ARC_data_acquisition_example]]
- **Implementation:** [[IMP_firmware_structure_example]]
- **Other Tests:** [[TAE_timestamp_accuracy_test_example]]

---

## Notes

**This is an EXAMPLE test file.** In a real project:
- Replace with actual test date and engineer name
- Include real screenshots and plots
- Link to actual test data files
- Document any deviations or anomalies
- Add retest information if initial test failed
