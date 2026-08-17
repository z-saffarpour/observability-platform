# Overview Exceptions

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/sql-exporter/sqlx-00-overview-exceptions.md) · [Exporter documentation](../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Same fleet layout as Overview, but tables are exception-only (threshold filters: CPU, log, latency, AG lag, failed jobs, security gaps, ...).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-00-overview-exceptions` |
| Source file | [`sqlx-00-overview-exceptions.json`](../../../../../grafana/dashboards/sql-exporter/sqlx-00-overview-exceptions.json) |
| Tags | `sql_exporter`, `mssql`, `overview`, `exceptions` |
| Panel count | 98 |
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
| 4 | Suspect | `stat` |
| 5 | Blocking | `stat` |
| 6 | HeadBlk | `stat` |
| 7 | JobFail | `stat` |
| 8 | OverAvg | `stat` |
| 9 | AG Lag | `stat` |
| 10 | AG RedoQ | `stat` |
| 11 | Max CPU | `stat` |
| 12 | Max Log% | `stat` |
| 13 | LogFull | `stat` |
| 14 | RestoreLag | `stat` |
| 15 | RestoreFail | `stat` |
| 16 | FailedLogins | `stat` |
| 17 | XpCmdshell | `stat` |
| 18 | SA Enabled | `stat` |
| 19 | Orphans | `stat` |
| 20 | ErrLogSig | `stat` |
| 21 | Latch845 | `stat` |
| 22 | AGRedo | `stat` |
| 23 | HeavyQ | `stat` |
| 24 | WriteLat | `stat` |
| 25 | LowPLE | `stat` |
| 26 | AGFlaps | `stat` |
| 27 | Unexpected | `stat` |
| 28 | Privileged | `stat` |
| 29 | NoEncBk | `stat` |
| 30 | Fleet Status | `row` |
| 31 | Server State | `table` |
| 32 | SQL Agent State | `table` |
| 33 | Head Blockers | `table` |
| 34 | Blocking | `table` |
| 35 | Memory Grants Pending | `table` |
| 36 | Long Transactions | `table` |
| 37 | AlwaysOn | `row` |
| 38 | AlwaysOn Lag (data loss / redo) > 30s | `table` |
| 39 | AG Sync Flaps 24h > 0 | `table` |
| 40 | CPU / Log | `row` |
| 41 | CPU > 40% | `table` |
| 42 | Log Used >= 70% | `table` |
| 43 | Low PLE < 300s | `table` |
| 44 | HA / Backup / Integrity / Long Jobs | `row` |
| 45 | Backup Age RW (Full 7d / Diff / Log) | `table` |
| 46 | Backup Age RO (Full monthly) | `table` |
| 47 | Restore Lag >= 5m | `table` |
| 48 | Suspect Pages > 0 | `table` |
| 49 | CHECKDB Age >= 7d | `table` |
| 50 | Jobs Running | `table` |
| 51 | Jobs Over Avg | `table` |
| 52 | Capacity / Autogrowth / IO | `row` |
| 53 | DB Space >= 85% | `table` |
| 54 | Autogrowth 24h > 0 | `table` |
| 55 | Read Latency >= 20ms | `table` |
| 56 | Write Latency >= 20ms | `table` |
| 57 | Failed Jobs / SSIS | `row` |
| 58 | Failed Jobs (24h) > 0 | `table` |
| 59 | SSIS Failed (24h) > 0 | `table` |
| 60 | Security / ERRORLOG | `row` |
| 61 | Failed Logins (60m) > 0 | `table` |
| 62 | ERRORLOG Signals > 0 | `table` |
| 63 | xp_cmdshell Enabled Hosts | `table` |
| 64 | Orphaned Users > 0 | `table` |
| 65 | Unexpected Logins > 0 | `table` |
| 66 | Privileged Sessions > 0 | `table` |
| 67 | TDE Off (user DBs) | `table` |
| 68 | Unencrypted Full Backup | `table` |
| 69 | TempDB / Deadlocks | `row` |
| 70 | TempDB Used MB | `table` |
| 71 | Deadlocks /h > 0 | `table` |
| 72 | AG Send / Suspended / Seeding | `row` |
| 73 | Waits / Scheduler / Locks / DB State | `row` |
| 74 | Volume Free | `row` |
| 75 | Replication | `row` |
| 76 | CDC / Change Tracking | `row` |
| 77 | Change Tracking Enabled | `table` |
| 78 | AG Send Queue > 0 | `table` |
| 79 | AG Suspended | `table` |
| 80 | AG Seeding % | `table` |
| 81 | Signal >= 15% / Nonbenign >= 50% | `table` |
| 82 | Top Wait Class (rate > 0) | `table` |
| 83 | Scheduler Pressure (Runnable/WQ > 5) | `table` |
| 84 | Locks Waiting > 0 | `table` |
| 85 | DB not ONLINE | `table` |
| 86 | Volume Free < 15% | `table` |
| 87 | Replication Dist Latency >= 30s | `table` |
| 88 | Replication Pending Cmds > 0 | `table` |
| 89 | CDC Capture Lag >= 5m | `table` |
| 90 | Instance Configuration | `row` |
| 91 | RestartPend | `stat` |
| 92 | IFIOff | `stat` |
| 93 | CfgDrift | `stat` |
| 94 | PrioBoost | `stat` |
| 95 | Restart Pending | `table` |
| 96 | IFI Disabled | `table` |
| 97 | Priority Boost ON | `table` |
| 98 | Lightweight Pooling ON | `table` |

Panel type summary: `row`: 14, `stat`: 33, `table`: 51

## Metrics used

- `mssql_alwayson_estimated_data_loss_seconds`
- `mssql_alwayson_is_suspended`
- `mssql_alwayson_log_send_queue_kb`
- `mssql_alwayson_log_send_queue_remaining_seconds`
- `mssql_alwayson_redo_queue_kb`
- `mssql_alwayson_redo_queue_remaining_seconds`
- `mssql_alwayson_replica_db_synchronization_health`
- `mssql_alwayson_seeding_percent`
- `mssql_alwayson_sync_state_flaps_24h`
- `mssql_autogrowth_events_24h`
- `mssql_backup_age_seconds`
- `mssql_backup_encryption_enabled`
- `mssql_blocking_count`
- `mssql_blocking_head_count`
- `mssql_buffer_pool_page_life_expectancy`
- `mssql_cdc_capture_lag_seconds`
- `mssql_change_tracking_enabled`
- `mssql_checkdb_age_seconds`
- `mssql_cpu_sqlserver_process_percent`
- `mssql_cpu_system_idle_percent`
- `mssql_database_is_read_only`
- `mssql_database_space_used_percent`
- `mssql_database_state`
- `mssql_deadlocks`
- `mssql_encryption_at_rest_enabled`
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
- `mssql_locks_waiting`
- `mssql_log_used_percent`
- `mssql_long_transaction_count`
- `mssql_memory_grants_pending`
- `mssql_orphaned_users`
- `mssql_privileged_sessions`
- `mssql_replication_distributor_latency_seconds`
- `mssql_replication_pending_commands`
- `mssql_requests_elapsed_ms`
- `mssql_restore_db_standby`
- `mssql_restore_job_failed_total_24h`
- `mssql_restore_lag_seconds`
- `mssql_sa_login_enabled`
- `mssql_scheduler_total_runnable`
- `mssql_scheduler_total_work_queue`
- `mssql_sqlagent_running`
- `mssql_ssis_failed_count`
- `mssql_suspect_pages`
- `mssql_suspect_pages_total`
- `mssql_tempdb_space_used_mb`
- `mssql_unexpected_login_count`
- `mssql_up`
- `mssql_volume_used_percent`
- `mssql_waits_by_class_time_ms`
- `mssql_waits_nonbenign_percent`
- `mssql_waits_signal_ratio_percent`
- `mssql_xp_cmdshell_enabled`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
