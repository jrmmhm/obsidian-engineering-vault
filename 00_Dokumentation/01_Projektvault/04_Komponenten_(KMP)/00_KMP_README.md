KMP-Notizen dokumentieren Komponenten und Baugruppen als eigenständige, wiederverwendbare Bausteine.  
Eine KMP-Notiz ist bewusst minimal: Sie ist ein Steckbrief mit Quellen und Einstiegspunkt zu Details.

## Single Source of Truth (SSOT) – Pflichtregel
Jeder “Aspekt” einer Komponente bekommt eine eigene Datei, sobald er mehr als Kurzinfo benötigt.

**Regel:**
- Eine Information wird nur einmal gepflegt.
- Die Haupt-KMP-Datei bleibt Steckbrief; Details werden ausgelagert und verlinkt.

**Beispiele für Aspekte (jeweils eigene Datei):**
- Operating Limits / Derating / Thermik
- Layout- und EMV-Hinweise
- Kalibrierung / Genauigkeit / Drift

**Konvention (empfohlen):**
- KMP_Name_Interfaces
- KMP_Name_OperatingLimits
- KMP_Name_Layout
- KMP_Name_Calibration
- KMP_Name_Notes

## Aufbau einer KMP-Datei (Pflichtabschnitte)

### 1) Quelle(n)
Hier stehen ausschließlich Links auf die verwendeten Primärquellen (z.B. Datenblatt, Appnote, Produktseite).  
Bevor Zahlen/Behauptungen in KMP notiert werden, muss eine Quelle existieren.

**Beispiel:**
- Zotero-Link: Datenblatt
- Zotero-Link: Appnote / Referenzdesign

---
### 2) Kontext
Kurze Beschreibung der Komponente/Baugruppe (3–5 Sätze):
- Was ist es?
- Welche Funktion erfüllt es?
- Welche Besonderheiten sind relevant?

---
### 3) Allgemeine Übersicht (Tabelle)
Die Übersicht enthält nur die wichtigsten Kenndaten (Key Specs), die als schneller Einstieg dienen.

**Pflichtfelder (empfohlen):**
- Typ
- Hersteller / Modell
- Revision / Variante (falls relevant)

Zusätzlich: wenige Key Specs (z.B. Bit-Tiefe, kS/s, Kanäle) — nur so viele wie sinnvoll.

---
## Was in KMP nicht hinein gehört
- Architekturzuordnung (“ist Teil von ARC_X”) → ergibt sich über Backlinks/ARC
- Schnittstellenverträge/Parameter (Pegel, Timing, Busmodus) → gehören in SST
- Umsetzung (Wiring, GPIO, Register, Code, konkrete Schaltplanstellen) → gehört in IMP
- Testergebnisse/Messwerte → gehören in TST/EVD (KMP darf verlinken)

---
## Minimal-Regeln für Konsistenz
- Keine Werte ohne Quelle.
- Keine Dopplung von Detailwissen: lieber Unterseite erstellen und verlinken.
- KMP bleibt lesbar: Steckbrief zuerst, Details nur als Links.
