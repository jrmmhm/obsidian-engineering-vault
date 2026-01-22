# Projektübersicht

Diese Ordner enthalten Hardware, Software, Testdaten, Beschaffung, Quellen sowie die vollständige Projektdokumentation.
Die technische Dokumentation wird im Projektvault geführt (/00_Dokumentation/01_Projektvault) und ist der zentrale Einstiegspunkt.

---

## Schnellstart (Dokumentation lesen)
Es wird stark empfohlen "Obsidian" als Software für die technische Dokumentation zu verwenden. 

1) Obsidian öffnen  
2) "Ordner als Vault öffnen"  
3) Ordner auswählen: `PMDE/00_Dokumentation/01_Projektvault`  
4) Einstieg: `00_README` im Vault lesen


## Ordnerstruktur (Überblick)

### 00_Dokumentation
- `01_Projektvault/`  
  Obsidian-Vault. Enthält die gesamte strukturierte Projektdokumentation.

  **Wichtig:** Auschließlich Markdown-Dateien (.md).
- `02_Dokumente/`
  Exporte, PDFs, ergänzende Dokumente, die nicht als Markdown-Notizen gepflegt werden, aber eine der Aufgaben im Projektvault erfüllen.

  **Wichtig:** Alle hier gespeicherten Dokumente sind projektintern. Externe Quellen liegen unter "50_Quellen".


`01_Projektvault/` und `02_Dokumente/` teilen sich die gleiche Hauptordnerstruktur. Um diese Struktur zu verstehen, wird empfohlen 00_README in `01_Projektvault/` zu lesen.

---

### Abgrenzung: 02_Dokumente vs. 50_Quellen

| Kriterium | 02_Dokumente (intern) | 50_Quellen (extern) |
|-----------|----------------------|---------------------|
| **Herkunft** | Im Projekt erstellt | Von außen übernommen |
| **Änderbarkeit** | Kann im Projekt geändert werden | Unverändert übernommen |

**Beispiele für 02_Dokumente (intern):**
- Eigener Messbericht zur Spannungsteiler-Kalibrierung
- Foto des Testaufbaus
- Projektspezifische Systemübersicht als PDF-Export
- Kalibrierschein des eigenen Multimeters
- Interne Präsentation zum Projektreview

**Beispiele für 50_Quellen (extern):**
- Datenblatt des AD7175-2 von Analog Devices
- DIN EN 61010-1 Norm als PDF
- Handbuch des Oszilloskops vom Hersteller
- wissenschaftliches Paper über dielektrische Elastomere
- STEP-Modell eines Steckverbinders vom Hersteller

**Faustregel:** Stammt das Dokument von einem Hersteller, Verlag oder Normungsgremium? → `50_Quellen`. Wurde es im Projekt erstellt? → `02_Dokumente`.

### 10_Hardware
Enthält alle Hardware-Entwurfsdaten.
- `11_Mechanik_CAD/` CAD-Quellen (modellierbar)
- `12_Mechanik_Export/` Exporte (STEP, STL, DXF etc.)
- `13_PCB/` Leiterplatten-Design (z.B. KiCad-Projekte)
- `14_Elektronik/` Schaltungen, Simulationen, Zusatzdaten (z.B. LTspice)

### 20_Software
Software-Code nach projektspezifischer Struktur.

### 30_Testdaten
Messdaten und Auswertungen.
- `31_Testdaten_roh/` Rohdaten (unverändert)
- `32_Testdaten_verarbeitet/` aufbereitete Daten (bereinigt, konvertiert)

### 40_Beschaffung
Komplette Beschaffungsdokumentation inkl. BOM und kaufmännischer Nachweise.

### 50_Quellen
Single Source of Truth für externe Quellen und Programmlibraries (Datenblätter, Manuals, Bücher, CAD-Libraries, Zotero-Lib etc.).
Unter 50_Quellen findet sich eine "README.md"-Datei, die den Aufbau, Benennung und Navigation detailiert erläutert.


### 60_Releases
Definierte Projektstände (Baseline-Snapshots). Jeder Release enthält:
- Versionsnummer und Datum
- Git-Tag-Referenz
- Zusammenfassung der Änderungen

### 90_Administration
Projektorganisation auf Ebene von Abgaben/Präsentationen/Exporte.
- Präsentationen, Thesis, Praxisbericht, Exporte, Abgabe-Unterlagen

### 99_Archiv
Ablage für alte Stände, überholte Inhalte, nicht mehr aktive Dokumente.
