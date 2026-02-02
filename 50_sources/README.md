# SOURCES – Storage and Naming Conventions

Sources is the central pool for external sources (PDFs, CAD models, standards, libraries, etc.).
Semantics/parameters (e.g., "which resistor can do what?") are NOT maintained here, but in a separate catalog file in the corresponding folder (e.g., `00_catalog.csv`).

Basic rules:
- Filenames are the primary metadata source.
- No deep folder trees (max. a few levels).
- Each file carries a version/revision identifier in the name: `__rev-...` (documents) or `__v-...` (models/exports).
- Domain (mechanics/electronics/...) is encoded in the folder, not in the filename.

---

## 01_datasheets
**Content**
- Datasheets, errata, PCNs, EOLs, safety sheets, app notes (if clearly component-related).

**Filename convention**
`Vendor__MPN_or_Model__DocType__rev-RevOrYear.pdf`

**Variables**
- `Vendor` = Manufacturer/source as short stable name (e.g., `AnalogDevices`, `Bosch`, `Murata`)
- `MPN_or_Model` = Specific part number / model designation (e.g., `AD7175-2`, `BME280`, `C3216X7R1E106K`)
- `DocType` = Document type (controlled vocabulary, see below)
- `rev-RevOrYear` = Revision, version code, or date (e.g., `rev-F`, `rev-1.6`, `rev-2024-05-02`)

**DocType (recommended)**
- `datasheet`
- `appnote`
- `errata`
- `pcn`
- `eol`
- `safety`

**Examples**
- `AnalogDevices__AD7175-2__datasheet__rev-F.pdf`
- `Bosch__BME280__datasheet__rev-1.6.pdf`
- `Murata__C3216X7R1E106K__datasheet__rev-2024.pdf`

---

## 02_paper
**Content**
- Scientific papers (PDF), preprints, conference contributions.

**Filename convention**
`FirstAuthorEtAl__YYYY__shorttitleslug.pdf`

**Variables**
- `FirstAuthorEtAl` = Last name of first author + `EtAl` (e.g., `RossetEtAl`)
- `YYYY` = Publication year (four digits)
- `shorttitleslug` = Short title slug, lowercase, `_` instead of spaces (e.g., `dielectric_elastomer_actuators_review`)

**Example**
- `RossetEtAl__2016__dielectric_elastomer_actuators_review.pdf`

---

## 03_books
**Content**
- Technical books as PDF/scan, official e-books, book chapters (when cited as book source).

**Filename convention**
`Author__YYYY__shorttitleslug__ed-n__LANG.pdf`

**Variables**
- `Author` = Last name (for multiple authors: first author/editor as main anchor)
- `YYYY` = Publication year
- `shorttitleslug` = Short title slug (lowercase, `_`)
- `ed-n` = Edition as number (e.g., `ed-1`, `ed-3`)
- `LANG` = Language (e.g., `DE`, `EN`), relevant here

**Example**
- `HerbertBernstein__2020__measuring_with_oscilloscope__ed-3__DE.pdf`

---

## 04_standards
**Content**
- Standards as PDF (full text or excerpt), normative documents.

**Filename convention**
`DIN_EN_...__YYYY__LANG__full.pdf`
or
`DIN_EN_...__YYYY__LANG__excerpt.pdf`

**Variables**
- `DIN_EN_...` = Standard identifier as officially designated (with `_` instead of spaces/hyphens as needed)
- `YYYY` = Issue year / version
- `LANG` = Language (`DE`, `EN`, ...)
- `full|excerpt` = Full text or excerpt

**Examples**
- `DIN_EN_61010-1__2020__DE__full.pdf`
- `DIN_EN_50191__2011__DE__full.pdf`
- `DIN_VDE_0100-410__2018__DE__excerpt.pdf`

---

## 05_manuals
**Content**
- Manuals, programming guides, user manuals, installation guides, operating instructions (not primarily "component datasheet", but product/system documentation).

**Filename convention**
`Vendor__Product__DocType__rev-RevOrYear.pdf`

**Variables**
- `Vendor` = Manufacturer/source
- `Product` = Product name/model (e.g., `USB220`, `Siglent_SDS814X_HD`)
- `DocType` = Document type (see below)
- `rev-RevOrDate` = Revision/version/date (e.g., `rev-2025-03-01`)

**DocType**
- `user-manual`
- `programming-guide`
- `hardware-guide`
- `installation-guide`
- `release-notes`

**Example**
- `Futek__USB220__user-manual__rev-2023.pdf`

---

## 06_licenses
**Content**
- License texts, EULAs, purchase receipts for standards/tools, terms, invoices for sources (where needed).

**Filename convention**
`VendorOrSource__Item__YYYY-MM-DD__doctype.pdf`

**Variables**
- `VendorOrSource` = Source/provider (e.g., `Beuth`, `Autodesk`, `AnalogDevices`)
- `Item` = What exactly (e.g., standard ID, software, subscription)
- `YYYY-MM-DD` = Date
- `doctype` = `invoice` | `license_text` | `terms`

**Example**
- `Beuth__DIN_EN_61010-1__2025-08-27__invoice.pdf`

---

## 07_CAD_files
**Content**
- 3D models (STEP, STL), drawings/exports, footprint or housing models, manufacturer-related CAD data.
- No project CAD sources (those are in the respective project), but reusable reference models.

**Filename convention**
`VendorOrSource__MPN_or_Model_or_Name__v-n.ext`

**Variables**
- `VendorOrSource` = Manufacturer or source (e.g., `Schuetzinger`, `Molex`, `Generic`)
- `MPN_or_Model_or_Name` = Model/part number or clear name
- `v-n` = Internal version of the saved file (integer)
- `ext` = File extension (`step`, `stl`, `dxf`, `pdf`, ...)

**Examples**
- `Schuetzinger__HV_Connector_XYZ__v-1.step`
- `Generic__M3_standoff_20mm__v-1.step`

---

## 08_libs
**Content**
- Libraries for software tools (reusable, tool-specific).
- Structure: one folder per software.

**Subfolder convention**
- `kicad/`
- `ltspice/`
- `inventor/`
- `zotero/` (if you want to store things here, otherwise external)
- Additional tools as needed

**Naming inside**
- Name sensibly within the tool, but represent version states via folders or tags (not over 20 levels deep).

---

## 09_rest
**Content**
- Temporary storage for sources that are not yet cleanly classified.
- Goal: empty regularly (sort in or delete).

**Convention**
- No special rules except: once clear → move to appropriate folder and name correctly.
