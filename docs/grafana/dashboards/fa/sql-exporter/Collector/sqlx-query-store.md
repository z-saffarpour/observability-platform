# Collector query_store

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-query-store.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Query Store ops view: QS enablement, fleet rollup, last_execution_time per query_id, and top queries by avg duration / CPU / executions (6h QS window, 300s scrape). Collector: mssql_query_store.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-query-store` |
| فایل منبع | [`sqlx-query-store.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-query-store.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `query_store` |
| تعداد پنل‌ها | 31 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_query_store_enabled{job="sql_exporter", instance=~"${instance:regex}"}, db)` |
| `over_avg_factor` | Over Avg x | `custom` | `1.2,1.5,2,3` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI (Query Store - last 6h window) | `row` |
| 2 | User databases with Query Store ON. | `stat` |
| 3 | QS Disabled DBs | `stat` |
| 4 | Tracked Queries | `stat` |
| 5 | Worst average duration among tracked queries. | `stat` |
| 6 | Worst average CPU among tracked queries. | `stat` |
| 7 | Sum of execution counts in the QS window. | `stat` |
| 8 | Newest Last Exec | `stat` |
| 9 | Oldest Last Exec | `stat` |
| 10 | Hotspots (right now) | `row` |
| 11 | Top DBs - Max Avg Duration | `bargauge` |
| 12 | Top Queries - Oldest Last Exec | `bargauge` |
| 13 | Top Objects - Avg Duration | `bargauge` |
| 14 | Trends (aggregated - safe for 300s scrape) | `row` |
| 15 | Max Avg Duration by Server | `timeseries` |
| 16 | Max Avg CPU by Server | `timeseries` |
| 17 | Oldest Last Exec Age by Server | `timeseries` |
| 18 | Newest Last Exec Age by Server | `timeseries` |
| 19 | Fleet rollup | `row` |
| 20 | Servers - QS coverage / hotspots / last exec age | `table` |
| 21 | Query Store enablement | `row` |
| 22 | All User Databases - QS Status | `table` |
| 23 | QS Disabled - Action List | `table` |
| 24 | Top queries - investigate (last 6h QS window) | `row` |
| 25 | Top Queries - Duration / CPU / Exec / Last Executed / Age / Statement | `table` |
| 26 | Ranked views | `row` |
| 27 | Top by Avg Duration | `table` |
| 28 | Top by Avg CPU | `table` |
| 29 | Top by Executions | `table` |
| 30 | Regressions vs fleet average | `row` |
| 31 | Queries Slower than Fleet Avg x Factor | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 8, `stat`: 8, `table`: 8, `timeseries`: 4

## متریک‌های استفاده‌شده

- `mssql_query_store_enabled`
- `mssql_query_store_top_cpu_ms`
- `mssql_query_store_top_duration_ms`
- `mssql_query_store_top_execution_count`
- `mssql_query_store_top_last_execution_age_seconds`
- `mssql_query_store_top_last_execution_unix`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
