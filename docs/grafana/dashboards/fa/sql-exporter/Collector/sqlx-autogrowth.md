# Collector autogrowth

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-autogrowth.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Autogrowth/shrink from default trace (24h): event counts, grown MB, duration, hotspots, plus file growth config risks (percent growth, tiny increments, near max size).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-autogrowth` |
| فایل منبع | [`sqlx-autogrowth.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-autogrowth.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `autogrowth` |
| تعداد پنل‌ها | 24 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_autogrowth_events_24h{job="sql_exporter", instance=~"$instance"}, db)` |
| `event_type` | Event | `custom` | `data_growth,log_growth,data_shrink,log_shrink` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI (last 24h from default trace) | `row` |
| 2 | Growth Events | `stat` |
| 3 | Servers w/ Growth | `stat` |
| 4 | Data Growth | `stat` |
| 5 | Log Growth | `stat` |
| 6 | Shrink Events | `stat` |
| 7 | Hot Files (>50) | `stat` |
| 8 | Growth MB | `stat` |
| 9 | Max Duration | `stat` |
| 10 | Hotspots | `row` |
| 11 | Growth / Shrink by File (24h) | `table` |
| 12 | Top Servers by Growth Events | `bargauge` |
| 13 | Trends | `row` |
| 14 | Events by Type (fleet) | `timeseries` |
| 15 | Growth MB by File | `timeseries` |
| 16 | Top DB Event Counts | `timeseries` |
| 17 | Max Growth Duration (ms) | `timeseries` |
| 18 | Per Database Rollup | `row` |
| 19 | Database - growth / shrink / MB (24h) | `table` |
| 20 | File Growth Config Risks (from database_space) | `row` |
| 21 | Percent Growth Enabled (fragmentation / unpredictable growth) | `table` |
| 22 | Tiny Fixed Growth (<64 MB) - frequent autogrowth risk | `table` |
| 23 | Near Max Size (>=85%) - autogrowth may fail soon | `table` |
| 24 | Growth Settings (all files in filter) | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 1, `row`: 5, `stat`: 8, `table`: 6, `timeseries`: 4

## متریک‌های استفاده‌شده

- `log_shrink`
- `mssql_autogrowth_avg_duration_ms_24h`
- `mssql_autogrowth_events_24h`
- `mssql_autogrowth_growth_mb_24h`
- `mssql_autogrowth_growth_mb_total_24h`
- `mssql_autogrowth_last_age_seconds`
- `mssql_autogrowth_max_duration_ms_24h`
- `mssql_autogrowth_shrink_total_24h`
- `mssql_autogrowth_total_24h`
- `mssql_database_space_growth_mb`
- `mssql_database_space_is_percent_growth`
- `mssql_database_space_pct_of_max`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
