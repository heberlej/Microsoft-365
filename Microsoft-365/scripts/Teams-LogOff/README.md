# Teams-LogOff

Meldet den Benutzer vollständig aus **Teams (klassisch)** ab und setzt den Client zurück, z. B. bei Anmeldeproblemen oder Kontowechsel.

## Was das Skript macht

1. Beendet alle `Teams`-Prozesse
2. Leert den Teams-Cache (`blob_storage`, `cache`, `databases`, `gpucache`, `IndexedDB`, `Local Storage`, `tmp`)
3. Entfernt gespeicherte `msteams`-Anmeldeinformationen aus der Windows-Anmeldeinformationsverwaltung
4. Löscht den Registry-Wert `HKCU:\Software\Microsoft\Office\Teams\HomeUserUpn`
5. Setzt in `desktop-config.json` den Abmeldestatus und leert UPN-/Tenant-Felder
6. Löscht `Cookies` und `storage.json`
7. Entfernt verknüpfte Geschäfts-/Schulkonten aus dem `AAD.BrokerPlugin`
8. Startet Teams neu

## Verwendung

Im Kontext des **angemeldeten Benutzers** ausführen (keine Admin-Rechte nötig):

```powershell
.\TeamsLogOff.ps1
```

## Hinweise

- Gilt für **Teams classic** (`%APPDATA%\Microsoft\Teams`). Das neue Teams speichert seine Daten an anderer Stelle.
- Schritt 7 entfernt **alle** verknüpften Arbeitskonten des Benutzers – danach ist für Outlook/OneDrive ggf. eine erneute Anmeldung nötig.
