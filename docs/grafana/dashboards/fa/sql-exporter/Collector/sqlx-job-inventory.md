# Collector job_inventory

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-job-inventory.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

SQL Agent job inventory: failed-at / next-run date-time, overdue schedule, fleet counts, activity monitor. Snapshot collector (15m).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-job-inventory` |
| فایل منبع | [`sqlx-job-inventory.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-job-inventory.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `jobs` |
| تعداد پنل‌ها | 29 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `category` | Category | `query` | `label_values(mssql_job_enabled{job="sql_exporter", instance=~"${instance:regex}"}, category_name)` |
| `enabled` | Enabled | `custom` | `1,0` |
| `overdue_sec` | Overdue sec | `custom` | `60,300,900,3600,86400` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Total Jobs | `stat` |
| 3 | True | `stat` |
| 4 | False | `stat` |
| 5 | Failed Last | `stat` |
| 6 | Succeeded | `stat` |
| 7 | Overdue | `stat` |
| 8 | Cancel/Unknown | `stat` |
| 9 | Servers | `stat` |
| 10 | Attention - Failed last run & overdue schedule | `row` |
| 11 | Failed Last Run by Server | `bargauge` |
| 12 | Overdue Jobs by Server | `bargauge` |
| 13 | Failed Jobs - last fail time & next run | `table` |
| 14 | Overdue Schedule - next run already passed | `table` |
| 15 | Upcoming Schedule - next run after now | `table` |
| 16 | Fleet inventory - counts by server / category | `row` |
| 17 | True vs False Jobs by Server | `timeseries` |
| 18 | Last-Run Outcome Counts (fleet) | `timeseries` |
| 19 | Top Categories (job count) | `bargauge` |
| 20 | Top Servers (total jobs) | `bargauge` |
| 21 | Schedule - next run (date + time) | `row` |
| 22 | Most Overdue - next run date/time | `table` |
| 23 | Upcoming Next Run (next 24h) - date/time | `table` |
| 24 | Activity Monitor - last run / end / next run | `row` |
| 25 | Longest Last Run Duration | `bargauge` |
| 26 | Longest Duration by Category | `bargauge` |
| 27 | Activity Monitor (last run / end / next run / duration) | `table` |
| 28 | Full inventory (filter Server/Category/Enabled first) | `row` |
| 29 | Job Inventory (last run / end / next run / duration / outcome) | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 6, `row`: 6, `stat`: 8, `table`: 7, `timeseries`: 2

## متریک‌های استفاده‌شده

- `mssql_job_activity_monitor`
- `mssql_job_count`
- `mssql_job_enabled`
- `mssql_job_last_run_outcome`
- `mssql_job_next_run_age_seconds`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
