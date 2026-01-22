## Kontext
_Was umfasst das Modul, UND was nicht. Verlinkung auf relevante Submodule. Max. 5-7 Sätze. Keine Implementierungsdetails._

## Anforderungen (Dateien)
- \[\[ANF_X]]: Warum relevant für dieses Modul (1 Satz).
- \[\[ANF_Y]]: Warum relevant für dieses Modul (1 Satz).
- etc.
## Entscheidungen (Dateien)
- \[\[ENT_X]]: Einordnung in Architektur (1 Satz).
- \[\[ENT_Y]]: Einordnung in Architektur (1 Satz).
- etc.
## Komponenten (Dateien)
- \[\[KMP_X]]: Rolle im Modul.
- \[\[KMP_Y]]: Rolle im Modul.
- etc.
## Schnittstellen
| Interface (SST)   | Endpunkt A          | Endpunkt B       | Kontext          |
| ----------------- | ------------------- | ---------------- | ---------------- |
| \[\[SST_SPI_ADC]] | \[\[KMP_ADC_Board]] | \[\[KMP_MCU_XY]] | ADC Daten an MCU |

## Implementierung (Dateien)
- \[\[IMP_X]]: Was wird hier realisiert.
- \[\[IMP_Y]]: Was wird hier realisiert.

## Zuordnung und Verifikation
| Submodul (ARC/KMP/SST)     | Zugeordnete Anforderungen (ANF-IDs) | Verifikation (TST)                                       | Status |
| -------------------------- | ----------------------------------- | -------------------------------------------------------- | ------ |
| \[\[KMP_VoltageDivider]]   | ANF-MEG-001, ANF-SAE-001            | \[\[TST_Messplatine_U_Messung]], \[\[TST_Beruehrschutz]] | Draft  |
| \[\[KMP_CurrentSense]]     | ANF-MEG-002, ANF-EMV-003            | \[\[TST_Messplatine_I_Messung]]                          | Draft  |
| \[\[SST_SPI_ADC]]          | ANF-MEG-004, ANF-EMV-002            | \[\[TST_SPI_Integritaet]]                                | Draft  |
| \[\[SST_Safety_Interlock]] | ANF-SAE-005                         | \[\[TST_Interlock_FaultInjection]]                       | Draft  |


