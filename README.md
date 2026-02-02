# Project Overview

This is a **project structure template** for mechatronics engineering projects. It provides a complete documentation system with hardware, software, test data, procurement, and sources organization.

The technical documentation is maintained in the project vault (/00_documentation/01_projectvault) and is the central entry point.

**Template Features:**
- Obsidian-based documentation with traceability (requirements → architecture → implementation → verification)
- Scalable folder structure for hardware, software, and documentation
- English documentation for international collaboration

---

## Quick Start (Reading Documentation)
It is highly recommended to use "Obsidian" as software for the technical documentation.

1) Open Obsidian
2) "Open folder as vault"
3) Select folder: `00_documentation`
4) Entry point: Read `README` under `01_projectvault`


## Folder Structure (Overview)

### 00_documentation
Contains all engineering documentation that explains and documents the technical aspects of the project.

- `01_projectvault/`
  Obsidian vault. Contains all structured project documentation as Markdown files.

  **Important:** Exclusively Markdown files (.md).
- `02_documents/`
  Exports, PDFs, supplementary documents that are not maintained as Markdown notes, but fulfill one of the documentation tasks in the project vault.

  **Important:** All documents stored here are project-internal. External sources are located under "50_sources".


`01_projectvault/` and `02_documents/` share the same main folder structure. To understand this structure, it is recommended to read the README in `01_projectvault/`.

---

#### Key Principle: What Belongs Under 00_documentation?

**Only engineering documentation belongs under `00_documentation/`.**

The distinction between folders inside `00_documentation/` (like `07_testing_and_evidence`) and folders outside (like `30_testdata` or `90_administration`) follows this rule:

| Inside 00_documentation | Outside 00_documentation |
|-------------------------|--------------------------|
| Documents that **explain and document** the engineering work | Raw data, artifacts, and non-engineering materials |
| Requirements, architecture, decisions, test conclusions | Test data files, presentations, procurement records |

**Examples:**
- A TAE file documenting **what was tested and why** → `00_documentation/01_projectvault/07_testing_and_evidence/`
- The actual **CSV measurement files** from that test → `30_testdata/`
- A **presentation for stakeholders** → `90_administration/`
- Meeting notes about project logistics → `90_administration/`

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
Measurement data and evaluations (raw artifacts, not documentation).
- `31_testdata_raw/` Raw data (unchanged, immutable)
- `32_testdata_processed/` Processed data (cleaned, converted, analyzed)

**Note:** Test data files go here. The documentation explaining what was tested and the conclusions goes in `00_documentation/01_projectvault/07_testing_and_evidence/`.

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
Project organization materials that are **not engineering documentation**.
- Presentations, thesis, practice report, exports, submission documents
- Meeting notes, schedules, project logistics

**Note:** This is for non-technical project materials. Engineering documentation (even if exported as PDF) belongs under `00_documentation/02_documents/`.

### 99_archive
Storage for old versions, obsolete content, no longer active documents.

---

## Using This Template

**This is a template repository.** To use it for your own project:

1. **Clone, download or Use this template** this repository
2. **Read the documentation structure:** Start with `00_documentation/01_projectvault/README.md`
3. **Understand the file creation rules:** Read `00_documentation_file_creation_and_conventions.md`
4. **Create your own modules** following the templates in each folder
5. **Update LICENSE** file with your name/organization
6. **Customize** README files to match your project specifics

**Documentation Entry Points:**
- Start here: `00_documentation/01_projectvault/README.md`
- System overview: `00_documentation/01_projectvault/system_overview.md`

---

## License

This project is licensed under the **MIT License** - see the LICENSE file for details.

**For template users:** You may keep this license (if open sourcing your project) or replace it with your own license.

Copyright (c) [Year] [Your Name or Organization]
