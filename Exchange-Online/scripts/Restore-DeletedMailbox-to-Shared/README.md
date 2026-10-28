# Restore-DeletedMailbox-to-Shared

Stellt **vorläufig gelöschte** (soft-deleted) Postfächer in Exchange Online als **freigegebene Postfächer** wieder her – z. B. für ausgeschiedene Mitarbeiter, deren Daten ohne Lizenz erhalten bleiben sollen.

## Ablauf je Postfach

1. Freigegebenes Postfach mit gleichem Namen anlegen
2. `New-MailboxRestoreRequest` vom gelöschten in das freigegebene Postfach
3. Restore-Requests in `Out-GridView` anzeigen und Fortschritt ausgeben

## Voraussetzungen

- Modul `ExchangeOnlineManagement`, Rolle *Mailbox Import Export* bzw. *Organization Management*
- Gelöschte Postfächer innerhalb der 30-Tage-Aufbewahrung

## Verwendung

```powershell
Connect-ExchangeOnline
.\Restore-DeletedMailboxToShared.ps1
```

## Hinweise

- Das Skript verarbeitet **alle** soft-deleted Postfächer. Für einzelne Postfächer die Liste aus `Get-Mailbox -SoftDeletedMailbox` vorher filtern.
- Fortschritt prüfen:
  ```powershell
  Get-MailboxRestoreRequest | Get-MailboxRestoreRequestStatistics
  ```
