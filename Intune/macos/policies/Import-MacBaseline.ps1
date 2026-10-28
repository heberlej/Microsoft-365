<#
.SYNOPSIS
  Importiert die macOS-Baseline (MAC-*) in einen Intune-Tenant.
.DESCRIPTION
  Liest manifest.json, ersetzt Platzhalter, legt Gruppe + Filter an, erstellt alle Objekte
  und weist sie der Gruppe MAC-GRP-Geraete-Alle zu. Bereits vorhandene Objekte (gleicher Name) werden übersprungen.
.EXAMPLE
  ./Import-MacBaseline.ps1 -TenantId contoso.onmicrosoft.com -LoginfensterText 'Eigentum der Contoso GmbH' -OrgName 'Contoso' `
                           -SupportName 'IT Contoso' -SupportTelefon '+49 30 123456'
.EXAMPLE
  ./Import-MacBaseline.ps1 -TenantId contoso.onmicrosoft.com ... -WhatIf     # nur anzeigen, nichts anlegen
#>
param(
  [Parameter(Mandatory)][string]$TenantId,
  [Parameter(Mandatory)][string]$LoginfensterText,
  [Parameter(Mandatory)][string]$OrgName,
  [string]$SupportName = 'IT-Support',
  [string]$SupportTelefon = '',
  [switch]$OhneApps,          # Defender/M365/Edge nicht anlegen
  [switch]$OhneEinschreibung, # Einschreibungs-Beschränkung + ADE-Profil nicht anlegen
  [switch]$OhneZuweisung,     # Objekte nur anlegen, nichts zuweisen
  [switch]$WhatIf
)
$ErrorActionPreference = 'Stop'
$pkg = $PSScriptRoot
$manifest = Get-Content "$pkg/manifest.json" -Raw | ConvertFrom-Json

if (-not $WhatIf) {
  Connect-MgGraph -TenantId $TenantId -UseDeviceCode -NoWelcome -ContextScope Process -Scopes @(
    'DeviceManagementConfiguration.ReadWrite.All','DeviceManagementApps.ReadWrite.All','DeviceManagementServiceConfig.ReadWrite.All','Group.ReadWrite.All')
  "VERBUNDEN: $((Get-MgContext).Account) / $((Get-MgContext).TenantId)"
}
function G([string]$Method, [string]$Uri, $Body) {
  $p = @{ Method = $Method; Uri = "https://graph.microsoft.com/$Uri"; OutputType = 'PSObject' }
  if ($null -ne $Body) { $p.Body = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 60 }; $p.ContentType = 'application/json; charset=utf-8' }
  Invoke-MgGraphRequest @p
}
function All($uri) { $i = @(); do { $r = G GET $uri; $i += $r.value; $uri = "$($r.'@odata.nextLink')" -replace '^https://graph.microsoft.com/','' } while ($uri); $i }
function Msg($e) { $m = "$($e.ErrorDetails.Message)"; $i = $m.IndexOf('message'); if ($i -lt 0) { $i = $m.IndexOf('Message') }; if ($i -ge 0) { $m.Substring($i, [Math]::Min(400, $m.Length - $i)) } elseif ($m) { $m } else { $e.Exception.Message } }
function Load($datei) {
  $t = Get-Content "$pkg/$datei" -Raw -Encoding utf8
  $t = $t.Replace('__LOGINFENSTER_TEXT__', $LoginfensterText).Replace('__ORG_NAME__', $OrgName).Replace('__SUPPORT_NAME__', $SupportName).Replace('__SUPPORT_TELEFON__', $SupportTelefon)
  $t
}
$ziel = @{   # Typ -> Graph-Endpunkt, Namensfeld, Zuweisungs-Endpunkt/-Format
  Katalog       = @{ uri = 'beta/deviceManagement/configurationPolicies';          name = 'name' }
  Konfig        = @{ uri = 'beta/deviceManagement/deviceConfigurations';           name = 'displayName' }
  Compliance    = @{ uri = 'beta/deviceManagement/deviceCompliancePolicies';       name = 'displayName' }
  Attribut      = @{ uri = 'beta/deviceManagement/deviceCustomAttributeShellScripts'; name = 'displayName' }
  App           = @{ uri = 'beta/deviceAppManagement/mobileApps';                  name = 'displayName' }
  Einschreibung = @{ uri = 'beta/deviceManagement/deviceEnrollmentConfigurations'; name = 'displayName' }
}

# --- Gruppe + Filter
$grpBody = Load ($manifest.objekte | Where-Object typ -eq 'Gruppe').datei | ConvertFrom-Json
$fltBody = Load ($manifest.objekte | Where-Object typ -eq 'Filter').datei | ConvertFrom-Json
if ($WhatIf) { "WHATIF Gruppe $($grpBody.displayName) / Filter $($fltBody.displayName)"; $grp = @{ id = 'GRP' }; $flt = @{ id = 'FLT' } }
else {
  $grp = (G GET "v1.0/groups?`$filter=displayName eq '$($grpBody.displayName)'").value | Select-Object -First 1
  if (-not $grp) { $grp = G POST 'v1.0/groups' $grpBody; "OK   Gruppe $($grpBody.displayName)" } else { "SKIP Gruppe existiert" }
  $flt = (All 'beta/deviceManagement/assignmentFilters') | Where-Object displayName -eq $fltBody.displayName | Select-Object -First 1
  if (-not $flt) { $flt = G POST 'beta/deviceManagement/assignmentFilters' $fltBody; "OK   Filter $($fltBody.displayName)" } else { "SKIP Filter existiert" }
}
$tGrp  = @{ '@odata.type' = '#microsoft.graph.groupAssignmentTarget'; groupId = $grp.id }
$tFlt  = $tGrp + @{ deviceAndAppManagementAssignmentFilterId = $flt.id; deviceAndAppManagementAssignmentFilterType = 'include' }

# --- Objekte
$vorhanden = @{}
foreach ($o in $manifest.objekte | Where-Object { $_.typ -notin 'Gruppe','Filter','ADE' }) {
  if ($OhneApps -and $o.typ -eq 'App') { continue }
  if ($OhneEinschreibung -and $o.typ -eq 'Einschreibung') { continue }
  $z = $ziel[$o.typ]; $json = Load $o.datei
  if ($WhatIf) { "WHATIF $($o.typ) $($o.name) [$($o.zuweisung)]"; continue }
  if (-not $vorhanden[$o.typ]) { $vorhanden[$o.typ] = @(All "$($z.uri)?`$select=id,$($z.name)") }
  if ($vorhanden[$o.typ] | Where-Object { $_.($z.name) -eq $o.name }) { "SKIP existiert: $($o.name)"; continue }
  try { $r = G POST $z.uri $json; "OK   $($o.typ) $($o.name)" } catch { "FAIL $($o.typ) $($o.name): $(Msg $_)"; continue }
  if ($OhneZuweisung) { continue }
  try {
    switch ($o.typ) {
      'Katalog'       { G POST "$($z.uri)/$($r.id)/assign" @{ assignments = @(@{ target = $(if ($o.zuweisung -eq 'gruppe') { $tGrp } else { $tFlt }) }) } | Out-Null }
      'Konfig'        { G POST "$($z.uri)/$($r.id)/assign" @{ assignments = @(@{ target = $tFlt }) } | Out-Null }
      'Compliance'    { G POST "$($z.uri)/$($r.id)/assign" @{ assignments = @(@{ target = $tFlt }) } | Out-Null }
      'Attribut'      { G POST "$($z.uri)/$($r.id)/assign" @{ deviceManagementScriptAssignments = @(@{ target = $tGrp }) } | Out-Null }
      'App'           { G POST "$($z.uri)/$($r.id)/assign" @{ mobileAppAssignments = @(@{ '@odata.type' = '#microsoft.graph.mobileAppAssignment'; intent = 'required'; target = $tFlt }) } | Out-Null }
      'Einschreibung' { G POST "$($z.uri)/$($r.id)/assign" @{ enrollmentConfigurationAssignments = @(@{ target = @{ '@odata.type' = '#microsoft.graph.allLicensedUsersAssignmentTarget' } }) } | Out-Null }
    }
    "     -> zugewiesen ($($o.zuweisung))"
  } catch { "FAIL Zuweisung $($o.name): $(Msg $_)" }
}

# --- ADE-Profil je Token (als Standard setzen)
$adeObj = $manifest.objekte | Where-Object typ -eq 'ADE'
if ($adeObj -and -not $OhneEinschreibung) {
  if ($WhatIf) { "WHATIF ADE $($adeObj.name) (Standardprofil je ADE-Token)" }
  else {
    $tokens = @(All 'beta/deviceManagement/depOnboardingSettings')
    if (-not $tokens) { 'OFFEN ADE: kein Apple-ADE-Token im Tenant – Profil später anlegen' }
    foreach ($tok in $tokens) {
      $profiles = @(All "beta/deviceManagement/depOnboardingSettings/$($tok.id)/enrollmentProfiles")
      if ($profiles | Where-Object displayName -eq $adeObj.name) { "SKIP ADE existiert ($($tok.tokenName))"; continue }
      $b = Load $adeObj.datei | ConvertFrom-Json -AsHashtable
      if ($profiles) { $b.configurationEndpointUrl = $profiles[0].configurationEndpointUrl }
      try {
        $p = G POST "beta/deviceManagement/depOnboardingSettings/$($tok.id)/enrollmentProfiles" $b; "OK   ADE $($adeObj.name) ($($tok.tokenName))"
        G POST "beta/deviceManagement/depOnboardingSettings/$($tok.id)/enrollmentProfiles/$($p.id)/setDefaultProfile" $null | Out-Null; '     -> Standardprofil'
      } catch { "FAIL ADE ($($tok.tokenName)): $(Msg $_)" }
    }
  }
}

# --- Defender-Connector für macOS (für Risiko-Prüfung in MAC-CMP-Basis)
if (-not $WhatIf) {
  try { G PATCH 'beta/deviceManagement/mobileThreatDefenseConnectors/fc780465-2017-40d4-a0c5-307022471b92' @{ macEnabled = $true } | Out-Null; 'OK   Defender-Connector: macOS aktiviert' }
  catch { 'OFFEN Defender-Connector: Microsoft Defender for Endpoint ist im Ziel-Tenant nicht mit Intune verbunden (Defender-Portal > Einstellungen > Endpunkte > Erweiterte Features > Microsoft Intune-Verbindung)' }
  Disconnect-MgGraph | Out-Null
}
'IMPORT FERTIG'
