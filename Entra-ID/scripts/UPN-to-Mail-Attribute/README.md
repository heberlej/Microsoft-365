# UPN-to-Mail-Attribute

Setzt im lokalen Active Directory das Attribut `mail` auf den `userPrincipalName` – typische Vorbereitung für Entra Connect / Cloud Sync, damit UPN und Mailadresse übereinstimmen.

## Voraussetzungen

- Modul `ActiveDirectory` (RSAT), Schreibrechte auf die Benutzerobjekte

## Verwendung

1. `$SearchBase` im Skript auf die gewünschte OU setzen
2. Ausführen:
   ```powershell
   .\Set-MailFromUPN.ps1
   ```

Für die umgekehrte Richtung (`mail` → `userPrincipalName`) den auskommentierten Block verwenden.

## Hinweise

- Vorher sichern:
  ```powershell
  Get-ADUser -SearchBase $SearchBase -Filter * -Properties mail, userPrincipalName |
      Select-Object SamAccountName, userPrincipalName, mail | Export-Csv backup.csv -NoTypeInformation
  ```
- Zuerst an einer Test-OU ausprobieren.
