# Connect-AnyService

Kleine WinForms-GUI, um sich per Häkchen mit einem oder mehreren Microsoft-365-Diensten zu verbinden.

## Unterstützte Dienste

- `Connect-ExchangeOnline`
- `Connect-MsolService`
- `Connect-AzureAD`
- `Connect-MgGraph` (öffnet ein zweites Fenster zur Auswahl der Graph-Scopes, z. B. `User.Read.All`, `Group.Read.All`, `Sites.Manage.All`)
- `Connect-PnPOnline`
- `Connect-MicrosoftTeams`

## Voraussetzungen

- Windows PowerShell 5.1 (WinForms)
- Die jeweiligen Module, z. B.:
  ```powershell
  Install-Module ExchangeOnlineManagement, Microsoft.Graph, MicrosoftTeams, PnP.PowerShell -Scope CurrentUser
  ```

## Verwendung

```powershell
.\Connect-AnyService.ps1
```

Dienst(e) anhaken → **Auswählen**. Die Anmeldung erfolgt interaktiv.

## Hinweise

- `MSOnline` und `AzureAD` sind von Microsoft abgekündigt. Für neue Aufgaben `Microsoft.Graph` verwenden.
