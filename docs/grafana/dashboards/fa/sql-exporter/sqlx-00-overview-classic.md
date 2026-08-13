# Overview Classic

[فهرست داشبوردها](../README.md) · [راهنمای Grafana](../../../../../grafana/README.md) · [English](../../en/sql-exporter/sqlx-00-overview-classic.md) · [مستندات فارسی Exporter](../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Classic compact fleet overview (earlier generation): core KPI + essential tables. Prefer Overview (canonical) for daily use.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-00-overview-classic` |
| فایل منبع | [`sqlx-00-overview-classic.json`](../../../../../grafana/dashboards/sql-exporter/sqlx-00-overview-classic.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `overview`, `classic` |
| تعداد پنل‌ها | 41 |
| بازهٔ تازه‌سازی | `5m` |
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
| 4 | Blocking | `stat` |
| 5 | JobFail | `stat` |
| 6 | بدون عنوان | `text` |
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

ترکیب نوع پنل‌ها: `row`: 2, `stat`: 18, `table`: 20, `text`: 1

## متریک‌های استفاده‌شده

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

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
