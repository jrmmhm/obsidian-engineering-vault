
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
- **DOM**: scope token of the file. Taken from the file's own `id` (`REQ-_DOM_-000`) when it carries one, and from the parentheses after the file name otherwise, e.g. `KRA`
- **NNN**: sequential number within this file (001, 002, 003 …) – appears as ID in the table

**Important:**
- Only **NNN** is entered in the table. The Full-ID is automatically derived from **DOM + NNN**.
- **DOM is stable**: meaning of DOM is never changed. Once the file carries an `id`, renaming the file does not change DOM either — identity lives in the frontmatter, not in the file name.
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

**Recommended sentence patterns (EARS).** Constraining requirements to
these five patterns measurably reduces ambiguity:
- Ubiquitous: "The `<system>` shall `<response>`."
- Event-driven: "When `<trigger>`, the `<system>` shall `<response>`."
- State-driven: "While `<state>`, the `<system>` shall `<response>`."
- Unwanted behavior: "If `<condition>`, then the `<system>` shall `<response>`."
- Optional feature: "Where `<feature>`, the `<system>` shall `<response>`."

**Anti-smells.** Avoid the defects with the largest measured impact on
both human and AI interpretation:
- No pronouns whose referent is outside the sentence ("it", "the system
  above") — referential ambiguity causes the most wrong interpretations.
- One requirement per row, atomic — no "and also" chains.
- Every value measurable with a stated pass/fail condition.
- No contradictions with other rows or files — a contradicting spec is
  worse than a missing one.

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


