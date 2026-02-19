CMP notes document components and assemblies as independent, reusable building blocks.
A CMP note is deliberately minimal: it is a profile with sources and entry point to details.

## Component Taxonomy

Every CMP entry must be classified as one of two types:

| Type | Use When | Template |
| ---- | -------- | -------- |
| **Individual Part** | Leaf-level component with external datasheet (IC, sensor, connector, mechanical part) | [[00_CMP_individual_part_README]] |
| **Assembly** | Composed of multiple parts, has physical boundaries (PCB assembly, cable harness, mounting plate, fixture) | [[00_CMP_assembly_README]] |

**Decision rule:** If the item has a manufacturer datasheet and is not decomposed further within the project, it is an **Individual Part**. If the item is built from multiple parts and needs scope definition (what belongs to it / what does not), it is an **Assembly**.

---

## Single Source of Truth (SSOT) -- Mandatory Rule
Each "aspect" of a component gets its own file as soon as it needs more than brief info. The main CMP file remains a profile; details are outsourced and linked. See [[00_CMP_individual_part_README]] for the aspect file convention.

---

## What Does Not Belong in CMP
- Architecture assignment ("is part of ARC_X") --> results via backlinks/ARC
- Interface contracts/parameters (levels, timing, bus mode) --> belong in IFC
- Implementation (wiring, GPIO, registers, code, concrete schematic locations) --> belongs in IMP
- Test results/measurement values --> belong in TAE/EVD (CMP may link)

---

## When to Use ARC Instead of CMP

**Use CMP** if the item is a leaf-level building block without internal decomposition.

**Use ARC** if the item:
- Has multiple subcomponents that interact with each other
- Has requirements allocated to it
- Has internal interfaces between subcomponents

In other words: if you need to decompose the item further and track requirement allocation/verification, it's a module (ARC). If it's an atomic building block that you just describe and reference, it's a component (CMP).

**Example:**
- A specific ADC chip (AD7175-2) --> CMP Individual Part (leaf component, no internal decomposition needed)
- A "Data Acquisition Module" containing ADC + amplifier + filtering --> ARC (has subcomponents, requirements allocated)
- A mounting bracket with screws and standoffs --> CMP Assembly (composed of parts, has physical boundaries)

---

## Minimal Rules for Consistency
- No values without source.
- No duplication of detailed knowledge: better create subpage and link.
- CMP remains readable: profile first, details only as links.
