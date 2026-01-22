
ANF-Dateien dokumentieren, welche Anforderungen an das System gestellt werden. Das Dateitemplate findet sich unter [[00_ANF_Dateitemplate]]. Jede Anforderung existiert genau einmal und ist mit einer Anforderungs-ID verknüpft. Die Erklärung der Anforderungs-ID und der Tabellenspalten findet sich in dieser Datei.


## Anforderungs-ID

Die ID einer jeden Anforderungstabellenzeile ist einzigartig und erlaubt eine eindeutige Zuordnung von Anforderungen auf Projektmodule / Komponenten. Jede Anforderung hat eine **Full-ID** nach dem Schema:

**ANF-_DOM_-_NNN_**

- **ANF**: Prefix für „Anforderung“
- **DOM**: 3-Buchstaben Domain-Kürzel der Datei (steht hinter dem Dateinamen in Klammern, z.B. `KRA`)
- **NNN**: laufende Nummer innerhalb dieser Datei (001, 002, 003 …) – steht als ID in der Tabelle

**Wichtig:**
- In der Tabelle wird nur **NNN** eingetragen. Die Full-ID ergibt sich automatisch aus **DOM + NNN**.
- **DOM ist stabil**: Bedeutung von DOM wird nie geändert.
- **NNN wird nie wiederverwendet oder umnummeriert**. Lücken sind erlaubt.
- Wenn eine Anforderung entfällt: ID bleibt belegt.

**Beispiel:**
- Datei = `Kraftaktor (KRA)`
- Tabellenzeile NNN = `007`  
    → Full-ID = **ANF-KRA-007**

---
## Aufbau


### Kontext
Beschreibt, welches Thema an Anforderungen das Modul umfasst und was nicht, inklusive Verlinkung auf relevante Submodule.


### Tabelle
Die Anforderungen stehen als Zeilen in einer Tabelle mit festen Spalten. Jede Spalte hat genau eine Aufgabe.

| Class (M/S/O) | NNN | Inhalt | Akzeptanzkriterium | Quelle / Begründung (REF/ENT) |
| ------------- | --: | ------ | ------------------ | ----------------------------- |

### Spalte 1 — **Class (M/S/O)**

Verbindlichkeit / Priorität der Anforderung.
- **M** (Mandatory): Muss erfüllt sein. Ohne Erfüllung keine Freigabe / unsicher / Kernfunktion nicht gegeben.
- **S** (Should): Soll erfüllt sein. Abweichung ist möglich, aber muss begründet werden.
- **O** (Optional): Optional. Nice-to-have, keine Begründung nötig, wenn nicht umgesetzt.

**Eintrag:** genau ein Zeichen `M`, `S` oder `O`.

---
### Spalte 2 — **NNN**

Die laufende Nummer der Anforderung innerhalb der Datei.
**Eintrag:** `001`, `002`, `003` … (immer 3-stellig)

**Regeln:**
- nicht umsortieren durch Umnummerieren
- nicht wiederverwenden
- lückenlos ist _nicht_ nötig

---
### Spalte 3 — **Inhalt**

Die eigentliche Anforderung als **eindeutiges technisches Statement**.

**Gut:**
- „Türöffnung muss die HV-Freigabe innerhalb von ≤ 100 ms deaktivieren.“

**Schlecht:**
- „Tür muss sicher sein.“ (nicht testbar)

---
### Spalte 4 — **Akzeptanzkriterium**

Messbares oder eindeutig prüfbares Kriterium, anhand dessen entschieden wird: erfüllt / nicht erfüllt.
**Eintrag:** Grenzwerte, Bedingungen, Messsetup-Rahmen, klare Pass/Fail-Bedingung.

Beispiele:
- „Pass, wenn HV_Enable innerhalb ≤ 100 ms nach Türsignal = offen auf 0 geht.“
- „Pass, wenn PE-Durchgängigkeit < 0,1 Ω zwischen Klemmblock und Gehäuse.“

---

### Spalte 5 — **Quelle / Begründung (REF/ENT)**

Woher kommt die Anforderung oder warum existiert sie?

**Eintrag:**
- `[[REF_...]]` (Norm, Datenblatt, Paper)
- und/oder `[[ENT_...]]` (Entscheidung/ADR, die das begründet)
- optional freier Kurztext zusätzlich (z.B. „DIN EN 61010-1“), aber besser als Referenz-Notiz.


