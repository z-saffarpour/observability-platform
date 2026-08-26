# Installing Grafana as a Windows service

[فارسی](../fa/installation.md)

## Prerequisites

- PowerShell 5.1 or newer, opened with **Run as Administrator**
- NSSM at `deployment/windows/tools/nssm/nssm.exe`
- The shared Grafana runtime under `grafana/runtime` and Windows AMD64 binary under `grafana/bin/windows-amd64`
- Network access from Grafana to Prometheus

The offline runtime is bundled with platform executables under `grafana/bin/<platform>` and shared assets such as `public` and `conf` under `grafana/runtime`.

## Install

Run from the repository root:

```powershell
$adminPassword = Read-Host 'Grafana admin password' -AsSecureString
.\scripts\powershell\grafana\Install-Grafana.ps1 `
  -AdminPassword $adminPassword `
  -PrometheusUrl 'http://localhost:9090' `
  -OpenFirewall
```

For a Prometheus server protected with Basic Auth:

```powershell
$adminPassword = Read-Host 'Grafana admin password' -AsSecureString
$prometheusPassword = Read-Host 'Prometheus password' -AsSecureString
.\scripts\powershell\grafana\Install-Grafana.ps1 `
  -AdminPassword $adminPassword `
  -PrometheusUsername admin `
  -PrometheusPassword $prometheusPassword
```

Use `-AllowDefaultAdminPassword` only for an isolated test environment. It keeps the initial `admin` password, which must be changed on first login.

## Key parameters

| Parameter | Default | Purpose |
|---|---|---|
| `-RuntimeArchivePath` | categorized repository runtime | Optional official ZIP or `tar.gz` for a later upgrade |
| `-InstallRoot` | `C:\Program Files\Observability\Grafana` | Self-contained installation root |
| `-DataRoot` | `<InstallRoot>\data` | Persistent Grafana database and data |
| `-LogRoot` | `<InstallRoot>\logs` | Rotating NSSM output logs |
| `-HttpAddress` / `-HttpPort` | `0.0.0.0` / `3000` | HTTP bind address and port |
| `-Domain` | `localhost` | Domain used to derive the public URL |
| `-RootUrl` | `http://<Domain>:<Port>/` | Public URL; set the real URL behind a reverse proxy. |
| `-AdminPassword` | required | Initial administrator password as `SecureString` |
| `-PrometheusUrl` | `http://localhost:9090` | Provisioned datasource URL |
| `-ForceConfig` | off | Replace the installed `grafana.ini` during upgrade. |
| `-OpenFirewall` | off | Open the HTTP port for Domain and Private profiles only. |

Re-running the installer upgrades the runtime and dashboards. It preserves the main configuration unless `-ForceConfig` is supplied, while datasource and dashboard provisioning are always synchronized. The LocalSystem service uses Automatic Delayed Start, three-stage recovery, and 10 MB log rotation.

## Verify

```powershell
Get-Service grafana
sc.exe qc grafana
Invoke-RestMethod http://localhost:3000/api/health
Get-Content 'C:\Program Files\Observability\Grafana\logs\grafana.err.log' -Tail 50
```

The admin password is stored in an ACL-protected secret file. When Prometheus Basic Auth is configured, the generated datasource file is also restricted to LocalSystem and Administrators.

## Offline Linux installation with systemd

The Linux AMD64 binary is bundled under `grafana/bin/linux-amd64`, with shared assets under `grafana/runtime`; no internet access or package repository is needed. Run from the repository root:

```bash
sudo GRAFANA_ADMIN_PASSWORD_FILE=/root/secrets/grafana-admin-password \
  bash scripts/bash/grafana/install-grafana.sh
```

The installer creates the restricted `grafana` system user, deploys the runtime to `/usr/local/lib/grafana`, and provisions configuration and dashboards under `/etc/grafana`. Writable data/plugins use `/var/lib/grafana`, while logs use `/var/log/grafana`. It does not automatically start or enable the service.

### Linux environment variables

| Variable | Default | Purpose |
|---|---|---|
| `GRAFANA_CONFIG_ROOT` | `/etc/grafana` | Configuration, provisioning, dashboards, and secrets |
| `GRAFANA_DATA_ROOT` | `/var/lib/grafana` | Database, sessions, and installed plugins |
| `GRAFANA_LOG_ROOT` | `/var/log/grafana` | Writable service log path |
| `GRAFANA_RUNTIME_ROOT` | `/usr/local/lib/grafana` | Read-only Grafana runtime |
| `GRAFANA_HTTP_ADDR` | `0.0.0.0` | Bind address |
| `GRAFANA_HTTP_PORT` | `3000` | HTTP port |
| `GRAFANA_DOMAIN` | `localhost` | Public domain |
| `GRAFANA_ROOT_URL` | derived from domain and port | Full public URL, especially behind a reverse proxy |
| `GRAFANA_ADMIN_USER` | `admin` | Initial administrator name |
| `GRAFANA_ADMIN_PASSWORD_FILE` | empty | Administrator password file; provide it for production. |
| `GRAFANA_PROMETHEUS_URL` | `http://localhost:9090` | Prometheus datasource URL |
| `GRAFANA_PROMETHEUS_USER` | empty | Prometheus Basic Auth username |
| `GRAFANA_PROMETHEUS_PASSWORD_FILE` | empty | Basic Auth password file; required with the username. |

For Prometheus Basic Auth:

```bash
sudo \
  GRAFANA_ADMIN_PASSWORD_FILE=/root/secrets/grafana-admin-password \
  GRAFANA_PROMETHEUS_URL=http://127.0.0.1:9090 \
  GRAFANA_PROMETHEUS_USER=admin \
  GRAFANA_PROMETHEUS_PASSWORD_FILE=/root/secrets/prometheus-password \
  bash scripts/bash/grafana/install-grafana.sh
```

Enable and verify the service afterward:

```bash
sudo systemctl enable --now grafana
sudo systemctl status grafana
sudo journalctl -u grafana -n 100 --no-pager
curl -fsS http://localhost:3000/api/health
```

The unit is hardened with `NoNewPrivileges`, `ProtectSystem=strict`, `ProtectHome`, restricted writable paths, and automatic restart.
