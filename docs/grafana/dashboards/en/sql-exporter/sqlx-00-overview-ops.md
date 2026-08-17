# Overview Live Ops

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/sql-exporter/sqlx-00-overview-ops.md) · [Exporter documentation](../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Live ops cockpit (15s): KPI strip, burning exceptions, TopK timeseries trends, jobs/SSIS. Tune Over Avg x for long-job detection.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-00-overview-ops` |
| Source file | [`sqlx-00-overview-ops.json`](../../../../../grafana/dashboards/sql-exporter/sqlx-00-overview-ops.json) |
| Tags | `sql_exporter`, `mssql`, `overview`, `ops`, `live` |
| Panel count | 67 |
| Refresh interval | `15s` |
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
| 4 | Suspect | `stat` |
| 5 | Blocking | `stat` |
| 6 | HeadBlk | `stat` |
| 7 | JobFail | `stat` |
| 8 | OverAvg | `stat` |
| 9 | AG Lag | `stat` |
| 10 | AG RedoQ | `stat` |
| 11 | Max CPU | `stat` |
| 12 | Max Log% | `stat` |
| 13 | WriteLat | `stat` |
| 14 | LowPLE | `stat` |
| 15 | RestoreLag | `stat` |
| 16 | SSISFail | `stat` |
| 17 | FailedLogins | `stat` |
| 18 | ErrLogSig | `stat` |
| 19 | LogFull | `stat` |
| 20 | Latch845 | `stat` |
| 21 | AGRedo | `stat` |
| 22 | XpCmdshell | `stat` |
| 23 | HeavyQ | `stat` |
| 24 | Deadlocks | `stat` |
| 25 | Now Burning (exceptions) | `row` |
| 26 | Blocking > 0 | `table` |
| 27 | Head Blockers > 0 | `table` |
| 28 | Long Transactions > 0 | `table` |
| 29 | Memory Grants Pending > 0 | `table` |
| 30 | CPU > 40% | `table` |
| 31 | Log Used >= 70% | `table` |
| 32 | Read Latency >= 20ms | `table` |
| 33 | Write Latency >= 20ms | `table` |
| 34 | Trends (Top 5 hotspots) | `row` |
| 35 | CPU % (topk 5) | `timeseries` |
| 36 | Signal Wait % (topk 5) | `timeseries` |
| 37 | PLE (bottom 5) | `timeseries` |
| 38 | Log Used % (topk 5) | `timeseries` |
| 39 | Write Latency (topk 5) | `timeseries` |
| 40 | AG Data Loss (topk 5) | `timeseries` |
| 41 | Jobs / SSIS | `row` |
| 42 | Jobs Running | `table` |
| 43 | Jobs Over Avg / Long | `table` |
| 44 | Failed Jobs (24h) > 0 | `table` |
| 45 | SSIS Failed (24h) > 0 | `table` |
| 46 | HA / Backup / Integrity | `row` |
| 47 | AlwaysOn Lag (exceptions) | `table` |
| 48 | Restore Lag >= 5m | `table` |
| 49 | Suspect Pages > 0 | `table` |
| 50 | CHECKDB Age >= 7d | `table` |
| 51 | DB Space >= 85% | `table` |
| 52 | Autogrowth 24h > 0 | `table` |
| 53 | Security / ERRORLOG | `row` |
| 54 | Failed Logins (60m) > 0 | `table` |
| 55 | ERRORLOG Signals > 0 | `table` |
| 56 | xp_cmdshell Enabled | `table` |
| 57 | Orphaned Users > 0 | `table` |
| 58 | Deadlocks /h > 0 | `table` |
| 59 | Instance Configuration | `row` |
| 60 | RestartPend | `stat` |
| 61 | IFIOff | `stat` |
| 62 | CfgDrift | `stat` |
| 63 | PrioBoost | `stat` |
| 64 | Restart Pending | `table` |
| 65 | IFI Disabled | `table` |
| 66 | Priority Boost ON | `table` |
| 67 | Lightweight Pooling ON | `table` |

Panel type summary: `row`: 6, `stat`: 28, `table`: 27, `timeseries`: 6

## Metrics used

- `mssql_alwayson_estimated_data_loss_seconds`
- `mssql_alwayson_redo_queue_kb`
- `mssql_alwayson_redo_queue_remaining_seconds`
- `mssql_autogrowth_events_24h`
- `mssql_blocking_count`
- `mssql_blocking_head_count`
- `mssql_buffer_pool_page_life_expectancy`
- `mssql_checkdb_age_seconds`
- `mssql_cpu_signal_wait_percent`
- `mssql_cpu_sqlserver_process_percent`
- `mssql_cpu_system_idle_percent`
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
- `mssql_restore_lag_seconds`
- `mssql_sqlagent_running`
- `mssql_ssis_failed_count`
- `mssql_suspect_pages`
- `mssql_suspect_pages_total`
- `mssql_up`
- `mssql_xp_cmdshell_enabled`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
