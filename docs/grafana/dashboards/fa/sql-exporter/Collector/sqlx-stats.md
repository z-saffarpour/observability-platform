# Collector stats

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-stats.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Statistics ops view: KPIs, modification/age/sample hotspots, filtered UPDATE STATISTICS queue, inventory, and per-DB rollup. Collector flags mod>=1000 OR age>7d OR NULL last_updated. TOP 80 sample - not full inventory.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-stats` |
| فایل منبع | [`sqlx-stats.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-stats.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `stats` |
| تعداد پنل‌ها | 30 |
| بازهٔ تازه‌سازی | `10m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_stats_age_seconds{job="sql_exporter", instance=~"$instance"}, db)` |
| `min_modifications` | Min Modifications | `custom` | `0,1000,10000,100000,1000000` |
| `min_age_days` | Min Age (days) | `custom` | `0,7,14,30,90` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Servers | `stat` |
| 3 | Databases | `stat` |
| 4 | Sampled Stats | `stat` |
| 5 | Total Stale | `stat` |
| 6 | Max Age | `stat` |
| 7 | Max Modifications | `stat` |
| 8 | Low Sample (<10%) | `stat` |
| 9 | DBs with Stale | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top by Modifications | `bargauge` |
| 12 | Top by Age | `bargauge` |
| 13 | Top DBs by Stale Count | `bargauge` |
| 14 | Worst Sample % (bottom 12) | `bargauge` |
| 15 | Action Queue (filter with Min Modifications / Min Age days) | `row` |
| 16 | UPDATE STATISTICS candidates - validate off-peak / large tables before running | `table` |
| 17 | Trends | `row` |
| 18 | Top Modifications | `timeseries` |
| 19 | Top Age | `timeseries` |
| 20 | Stale Count by Database | `timeseries` |
| 21 | Worst Sample % | `timeseries` |
| 22 | Statistics Inventory (TOP sample) | `row` |
| 23 | All sampled stale/changed statistics (TOP 80 fleet-wide) | `table` |
| 24 | Per-Database Rollup | `row` |
| 25 | Database rollup - stale pressure and sampling quality | `table` |
| 26 | Row / Sampling Detail | `row` |
| 27 | Top Rows (table size proxy) | `timeseries` |
| 28 | Top Rows Sampled | `timeseries` |
| 29 | Sampled Stats Count by DB | `timeseries` |
| 30 | Modifications Sum by DB | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 4, `row`: 7, `stat`: 8, `table`: 3, `timeseries`: 8

## متریک‌های استفاده‌شده

- `mssql_stats_age_seconds`
- `mssql_stats_modification_counter`
- `mssql_stats_rows`
- `mssql_stats_rows_sampled`
- `mssql_stats_sample_percent`
- `mssql_stats_stale_count`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
