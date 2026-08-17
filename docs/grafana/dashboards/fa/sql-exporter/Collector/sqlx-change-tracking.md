# Collector change_tracking

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-change-tracking.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Change Tracking ops: enablement, retention, auto-cleanup, tracked tables, current/min-valid version and version window. Collector: mssql_cdc_change_tracking (300s).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-change-tracking` |
| فایل منبع | [`sqlx-change-tracking.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-change-tracking.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `change_tracking` |
| تعداد پنل‌ها | 21 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_change_tracking_enabled{job="sql_exporter", instance=~"$instance"}, db)` |
| `window_warn` | Window Warn | `custom` | `1000,5000,10000,50000` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Databases with Change Tracking enabled. | `stat` |
| 3 | Sum of tables enabled for Change Tracking. | `stat` |
| 4 | Largest current - min_valid version gap. | `stat` |
| 5 | CT DBs with version window >= Window Warn. | `stat` |
| 6 | CT-enabled DBs with automatic cleanup disabled. | `stat` |
| 7 | CT On, 0 Tables | `stat` |
| 8 | Highest tracked-table count on a single DB. | `stat` |
| 9 | Min Retention | `stat` |
| 10 | Change Tracking Inventory | `row` |
| 11 | Change Tracking Databases | `table` |
| 12 | Top CT Tracked Tables | `bargauge` |
| 13 | Top CT Version Window | `bargauge` |
| 14 | Trends | `row` |
| 15 | CT Version Window | `timeseries` |
| 16 | CT Current Version | `timeseries` |
| 17 | CT Min Valid Version | `timeseries` |
| 18 | CT Tracked Tables | `timeseries` |
| 19 | CT Retention (configured) | `timeseries` |
| 20 | CT Auto Cleanup Enabled | `timeseries` |
| 21 | CT Enabled (1/0) | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 2, `row`: 3, `stat`: 8, `table`: 1, `timeseries`: 7

## متریک‌های استفاده‌شده

- `mssql_change_tracking_auto_cleanup_enabled`
- `mssql_change_tracking_current_version`
- `mssql_change_tracking_enabled`
- `mssql_change_tracking_min_valid_version`
- `mssql_change_tracking_retention_seconds`
- `mssql_change_tracking_table_count`
- `mssql_change_tracking_version_window`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
