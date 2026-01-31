## Context
This file provides a quick start guide for operating the data acquisition system. OAU files contain procedures and checklists for human operators.

**System:** Data Acquisition Module

**Related Architecture:** [[ARC_data_acquisition_example]]

**Target Audience:** Operators, technicians, new team members

---

## Prerequisites

**Hardware Required:**
- Data acquisition board (assembled and tested)
- USB cable (Type-A to Micro-USB or Type-C, depending on board)
- Sensor connected to input (see [[IFC_sensor_interface_example]])
- Power supply: 5V via USB or external (if applicable)

**Software Required:**
- Serial terminal program (PuTTY, Tera Term, or Arduino Serial Monitor)
- Python 3.7+ (for data logging script, optional)

**Safety:**
- Verify supply voltage before powering on
- Do not hot-plug sensors (power off before connecting/disconnecting)

---

## Quick Start (5 Minutes)

### Step 1: Hardware Connections
1. **Connect sensor to board:**
   - Analog sensor: Connect to ADC input pin (see board pinout)
   - Digital sensor: Connect to I2C/SPI pins (see [[IFC_sensor_interface_example]])
2. **Connect USB cable** from board to PC
3. **Verify LED:** Power LED should illuminate immediately

### Step 2: Open Serial Terminal
1. Launch serial terminal software
2. Configure settings:
   - **Baud rate:** 115200
   - **Data bits:** 8
   - **Parity:** None
   - **Stop bits:** 1
   - **Flow control:** None
3. **Select COM port:** Check Device Manager (Windows) or `ls /dev/tty*` (Linux/Mac)
4. **Open connection**

### Step 3: Verify Operation
1. **Expected output:**
   ```
   [000.000] Data Acquisition System v1.0.0
   [000.010] Initializing sensor...
   [000.050] Sensor ready
   [000.100] Starting acquisition at 10 Hz
   [000.100] Sample 0: 512 (2.50V)
   [000.200] Sample 1: 513 (2.51V)
   [000.300] Sample 2: 514 (2.52V)
   ...
   ```
2. **Verify:**
   - Samples appear every ~100 ms (10 Hz)
   - Values change when sensor input changes (e.g., touch temperature sensor)
   - No error messages

### Step 4: Data Logging (Optional)
1. **Use Python script:**
   ```bash
   cd 20_software/data_acquisition_firmware/tools/
   python log_data.py --port COM3 --duration 60
   ```
2. **Output saved to:** `captured_data.csv`

---

## Normal Operation

### Startup Sequence
1. Power on system (LED blinks during initialization)
2. Wait for "Starting acquisition" message (~5 seconds)
3. System begins sampling automatically at 10 Hz
4. Data is transmitted via UART and stored in circular buffer

### Data Format (UART Output)
```
[timestamp_ms] Sample sequence_number: ADC_value (voltage)
```

**Example:**
```
[001.234] Sample 12: 768 (3.75V)
```

**Fields:**
- `timestamp_ms`: Milliseconds since power-on
- `sequence_number`: Increments from 0 (wraps at 65535)
- `ADC_value`: Raw ADC reading (0-1023 for 10-bit ADC)
- `voltage`: Calculated voltage (0-5V scale)

### Indicator LEDs (Example)
- **Power LED (green):** Solid = system powered
- **Status LED (blue):** Blinks at 1 Hz = normal operation
- **Error LED (red):** On = sensor error or communication fault

---

## Troubleshooting

### Problem: No Data Appearing in Terminal
**Possible Causes:**
- Wrong COM port selected
- Wrong baud rate (must be 115200)
- Firmware not flashed or corrupted

**Solutions:**
1. Verify COM port in Device Manager
2. Check baud rate setting (115200)
3. Re-flash firmware (see [[IMP_firmware_structure_example]])
4. Try a different USB cable (some cables are charge-only)

### Problem: Sensor Values Not Changing
**Possible Causes:**
- Sensor not connected
- Sensor not powered
- Wrong sensor selected in firmware

**Solutions:**
1. Check physical connections (VCC, GND, Signal)
2. Verify sensor supply voltage with multimeter
3. Check firmware `config.h` for correct sensor type

### Problem: Irregular Sampling Rate
**Possible Causes:**
- System overload (too many tasks)
- Interrupt conflicts

**Solutions:**
1. Check CPU usage in debug build
2. Verify timer configuration
3. See [[TAE_acquisition_rate_test_example]] for validation procedure

### Problem: Data Stops After a While
**Possible Causes:**
- Buffer overflow (consumer not reading fast enough)
- System hang or watchdog reset

**Solutions:**
1. Check for error messages in terminal
2. Increase UART baud rate if buffer overruns detected
3. Power cycle and check for repeated failures
4. Enable debug logging to identify root cause

---

## Maintenance

### Daily Checks
- Verify sensor readings are reasonable (not stuck at min/max)
- Check for error messages in log
- Ensure system LED is blinking normally

### Weekly Checks
- Review logged data for anomalies
- Verify buffer statistics (overruns, dropped samples)
- Clean sensor connectors (if in dusty environment)

### Monthly Checks
- Perform acquisition rate test (see [[TAE_acquisition_rate_test_example]])
- Verify timestamp accuracy (see [[TAE_timestamp_accuracy_test_example]])
- Update firmware if new version available

---

## Advanced Operations

### Changing Sampling Rate
1. Edit `include/config.h`:
   ```c
   #define SAMPLING_RATE_HZ 20  // Change from 10 to 20 Hz
   ```
2. Rebuild and flash firmware
3. Verify new rate with logic analyzer

### Calibration (If Sensor Requires)
See: [[OAU_sensor_calibration_example]]

### Data Export
1. Capture data to CSV file using logging script
2. Import into Excel/MATLAB/Python for analysis
3. See `20_software/data_acquisition_firmware/tools/plot_data.py` for visualization

---

## Related

- **Architecture:** [[ARC_data_acquisition_example]]
- **Implementation:** [[IMP_firmware_structure_example]]
- **Testing:** [[TAE_acquisition_rate_test_example]]
- **Troubleshooting:** [[OAU_troubleshooting_guide_example]]

---

## Notes

**This is an EXAMPLE operation file.** In a real project:
- Replace with actual hardware setup photos
- Add actual screenshots of terminal output
- Document actual LED indicators and their meanings
- Include actual COM port detection procedures
- Add safety warnings specific to your hardware
