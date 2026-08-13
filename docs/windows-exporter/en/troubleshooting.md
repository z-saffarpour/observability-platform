# windows_exporter troubleshooting

[فارسی](../fa/troubleshooting.md)

## Service does not start

Inspect the service ImagePath, account, state, and Application event log. Run the exporter interactively with the exact service arguments. A `field ... not found` error means the configuration targets another version. Version 0.31.8 does not accept `telemetry.max-requests`; use `terminal_services` instead of `logon`.

## HTTP 401

Only applies when Basic Auth is enabled in `web-config.yml`. See [Installation and configuration — Basic Auth](install-config-guide.md#basic-auth-optional) for setup steps.

`--web.config.file` is active and `basic_auth_users` is non-empty, but Prometheus credentials do not match. Rotate to a strong password, restart the exporter after editing `web-config.yml`, update the Prometheus `password_file`, and do not commit plaintext credentials.

## Connection refused or timeout

Check `web.listen-address`, service state, firewall scope, and `Test-NetConnection SERVER01 -Port 9182`. Compare scrape timeout with collector duration.

## Collector failure

Query `windows_exporter_collector_success == 0`.

- `mssql`: requires a registered SQL instance and accessible performance counters.
- `service`: filters match service names, not display names.
- `process`: review service-account permissions and process cardinality.
- `textfile`: verify `collector.textfile.directories`, the `textfile_inputs` folder, and that the `prometheus_windows_ssas` service is running.
- `net`: experimental sub-collector warnings may be informational rather than failures.

## SSAS metrics are missing

1. Confirm the profile enables `textfile` (`ssas.yml` or `data-platform*.yml`) and the service was restarted.
2. Confirm `Install-SsasMetricsTask.ps1` installed the `prometheus_windows_ssas` service and that it is running.
3. Confirm `textfile_inputs\ssas*.prom` files are fresh (`ssas_collector_last_run_timestamp_seconds`).
4. Verify ADOMD/AMO libraries and that the task identity can reach the instance.
5. For XEvents: PowerShell `SqlServer` module, `*.xel` path, and the session from `scripts/ssas/windows-exporter/ssas-monitoring-xevents.xmla`.

More detail: [SSAS monitoring](ssas-monitoring.md).

## Metrics changed after upgrade

Review release notes, verify the metric directly in `/metrics`, then update dashboards and rules. Binary and configuration rollback must be performed together. For remote upgrade with automatic rollback, see [Install and upgrade](install-upgrade-guide.md).

## Remote install / upgrade failures

- WinRM: `Test-WSMan`, Administrator credential, and PowerShell Remoting enabled
- Incomplete client package: `windows_exporter.exe`, both YAML files, `profiles/`, and `scripts/powershell/windows-exporter/`
- Upgrade: align `-ExpectedVersion` with binary `--version`; on failure inspect `_backup\upgrade_...`
- Invalid profile or deploying `performancecounter.example.yml` as the service profile is not allowed

Create required access, then audit:

```powershell
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 `
  -ComputerName SERVER01 `
  -Credential (Get-Credential) `
  -PrometheusRemoteAddress 10.10.10.20
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -ComputerName SERVER01 -Credential (Get-Credential) -IncludeSsasChecks
```
