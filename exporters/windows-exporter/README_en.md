# windows_exporter — Windows Server monitoring

[فارسی](README.md) | [Full documentation](../../docs/windows-exporter/README.md)

Standard **windows_exporter 0.31.8** package for OS, disk, network, service, process, Terminal Services, SQL Server, and related Data Platform role metrics.

Default scrape port: **`9182`** — path: **`/metrics`** (Basic Auth disabled by default)

## Package contents

| Path | Purpose |
|---|---|
| `windows_exporter.exe` | Version 0.31.8 binary |
| `windows_exporter.yml` | Collectors, logging, telemetry, and listener settings |
| `web-config.yml` | Basic authentication and optional TLS settings |
| `prometheus/alert-rules/windows-exporter/` | Recording and alerting rules (P0/P1/P2 and role packs) |
| `prometheus/scrape-configs/windows-exporter/` | Ready `rule_files` profiles by priority and role |
| `alertmanager/windows-exporter/` | Priority routing for SMS and Email |
| `profiles/` | Role profiles for Windows, SQL, SSAS, PBIRS, Dynamics, Terminal Server, and Cluster |
| `scripts/` | Role discovery, remote install/upgrade, required-access helpers, `prometheus_windows_ssas` service and SSAS collectors, dashboard sync |
| `collector/` | Runtime collector configuration; `ssas-collector.json` is created here by the SSAS task installer |
| `textfile_inputs/` | Custom collector `.prom` output (created on the target during install/upgrade) |
| `../../docs/windows-exporter/fa/`, `../../docs/windows-exporter/en/` | Persian and English documentation |

## Test run

```powershell
.\windows_exporter.exe `
  --config.file=.\windows_exporter.yml `
  --web.config.file=.\web-config.yml
```

`web-config.yml` is not loaded automatically. The service ImagePath must contain `--web.config.file`.
Full guide to create bcrypt hashes, enable Basic Auth, and wire Prometheus: [`../../docs/windows-exporter/en/install-config-guide.md`](../../docs/windows-exporter/en/install-config-guide.md#basic-auth-optional).

## Choosing a profile

On the target host:

```powershell
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1
.\windows_exporter.exe --config.file=.\profiles\sql-server.yml --web.config.file=.\web-config.yml
```

From a client over WinRM (do not start the exporter on the client):

```powershell
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1 -ComputerName SQL01,SQL02 -Credential (Get-Credential)

.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01,SQL02 `
  -Profile sql-server.yml `
  -RemoteCredential (Get-Credential)
```

Use `data-platform.yml` for multi-role hosts and `data-platform-cluster.yml` for Windows Cluster nodes. Details: [`../../docs/windows-exporter/en/profiles.md`](../../docs/windows-exporter/en/profiles.md).

## Health check

```powershell
Invoke-WebRequest http://localhost:9182/metrics
```

If Basic Auth is enabled:

```powershell
$cred = Get-Credential
Invoke-WebRequest http://localhost:9182/metrics -Credential $cred
```

Monitor Prometheus `up`, `windows_exporter_collector_success`, and `windows_exporter_collector_duration_seconds`.

## Version 0.31.8 notes

- Startup rejects unknown configuration keys.
- `telemetry.max-requests` is no longer valid.
- The old `logon` collector is replaced by `terminal_services`.
- Canary the upgrade and verify dashboards and rules before a fleet rollout.

## Remote install and upgrade

Full parameters, profile options, and rollout checklist:
[`../../docs/windows-exporter/en/install-upgrade-guide.md`](../../docs/windows-exporter/en/install-upgrade-guide.md)
([HTML](../../docs/windows-exporter/en/install-upgrade-guide.html)).

```powershell
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 `
  -WhatIf

.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SERVER01 `
  -ListenAddress ':9182' `
  -BasicAuthUsername 'scrape_user' `
  -BasicAuthHash '$2a$12$REPLACE_WITH_BCRYPT_HASH' `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers SERVER01 `
  -ListenAddress ':9182' `
  -PreserveWebConfig `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Uninstall-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 `
  -WhatIf
```

Both scripts use WinRM and require Administrator access. Install is idempotent; they deploy `profiles/` and `scripts/`, create `collector/` and `textfile_inputs/`, detect Native/NSSM, back up, and roll back on failure. The SSAS collector is installed separately as the `prometheus_windows_ssas` Windows service with `Install-SsasMetricsTask.ps1`; its configuration is stored at `collector/ssas-collector.json`. Do not start `windows_exporter.exe` on the client.

The SSAS service supports two hosting modes. `ServiceBase` is dependency-free and is the default; `NSSM` uses the binary deployed from `deployment/windows/tools/nssm/nssm.exe`:

```powershell
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 -ServiceMode ServiceBase
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 -ServiceMode NSSM
```

The installer registers `prometheus_windows_ssas` as an Application event source. Collector lifecycle and error events therefore appear with the service name in Event Viewer. NSSM's own wrapper-internal events use its compiled-in `nssm` source; select the default `ServiceBase` mode if Application must contain no NSSM-originated entries.

For remote SSAS lifecycle operations use `Install-SsasMetricsRemote.ps1` and `Uninstall-SsasMetricsRemote.ps1`. The latter preserves shared windows_exporter files by default; pass `-RemoveFiles` to remove only SSAS-specific runtime files after backup. Full examples are in the [SSAS monitoring guide](../../docs/windows-exporter/en/ssas-monitoring.md#remote-service-lifecycle).

## Required access

```powershell
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -ShowRequirements
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1
```

`Set-WindowsExporterRequiredAccess.ps1` creates ACLs, a scoped firewall rule, and optional Log on as a service / Performance Monitor Users rights. `Test-WindowsExporterRequiredAccess.ps1` audits the result. Details: [`../../docs/windows-exporter/en/install-upgrade-guide.md`](../../docs/windows-exporter/en/install-upgrade-guide.md).

## Guides

- [Install, upgrade, and uninstall](../../docs/windows-exporter/en/install-upgrade-guide.md) ([HTML](../../docs/windows-exporter/en/install-upgrade-guide.html))
- [Installation and configuration](../../docs/windows-exporter/en/install-config-guide.md) ([Basic Auth](../../docs/windows-exporter/en/install-config-guide.md#basic-auth-optional))
- [Collector guide](../../docs/windows-exporter/en/collector-guide.md)
- [Role-based profiles](../../docs/windows-exporter/en/profiles.md)
- [SSAS monitoring](../../docs/windows-exporter/en/ssas-monitoring.md)
- [Prometheus rules](../../docs/windows-exporter/en/prometheus-rules.md)
- [prometheus/ folder](../../docs/windows-exporter/en/prometheus.md)
- [Alert catalog](../../docs/windows-exporter/en/alerting.md)
- [Alertmanager](../../docs/windows-exporter/en/alertmanager.md)
- [Troubleshooting](../../docs/windows-exporter/en/troubleshooting.md)
