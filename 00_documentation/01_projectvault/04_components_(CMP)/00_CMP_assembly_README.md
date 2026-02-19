CMP Assembly notes document mechanical or electrical assemblies as independent, reusable building blocks.
An Assembly note is deliberately minimal: profile + scope + composition. Details live in their own SSOT files and are linked.

For the decision rule between Individual Part and Assembly, see [[00_CMP_README]].

**Typical examples:** PCB assemblies, cable harnesses, mounting plates, fixtures, enclosure sub-assemblies, test jigs.

---

## Structure

### 1) Context

Brief description (3--5 sentences):
- Purpose
- Function in the system
- Particularities / criticality (brief)

**Goal:** Quick entry without detail overload.

---

### 2) General Overview (Table)

The overview contains only the most important meta-information to immediately classify the assembly.

**Mandatory fields:**
- Type
- Status
- Location / Installation site
- Primary function

**Note:** Manufacturer/Model is often not meaningful for assemblies and is therefore not part of the Assembly template.

---

### 3) Scope

Scope is the most important section: it prevents "container notes".

**Includes (physical boundary):**
- Which parts/segments belong to the assembly?

**Excludes (explicit):**
- Which parts explicitly do not belong?

**Goal:** Unambiguous physical boundaries, so that ownership and responsibilities remain stable.

---

### 4) Consists of (CMP)

This field describes the composition of the assembly.

**Rules:**
- Only links to CMP parts (and optionally links to sub-assemblies as CMP).
- No assembly instructions, no processing steps, no torque values.
- No complete screw/small-parts list if it gets large: then separate BOM file as SSOT.

**Purpose:** Navigable entry point ("what is it made of?"), without becoming a second BOM.

---

## What Does Not Belong in CMP Assembly
- Architecture assignment ("is part of ARC_X") --> results via backlinks/ARC
- Interface parameters (levels, timing, nodes, limits) --> belong in IFC
- Implementation (assembly instructions, wiring, machining, torque, crimping) --> belongs in IMP
- Test results/measurement values --> belong in TAE (CMP may link)
- Standard interpretations / decision justifications --> belong in DEC / REF
