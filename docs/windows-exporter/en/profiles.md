# Role-based windows_exporter profiles

[فارسی](../fa/profiles.md)

Profiles are complete YAML files selected with `--config.file`; they are not a
built-in windows_exporter feature.

| Profile | Use when |
|---|---|
| `windows-base.yml` | Windows host without a Data Platform role |
| `windows-cluster.yml` | Cluster node without a Data Platform role |
| `sql-server.yml` | Standalone SQL Server |
| `ssas.yml` | SSAS Tabular or Multidimensional |
| `powerbi-report-server.yml` | Power BI Report Server |
| `data-platform.yml` | Combined SQL/SSAS/PBIRS on one host |
| `data-platform-cluster.yml` | Cluster node with one or more Data Platform roles |
| `dynamics-ax-2012.yml` | Microsoft Dynamics AX 2012 AOS |
| `d365-finance-operations.yml` | D365 Finance & Operations on-premises / Service Fabric |
| `dynamics-platform.yml` | Host with both AX 2012 and D365 components |
| `terminal-server.yml` | Remote Desktop Session Host / Terminal Server |

## Role discovery

Discovery is read-only and based on Windows service names:

```powershell
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1 -ComputerName SQL01,SQL02 -Credential (Get-Credential)
```

Review the recommendation before rollout. Full install/upgrade parameters:
[Install and upgrade](install-upgrade-guide.md). From a client, install or upgrade with
`-Profile` or `-AutoProfile`:

```powershell
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 -Computers SQL01 -Profile sql-server.yml -RemoteCredential (Get-Credential)
.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 -Computers SQL01 -Profile sql-server.yml -RemoteCredential (Get-Credential)
```

Without `-Profile` / `-AutoProfile`, upgrade refreshes `profiles/` and `scripts/`
(and ensures `textfile_inputs/`) but leaves the existing `--config.file` unchanged.
Presence of `ClusSvc` selects a cluster profile. To change the profile of an
existing service, update `--config.file` in the ImagePath and restart.

`cpu_info` and `diskdrive` are not enabled in production profiles because of WMI
dependency; canary them under the service account before enabling.

## SSAS and Power BI Report Server

`ssas.yml`, `data-platform.yml`, and `data-platform-cluster.yml` enable the
`textfile` collector on `textfile_inputs`. DMV/AMO, Performance Counter, and
XEvent metrics are written by a separate scheduled task. Install details:
[SSAS monitoring](ssas-monitoring.md). Remote windows_exporter install deploys the
scripts but does **not** create the `prometheus_windows_ssas` service.

SSAS and PBIRS performance object names vary by product version, locale, and
instance. Discover them with `scripts/powershell/windows-exporter/Discover-PerformanceCounters.ps1`,
validate with `Get-Counter`, and adapt `profiles/performancecounter.example.yml`
on a canary. The example file is not deployable by itself; add
`performancecounter` to `collectors.enabled` only after validation. The collector
supports English counter names only.

## Terminal Server

`terminal-server.yml` enables the dedicated `terminal_services` collector with
CPU, memory, pagefile, disk, network, and TCP metrics, plus core RDS services.
Recording rules count active and disconnected user sessions. Default alerts live in
`prometheus/alert-rules/windows-exporter/windows_exporter-role-terminal.rules.yml` and are added through
`prometheus/scrape-configs/windows-exporter/terminal.yml`. The sample threshold for more than 20 disconnected
sessions for 30 minutes must be capacity-tuned. Sessions with `user=""` are excluded.
System sessions with empty `user` are excluded from the counts.

## Microsoft Dynamics

Role dashboard: `grafana/dashboards/winexp-00-d365.json` (UID: `winexp-00-d365`).

AX 2012 monitors `AOS60$<instance>` and `Ax32Serv`. D365 Finance & Operations
on-premises collects Service Fabric host services and `Fabric*` /
`Microsoft.Dynamics.AX.*` processes. `W3SVC`, `WAS`, and `w3wp` are included for
web workloads.

Service Fabric is distinct from Windows Failover Cluster; enabling a D365 profile
does not enable `mscluster`. For AOS, Batch, DMF, Reporting, and replica health,
add Service Fabric/LCS health or a custom textfile collector. Discovery of
`FabricHostSvc` means Service Fabric is present; re-check the recommended profile
if the host runs unrelated Service Fabric workloads.

## Post-rollout checks

```powershell
Get-Service windows_exporter
Invoke-WebRequest http://localhost:9182/health
Invoke-WebRequest http://localhost:9182/metrics
```

In Prometheus verify:

- `up{job=~"windows.*"} == 1`
- `windows_exporter_collector_success == 1`
- `windows_mssql_*` on SQL Server hosts
- `ssas_*` on SSAS hosts after the collector task is installed
- `windows_mscluster_*` only on cluster nodes

Cluster, data-platform, host, MSSQL, and role-pack alerts live under
`prometheus/alert-rules/windows-exporter/` with priority (`p0` / `p1` / `p2`) and role (`role-*`) prefixes.
Ready `rule_files` profiles are in `prometheus/scrape-configs/windows-exporter/`. SSAS alerts are in
`prometheus/alert-rules/windows-exporter/windows_exporter-role-ssas.rules.yml`. Full catalog:
[Alerting](alerting.md). Canary metric names and rule compatibility before a fleet
enablement.
