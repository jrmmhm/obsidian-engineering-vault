CMP notes document components and assemblies as independent, reusable building blocks.
A CMP note is deliberately minimal: it is a profile with sources and entry point to details.

## Single Source of Truth (SSOT) – Mandatory Rule
Each "aspect" of a component gets its own file as soon as it needs more than brief info.

**Rule:**
- Information is maintained only once.
- The main CMP file remains a profile; details are outsourced and linked.

**Examples for aspects (each own file):**
- Operating Limits / Derating / Thermals
- Layout and EMC hints
- Calibration / Accuracy / Drift

**Convention (recommended):**
- CMP_Name_Interfaces
- CMP_Name_OperatingLimits
- CMP_Name_Layout
- CMP_Name_Calibration
- CMP_Name_Notes

## Structure of a CMP File (Mandatory Sections)

### 1) Source(s)
Only links to the used primary sources (e.g. datasheet, appnote, product page).
Before numbers/claims are noted in CMP, a source must exist.

**Example:**
- Zotero link: Datasheet
- Zotero link: Appnote / Reference design

---
### 2) Context
Brief description of the component/assembly (3–5 sentences):
- What is it?
- What function does it fulfill?
- What particularities are relevant?

---
### 3) General Overview (Table)
The overview contains only the most important specifications (Key Specs) that serve as a quick entry.

**Mandatory fields (recommended):**
- Type
- Manufacturer / Model
- Revision / Variant (if relevant)

Additionally: few Key Specs (e.g. bit depth, kS/s, channels) — only as many as sensible.

---
## What does not belong in CMP
- Architecture assignment ("is part of ARC_X") → results via backlinks/ARC
- Interface contracts/parameters (levels, timing, bus mode) → belong in IFC
- Implementation (wiring, GPIO, registers, code, concrete schematic locations) → belongs in IMP
- Test results/measurement values → belong in TAE/EVD (CMP may link)

---
## Minimal Rules for Consistency
- No values without source.
- No duplication of detailed knowledge: better create subpage and link.
- CMP remains readable: profile first, details only as links.
