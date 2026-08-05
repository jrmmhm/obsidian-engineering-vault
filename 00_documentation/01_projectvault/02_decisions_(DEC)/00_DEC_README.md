
DEC files document **decisions** (why we do X instead of Y), so that the system remains traceable later, without having to maintain implementation details or requirements twice. The file template can be found at: [[00_DEC_file_template]].

## IMPORTANT

IF the statement:
  - Represents a choice between alternatives
  - Has a justification/trade-off analysis
  - Could have been different
THEN: Decisions (DEC)


## Structure

Every DEC file uses the fixed schema:
1. Date
2. Status
3. optional "Superseded by" link
4. Context
5. Options
6. Decision
7. Justification
8. Consequences

## 2) Status

- **Draft**: work in progress, not yet final
- **Accepted**: currently valid and is the active decision
- **Superseded**: has been replaced by a newer decision
    **Rule:** must contain a link `Superseded by: [[DEC_...]]` + short reason (1 sentence)
- **Deprecated**: no longer relevant (e.g. discarded, without direct successor)

**Rule:** Decisions are not deleted "silently" if they were ever implemented or discussed relevantly. Instead, set to **Superseded**. Only trivial incorrect notes that were never used may be removed.

## Implementation leakage (`impl-leak`)

The vault validator reads the **Context** section of a DEC file and reports
a number carrying a unit, or a pin or register token, as `impl-leak` (WARN).
Context frames the problem and the forces that act on it; a number that
weighs an alternative belongs in **Options**, and a number that says how the
thing is built belongs in IMP, CMP or IFC. ARC is not the destination: ARC
stores no values, and the same check reports one there as an ERROR.
