# Folder Structure Reference

This document explains every top-level folder, the rules for what goes where,
and the two distinctions that cause the most confusion in practice.

For the short version and the getting-started path, see the [README](README.md).

---

## The One Rule That Decides Everything

Every folder in this template answers a different question. Before you save a
file, ask: **does this document explain engineering work, or is it the artifact
of that work?**

| Explains the work | Is the artifact |
| ----------------- | --------------- |
| Goes **inside** `00_documentation/` | Goes **outside** `00_documentation/` |
| Requirements, architecture, decisions, test conclusions | Measurement files, CAD models, presentations, invoices |

Concrete cases:

| Thing | Belongs in |
| ----- | ---------- |
| A TAE note describing *what was tested and why* | `00_documentation/01_projectvault/07_testing_and_evidence_(TAE)/` |
| The CSV files that test produced | `30_testdata/31_testdata_raw/` |
| A stakeholder presentation | `90_administration/` |
| A datasheet from the manufacturer | `50_sources/01_datasheets/` |
| Your own measurement report as PDF | `00_documentation/02_documents/07_testing_and_evidence_(TAE)/` |

---

## 00_documentation

All engineering documentation. Two subfolders that share the same nine-domain
structure.

### 01_projectvault/

The Obsidian vault. All structured project documentation as Markdown.

**Rule: Markdown files only (`.md`).** Anything binary goes to `02_documents/`
or `50_sources/`.

Start with `01_projectvault/README.md` — it explains the domains, the file
creation rules and the recommended reading order.

### 02_documents/

Project-internal documents that are not maintained as Markdown but still serve
a documentary purpose: exports, PDFs, photos, calibration certificates.

The subfolders mirror the vault domains, so a measurement report lands under
`02_documents/07_testing_and_evidence_(TAE)/` exactly as its vault note does.

Naming schema: `Type__Description__YYYY-MM-DD__rev-N.ext`
See `00_documentation/02_documents/README.md` for the full type table.

### 02_documents vs. 50_sources

This is the distinction people get wrong most often.

| Criterion | `02_documents` (internal) | `50_sources` (external) |
| --------- | ------------------------- | ----------------------- |
| **Origin** | Created in the project | Adopted from outside |
| **Changeability** | Can be changed in the project | Adopted unchanged |

**Internal** — own measurement report, photo of the test setup, project-specific
system overview as PDF export, calibration certificate of your own multimeter,
internal review presentation.

**External** — AD7175-2 datasheet from Analog Devices, DIN EN 61010-1 as PDF,
oscilloscope manual from the manufacturer, a paper on dielectric elastomers, a
STEP model of a connector from the supplier.

**Rule of thumb:** Does it come from a manufacturer, publisher or standards
body? → `50_sources`. Was it created in the project? → `02_documents`.

---

## 10_hardware

All hardware design data.

| Folder | Contents |
| ------ | -------- |
| `11_mechanics_CAD/` | CAD sources (editable) |
| `12_mechanics_export/` | Exports — STEP, STL, DXF, technical drawings, 3D printing |
| `13_PCB/` | PCB design (e.g. KiCad projects) |
| `14_electronics/` | Circuits, simulations, additional data (e.g. LTspice) |

---

## 20_software

Source code, organized by project-specific structure.

If the project has several distinct responsibilities (firmware, host
application, web UI), create one folder per responsibility. Each folder can then
become its own git repository without restructuring later.

---

## 30_testdata

Measurement data and evaluations — raw artifacts, not documentation.

| Folder | Contents |
| ------ | -------- |
| `31_testdata_raw/` | Raw data, unchanged and immutable |
| `32_testdata_processed/` | Cleaned, converted, analyzed data |

The documentation explaining *what* was tested and *what it proves* belongs in
`00_documentation/01_projectvault/07_testing_and_evidence_(TAE)/`. Keep the
numbers here and the reasoning there — that is the whole point of the split.

---

## 40_procurement

Complete procurement trail, from first quote to payment.

`41_quotes/` · `42_orders/` · `43_invoices/` · `44_payments/` ·
`45_reimbursements/` · `46_dunning/` · `47_BOM/` · `48_tendering/`

---

## 50_sources

Single Source of Truth for external sources and program libraries.

`01_datasheets/` · `02_paper/` · `03_books/` · `04_standards/` · `05_manuals/` ·
`06_licenses/` · `07_CAD_files/` · `08_libs/` · `09_rest/`

`50_sources/README.md` explains structure, naming and navigation in detail.

Vault notes never copy source content — a REF note summarizes what the external
document says and points at the file here.

---

## 60_releases

Defined project states (baseline snapshots). Each release records:

- version number and date
- git tag reference
- summary of changes

That is *your project's* release trail. The template's own is
[CHANGELOG.md](CHANGELOG.md) at the repository root — keep the two apart, or
your project's first baseline inherits the template's history.

---

## 90_administration

Project organization material that is **not** engineering documentation:
presentations, thesis, practice report, exports, submission documents, meeting
notes, schedules.

Engineering documentation stays under `00_documentation/` even when it is
exported as PDF.

---

## 99_archive

Old states, superseded content, documents that are no longer active. Nothing is
deleted outright — it moves here so history stays reconstructable.

---

## .claude/skills/mechatronics-docs

The documentation skill that ships with this template: the agent instructions,
the vault validator, the traceability exporter, its hooks and its test suite.

The exporter (`export_traceability.py`) writes outside the vault by design and
refuses any `--output-dir` inside one, because the vault is Markdown only. A
revision worth keeping belongs in `00_documentation/02_documents/`.

That holds for `traceability_index.md` too — the compact index an agent reads
first. It stays generated rather than committed: a stored index is only as
current as its last run, and the vault is what it is derived from. `CLAUDE.md`
therefore names the command, not a path.

See the [README](README.md#the-ai-layer) for how to use it, with or without
Claude Code.

---

## .github

Everything GitHub reads rather than a person: `workflows/validate-vault.yml`
runs the validator, the template vault audit, the export determinism check and
the worked example on every push and pull request; `ISSUE_TEMPLATE/` holds the
bug report and the method change proposal, with `config.yml` for the chooser;
`pull_request_template.md` carries the checklist of gates a reviewer would
otherwise re-derive.

This is enforcement that does not depend on one editor being used. The Claude
Code hooks only see `Edit`, `Write` and `MultiEdit`; the workflow runs no matter
how a change was authored.

**In a project made from this template**, this directory arrives with it and
describes the template rather than your project. Delete it, or keep the workflow
and replace the templates with your own.

