Um eine konsistente hochqualitative Dokumentation zu gewährleisten wurden Regeln und Hinweise in eine Reihe von Dateien unterteilt, die dem Nutzer in Summe den Leitfaden vorgeben.

## Schnelle Orientierung

- Anforderungen → `01_Anforderungen (ANF)`
- Entscheidungen/Warum → `02_Entscheidungen (ENT)`
- Architektur/Zuordnung+Verifikation → `03_Architektur (ARC)`
- Umsetzung/Artefaktpfade → `06_Implementierung (IMP)`
- Nachweise/Messungen → `07_Test_und_Evidenz (TUE)`
- Betrieb/Runbooks → `08_Betrieb_und_Nutzung (BUN)`
- Quellenextrakte → `09_Referenzen (REF)`

**Wichtig:** Die Dateien unter 03_Architektur bilden die einzelnen Projektmodule ab, und fügen Dateien als Gesamtbild zusammen. Der zentrale Start in das Projekt und seine Architektur findet sich unter [[Systemuebersicht]].

## Verstehen
Ein tiefgehendes Verständnis der Dokumentationsweise wird durch das Lesen aller _00_Dateiname_ - Dateien erzielt.

Der Start erfolgt mit den Fragen, wann eine Datei überhaupt erstellt werden darf, und wie sie in die Ordnerstruktur einzusortieren ist. Diese Fragen werden unter [[00_Dokumentation_Dateierstellung]] aufgelistet und erklärt.

Nach dem erfolgreichen Beantworten jeder dieser Fragen, darf eine Datei erstellt werden mit dem Dateinamen:
_**Ordnerkürzel_AntwortAufDieHauptfrage**_

Die Erstellung von Unterordnern wird in [[00_Dokumentation_Unterordner]] erklärt.

Sobald verstanden ist, wann eine Datei erstellt werden darf, wie sie in die bereits bestehenden Ordner einzusortieren ist, und wann ein Unterordner erstellt werden sollte, empfiehlt es sich die README-Dateien und die Dateitemplates eines jeden Hauptordners anzuschauen. Die README-Datei erklärt, was explizit unter diesem Ordner einzusortieren ist, und was das Dateitemplate beschreibt. Das Dateitemplate gibt eine Dateivorlage, um Dateien konsistent aufzubauen und klar zu beantworten, was in eine Datei gehört. Für jede neue Datei in einem Hauptordner empfiehlt es sich das Dateitemplate zu duplizieren und die neue Datei nach dem duplizierten Template aufzubauen.

Diese Dateien finden sich in jedem Hauptordner unter:
`/XX_Ordnername (Ordnerkürzel)`
	- `/00_Ordnerkürzel_README`
	- `/00_Ordnerkürzel_Dateitemplate`


Zuletzt wird empfohlen die [[Systemuebersicht]] zu öffnen, da diese zentral die Hauptmodule in Form von ARC-Dateien beschreibt und erklärt. Die Systemübersicht dient somit als zentrale Anlaufstelle.

---

## Onboarding-Pfad (Empfohlene Lesereihenfolge)

Für neue Projektmitglieder wird folgender Lesepfad empfohlen:

| Schritt | Datei | Ziel |
| ------: | ----- | ---- |
| 1 | [[00_Dokumentation_Dateierstellung]] | SSOT-Prinzip und Rollenmatrix verstehen |
| 2 | [[00_Dokumentation_Unterordner]] | 3-Fragen-Regel für Unterordner |
| 3 | [[00_Glossar]] | Abkürzungen und Fachbegriffe nachschlagen |
| 4 | [[Systemuebersicht]] | Top-Level-Module kennenlernen |
| 5 | [[00_ARC_README]] | ARC-Struktur und Verifikationstabelle verstehen |
| 6 | [[00_ANF_README]] | Anforderungs-ID-Schema (ANF-DOM-NNN) |
| 7 | Beliebiges ARC-Modul nach Interesse | Vertiefung in spezifisches Modul |
