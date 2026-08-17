# `sql_exporter` install and configuration guide

This document covers the initial installation and reconfiguration of `sql_exporter` on SQL Server hosts.

The documented and validated exporter version is **0.24.4**.

For remote install, version upgrade, backup, and rollback, see: [Install and upgrade guide](install-upgrade-guide.md)

## Prerequisites

- Access to the `sql_exporter` package files
- Access to the target SQL Server
- An account that can grant or hold `VIEW SERVER STATE` and `VIEW ANY DEFINITION`
- An open scrape port for Prometheus (upstream default: **9399**)

## Important files

- `sql_exporter.exe`
- `sql_exporter.yml`
- `collector/*.collector.yml`
- `profiles/*.yml`
- `web-config.yml` — not for listen port; used for TLS and **Basic Auth**

## Installation steps

### 1) Copy the files to the server

Place all files from the `sql_exporter` folder into the final location.

### 2) Configure the SQL connection

Set `data_source_name` in `sql_exporter.yml`:

```yaml
data_source_name: 'sqlserver://HOST:PORT?trusted+connection=yes&app+name=sql_exporter'
```

Notes:
- `HOST` and `PORT` must match the real SQL Server endpoint.
- If the instance is named, use the correct port.

### 3) Select collectors

There are two modes:

#### Simple mode

```yaml
collectors: [mssql_*]
```

This loads and runs all collectors present in `collector/`.

#### Profile mode

For busy servers, enable only the collectors you need.

Recommended: apply a ready list from `profiles/` with the same `-Profile` parameter style as Windows Exporter:

```powershell
.\scripts\powershell\sql-exporter\Deploy-SqlExporterConfig.ps1 -Computers SQL01 -Profile oltp.yml
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 -Computers SQL01 -Profile oltp.yml
```

See [Collector Profiles](profiles.md) for the full list (`oltp.yml`, `dwh.yml`, …).

Example OLTP profile (manual copy into `sql_exporter.yml`):

```yaml
collectors:
  - mssql_standard
  - mssql_backup
  - mssql_alwayson
  - mssql_alwayson_events
  - mssql_waits
  - mssql_memory
  - mssql_tempdb
  - mssql_file_io
```

### 4) Grant access

#### Windows / network (same pattern as windows_exporter)

```powershell
.\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1 -ShowRequirements
.\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 -PrometheusRemoteAddress '<PROMETHEUS_IP>'
.\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1
```

Role matrix and details: [Required access](install-upgrade-guide.md#required-access).

#### SQL Server

Base permissions:

```sql
GRANT VIEW SERVER STATE TO [DOMAIN\SqlExporterAccount];
GRANT VIEW ANY DEFINITION TO [DOMAIN\SqlExporterAccount];
```

Recommended (full least-privilege for enabled collectors): run as sysadmin in SSMS after setting `@LoginName`:

```text
scripts/sql/Create-SqlExporterLogin.sql
```

For a Windows account: `@CreateSqlLogin = 0` and `@LoginName = N'DOMAIN\SqlExporterAccount'`.

Some collectors need extra access:

- `mssql_backup`, `mssql_restore`, `mssql_job_*` → `msdb` (`@GrantMsdbRead`)
- `mssql_ssis` → `SSISDB` (`@GrantSsisdbRead`)
- `mssql_errorlog_signals` / failed logins → `xp_readerrorlog` (`@GrantReadErrorLog`)
- `mssql_index_fragmentation` and other per-DB collectors → user database access (`@GrantUserDatabaseAccess`)
- `mssql_security` (Audit file read) → typically `CONTROL SERVER` (intentionally not granted by the least-privilege script)

### 5) Run or restart the service

Validate the complete configuration before restarting the service:

```powershell
.\sql_exporter.exe "-config.file=sql_exporter.yml" -config.check
```

If the service already exists:
- replace the config file
- restart the service

If you only want to test:
- start the exporter with the current config

### 6) Scrape port and Basic Auth (optional)

#### Port (default)

Upstream and install-script default: **`:9399`**

- Remote install: `-ListenAddress` (example: `-ListenAddress ':9399'`)
- Remote install/upgrade with Basic Auth: `-BasicAuthUsername` + `-BasicAuthHash` (recommended) or `-BasicAuthPassword` (requires Python with `bcrypt` on the client running the script); or `-WebConfigPath` for a custom file
- Remote upgrade: omit `-ListenAddress` to preserve the existing service address; use `-PreserveWebConfig` to keep the remote `web-config.yml`
- Manual: `--web.listen-address=:9399` on the service / ImagePath

Open the chosen port on the host firewall for Prometheus scrapes.

#### Basic Auth — default

In the current package, `basic_auth_users` in `web-config.yml` is **disabled** (no authentication).  
If the section is empty or commented out, `/metrics` is reachable without a username/password.

Official reference: [Prometheus exporter toolkit — web configuration](https://github.com/prometheus/exporter-toolkit/blob/master/docs/web-configuration.md)

#### Enable Basic Auth

1. Choose a strong password and create a **bcrypt hash** (never put the raw password in `web-config.yml`).

With Python (if `bcrypt` is installed):

```powershell
python -c "import bcrypt; print(bcrypt.hashpw(b'YOUR_PASSWORD', bcrypt.gensalt(rounds=12)).decode())"
```

Or use a trusted bcrypt generator (for example [bcrypt-generator.com](https://bcrypt-generator.com/)) with cost about **12**.

2. Enable the users section in `web-config.yml`:

```yaml
basic_auth_users:
  prometheus_user: $2a$12$REPLACE_WITH_BCRYPT_HASH
```

You can add multiple users; each key is a username and each value is that user's hash.

3. Ensure the service points at this file with `--web.config.file` (`Install-SqlExporterRemote.ps1` and `Upgrade-SqlExporterRemote.ps1` set this; use `-BasicAuthUsername` + `-BasicAuthHash` or `-WebConfigPath` during install/upgrade instead of editing the file by hand when possible).

4. Restart the service:

```powershell
Restart-Service prometheus_sql_exporter
```

5. Local test with credentials:

```powershell
$user = 'prometheus_user'
$pass = 'YOUR_PASSWORD'
$pair = "{0}:{1}" -f $user, $pass
$b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
Invoke-WebRequest -Uri 'http://127.0.0.1:9399/metrics' -Headers @{ Authorization = "Basic $b64" }
```

Without an `Authorization` header you should get **401**.

#### Configure Prometheus to scrape with Basic Auth

On the Prometheus side (not in the exporter file), set the **plaintext** password in a secret / `basic_auth` block:

```yaml
- job_name: sql_exporter
  basic_auth:
    username: prometheus_user
    password: YOUR_PASSWORD
  static_configs:
    - targets:
        - 'HOSTNAME:9399'
```

If Basic Auth is enabled on the exporter but missing from the scrape job, scrapes fail with `up=0` and HTTP 401.

#### Security notes

- Commit the bcrypt hash; do not commit the plaintext password.
- Always restart the service after changing `web-config.yml`.
- For production, enable Basic Auth and/or TLS.

## Health check

After startup, check:

```text
http://HOSTNAME:9399/metrics
```

If Basic Auth is enabled, the client must send credentials (browser prompt or `Authorization: Basic ...`).

You should see:
- `mssql_up`
- `mssql_hostname`
- `mssql_product_version`
- metrics from enabled collectors

## Recommended profiles

### DWH / BI
- `mssql_standard`
- `mssql_backup`
- `mssql_restore`
- `mssql_job_inventory`
- `mssql_alwayson`
- `mssql_alwayson_events`
- `mssql_waits`
- `mssql_memory`
- `mssql_tempdb`
- `mssql_file_io`

### Restore / backup-sync secondary
- `mssql_standard`
- `mssql_restore`
- `mssql_backup`
- `mssql_job_inventory`
- `mssql_job_running`
- `mssql_job_failed`
- `mssql_job_history`
- `mssql_database_space`
- `mssql_file_io`

### OLTP
- `mssql_standard`
- `mssql_backup`
- `mssql_alwayson`
- `mssql_alwayson_events`
- `mssql_waits`
- `mssql_memory`
- `mssql_tempdb`
- `mssql_file_io`
- `mssql_blocking`
- `mssql_log_usage`

### Phase P0 / P1 / P2 alerts
Minimum collectors for prioritized alerts; see [alerting.md](alerting.md):

```powershell
.\scripts\powershell\sql-exporter\Deploy-SqlExporterConfig.ps1 -Computers SQL01 -Profile alert-p1.yml
```

Sample `rule_files`: `prometheus/scrape-configs/sql-exporter/p1-high.yml`

## Important `sql_exporter.yml` settings

### `scrape_timeout`

Controls execution time. Use a reasonable value for busy SQL Servers.

### `scrape_timeout_offset`

Prevents Prometheus from timing out before the exporter.

### `min_interval`

Controls how often heavy queries can run.

### `collector_files`

Collector file path:

```yaml
collector_files:
  - "collector/*.collector.yml"
```

### `enable_query_metrics`

Version 0.24.4 can publish execution duration and returned-row counts for
individual collector queries. This is useful during rollout and performance
troubleshooting:

```yaml
global:
  enable_query_metrics: true
```

The resulting metrics are `query_duration_seconds` and
`query_rows_returned`. Keep this disabled by default if query labels create
unwanted cardinality.

## Quick troubleshooting

### `up=0`
- exporter service is down
- the port is blocked (default **9399**)
- the config is wrong
- Basic Auth is enabled on the exporter but not configured on the Prometheus job (HTTP 401)

### High `scrape_errors_total`
- a query is failing
- SQL permissions are missing
- a collector is too heavy

### Empty metric output
- the instance does not have that feature
- permissions are missing
- the collector is not relevant for that server

Feature-specific collectors such as CDC, replication, SSIS, Query Store,
Always On and Resource Governor may legitimately return no series when the
feature or its database is unavailable.

## Practical advice for new team members

1. Read `sql_exporter.yml` first.
2. Enable only one light profile.
3. Test `http://HOSTNAME:9399/metrics`.
4. Add heavier collectors later.
5. Always test on one server before rollout.

