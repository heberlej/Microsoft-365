# Exchange Online

Postfächer, Verteiler, Transportregeln, Mail-Flow, Anti-Spam/Defender-Richtlinien.

## Inhalt

- `scripts/` – PowerShell-/Automatisierungsskripte

## Skripte

| Skript | Zweck |
|---|---|
| [Exchange-Online-Migration](scripts/Exchange-Online-Migration/) | Anleitung + Skript: Benutzer einzeln aus Migrationsbatches per `Set-MoveRequest -CompleteAfter` terminieren |
| [Exchange-Hybrid-Migration-Tool](scripts/Exchange-Hybrid-Migration-Tool/) | GUI für Hybrid-Migrationen: Übersicht, sofortiger Cutover, Terminierung per `CompleteAfter`, Live-Status |
| [Connect-ExchangeOnPrem](scripts/Connect-ExchangeOnPrem/) | Remote-PowerShell zum lokalen Exchange-Server, Server automatisch aus AD ermittelt |
| [Rename-PublicFolder-Migration](scripts/Rename-PublicFolder-Migration/) | Öffentliche Ordner mit `\` oder `/` im Namen vor der Migration umbenennen |
| [Restore-DeletedMailbox-to-Shared](scripts/Restore-DeletedMailbox-to-Shared/) | Gelöschte Postfächer als freigegebene Postfächer wiederherstellen |
| [Remove-ProxyAddresses](scripts/Remove-ProxyAddresses/) | Alle Proxy-Adressen einer Domain aus dem lokalen AD entfernen |
| [LastLogon-Report](scripts/LastLogon-Report/) | Letzte Anmeldung und inaktive Tage aller Postfächer als CSV |
