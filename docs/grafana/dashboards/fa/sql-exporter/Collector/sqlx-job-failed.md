# Collector job_failed

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-job-failed.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

SQL Agent job failures ops view: sticky last-outcome fails, 1h/24h volume, recent failures with message snip, last-fail age/duration. Source: msdb sysjobhistory / sysjobservers.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-job-failed` |
| فایل منبع | [`sqlx-job-failed.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-job-failed.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `jobs`, `failures` |
| تعداد پنل‌ها | 27 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `job_name` | Job | `query` | `label_values(mssql_job_failed_count{job="sql_exporter", instance=~"$instance"}, job_name)` |
| `category` | Category | `query` | `label_values(mssql_job_failed_count{job="sql_exporter", instance=~"$instance"}, category_name)` |
| `enabled` | Enabled | `custom` | `1,0` |
| `window` | Window | `custom` | `1h,24h` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Failed 1h | `stat` |
| 3 | Failed 24h | `stat` |
| 4 | Sticky Failed | `stat` |
| 5 | Sticky Enabled | `stat` |
| 6 | Jobs Failed 24h | `stat` |
| 7 | Servers w/ Fail | `stat` |
| 8 | Recent Events | `stat` |
| 9 | Worst Job 24h | `stat` |
| 10 | Sticky Failures (sysjobservers.last_run_outcome = Failed) | `row` |
| 11 | Sticky Failed Jobs by Server | `timeseries` |
| 12 | Sticky Count by Server | `bargauge` |
| 13 | Currently Failed Jobs (sticky) | `table` |
| 14 | Failure Volume (1h / 24h windows) | `row` |
| 15 | Fleet Failed Totals | `timeseries` |
| 16 | Failed 24h by Server | `timeseries` |
| 17 | Top Failing Jobs | `bargauge` |
| 18 | Failures by Category | `bargauge` |
| 19 | Fail Count by Job (window filter) | `table` |
| 20 | Recent Failures (last 24h, TOP 50 / scrape, with message) | `row` |
| 21 | Longest Recent Fail Durations | `bargauge` |
| 22 | Recent Fail Count by Server | `bargauge` |
| 23 | Recent Fail Detail (message snip) | `table` |
| 24 | Last Failure Recency (jobs that failed in last 7 days) | `row` |
| 25 | Most Recent Fails (age) | `bargauge` |
| 26 | Longest Last-Fail Duration | `bargauge` |
| 27 | Last Fail Age + Duration | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 7, `row`: 5, `stat`: 8, `table`: 4, `timeseries`: 3

## متریک‌های استفاده‌شده

- `mssql_job_failed_count`
- `mssql_job_failed_current`
- `mssql_job_failed_last_age_seconds`
- `mssql_job_failed_last_duration_seconds`
- `mssql_job_failed_recent_duration_seconds`
- `mssql_job_failed_total`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
