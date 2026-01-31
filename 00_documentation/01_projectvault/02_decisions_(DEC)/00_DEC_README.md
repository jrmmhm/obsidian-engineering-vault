
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
