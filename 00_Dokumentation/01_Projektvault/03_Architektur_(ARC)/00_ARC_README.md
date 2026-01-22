ARC-Notizen beschreiben die Architektur eines Moduls als verbindendes Element zwischen Anforderungen (ANF), Entscheidungen (ENT), Komponenten (KMP) Schnittstellen (SST), Implementierung (IMP) und Test und Evidenz (TUE).  
ARC ist der Ort, an dem sichtbar wird, **welche Anforderungen auf welche Submodule/Schnittstellen wirken** und **wie diese Anforderungen verifiziert werden** (Allocation + Verification).

---

## Ziel und Prinzipien

### Ziel
- Modul als abgegrenzte Einheit dokumentieren (Kontext + Bestandteile)
- Relevante ANF- und ENT-Dateien zuordnen (ohne Inhalte zu duplizieren)
- Schnittstellen des Moduls als Beziehungen zwischen Endpunkten aufführen
- Anforderungen auf Submodule/Schnittstellen allokieren und Verifikation pro Allokation festhalten

### Prinzipien
- ARC ist **Orchestrator**, keine Datensenke: keine Implementierungsdetails, keine Messwerte, keine langen Begründungen.
- ARC verlinkt auf zuständige Dokumente, statt Inhalte zu kopieren.


## WICHTIG

ARC-Module brauchen klare Abgrenzungen nach einem einzigen Kriterium. Es gibt zwei sinnvolle Achsen:

- Physische Baugruppen (Hardware-Module), z.B. Messplatine, Kraftaktor, uC-Board, etc.

- Querschnittsysteme, z.B. Stromversorgung, Sicherheit, Logging/Datenerfassung

Es ist sehr ratsam sich für eine Achse zu entscheiden und diese konstant zu benutzen, da sich sonst Module überschneiden werden.

---

## Aufbau

### 1) Kontext
Beschreibt, was das Modul umfasst und was nicht, inklusive Verlinkung auf relevante Submodule.

**Regeln:**
- Max. 5–7 Sätze
- Keine Implementierungsdetails (keine Pinouts, keine Register, keine Schaltpläne)
- Keine Wiederholung von ANF/ENT-Inhalten

---

### 2) Anforderungen (Dateien)
Liste der relevanten ANF-Dateien (nicht einzelne Tabellenzeilen).

**Eintrag:**
- `[[ANF_...]]`: Warum relevant für dieses Modul (genau 1 Satz)

**Regeln:**
- Keine ANF-Inhalte kopieren
- Pro ANF-Datei genau ein Begründungssatz (keine Romane)

---

### 3) Entscheidungen (Dateien)
Liste der relevanten ENT-Dateien, die dieses Modul/Design beeinflussen.

**Eintrag:**
- `[[ENT_...]]`: Einordnung in Architektur (genau 1 Satz)

**Regeln:**
- Der Satz beschreibt, *was* die Entscheidung architektonisch beeinflusst (nicht *warum* sie getroffen wurde)
- Keine Implementierungsdetails

---

### 4) Komponenten (Dateien)
Liste der Komponenten/Baugruppen, die das Modul direkt bilden.

**Eintrag:**
- `[[KMP_...]]`: Rolle im Modul (kurz, 1 Satz oder Bullet)

**Regeln:**
- Nur direkte Bestandteile des Moduls (keine “Umgebungskomponenten” aufblasen)

---

### 5) Schnittstellen
Die Schnittstellentabelle beschreibt, welche SSTs das Modul nach außen (oder zwischen Submodulen) nutzt und welche Endpunkte dadurch verbunden sind.

**Tabellenformat:**

| Interface (SST) | Endpunkt A | Endpunkt B | Kontext |
| --- | --- | --- | --- |

**Spaltenregeln:**
- **Interface (SST):** Link auf genau eine SST-Notiz.
- **Endpunkt A / Endpunkt B:** Links auf die beiden Endpunkte (typisch KMPs). ARC-Links als Endpunkt nur, wenn Endpunkte noch bewusst grob gehalten werden.
- **Kontext:** Zweck in wenigen Worten (max. 6–10 Wörter). Keine Parameter, kein Vertragstext.

**Regel:**
- Eine SST bildet keine Kette/Topologie ab. Die Tabelle listet Punkt-zu-Punkt-Verbindungen, die im Modulkontext relevant sind.

---
### 6) Implementierung (Dateien)
Liste der Implementierungsdateien, die die genannten Anforderungen, Entscheidungen, Komponenten und Schnittstellen konkret umsetzen.

**Eintrag:**
- `[[IMP_...]]`: Was konkret realisiert wird (kurz, 1 Satz oder Bullet).

**Regeln:**
- Nur IMP-Dateien, die direkt zu dem Modul gehören.

### 7) Zuordnung und Verifikation
Diese Tabelle ordnet Anforderungen (ANF-IDs, Erklärung siehe [[00_ANF_README]]) einem Submodul oder einer Schnittstelle zu und verlinkt auf die Verifikation.

**Tabellenformat:**

| Submodul (ARC/KMP/SST) | Zugeordnete Anforderungen (ANF-IDs) | Verifikation (TST) | Status |
| ---------------------- | ----------------------------------- | ------------------ | ------ |

---
#### Spalte 1 — Submodul (ARC/KMP/SST)
Objekt, das die Anforderungen “besitzt”.

**Eintrag:**
- Link auf `[[KMP_...]]` (Komponente/Baugruppe) oder `[[SST_...]]` (Schnittstelle)

**Regel (Lesbarkeit):**
- ARC-Zeilen: Anforderung an komplettes Modul, wenn feinere Unterteilung zu komplex wäre
- KMP-Zeilen: Anforderungen an Bauteil/Subsystem
- SST-Zeilen: Anforderungen an die Verbindung/Signalführung

---
#### Spalte 2 — Zugeordnete Anforderungen (ANF-IDs)
Die betroffenen Anforderungen als IDs, nicht als Volltext.

**Eintrag:**
- Kommagetrennte Liste von ANF-IDs, z.B. `ANF-SAE-001, ANF-MEG-004`

**Regeln:**
- Exakte Schreibweise der IDs 
- Keine Inhaltsduplikation

---
#### Spalte 3 — Verifikation (TST)
Links auf Test-/Inspektions-/Analyse-Notizen, die die Erfüllung der zugeordneten Anforderungen für dieses Submodul belegen.

**Eintrag:**
- ein oder mehrere Links, z.B. `[[TST_...]]`
- bei mehreren Nachweisen: mehrere Links sind erlaubt

**Regel:**
- Wenn der Status später **Verified** werden soll, muss hier mindestens ein Link existieren.
- Verifikation ist pro Submodul/Interface geführt (nicht “ein Test für alles”).

---
#### Spalte 4 — Status
Status der **Allokation** (nicht der ANF-Datei insgesamt).

**Eintrag (empfohlen):**
- **Draft**: Zuordnung/Verifikation in Arbeit (TST kann fehlen oder TBD sein)
- **Approved**: Zuordnung steht, Verifikationsplan existiert (TST-Link oder TBD)
- **Verified**: verifiziert (TST/INS/ANA durchgeführt + Ergebnis/Evidenz vorhanden)
- **Deprecated**: Allokation nicht mehr gültig (z.B. Architektur geändert), bleibt historisch erhalten
- **Blocked**: aktuell nicht verifizierbar/umsetzbar (Abhängigkeit fehlt)

**Regel:**
- **Verified** nur setzen, wenn ein TST/INS/ANA-Link existiert und die dazugehörige Evidenz dokumentiert ist.
