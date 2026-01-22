## Kontext
Diese Datei gibt den Überblick über die großen Systemmodule und ist der Einstiegspunkt in die Architektur.
Für Details zu Anforderungen, Entscheidungen, Implementierung und Verifikation die jeweiligen ARC-Module öffnen. 
Empfohlener Einstieg: Lesepfad Tabellenzeile 1 -> Tabellenzeile 2 -> Tabellenzeile 3 -> etc.

## Systemmodule (ARC)

| Modul (ARC)                        | Kurzbeschreibung                                                                                                        |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| [[ARC_Gehaeuse_und_Zugangsschutz]] | Gehäuse, mechanische Integration, Zugangsschutz (Tür/Abdeckung/Signalisierung).                                         |
| [[ARC_Elektrik]]                   | Power- und Safety-Verdrahtung (Versorgung, Verteilung, Schutz, Sicherheit, PE/PA). Keine Elektronik/Signalverarbeitung. |
| [[ARC_MCU]]                        | Steuerungseinheit (Firmware-Logik, I/O-Anbindung, Systemzustände).                                                      |
| [[ARC_HV_Messplatine]]             | HV-Messung und galvanische Trennung zur sicheren Signalübertragung.                                                     |
| [[ARC_Kraftaktor]]                 | Kraftaktor, der für die Auslenkung und Krafteinwirkung auf den DE zuständig ist.                                        |
| [[ARC_Kraftsensor]]                | Kraftsensor der die von dem DE erzeugte Kraft / die vom Aktor aufgebrachte Kraft misst.                                 |
| [[ARC_Host]]                       | Host-System (Device-Daemon, Backend, Web-UI) zur Steuerung und Datenvisualisierung.                                     |

## Hinweise
- Diese Datei listet nur Top-Level-Module.
- Submodule, Schnittstellen, Allokation und Verifikation sind in den jeweiligen ARC-Dateien.
- DE = Dielektrisches Elastomer, siehe [[KMP_Dielektrischer_Elastomer_(DE)]].
