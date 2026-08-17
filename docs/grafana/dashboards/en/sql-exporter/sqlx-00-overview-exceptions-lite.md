# Overview Exceptions Lite

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/sql-exporter/sqlx-00-overview-exceptions-lite.md) · [Exporter documentation](../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Compact exceptions-only triage: fewer KPIs and incident tables than Overview Exceptions.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-00-overview-exceptions-lite` |
| Source file | [`sqlx-00-overview-exceptions-lite.json`](../../../../../grafana/dashboards/sql-exporter/sqlx-00-overview-exceptions-lite.json) |
| Tags | `sql_exporter`, `mssql`, `overview`, `exceptions`, `lite` |
| Panel count | 54 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `over_avg_factor` | Over Avg x | `custom` | `1.2,1.5,2,3` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Total | `stat` |
| 2 | Down | `stat` |
| 3 | Suspect | `stat` |
| 4 | Blocking | `stat` |
| 5 | HeadBlk | `stat` |
| 6 | JobFail | `stat` |
| 7 | OverAvg | `stat` |
| 8 | AG Lag | `stat` |
| 9 | FailedLogins | `stat` |
| 10 | XpCmdshell | `stat` |
| 11 | SA Enabled | `stat` |
| 12 | Orphans | `stat` |
| 13 | ErrLogSig | `stat` |
| 14 | HeavyQ | `stat` |
| 15 | Incidents (exceptions only) | `row` |
| 16 | Blocking > 0 | `table` |
| 17 | Long Tx > 0 | `table` |
| 18 | Head Blockers > 0 | `table` |
| 19 | AlwaysOn Lag (data loss / redo) > 30s | `table` |
| 20 | CPU >= 70% | `table` |
| 21 | Memory Grants > 0 | `table` |
| 22 | Log Used >= 70% | `table` |
| 23 | HA / Backup / Integrity / Long Jobs | `row` |
| 24 | Backup Age RW (Full 7d / Diff / Log) | `table` |
| 25 | Backup Age RO (Full monthly) | `table` |
| 26 | Restore Lag >= 5m | `table` |
| 27 | Suspect Pages > 0 | `table` |
| 28 | CHECKDB Age >= 7d | `table` |
| 29 | Jobs Over Avg | `table` |
| 30 | Capacity / Autogrowth / IO | `row` |
| 31 | DB Space >= 85% | `table` |
| 32 | Autogrowth 24h > 0 | `table` |
| 33 | Read Latency >= 20ms | `table` |
| 34 | Write Latency >= 20ms | `table` |
| 35 | Failed Jobs / SSIS | `row` |
| 36 | Failed Jobs (24h) | `table` |
| 37 | SSIS Failed (24h) | `table` |
| 38 | Security / ERRORLOG | `row` |
| 39 | Failed Logins (60m) | `table` |
| 40 | ERRORLOG Signals | `table` |
| 41 | xp_cmdshell Enabled Hosts | `table` |
| 42 | Orphaned Users | `table` |
| 43 | TempDB / Deadlocks | `row` |
| 44 | TempDB Used MB | `table` |
| 45 | Deadlocks /h > 0 | `table` |
| 46 | Instance Configuration | `row` |
| 47 | RestartPend | `stat` |
| 48 | IFIOff | `stat` |
| 49 | CfgDrift | `stat` |
| 50 | PrioBoost | `stat` |
| 51 | Restart Pending | `table` |
| 52 | IFI Disabled | `table` |
| 53 | Priority Boost ON | `table` |
| 54 | Lightweight Pooling ON | `table` |

Panel type summary: `row`: 7, `stat`: 18, `table`: 29

## Metrics used

- `mssql_alwayson_estimated_data_loss_seconds`
- `mssql_alwayson_redo_queue_kb`
- `mssql_alwayson_redo_queue_remaining_seconds`
- `mssql_alwayson_replica_db_synchronization_health`
- `mssql_autogrowth_events_24h`
- `mssql_backup_age_seconds`
- `mssql_blocking_count`
- `mssql_blocking_head_count`
- `mssql_checkdb_age_seconds`
- `mssql_cpu_sqlserver_process_percent`
- `mssql_cpu_system_idle_percent`
- `mssql_database_is_read_only`
- `mssql_database_space_used_percent`
- `mssql_deadlocks`
- `mssql_errorlog_signal_count`
- `mssql_failed_logins_total`
- `mssql_file_io_avg_read_latency_ms`
- `mssql_file_io_avg_write_latency_ms`
- `mssql_instance_config_restart_pending`
- `mssql_instance_config_value_in_use`
- `mssql_instance_ifi_enabled`
- `mssql_job_failed_count`
- `mssql_job_history_avg_duration_seconds_24h`
- `mssql_job_running_seconds`
- `mssql_log_used_percent`
- `mssql_long_transaction_count`
- `mssql_memory_grants_pending`
- `mssql_orphaned_users`
- `mssql_requests_elapsed_ms`
- `mssql_restore_db_standby`
- `mssql_restore_lag_seconds`
- `mssql_sa_login_enabled`
- `mssql_ssis_failed_count`
- `mssql_suspect_pages`
- `mssql_suspect_pages_total`
- `mssql_tempdb_space_used_mb`
- `mssql_up`
- `mssql_xp_cmdshell_enabled`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
