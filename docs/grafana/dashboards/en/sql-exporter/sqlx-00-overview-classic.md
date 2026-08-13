# Overview Classic

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/sql-exporter/sqlx-00-overview-classic.md) · [Exporter documentation](../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Classic compact fleet overview (earlier generation): core KPI + essential tables. Prefer Overview (canonical) for daily use.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-00-overview-classic` |
| Source file | [`sqlx-00-overview-classic.json`](../../../../../grafana/dashboards/sql-exporter/sqlx-00-overview-classic.json) |
| Tags | `sql_exporter`, `mssql`, `overview`, `classic` |
| Panel count | 41 |
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
| 3 | AgentDown | `stat` |
| 4 | Blocking | `stat` |
| 5 | JobFail | `stat` |
| 6 | Untitled | `text` |
| 7 | Server State | `table` |
| 8 | SQL Agent State | `table` |
| 9 | Blocking | `table` |
| 10 | Long Transactions | `table` |
| 11 | CPU | `table` |
| 12 | Memory Grants Pending | `table` |
| 13 | Log Used % | `table` |
| 14 | Backup Age RW (Full 7d / Diff / Log) | `table` |
| 15 | Backup Age RO (Full monthly) | `table` |
| 16 | Suspect Pages | `table` |
| 17 | Job Failed 24h | `table` |
| 18 | FailedLogins | `stat` |
| 19 | XpCmdshell | `stat` |
| 20 | SA Enabled | `stat` |
| 21 | Orphans | `stat` |
| 22 | ErrLogSig | `stat` |
| 23 | Latch845 | `stat` |
| 24 | AGRedo | `stat` |
| 25 | LogFull | `stat` |
| 26 | Security / ERRORLOG | `row` |
| 27 | Failed Logins (60m) | `table` |
| 28 | ERRORLOG Signals | `table` |
| 29 | xp_cmdshell Enabled Hosts | `table` |
| 30 | Orphaned Users | `table` |
| 31 | OverAvg | `stat` |
| 32 | Jobs Over Avg | `table` |
| 33 | Instance Configuration | `row` |
| 34 | RestartPend | `stat` |
| 35 | IFIOff | `stat` |
| 36 | CfgDrift | `stat` |
| 37 | PrioBoost | `stat` |
| 38 | Restart Pending | `table` |
| 39 | IFI Disabled | `table` |
| 40 | Priority Boost ON | `table` |
| 41 | Lightweight Pooling ON | `table` |

Panel type summary: `row`: 2, `stat`: 18, `table`: 20, `text`: 1

## Metrics used

- `mssql_alwayson_replica_db_synchronization_health`
- `mssql_backup_age_seconds`
- `mssql_blocking_count`
- `mssql_cpu_sqlserver_process_percent`
- `mssql_database_is_read_only`
- `mssql_errorlog_signal_count`
- `mssql_failed_logins_total`
- `mssql_instance_config_restart_pending`
- `mssql_instance_config_value_in_use`
- `mssql_instance_ifi_enabled`
- `mssql_job_failed_total`
- `mssql_job_history_avg_duration_seconds_24h`
- `mssql_job_running_seconds`
- `mssql_log_used_percent`
- `mssql_long_transaction_count`
- `mssql_memory_grants_pending`
- `mssql_orphaned_users`
- `mssql_restore_db_standby`
- `mssql_sa_login_enabled`
- `mssql_sqlagent_running`
- `mssql_suspect_pages`
- `mssql_up`
- `mssql_xp_cmdshell_enabled`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
