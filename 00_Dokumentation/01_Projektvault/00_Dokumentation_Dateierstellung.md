Die folgenden Fragen sollten sich vor jedem Erstellen einer Datei gestellt werden, um eine konsistente Dokumentation zu gewährleisten. Wenn eine dieser Fragen nicht klar beantwortet werden kann, dann sollte keine Datei erstellt werden. 

## 1) Existenzrecht

**Frage 1:** Hat diese Information eine Existenzberechtigung?
	- Nein: Information sollte nicht dokumentiert werden
	- Ja: Weiter mit Frage 2.

**Frage 2:** Welche EINZIGE Hauptfrage beantwortet diese Datei die nicht bereits durch eine andere Datei beantwortet wird (Single Source of Truth)?
	- lässt sich nicht klar sagen: Unterteilen der Datei in weitere Dateien bis sich **eine** klare Hauptfrage pro Datei beantworten lässt
	- klare Antwort: weiter mit Frage 3.

---
## 2) Rollenbestimmung

**Frage 3:** Zu welcher Rolle gehört diese Information?
	- kann nicht klar eingeordnet werden: Datei muss weiter unterteilt werden, bis die Datei nur **eine** Rolle erfüllt
	- eine klare Rolle: Einordnung, weiter mit Frage 4.

Pro Datei muss genau eine Rolle gewählt werden:

| Ordner                         | Zweck                               | Zeitachse | Frage                                          |
| ------------------------------ | ----------------------------------- | --------- | ---------------------------------------------- |
| `01_Anforderungen (ANF)`       | Zieldefinition, Rahmen, Constraints | Stabil    | Was soll erreicht werden?                      |
| `02_Entscheidungen (ENT)`      | Warum etwas so ist                  | Langsam   | Warum wurde etwas gewählt?                     |
| `03_Architektur (ARC)`         | Systemzusammenhang                  | Mittel    | Wie hängt alles zusammen?                      |
| `04_Komponenten (KMP)`         | Physische / logische Bausteine      | Stabil    | Was sagen Referenzen über eine Komponente aus? |
| `05_Schnittstellen (SST)`      | Verträge zwischen Teilen            | Langsam   | Wie kommunizieren zwei Systemmodule.           |
| `06_Implementierung (IMP)`     | Flüchtige Umsetzung                 | Schnell   | Wie ist es umgesetzt?                          |
| `07_Test_und_Evidenz (TUE)`    | Beweise, Messungen                  | Langsam   | Hat es funktioniert?                           |
| `08_Betrieb_und_Nutzung (BUN)` | Praxis, Wartung                     | Mittel    | Wie sehen der Betrieb und die Nutzung aus?     |
| `09_Referenzen (REF)`          | Externe Wahrheit, zusammengefasst   | Stabil    | Was sagt die externe Referenz aus?             |
| `98_Administration (ADM)`      | Projektlogistik                     | Mittel    | Was benötige ich zur Projektsteuerung          |
| `99_Inbox (INB)`               | Unklassifiziertes Rohmaterial       |           |                                                |


**Frage 4:** In welcher Zeitachse lebt diese Information?
	 - in mehreren: Datei so lange unterteilen, bis alle Informationen in einer Zeitachse leben
	 - in genau einer: Datei darf erstellt werden. Die Antwort auf die Hauptfrage sollte als Überschrift gewählt werden.

mögliche Zeitachsen: 
- Stabil (ändert sich praktisch nie)
- Langsam
- Mittel
- Schnell

