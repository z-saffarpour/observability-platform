# sql_exporter — SQL Server Monitoring

Documentation for the **sql_exporter** package is located in the docs folder.

Default scrape port: **`9399`**  
Basic Auth default: **disabled** (how to create and enable: [../../docs/sql-exporter/en/install-config-guide.md](../../docs/sql-exporter/en/install-config-guide.md#6-scrape-port-and-basic-auth-optional))

---

## Folder Contents

| File / Folder | Description |
|------|--------|
| `sql_exporter.exe` | Exporter binary |
| `sql_exporter.yml` | SQL connection settings + collector list |
| `web-config.yml` | TLS and Basic Auth (no auth by default) |
| `collector/` | Metric definitions (`mssql_*.collector.yml`) |
| `profiles/` | Ready-made collector profiles (e.g. `oltp.yml`, `alert-p1.yml`) |
| `prometheus/` | `rules/` + `profiles/` + `alertmanager/` for `rule_files` and SMS/Email routing |
| `grafana/dashboards/` | Grafana dashboards (Overview/NOC at root; collectors under `Collector/`) |
| `scripts/powershell/sql-exporter/` | PowerShell deployment and synchronization scripts |
| `scripts/sql/` | Helper SQL scripts (e.g. exporter login) |
| `../../docs/sql-exporter/en/README.md` | English documentation entry point |
| `../../docs/sql-exporter/fa/README.md` | Persian documentation entry point |
| `../../docs/sql-exporter/en/collector-guide.md` | Guide for creating/editing collectors (English) |
| `../../docs/sql-exporter/fa/collector-guide.md` | Guide for creating/editing collectors (Persian) |
| `../../docs/sql-exporter/en/install-upgrade-guide.md` | Install and upgrade guide (English) |
| `../../docs/sql-exporter/en/install-upgrade-guide.html` | Install and upgrade guide HTML (English) |
| `../../docs/sql-exporter/fa/install-upgrade-guide.md` | Install and upgrade guide (Persian) |
| `../../docs/sql-exporter/fa/install-upgrade-guide.html` | Install and upgrade guide HTML (Persian) |
| `../../docs/sql-exporter/en/install-config-guide.md` | sql_exporter installation and configuration guide (English) |
| `../../docs/sql-exporter/fa/install-config-guide.md` | sql_exporter installation and configuration guide (Persian) |
| `../../docs/sql-exporter/en/profiles.md` | Collector profile guide (English) |
| `../../docs/sql-exporter/fa/profiles.md` | Collector profile guide (Persian) |
| `../../docs/sql-exporter/en/prometheus.md` | prometheus/ folder guide (English) |
| `../../docs/sql-exporter/fa/prometheus.md` | prometheus/ folder guide (Persian) |
| `../../docs/sql-exporter/en/alerting.md` | Alert catalog P0/P1/P2 (English) |
| `../../docs/sql-exporter/fa/alerting.md` | Alert catalog P0/P1/P2 (Persian) |
| `../../docs/sql-exporter/en/alertmanager.md` | Alertmanager SMS/Email routing (English) |
| `../../docs/sql-exporter/fa/alertmanager.md` | Alertmanager SMS/Email routing (Persian) |
| `../../docs/sql-exporter/en/prometheus-rules.md` | Recording and alerting rule guide (English) |
| `../../docs/sql-exporter/fa/prometheus-rules.md` | Recording and alerting rule guide (Persian) |
| `../../docs/sql-exporter/en/grafana.md` | Grafana dashboards (English) |
| `../../docs/sql-exporter/fa/grafana.md` | Grafana dashboards (Persian) |
| `../../docs/sql-exporter/en/collectors/README.md` | Collector index and guide (English) |
| `../../docs/sql-exporter/fa/collectors/README.md` | Collector index and guide (Persian) |
| `../../docs/sql-exporter/README.md` | Documentation entry point (EN / FA router) |
| `README.md` | Root readme (default language) |
| `README_en.md` | English README (this file) |

Collector loading:

```yaml
collector_files:
  - "collector/*.collector.yml"

collectors: [mssql_*]   # or explicit list of profiles
```

---

## Remote installation (recommended)

Use the WinRM-based scripts for install and upgrade. Full details:
[Install and upgrade guide](../../docs/sql-exporter/en/install-upgrade-guide.md)

### Install / update service

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 -Computers sql-host-01,sql-host-02 -WhatIf
```

Apply:

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)
```

With a collector profile (same UX as windows_exporter `-Profile sql-server.yml`):

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -Profile oltp.yml `
  -RemoteCredential (Get-Credential)
```

With custom listen address and Basic Auth:

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -ListenAddress ':9399' `
  -BasicAuthUsername 'scrape_user' `
  -BasicAuthHash '$2a$12$REPLACE_WITH_BCRYPT_HASH' `
  -RemoteCredential (Get-Credential)
```

### Upgrade an existing installation

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 -Computers sql-host-01,sql-host-02 -WhatIf
```

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)
```

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -Profile oltp.yml `
  -RemoteCredential (Get-Credential)
```

Preserve web-config and change listen port on upgrade:

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -ListenAddress ':9399' `
  -PreserveWebConfig `
  -RemoteCredential (Get-Credential)
```

Notes:
- Requires PowerShell Remoting (WinRM) access to target servers.
- Creates/updates `prometheus_sql_exporter` service using native Windows service APIs.
- Deploys `sql_exporter.exe`, `sql_exporter.yml`, `web-config.yml`, `profiles\`, and `collector\` (unless `-SkipCollectors` on Install).
- `-ListenAddress` sets `--web.listen-address` (default `:9399`).
- `-BasicAuthUsername` + `-BasicAuthHash` (or `-BasicAuthPassword` / `-WebConfigPath`) enable Basic Auth during install/upgrade; `-PreserveWebConfig` keeps the remote file on upgrade.
- `-Profile <name>.yml` writes the collectors list from `profiles/` into `sql_exporter.yml`.
- Without `-Profile`, Upgrade preserves the remote config; it backs up before replacement and rolls back on failure.

### Uninstall a remote installation

```powershell
.\scripts\powershell\sql-exporter\Uninstall-SqlExporterRemote.ps1 `
  -Computers sql-host-01,sql-host-02 `
  -ServiceMode Preserve `
  -WhatIf
```

The default operation removes the service and deployment folder after creating a ZIP backup. Use `-KeepFiles` to remove only the service. Details: [Install, upgrade, and uninstall guide](../../docs/sql-exporter/en/install-upgrade-guide.md#remote-uninstall).

### Sync collectors only

Default matches `collector_files: collector/*.collector.yml`. Switch with `-Layout`:

```powershell
# Default: copy into collector\, purge root *.collector.yml
.\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 -Computers sql-host-01,sql-host-02 -Layout Collector

# Root layout: copy into install root, delete collector\ folder
.\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 -Computers sql-host-01 -Layout Root -WhatIf
```

Details: [Install and upgrade guide](../../docs/sql-exporter/en/install-upgrade-guide.md)

### Export Grafana dashboards into the repo

```powershell
# Requires GRAFANA_URL and GRAFANA_SERVICE_ACCOUNT_TOKEN
.\scripts\powershell\sql-exporter\Export-GrafanaDashboards.ps1
.\scripts\powershell\sql-exporter\Export-GrafanaDashboards.ps1 -RemoveOrphans
```

Guide: [../../docs/sql-exporter/en/grafana.md](../../docs/sql-exporter/en/grafana.md)

---

## Additional Guides

- [Main Documentation](../../docs/sql-exporter/README.md)
- [English Documentation](../../docs/sql-exporter/en/README.md)
- [Persian Documentation](../../docs/sql-exporter/fa/README.md)
- [Install and upgrade guide](../../docs/sql-exporter/en/install-upgrade-guide.md) ([HTML](../../docs/sql-exporter/en/install-upgrade-guide.html)) — [Required access](../../docs/sql-exporter/en/install-upgrade-guide.md#required-access)
- [Install and config guide](../../docs/sql-exporter/en/install-config-guide.md)
- [Collector Profiles](../../docs/sql-exporter/en/profiles.md)
- [prometheus/ folder guide](../../docs/sql-exporter/en/prometheus.md)
- [Alerting catalog](../../docs/sql-exporter/en/alerting.md)
- [Alertmanager — SMS and Email](../../docs/sql-exporter/en/alertmanager.md)
- [Prometheus Rules and Alerts](../../docs/sql-exporter/en/prometheus-rules.md)
- [Grafana dashboards](../../docs/sql-exporter/en/grafana.md)
- [Collector Documentation Index](../../docs/sql-exporter/en/collectors/README.md)

---

## Connecting to SQL Server

In `sql_exporter.yml`:

```yaml
data_source_name: 'sqlserver://127.0.0.1:49149?trusted+connection=yes&app+name=sql_exporter'
```

- Windows Authentication is used.
- Replace the port with the actual instance port.
- The exporter service must run under an account with SQL Server access.

### Required Permissions

```sql
GRANT VIEW SERVER STATE TO [DOMAIN\SqlExporterAccount];
GRANT VIEW ANY DEFINITION TO [DOMAIN\SqlExporterAccount];
```

| Collector | Additional Access |
|-----------|--------------|
| `mssql_backup`, `mssql_restore`, `mssql_job_inventory`, `mssql_job_running`, `mssql_job_history`, `mssql_job_failed` | Read access to `msdb` tables (`restorehistory` / `backupset` for restore) |
| `mssql_database_integrity` | `suspect_pages` + `DBCC DBINFO` |
| `mssql_ssis` | `db_datareader` on `SSISDB` |
| `mssql_replication` | Read access to `distribution` (if Distributor) |
| `mssql_errorlog_signals` | `xp_readerrorlog` |
| `mssql_security` | `xp_readerrorlog` (failed logins), `CONTROL SERVER` (SQL Audit file read) |
| `mssql_index_fragmentation` | Access to user databases |

---

## Removed Collectors (Merged)

These files have been moved to `sql_exporter_removed/`; their unique content has been merged into active collectors:

| Removed | Merged Into |
|---------|----------|
| `mssql_availability_sync` | `mssql_alwayson` |
| `mssql_workspace_memory` | `mssql_memory` |
| `mssql_performance_counters` | `mssql_standard` (`mssql_perf_counter`) + `mssql_memory` / `mssql_buffer_pool` |
| `mssql_ssis` / `mssql_ssisdb` (legacy) | `mssql_ssis` (+ Agent in `mssql_job_running`) |
| `mssql_oltp` | `mssql_locks` + `mssql_transactions_long` |
| `mssql_dwh` | `mssql_parallelism` + `mssql_ssis` + `mssql_job_running` |

---

## Collector Index

### Common (All Server Types)

| Collector | `min_interval` | Purpose |
|-----------|----------------|--------|
| `mssql_standard` | 30s | up, version, DB state/recovery, transactions, errors, batch, perf_counter, process/OS memory, user connections, compilations/recompilations, checkpoint/log reuse wait |
| `mssql_backup` | 900s | backup age/size + damaged + failed backup jobs + throughput/compression/verify |
| `mssql_restore` | 300s | latest restore from `restorehistory` (lag/age/size/source) + standby state + throughput/gap-to-RPO + failed restore jobs — ideal for backup-sync secondaries like sql-host-02\\NODE |
| `mssql_job_inventory` | 900s | job enabled/count / last outcome / next run |
| `mssql_waits` | 120s | top wait types + nonbenign/signal ratio + top 5 share |
| `mssql_memory` | 60s | clerks, resource semaphore, grants, Reserved Server Memory, active grants ≥100MB, target/total/stolen/locked pages |
| `mssql_tempdb` | 60s | tempdb space, version store, top sessions, waiting tasks, spill/load contention |
| `mssql_file_io` | 180s | stall/latency per file + volume space + pending requests/bytes + queue depth + p95 latency |
| `mssql_blocking` | 30s | blocked sessions / head blocker |
| `mssql_heavy_queries` | 60s | active heavy requests + top plan cache |
| `mssql_log_usage` | 60s | log percentage and volume |
| `mssql_connections_detail` | 60s | sessions by login/program/host/database |
| `mssql_database_size_growth` | 300s | data/log size growth and file growth |
| `mssql_cpu` | 30s | SQL process CPU from ring buffer |
| `mssql_buffer_pool` | 180s | PLE (NUMA) and Buffer Manager |
| `mssql_parallelism` | 60s | parallelism waits, MAXDOP/memory config, DOP + grant |
| `mssql_job_running` | 30s | Agent service + running jobs (+ step) |
| `mssql_job_failed` | 60s | job failures (1h/24h) + last fail + current failed |
| `mssql_job_history` | 120s | execution history / last duration / avg success |
| `mssql_database_space` | 300s | used/free, max_size, autogrowth, VLF |
| `mssql_database_integrity` | 3600s | suspect_pages + age of last CHECKDB |
| `mssql_scheduler` | 30s | runnable / work_queue / CPU topology |
| `mssql_plan_cache` | 120s | cache size, single-use ratio |
| `mssql_columnstore` | 300s | rowgroup health (useful for DWH) |
| `mssql_autogrowth` | 300s | autogrowth events from default trace |
| `mssql_stats` | 600s | TOP stale statistics / modification_counter / sample% + count stale per DB |
| `mssql_index_usage` | 300s | TOP index seeks/scans/lookups/updates |
| `mssql_instance_configuration` | 300s | instance config drift (value vs in_use) + IFI + uptime + global trace flags |
| `mssql_missing_index` | 600s | TOP 30 missing index recommendations + cost/compiles + per-DB rollup |
| `mssql_query_store` | 300s | QS status + top queries |
| `mssql_errorlog_signals` | 300s | count of ERRORLOG signals |
| `mssql_security` | 300s | security posture: failed logins, privileged sessions, audit, TDE/backup encryption, surface area, linked servers |

### Always On

| Collector | `min_interval` | Purpose |
|-----------|----------------|--------|
| `mssql_alwayson` | 30s | complete AG monitoring (lag / sync / seeding) |
| `mssql_alwayson_events` | 300s | replica state flaps from AlwaysOn_health (24h) |
| `mssql_hadr_cluster` | 30s | AG listeners + WSFC quorum/members + FCI nodes |

**`mssql_alwayson` includes:**
estimated data loss, secondary lag, `log_send_queue/rate`, `redo_queue/rate`, `commit_latency`, filestream send rate, approximate queue drain time, suspend, disconnected time, flap count, per-replica metrics, replica and AG health.
Legacy metric `mssql_alwayson_data_loss` is retained for dashboard compatibility.

**`mssql_hadr_cluster` includes:**
`IsClustered` / `IsHadrEnabled` flags, WSFC quorum and member state, AG listener DNS/port/IP state, FCI node status and current owner.

### OLTP Specific

| Collector | `min_interval` | Purpose |
|-----------|----------------|--------|
| `mssql_locks` | 30s | locks, waiting locks, latch stats, lock-related requests |
| `mssql_transactions_long` | 30s | open transactions ≥ 30s |
| `mssql_index_fragmentation` | **21600s (6h)** | index fragmentation — very expensive |
| `mssql_replication` | 60s | push/pull: DB role, inventory, Log Reader / Distribution / Snapshot latency+status, pending cmds, REPL-* jobs (suitable for Publisher+Subscriber like sql-pub-01 and Pull like sql-sub-01) |

### DWH / SSIS Specific

| Collector | `min_interval` | Purpose |
|-----------|----------------|--------|
| `mssql_ssis` | 60s | SSIS catalog + SSISDB health/volume |

If `SSISDB` / `distribution` / AG does not exist, results are empty and scrape does not fail.

---

## Profiles

Current default loads all collectors:

```yaml
collectors: [mssql_*]
```

For high-traffic servers, enable one of the profiles below in `sql_exporter.yml` (or pass `-Profile oltp.yml` to the Install/Upgrade/Deploy scripts). Complete lists live under `profiles/`; see [profiles guide](../../docs/sql-exporter/en/profiles.md).

### DWH / BI

```yaml
collectors:
  - mssql_standard
  - mssql_backup
  - mssql_restore
  - mssql_job_inventory
  - mssql_alwayson
  - mssql_heavy_queries
  - mssql_waits
  - mssql_memory
  - mssql_tempdb
  - mssql_file_io
  - mssql_blocking
  - mssql_log_usage
  - mssql_connections_detail
  - mssql_database_size_growth
  - mssql_cpu
  - mssql_buffer_pool
  - mssql_parallelism
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_scheduler
  - mssql_plan_cache
  - mssql_columnstore
  - mssql_autogrowth
  - mssql_stats
  - mssql_index_usage
  - mssql_missing_index
  - mssql_ssis
```

### Restore / backup-sync secondary (e.g., sql-host-02\\NODE)

```yaml
collectors:
  - mssql_standard
  - mssql_database_configuration
  - mssql_instance_configuration
  - mssql_backup
  - mssql_job_inventory
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_file_io
  - mssql_waits
  - mssql_memory
  - mssql_cpu
  - mssql_scheduler
  - mssql_autogrowth
  - mssql_restore
  - mssql_log_shipping
  - mssql_errorlog_signals
  - mssql_alwayson
  - mssql_alwayson_events
  - mssql_hadr_cluster
  - mssql_log_usage
  - mssql_connections_detail
```

### Replication (Publisher / Distributor / Subscriber)

```yaml
collectors:
  - mssql_standard
  - mssql_database_configuration
  - mssql_instance_configuration
  - mssql_cdc_change_tracking
  - mssql_backup
  - mssql_job_inventory
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_file_io
  - mssql_waits
  - mssql_memory
  - mssql_cpu
  - mssql_scheduler
  - mssql_autogrowth
  - mssql_replication
  - mssql_errorlog_signals
  - mssql_alwayson
  - mssql_alwayson_events
  - mssql_hadr_cluster
  - mssql_log_usage
  - mssql_blocking
  - mssql_connections_detail
  - mssql_transactions_long
```

### Security / audit

```yaml
collectors:
  - mssql_standard
  - mssql_database_configuration
  - mssql_instance_configuration
  - mssql_backup
  - mssql_job_inventory
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_autogrowth
  - mssql_security
  - mssql_errorlog_signals
  - mssql_certificates
```

### OLTP

```yaml
collectors:
  - mssql_standard
  - mssql_database_configuration
  - mssql_instance_configuration
  - mssql_cdc_change_tracking
  - mssql_resource_governor
  - mssql_backup
  - mssql_job_inventory
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_file_io
  - mssql_waits
  - mssql_memory
  - mssql_cpu
  - mssql_scheduler
  - mssql_autogrowth
  - mssql_alwayson
  - mssql_alwayson_events
  - mssql_hadr_cluster
  - mssql_heavy_queries
  - mssql_tempdb
  - mssql_blocking
  - mssql_log_usage
  - mssql_connections_detail
  - mssql_locks
  - mssql_transactions_long
  - mssql_buffer_pool
  - mssql_plan_cache
  - mssql_stats
  - mssql_index_usage
  - mssql_query_store
```

### Separate SSIS

```yaml
collectors:
  - mssql_standard
  - mssql_backup
  - mssql_job_inventory
  - mssql_waits
  - mssql_memory
  - mssql_tempdb
  - mssql_file_io
  - mssql_blocking
  - mssql_log_usage
  - mssql_connections_detail
  - mssql_cpu
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_autogrowth
  - mssql_ssis
```

---

## Deployment

1. Copy the entire folder contents to the server.
2. Configure `data_source_name` and optionally `collectors` in `sql_exporter.yml`.
3. Restart the sql_exporter Windows service.
4. Test:

```text
http://HOSTNAME:9399/metrics
```

If Basic Auth is enabled, requests without credentials return 401. Guide: [../../docs/sql-exporter/en/install-config-guide.md](../../docs/sql-exporter/en/install-config-guide.md#6-scrape-port-and-basic-auth-optional).

Useful example queries in `/metrics`:

- `mssql_up`
- `mssql_alwayson_`
- `mssql_hadr_`
- `mssql_requests_` / `mssql_top_query_`
- `mssql_wait_`
- `mssql_tempdb_`
- `mssql_perf_counter`
- `mssql_parallelism_`
- `mssql_memory_active_grant_mb`
- `mssql_memory_target_server_mb`
- `mssql_memory_stolen_mb`
- `mssql_tempdb_waiting_tasks_count`
- `mssql_tempdb_spill_writes_mb`
- `mssql_file_io_pending_requests`
- `mssql_file_io_read_latency_p95_ms`
- `mssql_backup_throughput_mb_s`
- `mssql_restore_gap_to_rpo_seconds`
- `mssql_waits_nonbenign_percent`
- `mssql_ssis_failed_total`
- `mssql_ssis_failed_count`
- `mssql_ssis_failed_last_age_seconds`
- `mssql_job_history_`
- `mssql_backup_age_seconds`
- `mssql_restore_lag_seconds`
- `mssql_restore_age_seconds`
- `mssql_restore_job_failed_total_24h`
- `mssql_job_failed_total`
- `mssql_job_failed_current`
- `mssql_database_space_`
- `mssql_checkdb_age_seconds`
- `mssql_scheduler_total_runnable`
- `mssql_plan_cache_single_use_ratio`
- `mssql_columnstore_`
- `mssql_autogrowth_`
- `mssql_stats_`
- `mssql_missing_index_`
- `mssql_alwayson_is_failover_ready`
- `mssql_backup_job_failed_total_24h`

---

## Adding a New Collector

1. Create a file `collector/mssql_NAME.collector.yml` (`collector_name` must match the file name).
2. If `collectors: [mssql_*]` is set → restart is all that's needed.
3. If using an explicit profile → add the name to the `collectors` list.
4. Test on a test server, then roll out.

Minimal template:

```yaml
collector_name: mssql_example
min_interval: 60s
metrics:
  - metric_name: mssql_example_value
    type: gauge
    help: 'Example metric'
    values: [value]
    query: |
      SELECT CAST(1 AS float) AS value;
```

---

## Performance Notes

- `min_interval` prevents excessive execution of heavy queries (even if scrape is every 15s).
- View counter metrics with `rate()` / `increase()`.
- Alert directly on point-in-time metrics (blocking, AG lag, pending grants).
- Avoid labeling full query text; use only short `statement_snip`.
- Disable on very busy servers unless needed:
  - `mssql_index_fragmentation`
  - `mssql_errorlog_signals`

---

## Troubleshooting

| Issue | Action |
|------|--------|
| Target `up=0` | Check exporter service, port 9399, firewall, Basic Auth |
| Cannot connect to SQL | Check DSN, instance port, service account permissions |
| `scrape_errors_total` high | Check service logs; one collector query is malformed |
| AG metrics empty | Instance is not a member of an AG |
| SSIS metrics empty | `SSISDB` does not exist or no access |
| restore metrics empty | No `restorehistory` on this instance this year (primary without restores) |
| Too many series | Limit the profile |

---

## Example Always On Alerts

```promql
mssql_alwayson_secondary_lag_seconds > 30
mssql_alwayson_log_send_queue_kb > 102400
mssql_alwayson_redo_queue_kb > 102400
mssql_alwayson_is_suspended == 1
mssql_alwayson_replica_connected_state == 0
mssql_alwayson_group_synchronization_health < 2
mssql_hadr_cluster_quorum_state != 1
mssql_hadr_cluster_member_state != 1
mssql_hadr_listener_ip_state != 0
mssql_hadr_fci_node_status != 0
```

## Example Restore / Backup-Sync Alerts

Equivalent to **Difference Restore** column in Power BI report (`GETDATE() - backup_finish_date`):

```promql
# Lag greater than 2 hours (like orange alert in Power BI)
mssql_restore_lag_seconds > 7200

# Critical lag (days without successful restore)
mssql_restore_lag_seconds > 86400

# Failed RESTORE jobs in last 24 hours
mssql_restore_job_failed_total_24h > 0
```

---

## Summary

| Server Type | Recommendation |
|----------|---------|
| DWH / BI | common + `mssql_parallelism` + `mssql_ssis` + `mssql_alwayson` (+ `mssql_restore` if also secondary) |
| restore secondary | `profiles/restore-secondary.yml`: restore + log shipping + AG/HADR |
| replication | `profiles/replication.yml`: replication + AG/HADR + CDC |
| security / audit | `profiles/security-audit.yml`: security + errorlog + certificates (no heavy perf-detail) |
| OLTP | `profiles/oltp.yml`: common + locks/transactions + AlwaysOn/HADR + Query Store |
| P0 alerts (Critical) | `profiles/alert-p0.yml` + `prometheus/scrape-configs/sql-exporter/p0-critical.yml` |
| P0+P1 alerts | `profiles/alert-p1.yml` + `prometheus/scrape-configs/sql-exporter/p1-high.yml` |
| Full priority stack | `profiles/alert-p2.yml` + `prometheus/scrape-configs/sql-exporter/p2-medium.yml` / `oltp.yml` |
| separate SSIS | lightweight common + `mssql_ssis` + `mssql_job_running` |
| all (testing) | `collectors: [mssql_*]` |
