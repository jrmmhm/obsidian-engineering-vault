SST-Notizen definieren Schnittstellen als Vertragstypen.  
Eine SST beschreibt die Parameter einer Verbindung (elektrisch/logisch/mechanisch), ohne konkrete Endpunkte festzulegen.  
Die Zuordnung, welche Komponenten eine SST verwenden, erfolgt in ARC über die Schnittstellentabelle [[00_ARC_README]].

## Ziel
- Schnittstellen elektrisch/mechanisch eindeutig definieren, ohne Implementierung oder Komponenten 
- Austauschbarkeit und Nachweisbarkeit sicherstellen (gleicher Vertrag, andere Endpunkte)

## Aufbau
### 1) Kontext
Art der Schnittstelle (als Vertragstyp)

### 2) Spezifikationen
relevante elektrische/mechanische Parameter


## nicht enthalten
- keine Endpunkte (Komponenten/Module) und keine Topologie
- keine Implementierungsdetails (Pins, Stecker-Pinbelegung, MCU-Instanzen wie SPI1)
- keine Architektur- oder Sicherheitskettenbeschreibung

Diese Informationen liegen in ARC (Zuordnung/Topologie) bzw. IMP (konkrete Umsetzung).

## Namenskonvention (empfohlen)
SST-Namen müssen eindeutig beschreiben, welcher Vertrag gemeint ist.
Beispiele:
- SST_SPI_ADC
- SST_PWR_24VDC
- SST_HV_IN
- SST_RELAY_COIL_GND_SW
- SST_DOOR_INTERLOCK_24V

Vermeiden:
- SST_SPI (zu generisch)
- SST_SPI1 (Implementierungsinstanz, gehört in IMP)

---

## Spezifikationsregeln
- Nur Parameter aufnehmen, die für Funktion, Austauschbarkeit oder Sicherheit relevant sind.
- Werte ohne Quelle vermeiden (Quellen ggf. über KMP/REF referenzieren).
- Wenn Parameter noch unbekannt sind: TBD setzen und Status/Verifikation später nachziehen (über ARC/TST).
