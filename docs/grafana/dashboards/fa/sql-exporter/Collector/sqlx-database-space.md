# Collector database_space

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-database-space.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Fast space ops view: DB-level used%/free/size + VLF hotspots. File-level detail is collapsed (expand to load). Avoids raw per-file timeseries.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-database-space` |
| فایل منبع | [`sqlx-database-space.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-database-space.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `space` |
| تعداد پنل‌ها | 23 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_database_space_size_mb{job="sql_exporter", instance=~"$instance"}, db)` |
| `type_desc` | File Type | `custom` | `ROWS,LOG,FILESTREAM,FULLTEXT` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | DBs Used >=85% | `stat` |
| 3 | DBs Used >=95% | `stat` |
| 4 | Files Near Max | `stat` |
| 5 | High VLF (>500) | `stat` |
| 6 | Percent Growth | `stat` |
| 7 | Tiny Growth | `stat` |
| 8 | Total Size | `stat` |
| 9 | Total Free | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top DBs by Used % | `bargauge` |
| 12 | Top Servers - DBs Used >=85% | `bargauge` |
| 13 | Top DBs by Size | `bargauge` |
| 14 | Trends (DB-level topk) | `row` |
| 15 | Used % - Top 15 Databases | `timeseries` |
| 16 | Free MB - Lowest 15 Databases | `timeseries` |
| 17 | Size MB - Top 15 Databases | `timeseries` |
| 18 | VLF - Top 15 Databases | `timeseries` |
| 19 | Per-Server Rollup | `row` |
| 20 | Servers - pressure / size / free | `table` |
| 21 | File Detail / Config Risks (expand to load) | `row` |
| 22 | Files Used >= 95% (topk 40) | `table` |
| 23 | Near Max Size >=85% (topk 40) | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 5, `stat`: 8, `table`: 3, `timeseries`: 4

## متریک‌های استفاده‌شده

- `FULLTEXT`
- `mssql_database_space_free_mb`
- `mssql_database_space_growth_mb`
- `mssql_database_space_is_percent_growth`
- `mssql_database_space_pct_of_max`
- `mssql_database_space_size_mb`
- `mssql_database_space_used_percent`
- `mssql_database_vlf_count`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
