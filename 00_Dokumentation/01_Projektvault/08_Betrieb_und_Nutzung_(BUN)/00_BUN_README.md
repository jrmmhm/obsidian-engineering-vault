BUN-Notizen beschreiben den Ablauf für Betrieb und Nutzung als reproduzierbares Runbook/Tutorial.  
BUN ist für Menschen geschrieben: klare Schritte, klare Checks, klare Abbruchregeln.

BUN beschreibt, wie das System bedient wird — nicht wie es aufgebaut ist (ARC), nicht warum Entscheidungen getroffen wurden (ENT) und nicht wie etwas implementiert ist (IMP).

## Ziel
- Bedienabläufe reproduzierbar dokumentieren (auch nach Monaten/Jahren)
- Bedienfehler vermeiden durch Checkpoints und klare Reaktionen
- Betrieb überwachen (nur das, was nicht automatisch überwacht/erzwungen wird)
- Häufige Fehlerbilder schnell beheben

---

## Aufbau

### 1) Kontext
Kurzbeschreibung des Ablaufs.
- Wofür ist dieser Ablauf gedacht? (1–3 Sätze)
- Zielzustand nach erfolgreichem Ablauf (1 Satz)

Regeln:
- Keine Architektur-Erklärungen
- Keine Begründungen/Entscheidungsrationalen

### 2) Voraussetzungen
Nur Voraussetzungen, die nicht durch das System (Hardware/Firmware) zuverlässig erzwungen oder detektiert werden können.

Erlaubte Inhalte:
- Hardware/Setup vorhanden (kurz)
- Sicherheitsvoraussetzungen, die nicht durch Projektmodule erzwungen werden können
- benötigte Software/Tools (wenn relevant)
- benötigte Dateien/Configs (Pfad relativ zum Projekt, wenn relevant)

Nicht erlaubt:
- Voraussetzungen, die ohnehin systemseitig geprüft/erzwungen werden (Interlock/Not-Aus etc.).  
  Diese gehören als Check in den Ablauf, nicht als Voraussetzung.

### 3) Ablauf
Schritt-für-Schritt-Anleitung für den Normalbetrieb als Tabelle.

Tabellenformat:

| Schritt | Aktion | Erwartung / Check | Wenn nicht erfüllt |
| ---: | --- | --- | --- |

Regeln:
- Pro Schritt genau eine Aktion
- Jede Aktion hat einen objektiven Check (“woran sehe ich, dass es klappt?”)
- “Wenn nicht erfüllt” enthält immer eine klare Reaktion:
  - Abbruch, oder
  - definierte Fehlerbehebung, oder
  - Verweis auf Troubleshooting

Formulierungsregeln:
- Keine schwammigen Aussagen (“sollte”, “normalerweise”)
- Stattdessen: messbar, sichtbar, eindeutig

### 4) Betriebsüberwachung
Beschreibt, was während des Betriebs beobachtet werden muss, sofern es nicht automatisch überwacht wird.

Erlaubte Inhalte:
- Anzeigen/Messwerte, die der Bediener prüfen muss
- manuelle Grenzwertbeobachtung, falls nicht automatisch vorhanden
- Logging/Dateien, falls der Bediener aktiv prüfen muss

Nicht erlaubt:
- Anforderungen neu definieren (ANF)
- technische Details aus IMP kopieren

### 5) Troubleshooting
Kurze Tabelle für die häufigsten Fehlerbilder.

Tabellenformat:

| Symptom | mögliche Ursache | Aktion/Verweis |
| --- | --- | --- |

Regeln:
- Nur häufige, reale Fälle (keine theoretischen Romane)
- Aktionen sind konkret oder verweisen auf eine passende BUN-/IMP-/TUE-Notiz
- Keine tiefen Ursachenanalysen (das ist Debug-/Analysearbeit, nicht BUN)


## Shutdown / Notfall
Shutdown-Prozeduren werden als eigene BUN-Dateien geführt (Single Source of Truth), z.B.:
- [[BUN_Shutdown_Normal]]
- [[BUN_Shutdown_Notfall]]

BUN-Abläufe verweisen darauf, statt Shutdown-Schritte zu duplizieren.
Abweichungen sind nur dann zulässig, wenn sie ablaufabhängig sind und explizit genannt werden.

