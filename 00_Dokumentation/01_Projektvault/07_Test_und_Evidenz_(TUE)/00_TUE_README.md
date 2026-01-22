TUE-Notizen dokumentieren Tests, Untersuchungen und Evidenzen inklusive Testbedingungen, Einschränkungen und nachvollziehbarer Schlussfolgerung. 

## Ziel
- Nachvollziehbar festhalten, was getestet wurde und unter welchen Bedingungen
- Evidenz (Messwerte/Beobachtungen) strukturiert dokumentieren
- Einschränkungen transparent machen
- Eine klare Folgerung aus der Evidenz ableiten

## Aufbau einer TUE-Datei

### 1) Kontext
Beschreibt kurz, was getestet/untersucht wurde.

Regeln:
- 1–3 Sätze
- Kein Hintergrundroman

---

### 2) Testbedingungen
Hier stehen alle Bedingungen/Voraussetzungen, die notwendig sind, um den Test zu reproduzieren oder korrekt zu interpretieren.

Typische Inhalte:
- Testobjekt (empfohlen): Link auf [[KMP_...]] oder [[SST_...]] oder [[ARC_...]]
- Testaufbau / verwendete Geräte (nur soweit relevant)
- Umgebungsbedingungen (Temperatur/Feuchte/EMV), wenn relevant
- Voraussetzungen (z.B. Kalibrierung, Aufwärmzeit, Konfiguration)

Regel:
- Nur das dokumentieren, was die Aussagekraft beeinflusst.

---

### 3) Verweise
Liste externer Artefakte, die den Test belegen oder ergänzen.  
Es werden nur Dateipfade relativ zum Projekt-Root verwendet.

Beispiele:
- Kalibrierschein: Projektname/00_Dokumentation/02_Dokumente/07_Test_und_Evidenz/Oszilloskop_Kalibrierschein.pdf
- Fotos: Projektname/00_Dokumentation/02_Dokumente/07_Test_und_Evidenz/Testaufbau_Foto_01.jpg
- Rohdaten: Projektname/07_Test_und_Validierung/Messdaten/run_2026-01-20.csv

Regeln:
- Keine Inhalte in die TUE kopieren
- Pfade müssen stabil und eindeutig sein

---

### 4) Einschränkungen
Alle Einschränkungen, die die Zuverlässigkeit, Genauigkeit oder Übertragbarkeit beeinflussen.

Beispiele:
- Messbereichsgrenze erreicht (Sättigung)
- Unklare Randbedingungen (z.B. Temperatur nicht kontrolliert)
- Stichprobe zu klein
- Aufbau nicht vollständig repräsentativ

Regel:
- Lieber Einschränkungen zu viel als zu wenig, wenn sie die Interpretation beeinflusst.

---

### 5) Evidenz
Konkrete Ergebnisse/Beobachtungen, bevorzugt in Tabellenform.

Regeln:
- Messwerte/Beobachtungen klar strukturiert
- Einheiten konsistent im Tabellenkopf angeben
- Rohdaten nicht duplizieren: wenn es viele Daten sind, als Datei verweisen und hier nur Zusammenfassung/Extrakt dokumentieren

---

### 6) Folgerung
Ableitung aus der Evidenz: Was ist das Ergebnis?

Regel:
- Keine neuen Messwerte oder Vermutungen in die Folgerung einführen.

