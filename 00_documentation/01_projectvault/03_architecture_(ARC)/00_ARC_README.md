ARC notes describe the architecture of a module as a connecting element between requirements (REQ), decisions (DEC), components (CMP), interfaces (IFC), implementation (IMP) and testing and evidence (TAE).
ARC is the place where it becomes visible **which requirements affect which submodules/interfaces** and **how these requirements are verified** (Allocation + Verification).

---

## Goal and Principles

### Goal
- Document module as a delimited unit (context + components)
- Assign relevant REQ and DEC files (without duplicating content)
- List module interfaces as relationships between endpoints
- Allocate requirements to submodules/interfaces and record verification per allocation

### Principles
- ARC is an **orchestrator**, not a data sink: no implementation details, no measurement values, no lengthy justifications.
- ARC links to responsible documents instead of copying content.


## IMPORTANT

ARC modules need clear delimitation according to a single criterion. There are two sensible axes:

- Physical assemblies (hardware modules), e.g. measurement board, force actuator, uC board, etc.

- Cross-cutting systems, e.g. power supply, safety, logging/data acquisition

It is highly advisable to choose one axis and use it consistently, otherwise modules will overlap.

**Important for physical assemblies:**
If a component has:
- Multiple subcomponents that interact
- Requirements allocated to it
- Internal interfaces between subcomponents
THEN: Create an ARC file (it's a module)
ELSE: Create a CMP file (it's a leaf component)

**Module Hierarchy Rule:**
If an ARC module primarily serves as a container for sub-modules (i.e., it delegates requirements, components, and interfaces to sub-ARCs), use the **Main Module template** ([[00_ARC_main_module_file_template]]). This template only contains Context + Submodule table.

If an ARC module directly owns components, interfaces, and requirement allocations, use the **full ARC template** ([[00_ARC_file_template]]) with all 7 sections.

**Example:**
- `ARC_Electrical` (parent with sub-ARCs for power supply, safety circuit, status indication) --> Main Module template
- `ARC_Electrical__Safety_Circuit` (directly owns components, interfaces, allocations) --> Full ARC template


---

## Structure

### 1) Context
Describes what the module includes and what it does not, using structured Includes/Excludes bullet points and links to relevant modules.

**Rules:**
- Max. 5–7 bullet points
- Use **Includes** / **Excludes** format for clear scope definition
- No implementation details (no pinouts, no registers, no schematics)
- No repetition of REQ/DEC content

---

### 2) Requirements (Files)
List of relevant REQ files (not individual table rows).

**Entry:**
- `[[REQ_...]]`: Why relevant for this module (exactly 1 sentence)

**Rules:**
- Do not copy REQ content
- Exactly one justification sentence per REQ file (no novels)

---

### 3) Decisions (Files)
List of relevant DEC files that influence this module/design.

**Entry:**
- `[[DEC_...]]`: Classification in architecture (exactly 1 sentence)

**Rules:**
- The sentence describes *what* the decision influences architecturally (not *why* it was made)
- No implementation details

---

### 4) Components (Files)
List of components/assemblies that directly form the module.

**Entry:**
- `[[CMP_...]]`: Role in the module (brief, 1 sentence or bullet)

**Rules:**
- Only direct components of the module (do not inflate with "environmental components")

---

### 5) Interfaces
The interface table describes which IFCs the module uses externally (or between submodules) and which endpoints are thereby connected.

**Table format:**

| Interface (IFC) | Endpoint A | Endpoint B | Context |
| --- | --- | --- | --- |

**Column rules:**
- **Interface (IFC):** Link to exactly one IFC note.
- **Endpoint A / Endpoint B:** Links to the two endpoints (typically CMPs). ARC links as endpoints only if endpoints are deliberately kept coarse.
- **Context:** Purpose in a few words (max. 6–10 words). No parameters, no contract text.

**Rule:**
- An IFC does not represent a chain/topology. The table lists point-to-point connections that are relevant in the module context.

---
### 6) Implementation (Files)
List of implementation files that concretely implement the mentioned requirements, decisions, components and interfaces.

**Entry:**
- `[[IMP_...]]`: What is concretely realized (brief, 1 sentence or bullet).

**Rules:**
- Only IMP files that directly belong to the module.

### 7) Allocation and Verification
This table assigns requirements (REQ-IDs, explanation see [[00_REQ_README]]) to a submodule or an interface and links to the verification.

**Table format:**

| Submodule (ARC/CMP/IFC) | Allocated Requirements (REQ-IDs) | Verification (TAE) | Status |
| ----------------------- | -------------------------------- | ------------------ | ------ |

---
#### Column 1 — Submodule (ARC/CMP/IFC)
Object that "owns" the requirements.

**Entry:**
- Link to `[[CMP_...]]` (component/assembly) or `[[IFC_...]]` (interface)

**Rule (readability):**
- ARC rows: requirement for complete module, if finer subdivision would be too complex
- CMP rows: requirements for component/subsystem
- IFC rows: requirements for the connection/signal routing

---
#### Column 2 — Allocated Requirements (REQ-IDs)
The affected requirements as IDs, not as full text.

**Entry:**
- Comma-separated list of REQ-IDs, e.g. `REQ-SAE-001, REQ-MEG-004`

**Rules:**
- Exact spelling of IDs
- No content duplication

---
#### Column 3 — Verification (TAE)
Links to test/inspection/analysis notes that demonstrate fulfillment of the assigned requirements for this submodule.

**Entry:**
- one or more links, e.g. `[[TAE_...]]`
- for multiple proofs: multiple links are allowed

**Rule:**
- If the status is to be set to **Verified** later, at least one link must exist here.
- Verification is managed per submodule/interface (not "one test for everything").

---
#### Column 4 — Status
Status of the **allocation** (not of the REQ file as a whole).

**Entry (recommended):**
- **Draft**: allocation/verification in progress (TAE may be missing or TBD)
- **Approved**: allocation is set, verification plan exists (TAE link or TBD)
- **Verified**: verified (TAE/INS/ANA performed + result/evidence available)
- **Deprecated**: allocation no longer valid (e.g. architecture changed), remains historically preserved
- **Blocked**: currently not verifiable/implementable (dependency missing)

**Rule:**
- Only set **Verified** if a TAE/INS/ANA link exists and the associated evidence is documented.
