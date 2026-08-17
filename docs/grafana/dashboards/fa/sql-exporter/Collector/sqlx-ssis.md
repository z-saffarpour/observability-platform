# Collector ssis

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-ssis.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

SSISDB ops view: live running packages, failure triage with error messages, execution status mix, catalog health (log/files/inventory), slow succeeded runs. Collector: mssql_ssis (SSISDB.catalog.*). Empty panels = SSISDB absent or no activity in lookback.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-ssis` |
| فایل منبع | [`sqlx-ssis.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-ssis.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `ssis` |
| تعداد پنل‌ها | 35 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `folder` | Folder | `query` | `label_values(mssql_ssis_running_duration_seconds{job="sql_exporter", instance=~"$instance"}, folder)` |
| `project` | Project | `query` | `label_values(mssql_ssis_running_duration_seconds{job="sql_exporter", instance=~"$instance", folder=~"${folder:regex}"}, project)` |
| `package` | Package | `query` | `label_values(mssql_ssis_running_duration_seconds{job="sql_exporter", instance=~"$instance", folder=~"${folder:regex}", project=~"${project:regex}"}, package)` |
| `fail_window` | Fail Window | `custom` | `1h,24h` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Running Now | `stat` |
| 3 | Failed 1h | `stat` |
| 4 | Failed 24h | `stat` |
| 5 | Success Rate 24h | `stat` |
| 6 | SSISDB Log % | `stat` |
| 7 | Long >=30m | `stat` |
| 8 | Servers w/ Failures | `stat` |
| 9 | Unexpected (7d) | `stat` |
| 10 | Live - Running Executions | `row` |
| 11 | Running Count by Server | `timeseries` |
| 12 | Longest Running (topk 15) | `bargauge` |
| 13 | Currently Running (folder / project / package / caller) | `table` |
| 14 | Runtime Trend (topk 20) | `timeseries` |
| 15 | Failures & Error Messages | `row` |
| 16 | Failed Packages (topk 15) | `bargauge` |
| 17 | Last Failure Age (topk 15) | `bargauge` |
| 18 | Recent Failures (24h) | `table` |
| 19 | Last Failure per Package (7d) - Failed only | `table` |
| 20 | Error Messages on Failed Runs (24h) | `table` |
| 21 | Execution Volume & Status Mix | `row` |
| 22 | Executions 24h by Status | `timeseries` |
| 23 | Executions 1h by Status | `timeseries` |
| 24 | Failed Total by Window | `bargauge` |
| 25 | Running Count Trend | `timeseries` |
| 26 | SSISDB Catalog Health | `row` |
| 27 | SSISDB Log Used % | `timeseries` |
| 28 | SSISDB File Size (MB) | `timeseries` |
| 29 | Catalog Inventory | `table` |
| 30 | Catalog Operations 24h | `timeseries` |
| 31 | Running Catalog Operations | `table` |
| 32 | Performance - Slow Runs & Event Noise | `row` |
| 33 | Slowest Succeeded Runs 24h (topk 15) | `bargauge` |
| 34 | Event Errors/Warnings by Package (24h) | `bargauge` |
| 35 | Event Errors Trend | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 6, `row`: 6, `stat`: 8, `table`: 6, `timeseries`: 9

## متریک‌های استفاده‌شده

- `mssql_ssis_environments`
- `mssql_ssis_event_errors_24h`
- `mssql_ssis_executions_1h`
- `mssql_ssis_failed_age_seconds`
- `mssql_ssis_failed_count`
- `mssql_ssis_failed_duration_seconds`
- `mssql_ssis_failed_last_age_seconds`
- `mssql_ssis_failed_last_duration_seconds`
- `mssql_ssis_failed_last_status`
- `mssql_ssis_failed_message_count_24h`
- `mssql_ssis_failed_message_last_age_seconds`
- `mssql_ssis_failed_message_last_start_timestamp`
- `mssql_ssis_failed_start_timestamp`
- `mssql_ssis_failed_total`
- `mssql_ssis_folders`
- `mssql_ssis_operation_running_seconds`
- `mssql_ssis_operation_running_start_timestamp`
- `mssql_ssis_operations_24h`
- `mssql_ssis_packages`
- `mssql_ssis_projects`
- `mssql_ssis_running_count`
- `mssql_ssis_running_duration_seconds`
- `mssql_ssis_succeeded_duration_seconds`
- `mssql_ssisdb_executions_24h`
- `mssql_ssisdb_failed_24h`
- `mssql_ssisdb_file_size_mb`
- `mssql_ssisdb_log_used_percent`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
