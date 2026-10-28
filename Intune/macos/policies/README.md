# macOS-Baseline für Intune – Importpaket

Namensschema: `MAC-<BEREICH>-<Inhalt>-<D|U>-v1.0` (D = Gerät, U = Benutzer)
Quelle: Intune-Export vom 27.10.2026, bereinigt (keine IDs, keine Zuweisungen, keine Tenant- oder Personendaten).

## Inhalt
| Ordner/Datei | Zweck |
|---|---|
| `objekte/*.json` | 32 Graph-Bodies (direkt per `POST` importierbar) |
| `manifest.json` | Reihenfolge, Typ, Zieldatei und Zuweisungsart je Objekt + Platzhalter |
| `Import-MacBaseline.ps1` | Importiert alles inkl. Gruppe, Filter und Zuweisungen |

## Voraussetzungen
- PowerShell 7 + Modul `Microsoft.Graph.Authentication`
- Konto mit Intune-Administrator + Gruppenrechten im Ziel-Tenant
- Optional: Apple-ADE-Token (für `MAC-ENR-ADE-Standard`), Defender-for-Endpoint-Verbindung zu Intune

## Import
```powershell
# Probelauf – zeigt nur an
./Import-MacBaseline.ps1 -TenantId contoso.onmicrosoft.com -LoginfensterText 'Eigentum der Contoso GmbH' -OrgName 'Contoso' -WhatIf
# Echter Import
./Import-MacBaseline.ps1 -TenantId contoso.onmicrosoft.com -LoginfensterText 'Eigentum der Contoso GmbH' -OrgName 'Contoso' `
                         -SupportName 'IT Contoso' -SupportTelefon '+49 30 123456'
```
Schalter: `-OhneApps`, `-OhneEinschreibung`, `-OhneZuweisung`. Bereits vorhandene Objekte (gleicher Name) werden übersprungen – das Skript kann gefahrlos erneut laufen.
Bei der Gerätecode-Anmeldung bleiben **120 Sekunden** für die Eingabe.

## Platzhalter
| Platzhalter | Parameter | Wo |
|---|---|---|
| `__LOGINFENSTER_TEXT__` | `-LoginfensterText` | MAC-SEC-Anmeldefenster |
| `__ORG_NAME__` | `-OrgName` | MAC-AUTH-PlatformSSO (Kontoanzeigename) |
| `__SUPPORT_NAME__` / `__SUPPORT_TELEFON__` | `-SupportName` / `-SupportTelefon` | MAC-ENR-ADE-Standard |

## Zuweisung
Alles geht an die dynamische Gruppe `MAC-GRP-Geraete-Alle` (`device.deviceOSType -eq "MacMDM"`), mit Filter `MAC-FLT-Firmengeraete` (nur firmeneigene Macs).
Ausnahmen: DDM-Profile (`MAC-SEC-Code-Sperre`, `MAC-UPD-macOS-DDM`) und Attribute unterstützen keine Filter → nur Gruppe.
Einschreibungs-Beschränkung → alle lizenzierten Benutzer. ADE-Profil → Standardprofil je ADE-Token.

## Nicht im Paket (tenant-/lizenzspezifisch, manuell)
- **MAC-DEF-Onboarding-D-v1.0** – Onboarding-Paket aus dem Defender-Portal des Ziel-Tenants (Einstellungen → Endpunkte → Onboarding → macOS → Microsoft Intune) als benutzerdefiniertes Profil hochladen.
- **Sophos Intercept X** – Originalprofile aus `SophosMacDeploymentTools.zip` (Sophos Central des Ziel-Tenants).
- **Global Secure Access Client** – PKG aus dem Entra-Admin-Center; die Systemerweiterungen gibt `MAC-NET-GlobalSecureAccess` bereits frei.

## Hinweise
- Compliance `MAC-CMP-Basis-v1.0` verlangt Defender-Risiko ≤ niedrig. Ohne Defender-Onboarding → nach 72 h nicht konform. Bei Bedarf in der Datei `advancedThreatProtectionRequiredSecurityLevel` entfernen.
- `MAC-AUTH-PlatformSSO`: Benutzer werden lokale **Admins** (`userauthorizationmode = 1`). Für Standardbenutzer auf `_0` ändern.
- App-Freigaben (AnyDesk, RustDesk, DisplayLink, BetterDisplay) sind an die Code-Signatur der Hersteller gebunden (Team-IDs KHRWM533LU, HZF9JMC8YN, 73YQY62QM3, 299YSU96J7).
