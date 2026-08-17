# Collector index_fragmentation

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-index-fragmentation.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Index fragmentation ops view: KPI, rebuild/reorganize action queue, impact-ranked hotspots, and DB inventory. Collector samples LIMITED mode for large indexes (>=10k pages, >=30% frag) about every 6h.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-index-fragmentation` |
| فایل منبع | [`sqlx-index-fragmentation.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-index-fragmentation.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `indexes`, `maintenance` |
| تعداد پنل‌ها | 23 |
| بازهٔ تازه‌سازی | `30m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_index_fragmentation_percent{job="sql_exporter", instance=~"$instance"}, db)` |
| `index_type` | Index Type | `query` | `label_values(mssql_index_fragmentation_percent{job="sql_exporter", instance=~"$instance"}, index_type_desc)` |
| `min_frag` | Min Frag % | `custom` | `30,50,70` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Fragmented Indexes | `stat` |
| 3 | Servers Affected | `stat` |
| 4 | Databases Affected | `stat` |
| 5 | Max Frag % | `stat` |
| 6 | Rebuild >=70% | `stat` |
| 7 | Reorg 30-70% | `stat` |
| 8 | Total Size | `stat` |
| 9 | Worst Impact | `stat` |
| 10 | Action Queue (maintenance candidates) | `row` |
| 11 | Priority list - sort by Impact (Frag% x Pages); REBUILD when Frag >=70, else REORGANIZE | `table` |
| 12 | Hotspots | `row` |
| 13 | Top by Fragmentation % | `bargauge` |
| 14 | Top by Impact (Frag% x Pages) | `bargauge` |
| 15 | Top by Index Size (MB) | `bargauge` |
| 16 | Indexes by Type | `bargauge` |
| 17 | Trends (collector samples ~every 6h) | `row` |
| 18 | Max Fragmentation % by Server | `timeseries` |
| 19 | Fragmented Index Count by Server | `timeseries` |
| 20 | Top Indexes - Fragmentation % | `timeseries` |
| 21 | Top Indexes - Size (MB) | `timeseries` |
| 22 | Database Inventory | `row` |
| 23 | Per-database fragmentation summary | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 4, `row`: 5, `stat`: 8, `table`: 2, `timeseries`: 4

## متریک‌های استفاده‌شده

- `mssql_index_fragmentation_page_count`
- `mssql_index_fragmentation_percent`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
