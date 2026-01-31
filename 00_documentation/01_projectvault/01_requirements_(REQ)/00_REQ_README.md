
REQ files document which requirements are placed on the system. The file template can be found at [[00_REQ_file_template]]. Each requirement exists exactly once and is linked to a requirement ID. The explanation of the requirement ID and the table columns can be found in this file.

## IMPORTANT

IF the statement:
  - Comes from external source (customer, regulation, physics)
  - Is non-negotiable / given
  - Defines acceptance criteria
THEN: Requirements (REQ)


## Requirement ID

The ID of each requirement table row is unique and allows unambiguous assignment of requirements to project modules / components. Each requirement has a **Full-ID** according to the schema:

**REQ-_DOM_-_NNN_**

- **REQ**: Prefix for "Requirement"
- **DOM**: 3-letter domain abbreviation of the file (appears after the file name in parentheses, e.g. `KRA`)
- **NNN**: sequential number within this file (001, 002, 003 …) – appears as ID in the table

**Important:**
- Only **NNN** is entered in the table. The Full-ID is automatically derived from **DOM + NNN**.
- **DOM is stable**: meaning of DOM is never changed.
- **NNN is never reused or renumbered**. Gaps are allowed.
- If a requirement becomes obsolete: ID remains occupied.

**Example:**
- File = `Force_Actuator (KRA)`
- Table row NNN = `007`
    → Full-ID = **REQ-KRA-007**

---
## Structure


### Context
Describes which topic of requirements the module covers and what it does not, including links to relevant submodules.


### Table
The requirements are listed as rows in a table with fixed columns. Each column has exactly one task.

| Class (M/S/O) | NNN | Content | Acceptance Criterion | Source / Justification (REF/DEC) |
| ------------- | --: | ------- | -------------------- | -------------------------------- |

### Column 1 — **Class (M/S/O)**

Binding nature / priority of the requirement.
- **M** (Mandatory): Must be fulfilled. Without fulfillment no release / unsafe / core function not provided.
- **S** (Should): Should be fulfilled. Deviation is possible, but must be justified.
- **O** (Optional): Optional. Nice-to-have, no justification necessary if not implemented.

**Entry:** exactly one character `M`, `S` or `O`.

---
### Column 2 — **NNN**

The sequential number of the requirement within the file.
**Entry:** `001`, `002`, `003` … (always 3 digits)

**Rules:**
- do not resort by renumbering
- do not reuse
- continuous numbering is _not_ necessary

---
### Column 3 — **Content**

The actual requirement as a **unique technical statement**.

**Good:**
- "Door opening must deactivate HV release within ≤ 100 ms."

**Bad:**
- "Door must be safe." (not testable)

---
### Column 4 — **Acceptance Criterion**

Measurable or clearly verifiable criterion, based on which the decision is made: fulfilled / not fulfilled.
**Entry:** limit values, conditions, measurement setup framework, clear pass/fail condition.

Examples:
- "Pass, if HV_Enable goes to 0 within ≤ 100 ms after door signal = open."
- "Pass, if PE continuity < 0.1 Ω between terminal block and housing."

---

### Column 5 — **Source / Justification (REF/DEC)**

Where does the requirement come from or why does it exist?

**Entry:**
- `[[REF_...]]` (standard, datasheet, paper)
- and/or `[[DEC_...]]` (decision/ADR that justifies this)
- optionally free short text in addition (e.g. "DIN EN 61010-1"), but better as reference note.


