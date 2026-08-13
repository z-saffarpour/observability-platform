# Collector restore

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-restore.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Restore / log-shipping ops view: Difference Restore inventory, lag by type (Full/Diff/Log), RPO gap trends, failed restore jobs, standby/state. Collector: mssql_restore.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-restore` |
| فایل منبع | [`sqlx-restore.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-restore.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `restore`, `log_shipping` |
| تعداد پنل‌ها | 24 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_restore_lag_seconds{job="sql_exporter", instance=~"$instance"}, db)` |
| `lag_warn` | Lag Warn (s) | `custom` | `300,900,1800,3600,7200` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Max Restore Lag | `stat` |
| 3 | Hot Lag (>= warn) | `stat` |
| 4 | Failed Jobs 24h | `stat` |
| 5 | DBs Tracked | `stat` |
| 6 | Standby DBs | `stat` |
| 7 | Restoring DBs | `stat` |
| 8 | Database State / Standby | `row` |
| 9 | Standby + State | `table` |
| 10 | Last Restore Inventory (Difference Restore) | `row` |
| 11 | Restore Status - Last Applied Backup per DB | `table` |
| 12 | Lag by Backup Type (Full / Diff / Log) | `row` |
| 13 | Difference Restore by Type | `table` |
| 14 | Trends | `row` |
| 15 | Restore Lag (Difference Restore) | `timeseries` |
| 16 | Restore Age (since restore_date) | `timeseries` |
| 17 | Log Lag by DB | `timeseries` |
| 18 | RPO Gap Trend | `timeseries` |
| 19 | Top Restore Lag (now) | `bargauge` |
| 20 | Top Log Lag (now) | `bargauge` |
| 21 | Restore Job Failures (24h) | `row` |
| 22 | Failed Restore Jobs by Server | `timeseries` |
| 23 | Top Failed Restore Jobs | `bargauge` |
| 24 | Failed Restore Jobs (detail) | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 6, `stat`: 6, `table`: 4, `timeseries`: 5

## متریک‌های استفاده‌شده

- `mssql_restore_age_seconds`
- `mssql_restore_backup_size_bytes`
- `mssql_restore_backup_unix`
- `mssql_restore_db_standby`
- `mssql_restore_db_state`
- `mssql_restore_gap_to_rpo_seconds`
- `mssql_restore_job_executions_24h`
- `mssql_restore_job_failed_24h`
- `mssql_restore_job_failed_total_24h`
- `mssql_restore_lag_seconds`
- `mssql_restore_last_by_type_lag_seconds`
- `mssql_restore_last_unix`
- `mssql_restore_throughput_mb_s`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
