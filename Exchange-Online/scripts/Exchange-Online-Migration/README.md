# Exchange Online Migration – Benutzer einzeln umstellen

Anleitung und Skript, um Benutzer aus einem Exchange-Hybrid-Migrationsbatch **Stück für Stück** auf Exchange Online umzustellen (Cutover), statt den ganzen Batch auf einmal abzuschließen.

Grundlage ist das Cmdlet:

```powershell
Set-MoveRequest -Identity "<Benutzer>" -CompleteAfter <Datum>
```

Exchange Online speichert den Zeitpunkt am MoveRequest und führt die Umstellung dann selbst aus. Dein Rechner muss dafür nicht laufen.

## Voraussetzungen

- **PowerShell** 5.1 (Windows) oder PowerShell 7 (Windows/macOS/Linux)
- **Modul `ExchangeOnlineManagement`:**
  ```powershell
  Install-Module ExchangeOnlineManagement -Scope CurrentUser
  ```
- **Berechtigung** in Exchange Online, z. B. Rollengruppe *Recipient Management* oder *Organization Management* (Rolle *Move Mailboxes*)
- **Bestehender Migrationsbatch** (Remote Move / Hybrid), der **nicht automatisch abgeschlossen** wird:
  - im EAC: „Batch manuell abschließen“, oder
  - per PowerShell ohne `-AutoComplete` bzw. mit einem `-CompleteAfter` weit in der Zukunft
- Die Postfächer sind **bereits synchronisiert**, Status `Synced`

## Ablauf

### 1. Verbinden

```powershell
Connect-ExchangeOnline
```

### 2. Status der Benutzer prüfen

```powershell
Get-MigrationUser -BatchId "<Batchname>" | Select-Object Identity, Status, LastSuccessfulSyncTime
```

Nur Benutzer mit Status **`Synced`** sind bereit für den Cutover.

### 3. Skript anpassen

Oben in `Set-MigrationCompleteAfter.ps1`:

```powershell
$Users = @(
    'max.mustermann@contoso.com'
    'erika.musterfrau@contoso.com'
)

$CompleteAfter = '15.11.2026 20:00'   # lokale Zeit, TT.MM.JJJJ HH:mm
```

Das Skript rechnet die lokale Zeit automatisch nach **UTC** um. Exchange Online wertet `-CompleteAfter` ohne Zeitzone als UTC; ohne Umrechnung käme der Cutover in Deutschland 1–2 Stunden zu spät.

### 4. Probelauf

```powershell
.\Set-MigrationCompleteAfter.ps1 -WhatIf
```

### 5. Termin setzen

```powershell
.\Set-MigrationCompleteAfter.ps1
```

Am Ende zeigt eine Tabelle pro Benutzer den vorherigen Status, den gesetzten Termin und das Ergebnis. Bereits abgeschlossene Postfächer werden übersprungen.

### 6. Termin kontrollieren / Fortschritt verfolgen

```powershell
Get-MoveRequest -BatchName "*<Batchname>*" | Select-Object DisplayName, Status, CompleteAfter

Get-MoveRequestStatistics -Identity "max.mustermann@contoso.com" |
    Select-Object DisplayName, StatusDetail, PercentComplete
```

Der Status wechselt zum Termin von `Synced` über `CompletionInProgress` zu `Completed`.

## Manuell ohne Skript

Einzelnen Benutzer terminieren:

```powershell
Set-MoveRequest -Identity "max.mustermann@contoso.com" -CompleteAfter (Get-Date "15.11.2026 20:00").ToUniversalTime()
```

Sofort umstellen:

```powershell
Set-MoveRequest -Identity "max.mustermann@contoso.com" -CompleteAfter 1
```

`-CompleteAfter 1` steht für einen Zeitpunkt in der Vergangenheit, deshalb startet der Cutover sofort.

## Hinweise und Fallstricke

- **Nicht `Complete-MigrationBatch` verwenden**, wenn nur einzelne Benutzer umgestellt werden sollen. Das schließt den **gesamten** Batch ab.
- **Termin ändern:** Skript bzw. `Set-MoveRequest` einfach mit neuem Zeitpunkt erneut ausführen, solange der Cutover noch nicht begonnen hat.
- **Status `AutoSuspended`:** Wurde der Batch mit „nach Synchronisierung anhalten“ angelegt, muss der MoveRequest zusätzlich fortgesetzt werden:
  ```powershell
  Resume-MoveRequest -Identity "max.mustermann@contoso.com"
  ```
- **Lizenz** vor dem Cutover zuweisen. Nach der Umstellung hat der Benutzer sonst nur eine Kulanzfrist von 30 Tagen.
- **Outlook/Mobilgeräte:** Nach dem Cutover kann Outlook einen Neustart verlangen. Am besten zu einem Zeitpunkt außerhalb der Arbeitszeit umstellen.
- Die Benutzer im Skript sind **Beispiele** (`contoso.com`). Echte Benutzerlisten nicht ins öffentliche Repository einchecken.

## Verwandt

- [Exchange-Hybrid-Migration-Tool](../Exchange-Hybrid-Migration-Tool/): GUI für dieselbe Aufgabe mit Übersicht und Live-Status
