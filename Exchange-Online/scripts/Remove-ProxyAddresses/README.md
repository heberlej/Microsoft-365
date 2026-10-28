# Remove-ProxyAddresses

Entfernt im lokalen Active Directory alle **Proxy-Adressen einer bestimmten Domain** (z. B. nach Umbenennung oder vor Entfernen einer Domain aus dem Tenant).

Systempostfächer (`Health`, `SystemMailbox`, `Migration`, `FederatedEmail`, `MsExchDiscovery`) werden ausgenommen.

## Voraussetzungen

- Modul `ActiveDirectory` (RSAT), Schreibrechte auf die Benutzer
- Ordner `C:\temp`

## Verwendung

1. `contoso.com` im Skript (2 Stellen) durch die zu entfernende Domain ersetzen
2. Ausführen:
   ```powershell
   .\Remove-ProxyAddresses.ps1
   ```

## Sicherung

Das Skript schreibt vorher und nachher alle Benutzerattribute nach:

- `C:\temp\backup-ad.txt`
- `C:\temp\backup-ad-danach.txt`

## Hinweise

- Ist eine Adresse der Domain die **primäre** (`SMTP:`), wird auch sie entfernt – vorher eine neue primäre Adresse setzen.
- Danach Entra-Connect-Synchronisation abwarten oder anstoßen: `Start-ADSyncSyncCycle -PolicyType Delta`
