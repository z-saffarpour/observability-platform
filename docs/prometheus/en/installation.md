# Installing Prometheus on Windows and Linux

[فارسی](../fa/installation.md)

## Common prerequisites

- `prometheus/config/prometheus.yml` and all rules must pass `promtool` validation.
- The deployed `web-config.yml` must contain a valid bcrypt hash.
- `sql-exporter-password` and `windows-exporter-password` must exist under
  `secrets` and match the corresponding exporter web configuration.
- Create real target files from the templates; `.template` files are not loaded.

## Windows service installation

Open PowerShell with **Run as Administrator**. For an authenticated installation:

```powershell
.\scripts\powershell\prometheus\Install-Prometheus.ps1 `
  -WebConfigPath C:\Secure\prometheus-web-config.yml `
  -OpenFirewall
```

Alternatively, provide an existing bcrypt hash:

```powershell
.\scripts\powershell\prometheus\Install-Prometheus.ps1 `
  -BasicAuthUsername admin `
  -BasicAuthHash '$2b$12$REPLACE_WITH_VALID_BCRYPT_HASH' `
  -OpenFirewall
```

`-BasicAuthPassword` is also supported, but generating bcrypt this way requires
Python and its `bcrypt` module on the Windows server. `-WebConfigPath` or
`-BasicAuthHash` is more predictable for production installations.

### Windows installer inputs

Complete input declaration, matching the PowerShell script:

```powershell
param(
    [string]$SourceRoot,
    [string]$InstallRoot = 'C:\Program Files\Observability\Prometheus',
    [string]$DataRoot,
    [string]$LogRoot,
    [string]$ServiceName = 'prometheus',
    [string]$ServiceDisplayName = 'Prometheus Monitoring Server',
    [string]$ServiceDescription = 'Prometheus monitoring and time-series database',
    [string]$ListenAddress = '0.0.0.0:9090',
    [string]$WebConfigPath,
    [string]$BasicAuthUsername,
    [SecureString]$BasicAuthPassword,
    [string]$BasicAuthHash,
    [switch]$AllowUnauthenticated,
    [switch]$ForceConfig,
    [switch]$OpenFirewall,
    [ValidateRange(5, 300)][int]$ServiceTimeoutSec = 60
)
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| `-SourceRoot` | `String` | Project root derived from the script location | Path to the checkout containing `prometheus`, `deployment`, and `scripts`. Set it only when running the installer outside its original project layout. |
| `-InstallRoot` | `String` | `C:\Program Files\Observability\Prometheus` | Root of the self-contained installation. Binaries, configuration, rules, targets, secrets, data, and logs are placed below it. A drive root is rejected. |
| `-DataRoot` | `String` | `<InstallRoot>\data` | TSDB location. It may be placed on a separate disk. A drive root is rejected. |
| `-LogRoot` | `String` | `<InstallRoot>\logs` | NSSM stdout and stderr log directory. A drive root is rejected. |
| `-ServiceName` | `String` | `prometheus` | Internal Windows Service name used by `Get-Service` and `sc.exe`. |
| `-ServiceDisplayName` | `String` | `Prometheus Monitoring Server` | Service name displayed in Services MMC. |
| `-ServiceDescription` | `String` | `Prometheus monitoring and time-series database` | Description registered for the service. |
| `-ListenAddress` | `String` | `0.0.0.0:9090` | UI/API bind address. Accepted forms include `IP:port`, `localhost:port`, `*:port`, and `:port`. |
| `-WebConfigPath` | `String` | none | Path to a complete, valid `web-config.yml`. It cannot be combined with `BasicAuth*` parameters or `-AllowUnauthenticated`. |
| `-BasicAuthUsername` | `String` | none | UI/API username. It requires exactly one of `-BasicAuthPassword` or `-BasicAuthHash`. |
| `-BasicAuthPassword` | `SecureString` | none | Secure password input that the installer converts to bcrypt; requires Python and its `bcrypt` module. It cannot be combined with `-BasicAuthHash`. |
| `-BasicAuthHash` | `String` | none | Existing bcrypt hash with a valid prefix such as `$2b$12$`. It cannot be combined with `-BasicAuthPassword`. |
| `-AllowUnauthenticated` | `Switch` | off | Explicitly disables UI/API authentication; intended only for test environments. It conflicts with every authentication parameter. |
| `-ForceConfig` | `Switch` | off | Replaces the installed `prometheus.yml` with the source version during an upgrade. Without it, existing configuration is preserved. |
| `-OpenFirewall` | `Switch` | off | Creates an inbound Domain/Private firewall rule for the port in `ListenAddress`. |
| `-ServiceTimeoutSec` | `Int32` | `60` | Service stop/start timeout. Allowed range: 5–300 seconds. |
| `-WhatIf` | PowerShell common parameter | off | Simulates modifying operations without installing files or changing the service. |
| `-Confirm` | PowerShell common parameter | automatic | Controls confirmation prompts provided through `SupportsShouldProcess`. |
| `-Verbose` | PowerShell common parameter | off | Enables additional PowerShell diagnostic output. |

Because the script uses `CmdletBinding`, standard PowerShell common parameters
such as `-Debug`, `-ErrorAction`, `-WarningAction`, `-InformationAction`, their
associated variable parameters, and `-OutVariable` are also available. They
control standard PowerShell behavior rather than installer-specific logic.

Select at least one authentication mode:

1. `-WebConfigPath`
2. `-BasicAuthUsername` with `-BasicAuthHash` or `-BasicAuthPassword`
3. `-AllowUnauthenticated` for testing only

Example customizing the primary paths:

```powershell
.\scripts\powershell\prometheus\Install-Prometheus.ps1 `
  -InstallRoot 'C:\Program Files\Observability\Prometheus' `
  -DataRoot 'D:\Prometheus\data' `
  -LogRoot 'D:\Prometheus\logs' `
  -ServiceName prometheus `
  -ServiceDisplayName 'Prometheus Monitoring Server' `
  -ListenAddress '0.0.0.0:9090' `
  -WebConfigPath 'C:\Secure\prometheus-web-config.yml' `
  -ServiceTimeoutSec 90 `
  -OpenFirewall
```

Default locations:

| Item | Path |
|---|---|
| Program and configuration | `C:\Program Files\Observability\Prometheus` |
| Binaries | `C:\Program Files\Observability\Prometheus\bin` |
| TSDB data | `C:\Program Files\Observability\Prometheus\data` |
| Service logs | `C:\Program Files\Observability\Prometheus\logs` |
| Service name | `prometheus` |

The Windows installation is self-contained and follows the source layout:

```text
C:\Program Files\Observability\Prometheus\
├── bin\
├── config\
├── alert-rules\
├── recording-rules\
├── targets\
├── secrets\
├── data\
└── logs\
```

The installer uses NSSM and LocalSystem, configures Automatic Delayed Start,
three-stage restart recovery, and 10 MB log rotation. Re-running it upgrades the
binaries and rules. Existing `prometheus.yml` is replaced only with `-ForceConfig`.

Verify the installation:

```powershell
Get-Service prometheus
sc.exe qc prometheus
Get-Content 'C:\Program Files\Observability\Prometheus\logs\prometheus.err.log' -Tail 50
```

For test environments only, unauthenticated installation must be explicit:

```powershell
.\scripts\powershell\prometheus\Install-Prometheus.ps1 -AllowUnauthenticated
```

## Linux systemd installation

Run from the repository root:

```bash
sudo bash scripts/bash/prometheus/install-prometheus.sh
```

### Linux installer inputs

The shell installer accepts no positional arguments or custom flags. It reads
its inputs from these environment variables:

| Variable | Default | Description |
|---|---|---|
| `PROMETHEUS_CONFIG_ROOT` | `/etc/prometheus` | Absolute installed configuration root. The installer creates `config`, `alert-rules`, `recording-rules`, `targets`, and `secrets` below it and renders the unit with the same value. |
| `PROMETHEUS_DATA_ROOT` | `/var/lib/prometheus` | Absolute writable TSDB directory owned by the `prometheus` service user; the value is also applied to the installed unit. |

Fixed inputs and behavior:

- The repository root is derived from the installer location and has no separate input.
- Binaries are installed as `/usr/local/bin/prometheus` and `/usr/local/bin/promtool`.
- The unit is installed as `/etc/systemd/system/prometheus.service`.
- Run the installer as `root` or through `sudo`.
- The installer runs `systemctl daemon-reload` but does not automatically start or enable the service.

Example with custom paths:

```bash
sudo env \
  PROMETHEUS_CONFIG_ROOT=/opt/prometheus/configuration \
  PROMETHEUS_DATA_ROOT=/data/prometheus \
  bash scripts/bash/prometheus/install-prometheus.sh
```

Create or complete these files before starting the service:

```text
/etc/prometheus/config/web-config.yml
/etc/prometheus/secrets/sql-exporter-password
/etc/prometheus/secrets/windows-exporter-password
/etc/prometheus/targets/*/*.json
```

Validate the configuration and enable the service:

```bash
sudo promtool check web-config /etc/prometheus/config/web-config.yml
sudo promtool check config /etc/prometheus/config/prometheus.yml
sudo systemctl enable --now prometheus
sudo systemctl status prometheus
journalctl -u prometheus -n 100 --no-pager
```

The Linux unit runs as the restricted `prometheus` user and grants write access
only to `/var/lib/prometheus`.
