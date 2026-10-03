# SSAS Tabular and Multidimensional monitoring

[فارسی](../fa/ssas-monitoring.md)

The custom collector `Collect-SsasMetrics.ps1` exports DMV and AMO data through the windows_exporter **textfile** collector and works for both storage modes. User names are intentionally not published as Prometheus labels; only counts are exported to avoid leaking security data and to keep cardinality under control.

Remote install of windows_exporter (`Install-WindowsExporterRemote.ps1`) deploys the exporter, role profiles, `scripts/powershell`, `scripts/ssas`, and `textfile_inputs`. On SSAS hosts you must still run `Install-SsasMetricsTask.ps1` as Administrator to install the `prometheus_windows_ssas` Windows service (and optionally deploy the XEvent session). For exporter deployment itself, see [Install and upgrade](install-upgrade-guide.md).

The service can use the built-in `ServiceBase` host or NSSM. Remote install and upgrade deploy NSSM to `C:\Program Files\Observability\Tools\NSSM\nssm.exe`.

```powershell
# Built-in host (default)
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 -ServiceMode ServiceBase

# NSSM host
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 -ServiceMode NSSM
```

Both local and remote installers set the service **Log On** account. `-ServiceAccountMode` supports `LocalSystem` (default), `LocalService`, `NetworkService`, `Credential`, `gMSA`, and `NtService`. For a domain service account, use `-ServiceAccountMode Credential -ServiceCredential (Get-Credential 'DOMAIN\svc-ssas-monitoring')`; for a gMSA, use `-ServiceAccountMode gMSA -ServiceAccount 'DOMAIN\gmsa-ssas-monitoring$'`.

The installer writes step-by-step progress and failures to `Log\prometheus_windows_ssas.install.log` beneath the installation root, as well as to the interactive console. It registers `prometheus_windows_ssas` as an Application event source: Event ID `1001` records a successful installation and Event ID `1002` records an installation failure. Collector lifecycle/errors use the same source. NSSM's own wrapper-internal messages retain its compiled-in `nssm` source. Use `ServiceBase` when every related Application entry must show the service name.

For WinRM-based fleet deployment and removal, run the remote orchestrators from the management host:

```powershell
.\scripts\powershell\windows-exporter\Install-SsasMetricsRemote.ps1 -Computers SSAS01,SSAS02 -ServiceMode ServiceBase
.\scripts\powershell\windows-exporter\Uninstall-SsasMetricsRemote.ps1 -Computers SSAS01,SSAS02 -ServiceMode Preserve
```

### Remote service lifecycle

`Install-SsasMetricsRemote.ps1` stages the required collector and service-host scripts, installs or updates `prometheus_windows_ssas`, writes `collector/ssas-collector.json`, and deploys the shared NSSM binary to `C:\Program Files\Observability\Tools\NSSM\nssm.exe` when `-ServiceMode NSSM` is selected.

```powershell
# Preview NSSM deployment
.\scripts\powershell\windows-exporter\Install-SsasMetricsRemote.ps1 `
  -Computers SSAS01,SSAS02 -ServiceMode NSSM -WhatIf

# Install and configure instances
.\scripts\powershell\windows-exporter\Install-SsasMetricsRemote.ps1 `
  -Computers SSAS01,SSAS02 `
  -ServiceMode ServiceBase `
  -Instance 'localhost','SSAS01\TABULAR' `
  -RemoteCredential (Get-Credential)
```

`Uninstall-SsasMetricsRemote.ps1` removes the service and the legacy scheduled task. Shared windows_exporter files are preserved. `-RemoveFiles` removes only SSAS-specific scripts, `collector/ssas-collector.json`, SSAS textfile outputs, and SSAS logs after creating a backup. Add `-SkipBackup` only when recovery is not required.

```powershell
.\scripts\powershell\windows-exporter\Uninstall-SsasMetricsRemote.ps1 `
  -Computers SSAS01,SSAS02 -ServiceMode Preserve -WhatIf

.\scripts\powershell\windows-exporter\Uninstall-SsasMetricsRemote.ps1 `
  -Computers SSAS01,SSAS02 `
  -ServiceMode Preserve `
  -RemoveFiles `
  -RemoteCredential (Get-Credential)
```

The local helpers `Install-SsasMetricsTask.ps1` and `Uninstall-SsasMetricsService.ps1` remain available for direct execution on a target server.

## Installation

Prerequisites: SSAS client libraries including `Microsoft.AnalysisServices.AdomdClient` and AMO. The service Log On account must be allowed to connect and read DMVs; full role/member counts need SSAS administrative rights.

```powershell
Set-Location 'C:\Program Files\Observability\PrometheusExporters\windows-exporter'
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 -Instance localhost
# Named instance or multiple instances:
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 -Instance 'SERVER01\TABULAR','SERVER01\MD'
```

Run windows_exporter with `profiles/ssas.yml` (or `data-platform.yml` / `data-platform-cluster.yml` when combined with SQL/PBIRS), then restart the service. Manual smoke test:

```powershell
.\scripts\powershell\windows-exporter\Collect-SsasMetrics.ps1 -Instance localhost
Get-Content .\textfile_inputs\ssas.prom
Invoke-WebRequest http://localhost:9182/metrics | Select-String 'ssas_'
```

## Core metrics

| Metric | Meaning |
|---|---|
| `ssas_up`, `ssas_server_info` | Connectivity, mode, version, edition |
| `ssas_databases`, `ssas_database_info` | Database inventory and compatibility level |
| `ssas_database_last_processed_timestamp_seconds` | Newest partition/dimension process time in the database |
| `ssas_database_processing_stale` | `1` when any partition or dimension in the database is stale |
| `ssas_database_stale_partitions` | Count of stale partitions in the database |
| `ssas_database_stale_dimensions` | Count of stale dimensions in the database |
| `ssas_object_last_processed_timestamp_seconds` | Last processed/refreshed time per partition or dimension |
| `ssas_object_processing_stale` | Stale flag per partition or dimension (`object_type` = `partition` or `dimension`) |
| `ssas_sessions`, `ssas_connections`, `ssas_commands_active` | Concurrent load |
| `ssas_sessions_by_login` | Active sessions by `login`, `application`, `database`, and `client_host` (client IP or hostname from DMV) |
| `ssas_unique_logins` | Distinct logins among current sessions |
| `ssas_session_cpu_time_seconds_total` | Aggregated CPU from observed sessions |
| `ssas_server_administrators` | Server admin role member count |
| `ssas_roles`, `ssas_role_members` | Role and member counts by database and permission (Tabular: `TMSCHEMA_ROLES` via ADOMD; Multidimensional: `Database.Roles` via AMO) |
| `ssas_high_privilege_logins` | Distinct Administrator/Refresh principals plus server admins |
| `ssas_privileged_active_sessions` | Current sessions for high-privilege users |
| `ssas_collector_errors`, `ssas_collector_duration_seconds` | Collector health |
| `ssas_database_size_bytes` | Tabular VertiPaq segment bytes summed per database; Multidimensional uses AMO `EstimateSize` |
| `ssas_database_memory_bytes` | Sum of live database memory rows matched by `OBJECT_PARENT_PATH` / `ObjectParentPath` (falls back to `DISCOVER_MEMORYUSAGE` when `DISCOVER_OBJECT_MEMORY_USAGE` overflows) |
| `ssas_memory_object_usage_bytes` | Memory breakdown per database and `object_group` from the same DMV |
| `ssas_tabular_object_size_bytes` | Tabular segment bytes per database/table_id/column_id |

In this implementation, **high privilege** includes Server Administrator and database roles with `Administrator`, `Refresh`, or `ReadRefresh`. On older Multidimensional builds where AMO permission properties are not readable, a role whose name contains `admin` is treated as a fallback; validate that on a canary against your real role naming.

Sample alerts live in `prometheus/alert-rules/windows-exporter/windows_exporter-role-ssas.rules.yml` and are wired via `prometheus/scrape-configs/windows-exporter/ssas.yml`. The default processing-stale threshold is 24 hours and must be tuned to each model's schedule. Catalog: [Alerting](alerting.md).

## Grafana dashboard

Import `grafana/dashboards/winexp-00-ssas.json` via **Dashboards > Import**. The dashboard filters on Prometheus job, Windows server, SSAS instance, and database, and shows availability, session/login load, high privilege, role membership, processing freshness, version info, and `msmdsrv` CPU/memory.

The default Prometheus datasource UID matches the other package dashboards (`ce0xqwhy35wqod`). If your environment uses a different UID, map the datasource on import or replace the UID in the JSON.

## Collector architecture

| Script | Data |
|---|---|
| `Collect-SsasMetrics.ps1` | Service/PID, TCP endpoint, live probe, DMV session/connection/command, AMO database/role, Tabular segment sizes |
| `Collect-SsasPerformanceCounters.ps1` | Official Connection, Cache, Locks, Memory, Processing, Storage Engine Query, Threads, and Reliability counter groups |
| `Collect-SsasXEventMetrics.ps1` | Cumulative Login/Logout, security, Processing, Backup, and Query counters from XEL files |
| `Invoke-SsasCollectors.ps1` | Runs all three collectors from the SSAS metrics service |
| `Run-SsasMetricsService.ps1` | Windows ServiceBase host for `prometheus_windows_ssas` |

In addition to fixed aliases, every selected counter group is also published as `ssas_performance_counter_value` with limited labels `counter_set`, `group`, `counter`, and `perf_instance`. Performance object names differ by product version and named instance, so they are discovered at runtime.

## Standard file locations

| Purpose | Recommended path |
|---|---|
| Collector install and config | `C:\Program Files\Observability\PrometheusExporters\windows-exporter\` |
| Prometheus output (`.prom`) | `...\textfile_inputs\` |
| Small collector state files | `...\state\` |
| XEL/XEM files (written by SSAS) | `C:\ProgramData\Observability\SSAS\xevents\` |
| Read-only probe connection string | `C:\ProgramData\Observability\SSAS\secrets\` |
| SIEM audit JSONL | `C:\ProgramData\Observability\SSAS\audit\ssas-security-audit.jsonl` |
| SSAS backups (outside Observability) | Real backup path on the server (for example `D:\SSAS\Backup`) |

`Install-SsasMetricsTask.ps1` creates `ProgramData\Observability\SSAS\` during installation. With `-EnableXEvents`, when `-XelPath` is omitted, the default `C:\ProgramData\Observability\SSAS\xevents\*.xel` is written to `collector\ssas-collector.json`.

## Path defaults on install and upgrade

`ProgramData` paths and rotation settings are written to `collector\ssas-collector.json`. On reinstall or upgrade, existing `Instance`, `Endpoint`, and timeout values are preserved; standard paths and the `Rotation` section are refreshed from current defaults.

| Install parameter | Default |
|---|---|
| `ProgramDataRoot` | `C:\ProgramData\Observability\SSAS` |
| `XEventsDirectory` | `...\SSAS\xevents` |
| `SecretsDirectory` | `...\SSAS\secrets` |
| `AuditDirectory` | `...\SSAS\audit` |
| `SiemOutputPath` | `...\audit\ssas-security-audit.jsonl` |

Override example:

```powershell
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 `
  -Instance 'NODE' `
  -Endpoint 'NODE=localhost:49160' `
  -EnableXEvents `
  -ProgramDataRoot 'D:\Observability\SSAS' `
  -AuditLogMaxBytes 104857600
```

To refresh config only without reinstalling the service:

```powershell
.\scripts\powershell\windows-exporter\Update-SsasCollectorConfig.ps1
```

`Upgrade-WindowsExporterRemote.ps1` copies SSAS scripts and merges `ssas-collector.json` on hosts where `prometheus_windows_ssas` is installed.

Example `ssas-collector.json` structure:

```json
{
  "Instance": ["NODE"],
  "Endpoint": ["NODE=localhost:49160"],
  "Paths": {
    "ProgramDataRoot": "C:\\ProgramData\\Observability\\SSAS",
    "XEventsDirectory": "C:\\ProgramData\\Observability\\SSAS\\xevents",
    "SecretsDirectory": "C:\\ProgramData\\Observability\\SSAS\\secrets",
    "AuditDirectory": "C:\\ProgramData\\Observability\\SSAS\\audit"
  },
  "XelPath": ["C:\\ProgramData\\Observability\\SSAS\\xevents\\*.xel"],
  "SiemOutputPath": "C:\\ProgramData\\Observability\\SSAS\\audit\\ssas-security-audit.jsonl",
  "CommandTimeoutSec": 120,
  "Rotation": {
    "AuditLogMaxBytes": 52428800,
    "XelFileMaxBytes": 1073741824,
    "XelDirectoryMaxBytes": 5368709120,
    "KeepRotatedFiles": 10
  }
}
```

## File rotation

When files exceed configured limits, the collector rotates them automatically:

| Setting | Default | Behavior |
|---|---|---|
| `AuditLogMaxBytes` | 50 MB | Audit JSONL moved to `audit\archive\` |
| `XelFileMaxBytes` | 1 GB | Stale inactive `.xel` files moved to `xevents\archive\` |
| `XelDirectoryMaxBytes` | 5 GB | Total xevents directory size cap (including archive) |
| `KeepRotatedFiles` | 10 | Maximum archived files retained |

The Extended Events XMLA session also sets `max_file_size=256` MB and `max_rollover_files=10` (SSAS-side rollover). Collector rotation complements this by archiving or removing processed or oversized files.

Override limits at install time:

```powershell
.\Install-SsasMetricsRemote.ps1 -Computers SSAS01 `
  -Instance 'NODE' -Endpoint 'NODE=localhost:49160' -EnableXEvents `
  -AuditLogMaxBytes 104857600 -XelDirectoryMaxBytes 10737418240
```

## Full installation

Default instance:

```powershell
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 `
  -Instance localhost `
  -Endpoint 'localhost=localhost:2383' `
  -BackupPath 'D:\SSAS\Backup' `
  -EnableXEvents
```

Named instances require the real listen ports:

```powershell
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 `
  -Instance 'SERVER01\TABULAR','SERVER01\MD' `
  -Endpoint 'SERVER01\TABULAR=SERVER01:51342','SERVER01\MD=SERVER01:51343' `
  -BackupPath 'E:\SSAS-Backup' `
  -EnableXEvents
```

Or pass an explicit path in the same install command:

```powershell
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 `
  -Instance 'SERVER01\TABULAR' `
  -Endpoint 'SERVER01\TABULAR=SERVER01:51342' `
  -XelPath 'C:\ProgramData\Observability\SSAS\xevents\*.xel'
```

The task runs as `SYSTEM` by default. Full `DISCOVER_SESSIONS` and role/member reads need an appropriate SSAS admin identity on that account. An optional separate read-only probe is supported: put the connection string in a file whose ACL is readable only by `SYSTEM` and Administrators, then map it:

```powershell
$probeFile='C:\ProgramData\Observability\SSAS\secrets\readonly-probe.connectionstring'
# Example content: Data Source=SERVER01\TABULAR;User ID=DOMAIN\ssas_probe;Password=...;Application Name=Prometheus ReadOnly Probe
icacls $probeFile /inheritance:r /grant:r 'SYSTEM:R' 'Administrators:F'

.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 `
  -Instance 'SERVER01\TABULAR' `
  -ReadOnlyProbeConnectionStringFile "SERVER01\TABULAR=$probeFile"
```

If no separate probe file is defined, the probe runs as the scheduled-task identity and is labeled `probe_mode="collector_identity"`. Passwords are never written to labels or `.prom` files.

## Extended Events and SIEM

`scripts/ssas/windows-exporter/ssas-monitoring-xevents.xmla` is a session template covering `AuditLogin`, `AuditLogout`, `AuditServerStartsAndStops`, `AuditObjectPermissionEvent`, `AuditAdminOperationsEvent`, `ProgressReportEnd`, `QueryEnd`, and `Error`. Review the XEL path, then execute the XMLA from an Analysis Services connection in SSMS. Event/action names can differ on older builds; in that case create an equivalent session under **Management > Extended Events**, script it, and replace the template.

`Collect-SsasXEventMetrics.ps1` requires the PowerShell `SqlServer` module and `Read-SqlXEvent`. Per-file read offsets and cumulative counters are stored in `state/ssas-xevents-state.json`. Deleting that file resets counters and may re-read XEL data.

Username, client, application, database, and event text are written only to `C:\ProgramData\Observability\SSAS\audit\ssas-security-audit.jsonl` for WEC/SIEM forwarding; no username or IP is promoted to a Prometheus label.

## Metric coverage

- Availability: `ssas_service_running`, `ssas_service_uptime_seconds`, `ssas_service_restarts_total`, `ssas_endpoint_up`, `ssas_endpoint_response_seconds`, `ssas_readonly_probe_success` and response time.
- Connection/Session: `ssas_active_*`, long/idle sessions, database/application breakdowns, and connection totals/rates.
- Security history: `ssas_logins_total`, `ssas_logouts_total`, failures, permission/admin operations, privileged changes.
- Privilege: server admin, implicit Local Admin, service-account direct admin, and admin/process/readwrite role members.
- Processing/Backup: LastProcessed per database, last successful processing, last processing duration, failure totals, and last backup from xEvents or ABF files.
- Performance: query rate/duration/failure, cache, lock/wait, thread pool, processing rows/partitions, DirectQuery, memory usage/limits/pressure, reliability.
- Tabular capacity: `ssas_tabular_object_size_bytes`, `ssas_database_size_bytes`, row and segment counts by database/table_id/column_id.
- Database memory: `ssas_database_memory_bytes` and `ssas_memory_object_usage_bytes` from `DISCOVER_OBJECT_MEMORY_USAGE` (with DMV name fallbacks).
- Host capacity: CPU, Working Set/Private Bytes, page fault, disk latency/IOPS, and free space from standard `process`, `cpu`, `memory`, and `logical_disk` collectors.

Rule thresholds include 24 hours for processing, 48 hours for backup, and a 50% processing-duration increase; tune them to each model's SLA.

Official references: [SSAS performance counters](https://learn.microsoft.com/en-us/analysis-services/instances/performance-counters-ssas?view=sql-analysis-services-2025), [Analysis Services DMVs](https://learn.microsoft.com/en-us/analysis-services/instances/use-dynamic-management-views-dmvs-to-monitor-analysis-services?view=asallproducts-allversions), [SSAS Extended Events](https://learn.microsoft.com/en-us/analysis-services/instances/monitor-analysis-services-with-sql-server-extended-events?view=sql-analysis-services-2025), [Security Audit Events](https://learn.microsoft.com/en-us/analysis-services/trace-events/security-audit-event-category?view=sql-analysis-services-2025), and [Server Administrator](https://learn.microsoft.com/en-us/analysis-services/instances/grant-server-admin-rights-to-an-analysis-services-instance?view=sql-analysis-services-2025).
