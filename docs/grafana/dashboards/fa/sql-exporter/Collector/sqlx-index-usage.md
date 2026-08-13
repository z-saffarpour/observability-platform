# Collector index_usage

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-index-usage.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Index usage ops view: hot indexes (reads/seeks/scans/lookups), scan & write ratios, unused/write-heavy drop candidates, and per-DB rollup. Stats reset on restart. Not fragmentation.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-index-usage` |
| فایل منبع | [`sqlx-index-usage.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-index-usage.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `indexes` |
| تعداد پنل‌ها | 34 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_index_usage_reads{job="sql_exporter", instance=~"$instance"}, db)` |
| `candidate_kind` | Candidate | `custom` | `unused,write_heavy` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Servers | `stat` |
| 3 | DBs Tracked | `stat` |
| 4 | Hot Indexes | `stat` |
| 5 | Unused Indexes | `stat` |
| 6 | Stale Candidates | `stat` |
| 7 | Max Scan % | `stat` |
| 8 | Total Reads | `stat` |
| 9 | Total Updates | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top Indexes by Reads | `bargauge` |
| 12 | Top Indexes by Scan Ratio | `bargauge` |
| 13 | Top DBs by Unused Indexes | `bargauge` |
| 14 | Top Stale by Updates | `bargauge` |
| 15 | Trends | `row` |
| 16 | DB Reads (rollup) | `timeseries` |
| 17 | DB Updates (rollup) | `timeseries` |
| 18 | DB Scan Ratio | `timeseries` |
| 19 | DB Unused Index Count | `timeseries` |
| 20 | Top Hot Index Reads | `timeseries` |
| 21 | Top Hot Index Updates | `timeseries` |
| 22 | Hot Index Inventory (TOP by reads) | `row` |
| 23 | Hot indexes - seeks / scans / lookups / updates / ratios | `table` |
| 24 | Drop / Disable Review Candidates | `row` |
| 25 | Unused (reads=0) or write-heavy (updates >= 10x reads) nonclustered indexes | `table` |
| 26 | Stale Candidate Updates Trend | `timeseries` |
| 27 | Stale Write/Read Ratio Trend | `timeseries` |
| 28 | Per-Database Usage Rollup | `row` |
| 29 | Database rollup - activity + unused nonclustered count | `table` |
| 30 | Access Pattern Detail (seeks / scans / lookups) | `row` |
| 31 | Seeks | `timeseries` |
| 32 | Scans | `timeseries` |
| 33 | Lookups | `timeseries` |
| 34 | Updates (hot set) | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 4, `row`: 7, `stat`: 8, `table`: 3, `timeseries`: 12

## متریک‌های استفاده‌شده

- `mssql_index_usage_db_lookups`
- `mssql_index_usage_db_reads`
- `mssql_index_usage_db_scan_ratio`
- `mssql_index_usage_db_scans`
- `mssql_index_usage_db_seeks`
- `mssql_index_usage_db_tracked_indexes`
- `mssql_index_usage_db_unused_indexes`
- `mssql_index_usage_db_updates`
- `mssql_index_usage_lookup_ratio`
- `mssql_index_usage_lookups`
- `mssql_index_usage_reads`
- `mssql_index_usage_scan_ratio`
- `mssql_index_usage_scans`
- `mssql_index_usage_seeks`
- `mssql_index_usage_stale_reads`
- `mssql_index_usage_stale_updates`
- `mssql_index_usage_stale_write_read_ratio`
- `mssql_index_usage_updates`
- `mssql_index_usage_write_read_ratio`
- `mssql_up`
- `write_heavy`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
