# Collector backup

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-backup.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Backup age and coverage for Full/Diff/Log; encryption gaps pair with Security.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-backup` |
| فایل منبع | [`sqlx-backup.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-backup.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `backup` |
| تعداد پنل‌ها | 17 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Failed Jobs 24h | `stat` |
| 2 | Verify Fail 24h | `stat` |
| 3 | Damaged 7d | `stat` |
| 4 | Never Full | `stat` |
| 5 | Max Full Age | `stat` |
| 6 | No Enc Full | `stat` |
| 7 | Backup Age RW (Full 7d / Diff / Log) | `table` |
| 8 | Backup Age (Read-Only / Monthly) | `table` |
| 9 | Backup Size | `timeseries` |
| 10 | Throughput | `timeseries` |
| 11 | Compression Ratio | `timeseries` |
| 12 | Backup Age Trend | `timeseries` |
| 13 | Backup Job Failed 24h | `table` |
| 14 | Damaged 7d | `table` |
| 15 | Last Backup Size (Full / Diff / Log today) | `table` |
| 16 | Unencrypted Backup (Full / Diff / Log) | `table` |
| 17 | Backup Performance | `table` |

ترکیب نوع پنل‌ها: `stat`: 6, `table`: 7, `timeseries`: 4

## متریک‌های استفاده‌شده

- `mssql_alwayson_replica_db_synchronization_health`
- `mssql_backup_age_seconds`
- `mssql_backup_compression_ratio`
- `mssql_backup_damaged_7d`
- `mssql_backup_encryption_enabled`
- `mssql_backup_job_failed_24h`
- `mssql_backup_job_failed_total_24h`
- `mssql_backup_log_size_today_bytes`
- `mssql_backup_size_bytes`
- `mssql_backup_throughput_mb_s`
- `mssql_backup_verify_failed_count`
- `mssql_database_is_read_only`
- `mssql_restore_db_standby`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
