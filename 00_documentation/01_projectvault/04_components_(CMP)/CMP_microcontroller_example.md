## Context
This component represents a generic microcontroller that processes sensor data. In a real project, this would reference a specific MCU (e.g., STM32, Arduino, Raspberry Pi Pico).

**Component Type:** Controller (Processing Unit)

**Used In:** [[ARC_data_acquisition_example]]

---

## Component Overview

**Microcontroller Role:**
- **Function:** Read sensor data, buffer it, and transmit to host system
- **Processing:** Timestamp generation, data buffering, communication handling
- **Interfaces:** ADC inputs (for analog sensors), Digital I/O (for digital sensors), UART/USB (for data transmission)

---

## Key Specifications (Template)

| Parameter | Value | Notes |
|---|---|---|
| Architecture | ARM Cortex-M / AVR / etc. | Project-specific |
| Clock Speed | ≥48 MHz recommended | Needed for 10+ Hz multi-channel sampling |
| RAM | ≥8 KB | Must fit circular buffer (1000 points) |
| Flash | ≥32 KB | Program + data logging |
| ADC Channels | ≥1 | Match number of analog sensors |
| ADC Resolution | ≥10 bit | Adequate for most sensors |
| Communication | UART/USB/SPI | Host connection |

---

## Resource Allocation

**For Data Acquisition Module:**
- **Circular Buffer:** 1000 points × 4 bytes = 4 KB RAM
- **Program Code:** ~10-20 KB Flash
- **Communication Buffer:** ~1 KB RAM
- **Stack/Heap:** ~2 KB RAM
- **Total Estimate:** 7+ KB RAM, 15+ KB Flash

---

## Interface Requirements

**Sensor Interface:**
- ADC inputs with configurable sampling rate
- I2C/SPI for digital sensors (optional)
- GPIO for sensor power control (optional)

**Host Interface:**
- UART or USB for data transmission
- Minimum baud rate: 115200 bps (for 10 Hz × multiple channels)

**Power:**
- Supply voltage: 3.3V or 5V
- Low-power sleep modes (optional, for battery operation)

---

## Example Specific Microcontrollers (Replace in Real Project)

- **Low-cost:** Arduino Nano (ATmega328P, 8-bit)
- **Mid-range:** STM32F103 (ARM Cortex-M3, 32-bit)
- **High-performance:** ESP32 (Dual-core, WiFi/Bluetooth)
- **Prototyping:** Raspberry Pi Pico (RP2040, dual Cortex-M0+)

---

## Selection Criteria

When choosing a specific MCU for your project:
1. **ADC channels** match number of sensors
2. **RAM** sufficient for buffer size
3. **Clock speed** supports required sampling rate
4. **Communication** interfaces available (UART/USB/WiFi)
5. **Development tools** available (IDE, debugger)
6. **Team familiarity** with architecture

---

## Related

- **Architecture:** [[ARC_data_acquisition_example]]
- **Implementation:** [[IMP_firmware_structure_example]]
- **Testing:** [[TAE_mcu_verification_example]]

---

## Notes

**This is a TEMPLATE component file.** In a real project:
- Replace "Generic Microcontroller" with specific part number
- Fill in actual specifications from datasheet
- Add schematic symbol and PCB footprint references
- Link to reference manual in 50_sources/
- Document pin assignments and resource usage
