# 02_Dokumente

## Zweck
Dieser Ordner enthält **projektinterne Dokumente**, die nicht als Markdown im Projektvault gepflegt werden, aber eine dokumentarische Funktion im Projekt erfüllen.

Typische Inhalte:
- Eigene Messberichte als PDF
- Projektspezifische Zeichnungen und Exporte
- Fotos von Testaufbauten
- Kalibrierscheine eigener Messgeräte
- Interne Präsentationen und Reports

## Abgrenzung zu 50_Quellen
| Kriterium | 02_Dokumente | 50_Quellen |
|-----------|--------------|------------|
| Herkunft | Projektintern erstellt | Extern (Hersteller, Normen, Literatur) |
| Beispiele | Eigene Messberichte, Testfotos, Projektzeichnungen | Datenblätter, Normen, Paper, Handbücher |
| Änderbarkeit | Kann im Projekt geändert werden | Unverändert übernommen |

**Faustregel:** Wenn das Dokument von außerhalb des Projekts stammt (Hersteller, Normungsgremium, Verlag), gehört es in `50_Quellen`. Wenn es im Projekt erstellt wurde, gehört es in `02_Dokumente`.

## Ordnerstruktur
Die Unterordner spiegeln die Struktur des Projektvaults:
- `01_Anforderungen_(ANF)/`
- `02_Entscheidungen_(ENT)/`
- `03_Architektur_(ARC)/`
- `04_Komponenten_(KMP)/`
- `05_Schnittstellen_(SST)/`
- `06_Implementierung_(IMP)/`
- `07_Test_und_Evidenz_(TUE)/`
- `08_Betrieb_und_Nutzung_(BUN)/`
- `09_Referenzen_(REF)/`

Die Einordnung erfolgt nach derselben Logik wie im Vault: Messergebnisse → `07_Test_und_Evidenz_(TUE)/`, Architekturdiagramme → `03_Architektur_(ARC)/` etc.

---

## Namenskonvention

### Allgemeines Schema
`Typ__Beschreibung__YYYY-MM-DD__rev-N.ext`

**Bestandteile:**
- `Typ`: Dokumenttyp (siehe Tabelle unten)
- `Beschreibung`: Kurze, eindeutige Beschreibung (lowercase, `_` statt Leerzeichen)
- `YYYY-MM-DD`: Erstellungsdatum oder Messdatum
- `rev-N`: Revisionsnummer (integer, beginnend bei 1)
- `ext`: Dateiendung (pdf, jpg, png, xlsx etc.)

### Dokumenttypen (Typ)

| Typ | Beschreibung | Beispiel |
|-----|--------------|----------|
| `report` | Messberichte, Analysen, Auswertungen | `report__spannungsteiler_kalibrierung__2025-01-15__rev-1.pdf` |
| `photo` | Fotos von Aufbauten, Komponenten, Tests | `photo__testaufbau_hv_messung__2025-01-20__rev-1.jpg` |
| `drawing` | Zeichnungen, Skizzen, Diagramme | `drawing__gehaeuse_abmessungen__2025-01-10__rev-2.pdf` |
| `certificate` | Kalibrierscheine, Zertifikate | `certificate__multimeter_fluke87__2024-12-01__rev-1.pdf` |
| `presentation` | Interne Präsentationen | `presentation__projektreview_q1__2025-03-15__rev-1.pdf` |
| `export` | Exporte aus Tools (KiCad, CAD etc.) | `export__messplatine_schematic__2025-01-18__rev-3.pdf` |
| `log` | Protokolle, Logdateien | `log__inbetriebnahme_mcu__2025-01-22__rev-1.pdf` |

### Beispiele

**07_Test_und_Evidenz_(TUE)/**
- `report__isolationsmessung_platinengehaeuse__2025-01-15__rev-1.pdf`
- `photo__testaufbau_isolationsmessung__2025-01-15__rev-1.jpg`
- `certificate__ME_mit410__2024-06-01__rev-1.pdf`

**03_Architektur_(ARC)/**
- `drawing__systemuebersicht_blockschaltbild__2025-01-05__rev-2.pdf`
- `export__systemarchitektur_diagramm__2025-01-10__rev-1.png`

**06_Implementierung_(IMP)/**
- `export__messplatine_schematic__2025-01-18__rev-3.pdf`
- `export__messplatine_layout__2025-01-18__rev-3.pdf`
- `photo__pcb_bestueckt_oberseite__2025-01-20__rev-1.jpg`

---

## Regeln

1. **Keine externen Quellen hier ablegen.** Datenblätter, Normen, Paper → `50_Quellen`.
2. **Keine Markdown-Dateien.** Strukturierte Dokumentation → `01_Projektvault`.
3. **Versionierung im Dateinamen.** Bei Änderungen `rev-N` erhöhen, alte Version behalten oder in `99_Archiv` verschieben.
4. **Referenzierung aus dem Vault.** IMP- und TUE-Dateien verweisen auf Dokumente hier per relativem Pfad.
