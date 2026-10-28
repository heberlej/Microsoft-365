# Exchange Hybrid Migration GUI

PowerShell-GUI zur Steuerung von Exchange-Hybrid-Migrationsbenutzern: Übersicht, sofortiges Umstellen, Terminieren und Live-Statusverfolgung.

## Voraussetzungen

- Windows PowerShell mit Ausführungsrechten für Skripte (die GUI basiert auf WPF, läuft also nur unter Windows)
- Exchange-Online-Berechtigung (Rolle mit Zugriff auf Migrations-/Move-Request-Cmdlets, z. B. „Recipient Management“)
- Optional: Microsoft-Graph-Zugriff (`User.Read.All`) für den Lizenzstatus
- Module `ExchangeOnlineManagement` und `Microsoft.Graph.Users` – werden bei Bedarf automatisch im Benutzerkontext installiert (`-Scope CurrentUser`), keine Admin-Rechte nötig

## Funktionen

### Automatischer Logout beim Start

Bevor irgendetwas anderes passiert, meldet sich das Skript von einer eventuell zwischengespeicherten Exchange-Online-/Microsoft-Graph-Sitzung ab (`Disconnect-ExchangeOnline`, `Disconnect-MgGraph`). So wird verhindert, dass beim Verbinden versehentlich ein falscher Tenant/Account aus einem alten Login wiederverwendet wird. Mit `-SkipAutoLogout` lässt sich das überspringen:

```powershell
.\Exchange-HybridMigration-GUI.ps1 -SkipAutoLogout
```

### Verbinden

Zwei getrennte Logins: „Mit Exchange Online verbinden“ (für Migrationsdaten) und „Mit Microsoft Graph verbinden“ (für Lizenzstatus).

### Migrationsbenutzer-Übersicht

Zeigt alle Migrationsbenutzer mit Identity, Batch, Status, Lizenz-/Exchange-Online-Status, geplantem Termin und letzter Fehlermeldung.

### Suche

Filtert live über Identity, Batch, Status, Lizenz und Fehlermeldung.

### Jetzt umstellen

Wählt automatisch die passende Aktion je nach Status:

- Noch nicht synchronisiert/fehlgeschlagen → Migration wird gestartet
- Bereits synchronisiert/wartend → sofortiger Cutover (Postfach wird final auf Exchange Online umgestellt)

### Terminieren

Setzt für ausgewählte Benutzer direkt in Exchange Online `Set-MoveRequest -CompleteAfter <Zeitpunkt>`. Exchange selbst führt die Fertigstellung zum gewählten Datum/Uhrzeit serverseitig aus – unabhängig davon, ob dieser Rechner zu dem Zeitpunkt noch läuft. Funktioniert nur für Postfächer, deren Erstsynchronisierung bereits abgeschlossen ist (Status `Synced`/`Waiting`).

### Auto-Aktualisierung

Lädt alle 10 Sekunden automatisch neu, um den Fortschritt (z. B. `Synced` → `InProgress` → `Completed`) live zu beobachten. Die Auswahl bleibt dabei erhalten.

## Nutzung

```powershell
.\Exchange-HybridMigration-GUI.ps1
```

1. Mit Exchange Online verbinden
2. Optional: Mit Microsoft Graph verbinden (für Lizenzstatus)
3. Benutzer suchen/auswählen
4. „Jetzt umstellen“ oder Datum/Uhrzeit setzen und „Terminieren“

## Hinweise

- Termine werden nativ in Exchange Online gespeichert (`CompleteAfter`-Property des MoveRequests) – keine lokale Ablage, kein Windows-Task nötig. Die Spalte „Terminiert am“ liest diesen Wert direkt aus Exchange.
- Beim Start wird automatisch von Exchange Online/Microsoft Graph abgemeldet (siehe oben), damit jede Verbindung mit einer sauberen Kontoauswahl beginnt.
- Alle Aktionen werden in `ExchangeHybridMigration.log` (im Skriptordner) protokolliert. Die Logdatei ist per `.gitignore` vom Repository ausgeschlossen.
