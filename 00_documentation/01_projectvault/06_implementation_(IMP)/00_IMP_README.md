IMP notes document the concrete implementation of a module / submodule of the system.
They form the bridge between the documentation and the real implementation (hardware, firmware, mechanics, configuration).

IMP describes how it is implemented and where relevant files are located – not why and not how the system is architecturally structured.


## Goal
- Record concrete implementations unambiguously
- Make external artifacts (schematics, CAD, code, configurations) findable
- Document deviations and specifications that are not clearly stated elsewhere

IMP is deliberately **minimal** and **fact-oriented**.

## IMPORTANT 

IF the document describes:
  - HOW the artifact was built/designed (static design decisions)
  - Paths to source files, CAD files, schematics
  - Design parameters, register settings, pinouts
THEN: Implementation (IMP)

## IMPORTANT FOR SOFTWARE

Implementation_(IMP) contains:
  - LINKS/PATHS to 20_software/ artifacts
  - High-level implementation notes (architectural implementation)
  - NOT duplicated Code-Blocks

**RULES:**
- IMP never duplicates code-level docs
- IMP files are SHORT (1-2 pages max)
- IMP files are pointers, not duplicates. Link to actual artifacts.

## Artifacts on Other Machines

The pointer rule protects one property: a copied artifact drifts against its original, a path cannot.
It therefore applies to artifacts this project owns — things that exist as files in this repository.

A system whose parts run on other machines has artifacts that are not files here and never will be: the state of a directory on a server, a configuration in effect on a host, a command that establishes or verifies one.
There is no path to point at, because there is no file.
Such a block is not a copy of anything — it is the only record of an observation, and its currency is carried by `last-verified`, not by a source file.

**Rules:**
- A block up to 15 content lines is a single observation. It needs no declaration.
- A longer block must either give way to a path pointing at the file it was copied from, or name the machine it is true on, written into the fence's info string after the language:

```bash host=userver
systemctl --user status navidrome
```

- Use the same machine name you would use in a host-qualified path (`userver:/etc/systemd/system/navidrome.service`). It is the name under which the machine is documented, not an IP and not a connection string.
- Never write `localhost`. The vault is read on other machines than the one you are sitting at, and `localhost` names a different machine for every reader.
- A declared block is reported as a warning, deliberately: nothing can verify that no source file exists, so the claim stays visible and is yours.
- A repeatable multi-step procedure belongs in OAU. A single command that verifies one fact is not a runbook — it stays with the fact it proves.
- In ARC none of this applies: ARC is a map and holds no blocks at all.


## Structure of an IMP File

### 1) Context
Brief description of what is concretely implemented or specified here.

**Content:**
- What is being implemented or configured?
- Which aspect of the system does this implementation refer to?

**Rules:**
- 1–3 sentences
- Optional links to relevant files
- No architecture or decision justifications

---

### 2) References
List of external artifacts that represent or contain the implementation.

**Entry:**
- Pure file path relative to project root
  (no Obsidian link, no file:// link, do not copy content)

**Examples:**
- Schematic: `Projectname/10_hardware/13_PCB/Measurement_Board.kicad_sch`
- PCB layout: `Projectname/10_hardware/13_PCB/Measurement_Board.kicad_pcb`
- CAD: `Projectname/10_hardware/11_mechanics_CAD/Housing.step`

**Rules:**
- Paths must be stable and project-wide unique
- No duplication of files in the vault
- IMP refers to artifacts, it does not replace them

---

### 3) Implementation
Concrete specifications or implementation details that **do not clearly emerge from other documents**.

**Allowed:**
- Actually set parameters
- Concrete circuit or software decisions
- Default states
- Limitations or particularities of the implementation

**Examples:**
- Relay coil is switched low-side via N-MOSFET
- Pull-down at gate: 100 kΩ
- Default state at reset: relay off
- SPI clock fixed at 5 MHz

**Rules:**
- Only facts, no justifications
- No repetition of ARC or DEC content
- No test results (belong in TAE/EVD)


