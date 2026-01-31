## Context
This file demonstrates requirements documentation for a data acquisition module. This example applies to any mechatronics project that needs to collect sensor data (temperature, pressure, position, etc.).

**Requirement ID Schema:** REQ-DAQ-NNN (Explanation: [[00_REQ_README]])

## Requirements Table

| Class (M/S/O) | NNN | Content                                                                | Acceptance Criterion                                                     | Source / Justification (REF/DEC)     |
| ------------- | --: | ---------------------------------------------------------------------- | ------------------------------------------------------------------------ | ------------------------------------ |
| M             | 001 | The system should acquire sensor data at a minimum rate of 10 Hz       | Data acquisition verified at 10 Hz or higher during continuous operation | External requirement (customer spec) |
| M             | 002 | The system shall store acquired data with timestamp accuracy of ±10 ms | Timestamps verified against calibrated clock                             | Required for data correlation        |
| S             | 003 | The system shall buffer at least 1000 data points locally              | Buffer capacity test shows 1000+ points retained                         | [[DEC_buffer_strategy_example]]      |
| O             | 004 | The system should provide real-time data visualization                 | Live plot visible during acquisition                                     | Usability enhancement                |

