## Context
This file summarizes key concepts from external sources about ADC (Analog-to-Digital Converter) fundamentals. REF files extract relevant information from external sources without duplicating entire documents.

**Source Type:** Technical Tutorial / Application Note

**External Source Location:** `50_sources/02_paper/ADC_Fundamentals_AppNote.pdf` (example)

**Related Components:** [[CMP_microcontroller_example]]

**Used In:** [[ARC_data_acquisition_example]]

---

## Source Information

**Title:** Understanding ADC Specifications (Example)

**Author:** Analog Devices (example)

**Date:** 2020 (example)

**Document Type:** Application Note

**Why Referenced:** Explains ADC resolution, sampling rate, and accuracy - critical for sensor interfacing

---

## Key Concepts Extracted

### ADC Resolution

**Definition:** Number of discrete digital values an ADC can produce

**Formula:** Number of levels = 2^N, where N = number of bits

**Examples:**
- 8-bit ADC: 256 levels (0-255)
- 10-bit ADC: 1024 levels (0-1023)
- 12-bit ADC: 4096 levels (0-4095)

**Practical Impact:**
- Higher resolution = finer voltage steps
- 10-bit ADC with 5V reference: 5V / 1024 = 4.88 mV per step
- Sensor accuracy must match ADC resolution (no point using 0.1% sensor with 8-bit ADC)

### Sampling Rate

**Definition:** How many times per second the ADC converts analog to digital

**Units:** Samples per second (SPS) or Hertz (Hz)

**Nyquist Theorem:** Sampling rate must be at least 2× the highest frequency in signal
- Example: To capture 5 Hz signal changes, sample at ≥10 Hz

**Aliasing:** If sampling rate too low, high frequencies appear as false low frequencies

**Application to Project:**
- REQ-DAQ-001 requires 10 Hz sampling
- Adequate for slowly changing sensors (temperature, pressure)
- Inadequate for vibration or audio signals

### Conversion Time

**Definition:** Time required for one ADC conversion

**Typical Values:**
- Successive Approximation (SAR): 1-10 μs
- Sigma-Delta: 10-1000 μs (slower but higher resolution)

**Constraint:** Conversion time must be < sampling interval
- For 10 Hz sampling (100 ms interval), even slow ADCs are adequate

### ADC Accuracy and Errors

**Quantization Error:** Inherent error due to discrete levels (±½ LSB)

**Offset Error:** Constant voltage error at all input levels
- Solution: Calibration to measure and subtract offset

**Gain Error:** Slope error (range compression/expansion)
- Solution: Calibration with known reference voltages

**INL/DNL (Integral/Differential Non-Linearity):**
- Measures deviation from ideal transfer function
- Low-cost MCU ADCs: ±2-4 LSB typical
- High-precision ADCs: ±0.5 LSB

### Reference Voltage

**Purpose:** Defines the full-scale input range

**Example:** 5V reference means:
- 0V input → ADC output 0
- 5V input → ADC output 1023 (10-bit)
- 2.5V input → ADC output 512

**Stability Critical:**
- 1% reference error → 1% measurement error
- Use stable reference IC (not just MCU supply) for precision

---

## Application to This Project

### ADC Selection Criteria (from this reference)
1. **Resolution:** 10-bit adequate for ±1% sensor accuracy
2. **Sampling Rate:** 10 Hz meets requirement, any MCU ADC sufficient
3. **Reference:** Internal reference acceptable if ±2% accuracy OK, external reference for ±0.5%

### Design Decisions Informed
- [[DEC_buffer_strategy_example]]: Buffer size of 1000 points = 100 seconds of data at 10 Hz
- Component selection: 10-bit ADC in [[CMP_microcontroller_example]] is sufficient

### Testing Implications
- [[TAE_acquisition_rate_test_example]]: Verify 10 Hz sampling rate
- Timestamp accuracy: Should be better than ADC conversion time (μs vs. ms)

---

## Key Equations

**ADC Output Calculation:**
```
ADC_Output = (Input_Voltage / Reference_Voltage) × (2^N - 1)
```

**Voltage from ADC Reading:**
```
Input_Voltage = (ADC_Output / (2^N - 1)) × Reference_Voltage
```

**Quantization Error (max):**
```
Max_Error = Reference_Voltage / 2^(N+1)  (i.e., ±½ LSB)
```

**Effective Number of Bits (ENOB):**
Accounts for real-world noise and non-idealities
```
ENOB = (SINAD - 1.76) / 6.02
```
Where SINAD = Signal-to-Noise And Distortion ratio in dB

---

## Figures and Tables (Not Reproduced)

**Reference:** See original document in `50_sources/02_paper/ADC_Fundamentals_AppNote.pdf`

**Key Figures:**
- Figure 3: ADC transfer function showing quantization steps
- Figure 5: Aliasing demonstration (sampling below Nyquist rate)
- Table 2: Comparison of ADC architectures (SAR, Sigma-Delta, Flash)

---

## Related

- **Architecture:** [[ARC_data_acquisition_example]]
- **Components:** [[CMP_microcontroller_example]], [[CMP_generic_sensor_example]]
- **Interface:** [[IFC_sensor_interface_example]]
- **Testing:** [[TAE_acquisition_rate_test_example]]

---

## Notes

**This is an EXAMPLE reference file.** In a real project:
- Replace with actual external document details
- Cite specific page numbers and sections
- Add direct quotes (with quotation marks) for critical definitions
- Include copyright notice from source document
- Link to actual file in 50_sources/
