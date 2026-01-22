IMP-Notizen dokumentieren die konkrete Umsetzung eines Moduls / Submoduls des Systems.  
Sie bilden die Brücke zwischen der Dokumentation und der realen Implementierung (Hardware, Firmware, Mechanik, Konfiguration).

IMP beschreibt wie es umgesetzt ist und wo relevante Dateien liegen – nicht warum und nicht wie das System architektonisch aufgebaut ist.


## Ziel
- Konkrete Implementierungen eindeutig festhalten
- Externe Artefakte (Schaltpläne, CAD, Code, Konfigurationen) auffindbar machen
- Abweichungen und Festlegungen dokumentieren, die sonst nirgends eindeutig stehen

IMP ist bewusst **minimal** und **faktenorientiert**.

## Aufbau einer IMP-Datei

### 1) Kontext
Kurze Beschreibung dessen, was hier konkret implementiert oder festgelegt wird.

**Inhalt:**
- Was wird umgesetzt oder konfiguriert?
- Auf welchen Aspekt des Systems bezieht sich diese Implementierung?

**Regeln:**
- 1–3 Sätze
- Optional Links auf relevante Dateien
- Keine Architektur- oder Entscheidungsbegründungen

---

### 2) Verweise
Liste der externen Artefakte, die die Implementierung darstellen oder enthalten.

**Eintrag:**
- Reiner Dateipfad relativ zum Projekt-Root  
  (kein Obsidian-Link, kein file://-Link, keine Inhalte kopieren)

**Beispiele:**
- Schaltplan: `Projektname/01_Hardware/02_KiCAD/Messplatine.kicad_sch`
- PCB-Layout: `Projektname/01_Hardware/02_KiCAD/Messplatine.kicad_pcb`
- CAD: `Projektname/01_Hardware/01_CAD/Gehäuse.step`

**Regeln:**
- Pfade müssen stabil und projektweit eindeutig sein
- Keine Duplikation von Dateien im Vault
- IMP verweist auf Artefakte, es ersetzt sie nicht

---

### 3) Implementierung
Konkrete Festlegungen oder Umsetzungsdetails, die **nicht eindeutig aus anderen Dokumenten hervorgehen**.

**Erlaubt:**
- Tatsächlich gesetzte Parameter
- Konkrete Schaltungs- oder Softwareentscheidungen
- Default-Zustände
- Einschränkungen oder Besonderheiten der Umsetzung

**Beispiele:**
- Relais-Spule wird low-side über N-MOSFET geschaltet
- Pull-down am Gate: 100 kΩ
- Default-Zustand bei Reset: Relais aus
- SPI-Takt fest auf 5 MHz eingestellt

**Regeln:**
- Nur Fakten, keine Begründungen
- Keine Wiederholung von ARC- oder ENT-Inhalten
- Keine Testergebnisse (gehören in TST/EVD)


