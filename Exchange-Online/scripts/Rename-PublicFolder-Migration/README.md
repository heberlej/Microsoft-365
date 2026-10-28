# Rename-PublicFolder-Migration

Bereitet öffentliche Ordner für die Migration nach Exchange Online vor: Ordnernamen mit `\` oder `/` werden von der Migration nicht unterstützt und hier durch `|` ersetzt.

## Voraussetzungen

- Lokaler Exchange-Server (2013/2016/2019), Modul `ActiveDirectory`
- Exchange-Admin-Berechtigung

## Verwendung

```powershell
.\Rename-PublicFolderForMigration.ps1
```

1. Verbindet sich (wie [Connect-ExchangeOnPrem](../Connect-ExchangeOnPrem/)) mit dem Exchange-Server
2. Sucht alle öffentlichen Ordner mit `\` oder `/` im Namen
3. Benennt sie um, z. B. `Einkauf/Verkauf` → `Einkauf|Verkauf`

## Hinweise

- Vorher die betroffenen Ordner prüfen:
  ```powershell
  Get-PublicFolderStatistics -ResultSize Unlimited | Where-Object { $_.Name -like "*\*" -or $_.Name -like "*/*" }
  ```
- Die Umbenennung ist für Benutzer sichtbar.
