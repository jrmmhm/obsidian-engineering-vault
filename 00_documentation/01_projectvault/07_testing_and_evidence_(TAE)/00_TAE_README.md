TAE notes document tests, investigations and evidence including test conditions, limitations and traceable conclusions.

## Goal
- Record traceably what was tested and under which conditions
- Document evidence (measurement values/observations) in structured form
- Make limitations transparent
- Derive a clear conclusion from the evidence

## IMPORTANT

IF the document is:
  - Project-specific test results
  - Measurements performed by the operator
  - Verification evidence for a requirement
THEN: Testing and Evidence (TAE)


## Structure of a TAE File

### 1) Context
Briefly describes what was tested/investigated.

Rules:
- 1–3 sentences
- No background novel

---

### 2) Test Conditions
All conditions/prerequisites necessary to reproduce the test or interpret it correctly.

Typical content:
- Test object (recommended): Link to [[CMP_...]] or [[IFC_...]] or [[ARC_...]]
- Test setup / used equipment (only as far as relevant)
- Environmental conditions (temperature/humidity/EMC), if relevant
- Prerequisites (e.g. calibration, warm-up time, configuration)

Rule:
- Only document what influences significance.

---

### 3) References
List of external artifacts that support or supplement the test.
Only file paths relative to project root are used.

Examples:
- Calibration certificate: Projectname/00_documentation/02_documents/07_testing_and_evidence/Oscilloscope_Calibration_Certificate.pdf
- Photos: Projectname/00_documentation/02_documents/07_testing_and_evidence/Test_Setup_Photo_01.jpg
- Raw data: Projectname/30_testdata/31_testdata_raw/run_2026-01-20.csv

Rules:
- Do not copy content into TAE
- Paths must be stable and unique

---

### 4) Limitations
All limitations that influence reliability, accuracy or transferability.

Examples:
- Measurement range limit reached (saturation)
- Unclear boundary conditions (e.g. temperature not controlled)
- Sample too small
- Setup not fully representative

Rule:
- Rather too many limitations than too few, if they influence interpretation.

---

### 5) Evidence
Concrete results/observations, preferably in table form.

Rules:
- Measurement values/observations clearly structured
- Specify units consistently in table header
- Do not duplicate raw data: if there is a lot of data, refer to file and only document summary/extract here

---

### 6) Conclusion
Derivation from the evidence: What is the result?

Rule:
- Do not introduce new measurement values or assumptions into the conclusion.

