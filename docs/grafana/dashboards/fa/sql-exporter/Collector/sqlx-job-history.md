# Collector job_history

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-job-history.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

SQL Agent job history ops view: failure KPIs, recent fail messages, last outcome snapshot, duration vs 24h success average (Over Avg). Collector: mssql_job_history (sysjobhistory step_id=0).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-job-history` |
| فایل منبع | [`sqlx-job-history.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-job-history.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `jobs`, `job_history` |
| تعداد پنل‌ها | 28 |
| بازهٔ تازه‌سازی | `2m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `job_name` | Job | `query` | `label_values(mssql_job_history_last_status{job="sql_exporter", instance=~"$instance"}, job_name)` |
| `window` | Window | `custom` | `1h,24h` |
| `over_avg_factor` | Over Avg x | `custom` | `1.2,1.5,2,3` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Failed (window) | `stat` |
| 3 | Failed 1h | `stat` |
| 4 | Failed 24h | `stat` |
| 5 | Last = Failed | `stat` |
| 6 | Success % | `stat` |
| 7 | Over Avg | `stat` |
| 8 | Jobs Tracked | `stat` |
| 9 | Canceled (win) | `stat` |
| 10 | Failures (sysjobhistory step_id=0) | `row` |
| 11 | Failed Outcomes by Server | `timeseries` |
| 12 | Runs by Status (fleet) | `timeseries` |
| 13 | Top Failed Jobs (window) | `bargauge` |
| 14 | Servers with Most Failures | `bargauge` |
| 15 | Recent Failures (24h TOP 40) | `table` |
| 16 | Last Outcome Snapshot | `row` |
| 17 | Last Status + Run At + Duration + Age | `table` |
| 18 | Jobs Whose Last Run Failed | `table` |
| 19 | Failed Last Run - Duration + Age + Run At | `table` |
| 20 | Duration vs 24h Success Average | `row` |
| 21 | Top Last Durations | `bargauge` |
| 22 | Over Avg Ratio (jobs above factor) | `bargauge` |
| 23 | Jobs Over Avg (last duration) | `table` |
| 24 | Avg Success Duration 24h (sample) | `timeseries` |
| 25 | Run Volume | `row` |
| 26 | Succeeded Runs by Server | `timeseries` |
| 27 | Failed Runs by Server | `timeseries` |
| 28 | Top Busy Jobs (all statuses) | `bargauge` |

ترکیب نوع پنل‌ها: `bargauge`: 5, `row`: 5, `stat`: 8, `table`: 5, `timeseries`: 5

## متریک‌های استفاده‌شده

- `mssql_job_history_avg_duration_seconds_24h`
- `mssql_job_history_failed_duration_seconds`
- `mssql_job_history_failed_total`
- `mssql_job_history_last_age_seconds`
- `mssql_job_history_last_duration_seconds`
- `mssql_job_history_last_status`
- `mssql_job_history_runs`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
