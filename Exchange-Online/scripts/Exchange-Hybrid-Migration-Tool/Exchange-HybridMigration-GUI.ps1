<#
.SYNOPSIS
    GUI zur Steuerung von Exchange-Hybrid-Migrationsbenutzern (Onboarding zu Exchange Online).

.DESCRIPTION
    - Verbindet sich mit Exchange Online (ExchangeOnlineManagement-Modul) und optional
      mit Microsoft Graph (Lizenzstatus).
    - Liest bestehende Migrationsbenutzer per Get-MigrationUser/Get-MoveRequest aus.
    - Zeigt sie in einer Liste mit Checkboxen an.
    - Erlaubt, ausgewaehlte Benutzer:
        a) sofort umzustellen (Start-MigrationUser bzw. Set-MoveRequest -CompleteAfter 1), oder
        b) zu einem gewaehlten Datum/Uhrzeit umzustellen, indem direkt in Exchange Online
           Set-MoveRequest -CompleteAfter <Zeitpunkt> gesetzt wird. Exchange selbst fuehrt
           die Fertigstellung dann zum gewaehlten Zeitpunkt serverseitig aus - unabhaengig
           davon, ob dieser Rechner zu dem Zeitpunkt noch laeuft.

.NOTES
    Benoetigt: Module ExchangeOnlineManagement und Microsoft.Graph.Users
    (werden bei Bedarf automatisch im Benutzerkontext installiert).
    Ausfuehrung als Benutzer mit Exchange-Online-Migrations-Berechtigungen.
#>

[CmdletBinding()]
param(
    [string]$LogPath = (Join-Path $PSScriptRoot 'ExchangeHybridMigration.log'),

    # Standardmaessig meldet sich das Skript beim Start von Exchange Online / Microsoft Graph ab,
    # damit nie versehentlich ein alter Tenant/Account wiederverwendet wird. Mit -SkipAutoLogout
    # kann das (z.B. fuer schnelles Testen) uebersprungen werden.
    [switch]$SkipAutoLogout
)

$script:IsGuiMode = $true

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $LogPath -Value $line -Encoding UTF8
    Write-Host $line
}

# ----------------------------------------------------------------------------
# Erster Befehl beim Start: von allen zwischengespeicherten Exchange-Online-/Microsoft-Graph-
# Sitzungen abmelden, damit nie versehentlich ein alter Tenant/Account (Token-Cache/Windows-
# Broker) stillschweigend wiederverwendet wird. Einfache, direkte Aufrufe ohne Modul-Import-
# Klimmzuege - falls die Module nicht installiert/geladen sind, greift einfach der catch-Block.
# ----------------------------------------------------------------------------
if (-not $SkipAutoLogout) {
    try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction Stop | Out-Null } catch { }
    try { Disconnect-MgGraph -ErrorAction Stop | Out-Null } catch { }
    Write-Log "Abmeldung von Exchange Online / Microsoft Graph beim Start versucht."
}

# ----------------------------------------------------------------------------
# Hilfsfunktionen
# ----------------------------------------------------------------------------

function Install-ModuleForCurrentUser {
    <#
        Installiert ein PowerShell-Modul im Benutzerkontext (-Scope CurrentUser),
        d.h. ohne Admin-Rechte. Stellt vorher sicher, dass NuGet-Provider und ein
        moderner TLS-Standard fuer den Zugriff auf die PowerShell Gallery vorhanden sind.
    #>
    param([string]$ModuleName, [version]$RequiredVersion)

    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
        Write-Log "NuGet-Paketanbieter fehlt, installiere ihn im Benutzerkontext..."
        Install-PackageProvider -Name NuGet -Scope CurrentUser -Force -ErrorAction Stop | Out-Null
    }

    $psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if ($psGallery -and $psGallery.InstallationPolicy -ne 'Trusted') {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    }

    if ($RequiredVersion) {
        Write-Log "Installiere Modul '$ModuleName' Version $RequiredVersion im Benutzerkontext (-Scope CurrentUser)..."
        Install-Module -Name $ModuleName -RequiredVersion $RequiredVersion -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Write-Log "Modul '$ModuleName' Version $RequiredVersion erfolgreich installiert."
    } else {
        Write-Log "Installiere Modul '$ModuleName' im Benutzerkontext (-Scope CurrentUser)..."
        Install-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Write-Log "Modul '$ModuleName' erfolgreich installiert."
    }
}

function Ensure-ModuleInstalled {
    <#
        Generische Modul-Pruefung/-Installation. Im GUI-Modus wird vor der Installation
        nachgefragt; im Hintergrundmodus (geplante Aufgabe, keine GUI vorhanden) wird
        automatisch ohne Rueckfrage installiert.
    #>
    param([string]$ModuleName, [string]$PromptText)

    if (Get-Module -ListAvailable -Name $ModuleName) {
        if (-not (Get-Module -Name $ModuleName)) {
            Import-Module $ModuleName -ErrorAction Stop
        }
        return
    }

    Write-Log "Modul '$ModuleName' ist nicht installiert." 'WARN'

    $shouldInstall = $true
    if ($script:IsGuiMode) {
        Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
        $confirm = [System.Windows.MessageBox]::Show(
            "$PromptText`n`nSoll es jetzt automatisch im Benutzerkontext installiert werden (Install-Module -Scope CurrentUser)?",
            "Modul fehlt", 'YesNo', 'Question')
        $shouldInstall = ($confirm -eq 'Yes')
    }

    if (-not $shouldInstall) {
        throw "Das Modul '$ModuleName' ist nicht installiert. Bitte manuell ausfuehren: Install-Module $ModuleName -Scope CurrentUser"
    }

    try {
        Install-ModuleForCurrentUser -ModuleName $ModuleName
    } catch {
        throw "Automatische Installation von '$ModuleName' fehlgeschlagen: $($_.Exception.Message)`nBitte manuell ausfuehren: Install-Module $ModuleName -Scope CurrentUser"
    }

    Import-Module $ModuleName -ErrorAction Stop
}

function Ensure-ExchangeOnlineModule {
    Ensure-ModuleInstalled -ModuleName 'ExchangeOnlineManagement' `
        -PromptText "Das PowerShell-Modul 'ExchangeOnlineManagement' ist nicht installiert."
}

function Ensure-GraphModule {
    Ensure-ModuleInstalled -ModuleName 'Microsoft.Graph.Users' `
        -PromptText "Fuer die Lizenz-/Exchange-Online-Status-Spalte wird das PowerShell-Modul 'Microsoft.Graph.Users' benoetigt (liest Lizenzinformationen aus Microsoft Entra ID)."
}

function Connect-GraphIfNeeded {
    Ensure-GraphModule

    $ctx = $null
    try { $ctx = Get-MgContext -ErrorAction Stop } catch { $ctx = $null }
    if ($ctx -and $ctx.Account) { return }

    try {
        Connect-MgGraph -Scopes 'User.Read.All' -NoWelcome -ErrorAction Stop
    } catch {
        throw "Anmeldung bei Microsoft Graph fehlgeschlagen: $($_.Exception.Message)"
    }
}

function Connect-IfNeeded {
    <#
        Stellt NUR die Verbindung zu Exchange Online her. Prueft bewusst NICHT,
        ob Migrations-Cmdlets verfuegbar sind - das passiert separat in
        Get-MigrationMode, damit ein fehlendes Cmdlet nicht als "Verbindung
        fehlgeschlagen" missverstanden wird.
    #>
    Ensure-ExchangeOnlineModule

    $connected = $false
    try {
        $info = Get-ConnectionInformation -ErrorAction Stop
        if ($info -and ($info | Where-Object { $_.State -eq 'Connected' })) {
            $connected = $true
        }
    } catch {
        $connected = $false
    }

    if ($connected) { return }

    try {
        Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
    } catch {
        $msg = $_.Exception.Message
        if ($msg -match 'cancel|abgebrochen|user_cancelled') {
            throw "Die Anmeldung wurde abgebrochen (Login-Fenster geschlossen oder MFA nicht bestaetigt). Bitte erneut versuchen."
        } elseif ($msg -match 'proxy|network|timeout|Namensaufloesung|could not be resolved') {
            throw "Keine Verbindung zu Exchange Online moeglich (Netzwerk/Proxy/DNS). Details: $msg"
        } else {
            throw "Connect-ExchangeOnline ist fehlgeschlagen: $msg"
        }
    }

    # Verbindung nach dem Connect-Versuch verifizieren
    try {
        $info = Get-ConnectionInformation -ErrorAction Stop
        if (-not ($info | Where-Object { $_.State -eq 'Connected' })) {
            throw "Nach Connect-ExchangeOnline besteht keine aktive Sitzung (Status pruefen mit Get-ConnectionInformation)."
        }
    } catch {
        throw "Verbindung konnte nicht bestaetigt werden: $($_.Exception.Message)"
    }
}

function Get-MigrationMode {
    <#
        Ermittelt, welcher Cmdlet-Satz fuer das verbundene Konto verfuegbar ist:
          - 'MigrationUser'  -> Get-MigrationUser / Start-MigrationUser (Migrationsbatches)
          - 'MoveRequest'    -> Get-MoveRequest / Resume-MoveRequest (klassische Hybrid-Verschiebeanfragen)
          - $null            -> keines von beiden verfuegbar (Berechtigungsproblem)
    #>
    if (Get-Command -Name Get-MigrationUser -ErrorAction SilentlyContinue) {
        return 'MigrationUser'
    }
    if (Get-Command -Name Get-MoveRequest -ErrorAction SilentlyContinue) {
        return 'MoveRequest'
    }
    return $null
}

function Invoke-MigrationCutoverOrStart {
    <#
        Fuehrt je nach aktuellem Status die richtige Aktion fuer einen Migrationsbenutzer aus:
          - Noch nicht gestartet / fehlgeschlagen  -> Start-MigrationUser bzw. Resume-MoveRequest
          - Bereits synchronisiert und wartend      -> Set-MoveRequest -CompleteAfter 1 (sofortiger Cutover)
        Hintergrund: Bei Hybrid-Remote-Move-Batches (MigrationType 'ExchangeRemoteMove') zeigt
        Get-MigrationUser nach erfolgreicher Erstsynchronisierung Status 'Synced'/State 'Waiting' -
        SupportedActions enthaelt dann kein 'Start' mehr. Die eigentliche Umstellung (Cutover) erfolgt
        nicht ueber Get-MigrationUser/Complete-MigrationBatch (das wuerde den GESAMTEN Batch abschliessen),
        sondern individuell ueber das darunterliegende MoveRequest-Objekt:
          Set-MoveRequest -Identity <Postfach> -CompleteAfter 1
        (siehe https://www.alitajran.com/complete-individual-mailbox-move-request-from-migration-batch/)
    #>
    param([string]$Identity, [string]$Mode)

    if ($Mode -eq 'MigrationUser') {
        $mu = Get-MigrationUser -Identity $Identity -ErrorAction Stop
        $isWaitingToComplete = ($mu.Status -eq 'Synced') -or ($mu.State -eq 'Waiting')
        if ($isWaitingToComplete) {
            Set-MoveRequest -Identity $Identity -CompleteAfter 1 -ErrorAction Stop
            return "Cutover ausgeloest (Set-MoveRequest -CompleteAfter 1) - vorheriger Status: $($mu.Status)/$($mu.State)"
        } else {
            Start-MigrationUser -Identity $Identity -ErrorAction Stop
            return "Migration gestartet (Start-MigrationUser) - vorheriger Status: $($mu.Status)/$($mu.State)"
        }
    } else {
        $mr = Get-MoveRequest -Identity $Identity -ErrorAction Stop
        if ($mr.Status -in @('AutoSuspended', 'Suspended')) {
            Resume-MoveRequest -Identity $Identity -ErrorAction Stop
            return "Verschiebeanfrage fortgesetzt (Resume-MoveRequest) - vorheriger Status: $($mr.Status)"
        } elseif ($mr.Status -in @('InProgress', 'Queued', 'CompletionInProgress', 'NeedsApproval')) {
            throw "MoveRequest ist bereits aktiv (Status: $($mr.Status)) - keine Aktion noetig, bitte Status abwarten."
        } else {
            Set-MoveRequest -Identity $Identity -CompleteAfter 1 -ErrorAction Stop
            return "Cutover ausgeloest (Set-MoveRequest -CompleteAfter 1) - vorheriger Status: $($mr.Status)"
        }
    }
}

function Get-CompleteAfterMap {
    <#
        Liefert eine Hashtable Identity(lowercase) -> CompleteAfter (DateTime, UTC) aus einer
        Liste von MoveRequest-Objekten. CompleteAfter ist eine direkte Property des
        MoveRequest-Objekts (gesetzt via Set-MoveRequest -CompleteAfter <Zeitpunkt>) - Exchange
        selbst haelt diesen Zeitpunkt vor, es ist KEINE lokale Ablage noetig.
    #>
    param($MoveRequests)
    $map = @{}
    foreach ($m in $MoveRequests) {
        if ($m.CompleteAfter -and $m.CompleteAfter -gt [DateTime]::MinValue) {
            $map[$m.Identity.ToString().ToLowerInvariant()] = $m.CompleteAfter
        }
    }
    return $map
}

function Get-MigrationDiagnostics {
    <#
        Liefert eine lesbare Liste vorhandener Exchange-Cmdlets, damit man im Fehlerfall
        sofort sieht, was das verbundene Konto ueberhaupt darf.
    #>
    $available = Get-Command -Name *Migration*, *MoveRequest* -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Name -Unique | Sort-Object
    if (-not $available -or $available.Count -eq 0) {
        return "Keine Migrations- oder MoveRequest-Cmdlets fuer dieses Konto sichtbar."
    }
    return "Verfuegbare Cmdlets: $($available -join ', ')"
}

function Get-LicenseMap {
    <#
        Liefert eine Hashtable UPN/Mail(lowercase) -> [PSCustomObject]{IsLicensed; ExchangeOnlineEnabled}
        ueber Microsoft Graph (Get-MgUser). Ein einziger, paginierter Aufruf fuer alle Benutzer statt
        pro Migrationsbenutzer eine eigene Abfrage.
        Bei Fehlern (z.B. fehlende Berechtigung User.Read.All, Graph-Modul lehnt Installation ab)
        wird eine leere Map zurueckgegeben und der Fehler geloggt - die Spalte zeigt dann "Unbekannt",
        ohne das Laden der Migrationsbenutzer zu blockieren.
    #>
    try {
        Connect-GraphIfNeeded
        $graphUsers = Get-MgUser -All -Property Id, UserPrincipalName, Mail, AssignedLicenses, AssignedPlans -ErrorAction Stop

        $map = @{}
        foreach ($gu in $graphUsers) {
            $isLicensed = [bool]($gu.AssignedLicenses -and $gu.AssignedLicenses.Count -gt 0)
            $exoEnabled = [bool]($gu.AssignedPlans | Where-Object {
                $_.ServicePlanName -like 'EXCHANGE*' -and $_.CapabilityStatus -eq 'Enabled'
            } | Select-Object -First 1)

            $info = [PSCustomObject]@{
                IsLicensed            = $isLicensed
                ExchangeOnlineEnabled = $exoEnabled
            }

            foreach ($key in @($gu.UserPrincipalName, $gu.Mail)) {
                if (-not [string]::IsNullOrWhiteSpace($key)) {
                    $map[$key.ToString().ToLowerInvariant()] = $info
                }
            }
        }
        Write-Log "Lizenzinformationen ueber Microsoft Graph geladen: $($map.Count) Eintraege."
        return $map
    } catch {
        Write-Log "Lizenzinformationen konnten nicht geladen werden (Microsoft Graph): $($_.Exception.Message)" 'ERROR'
        return @{}
    }
}

# ----------------------------------------------------------------------------
# GUI-Modus
# ----------------------------------------------------------------------------

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Exchange Hybrid Migration" Height="650" Width="1150"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <WrapPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
            <Button x:Name="BtnConnect" Content="Mit Exchange Online verbinden" Width="220" Height="30" Margin="0,0,10,5"/>
            <Button x:Name="BtnConnectGraph" Content="Mit Microsoft Graph verbinden" Width="220" Height="30" Margin="0,0,10,5"/>
            <Button x:Name="BtnRefresh" Content="Migrationsbenutzer aktualisieren" Width="220" Height="30" Margin="0,0,10,5"/>
            <ToggleButton x:Name="ToggleAutoRefresh" Content="Auto-Aktualisierung: AUS" Width="200" Height="30" Margin="0,0,10,5"/>
            <TextBlock Text="Suche:" VerticalAlignment="Center" Margin="10,0,5,5"/>
            <TextBox x:Name="TxtSearch" Width="220" Height="24" VerticalContentAlignment="Center" Margin="0,0,0,5" ToolTip="Filtert Identity, Batch, Status und Lizenz"/>
            <Button x:Name="BtnClearSearch" Content="X" Width="24" Height="24" Margin="4,0,10,5"/>
            <TextBlock x:Name="TxtStatus" VerticalAlignment="Center" Margin="10,0,0,5" Foreground="DarkSlateGray"/>
        </WrapPanel>

        <DataGrid x:Name="GridUsers" Grid.Row="1" AutoGenerateColumns="False"
                  CanUserAddRows="False" CanUserDeleteRows="False" SelectionMode="Extended"
                  IsReadOnly="False" AlternatingRowBackground="#FFF3F3F3" RowHeight="26">
            <DataGrid.Columns>
                <DataGridCheckBoxColumn Header="Auswahl" Binding="{Binding IsSelected, UpdateSourceTrigger=PropertyChanged}" Width="70"/>
                <DataGridTextColumn Header="Identity" Binding="{Binding Identity}" Width="260" IsReadOnly="True"/>
                <DataGridTextColumn Header="Batch" Binding="{Binding BatchId}" Width="150" IsReadOnly="True"/>
                <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="120" IsReadOnly="True"/>
                <DataGridTextColumn Header="Lizenz / Exchange Online" Binding="{Binding LicenseStatus}" Width="190" IsReadOnly="True"/>
                <DataGridTextColumn Header="Terminiert am" Binding="{Binding ScheduledFor}" Width="150" IsReadOnly="True"/>
                <DataGridTextColumn Header="Letzte Fehlermeldung" Binding="{Binding LastError}" Width="*" IsReadOnly="True"/>
            </DataGrid.Columns>
        </DataGrid>

        <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,10">
            <Button x:Name="BtnSelectAll" Content="Alle auswaehlen" Width="130" Height="28" Margin="0,0,10,0"/>
            <Button x:Name="BtnSelectNone" Content="Auswahl aufheben" Width="130" Height="28" Margin="0,0,20,0"/>

            <TextBlock Text="Datum:" VerticalAlignment="Center" Margin="0,0,5,0"/>
            <DatePicker x:Name="DatePickerSchedule" Width="130" Margin="0,0,15,0"/>

            <TextBlock Text="Uhrzeit (HH:mm):" VerticalAlignment="Center" Margin="0,0,5,0"/>
            <TextBox x:Name="TxtTime" Width="60" Text="20:00" Margin="0,0,20,0"/>
        </StackPanel>

        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right">
            <Button x:Name="BtnStartNow" Content="Ausgewaehlte jetzt umstellen" Width="220" Height="34" Margin="0,0,10,0" Background="#FF2E7D32" Foreground="White"/>
            <Button x:Name="BtnSchedule" Content="Ausgewaehlte terminieren" Width="220" Height="34" Background="#FF1565C0" Foreground="White"/>
        </StackPanel>
    </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$btnConnect      = $window.FindName('BtnConnect')
$btnConnectGraph = $window.FindName('BtnConnectGraph')
$btnRefresh      = $window.FindName('BtnRefresh')
$toggleAutoRefresh = $window.FindName('ToggleAutoRefresh')
$txtSearch       = $window.FindName('TxtSearch')
$btnClearSearch  = $window.FindName('BtnClearSearch')
$txtStatus       = $window.FindName('TxtStatus')
$gridUsers       = $window.FindName('GridUsers')
$btnSelectAll    = $window.FindName('BtnSelectAll')
$btnSelectNone   = $window.FindName('BtnSelectNone')
$datePicker      = $window.FindName('DatePickerSchedule')
$txtTime         = $window.FindName('TxtTime')
$btnStartNow     = $window.FindName('BtnStartNow')
$btnSchedule     = $window.FindName('BtnSchedule')

# Beobachtbare Collection als DataGrid-Datenquelle
$script:MigrationUsers = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$gridUsers.ItemsSource = $script:MigrationUsers
$script:MigrationMode = $null
$script:LicenseMapCache = $null
$script:LicenseMapCacheTime = [DateTime]::MinValue

# CollectionView fuer die Live-Suche/Filterung ueber der ObservableCollection
$script:UsersView = [System.Windows.Data.CollectionViewSource]::GetDefaultView($script:MigrationUsers)
$script:UsersView.Filter = {
    param($item)
    $q = $txtSearch.Text
    if ([string]::IsNullOrWhiteSpace($q)) { return $true }
    return ($item.Identity -like "*$q*") -or
           ($item.EmailAddress -like "*$q*") -or
           ($item.BatchId -like "*$q*") -or
           ($item.Status -like "*$q*") -or
           ($item.LicenseStatus -like "*$q*") -or
           ($item.ScheduledFor -like "*$q*") -or
           ($item.LastError -like "*$q*")
}

$txtSearch.Add_TextChanged({
    $script:UsersView.Refresh()
    $visibleCount = ($script:UsersView | Measure-Object).Count
    $txtStatus.Text = "$visibleCount von $($script:MigrationUsers.Count) Eintraegen sichtbar."
})

$btnClearSearch.Add_Click({
    $txtSearch.Text = ''
    $txtSearch.Focus() | Out-Null
})

function New-Row {
    param($Identity, $EmailAddress, $BatchId, $Status, $LastError, $ScheduledFor, $LicenseStatus)
    [PSCustomObject]@{
        IsSelected    = $false
        Identity      = $Identity
        EmailAddress  = $EmailAddress
        BatchId       = $BatchId
        Status        = $Status
        LicenseStatus = $LicenseStatus
        ScheduledFor  = $ScheduledFor
        LastError     = $LastError
    }
}

function Test-ExchangeOnlineConnected {
    try {
        $info = Get-ConnectionInformation -ErrorAction Stop
        return [bool]($info | Where-Object { $_.State -eq 'Connected' })
    } catch {
        return $false
    }
}

function Load-MigrationUsers {
    $txtStatus.Text = "Lade Migrationsbenutzer..."
    # Aktuelle Checkbox-Auswahl merken, damit sie nach dem Neuladen (z.B. durch
    # Auto-Aktualisierung) nicht verloren geht.
    $previouslySelected = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($row in $script:MigrationUsers) {
        if ($row.IsSelected) { [void]$previouslySelected.Add($row.Identity) }
    }

    $script:MigrationUsers.Clear()
    try {
        Connect-IfNeeded
        $script:MigrationMode = Get-MigrationMode

        if (-not $script:MigrationMode) {
            $diag = Get-MigrationDiagnostics
            $txtStatus.Text = "Kein Migrations-Cmdlet verfuegbar."
            Write-Log "Kein Migrations-Cmdlet verfuegbar. $diag" 'ERROR'
            [System.Windows.MessageBox]::Show(
                "Weder 'Get-MigrationUser' noch 'Get-MoveRequest' stehen fuer dieses Konto zur Verfuegung.`n`n" +
                "$diag`n`n" +
                "Bitte pruefen:`n" +
                "  Get-ManagementRoleAssignment -RoleAssignee '<dein-konto>' | Where-Object { `$_.Role -like '*Migration*' -or `$_.Role -like '*Move Mailboxes*' }`n`n" +
                "und dem Konto ggf. die Rollengruppe 'Recipient Management' oder 'Organization Management' zuweisen. " +
                "Danach neu anmelden (Connect-ExchangeOnline liest Rollen bei der Anmeldung ein).",
                "Keine Berechtigung fuer Migrations-Cmdlets", 'OK', 'Warning') | Out-Null
            return
        }

        # Lizenzinformationen sind teuer abzufragen (eine Microsoft-Graph-Abfrage ueber alle
        # Benutzer) - deshalb 5 Minuten gecacht, damit die 10-Sekunden-Auto-Aktualisierung
        # nicht bei jedem Tick erneut die komplette Lizenzliste abruft.
        $useCache = $script:LicenseMapCache -and ((Get-Date) - $script:LicenseMapCacheTime) -lt (New-TimeSpan -Minutes 5)
        if ($useCache) {
            $licenseMap = $script:LicenseMapCache
        } else {
            $licenseMap = Get-LicenseMap
            $script:LicenseMapCache = $licenseMap
            $script:LicenseMapCacheTime = Get-Date
        }

        # "CompleteAfter" kommt direkt von Exchange (MoveRequest-Objekt) - im MigrationUser-Modus
        # dafuer einmalig zusaetzlich Get-MoveRequest abfragen (best effort: schlaegt es fehl,
        # bleibt die Spalte leer, ohne das Laden der Migrationsbenutzer zu blockieren).
        $completeAfterMap = @{}
        if ($script:MigrationMode -eq 'MigrationUser') {
            try {
                $allMoveRequests = Get-MoveRequest -ResultSize Unlimited -ErrorAction Stop
                $completeAfterMap = Get-CompleteAfterMap -MoveRequests $allMoveRequests
            } catch {
                Write-Log "Get-MoveRequest fuer 'Terminiert am' fehlgeschlagen: $($_.Exception.Message)" 'WARN'
            }
        }

        function Resolve-ScheduledFor {
            param($Identity, $EmailAddress)
            foreach ($candidate in @($Identity, $EmailAddress)) {
                if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
                $key = $candidate.ToString().ToLowerInvariant()
                if ($completeAfterMap.ContainsKey($key)) {
                    return $completeAfterMap[$key].ToLocalTime().ToString('dd.MM.yyyy HH:mm')
                }
            }
            return $null
        }

        function Resolve-LicenseStatus {
            param($Identity, $EmailAddress)
            foreach ($candidate in @($Identity, $EmailAddress)) {
                if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
                $key = $candidate.ToString().ToLowerInvariant()
                if ($licenseMap.ContainsKey($key)) {
                    $info = $licenseMap[$key]
                    if (-not $info.IsLicensed) { return "Nicht lizenziert" }
                    if ($info.ExchangeOnlineEnabled) { return "Lizenziert, EXO aktiv" }
                    return "Lizenziert, EXO inaktiv"
                }
            }
            return "Unbekannt"
        }

        if ($script:MigrationMode -eq 'MigrationUser') {
            $users = Get-MigrationUser -ResultSize Unlimited -ErrorAction Stop
            foreach ($u in $users) {
                $scheduledFor = Resolve-ScheduledFor -Identity $u.Identity -EmailAddress $u.EmailAddress
                $licenseStatus = Resolve-LicenseStatus -Identity $u.Identity -EmailAddress $u.EmailAddress
                $row = New-Row -Identity $u.Identity -EmailAddress $u.EmailAddress -BatchId $u.BatchId -Status $u.Status -LastError $u.ErrorSummary -ScheduledFor $scheduledFor -LicenseStatus $licenseStatus
                if ($previouslySelected.Contains($row.Identity)) { $row.IsSelected = $true }
                $script:MigrationUsers.Add($row)
            }
        } else {
            $moves = Get-MoveRequest -ResultSize Unlimited -ErrorAction Stop
            foreach ($m in $moves) {
                $scheduledFor = if ($m.CompleteAfter -and $m.CompleteAfter -gt [DateTime]::MinValue) { $m.CompleteAfter.ToLocalTime().ToString('dd.MM.yyyy HH:mm') } else { $null }
                $licenseStatus = Resolve-LicenseStatus -Identity $m.Identity -EmailAddress $m.Identity
                $row = New-Row -Identity $m.Identity -EmailAddress $m.Identity -BatchId $m.BatchName -Status $m.Status -LastError $null -ScheduledFor $scheduledFor -LicenseStatus $licenseStatus
                if ($previouslySelected.Contains($row.Identity)) { $row.IsSelected = $true }
                $script:MigrationUsers.Add($row)
            }
        }

        $txtStatus.Text = "$($script:MigrationUsers.Count) Eintraege geladen (Modus: $($script:MigrationMode))."
        Write-Log "Eintraege geladen ueber Modus '$($script:MigrationMode)': $($script:MigrationUsers.Count)"
    } catch {
        $txtStatus.Text = "Fehler beim Laden: $($_.Exception.Message)"
        Write-Log "Fehler beim Laden der Migrationsbenutzer: $($_.Exception.Message)" 'ERROR'
        [System.Windows.MessageBox]::Show("Fehler beim Laden der Migrationsbenutzer:`n$($_.Exception.Message)", "Fehler", 'OK', 'Error') | Out-Null
    }
}

function Get-SelectedIdentities {
    $script:MigrationUsers | Where-Object { $_.IsSelected } | Select-Object -ExpandProperty Identity
}

# ----------------------------------------------------------------------------
# Event-Handler
# ----------------------------------------------------------------------------

$btnConnect.Add_Click({
    $txtStatus.Text = "Verbinde mit Exchange Online..."
    try {
        Connect-IfNeeded
        $script:MigrationMode = Get-MigrationMode
        if ($script:MigrationMode) {
            $txtStatus.Text = "Verbunden mit Exchange Online. Modus: $($script:MigrationMode)."
            Write-Log "Verbindung hergestellt. Migrationsmodus: $($script:MigrationMode)."
        } else {
            $txtStatus.Text = "Verbunden, aber keine Migrations-Cmdlets verfuegbar."
            Write-Log "Verbindung hergestellt, aber kein Migrations-Cmdlet gefunden. $(Get-MigrationDiagnostics)" 'WARN'
        }
    } catch {
        $txtStatus.Text = "Verbindung fehlgeschlagen."
        Write-Log "Verbindung fehlgeschlagen: $($_.Exception.Message)" 'ERROR'
        [System.Windows.MessageBox]::Show("Verbindung fehlgeschlagen:`n$($_.Exception.Message)", "Fehler", 'OK', 'Error') | Out-Null
    }
})

$btnConnectGraph.Add_Click({
    $txtStatus.Text = "Verbinde mit Microsoft Graph..."
    try {
        Connect-GraphIfNeeded
        $ctx = Get-MgContext -ErrorAction Stop
        $txtStatus.Text = "Verbunden mit Microsoft Graph ($($ctx.Account))."
        Write-Log "Verbindung zu Microsoft Graph hergestellt: $($ctx.Account)"

        # Lizenz-Cache erzwungen neu laden und Tabelle aktualisieren, damit man das Ergebnis sofort sieht
        $script:LicenseMapCache = Get-LicenseMap
        $script:LicenseMapCacheTime = Get-Date
        if ($script:MigrationMode) { Load-MigrationUsers }
    } catch {
        $txtStatus.Text = "Verbindung zu Microsoft Graph fehlgeschlagen."
        Write-Log "Verbindung zu Microsoft Graph fehlgeschlagen: $($_.Exception.Message)" 'ERROR'
        [System.Windows.MessageBox]::Show("Verbindung zu Microsoft Graph fehlgeschlagen:`n$($_.Exception.Message)", "Fehler", 'OK', 'Error') | Out-Null
    }
})

$btnRefresh.Add_Click({ Load-MigrationUsers })

# ----------------------------------------------------------------------------
# Auto-Aktualisierung alle 10 Sekunden (z.B. um einen laufenden Cutover zu beobachten)
# ----------------------------------------------------------------------------

$script:AutoRefreshTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:AutoRefreshTimer.Interval = [TimeSpan]::FromSeconds(10)
$script:IsAutoRefreshing = $false

$script:AutoRefreshTimer.Add_Tick({
    if ($script:IsAutoRefreshing) { return }
    if (-not (Test-ExchangeOnlineConnected)) {
        $script:AutoRefreshTimer.Stop()
        $toggleAutoRefresh.IsChecked = $false
        $txtStatus.Text = "Auto-Aktualisierung gestoppt: keine Verbindung zu Exchange Online."
        return
    }
    $script:IsAutoRefreshing = $true
    try {
        Load-MigrationUsers
    } finally {
        $script:IsAutoRefreshing = $false
    }
})

$toggleAutoRefresh.Add_Checked({
    if (-not (Test-ExchangeOnlineConnected)) {
        [System.Windows.MessageBox]::Show("Bitte zuerst mit Exchange Online verbinden.", "Hinweis", 'OK', 'Warning') | Out-Null
        $toggleAutoRefresh.IsChecked = $false
        return
    }
    $script:AutoRefreshTimer.Start()
    $toggleAutoRefresh.Content = "Auto-Aktualisierung: EIN (10s)"
})

$toggleAutoRefresh.Add_Unchecked({
    $script:AutoRefreshTimer.Stop()
    $toggleAutoRefresh.Content = "Auto-Aktualisierung: AUS"
})

$window.Add_Closing({ $script:AutoRefreshTimer.Stop() })

$btnSelectAll.Add_Click({
    foreach ($row in $script:UsersView) { $row.IsSelected = $true }
    $gridUsers.Items.Refresh()
})

$btnSelectNone.Add_Click({
    foreach ($row in $script:UsersView) { $row.IsSelected = $false }
    $gridUsers.Items.Refresh()
})

$btnStartNow.Add_Click({
    $gridUsers.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true)
    $selected = Get-SelectedIdentities
    if (-not $selected -or $selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Bitte mindestens einen Benutzer auswaehlen.", "Hinweis", 'OK', 'Warning') | Out-Null
        return
    }

    $confirm = [System.Windows.MessageBox]::Show(
        "Folgende Benutzer jetzt umstellen?`n`n$($selected -join "`n")",
        "Bestaetigung", 'YesNo', 'Question')
    if ($confirm -ne 'Yes') { return }

    try {
        Connect-IfNeeded
        if (-not $script:MigrationMode) { $script:MigrationMode = Get-MigrationMode }
        if (-not $script:MigrationMode) {
            [System.Windows.MessageBox]::Show("Kein Migrations-Cmdlet verfuegbar. $(Get-MigrationDiagnostics)", "Fehler", 'OK', 'Error') | Out-Null
            return
        }

        $resultLines = New-Object System.Collections.Generic.List[string]
        foreach ($identity in $selected) {
            try {
                $result = Invoke-MigrationCutoverOrStart -Identity $identity -Mode $script:MigrationMode
                Write-Log "$identity : $result"
                $resultLines.Add("$identity : $result")
            } catch {
                Write-Log "Fehler beim Verarbeiten von '$identity': $($_.Exception.Message)" 'ERROR'
                $resultLines.Add("$identity : FEHLER - $($_.Exception.Message)")
            }
        }
        [System.Windows.MessageBox]::Show(($resultLines -join "`n"), "Ergebnis", 'OK', 'Information') | Out-Null
        $txtStatus.Text = "Verarbeitung fuer $($selected.Count) Benutzer abgeschlossen."
        Load-MigrationUsers
    } catch {
        [System.Windows.MessageBox]::Show("Fehler:`n$($_.Exception.Message)", "Fehler", 'OK', 'Error') | Out-Null
    }
})

$btnSchedule.Add_Click({
    $gridUsers.CommitEdit([System.Windows.Controls.DataGridEditingUnit]::Cell, $true)
    $selected = Get-SelectedIdentities
    if (-not $selected -or $selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Bitte mindestens einen Benutzer auswaehlen.", "Hinweis", 'OK', 'Warning') | Out-Null
        return
    }
    # Falls das Datum eingetippt statt ueber den Kalender gewaehlt wurde, hat der DatePicker
    # den Text moeglicherweise noch nicht in SelectedDate uebernommen (das passiert erst bei
    # Fokuswechsel). Deshalb hier zur Sicherheit selbst aus dem angezeigten Text parsen.
    $selectedDate = $datePicker.SelectedDate
    if (-not $selectedDate) {
        $rawDateText = $datePicker.Text
        if ([string]::IsNullOrWhiteSpace($rawDateText)) {
            [System.Windows.MessageBox]::Show("Bitte ein Datum auswaehlen.", "Hinweis", 'OK', 'Warning') | Out-Null
            return
        }
        $parsedDate = New-Object DateTime
        $dateFormats = @('dd.MM.yyyy', 'd.M.yyyy', 'yyyy-MM-dd')
        $dateOk = $false
        foreach ($fmt in $dateFormats) {
            if ([DateTime]::TryParseExact($rawDateText, $fmt, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsedDate)) {
                $dateOk = $true
                break
            }
        }
        if (-not $dateOk -and [DateTime]::TryParse($rawDateText, [Globalization.CultureInfo]::CurrentCulture, [Globalization.DateTimeStyles]::None, [ref]$parsedDate)) {
            $dateOk = $true
        }
        if (-not $dateOk) {
            [System.Windows.MessageBox]::Show("Datum '$rawDateText' konnte nicht gelesen werden. Bitte Format TT.MM.JJJJ verwenden oder ueber den Kalender waehlen.", "Hinweis", 'OK', 'Warning') | Out-Null
            return
        }
        $selectedDate = $parsedDate
    }

    $timeText = $txtTime.Text.Trim()
    $parsedTime = New-Object DateTime
    if (-not [DateTime]::TryParseExact($timeText, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsedTime)) {
        [System.Windows.MessageBox]::Show("Ungueltige Uhrzeit. Bitte im Format HH:mm angeben (z.B. 20:00).", "Hinweis", 'OK', 'Warning') | Out-Null
        return
    }

    $scheduledDateTime = $selectedDate.Date.AddHours($parsedTime.Hour).AddMinutes($parsedTime.Minute)
    if ($scheduledDateTime -le (Get-Date)) {
        [System.Windows.MessageBox]::Show("Der gewaehlte Zeitpunkt liegt in der Vergangenheit.", "Hinweis", 'OK', 'Warning') | Out-Null
        return
    }

    $confirm = [System.Windows.MessageBox]::Show(
        "Folgende Benutzer am $($scheduledDateTime.ToString('dd.MM.yyyy HH:mm')) Uhr (lokale Zeit) automatisch fertigstellen (Cutover)?`n`n$($selected -join "`n")`n`n" +
        "Hinweis: Das setzt direkt in Exchange Online 'CompleteAfter' - funktioniert nur, wenn die Erstsynchronisierung des Postfachs bereits abgeschlossen ist (Status Synced/Waiting). " +
        "Der Zeitpunkt wird von Exchange selbst verwaltet, dieser Rechner muss dafuer nicht laufen.",
        "Bestaetigung", 'YesNo', 'Question')
    if ($confirm -ne 'Yes') { return }

    try {
        Connect-IfNeeded
        $completeAfterUtc = $scheduledDateTime.ToUniversalTime()

        $resultLines = New-Object System.Collections.Generic.List[string]
        foreach ($identity in $selected) {
            try {
                Set-MoveRequest -Identity $identity -CompleteAfter $completeAfterUtc -ErrorAction Stop
                Write-Log "$identity : Cutover terminiert fuer $($scheduledDateTime.ToString('dd.MM.yyyy HH:mm')) (lokal) / $completeAfterUtc (UTC)"
                $resultLines.Add("$identity : terminiert fuer $($scheduledDateTime.ToString('dd.MM.yyyy HH:mm'))")
            } catch {
                Write-Log "Fehler beim Terminieren von '$identity': $($_.Exception.Message)" 'ERROR'
                $resultLines.Add("$identity : FEHLER - $($_.Exception.Message)")
            }
        }
        [System.Windows.MessageBox]::Show(($resultLines -join "`n"), "Ergebnis", 'OK', 'Information') | Out-Null
        $txtStatus.Text = "Terminierung fuer $($selected.Count) Benutzer verarbeitet."
        Load-MigrationUsers
    } catch {
        [System.Windows.MessageBox]::Show("Fehler:`n$($_.Exception.Message)", "Fehler", 'OK', 'Error') | Out-Null
    }
})

if (-not $SkipAutoLogout) {
    $txtStatus.Text = "Alte Sitzungen abgemeldet. Bitte mit Exchange Online verbinden."
}

$window.ShowDialog() | Out-Null
