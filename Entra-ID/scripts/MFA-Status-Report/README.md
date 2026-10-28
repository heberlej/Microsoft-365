# MFA-Status-Report

Erstellt einen Bericht, welche lizenzierten Benutzer **MFA pro Benutzer** (aktiviert/erzwungen) nutzen und welche Standardmethode eingestellt ist.

## Varianten im Skript

1. **Alle** lizenzierten Benutzer
2. Nur lizenzierte Mitglieder einer Gruppe (`<MFA-GRUPPE>` ersetzen)

## Voraussetzungen

- Modul `MSOnline`, Verbindung mit `Connect-MsolService`
- Ordner `C:\temp`

## Verwendung

```powershell
Connect-MsolService
.\Get-MFAStatus.ps1
```

Ausgabe in `Out-GridView` und als `C:\temp\MFAUsers.CSV`.

## Hinweise

- Das Skript enthält beide Varianten nacheinander – nur den benötigten Teil ausführen.
- Erfasst nur das alte **MFA pro Benutzer**. MFA über Conditional Access oder Security Defaults erscheint hier als „Not Enabled“.
- `MSOnline` ist abgekündigt. Moderner Ersatz: `Get-MgReportAuthenticationMethodUserRegistrationDetail` (Microsoft Graph).
