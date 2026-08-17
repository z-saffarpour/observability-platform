# Collector buffer_pool

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-buffer-pool.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Buffer pool health: PLE (incl. NUMA), cache hit %, physical page I/O rates, lazy writes / free-list stalls, fleet snapshot, and per-database buffer occupancy. /sec counters use rate([5m]).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-buffer-pool` |
| فایل منبع | [`sqlx-buffer-pool.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-buffer-pool.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `buffer_pool` |
| تعداد پنل‌ها | 30 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_buffer_pool_database_pages{job="sql_exporter", instance=~"${instance:regex}"}, db)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Low PLE (<300s) | `stat` |
| 3 | Min PLE | `stat` |
| 4 | Median PLE | `stat` |
| 5 | Cache Hit % | `stat` |
| 6 | Max Page Reads/s | `stat` |
| 7 | Max Page Writes/s | `stat` |
| 8 | Max Lazy Writes/s | `stat` |
| 9 | Servers w/ Stalls | `stat` |
| 10 | PLE & Buffer Cache | `row` |
| 11 | Page Life Expectancy (_Total) | `timeseries` |
| 12 | PLE by NUMA Node | `timeseries` |
| 13 | Buffer Cache Hit Ratio % | `timeseries` |
| 14 | Buffer Pool Size (Database vs Target) | `timeseries` |
| 15 | Physical I/O (rate of cumulative counters) | `row` |
| 16 | Page Reads /s | `timeseries` |
| 17 | Page Writes /s | `timeseries` |
| 18 | Readahead Pages /s | `timeseries` |
| 19 | Page Lookups /s | `timeseries` |
| 20 | Memory Pressure Signals | `row` |
| 21 | Lazy Writes /s | `timeseries` |
| 22 | Free List Stalls /s | `timeseries` |
| 23 | Checkpoint Pages /s | `timeseries` |
| 24 | Fleet Snapshot | `row` |
| 25 | Buffer Pool Health by Server | `table` |
| 26 | Low PLE Servers (< 300s) | `table` |
| 27 | Buffer usage by database | `row` |
| 28 | Cached Size by Database | `table` |
| 29 | Dirty Size by Database | `table` |
| 30 | Buffer Occupancy by Database | `table` |

ترکیب نوع پنل‌ها: `row`: 6, `stat`: 8, `table`: 5, `timeseries`: 11

## متریک‌های استفاده‌شده

- `mssql_buffer_pool_cache_hit_ratio`
- `mssql_buffer_pool_counter`
- `mssql_buffer_pool_database_dirty_pages`
- `mssql_buffer_pool_database_pages`
- `mssql_buffer_pool_page_life_expectancy`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
