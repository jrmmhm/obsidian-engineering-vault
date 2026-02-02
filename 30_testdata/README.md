# TEST DATA – Storage and Naming Conventions

Test data is the central repository for all experimental measurements, sensor logs, and analysis results. This folder follows strict naming conventions to ensure data is findable, traceable, and properly organized.

**Key Principles:**
- Filenames are the primary metadata source
- Date-based organization (YYYY-MM-DD format)
- Campaign/test-based grouping
- Clear separation: raw data (immutable) vs. processed data (derived)
- Link to documentation (TAE files document what the data means)

---

## Folder Structure

```
30_testdata/
├── 31_testdata_raw/              ← Unmodified sensor output
│   └── YYYY-MM-DD_campaign_name/
│       ├── sensor_log_01.csv
│       ├── sensor_log_02.csv
│       └── metadata.txt
│
└── 32_testdata_processed/        ← Cleaned, analyzed, plotted
    └── YYYY-MM-DD_campaign_name/
        ├── cleaned_data.csv
        ├── analysis.xlsx
        └── plots/
            ├── plot_01.png
            └── plot_02.png
```

---

## 31_testdata_raw (Raw Data)

**Content:**
- Unmodified sensor outputs (CSV, binary, logs)
- Oscilloscope captures
- Logic analyzer traces
- Camera images/videos from experiments
- Any data directly from measurement equipment

**Key Rule:** **IMMUTABLE** - Never edit raw data files. If corrections are needed, copy to `32_testdata_processed/` and document changes.

### Naming Convention: Campaign Folders

**Format:** `YYYY-MM-DD_campaign_name/`

**Variables:**
- `YYYY-MM-DD` = Date of test/measurement (ISO 8601 format)
- `campaign_name` = Descriptive name (lowercase, underscores, no spaces)

**Examples:**
- `2025-01-15_voltage_sweep_test/`
- `2025-01-20_temperature_calibration/`
- `2025-02-01_long_term_stability/`
- `2025-02-10_vibration_analysis/`

### Naming Convention: Data Files Inside Campaign

**Format:** `descriptor_sequence.ext`

**Guidelines:**
- Use descriptive names indicating what was measured
- Include sequence number if multiple files (01, 02, ...)
- Use standard extensions (.csv, .txt, .bin, .sal, .jpg, etc.)

**Examples:**
```
2025-01-15_voltage_sweep_test/
├── adc_readings_0v_to_5v.csv
├── scope_capture_01.csv
├── scope_capture_02.csv
├── test_photo_setup.jpg
└── metadata.txt
```

### Metadata File (Recommended)

Each campaign folder should include `metadata.txt` with:
```
Test Campaign: Voltage Sweep Test
Date: 2025-01-15
Engineer: [Your Name]
Equipment: DMM Fluke 87V, Scope Rigol DS1054Z
Purpose: Characterize ADC linearity from 0V to 5V
Conditions: Room temp 22°C, Supply 5.0V ±0.01V
Results: See 32_testdata_processed/2025-01-15_voltage_sweep_test/
Documentation: See 07_testing_and_evidence_(TAE)/TAE_adc_linearity_test.md
```

---

## 32_testdata_processed (Processed Data)

**Content:**
- Cleaned/filtered data (outliers removed, noise filtered)
- Calculated results (statistics, averages, fits)
- Plots and visualizations
- Analysis spreadsheets
- Reports generated from raw data

**Key Rule:** Always reference the source raw data. Every processed file should trace back to its raw origin.

### Naming Convention: Campaign Folders

**Format:** `YYYY-MM-DD_campaign_name/` (matches raw data folder)

**Linkage:** Use same date and name as corresponding raw data folder for easy cross-reference.

### Naming Convention: Processed Files

**Format:** `descriptor_processing_type.ext`

**Processing Types (Recommendations):**
- `cleaned` = Outliers removed, noise filtered
- `analyzed` = Statistical analysis applied
- `fitted` = Curve fitting, regression
- `summary` = Aggregated results

**Examples:**
```
2025-01-15_voltage_sweep_test/
├── adc_readings_cleaned.csv
├── linearity_analysis.xlsx
├── adc_linearity_summary.txt
└── plots/
    ├── adc_linearity_plot.png
    ├── residuals_plot.png
    └── histogram_errors.png
```

### Subfolder: plots/

For campaigns with multiple visualizations, create `plots/` subfolder:

**Naming Convention:** `plot_description.png` (or .pdf, .svg)

**Examples:**
- `plot_adc_linearity.png`
- `plot_temperature_vs_time.png`
- `plot_fft_spectrum.png`

**Recommendation:** Use PNG for raster images (screenshots, photos), PDF for vector graphics (MATLAB/Python plots).

---

## File Formats

### Recommended Formats

| Data Type | Format | Reasoning |
|---|---|---|
| Tabular data | CSV | Universal, text-based, version-control friendly |
| Analysis | XLSX | Calculations, formatting, formulas |
| Plots | PNG, PDF | PNG for inclusion in docs, PDF for vector quality |
| Scope/Logic Analyzer | Vendor format + CSV export | Keep original + text export |
| Metadata | TXT, MD | Human-readable |
| Binary sensor logs | Vendor format + CSV export | Keep original + converted |

**Avoid proprietary formats** unless necessary (e.g., oscilloscope native format is OK, but also export CSV).

---

## Data Retention Policy

**Raw Data:**
- **Keep forever** or archive after project completion
- Move old campaigns to `99_archive/` if disk space needed
- Never delete without team approval

**Processed Data:**
- Can be regenerated from raw data (in theory)
- Keep for project lifetime + 1 year
- Archive or delete after verification that raw data is intact

**Recommendation:** If raw data is large (GB/TB), consider:
1. Archive to external drive or cloud storage
2. Keep processed data and small raw data samples in repo
3. Document archive location in metadata file

---

## Campaign Types (Examples)

Organize campaigns by test type:

### Calibration Tests
**Naming:** `YYYY-MM-DD_calibration_component_name/`

**Example:** `2025-01-15_calibration_temperature_sensor/`

**Purpose:** Establish sensor accuracy, generate calibration curves

**Typical Files:**
- Reference measurements vs. sensor readings
- Calibration curve (plot)
- Calibration coefficients (text file)

---

### Characterization Tests
**Naming:** `YYYY-MM-DD_characterization_parameter_name/`

**Example:** `2025-01-20_characterization_adc_linearity/`

**Purpose:** Measure component/system behavior over range of inputs

**Typical Files:**
- Sweep data (voltage, temperature, frequency, etc.)
- Performance metrics (linearity, noise, bandwidth)
- Specification compliance check

---

### Long-Term Stability Tests
**Naming:** `YYYY-MM-DD_stability_duration/`

**Example:** `2025-02-01_stability_24h/`

**Purpose:** Monitor behavior over extended time

**Typical Files:**
- Continuous log files (time series)
- Drift analysis
- Temperature/humidity logs (if environmental chamber used)

---

### Failure/Stress Tests
**Naming:** `YYYY-MM-DD_stress_test_condition/`

**Example:** `2025-02-15_stress_overvoltage/`

**Purpose:** Determine failure modes, safety margins

**Typical Files:**
- Pre-test baseline measurements
- Stress condition logs
- Post-test failure analysis photos
- Failure report

---

### Integration Tests
**Naming:** `YYYY-MM-DD_integration_test_name/`

**Example:** `2025-03-01_integration_full_system/`

**Purpose:** Verify system-level functionality

**Typical Files:**
- Multi-channel data (all sensors)
- System state logs
- Pass/fail results
- Video recording of test

---

## Traceability to Documentation

**Every test campaign should link to documentation:**

**In metadata.txt:**
```
Documentation: See 07_testing_and_evidence_(TAE)/TAE_voltage_sweep_test.md
```

**In TAE file:**
```markdown
## Test Artifacts

**Raw Data:**
`30_testdata/31_testdata_raw/2025-01-15_voltage_sweep_test/`

**Processed Data:**
`30_testdata/32_testdata_processed/2025-01-15_voltage_sweep_test/`
```

**This creates two-way traceability:**
- From data → documentation (what does this data mean?)
- From documentation → data (where is the evidence?)

---

## Example: Complete Test Campaign

### Scenario
Verify ADC linearity for data acquisition module

### Folder Structure
```
31_testdata_raw/2025-01-15_adc_linearity_test/
├── metadata.txt
├── adc_readings_0v_to_5v_run1.csv
├── adc_readings_0v_to_5v_run2.csv
├── adc_readings_0v_to_5v_run3.csv
├── reference_voltmeter_log.csv
└── test_setup_photo.jpg

32_testdata_processed/2025-01-15_adc_linearity_test/
├── combined_runs_cleaned.csv
├── linearity_analysis.xlsx
├── adc_calibration_coefficients.txt
└── plots/
    ├── adc_linearity.png
    ├── residuals.png
    └── error_histogram.png
```

### metadata.txt
```
Test Campaign: ADC Linearity Characterization
Date: 2025-01-15
Engineer: [Your Name]
Equipment:
  - DUT: Data acquisition board v1.0
  - Reference: Fluke 87V DMM (calibrated 2024-12-01)
  - Source: Keysight E3631A power supply
Purpose: Characterize ADC linearity from 0V to 5V in 100mV steps
Test Procedure:
  1. Apply voltage from 0V to 5V in 100mV steps
  2. Record ADC reading (10 samples per step)
  3. Record reference DMM reading
  4. Repeat 3 times (run1, run2, run3)
Conditions:
  - Room temperature: 22°C ± 1°C
  - Supply voltage: 5.00V ± 0.01V
  - Reference voltage: 5.00V ± 0.001V
Results:
  - Linearity: ±0.3% FSR (within spec)
  - See processed data for plots and analysis
Documentation:
  - TAE file: 07_testing_and_evidence_(TAE)/TAE_adc_linearity_test_example.md
  - Requirement: REQ-DAQ-002 (timestamp accuracy)
```

---

## Best Practices

### DO:
✓ Always include metadata.txt in campaign folders
✓ Use ISO date format (YYYY-MM-DD) for sortability
✓ Keep raw data immutable
✓ Document equipment and calibration dates
✓ Link to TAE documentation files
✓ Include photos of test setup
✓ Export proprietary formats to CSV/TXT

### DON'T:
✗ Edit raw data files directly
✗ Mix raw and processed data in same folder
✗ Use spaces or special characters in folder names
✗ Forget to document test conditions
✗ Delete data without archiving
✗ Use ambiguous file names (e.g., "data.csv", "test1.csv")

---

## Tools and Scripts

### Data Processing Scripts
Store analysis scripts in: `20_software/data_analysis/`

**Example:**
```
20_software/data_analysis/
├── process_adc_data.py      # Reads raw CSV, outputs cleaned data
├── plot_linearity.py         # Generates linearity plots
└── README.md                 # Usage instructions
```

**Link from processed data:**
```
32_testdata_processed/2025-01-15_adc_linearity_test/
└── processing_notes.txt:
    "Data processed using: 20_software/data_analysis/process_adc_data.py"
```

---

## Migration from Unorganized Data

**If you have existing unorganized test data:**

1. **Create campaign folders** based on test dates (estimate if unknown)
2. **Move data files** into appropriate folders
3. **Rename files** following conventions
4. **Create metadata.txt** retroactively (document what you remember)
5. **Update TAE files** to link to reorganized data
6. **Archive old structure** in `99_archive/` for reference

---

## Summary

**Folder Structure:**
- `31_testdata_raw/YYYY-MM-DD_campaign_name/` - Immutable raw data
- `32_testdata_processed/YYYY-MM-DD_campaign_name/` - Derived results

**Key Naming Elements:**
- ISO date (YYYY-MM-DD)
- Campaign name (lowercase, underscores)
- Descriptive file names
- Standard extensions

**Traceability:**
- metadata.txt in each campaign
- Links to TAE documentation
- Links to requirements being verified

**File Retention:**
- Raw data: Keep indefinitely
- Processed data: Can be regenerated, archive after project

---

## Related

- **Documentation:** Link test campaigns to TAE files in `07_testing_and_evidence_(TAE)/`
- **Analysis Scripts:** Store in `20_software/data_analysis/`
- **Example:** See `ARC_data_acquisition_example.md` verification table for data references
