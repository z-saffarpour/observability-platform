# Overview

[فهرست داشبوردها](../README.md) · [راهنمای Grafana](../../../../../grafana/README.md) · [English](../../en/sql-exporter/sqlx-00-overview.md) · [مستندات فارسی Exporter](../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Canonical fleet overview: KPI strip + full inventory tables (state, HA, backup, capacity, security, replication, CDC). Drill into collectors via Related links.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-00-overview` |
| فایل منبع | [`sqlx-00-overview.json`](../../../../../grafana/dashboards/sql-exporter/sqlx-00-overview.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `overview`, `canonical` |
| تعداد پنل‌ها | 98 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `over_avg_factor` | Over Avg x | `custom` | `1.2,1.5,2,3` |

## پنل‌ها

| ردیف | عنوان | نوع |
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
| 38 | AlwaysOn Lag (data loss / redo / queue) | `table` |
| 39 | CPU / Log | `row` |
| 40 | CPU % | `table` |
| 41 | Log Used % | `table` |
| 42 | Low PLE < 300s | `table` |
| 43 | HA / Backup / Integrity / Long Jobs | `row` |
| 44 | Backup Age RW (Full 7d / Diff / Log) | `table` |
| 45 | Backup Age RO (Full monthly) | `table` |
| 46 | Restore Lag | `table` |
| 47 | Suspect Pages | `table` |
| 48 | CHECKDB Age | `table` |
| 49 | Jobs Running | `table` |
| 50 | Capacity / Autogrowth / IO | `row` |
| 51 | DB Space Used % | `table` |
| 52 | Autogrowth 24h | `table` |
| 53 | Read Latency | `table` |
| 54 | Write Latency >= 20ms | `table` |
| 55 | Failed Jobs / SSIS | `row` |
| 56 | Failed Jobs (24h) | `table` |
| 57 | SSIS Failed (24h) | `table` |
| 58 | Security / ERRORLOG | `row` |
| 59 | Failed Logins (60m) | `table` |
| 60 | ERRORLOG Signals | `table` |
| 61 | xp_cmdshell Enabled Hosts | `table` |
| 62 | Orphaned Users | `table` |
| 63 | Unexpected Logins | `table` |
| 64 | Privileged Sessions | `table` |
| 65 | TDE Off (user DBs) | `table` |
| 66 | Unencrypted Full Backup | `table` |
| 67 | TempDB / Deadlocks | `row` |
| 68 | TempDB Used MB | `table` |
| 69 | Deadlocks /h | `table` |
| 70 | Jobs Over Avg | `table` |
| 71 | AG Sync Flaps 24h > 0 | `table` |
| 72 | AG Send / Suspended / Seeding | `row` |
| 73 | Waits / Scheduler / Locks / DB State | `row` |
| 74 | Volume Free | `row` |
| 75 | Replication | `row` |
| 76 | CDC / Change Tracking | `row` |
| 77 | AG Send Queue | `table` |
| 78 | AG Suspended | `table` |
| 79 | AG Seeding % | `table` |
| 80 | Signal / Nonbenign Waits % | `table` |
| 81 | Top Wait Class (rate) | `table` |
| 82 | Scheduler Pressure | `table` |
| 83 | Locks Waiting | `table` |
| 84 | DB not ONLINE | `table` |
| 85 | Volume Free % | `table` |
| 86 | Replication Dist Latency | `table` |
| 87 | Replication Pending Cmds | `table` |
| 88 | CDC Capture Lag | `table` |
| 89 | Change Tracking Enabled | `table` |
| 90 | Instance Configuration | `row` |
| 91 | RestartPend | `stat` |
| 92 | IFIOff | `stat` |
| 93 | CfgDrift | `stat` |
| 94 | PrioBoost | `stat` |
| 95 | Restart Pending | `table` |
| 96 | IFI Disabled | `table` |
| 97 | Priority Boost ON | `table` |
| 98 | Lightweight Pooling ON | `table` |

ترکیب نوع پنل‌ها: `row`: 14, `stat`: 33, `table`: 51

## متریک‌های استفاده‌شده

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

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
