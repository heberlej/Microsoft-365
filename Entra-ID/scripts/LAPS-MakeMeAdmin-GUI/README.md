# LAPS-MakeMeAdmin-GUI

Liest das **Windows-LAPS-Kennwort** eines Entra-ID-Geräts über Microsoft Graph (`deviceLocalCredentials`) aus – als GUI („Make Me Admin Azure“) oder als einfaches Skript.

## Dateien

| Datei | Beschreibung |
|---|---|
| `LAPS-GUI.ps1` / `LAPS-GUI2.ps1` | WinForms-GUI: Gerät auswählen, Kennwort abrufen und anzeigen |
| `Get-LapsPassword.ps1` | Ohne Hauptfenster: Kennwort für den eigenen Rechner (`hostname`) abrufen |
| `Get-LapsPassword-SecureString.ps1` | Variante mit Button und festem Gerätenamen |
| `BIN/Image/` | Bilder für die GUI |

## Voraussetzungen

- Windows LAPS mit Sicherung in Entra ID
- App-Registrierung in Entra ID mit den **Anwendungs**-Berechtigungen (Admin-Zustimmung):
  - `DeviceLocalCredential.Read.All`
  - `Device.Read.All`
- Modul `Microsoft.Graph`

## Konfiguration

In jedem Skript die Platzhalter ersetzen:

```powershell
$ClientId     = "<CLIENT-ID>"
$ClientSecret = "<CLIENT-SECRET>"
$tenantid     = "<TENANT-ID>"
```

In `Get-LapsPassword-SecureString.ps1` zusätzlich `<GERAETENAME>`.

## ⚠️ Sicherheit

- Wer das Skript mit Client Secret hat, kann **die LAPS-Kennwörter aller Geräte** lesen. Das Secret nie ins Repository einchecken und das Skript nicht an Endbenutzer verteilen.
- Besser: Zertifikat statt Secret oder interaktive Anmeldung (`Connect-MgGraph -Scopes DeviceLocalCredential.Read.All`) verwenden.
