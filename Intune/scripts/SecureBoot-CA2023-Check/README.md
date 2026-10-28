# SecureBoot-CA2023-Check

Intune-**Erkennungsskript** (Skripts und Wartungen), das prüft, ob das Secure-Boot-Zertifikat **Windows UEFI CA 2023** auf dem Gerät ausgerollt ist (die 2011er-Zertifikate laufen 2026 ab).

## Prüfungen

1. Ist `Windows UEFI CA 2023` in der Secure-Boot-Datenbank (`db`) enthalten? → compliant
2. Sonst Registry `HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing`:
   - `UEFICA2023Status = Updated` **oder** `WindowsUEFICA2023Capable = 2`
   - **und** `UEFICA2023Error` fehlt oder ist `0`

| Exit-Code | Bedeutung |
|---|---|
| `0` | Compliant – Update ausgerollt |
| `1` | Nicht compliant – Wartungsskript wird ausgeführt |

## Einsatz in Intune

*Geräte → Skripts und Wartungen → Erstellen*

- Erkennungsskript: `SecureBootCheck.ps1`
- Skript mit den Anmeldeinformationen des angemeldeten Benutzers ausführen: **Nein**
- In 64-Bit-PowerShell ausführen: **Ja**

Lokal testen (als Administrator):

```powershell
.\SecureBootCheck.ps1; $LASTEXITCODE
```
