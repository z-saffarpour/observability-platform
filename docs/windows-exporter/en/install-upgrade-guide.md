# windows_exporter install, upgrade, and uninstall guide

[فارسی](../fa/install-upgrade-guide.md) · [HTML](install-upgrade-guide.html) · [HTML فارسی](../fa/install-upgrade-guide.html)

This guide covers **remote** install and upgrade over WinRM to version **0.31.8**. Default scrape port: **9182** (Basic Auth off).

For manual local service setup, firewall, **creating and enabling Basic Auth**, and a sample `scrape_config`, see [Installation and configuration](install-config-guide.md#basic-auth-optional).

## Prerequisites

| Item | Notes |
|---|---|
| Client | PowerShell 5.1+; full package locally (exe, yml, `profiles/`, scripts) |
| Target | Windows Server 2016+; Administrator; WinRM / PowerShell Remoting enabled |
| Network | Client → target WinRM; Prometheus → TCP/9182 |
| Package | `windows_exporter.exe`, `windows_exporter.yml`, `web-config.yml`, `profiles/`, `scripts/powershell/windows-exporter/` (and `scripts/ssas/windows-exporter/` when present) |

Run the scripts **from a client**. Do not start `windows_exporter.exe` on the client.

```powershell
# Verify WinRM before install
Test-WSMan -ComputerName SERVER01
```

## Required access

List required access, create ACLs/firewall/rights, then audit:

```powershell
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -ShowRequirements
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20 -WhatIf
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 `
  -ComputerName SQL01 `
  -Credential (Get-Credential) `
  -ServiceAccount 'DOMAIN\svc-winexporter$' `
  -PrometheusRemoteAddress 10.10.10.20 `
  -GrantPerformanceMonitorUsers
```

`Set-WindowsExporterRequiredAccess.ps1` creates access; `Test-WindowsExporterRequiredAccess.ps1` audits it. SSAS Admin/DMV rights are configured inside Analysis Services, not by these scripts.

## Choosing a profile

| Method | Parameter | Behavior |
|---|---|---|
| Install default | no `-Profile` | root `windows_exporter.yml` |
| Fixed | `-Profile sql-server.yml` | role config from `profiles/` |
| Auto | `-AutoProfile` | role discovery via `Discover-WindowsExporterRole.ps1` per host |
| Upgrade preserve | no `-Profile` / `-AutoProfile` | keeps current `--config.file`; refreshes `profiles/` and `scripts/`, ensures `textfile_inputs/` |

Do not pass both `-Profile` and `-AutoProfile`. Role details: [Role-based profiles](profiles.md). On SSAS hosts, after the exporter is installed, install the metrics task separately per [SSAS monitoring](ssas-monitoring.md).

```powershell
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1 -ComputerName SQL01,SQL02 -Credential (Get-Credential)
```

## Remote install

Script: `scripts/powershell/windows-exporter/Install-WindowsExporterRemote.ps1`

### What it does

1. Copies package files, `profiles/`, and `scripts/` (powershell + ssas) from the client and creates `textfile_inputs/`
2. Creates a timestamped backup (`_backup\install_...`)
3. Creates or updates the native `windows_exporter` service ImagePath
4. Applies the service account and starts the service
5. Re-runs are safe (idempotent refresh)

> Installing the exporter alone does not create the SSAS metrics service. After install with an SSAS-capable profile, run `Install-SsasMetricsTask.ps1` as Administrator to install the `prometheus_windows_ssas` Windows service. Details: [SSAS monitoring](ssas-monitoring.md).

Default install path:

```text
C:\Program Files\Observability\PrometheusExporters\windows-exporter
```

### Key parameters

| Parameter | Default | Purpose |
|---|---|---|
| `-Computers` | (required) | Host names or list from a file |
| `-SourceRoot` | package root | Package path on the client |
| `-InstallRoot` | Program Files path above | Install path on the target |
| `-Profile` / `-AutoProfile` | — | Role config selection |
| `-ServiceAccountMode` | `LocalSystem` | `LocalSystem`, `LocalService`, `NetworkService`, `Credential`, `gMSA`, `NtService` |
| `-ServiceCredential` | — | For `Credential` mode |
| `-ServiceAccount` | — | gMSA ending with `$`; optional `NT SERVICE\<ServiceName>` for `NtService` |
| `-RemoteCredential` | — | WinRM credential |
| `-ServiceTimeoutSec` | `60` | Service stop/start wait timeout |
| `-WhatIf` | — | Dry run |

### Examples

```powershell
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 `
  -WhatIf

.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01,SQL02 `
  -Profile sql-server.yml `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01,APP01 `
  -AutoProfile `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01 `
  -Profile sql-server.yml `
  -ServiceAccountMode Credential `
  -ServiceCredential (Get-Credential) `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01 `
  -ServiceAccountMode gMSA `
  -ServiceAccount 'DOMAIN\svc-winexporter$' `
  -RemoteCredential (Get-Credential)

# Virtual service account (NT SERVICE\windows_exporter)
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01 `
  -ServiceAccountMode NtService `
  -RemoteCredential (Get-Credential)
# After NtService, harden ACLs for the virtual account:
# .\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -ComputerName SQL01 -Credential (Get-Credential) -ServiceAccount 'NT SERVICE\windows_exporter'
```

## Remote upgrade

Script: `scripts/powershell/windows-exporter/Upgrade-WindowsExporterRemote.ps1`

### What it does

1. Auto-detects **Native** or **NSSM** installs and the binary path
2. Backs up before replace (`_backup\upgrade_<version>_...`)
3. Refreshes the exe, YAML files, `profiles/`, and `scripts/`, and ensures `textfile_inputs/`
4. Verifies the installed version against `-ExpectedVersion` (default `0.31.8`)
5. Rolls back files (and ImagePath/AppParameters if a profile change was applied) when validation or startup fails
6. Keeps the newest `-KeepBackups` upgrade backups (default 5)

### Key parameters

| Parameter | Default | Purpose |
|---|---|---|
| `-Computers` | (required) | Target hosts |
| `-ExpectedVersion` | `0.31.8` | Expected package and post-install version |
| `-InstallRoot` | (auto-detect) | Only if the exe path cannot be detected |
| `-Profile` / `-AutoProfile` | preserve current | Change `--config.file` |
| `-ServiceAccountMode` | preserve current | `LocalSystem`, `LocalService`, `NetworkService`, `Credential`, `gMSA`, `NtService` |
| `-ServiceCredential` | — | For `Credential` mode |
| `-ServiceAccount` | — | gMSA ending with `$`; optional `NT SERVICE\<ServiceName>` for `NtService` |
| `-KeepBackups` | `5` | Number of `upgrade_*` backups to retain |
| `-RemoteCredential` | — | WinRM credential |
| `-ServiceTimeoutSec` | `60` | Service stop/start wait timeout |
| `-WhatIf` | — | Dry run |

### Examples

```powershell
.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 `
  -WhatIf

.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers SQL01,SQL02 `
  -Profile sql-server.yml `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers SQL01,SQL02 `
  -AutoProfile `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers SERVER01 `
  -ExpectedVersion 0.32.0 `
  -RemoteCredential (Get-Credential)

# Upgrade and switch to NT SERVICE\windows_exporter
.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers SQL01 `
  -ServiceAccountMode NtService `
  -RemoteCredential (Get-Credential)
```

## Remote uninstall

Script: `scripts/powershell/windows-exporter/Uninstall-WindowsExporterRemote.ps1`

The uninstaller uses WinRM, detects `ServiceBase` or `NSSM`, stops and removes `prometheus_windows_exporter`, and optionally removes its files. Unless `-SkipBackup` is specified, it first creates a ZIP under `C:\ProgramData\Observability\PrometheusExporters\uninstall-backups`. The Application event source is preserved by default so historical Event Viewer entries remain readable.

```powershell
# Preview only
.\scripts\powershell\windows-exporter\Uninstall-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 -WhatIf

# Remove service and deployment files; preserve Event Source
.\scripts\powershell\windows-exporter\Uninstall-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 `
  -ServiceMode Preserve `
  -RemoteCredential (Get-Credential)

# Remove only the service
.\scripts\powershell\windows-exporter\Uninstall-WindowsExporterRemote.ps1 `
  -Computers SERVER01 -KeepFiles
```

Important switches: `-KeepFiles`, `-SkipBackup`, and `-RemoveEventSource`. Use `-RemoveEventSource` only when historical Application events no longer need their registered source.

## Recommended rollout order

1. Canary one host with `-WhatIf`, then a real install/upgrade
2. Check `Get-Service windows_exporter` and `/metrics`
3. Verify Prometheus `up` and `windows_exporter_collector_success`
4. Confirm dashboards and rules against the new metric names
5. Roll out to the remaining servers

## Post-install / post-upgrade checks

```powershell
Get-Service windows_exporter
Get-CimInstance Win32_Service -Filter "Name='windows_exporter'" |
  Select-Object Name, State, StartName, PathName

.\windows_exporter.exe --version

Invoke-WebRequest http://localhost:9182/metrics
```

From Prometheus:

```powershell
Test-NetConnection SERVER01 -Port 9182
```

Health metrics: `up`, `windows_exporter_collector_success`, `windows_exporter_collector_duration_seconds`.

## Version 0.31.8 notes

- Startup rejects unknown YAML keys
- `telemetry.max-requests` is invalid
- The old `logon` collector is replaced by `terminal_services`
- `web-config.yml` alone is not enough; `--web.config.file` must be in the service ImagePath

## Quick troubleshooting

| Symptom | Action |
|---|---|
| WinRM / access errors | `Test-WSMan`; `Test-WindowsExporterRequiredAccess.ps1`; use `Set-WindowsExporterRequiredAccess.ps1` when creating ACLs/firewall |
| Service will not start | Application Event Log; run manually with the ImagePath args |
| Version mismatch on upgrade | Align `-ExpectedVersion` with package `--version` |
| Upgrade failed + rollback | Error message shows cause; backup under `_backup\upgrade_...` |
| 401 on `/metrics` | Only when Basic Auth is enabled: check hash/password and `--web.config.file` |

More detail: [Troubleshooting](troubleshooting.md).

## Related docs

- [Installation and configuration / Basic Auth](install-config-guide.md#basic-auth-optional)
- [Required access (Set/Test)](#required-access)
- [Role-based profiles](profiles.md)
- [SSAS monitoring](ssas-monitoring.md)
- [Prometheus rules](prometheus-rules.md)
- [Troubleshooting](troubleshooting.md)
