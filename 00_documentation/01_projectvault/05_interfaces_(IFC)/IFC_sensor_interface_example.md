## Context
This interface defines the communication contract between the sensor and microcontroller. This example shows how interfaces document protocols, not just physical connections.

**Interface Type:** Sensor Data Acquisition

**Endpoints:** [[CMP_generic_sensor_example]] ↔ [[CMP_microcontroller_example]]

**Used In:** [[ARC_data_acquisition_example]]

---

## Interface Overview

**Purpose:** Transfer sensor measurement from sensor to microcontroller

**Direction:** Sensor (output) → Microcontroller (input)

**Update Rate:** Minimum 10 Hz (per REQ-DAQ-001)

---

## Physical Layer

### Option A: Analog Interface (Example)

| Signal | Direction | Type | Range | Notes |
|---|---|---|---|---|
| VCC | MCU → Sensor | Power | 3.3V or 5V | Sensor supply |
| GND | Common | Ground | 0V | Common reference |
| SIGNAL | Sensor → MCU | Analog | 0-5V | Measurement output |

**Connector:** 3-pin JST-XH or screw terminal

**Cable:** Shielded twisted pair (if length > 1m or noisy environment)

### Option B: Digital Interface (Example - I2C)

| Signal | Direction | Type | Notes |
|---|---|---|---|
| VCC | MCU → Sensor | Power | 3.3V or 5V |
| GND | Common | Ground | Common reference |
| SDA | Bidirectional | I2C Data | Pull-up required (4.7kΩ) |
| SCL | MCU → Sensor | I2C Clock | Pull-up required (4.7kΩ) |

**I2C Address:** 0x48 (example, sensor-specific)

**Clock Speed:** 100 kHz (standard mode) or 400 kHz (fast mode)

---

## Protocol (Digital Interface Example)

### Read Sequence (I2C)
1. MCU sends START condition
2. MCU sends sensor address + WRITE bit
3. MCU sends register address (measurement register)
4. MCU sends REPEATED START
5. MCU sends sensor address + READ bit
6. Sensor sends 2 bytes (measurement data, MSB first)
7. MCU sends STOP condition

### Timing
- **Polling Rate:** 10 Hz minimum (100 ms interval)
- **Response Time:** Sensor responds within 10 ms (typical)
- **Timeout:** 50 ms (MCU aborts if no response)

---

## Data Format

### Analog Interface
- **Raw ADC Value:** 0-1023 (10-bit ADC example)
- **Conversion:** Physical_Value = (ADC_Value / 1023) × Sensor_Range
- **Example:** If sensor outputs 0-5V for 0-100°C:
  - ADC reads 512 → 2.5V → 50°C

### Digital Interface
- **Data:** 16-bit signed integer (example)
- **Resolution:** 0.01 units per LSB (sensor-specific)
- **Example:** Raw value 2500 → 25.00°C

---

## Error Handling

**Analog Interface:**
- Out-of-range detection: ADC value < 10 or > 1013 (indicates disconnect/short)
- Filtering: Moving average (N=5) to reduce noise

**Digital Interface:**
- Communication timeout: No response within 50 ms → retry up to 3 times
- Checksum validation: If sensor provides CRC, validate each reading
- I2C bus error: If NACK received, log error and retry

---

## Performance Requirements

| Requirement | Value | Verification |
|---|---|---|
| Update Rate | ≥10 Hz | [[TAE_acquisition_rate_test_example]] |
| Latency | <10 ms | Measure time from trigger to data available |
| Accuracy | ±0.5% FS | Compare against calibrated reference |

---

## Related

- **Architecture:** [[ARC_data_acquisition_example]]
- **Components:** [[CMP_generic_sensor_example]], [[CMP_microcontroller_example]]
- **Implementation:** [[IMP_sensor_driver_example]]
- **Testing:** [[TAE_interface_verification_example]]

---

## Notes

**This is a TEMPLATE interface file.** In a real project:
- Choose specific physical layer (analog, I2C, SPI, UART, etc.)
- Fill in actual timing diagrams
- Add oscilloscope captures of signal traces (save in 02_documents/)
- Document actual sensor protocol from datasheet
- Include error codes and fault conditions
