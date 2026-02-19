REF notes document external sources (standards, datasheets, books, papers, websites) so that they are quickly findable, traceable and usable in the project.
REF is not a literature management replacement and not a complete transcription, but a project-related extract: **What is relevant and where is it located?**

---

## Goal
- Reference sources unambiguously (reference manager + optional file storage in 50_sources)
- Briefly justify relevance of the source for the project
- Extract project-relevant statements in structured form (chapter by chapter, if sensible)
- Ensure traceability: each statement can be traced back to the source

## IMPORTANT

IF the document is:
  - A summary/extract of an external source (datasheet, paper, standard)
  - Immutable content (external truth)
  - No project-specific measurements
THEN: References (REF)


---

## Structure

### 1) Source(s)
Contains the primary reference to the source.

Mandatory:
- Reference manager link (e.g. Zotero, Mendeley, Citavi, or similar)

Optional:
- Project path to file in `50_sources` (relative to project root), e.g.
  `Projectname/50_sources/Standards/DIN_EN_61010-1.pdf`

Rules:
- Do not copy content into REF if it exists as a file (only reference)
- Paths must be stable and unique

---

### 2) Context
Brief classification:
- What is the source? (standard, datasheet, paper, book, website)
- Why is it relevant for the project?

Rules:
- 1–5 sentences
- No long summary, only relevance argument

---

### 3) Content
Extracts exclusively the statements that are actually used in the project or relevant as boundary conditions.

Structure:
- Bullet points
- optionally chapter-wise organization (recommended for standards/books)

Examples:
- Requirements/protection principles
- Limit values, definitions, test requirements
- safety-relevant boundary conditions
- EMC-relevant statements

Rules:
- Only relevant points, no complete content reproduction
- Formulate statements precisely
- If possible, unambiguously name chapter/section (chapter heading is sufficient, page number optional)


