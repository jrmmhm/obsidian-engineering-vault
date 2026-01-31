## Context
This architecture file describes the Data Acquisition Module as a complete, traceable system. ARC files are the central hub connecting requirements, decisions, components, interfaces, implementation, and verification.

---

## Module Scope

**Includes:**
- Sensor interface (analog or digital)
- Microcontroller-based data acquisition
- Circular buffer for local storage
- UART/USB communication to host
- Timestamp generation

**Excludes:**
- Sensor calibration algorithms (handled in separate module)
- Long-term data storage (handled by host system)
- Real-time control loops (separate module)

**Related Modules:**
- None (this is a standalone example module)
- In a real project, this might connect to: Power Supply Module, Communication Module, User Interface Module

---

## Requirements (Files)

- [[REQ_data_acquisition_example_(DAQ)]]: External requirements.

---

## Decisions (Files)

List of design decisions that shaped this module:

- [[DEC_buffer_strategy_example]]: Circular buffer with 1000-point capacity chosen for predictable memory usage
  - **Impact:** Implementation uses fixed-size ring buffer, oldest data may be lost if consumer is slow

---

## Components (Files)

Direct components forming this module:

- [[CMP_microcontroller_example]]: Processes sensor data, manages buffer, handles communication
  - **Role:** Central controller, runs firmware, provides ADC and UART peripherals

- [[CMP_generic_sensor_example]]: Measures physical quantity (temperature, pressure, etc.)
  - **Role:** Data source, converts physical value to electrical signal

---

## Interfaces

Interface table showing connections between components:

| Interface (IFC) | Endpoint A | Endpoint B | Context |
| --- | --- | --- | --- |
| [[IFC_sensor_interface_example]] | [[CMP_generic_sensor_example]] | [[CMP_microcontroller_example]] | Analog or digital signal transfer at 10 Hz |

**Notes:**
- In a real project with more components, this table would have multiple rows
- Each row represents a point-to-point connection
- Context describes purpose (not full protocol - see IFC file for details)

---

## Implementation (Files)

Implementation artifacts realizing this module:

- [[IMP_firmware_structure_example]]: Firmware implementing sampling, buffering, and communication
  - **What is realized:** Main control loop, sensor driver, circular buffer, UART handler
  - **Location:** `20_software/data_acquisition_firmware/`

**Hardware Files (Example):**
- PCB schematic: `10_hardware/13_PCB/data_acquisition_board/schematic.pdf`
- PCB layout: `10_hardware/13_PCB/data_acquisition_board/layout.kicad_pcb`
- BOM: `40_procurement/47_BOM/data_acquisition_board_BOM.xlsx`

---

## Verification Table (Allocation + Verification)

This table is the **heart of traceability**: it allocates requirements to specific components/interfaces and links to verification evidence.

| REQ-ID | Requirement Summary | Allocated To | Verification Method | Evidence (TAE) | Status |
| --- | --- | --- | --- | --- | --- |
| REQ-DAQ-001 | Acquire at ≥10 Hz | [[IMP_firmware_structure_example]] | Test: Logic analyzer timing measurement | [[TAE_acquisition_rate_test_example]] | PASS ✓ |
| REQ-DAQ-002 | Timestamp accuracy ±10 ms | [[IMP_firmware_structure_example]] | Test: Compare to reference clock | TAE_timestamp_accuracy_test_example (placeholder) | TBD |
| REQ-DAQ-003 | Buffer 1000+ points | [[IMP_firmware_structure_example]] | Code Review + Unit Test | Unit test in firmware repo | PASS ✓ |
| REQ-DAQ-004 | Real-time visualization | Host software (external) | Demonstration | Demo video (optional) | N/A |

**Status Legend:**
- **PASS:** Requirement verified and satisfied
- **TBD:** Verification planned but not yet executed
- **N/A:** Not applicable or optional requirement

**Interpretation:**
- Every requirement appears in this table (traceability)
- Each requirement is allocated to a specific implementation
- Each requirement has a verification method defined
- Evidence is linked (TAE file) or referenced

---

## System Diagram (Example)

```
┌─────────────────────────────────────────────────────────────┐
│                  Data Acquisition Module                    │
│                                                             │
│  ┌──────────────┐         ┌──────────────────────────────┐  │
│  │   Sensor     │ Analog/ │   Microcontroller            │  │
│  │              │ Digital │                              │  │
│  │ - Temp       │ ────────> ADC / I2C Input              │  │
│  │ - Pressure   │         │                              │  │
│  │ - Position   │         │  ┌───────────────────────┐   │  │
│  └──────────────┘         │  │  Main Control Loop    │   │  │
│                           │  │  - Sample at 10 Hz    │   │  │
│                           │  │  - Timestamp          │   │  │
│  Power: 5V via USB        │  └───────────────────────┘   │  │
│                           │                              │  │
│                           │  ┌───────────────────────┐   │  │
│                           │  │  Circular Buffer      │   │  │
│                           │  │  - 1000 points        │   │  │
│                           │  │  - Ring buffer logic  │   │  │
│                           │  └───────────────────────┘   │  │
│                           │                              │  │
│                           │  ┌───────────────────────┐   │  │
│                           │  │  UART Transmitter     │   │  │
│                           │  │  - 115200 baud        │   │  │
│                           │  └───────────────────────┘   │  │
│                           │            │                 │  │
│                           └────────────┼─────────────────┘  │
│                                        │ USB                │
└────────────────────────────────────────┼────────────────────┘
                                         │
                                         v
                              ┌──────────────────┐
                              │   Host PC        │
                              │ - Serial Monitor │
                              │ - Data Logging   │
                              │ - Plotting       │
                              └──────────────────┘
```

**Diagram Source:** Created as text (ASCII art) for portability
- In a real project, use draw.io, PowerPoint, or CAD tool
- Save as: `02_documents/03_architecture_(ARC)/data_acquisition_block_diagram.pdf`

---

## Operation and Usage

**Quick Start:** See [[OAU_quick_start_guide_example]]

**Typical Workflow:**
1. Connect sensor to board
2. Connect board to PC via USB
3. Open serial terminal (115200 baud)
4. System automatically starts acquiring at 10 Hz
5. Data appears in terminal and is buffered locally
6. (Optional) Run Python logging script to save to CSV

**Maintenance:** See weekly/monthly checks in [[OAU_quick_start_guide_example]]

---

## References

External knowledge used in this module:

- [[REF_adc_fundamentals_example]]: ADC resolution, sampling theory, accuracy
  - **Why relevant:** Informs sensor interface design and component selection

---

## Design Rationale Summary

**Why 10 Hz sampling rate?**
- Balances responsiveness vs. data volume
- Adequate for slowly-changing sensors (temperature, pressure)
- Nyquist theorem: captures signals up to 5 Hz

**Why circular buffer?**
- Predictable memory footprint (embedded-friendly)
- System never stops (unlike linear buffer that fills up)
- Trade-off: May lose oldest data if consumer slow (acceptable for real-time monitoring)

**Why UART communication?**
- Simple, widely supported
- No drivers needed on host (built into all PCs)
- Adequate bandwidth for 10 Hz data rate
- Easy to debug (human-readable text)

---

## Future Enhancements (Out of Scope)

**Not included in this example, but common extensions:**
- SD card logging (local storage without host)
- WiFi/Bluetooth wireless communication
- Multi-channel acquisition (multiple sensors)
- Automatic sensor calibration
- Data compression before transmission

---

## Related

- **Requirements:** [[REQ_data_acquisition_example_(DAQ)]]
- **Decisions:** [[DEC_buffer_strategy_example]]
- **Components:** [[CMP_microcontroller_example]], [[CMP_generic_sensor_example]]
- **Interfaces:** [[IFC_sensor_interface_example]]
- **Implementation:** [[IMP_firmware_structure_example]]
- **Testing:** [[TAE_acquisition_rate_test_example]]
- **Operation:** [[OAU_quick_start_guide_example]]
- **References:** [[REF_adc_fundamentals_example]]

---

## Notes

**This is an EXAMPLE architecture file** demonstrating the structure and linkages. In a real project:
- Replace with actual module name and scope
- Populate verification table with all requirements (not just 4)
- Add actual system diagrams (block diagram, signal flow, state machine)
- Include photos of hardware (if physical module)
- Link to actual test results (all TAE files)
- Add lessons learned section (after project completion)

**For New Users:**
This file is the **starting point** for understanding the module. Follow the links to:
1. Understand requirements (REQ files)
2. See why decisions were made (DEC files)
3. Find component details (CMP files)
4. Locate source code (IMP files)
5. Check verification status (TAE files)
