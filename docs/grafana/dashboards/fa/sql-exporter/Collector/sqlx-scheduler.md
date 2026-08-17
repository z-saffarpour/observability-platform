# Collector scheduler

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-scheduler.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Scheduler / SOS worker pressure: KPI, fleet trends, hot scheduler tables, and CPU topology. Collector: mssql_scheduler (30s).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-scheduler` |
| فایل منبع | [`sqlx-scheduler.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-scheduler.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `scheduler` |
| تعداد پنل‌ها | 31 |
| بازهٔ تازه‌سازی | `30s` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `scheduler_id` | Scheduler | `query` | `label_values(mssql_scheduler_runnable_tasks{job="sql_exporter", instance=~"$instance"}, scheduler_id)` |
| `min_runnable` | Min Runnable | `custom` | `0,1,2,5` |
| `over_avg_factor` | Over Avg x | `custom` | `1.2,1.5,2,3` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Total Runnable | `stat` |
| 3 | Total Work Queue | `stat` |
| 4 | Hot Schedulers | `stat` |
| 5 | Instances with total runnable > 10 right now. | `stat` |
| 6 | Highest runnable count on any single scheduler. | `stat` |
| 7 | Max Load Factor | `stat` |
| 8 | Pending Disk IO | `stat` |
| 9 | Online Schedulers | `stat` |
| 10 | Fleet Pressure - trends | `row` |
| 11 | Total Runnable by Server | `timeseries` |
| 12 | Total Work Queue by Server | `timeseries` |
| 13 | Signal Wait % | `timeseries` |
| 14 | Runnable per CPU | `timeseries` |
| 15 | Max Scheduler Runnable | `timeseries` |
| 16 | Hot Schedulers - investigate now | `row` |
| 17 | Scheduler Snapshot (all metrics) | `table` |
| 18 | Top Runnable Schedulers | `bargauge` |
| 19 | Top Work Queue | `bargauge` |
| 20 | Top Load Factor | `bargauge` |
| 21 | Fleet Snapshot - per server | `row` |
| 22 | Server Pressure Summary | `table` |
| 23 | Hot Schedulers (above avg) | `table` |
| 24 | Scheduler Detail - time series | `row` |
| 25 | Runnable (top 8 or filtered) | `timeseries` |
| 26 | Work Queue (top 8 or filtered) | `timeseries` |
| 27 | Load Factor (top 8 or filtered) | `timeseries` |
| 28 | Active Workers & Current Tasks | `timeseries` |
| 29 | Pending Disk IO (top 8 or filtered) | `timeseries` |
| 30 | CPU Topology & Memory | `row` |
| 31 | Server CPU Topology | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 4, `timeseries`: 10

## متریک‌های استفاده‌شده

- `mssql_cpu_signal_wait_percent`
- `mssql_os_cpu_count`
- `mssql_os_hyperthread_ratio`
- `mssql_os_physical_memory_kb`
- `mssql_scheduler_active_workers`
- `mssql_scheduler_current_tasks`
- `mssql_scheduler_load_factor`
- `mssql_scheduler_online_count`
- `mssql_scheduler_pending_disk_io`
- `mssql_scheduler_runnable_tasks`
- `mssql_scheduler_total_runnable`
- `mssql_scheduler_total_work_queue`
- `mssql_scheduler_work_queue`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
