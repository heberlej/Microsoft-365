# LastLogon-Report

Exportiert für alle Postfächer in Exchange Online die **letzte Anmeldung**, das Erstellungsdatum und die Anzahl inaktiver Tage – z. B. um ungenutzte Konten und Lizenzen zu finden.

## Voraussetzungen

- Modul `ExchangeOnlineManagement`

## Verwendung

```powershell
Connect-ExchangeOnline
.\Get-LastLogonReport.ps1
```

Ergebnis: `LastLogonTimeReport_<Datum>.csv` im aktuellen Ordner mit

`UserPrincipalName, DisplayName, LastLogonTime, CreationTime, InactiveDays`

Postfächer ohne Anmeldung erscheinen mit `Garnicht`.

## Hinweise

- `LastLogonTime` aus `Get-MailboxStatistics` ist nur ein Näherungswert (auch Hintergrundzugriffe zählen).
- Bei vielen Postfächern dauert es lange; die Laufzeit wird am Ende ausgegeben (`Measure-Command`).
