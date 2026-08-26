# Alertmanager

Runtime binaries for Alertmanager `0.33.1` are included for:

- Windows x86-64: `bin/windows-amd64/alertmanager.exe` and `amtool.exe`
- Linux x86-64: `bin/linux-amd64/alertmanager` and `amtool`

To install the Windows binary as an automatic service, run an elevated
PowerShell session from the repository root:

```powershell
.\scripts\powershell\alertmanager\Install-Alertmanager.ps1 `
  -ConfigPath .\alertmanager\windows-exporter\alertmanager.yml `
  -OpenFirewall
```

The default service name is `prometheus_alert_manager` and its display name is
`Prometheus Alert Manager`. Replace every `CHANGE_ME_*` value in the selected
configuration before installation. The installer copies the adjacent
`templates` directory, validates the deployed configuration with `amtool`,
configures restart recovery and rotating logs, and starts the service on port
`9093`.
