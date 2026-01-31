# 02_documents

## Purpose
This folder contains **project-internal documents** that are not maintained as Markdown in the project vault, but fulfill a documentary function in the project.

Typical contents:
- Own measurement reports as PDF
- Project-specific drawings and exports
- Photos of test setups
- Calibration certificates of own measuring devices
- Internal presentations and reports

## Distinction from 50_sources
| Criterion | 02_documents | 50_sources |
|-----------|--------------|------------|
| Origin | Created internally in project | External (manufacturers, standards, literature) |
| Examples | Own measurement reports, test photos, project drawings | Data sheets, standards, papers, manuals |
| Changeability | Can be changed in project | Adopted unchanged |

**Rule of thumb:** If the document comes from outside the project (manufacturer, standards organization, publisher), it belongs in `50_sources`. If it was created in the project, it belongs in `02_documents`.

## Folder Structure
The subfolders mirror the structure of the project vault:
- `01_requirements_(REQ)/`
- `02_decisions_(DEC)/`
- `03_architecture_(ARC)/`
- `04_components_(CMP)/`
- `05_interfaces_(IFC)/`
- `06_implementation_(IMP)/`
- `07_testing_and_evidence_(TAE)/`
- `08_operation_and_usage_(OAU)/`
- `09_references_(REF)/`

The classification follows the same logic as in the vault: Measurement results → `07_testing_and_evidence_(TAE)/`, architecture diagrams → `03_architecture_(ARC)/` etc.

---

## Naming Convention

### General Schema
`Type__Description__YYYY-MM-DD__rev-N.ext`

**Components:**
- `Type`: Document type (see table below)
- `Description`: Short, unique description (lowercase, `_` instead of spaces)
- `YYYY-MM-DD`: Creation date or measurement date
- `rev-N`: Revision number (integer, starting at 1)
- `ext`: File extension (pdf, jpg, png, xlsx etc.)

### Document Types (Type)

| Type | Description | Example |
|-----|--------------|----------|
| `report` | Measurement reports, analyses, evaluations | `report__voltage_divider_calibration__2025-01-15__rev-1.pdf` |
| `photo` | Photos of setups, components, tests | `photo__test_setup_hv_measurement__2025-01-20__rev-1.jpg` |
| `drawing` | Drawings, sketches, diagrams | `drawing__housing_dimensions__2025-01-10__rev-2.pdf` |
| `certificate` | Calibration certificates, certificates | `certificate__multimeter_fluke87__2024-12-01__rev-1.pdf` |
| `presentation` | Internal presentations | `presentation__project_review_q1__2025-03-15__rev-1.pdf` |
| `export` | Exports from tools (KiCad, CAD etc.) | `export__measurement_board_schematic__2025-01-18__rev-3.pdf` |
| `log` | Protocols, log files | `log__mcu_commissioning__2025-01-22__rev-1.pdf` |

### Examples

**07_testing_and_evidence_(TAE)/**
- `report__insulation_measurement_board_housing__2025-01-15__rev-1.pdf`
- `photo__test_setup_insulation_measurement__2025-01-15__rev-1.jpg`
- `certificate__ME_mit410__2024-06-01__rev-1.pdf`

**03_architecture_(ARC)/**
- `drawing__system_overview_block_diagram__2025-01-05__rev-2.pdf`
- `export__system_architecture_diagram__2025-01-10__rev-1.png`

**06_implementation_(IMP)/**
- `export__measurement_board_schematic__2025-01-18__rev-3.pdf`
- `export__measurement_board_layout__2025-01-18__rev-3.pdf`
- `photo__pcb_assembled_top_side__2025-01-20__rev-1.jpg`

---

## Rules

1. **No external sources here.** Data sheets, standards, papers → `50_sources`.
2. **No Markdown files.** Structured documentation → `01_projectvault`.
3. **Versioning in filename.** For changes, increase `rev-N`, keep old version or move to `99_archive`.
4. **Referencing from vault.** IMP and TAE files reference documents here via relative path.
