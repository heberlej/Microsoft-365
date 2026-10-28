# Microsoft Intune

Geräteverwaltung (MDM/MAM): Konfigurationsprofile, Compliance-Richtlinien, App-Bereitstellung, Remediations.

## Inhalt

- `scripts/` – PowerShell-/Automatisierungsskripte
- `macos/policies/` – macOS-Richtlinien als importierbare JSON-Dateien

## Skripte

| Skript | Zweck |
|---|---|
| [SecureBoot-CA2023-Check](scripts/SecureBoot-CA2023-Check/) | Erkennungsskript: Secure-Boot-Zertifikat Windows UEFI CA 2023 ausgerollt? |
| [Autopilot-HardwareHash-to-Blob](scripts/Autopilot-HardwareHash-to-Blob/) | Autopilot-Hash auslesen und per AzCopy in Azure Blob Storage hochladen |

## macOS

| Ordner | Zweck |
|---|---|
| [macos/policies](macos/policies/) | macOS-Baseline: 32 Intune-Objekte (Settings Catalog, Compliance, Apps, ADE …) als JSON inkl. Import-Skript |
