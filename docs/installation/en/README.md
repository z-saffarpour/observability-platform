# Platform installation and startup guide

[فارسی](../fa/README.md)

Use this guide to select the correct installation path for the central
Observability server. Run all commands from the repository root.

## Choose an installation path

| Role | Windows | Linux |
|---|---|---|
| Central Prometheus | PowerShell + NSSM | Bash + systemd |
| Central Alertmanager | PowerShell + NSSM | Manual offline install + systemd |
| Central Grafana | PowerShell + NSSM | Bash + systemd |
| Nginx reverse proxy | PowerShell + NSSM | Bash + systemd |
| Windows Exporter on a target | Supported | Not applicable |
| SQL Exporter for Microsoft SQL Server | Remote PowerShell deployment to Windows | No Linux installer in this repository |

For production, the recommended topology is to run the central services on a
Linux server and deploy exporters to the target Windows and SQL Server hosts.
An all-Windows deployment using NSSM is also supported.

## Common prerequisites

- The central host uses the `x86-64/AMD64` architecture.
- Git LFS artifacts have been downloaded with `git lfs pull`.
- Default ports are available: Prometheus `9090`, Alertmanager `9093`, Grafana
  `3000`, and Nginx `80` or `443`.
- DNS, firewall rules, and network access from Prometheus to each exporter are ready.
- Real passwords and bcrypt hashes are stored outside Git.
- Real target files have been created from the templates; Prometheus does not
  load `.template` files.

Recommended startup order:

1. Prepare Prometheus targets, secrets, and configuration.
2. Install and validate Prometheus.
3. Install Alertmanager and connect Prometheus to it.
4. Install Grafana and connect its Prometheus datasource.
5. Install Nginx and bind internal services to loopback.
6. Deploy exporters to target hosts.
7. Verify targets, alerts, and dashboards.

## Windows path

Open PowerShell 5.1 or later with **Run as Administrator**. NSSM must exist at
`deployment/windows/tools/nssm/nssm.exe`.

Install Prometheus with a production web configuration:

```powershell
.\scripts\powershell\prometheus\Install-Prometheus.ps1 `
  -WebConfigPath 'C:\Secure\prometheus-web-config.yml' `
  -OpenFirewall
```

Complete the targets and secrets under
`C:\Program Files\Observability\Prometheus`, then verify the service:

```powershell
Get-Service prometheus
# Enter the credential configured in web-config when Basic Auth is enabled.
Invoke-WebRequest http://localhost:9090/-/healthy -Credential (Get-Credential)
```

See the [Prometheus installation guide](../../prometheus/en/installation.md) for
authentication, custom paths, and upgrades.

### Install Alertmanager on Windows

Install Alertmanager after replacing every `CHANGE_ME_*` SMTP, email, and SMS
gateway value in the selected configuration. The SQL and Windows configurations
are separate examples; merge their routes, receivers, and templates into one
production configuration when monitoring both exporters.

```powershell
.\alertmanager\bin\windows-amd64\amtool.exe check-config `
  .\alertmanager\sql-exporter\alertmanager.yml

.\scripts\powershell\alertmanager\Install-Alertmanager.ps1 `
  -ConfigPath .\alertmanager\sql-exporter\alertmanager.yml `
  -ListenAddress '127.0.0.1:9093'

Get-Service prometheus_alert_manager
Invoke-RestMethod http://127.0.0.1:9093/-/ready
```

Prometheus already targets `127.0.0.1:9093` by default. Update
`alerting.alertmanagers` when Alertmanager runs on another host, then validate
and restart Prometheus. Use `0.0.0.0:9093` only when remote access is required,
and restrict its firewall rule to the Prometheus host.

Install Grafana:

```powershell
$adminPassword = Read-Host 'Grafana admin password' -AsSecureString
$prometheusPassword = Read-Host 'Prometheus password' -AsSecureString

.\scripts\powershell\grafana\Install-Grafana.ps1 `
  -AdminPassword $adminPassword `
  -PrometheusUrl 'http://localhost:9090' `
  -PrometheusUsername admin `
  -PrometheusPassword $prometheusPassword `
  -OpenFirewall

Get-Service grafana
Invoke-RestMethod http://localhost:3000/api/health
```

Omit the Prometheus username and password parameters when Basic Auth is not
enabled. See the [Grafana installation guide](../../grafana/en/installation.md).

Install the optional but recommended reverse proxy after configuring the public
Grafana and Prometheus URLs:

```powershell
.\scripts\powershell\nginx\Install-Nginx.ps1 `
  -DependencyServiceNames prometheus,grafana `
  -OpenFirewall

Get-Service nginx
Invoke-WebRequest http://localhost/healthz
```

After the proxy works, do not expose ports `3000` and `9090` publicly. See the
[Nginx installation guide](../../nginx/en/installation.md) for subpaths, TLS,
and reload behavior.

Deploy exporters to target hosts using the [SQL Exporter guide](../../sql-exporter/en/README.md)
and [Windows Exporter guide](../../windows-exporter/en/README.md). Remote
deployment requires WinRM, administrator access, and an appropriately privileged
service account. Test one target before a group rollout.

## Linux path

This path targets distributions with `systemd`. Nginx installation also requires
`apt-get`, `dnf`, or `yum`. Use an account with `sudo` access.

Install and start Prometheus:

```bash
sudo bash scripts/bash/prometheus/install-prometheus.sh

# Complete /etc/prometheus/config/web-config.yml, secrets, and target JSON files.
sudo promtool check web-config /etc/prometheus/config/web-config.yml
sudo promtool check config /etc/prometheus/config/prometheus.yml
sudo systemctl enable --now prometheus
sudo systemctl status prometheus --no-pager
curl -fsS -u admin http://127.0.0.1:9090/-/healthy
```

See the [Prometheus installation guide](../../prometheus/en/installation.md) for
custom configuration and TSDB paths.

### Install Alertmanager on Linux

Install the bundled Alertmanager binaries and your finalized configuration on
Linux. Replace all `CHANGE_ME_*` values before starting it:

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin alertmanager 2>/dev/null || true
sudo install -m 0755 alertmanager/bin/linux-amd64/alertmanager /usr/local/bin/alertmanager
sudo install -m 0755 alertmanager/bin/linux-amd64/amtool /usr/local/bin/amtool
sudo install -d -o alertmanager -g alertmanager -m 0750 /etc/alertmanager/templates
sudo install -d -o alertmanager -g alertmanager -m 0750 /var/lib/alertmanager
sudo install -m 0640 -o root -g alertmanager alertmanager/sql-exporter/alertmanager.yml /etc/alertmanager/alertmanager.yml
sudo install -m 0640 -o root -g alertmanager alertmanager/sql-exporter/templates/*.tmpl /etc/alertmanager/templates/
cd /etc/alertmanager
sudo amtool check-config alertmanager.yml
```

Create `/etc/systemd/system/alertmanager.service` with the following unit:

```ini
[Unit]
Description=Prometheus Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=alertmanager
Group=alertmanager
ExecStart=/usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/var/lib/alertmanager --web.listen-address=127.0.0.1:9093
Restart=on-failure
RestartSec=5s
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/var/lib/alertmanager

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now alertmanager
curl -fsS http://127.0.0.1:9093/-/ready
amtool --alertmanager.url=http://127.0.0.1:9093 alert query
sudo promtool check config /etc/prometheus/config/prometheus.yml
sudo systemctl reload prometheus
```

Create an admin-password file outside the repository and install Grafana:

```bash
sudo install -d -m 700 /root/secrets
read -rsp 'Grafana admin password: ' GRAFANA_ADMIN_PASSWORD; echo
printf '%s' "$GRAFANA_ADMIN_PASSWORD" | sudo tee /root/secrets/grafana-admin-password >/dev/null
sudo chmod 600 /root/secrets/grafana-admin-password
unset GRAFANA_ADMIN_PASSWORD

sudo \
  GRAFANA_ADMIN_PASSWORD_FILE=/root/secrets/grafana-admin-password \
  GRAFANA_PROMETHEUS_URL=http://127.0.0.1:9090 \
  GRAFANA_PROMETHEUS_USER=admin \
  GRAFANA_PROMETHEUS_PASSWORD_FILE=/root/secrets/prometheus-password \
  bash scripts/bash/grafana/install-grafana.sh

sudo systemctl enable --now grafana
sudo systemctl status grafana --no-pager
curl -fsS http://127.0.0.1:3000/api/health
```

Omit the Prometheus user/password variables if Basic Auth is disabled. See the
[Grafana installation guide](../../grafana/en/installation.md).

Install Nginx:

```bash
sudo env NGINX_OPEN_FIREWALL=1 \
  bash scripts/bash/nginx/install-nginx.sh

sudo nginx -t
sudo systemctl status nginx --no-pager
curl -fsS http://127.0.0.1/healthz
```

Configure TLS for production and expose Prometheus/Grafana only through loopback.
See the [Nginx installation guide](../../nginx/en/installation.md).

The central host may run Linux, but this repository's exporters monitor Windows
and Microsoft SQL Server targets on Windows. Run their PowerShell deployment
scripts from a Windows management station and register the resulting endpoints
in the Linux Prometheus target files.

## Final verification

- Prometheus `/targets` reports all expected endpoints as `UP`.
- Prometheus `/alertmanagers` reports Alertmanager as `UP`.
- `amtool alert query` succeeds and a controlled test alert reaches its receiver.
- Grafana reports that the Prometheus datasource is working.
- Provisioned dashboards open without datasource errors.
- `http://<host>/healthz` succeeds through Nginx.
- Ports `3000` and `9090` are not publicly exposed unless explicitly intended.
- Prometheus, Alertmanager, Grafana, and Nginx survive a restart and their logs contain no startup errors.
- No real secret, password, or sensitive target file is committed to Git.

For failures, first validate Prometheus with `promtool`, inspect Windows service
logs, or run `journalctl -u <service> -n 100 --no-pager` on Linux. An Nginx `502`
usually means the corresponding Grafana or Prometheus backend is unavailable or
configured at the wrong address.
