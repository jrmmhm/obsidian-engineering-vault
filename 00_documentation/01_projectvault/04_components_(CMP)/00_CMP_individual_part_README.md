CMP Individual Part notes document leaf-level components as independent, reusable building blocks.
An Individual Part note is deliberately minimal: it is a profile with sources and entry point to details.

For the decision rule between Individual Part and Assembly, see [[00_CMP_README]].

**Typical examples:** ICs, sensors, connectors, relays, power supplies, passive components, mechanical off-the-shelf parts.

---

## Structure

### 1) Source(s)
Only links to the used primary sources (e.g. datasheet, appnote, product page).
Before numbers/claims are noted in CMP, a source must exist.

**Example:**
- Reference manager link: Datasheet
- Reference manager link: Appnote / Reference design

---

### 2) Context
Brief description of the component (3--5 sentences):
- What is it?
- What function does it fulfill?
- What particularities are relevant?

---

### 3) General Overview (Table)
The overview contains only the most important specifications (Key Specs) that serve as a quick entry.

**Mandatory fields:**
- Type
- Manufacturer / Model
- Revision / Variant (if relevant)

Additionally: few Key Specs (e.g. bit depth, kS/s, channels) -- only as many as sensible.

---

## SSOT Aspect Files

When a component needs more detail than fits in the profile, create separate aspect files:

**Convention (recommended):**
- CMP_Name_Interfaces
- CMP_Name_OperatingLimits
- CMP_Name_Layout
- CMP_Name_Calibration
- CMP_Name_Notes

The main CMP file links to these aspect files. Details live in the aspect file, not in the profile.
