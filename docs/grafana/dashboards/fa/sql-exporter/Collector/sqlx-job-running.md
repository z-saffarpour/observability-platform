# Collector job_running

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-job-running.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Live SQL Agent jobs ops view: Agent service health, currently running jobs with step + Runtime vs 24h success average (OverAvg), longest runners, fleet busy servers. Collector: mssql_job_running (sysjobactivity).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-job-running` |
| فایل منبع | [`sqlx-job-running.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-job-running.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `jobs`, `job_running` |
| تعداد پنل‌ها | 23 |
| بازهٔ تازه‌سازی | `30s` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `category` | Category | `query` | `label_values(mssql_job_running_seconds{job="sql_exporter", instance=~"$instance"}, category_name)` |
| `job_name` | Job | `query` | `label_values(mssql_job_running_seconds{job="sql_exporter", instance=~"$instance", category_name=~"${category:regex}"}, job_name)` |
| `enabled` | Enabled | `custom` | `1,0` |
| `over_avg_factor` | Over Avg x | `custom` | `1.2,1.5,2,3` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Agents Down | `stat` |
| 3 | Agents OK | `stat` |
| 4 | Jobs Running | `stat` |
| 5 | OverAvg | `stat` |
| 6 | Long >=30m | `stat` |
| 7 | Max Duration | `stat` |
| 8 | Servers Busy | `stat` |
| 9 | Fleet Count | `stat` |
| 10 | Live Running Now | `row` |
| 11 | Running Jobs by Server | `timeseries` |
| 12 | Longest Running (topk 15) | `bargauge` |
| 13 | Jobs Currently Running (Duration vs Avg) | `table` |
| 14 | Runtime Trend (topk 20) | `timeseries` |
| 15 | OverAvg Anomalies (vs own 24h success average) | `row` |
| 16 | OverAvg Ratio (topk 15) | `bargauge` |
| 17 | Long w/o Baseline (>=30m) | `bargauge` |
| 18 | Jobs Over Avg (Duration vs Avg) | `table` |
| 19 | SQL Server Agent Service | `row` |
| 20 | Agent Up (1=Running) | `timeseries` |
| 21 | Running Jobs per Server | `bargauge` |
| 22 | Agent Status by Server | `table` |
| 23 | Agents Down / Not Running | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 4, `row`: 4, `stat`: 8, `table`: 4, `timeseries`: 3

## متریک‌های استفاده‌شده

- `mssql_job_history_avg_duration_seconds_24h`
- `mssql_job_running_count`
- `mssql_job_running_seconds`
- `mssql_job_running_start_timestamp`
- `mssql_sqlagent_running`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
