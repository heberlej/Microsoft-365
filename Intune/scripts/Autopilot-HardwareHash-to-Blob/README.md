# Autopilot-HardwareHash-to-Blob

Liest den **Autopilot-Hardware-Hash** eines Geräts aus und lädt die CSV direkt in einen **Azure Blob Storage**. Praktisch, um Hashes vieler Geräte einzusammeln, ohne USB-Stick.

## Ablauf

1. Ordner `C:\hhash` anlegen
2. `Get-WindowsAutoPilotInfo` installieren und `<Hostname>-Hash.csv` erzeugen
3. AzCopy herunterladen und entpacken
4. CSV per AzCopy in den Blob-Container hochladen
5. `C:\hhash` wieder löschen

## Vorbereitung

1. Storage Account + Container anlegen (z. B. `hash`)
2. **SAS-Token** für den Container erzeugen: nur Berechtigung **Schreiben**, kurze Gültigkeit
3. Im Skript ersetzen:
   ```powershell
   $sasurl = "https://<STORAGEACCOUNT>.blob.core.windows.net/<CONTAINER>?<SAS-TOKEN>"
   ```

## Verwendung

Als Administrator auf dem Gerät ausführen (z. B. in der OOBE mit `Shift+F10`):

```powershell
.\HardwareHashToBlob.ps1
```

Danach die CSVs aus dem Container in Intune importieren: *Geräte → Windows → Registrierung → Geräte → Importieren*.

## Hinweise

- Das Skript setzt die Ausführungsrichtlinie auf `Unrestricted`.
- SAS-URL nie mit Leseberechtigung oder langer Laufzeit verteilen.
