# SharePoint-OneDrive-Sync-GPO

Erzeugt für **alle SharePoint-Seiten** des Tenants den Bibliotheks-String, den man in die GPO bzw. Intune-Einstellung **„Bibliotheken automatisch synchronisieren“** (OneDrive *TenantAutoMount*) einträgt.

Format:

```
tenantId=...&siteId={...}&webId={...}&listId=...&webUrl=...&version=1
```

## Voraussetzungen

- Module `Microsoft.Online.SharePoint.PowerShell` und `PnP.PowerShell`
- SharePoint-CSOM-Assemblies (`Microsoft.SharePoint.Client`)
- SharePoint-Admin-Rechte

## Verwendung

1. `$AdminUrl` anpassen: `https://<tenant>-admin.sharepoint.com/`
2. Ggf. `$ListName` anpassen (Standard: `Dokumente`)
3. Ausführen und zweimal anmelden:
   ```powershell
   .\Get-SharePointSyncString.ps1
   ```

Ergebnis: `%USERPROFILE%\Desktop\OneDriveSync.csv` mit `Titel;String;URL` pro Seite.

## Hinweise

- `SharePointOnlineCredentials` funktioniert nicht mit MFA. Mit MFA die IDs besser per PnP abfragen (`Connect-PnPOnline -Interactive`).
- Die CSV wird angehängt (`-Append`) – vor einem neuen Lauf löschen.
