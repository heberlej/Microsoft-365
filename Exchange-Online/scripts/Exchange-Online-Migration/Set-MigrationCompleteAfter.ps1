<#
.SYNOPSIS
    Stellt einzelne Benutzer aus einem Exchange-Online-Migrationsbatch zu einem festen Zeitpunkt um.

.DESCRIPTION
    Setzt fuer jeden Benutzer im Array $Users per
        Set-MoveRequest -Identity <Benutzer> -CompleteAfter <Zeitpunkt>
    den Fertigstellungszeitpunkt (Cutover). Exchange Online fuehrt die Umstellung zu diesem
    Zeitpunkt serverseitig aus - dieser Rechner muss dann nicht mehr laufen.

    So lassen sich Benutzer Stueck fuer Stueck umstellen, ohne den gesamten Batch mit
    Complete-MigrationBatch abzuschliessen.

    Voraussetzung: Die Postfaecher sind bereits synchronisiert (Status "Synced"). Siehe README.md.

.EXAMPLE
    .\Set-MigrationCompleteAfter.ps1 -WhatIf
    Zeigt nur an, was passieren wuerde.

.EXAMPLE
    .\Set-MigrationCompleteAfter.ps1
    Setzt den Termin fuer alle Benutzer im Array $Users.
#>

[CmdletBinding(SupportsShouldProcess)]
param()

# ============================================================================
# KONFIGURATION - hier anpassen
# ============================================================================

# Benutzer, die umgestellt werden sollen (UPN bzw. primaere SMTP-Adresse)
$Users = @(
    'max.mustermann@contoso.com'
    'erika.musterfrau@contoso.com'
    'john.doe@contoso.com'
)

# Zeitpunkt der Umstellung in LOKALER Zeit, Format: TT.MM.JJJJ HH:mm
# Wird automatisch nach UTC umgerechnet (Exchange Online erwartet UTC).
$CompleteAfter = '15.11.2026 20:00'

# ============================================================================
# AB HIER NICHTS MEHR AENDERN
# ============================================================================

$ErrorActionPreference = 'Stop'

# Zeitpunkt pruefen und nach UTC umrechnen
try {
    $completeAfterLocal = [datetime]::ParseExact($CompleteAfter, 'dd.MM.yyyy HH:mm', [Globalization.CultureInfo]::InvariantCulture)
} catch {
    throw "Ungueltiges Datum in `$CompleteAfter: '$CompleteAfter'. Erwartetes Format: TT.MM.JJJJ HH:mm"
}
if ($completeAfterLocal -le (Get-Date)) {
    Write-Warning "Der Zeitpunkt $CompleteAfter liegt in der Vergangenheit - die Umstellung startet sofort."
}
$completeAfterUtc = $completeAfterLocal.ToUniversalTime()

# Verbindung zu Exchange Online sicherstellen
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    throw "Modul 'ExchangeOnlineManagement' fehlt. Installieren mit: Install-Module ExchangeOnlineManagement -Scope CurrentUser"
}
$connected = Get-ConnectionInformation -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Connected' }
if (-not $connected) {
    Connect-ExchangeOnline -ShowBanner:$false
}

Write-Host "Umstellung geplant fuer: $($completeAfterLocal.ToString('dd.MM.yyyy HH:mm')) (lokal) / $($completeAfterUtc.ToString('dd.MM.yyyy HH:mm')) (UTC)" -ForegroundColor Cyan
Write-Host ""

$results = foreach ($user in $Users) {
    $result = [PSCustomObject]@{
        Benutzer      = $user
        StatusVorher  = $null
        CompleteAfter = $null
        Ergebnis      = $null
    }

    try {
        $mr = Get-MoveRequest -Identity $user
        $result.StatusVorher = $mr.Status

        if ($mr.Status -eq 'Completed') {
            $result.Ergebnis = 'Uebersprungen - bereits abgeschlossen'
        } elseif ($PSCmdlet.ShouldProcess($user, "Set-MoveRequest -CompleteAfter $completeAfterUtc (UTC)")) {
            Set-MoveRequest -Identity $user -CompleteAfter $completeAfterUtc
            $check = Get-MoveRequest -Identity $user
            $result.CompleteAfter = if ($check.CompleteAfter) { $check.CompleteAfter.ToLocalTime().ToString('dd.MM.yyyy HH:mm') }
            $result.Ergebnis = 'Terminiert'
        } else {
            $result.Ergebnis = 'WhatIf - nicht geaendert'
        }
    } catch {
        $result.Ergebnis = "FEHLER: $($_.Exception.Message)"
    }

    $result
}

$results | Format-Table -AutoSize -Wrap
