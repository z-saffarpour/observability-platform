# Collector heavy_queries

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-heavy-queries.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

نمای عملیاتی queryهای سنگین: sessionهای زنده از `mssql_heavy_queries` با فاصله ۶۰ ثانیه و رتبه‌بندی تاریخی CPU، duration و grant از `mssql_plan_cache_hotspots` با فاصله ۵ دقیقه دریافت می‌شود.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-heavy-queries` |
| فایل منبع | [`sqlx-heavy-queries.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-heavy-queries.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `queries`, `heavy_queries` |
| تعداد پنل‌ها | 42 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_requests_elapsed_ms{job="sql_exporter", instance=~"${instance:regex}"}, db)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI (sessions - excludes background workers) | `row` |
| 2 | Active Sessions | `stat` |
| 3 | Suspended | `stat` |
| 4 | Currently running (on CPU) heavy sessions. | `stat` |
| 5 | Max Elapsed | `stat` |
| 6 | Max CPU | `stat` |
| 7 | Max Grant | `stat` |
| 8 | Long > 2m | `stat` |
| 9 | Hot Waits | `stat` |
| 10 | Trends (aggregated - never raw sessions) | `row` |
| 11 | Active Sessions by Server | `timeseries` |
| 12 | Max Elapsed by Server | `timeseries` |
| 13 | Max CPU by Server | `timeseries` |
| 14 | Max Memory Grant by Server | `timeseries` |
| 15 | Hotspots | `row` |
| 16 | Top Servers - Active Sessions | `bargauge` |
| 17 | Top Wait Types (sessions) | `bargauge` |
| 18 | Top Databases (sessions) | `bargauge` |
| 19 | Fleet rollup | `row` |
| 20 | Servers - sessions / elapsed / CPU / grant / noise | `table` |
| 21 | Active sessions now (investigate) | `row` |
| 22 | Active Heavy Sessions (elapsed / CPU / grant / reads / statement) | `table` |
| 23 | Contention waits (locks / IO / CPU / memory) | `row` |
| 24 | Hot Wait Sessions (LCK_ / PAGEIOLATCH_ / RESOURCE_SEMAPHORE / ...) | `table` |
| 25 | Breakdowns | `row` |
| 26 | By Wait Type | `table` |
| 27 | By Database | `table` |
| 28 | By Program | `table` |
| 29 | By Login | `table` |
| 30 | Plan cache - CPU hotspots (historical) | `row` |
| 31 | Top by Total CPU (worker ms) + avg elapsed + executions | `table` |
| 32 | Plan cache - duration hotspots | `row` |
| 33 | Top by Total Elapsed (wall-clock) + avg duration + executions | `table` |
| 34 | Plan cache - large memory grants (>= 1 GB) | `row` |
| 35 | Top by Max Memory Grant (MB) + used + executions | `table` |
| 36 | Background / system workers (usually noise - expand if needed) | `row` |
| 37 | Background Count | `stat` |
| 38 | All Heavy (incl. bg) | `stat` |
| 39 | Servers w/ Sessions | `stat` |
| 40 | Worst background worker elapsed (informational). | `stat` |
| 41 | Background by Wait Type | `table` |
| 42 | Background by Server | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 11, `stat`: 12, `table`: 12, `timeseries`: 4

## متریک‌های استفاده‌شده

- `mssql_requests_cpu_ms`
- `mssql_requests_elapsed_ms`
- `mssql_requests_granted_memory_mb`
- `mssql_requests_logical_reads`
- `mssql_top_query_avg_duration_ms`
- `mssql_top_query_avg_elapsed_ms`
- `mssql_top_query_elapsed_execution_count`
- `mssql_top_query_execution_count`
- `mssql_top_query_grant_execution_count`
- `mssql_top_query_max_grant_mb`
- `mssql_top_query_max_used_grant_mb`
- `mssql_top_query_total_elapsed_ms`
- `mssql_top_query_total_worker_ms`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
