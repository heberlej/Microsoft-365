# Connect-ExchangeOnPrem

Verbindet sich per Remote-PowerShell mit einem **lokalen Exchange-Server**, ohne dass die Exchange-Verwaltungstools installiert sein müssen. Der Server wird automatisch aus der AD-Gruppe *Exchange Servers* ermittelt.

## Voraussetzungen

- Domänenmitgliedschaft, Modul `ActiveDirectory` (RSAT)
- Exchange-Admin-Berechtigung

## Verwendung

```powershell
.\Connect-ExchangeOnPrem.ps1
```

Anmeldedaten eingeben – danach stehen die Exchange-Cmdlets (`Get-Mailbox` usw.) in der Sitzung zur Verfügung.

## Hinweise

- Verwendet wird der **letzte** gefundene Server der Gruppe.
- Verbindung über `http://<Server>/PowerShell/` mit Kerberos.
- Sitzung beenden: `Get-PSSession | Remove-PSSession`
