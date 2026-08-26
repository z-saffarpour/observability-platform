# Install Nginx on Windows with NSSM

[فارسی](../fa/installation.md)

This deployment runs Nginx as the reverse proxy for Grafana and Prometheus:

- `/grafana/` proxies to `127.0.0.1:3000`
- `/prometheus/` proxies to `127.0.0.1:9090`
- `/healthz` checks Nginx itself

The repository includes the official nginx/Windows 1.31.4 mainline binary, licenses, source URL, and SHA-256 metadata under `nginx/bin/windows-amd64/`. The Windows build has known scalability limitations; use Linux for high-load production deployments.

Configure Grafana with `http_addr = 127.0.0.1`, a `root_url` ending in `/grafana/`, and `serve_from_sub_path = true`. Start Prometheus with:

```text
--web.listen-address=127.0.0.1:9090
--web.external-url=http://monitoring.example.local/prometheus/
--web.route-prefix=/prometheus/
```

Run an elevated PowerShell from the repository root:

```powershell
.\scripts\powershell\nginx\Install-Nginx.ps1 `
  -DependencyServiceNames prometheus,Grafana `
  -OpenFirewall
```

The default installation root is `C:\Program Files\Observability\Nginx`. Re-running the installer upgrades the runtime while preserving deployed configuration. Pass `-ForceConfig` to redeploy repository configuration. `-WhatIf` performs a dry run.

Validate and inspect the service:

```powershell
& 'C:\Program Files\Observability\Nginx\bin\nginx.exe' `
  -t -p 'C:\Program Files\Observability\Nginx\' -c config/nginx.conf
Get-Service nginx
Invoke-WebRequest http://localhost/healthz
```

Confirm the actual Grafana service name before supplying dependencies. Add HTTPS and access control before exposing the proxy outside trusted networks.

## Linux installation with systemd

The Linux installer supports systems with `apt-get`, `dnf`, or `yum`. It installs Nginx from the configured OS repositories when needed, deploys the project configuration, validates it, and enables the systemd service:

```bash
sudo bash scripts/bash/nginx/install-nginx.sh
```

Optional environment variables are `NGINX_SOURCE_ROOT`, `NGINX_LISTEN_PORT` (default `80`), and `NGINX_OPEN_FIREWALL=1`. For example:

```bash
sudo env NGINX_LISTEN_PORT=8080 NGINX_OPEN_FIREWALL=1 \
  bash scripts/bash/nginx/install-nginx.sh
```

The configuration is deployed to `/etc/nginx/conf.d/observability.conf`. The repository unit at `deployment/systemd/nginx.service` is installed as `/etc/systemd/system/nginx.service`, followed by `systemctl daemon-reload`. Existing configuration and unit files are backed up under `/var/backups/observability-nginx/<UTC timestamp>/`. If validation fails, the installer restores the previous files.

Verify the deployment:

```bash
sudo nginx -t
sudo systemctl status nginx --no-pager
sudo systemctl cat nginx
curl -fsS http://127.0.0.1/healthz
```

Grafana and Prometheus still require the loopback and subpath settings described above. Nginx returns `502` while a backend is unavailable and recovers without a proxy restart when that backend starts.
