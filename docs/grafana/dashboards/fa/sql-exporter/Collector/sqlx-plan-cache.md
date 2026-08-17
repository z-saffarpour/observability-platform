# Collector plan_cache

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-plan-cache.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Plan cache ops view: total size and plan count, single-use (ad-hoc pollution) ratio, per-database and object-type breakdown, fleet inventory, and alert-aligned pollution watch. Collector: mssql_plan_cache (120s). Per-db panels need enriched collector redeploy.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-plan-cache` |
| فایل منبع | [`sqlx-plan-cache.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-plan-cache.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `plan_cache` |
| تعداد پنل‌ها | 36 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `objtype` | Object Type | `query` | `label_values(mssql_plan_cache_size_mb{job="sql_exporter", instance=~"$instance"}, objtype)` |
| `db` | Database | `query` | `label_values(mssql_plan_cache_db_size_mb{job="sql_exporter", instance=~"$instance"}, db)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Total Cache | `stat` |
| 3 | Cached Plans | `stat` |
| 4 | Single-Use % | `stat` |
| 5 | Single-Use Plans | `stat` |
| 6 | Adhoc Size | `stat` |
| 7 | Adhoc % Cache | `stat` |
| 8 | Avg Plan KB | `stat` |
| 9 | Servers >50% | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top Servers by Cache Size | `bargauge` |
| 12 | Top Servers by Single-Use % | `bargauge` |
| 13 | Size by Object Type | `bargauge` |
| 14 | Single-Use Plans by Type | `bargauge` |
| 15 | Trends | `row` |
| 16 | Total Cache Size | `timeseries` |
| 17 | Total Cached Plans | `timeseries` |
| 18 | Single-Use Ratio | `timeseries` |
| 19 | Size by Object Type (stacked) | `timeseries` |
| 20 | Plan Count by Object Type | `timeseries` |
| 21 | Single-Use Ratio by Type | `timeseries` |
| 22 | Avg Plan Size by Type (KB) | `timeseries` |
| 23 | Fleet Inventory (per server & database) | `row` |
| 24 | Server + database rollup - size, pollution, ad-hoc pressure | `table` |
| 25 | Server Rollup Summary | `row` |
| 26 | Server-only summary (collapsed) | `table` |
| 27 | Top Databases by Cache Size | `bargauge` |
| 28 | Object Type Breakdown | `row` |
| 29 | Per object type - size, count, reuse, share of cache | `table` |
| 30 | Pollution Watch (>50% single-use) | `row` |
| 31 | Servers breaching alert threshold | `table` |
| 32 | Adhoc types with highest single-use ratio | `table` |
| 33 | Databases breaching 50% single-use | `table` |
| 34 | Single-Use Count Trend | `timeseries` |
| 35 | Cache Growth Rate (MB/h) | `timeseries` |
| 36 | Top Database Cache Size Trend | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 5, `row`: 7, `stat`: 8, `table`: 6, `timeseries`: 10

## متریک‌های استفاده‌شده

- `mssql_plan_cache_db_adhoc_single_use_ratio`
- `mssql_plan_cache_db_adhoc_size_mb`
- `mssql_plan_cache_db_plan_count`
- `mssql_plan_cache_db_single_use_count`
- `mssql_plan_cache_db_single_use_ratio`
- `mssql_plan_cache_db_size_mb`
- `mssql_plan_cache_plan_count`
- `mssql_plan_cache_single_use_count`
- `mssql_plan_cache_single_use_ratio`
- `mssql_plan_cache_size_mb`
- `mssql_plan_cache_total_plans`
- `mssql_plan_cache_total_size_mb`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
