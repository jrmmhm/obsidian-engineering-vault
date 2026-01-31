# Project Overview

This is a **project structure template** for mechatronics engineering projects. It provides a complete documentation system with hardware, software, test data, procurement, and sources organization.

The technical documentation is maintained in the project vault (/00_documentation/01_projectvault) and is the central entry point.

**Template Features:**
- Obsidian-based documentation with traceability (requirements → architecture → implementation → verification)
- Universal example module demonstrating best practices
- Scalable folder structure for hardware, software, and documentation
- English documentation for international collaboration

**License:** MIT (see LICENSE file) - Free to use for any purpose, including commercial projects

---

## Quick Start (Reading Documentation)
It is highly recommended to use "Obsidian" as software for the technical documentation.

1) Open Obsidian
2) "Open folder as vault"
3) Select folder: `PMDE/00_documentation`
4) Entry point: Read `README` under `01_projectvault`


## Folder Structure (Overview)

### 00_documentation
- `01_projectvault/`
  Obsidian vault. Contains all structured project documentation.

  **Important:** Exclusively Markdown files (.md).
- `02_documents/`
  Exports, PDFs, supplementary documents that are not maintained as Markdown notes, but fulfill one of the tasks in the project vault.

  **Important:** All documents stored here are project-internal. External sources are located under "50_sources".


`01_projectvault/` and `02_documents/` share the same main folder structure. To understand this structure, it is recommended to read the README in `01_projectvault/`.

---

#### Distinction: 02_documents vs. 50_sources

| Criterion | 02_documents (internal) | 50_sources (external) |
|-----------|----------------------|---------------------|
| **Origin** | Created in project | Adopted from outside |
| **Changeability** | Can be changed in project | Adopted unchanged |

**Examples for 02_documents (internal):**
- Own measurement report for voltage divider calibration
- Photo of test setup
- Project-specific system overview as PDF export
- Calibration certificate of own multimeter
- Internal presentation for project review

**Examples for 50_sources (external):**
- Data sheet of AD7175-2 from Analog Devices
- DIN EN 61010-1 standard as PDF
- Oscilloscope manual from manufacturer
- Scientific paper on dielectric elastomers
- STEP model of a connector from manufacturer

**Rule of thumb:** Does the document come from a manufacturer, publisher, or standards organization? → `50_sources`. Was it created in the project? → `02_documents`.

### 10_hardware
Contains all hardware design data.
- `11_mechanics_CAD/` CAD sources (editable)
- `12_mechanics_export/` Exports (STEP, STL, DXF etc.)
- `13_PCB/` PCB design (e.g., KiCad projects)
- `14_electronics/` Circuits, simulations, additional data (e.g., LTspice)

### 20_software
Software code according to project-specific structure. If there are several different responsibilities in the project, it is recommended to create one folder per responsibility, so that one repository can be created per folder.

### 30_testdata
Measurement data and evaluations.
- `31_testdata_raw/` Raw data (unchanged)
- `32_testdata_processed/` Processed data (cleaned, converted)

### 40_procurement
Complete procurement documentation including BOM and commercial evidence.

### 50_sources
Single Source of Truth for external sources and program libraries (data sheets, manuals, books, CAD libraries, Zotero library, etc.).
Under 50_sources there is a "README.md" file that explains the structure, naming, and navigation in detail.


### 60_releases
Defined project states (baseline snapshots). Each release contains:
- Version number and date
- Git tag reference
- Summary of changes

### 90_administration
Project organization at the level of submissions/presentations/exports.
- Presentations, thesis, practice report, exports, submission documents

### 99_archive
Storage for old versions, obsolete content, no longer active documents.

---

## Using This Template

**This is a template repository.** To use it for your own project:

1. **Clone or download** this repository
2. **Review the example module:** `00_documentation/01_projectvault/03_architecture_(ARC)/ARC_data_acquisition_example.md`
3. **Delete example files** (files with `_example` in the name) once you understand the structure
4. **Create your own modules** following the example patterns
5. **Update LICENSE** file with your name/organization
6. **Customize** README files to match your project specifics

**Documentation Entry Points:**
- Start here: `00_documentation/01_projectvault/README.md`
- System overview: `00_documentation/01_projectvault/system_overview.md`
- Example module: `ARC_data_acquisition_example.md` (shows complete traceability)

---

## License

This project is licensed under the **MIT License** - see the LICENSE file for details.

**For template users:** You may keep this license (if open sourcing your project) or replace it with your own license. See `LICENSE_GUIDE.md` for guidance on choosing the right license for your project.

Copyright (c) 2025 [Your Name or Organization]
