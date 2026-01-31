OAU notes describe the workflow for operation and usage as a reproducible runbook/tutorial.
OAU is written for humans: clear steps, clear checks, clear abort rules.

OAU describes how the system is operated — not how it is structured (ARC), not why decisions were made (DEC) and not how something is implemented (IMP).

## Goal
- Document operating procedures reproducibly (even after months/years)
- Avoid operating errors through checkpoints and clear responses
- Monitor operation (only what is not automatically monitored/enforced)
- Quickly remedy common error patterns

## IMPORTANT

IF the document describes:
  - ACTIONS a human takes to operate/maintain the system
  - Procedures that repeat over system lifetime
  - Runbooks, checklists, calibration steps
THEN: Operation and Usage (OAU)


---

## Structure

### 1) Context
Brief description of the workflow.
- What is this workflow intended for? (1–3 sentences)
- Target state after successful workflow (1 sentence)

Rules:
- No architecture explanations
- No justifications/decision rationales

### 2) Prerequisites
Only prerequisites that cannot be reliably enforced or detected by the system (hardware/firmware).

Allowed content:
- Hardware/setup available (brief)
- Safety prerequisites that cannot be enforced by project modules
- required software/tools (if relevant)
- required files/configs (path relative to project, if relevant)

Not allowed:
- Prerequisites that are already checked/enforced by the system (interlock/emergency stop etc.).
  These belong as a check in the workflow, not as a prerequisite.

### 3) Workflow
Step-by-step instructions for normal operation as a table.

Table format:

| Step | Action | Expectation / Check | If not fulfilled |
| ---: | ------ | ------------------- | ---------------- |

Rules:
- Exactly one action per step
- Each action has an objective check ("how do I know it works?")
- "If not fulfilled" always contains a clear response:
  - Abort, or
  - defined error correction, or
  - Reference to troubleshooting

Formulation rules:
- No vague statements ("should", "normally")
- Instead: measurable, visible, unambiguous

### 4) Operation Monitoring
Describes what must be observed during operation, if it is not automatically monitored.

Allowed content:
- Displays/measurement values that the operator must check
- manual limit value observation, if not automatically available
- Logging/files, if the operator must actively check

Not allowed:
- Redefine requirements (REQ)
- Copy technical details from IMP

### 5) Troubleshooting
Brief table for the most common error patterns.

Table format:

| Symptom | Possible Cause | Action/Reference |
| ------- | -------------- | ---------------- |

Rules:
- Only common, real cases (no theoretical novels)
- Actions are concrete or refer to an appropriate OAU/IMP/TAE note
- No deep root cause analyses (that is debug/analysis work, not OAU)


## Shutdown / Emergency
Shutdown procedures are maintained as separate OAU files (Single Source of Truth), e.g.:
- [[OAU_Shutdown_Normal]]
- [[OAU_Shutdown_Emergency]]

OAU workflows refer to these instead of duplicating shutdown steps.
Deviations are only permissible if they are workflow-dependent and explicitly stated.

