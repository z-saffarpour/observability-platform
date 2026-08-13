# Overview Exceptions

[فهرست داشبوردها](../README.md) · [راهنمای Grafana](../../../../../grafana/README.md) · [English](../../en/windows-exporter/winexp-00-overview-v02.md) · [مستندات فارسی Exporter](../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

این داشبورد توضیح ثبت‌شده‌ای در JSON ندارد.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-00-overview-v02` |
| فایل منبع | [`winexp-00-overview-v02.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-overview-v02.json) |
| برچسب‌ها | `windows_exporter`, `overview`, `operations`, `v02` |
| تعداد پنل‌ها | 51 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(windows_exporter_build_info{job="windows_exporter"}, instance)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | بدون عنوان | `stat` |
| 2 | بدون عنوان | `stat` |
| 3 | بدون عنوان | `stat` |
| 4 | بدون عنوان | `stat` |
| 5 | بدون عنوان | `stat` |
| 6 | بدون عنوان | `stat` |
| 7 | بدون عنوان | `stat` |
| 8 | بدون عنوان | `stat` |
| 9 | بدون عنوان | `stat` |
| 10 | بدون عنوان | `stat` |
| 11 | بدون عنوان | `stat` |
| 12 | بدون عنوان | `stat` |
| 13 | بدون عنوان | `stat` |
| 14 | بدون عنوان | `stat` |
| 15 | بدون عنوان | `stat` |
| 16 | بدون عنوان | `stat` |
| 17 | بدون عنوان | `stat` |
| 18 | بدون عنوان | `stat` |
| 19 | بدون عنوان | `stat` |
| 20 | بدون عنوان | `stat` |
| 21 | بدون عنوان | `stat` |
| 22 | بدون عنوان | `stat` |
| 23 | بدون عنوان | `stat` |
| 24 | بدون عنوان | `stat` |
| 25 | بدون عنوان | `stat` |
| 26 | بدون عنوان | `stat` |
| 27 | Fleet Status | `row` |
| 28 | Targets Down | `table` |
| 29 | Failed Collectors | `table` |
| 30 | All Collectors | `table` |
| 31 | Critical Services Down | `table` |
| 32 | Host Resources | `row` |
| 33 | CPU > Own Avg (1h) | `table` |
| 34 | Memory Available < 20% | `table` |
| 35 | Disk Free < 10% | `table` |
| 36 | Processor Queue > Own Avg (1h) | `table` |
| 37 | Disk Latency > 20ms | `table` |
| 38 | License Issues | `table` |
| 39 | SQL Server | `row` |
| 40 | MSSQL Collector Failed | `table` |
| 41 | Blocked Processes > 0 | `table` |
| 42 | Memory Grants Pending > 0 | `table` |
| 43 | Long Transactions > 5m | `table` |
| 44 | Log Used >= 70% | `table` |
| 45 | Low PLE < 300s | `table` |
| 46 | Deadlocks /h > 0 | `table` |
| 47 | User Connections | `table` |
| 48 | Exporter Health | `row` |
| 49 | Slow Scrape > 30s | `table` |
| 50 | Collector Duration (s) | `table` |
| 51 | Exporter Build Info | `table` |

ترکیب نوع پنل‌ها: `row`: 4, `stat`: 26, `table`: 21

## متریک‌های استفاده‌شده

- `up`
- `windows_cpu_time_total`
- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_scrape_duration_seconds`
- `windows_license_status`
- `windows_logical_disk_free_bytes`
- `windows_logical_disk_read_latency_seconds_total`
- `windows_logical_disk_requests_queued`
- `windows_logical_disk_size_bytes`
- `windows_logical_disk_write_latency_seconds_total`
- `windows_memory_available_bytes`
- `windows_memory_physical_total_bytes`
- `windows_mssql_bufman_page_life_expectancy_seconds`
- `windows_mssql_collector_success`
- `windows_mssql_databases_log_used_percent`
- `windows_mssql_genstats_blocked_processes`
- `windows_mssql_genstats_user_connections`
- `windows_mssql_locks_deadlocks`
- `windows_mssql_memmgr_pending_memory_grants`
- `windows_mssql_sqlstats_batch_requests`
- `windows_mssql_transactions_longest_transaction_running_seconds`
- `windows_net_packets_received_errors_total`
- `windows_net_packets_sent_errors_total`
- `windows_service_state`
- `windows_system_processor_queue_length`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
