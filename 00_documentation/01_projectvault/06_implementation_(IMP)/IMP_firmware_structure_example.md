## Context
This file provides links to actual implementation artifacts (source code, CAD files, etc.) for the data acquisition module. IMP files are SHORT and point to real artifacts, they do NOT duplicate code documentation.

**Module:** Data Acquisition Firmware

**Related Architecture:** [[ARC_data_acquisition_example]]

---

## Source Code Location

**Primary Repository:** `20_software/data_acquisition_firmware/`

**Repository Structure:**
```
20_software/data_acquisition_firmware/
├── src/
│   ├── main.c                    # Entry point, initialization
│   ├── sensor_driver.c           # Sensor interface implementation
│   ├── circular_buffer.c         # Ring buffer implementation
│   └── uart_comm.c               # Host communication
├── include/
│   ├── sensor_driver.h
│   ├── circular_buffer.h
│   └── uart_comm.h
├── test/
│   └── test_circular_buffer.c    # Unit tests
├── platformio.ini                # Build configuration
└── README.md                     # Build instructions
```

**Key Files:**
- **Circular Buffer:** `src/circular_buffer.c` implements [[DEC_buffer_strategy_example]]
- **Sensor Driver:** `src/sensor_driver.c` implements [[IFC_sensor_interface_example]]
- **Main Loop:** `src/main.c` orchestrates 10 Hz sampling (per REQ-DAQ-001)

---

## Hardware Design Files

**PCB Design:** `10_hardware/13_PCB/data_acquisition_board/`

**Schematic:** `10_hardware/13_PCB/data_acquisition_board/schematic.pdf`
- Shows connections: Sensor → MCU → USB

**PCB Layout:** `10_hardware/13_PCB/data_acquisition_board/layout.kicad_pcb`
- 2-layer board, dimensions: 50mm × 30mm (example)

**Bill of Materials (BOM):** `40_procurement/47_BOM/data_acquisition_board_BOM.xlsx`

---

## Build Instructions

**Environment Setup:**
1. Install PlatformIO (or Arduino IDE)
2. Clone repository: `git clone path/to/20_software/data_acquisition_firmware`
3. Open folder in VS Code with PlatformIO extension

**Compilation:**
```bash
cd 20_software/data_acquisition_firmware
pio run                    # Build firmware
pio test                   # Run unit tests
pio run --target upload    # Flash to microcontroller
```

**Dependencies:**
- No external libraries required (bare-metal example)
- Optional: Unity test framework for unit tests

**Build Output:**
- Binary: `.pio/build/target/firmware.bin`
- Size: ~15 KB Flash, ~6 KB RAM (example)

---

## Configuration Parameters

**Located in:** `include/config.h`

| Parameter | Default Value | Description |
|---|---|---|
| SAMPLING_RATE_HZ | 10 | Sensor polling rate (REQ-DAQ-001) |
| BUFFER_SIZE | 1000 | Circular buffer capacity (REQ-DAQ-003) |
| UART_BAUD | 115200 | Host communication speed |
| ADC_RESOLUTION | 10 | ADC bit depth (10-bit = 0-1023) |

**Calibration Values:** (sensor-specific)
- Offset: `SENSOR_OFFSET_mV`
- Scale factor: `SENSOR_SCALE_FACTOR`

---

## Deployment

**Target Hardware:** (example)
- Microcontroller: STM32F103C8T6 (Blue Pill board)
- Programmer: ST-Link V2 USB dongle

**Flash Procedure:**
1. Connect ST-Link to MCU (SWDIO, SWCLK, GND, 3.3V)
2. Run: `pio run --target upload`
3. Verify: LED blinks at 1 Hz (indicates successful boot)

**First-Time Setup:**
See: [[OAU_commissioning_procedure_example]]

---

## Code Documentation

**Internal Documentation:**
- Function-level comments in source files
- Doxygen-compatible docstrings (can generate HTML docs)

**To generate code docs:**
```bash
cd 20_software/data_acquisition_firmware
doxygen Doxyfile    # Generates docs in docs/html/
```

---

## Testing

**Unit Tests:** `test/test_circular_buffer.c`
- Validates buffer wrap-around logic
- Validates overrun detection

**Integration Tests:** See [[TAE_integration_test_example]]

**Verification:** See [[TAE_firmware_verification_example]]

---

## Related

- **Requirements:** [[REQ_data_acquisition_example_(DAQ)]]
- **Decisions:** [[DEC_buffer_strategy_example]]
- **Architecture:** [[ARC_data_acquisition_example]]
- **Components:** [[CMP_microcontroller_example]]
- **Interface:** [[IFC_sensor_interface_example]]
- **Operation:** [[OAU_firmware_update_example]]

---

## Notes

**This is an EXAMPLE implementation file.** In a real project:
- Replace paths with actual repository locations
- Add screenshots of IDE setup
- Document actual hardware programmer setup
- Link to CI/CD pipeline (if exists)
- Add troubleshooting section for common build errors
