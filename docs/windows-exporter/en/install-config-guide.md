# windows_exporter installation and configuration

[فارسی](../fa/install-config-guide.md)

This guide targets **0.31.8** and the upstream default port **9182**. Basic Auth is disabled by default.

For remote WinRM install and upgrade, see [Install and upgrade](install-upgrade-guide.md) ([HTML](install-upgrade-guide.html)).

## Prerequisites

- Windows Server 2016 or later
- Administrator access for service and firewall setup
- Prometheus network access to TCP/9182
- A service account with the minimum access required by enabled collectors

Required-access matrix, create ACLs/firewall, then audit:

```powershell
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -ShowRequirements
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -PrometheusRemoteAddress '<PROMETHEUS_IP>'
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1
```

## Required files

For a manual install, keep at least these files in a stable directory such as:

```text
C:\Program Files\Observability\PrometheusExporters\windows-exporter
```

- `windows_exporter.exe`
- `windows_exporter.yml` (or a role file from `profiles/`)
- `web-config.yml`

Remote and role-based installs also require `profiles/` and `scripts/powershell/windows-exporter/` (plus `scripts/ssas/windows-exporter/` when using SSAS collectors). Details: [Install and upgrade](install-upgrade-guide.md).

## Pre-install validation

```powershell
.\windows_exporter.exe --version
.\windows_exporter.exe `
  --config.file=.\windows_exporter.yml `
  --web.listen-address=127.0.0.1:49176 `
  --log.file=stderr
```

Check `http://127.0.0.1:49176/metrics`, then stop the test process. Version 0.31.8 rejects unknown YAML keys at startup.

## Install the service

Run elevated PowerShell and replace the paths as needed:

```powershell
$exe = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter\windows_exporter.exe'
$config = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter\windows_exporter.yml'
$webConfig = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter\web-config.yml'
$binPath = ('"{0}" --config.file="{1}" --web.config.file="{2}"' -f $exe,$config,$webConfig)

New-Service -Name windows_exporter -BinaryPathName $binPath -DisplayName 'Prometheus Windows Exporter' -StartupType Automatic
sc.exe failure windows_exporter reset= 86400 actions= restart/5000/restart/15000/restart/60000
Start-Service windows_exporter
```

For an existing service, correct ImagePath with `sc.exe config`. For fleet upgrades prefer the remote script with backup and rollback: [Install and upgrade](install-upgrade-guide.md). Manual upgrade is only recommended for a single canary host; stop the service and keep a rollback copy before replacing files.

## Firewall

Prefer the access script so the inbound rule is limited to Prometheus hosts:

```powershell
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -PrometheusRemoteAddress '<PROMETHEUS_IP>'
```

Manual equivalent:

```powershell
New-NetFirewallRule -DisplayName 'Prometheus windows_exporter 9182' `
  -Direction Inbound -Protocol TCP -LocalPort 9182 `
  -RemoteAddress '<PROMETHEUS_IP>' -Action Allow
```

## Basic Auth (optional)

The package ships with `basic_auth_users: {}`, so `/metrics` responds without credentials. Enable Basic Auth when you want to restrict scrape access.

> Having `web-config.yml` on disk is not enough. The service ImagePath must include `--web.config.file=...` (remote install scripts set this).

### 1) Generate a bcrypt hash

Never commit plaintext passwords. Store only the hash in `web-config.yml`.

With `htpasswd`:

```bash
htpasswd -nBC 12 '' | tr -d ':\n'
```

With Python:

```powershell
python -c "import bcrypt; print(bcrypt.hashpw(b'YOUR_STRONG_PASSWORD', bcrypt.gensalt(rounds=12)).decode())"
```

Or use a trusted bcrypt generator (for example [bcrypt-generator.com](https://bcrypt-generator.com/)) with cost **12** or higher and copy the hash.

Example output:

```text
$2a$12$abcdefghijklmnopqrstuvABCDEFGHIJKLMNOPQRSTUVWXYZ012345
```

### 2) Edit `web-config.yml`

```yaml
basic_auth_users:
  scrape_user: $2a$12$abcdefghijklmnopqrstuvABCDEFGHIJKLMNOPQRSTUVWXYZ012345
```

Multiple users are allowed (`username: <bcrypt-hash>` per line). To disable again:

```yaml
basic_auth_users: {}
```

Tighten file ACLs:

```powershell
icacls 'C:\Program Files\Observability\PrometheusExporters\windows-exporter\web-config.yml' `
  /inheritance:r `
  /grant:r 'SYSTEM:(R)' 'Administrators:(F)'
```

If the service account is not `LocalSystem`, grant that account `(R)` as well.

### 3) Restart and verify

```powershell
Restart-Service windows_exporter
# Without credentials expect HTTP 401
try { Invoke-WebRequest http://localhost:9182/metrics -UseBasicParsing } catch { $_.Exception.Response.StatusCode }

$cred = Get-Credential   # same username / plaintext password
Invoke-WebRequest http://localhost:9182/metrics -Credential $cred -UseBasicParsing
```

### 4) Configure Prometheus

Prefer `password_file` (or a secret manager) over inline passwords:

```yaml
scrape_configs:
  - job_name: windows
    scrape_interval: 30s
    scrape_timeout: 25s
    metrics_path: /metrics
    basic_auth:
      username: scrape_user
      password_file: /etc/prometheus/secrets/windows_exporter_password
    static_configs:
      - targets: ['SERVER01:9182']
```

After reload, check `up{job="windows"}`. A common failure mode is mismatched credentials → HTTP 401 on the target.

### Security notes

- Basic Auth without TLS only blocks anonymous scrapes; traffic can still be sniffed. On untrusted networks enable TLS or mTLS in `web-config.yml`.
- Do not commit passwords or environment-specific hashes.
- Rotation: create a new hash → update `web-config.yml` → restart the service → update the Prometheus `password_file`.

## Prometheus example without Basic Auth

```yaml
scrape_configs:
  - job_name: windows
    scrape_interval: 30s
    scrape_timeout: 25s
    metrics_path: /metrics
    static_configs:
      - targets: ['SERVER01:9182']
```

## Post-install checks

```powershell
Get-Service windows_exporter
Get-CimInstance Win32_Service -Filter "Name='windows_exporter'" | Select-Object Name,State,StartName,PathName
Test-NetConnection localhost -Port 9182
Invoke-WebRequest http://localhost:9182/metrics -UseBasicParsing
```

Verify Prometheus `up` and per-collector success after installation.
