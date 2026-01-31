# SOURCES – Ablage- und Benennungsregeln

Quellen ist der zentrale Pool für externe Quellen (PDFs, CAD-Modelle, Normen, Libraries etc.).
Semantik/Parameter (z. B. “welcher Widerstand kann was?”) wird NICHT hier gepflegt, sondern in einer separaten Katalog-Datei im entsprechenden Ordner (z. B. `00_catalog.csv`).

Grundregeln:
- Dateinamen sind die primäre Metadatenquelle.
- Keine tiefen Ordnerbäume (max. wenige Ebenen).
- Jede Datei trägt eine Versions-/Revisionskennung im Namen: `__rev-...` (Dokumente) oder `__v-...` (Modelle/Exports).
- Domain (Mechanik/Elektronik/…) steckt im Ordner, nicht im Dateinamen.

---

## 01_datasheets
**Inhalt**
- Datenblätter, Errata, PCNs, EOLs, Safety-Sheets, App Notes (sofern klar bauteilbezogen).

**Dateinamenkonvention**
`Vendor__MPN_or_Model__DocType__rev-RevOrYear.pdf`

**Variablen**
- `Vendor` = Hersteller/Quelle als kurzer stabiler Name (z. B. `AnalogDevices`, `Bosch`, `Murata`)
- `MPN_or_Model` = konkrete Teilenummer / Modellbezeichnung (z. B. `AD7175-2`, `BME280`, `C3216X7R1E106K`)
- `DocType` = Dokumenttyp (kontrolliertes Vokabular, siehe unten)
- `rev-RevOrYear` = Revision, Versionscode oder Datum (z. B. `rev-F`, `rev-1.6`, `rev-2024-05-02`)

**DocType (Empfehlung)**
- `datasheet`
- `appnote`
- `errata`
- `pcn`
- `eol`
- `safety`

**Beispiele**
- `AnalogDevices__AD7175-2__datasheet__rev-F.pdf`
- `Bosch__BME280__datasheet__rev-1.6.pdf`
- `Murata__C3216X7R1E106K__datasheet__rev-2024.pdf`

---

## 02_paper
**Inhalt**
- Wissenschaftliche Paper (PDF), Preprints, Konferenzbeiträge.

**Dateinamenkonvention**
`FirstAuthorEtAl__YYYY__shorttitleslug.pdf`

**Variablen**
- `FirstAuthorEtAl` = Nachname des ersten Autors + `EtAl` (z. B. `RossetEtAl`)
- `YYYY` = Veröffentlichungsjahr (vierstellig)
- `shorttitleslug` = kurzer Titel-Slug, lowercase, `_` statt Leerzeichen (z. B. `dielectric_elastomer_actuators_review`)

**Beispiel**
- `RossetEtAl__2016__dielectric_elastomer_actuators_review.pdf`

---

## 03_books
**Inhalt**
- Fachbücher als PDF/Scan, offizielle E-Books, Buchkapitel (wenn als Buchquelle geführt).

**Dateinamenkonvention**
`Author__YYYY__shorttitleslug__ed-n__LANG.pdf`

**Variablen**
- `Author` = Nachname (bei mehreren: erster Autor/Editor als Hauptanker)
- `YYYY` = Erscheinungsjahr
- `shorttitleslug` = kurzer Titel-Slug (lowercase, `_`)
- `ed-n` = Edition/Auflage als Zahl (z. B. `ed-1`, `ed-3`)
- `LANG` = Sprache (z. B. `DE`, `EN`), weil hier relevant

**Beispiel**
- `HerbertBernstein__2020__Messen-mit-dem-Oszilloskop__ed-3__DE.pdf`

---

## 04_standards
**Inhalt**
- Normen als PDF (Volltext oder Auszug), normative Dokumente.

**Dateinamenkonvention**
`DIN_EN_...__YYYY__LANG__full.pdf`
oder
`DIN_EN_...__YYYY__LANG__excerpt.pdf`

**Variablen**
- `DIN_EN_...` = Normenkennung, wie sie offiziell geführt wird (mit `_` statt Leerzeichen/Bindestrich-Trennung nach Bedarf)
- `YYYY` = Ausgabejahr / Stand
- `LANG` = Sprache (`DE`, `EN`, …)
- `full|excerpt` = Volltext oder Auszug

**Beispiele**
- `DIN_EN_61010-1__2020__DE__full.pdf`
- `DIN_EN_50191__2011__DE__full.pdf`
- `DIN_VDE_0100-410__2018__DE__excerpt.pdf`

---

## 05_manuals
**Inhalt**
- Handbücher, Programming Guides, User Manuals, Installationsanleitungen, Bedienungsanleitungen (nicht primär “Bauteil-Datenblatt”, sondern Produkt-/Systemdoku).

**Dateinamenkonvention**
`Vendor__Product__DocType__rev-RevOrYear.pdf`

**Variablen**
- `Vendor` = Hersteller/Quelle
- `Product` = Produktname/Modell (z. B. `USB220`, `Siglent_SDS814X_HD`)
- `DocType` = Dokumenttyp (siehe unten)
- `rev-RevOrDate` = Revision/Version/Datum (z. B. `rev-2025-03-01`)

**DocType**
- `user-manual`
- `programming-guide`
- `hardware-guide`
- `installation-guide`
- `release-notes`

**Beispiel**
- `Futek__USB220__user-manual__rev-2023.pdf`

---

## 06_licenses
**Inhalt**
- Lizenztexte, EULAs, Kaufbelege für Normen/Tools, Terms, Rechnungen zu Quellen (wo nötig).

**Dateinamenkonvention**
`VendorOrSource__Item__YYYY-MM-DD__doctype.pdf`

**Variablen**
- `VendorOrSource` = Quelle/Anbieter (z. B. `Beuth`, `Autodesk`, `AnalogDevices`)
- `Item` = was genau (z. B. Norm-ID, Software, Subscription)
- `YYYY-MM-DD` = Datum
- `doctype` = `invoice` | `license_text` | `terms`

**Beispiel**
- `Beuth__DIN_EN_61010-1__2025-08-27__invoice.pdf`

---

## 07_CAD_files
**Inhalt**
- 3D-Modelle (STEP, STL), Zeichnungen/Exports, Footprint- oder Gehäusemodelle, herstellerbezogene CAD-Daten.
- Keine Projekt-CAD-Quellen (die liegen im jeweiligen Projekt), sondern wiederverwendbare Referenzmodelle.

**Dateinamenkonvention**
`VendorOrSource__MPN_or_Model_or_Name__v-n.ext`

**Variablen**
- `VendorOrSource` = Hersteller oder Quelle (z. B. `Schuetzinger`, `Molex`, `Generic`)
- `MPN_or_Model_or_Name` = Modell/Teilenummer oder klarer Name
- `v-n` = interne Version des gespeicherten Files (integer)
- `ext` = Dateiendung (`step`, `stl`, `dxf`, `pdf`, …)

**Beispiele**
- `Schuetzinger__HV_Connector_XYZ__v-1.step`
- `Generic__M3_standoff_20mm__v-1.step`

---

## 08_libs
**Inhalt**
- Bibliotheken für Software-Tools (wiederverwendbar, tool-spezifisch).
- Struktur: ein Ordner pro Software.

**Unterordnerkonvention**
- `kicad/`
- `ltspice/`
- `zotero/` (falls du hier Dinge ablegen willst, ansonsten extern)
- weitere Tools nach Bedarf

**Benennung innerhalb**
- Tool-intern sinnvoll benennen, aber Versionsstände über Ordner oder Tags abbilden (nicht über 20 Ebenen).

---

## 09_rest
**Inhalt**
- Temporäre Ablage für Quellen, die noch nicht sauber klassifiziert sind.
- Ziel: regelmäßig leeren (einsortieren oder löschen).

**Konvention**
- Keine besonderen Regeln außer: sobald klar → in passenden Ordner verschieben und korrekt benennen.
