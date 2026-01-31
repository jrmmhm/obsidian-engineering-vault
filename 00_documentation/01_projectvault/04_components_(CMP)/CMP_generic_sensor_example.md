## Context
This component represents a generic sensor interface. In a real project, this would reference a specific sensor (e.g., temperature sensor, pressure transducer, encoder).

**Component Type:** Sensor (Input Device)

**Used In:** [[ARC_data_acquisition_example]]

---

## Component Overview

**Generic Sensor Characteristics:**
- **Function:** Converts physical quantity (temperature, pressure, position, etc.) to electrical signal
- **Output Type:** Analog voltage (0-5V) or Digital (I2C, SPI, UART)
- **Interface:** Standard communication protocol
- **Power:** Typically 3.3V or 5V supply

---

## Key Specifications (Template)

| Parameter | Value | Notes |
|---|---|---|
| Measurement Range | TBD | Example: -40°C to +125°C |
| Accuracy | TBD | Example: ±0.5% |
| Output Type | Analog or Digital | Project-specific |
| Supply Voltage | 3.3V or 5V | Match system voltage |
| Update Rate | ≥10 Hz | Must satisfy REQ-DAQ-001 |

---

## Interface Requirements

**Physical:**
- Connector type: TBD (e.g., JST-XH, screw terminal)
- Pinout: VCC, GND, Signal (analog) or VCC, GND, SDA, SCL (I2C)

**Electrical:**
- Signal level compatible with microcontroller ADC input
- Protection: ESD protection recommended
- Filtering: Low-pass filter if noisy environment

---

## Selection Criteria (Examples)

When choosing a specific sensor for your project:
1. **Measurement range** covers expected operating conditions
2. **Accuracy** meets requirement tolerance
3. **Output type** matches available microcontroller interfaces
4. **Update rate** ≥10 Hz (per REQ-DAQ-001)
5. **Availability** and lead time acceptable
6. **Cost** within project budget

---

## Example Specific Sensors (Replace in Real Project)

- **Temperature:** DS18B20 (digital, 1-wire)
- **Pressure:** MPX5700AP (analog, 0-5V)
- **Position:** Bourns 3386 potentiometer (analog)
- **Current:** ACS712 Hall-effect sensor (analog)

---

## Related

- **Architecture:** [[ARC_data_acquisition_example]]
- **Interface:** [[IFC_sensor_interface_example]]
- **Datasheet Reference:** [[REF_sensor_datasheet_example]]
- **Testing:** [[TAE_sensor_verification_example]]

---

## Notes

**This is a TEMPLATE component file.** In a real project:
- Replace "Generic Sensor" with specific part number
- Fill in actual specifications from datasheet
- Add photos of physical component
- Link to vendor datasheet in 50_sources/
