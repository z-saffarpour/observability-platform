# Collector cdc

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-cdc.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Change Data Capture ops: enablement, capture lag, retained LSN age, capture/cleanup jobs, trends. Collector: mssql_cdc_change_tracking (300s).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-cdc` |
| فایل منبع | [`sqlx-cdc.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-cdc.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `cdc` |
| تعداد پنل‌ها | 24 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_cdc_enabled{job="sql_exporter", instance=~"$instance"}, db)` |
| `lag_warn` | Lag Warn (s) | `custom` | `300,900,1800,3600` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Databases with is_cdc_enabled = 1. | `stat` |
| 3 | Sum of CDC capture instances / change tables. | `stat` |
| 4 | Seconds since CDC high endpoint was processed. | `stat` |
| 5 | CDC DBs with capture lag >= Lag Warn. | `stat` |
| 6 | CDC capture Agent jobs that are disabled. | `stat` |
| 7 | Continuous capture jobs that are not running. | `stat` |
| 8 | CDC cleanup Agent jobs that are disabled. | `stat` |
| 9 | Oldest retained capture-instance LSN age. | `stat` |
| 10 | CDC Inventory | `row` |
| 11 | CDC Databases | `table` |
| 12 | Top CDC Capture Lag | `bargauge` |
| 13 | Top Retained LSN Age | `bargauge` |
| 14 | CDC Capture / Cleanup Jobs | `row` |
| 15 | CDC Jobs (capture + cleanup) | `table` |
| 16 | CDC Capture Job Running | `timeseries` |
| 17 | CDC Cleanup Job Running | `timeseries` |
| 18 | Trends | `row` |
| 19 | CDC Capture Lag | `timeseries` |
| 20 | CDC Retained LSN Age | `timeseries` |
| 21 | CDC Capture Instances | `timeseries` |
| 22 | CDC Capture Polling Interval | `timeseries` |
| 23 | CDC Cleanup Retention (minutes) | `timeseries` |
| 24 | CDC Enabled (1/0) | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 2, `row`: 4, `stat`: 8, `table`: 2, `timeseries`: 8

## متریک‌های استفاده‌شده

- `mssql_cdc_capture_continuous_enabled`
- `mssql_cdc_capture_lag_seconds`
- `mssql_cdc_capture_polling_interval_seconds`
- `mssql_cdc_change_table_count`
- `mssql_cdc_cleanup_retention_minutes`
- `mssql_cdc_cleanup_threshold`
- `mssql_cdc_enabled`
- `mssql_cdc_job_enabled`
- `mssql_cdc_job_running`
- `mssql_cdc_retained_lsn_age_seconds`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
