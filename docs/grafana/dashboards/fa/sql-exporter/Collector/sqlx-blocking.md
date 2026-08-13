# Collector blocking

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-blocking.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Blocking / head-blocker ops view: fleet KPIs, wait trends, who is blocking whom, statement snippets, and breakdowns by wait type / DB / program. Collector: mssql_blocking (30s).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-blocking` |
| فایل منبع | [`sqlx-blocking.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-blocking.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `blocking` |
| تعداد پنل‌ها | 26 |
| بازهٔ تازه‌سازی | `30s` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Blocked Sessions | `stat` |
| 3 | Head Blockers | `stat` |
| 4 | Servers Affected | `stat` |
| 5 | Max Wait | `stat` |
| 6 | Blocked sessions waiting longer than 30 seconds. | `stat` |
| 7 | Waits > 5m | `stat` |
| 8 | Max Head Elapsed | `stat` |
| 9 | Distinct Wait Types | `stat` |
| 10 | Trends | `row` |
| 11 | Blocked Sessions | `timeseries` |
| 12 | Head Blockers | `timeseries` |
| 13 | Max Wait Time | `timeseries` |
| 14 | Max Head Blocker Elapsed | `timeseries` |
| 15 | Fleet - who is blocking? | `row` |
| 16 | Servers with Blocking (fleet) | `table` |
| 17 | Head Blockers - investigate / kill first | `row` |
| 18 | Head Blockers (victims / elapsed / CPU / statement) | `table` |
| 19 | Blocked Sessions - who is waiting? | `row` |
| 20 | Blocked Sessions (wait + elapsed + statement) | `table` |
| 21 | Breakdowns | `row` |
| 22 | By Wait Type | `table` |
| 23 | By Database | `table` |
| 24 | By Program | `table` |
| 25 | Max Wait by Wait Type | `table` |
| 26 | Max Wait by Database | `table` |

ترکیب نوع پنل‌ها: `row`: 6, `stat`: 8, `table`: 8, `timeseries`: 4

## متریک‌های استفاده‌شده

- `mssql_blocking_count`
- `mssql_blocking_elapsed_ms`
- `mssql_blocking_head_count`
- `mssql_blocking_wait_ms`
- `mssql_head_blocker_cpu_ms`
- `mssql_head_blocker_elapsed_ms`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
