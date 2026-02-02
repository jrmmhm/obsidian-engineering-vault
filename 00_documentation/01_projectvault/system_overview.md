## Context
This file provides an overview of the major system modules and is the entry point into the architecture.

**Purpose:** This is a **Map of Content (MOC)** - a hub that lists all top-level modules in the project.

**How to Use:**
1. Browse the module list below to see what the system contains
2. Click on any module link to dive into its architecture
3. Each ARC module links to requirements, components, implementation, and verification

---

## System Modules (ARC)

This table lists all architectural modules in the project. Each row is a distinct module with its own requirements, components, and interfaces.

| Module (ARC) | Brief Description |
| ------------ | ----------------- |
| *Add your modules here* | *Brief description of the module* |

**Instructions:**
- Add one row per major module
- Keep descriptions brief (one line, under 100 characters)
- Link to the ARC file using `[[ARC_module_name]]`

---

## Module Categories (Typical for Mechatronics Projects)

When building your project, consider organizing modules by:

### Physical Modules (Hardware)
Examples of what might be created:
- Power supply board
- Sensor board
- Actuator board
- Main controller board
- User interface panel

### Cross-Cutting Systems
Examples of what might be created:
- Communication system (CAN, Ethernet, WiFi)
- Safety system (emergency stop, interlocks)
- Data logging system
- Calibration system
- Diagnostics system

### Software Modules
Examples of what might be created:
- Firmware architecture (if complex enough to warrant separate ARC)
- Control algorithms (PID, state machines)
- User interface software
- Data processing pipeline

---

## System Decomposition Strategy

**Important:** Choose ONE decomposition axis and use it consistently:

**Option A: Physical Assembly Hierarchy**
- Decompose by physical hardware modules (boards, assemblies)
- Example: Main Board → Sensor Board → Individual Sensors

**Option B: Functional Decomposition**
- Decompose by function (power, sensing, control, communication)
- Example: Power System → Communication System → Control System

**Don't Mix:** Avoid mixing physical and functional decomposition at the same level (causes overlap and confusion).

