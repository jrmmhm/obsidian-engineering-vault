
ENT-Dateien dokumentieren **Entscheidungen** (warum wir X statt Y tun), damit das System später nachvollziehbar bleibt, ohne dass Implementierungsdetails oder Anforderungen doppelt gepflegt werden. Das Dateitemplate findet sich unter: [[00_ENT_Dateitemplate]].

## Aufbau

Jede ENT-Datei nutzt das feste Schema:
1. Datum
2. Status
3. optional „Superseded by“-Link
4. Kontext
5. Optionen
6. Entscheidung
7. Begründung
8. Konsequenzen

## 2) Status 

- **Draft**: in Arbeit, noch nicht final
- **Accepted**: gilt aktuell und ist die aktive Entscheidung
- **Superseded**: wurde durch eine neuere Entscheidung ersetzt  
    **Regel:** muss einen Link `Superseded by: [[ENT_...]]` enthalten + Kurzgrund (1 Satz)
- **Deprecated**: nicht mehr relevant (z.B. verworfen, ohne direkten Nachfolger)

**Regel:** Entscheidungen werden nicht „still“ gelöscht, wenn sie jemals umgesetzt oder relevant diskutiert wurden. Stattdessen auf **Superseded** setzen. Nur triviale Fehlnotizen, die nie genutzt wurden, dürfen entfernt werden.
