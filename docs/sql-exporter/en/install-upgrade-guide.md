# `sql_exporter` install, upgrade, and uninstall guide

This document covers **fresh installation**, **version upgrades**, and **safe remote removal** of `sql_exporter` on SQL Server hosts.

Documented and validated version in this project: **0.24.4**

For configuration details, collector profiles, and troubleshooting, see: [Install and config guide](install-config-guide.md)

HTML version (browser / print): [install-upgrade-guide.html](install-upgrade-guide.html)
· Persian: [../fa/install-upgrade-guide.html](../fa/install-upgrade-guide.html)

---

## Which script should I use?

| Goal | Script | Notes |
|------|--------|--------|
| Fresh install or create/update the service from scratch | `scripts/powershell/sql-exporter/Install-SqlExporterRemote.ps1` | Creates or updates the service; knows the default install path |
| Upgrade an existing installation | `scripts/powershell/sql-exporter/Upgrade-SqlExporterRemote.ps1` | Resolves the exe from the service; backs up; rolls back on failure |
| Remove the service and optionally its files | `scripts/powershell/sql-exporter/Uninstall-SqlExporterRemote.ps1` | Detects ServiceBase/NSSM; ZIP backup by default; supports `-WhatIf` |
| Config / profile only (no binary replace) | `scripts/powershell/sql-exporter/Deploy-SqlExporterConfig.ps1` | Deploys `sql_exporter.yml` (and `profiles\` when `-Profile` is set) |
| Sync collector `.yml` files only | `scripts/powershell/sql-exporter/Deploy-Collectors.ps1` | `-Layout Collector` (default) or `-Layout Root` — see below |
| Export Grafana dashboards → repo | `scripts/powershell/sql-exporter/Export-GrafanaDashboards.ps1` | Pulls live `sqlx-*` dashboards into `grafana/dashboards/` |

Install / Upgrade / Deploy-Config scripts use **WinRM**. Deploy-Collectors also uses WinRM for the service stop/start. Export-GrafanaDashboards talks to the Grafana HTTP API (`GRAFANA_URL` + `GRAFANA_SERVICE_ACCOUNT_TOKEN`).

---

## Sync collectors only (`Deploy-Collectors.ps1`)

Matches `sql_exporter.yml` (`collector_files: collector/*.collector.yml`) by default.

| `-Layout` | Behavior |
|-----------|----------|
| `Collector` (default) | Copy into remote `collector\`; remove `*.collector.yml` from install root |
| `Root` | Copy into install root; delete remote `collector\` folder |

```powershell
# Default layout (collector\)
.\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 -Computers sql-host-01,sql-host-02 -WhatIf

.\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -Layout Collector

# Flat root layout (legacy)
.\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 -Computers sql-host-01 -Layout Root
```

Filters inside the script:
- `ExcludeEverywhere` — never deploy; purged remotely
- `AllowOnlyOn` — deploy only to listed hosts (e.g. `mssql_restore` → `sql-host-02`)

---

## Prerequisites

- WinRM / PowerShell Remoting access to the target host
- An account that can install/manage Windows services on the target
- Package files at the project root:
  - `sql_exporter.exe`
  - `sql_exporter.yml`
  - `web-config.yml`
  - `collector/*.collector.yml`
  - `profiles/*.yml`
- SQL access for the service account (at minimum `VIEW SERVER STATE` and `VIEW ANY DEFINITION`)
- An open scrape port for Prometheus (upstream default: **9399**)

```powershell
# Verify WinRM before install
Test-WSMan -ComputerName sql-host-01
```

---

## Required access

List required access, create ACLs/firewall/account rights, then audit. SQL grants are separate (T-SQL script):

```powershell
.\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1 -ShowRequirements
.\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20 -WhatIf
.\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20
.\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1
.\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 `
  -ComputerName sql-host-01 `
  -Credential (Get-Credential) `
  -ServiceAccount 'DOMAIN\SqlExporterAccount' `
  -PrometheusRemoteAddress 10.10.10.20 `
  -GrantLogonAsService
```

| Role | Access | Tool |
|------|--------|------|
| Install/upgrade operator | Administrators on the target | WinRM account |
| Deploy client | WinRM / PowerShell Remoting | `Install-` / `Upgrade-` / `Deploy-*` |
| Windows service | Read on install path and `web-config.yml` | `Set-SqlExporterRequiredAccess.ps1` |
| Service → SQL Server | `VIEW SERVER STATE`, `VIEW ANY DEFINITION` (+ optional msdb/SSISDB/user DBs) | `scripts/sql/Create-SqlExporterLogin.sql` |
| Prometheus | TCP/**9399** (+ Basic Auth when enabled) | Firewall rule in `Set-…RequiredAccess.ps1` |

`Set-SqlExporterRequiredAccess.ps1` creates Windows/network access; `Test-SqlExporterRequiredAccess.ps1` audits it. SQL Server permissions are granted with `Create-SqlExporterLogin.sql` (as sysadmin) — not by the Set/Test scripts.

GRANT details and collector-specific rights: [Install and config guide — Grant access](install-config-guide.md#4-grant-access).

---

## Fresh install (remote — recommended)

### 1) Dry-run with WhatIf

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 -Computers sql-host-01,sql-host-02 -WhatIf
```

### 2) Apply

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)
```

### 2b) Apply with a collector profile

Same UX as `windows_exporter -Profile sql-server.yml`. SQL Exporter profiles live under `profiles/` (for example `oltp.yml`, `dwh.yml`):

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers OKDC34017 `
  -Profile oltp.yml `
  -RemoteCredential (Get-Credential)
```

This copies `profiles\` to the install path and writes the selected profile’s `collectors:` list into `sql_exporter.yml`.

### 3) Service account (optional)

Default: `LocalSystem`

Domain credential:

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -ServiceAccountMode Credential `
  -ServiceCredential (Get-Credential 'DOMAIN\SqlExporterAccount')
```

gMSA:

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -ServiceAccountMode gMSA `
  -ServiceAccount 'DOMAIN\SqlExporterAccount$'
```

### What gets installed

- Default install path:  
  `C:\Program Files\Observability\PrometheusExporters\sql-exporter`
- Service name: `prometheus_sql_exporter`
- Files: `sql_exporter.exe`, `sql_exporter.yml`, `web-config.yml`, `profiles\`, and `collector\` (unless `-SkipCollectors`)
- Default listen address: `:9399`

### Important install parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `-Computers` | sample list in the script | Targets |
| `-SourceRoot` | project root | Package source |
| `-InstallRoot` | Program Files path above | Install path on target |
| `-ServiceName` | `prometheus_sql_exporter` | Windows service name |
| `-ListenAddress` | `:9399` | Scrape address/port |
| `-Profile` | (empty) | Apply `profiles/<name>.yml` collectors into `sql_exporter.yml` |
| `-ServiceAccountMode` | `LocalSystem` | Service account type |
| `-RemoteCredential` | (empty) | WinRM credential |
| `-SkipCollectors` | off | Skip copying collectors |
| `-ServiceMode` | `ServiceBase` | Service host: `ServiceBase` or `NSSM` |

---

## Upgrade (remote)

Use the upgrade script when the service already exists and you want to move to the current package version (for example **0.24.4**).

### Upgrade script behavior

1. Compares the source binary version with `-ExpectedVersion`
2. Resolves `sql_exporter.exe` from the service (Native or NSSM)
3. Backs up `sql_exporter.exe`, `sql_exporter.yml`, `web-config.yml`, `collector\`, and `profiles\`
4. Stops the service, replaces binary/web-config/collectors/profiles, verifies version, starts the service
5. Without `-Profile`, leaves the remote `sql_exporter.yml` collectors unchanged; with `-Profile`, applies that profile’s collectors while preserving DSN and other settings
6. On start or version failure, restores files from backup
7. Prunes older backups beyond `-KeepBackups` (default: 5)

Example backup path:

```text
<InstallPath>\_backup\upgrade_<oldVersion>_yyyyMMdd_HHmmss\
```

### 1) Dry-run

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 -Computers sql-host-01,sql-host-02 -WhatIf
```

### 2) Apply upgrade

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)
```

### 2b) Upgrade and set a collector profile

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers OKDC34017 `
  -Profile oltp.yml `
  -RemoteCredential (Get-Credential)
```

### 3) If the exe path cannot be resolved from the service

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -InstallRoot 'D:\Monitoring\sql_exporter'
```

### Important upgrade parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `-Computers` | sample list in the script | Targets |
| `-SourceRoot` | project root | Package source |
| `-ExpectedVersion` | `0.24.4` | Expected binary version |
| `-ServiceName` | `prometheus_sql_exporter` | Service name |
| `-InstallRoot` | (empty = auto-detect) | Force install path |
| `-Profile` | (empty) | Apply `profiles/<name>.yml` collectors; omit to preserve remote config |
| `-RemoteCredential` | (empty) | WinRM credential |
| `-ServiceTimeoutSec` | `60` | Stop/start timeout |
| `-KeepBackups` | `5` | Number of backups to retain |

### Status values

| Status | Meaning |
|--------|---------|
| `Upgraded` | Version changed |
| `Refreshed` | Same version; files/collectors refreshed |
| `WhatIf` | Simulation only |
| `Failed` | Error; rollback applied when possible |

---

## Remote uninstall

Script: `scripts/powershell/sql-exporter/Uninstall-SqlExporterRemote.ps1`

It detects `ServiceBase` or `NSSM`, removes `prometheus_sql_exporter`, and deletes `C:\Program Files\Observability\PrometheusExporters\sql-exporter` unless `-KeepFiles` is used. A ZIP backup is created under `C:\ProgramData\Observability\PrometheusExporters\uninstall-backups` unless `-SkipBackup` is specified. The Event Source remains registered by default.

```powershell
# Preview
.\scripts\powershell\sql-exporter\Uninstall-SqlExporterRemote.ps1 `
  -Computers sql-host-01,sql-host-02 -WhatIf

# Remove service and files
.\scripts\powershell\sql-exporter\Uninstall-SqlExporterRemote.ps1 `
  -Computers sql-host-01,sql-host-02 `
  -ServiceMode Preserve `
  -RemoteCredential (Get-Credential)

# Remove service only
.\scripts\powershell\sql-exporter\Uninstall-SqlExporterRemote.ps1 `
  -Computers sql-host-01 -KeepFiles
```

Optional switches: `-SkipBackup` and `-RemoveEventSource`.

---

## Manual install / upgrade (no WinRM)

Use only when remote access is unavailable.

### Manual install

1. Copy the package folder to the server.
2. Set `data_source_name` in `sql_exporter.yml`.
3. Grant SQL permissions (details: [install-config-guide](install-config-guide.md)).
4. Create the Windows service, or use the install script against a reachable host.
5. Before starting the service:

```powershell
.\sql_exporter.exe "-config.file=sql_exporter.yml" -config.check
```

### Manual upgrade

1. Stop the service.
2. Back up the install folder.
3. Replace `sql_exporter.exe` (and `collector\` / yml files as needed).
4. Check the version:

```powershell
.\sql_exporter.exe --version
```

5. Start the service. If it fails, restore from backup.

---

## Health checks after install or upgrade

1. Service status:

```powershell
Get-Service prometheus_sql_exporter
```

2. Version:

```powershell
& 'C:\Program Files\Observability\PrometheusExporters\sql-exporter\sql_exporter.exe' --version
```

3. Metrics:

```text
http://HOSTNAME:9399/metrics
```

If Basic Auth is enabled in `web-config.yml`, test with username/password. How to create the hash and configure Prometheus: [Install and config guide — port and Basic Auth](install-config-guide.md#6-scrape-port-and-basic-auth-optional).

You should at least see:

- `mssql_up`
- `mssql_hostname`
- `mssql_product_version`

4. In Prometheus, the scrape target should show `up=1`.

---

## Quick deployment troubleshooting

| Issue | Check |
|-------|--------|
| WinRM cannot connect | Remoting, firewall, credential; `Test-WSMan`; `Test-SqlExporterRequiredAccess.ps1` |
| Service will not start | Event Viewer, `config.check`, ImagePath; for custom accounts use `-GrantLogonAsService` |
| Upgrade cannot resolve exe | Pass `-InstallRoot` |
| No metrics after upgrade | Port 9399, `sql_exporter.yml`, SQL permissions, Basic Auth / scrape job; `Test-SqlExporterRequiredAccess.ps1` |
| SQL access errors / empty metrics | `Create-SqlExporterLogin.sql`; collector permission notes in [install-config-guide](install-config-guide.md) |
| Automatic rollback | Script error output + `_backup` folder |

---

## Recommended rollout order

1. Test one non-critical server with `-WhatIf`, then apply.
2. Confirm `/metrics` and Prometheus scrape health.
3. Roll out remaining hosts from `servers.txt`.
4. For config/profile changes without replacing the binary, use `Deploy-SqlExporterConfig.ps1` (with or without `-Profile`) and the [config guide](install-config-guide.md).
5. To push only collector YAML updates, use `Deploy-Collectors.ps1` (`-Layout Collector` or `-Layout Root`).
