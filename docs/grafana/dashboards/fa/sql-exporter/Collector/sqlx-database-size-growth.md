# Collector database_size_growth

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-database-size-growth.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Database capacity & growth: total data/log, 24h/7d growth deltas, top growers, DB/file inventory, recovery model, percent-growth risks. Cross-link Database Space (used%) and Autogrowth (events).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-database-size-growth` |
| فایل منبع | [`sqlx-database-size-growth.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-database-size-growth.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `growth`, `capacity` |
| تعداد پنل‌ها | 26 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_database_data_size_mb{job="sql_exporter", instance=~"$instance"}, db)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Capacity / Growth KPI | `row` |
| 2 | Total Data | `stat` |
| 3 | Total Log | `stat` |
| 4 | Total Size | `stat` |
| 5 | Databases | `stat` |
| 6 | Data +24h | `stat` |
| 7 | Log +24h | `stat` |
| 8 | Data +7d | `stat` |
| 9 | Fast Growers (7d>1GB) | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top Databases by Total Size | `bargauge` |
| 12 | Top Data Growth (7d) | `bargauge` |
| 13 | Top Servers by Total Size | `bargauge` |
| 14 | Database Inventory | `row` |
| 15 | Databases - size + growth (24h / 7d) | `table` |
| 16 | Trends | `row` |
| 17 | Data Size by Database | `timeseries` |
| 18 | Log Size by Database | `timeseries` |
| 19 | Fleet Total (Data + Log) | `timeseries` |
| 20 | Data Growth Rate (MB/day) | `timeseries` |
| 21 | Per-Server Rollup | `row` |
| 22 | Servers - capacity + 7d growth | `table` |
| 23 | Files and Growth Settings | `row` |
| 24 | File inventory (size + autogrowth setting) | `table` |
| 25 | Percent Growth Enabled (risky) | `table` |
| 26 | File Size Trend | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 4, `timeseries`: 5

## متریک‌های استفاده‌شده

- `mssql_database_data_size_mb`
- `mssql_database_file_size_mb`
- `mssql_database_log_size_mb`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
