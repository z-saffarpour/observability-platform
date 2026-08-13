# Dynamics AX 2012

[فهرست داشبوردها](../README.md) · [راهنمای Grafana](../../../../../grafana/README.md) · [English](../../en/windows-exporter/winexp-00-ax2012.md) · [مستندات فارسی Exporter](../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

AOS availability, Ax32Serv/w3wp process health, IIS web services, and host capacity for Microsoft Dynamics AX 2012. Pair with profiles/dynamics-ax-2012.yml. App-level Batch/DMF/Reporting needs extra collectors beyond windows_exporter.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-00-ax2012` |
| فایل منبع | [`winexp-00-ax2012.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-ax2012.json) |
| برچسب‌ها | `windows_exporter`, `dynamics`, `ax2012`, `aos` |
| تعداد پنل‌ها | 33 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_exporter_build_info, job)` |
| `instance` | Server | `query` | `label_values(windows_service_state{job=~"${job:regex}",name=~"(?i)AOS60\\$.+"}, instance)` |
| `aos_service` | AOS Service | `query` | `label_values(windows_service_state{job=~"${job:regex}",instance=~"${instance:regex}",name=~"(?i)AOS60\\$.+"}, name)` |
| `process` | Process | `query` | `label_values(windows_process_info{job=~"${job:regex}",instance=~"${instance:regex}",process=~"(?i)(Ax32Serv\|w3wp)"}, process)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health Snapshot | `row` |
| 2 | AOS Down | `stat` |
| 3 | AOS Running | `stat` |
| 4 | Ax32Serv Processes | `stat` |
| 5 | Web Services Down | `stat` |
| 6 | w3wp Processes | `stat` |
| 7 | CPU > 85% | `stat` |
| 8 | Mem Avail < 10% | `stat` |
| 9 | Collector Failures | `stat` |
| 10 | AOS Services | `row` |
| 11 | AOS Service State | `table` |
| 12 | AOS Availability Timeline | `state-timeline` |
| 13 | AOS Running Count | `timeseries` |
| 14 | Dynamics Process Presence | `timeseries` |
| 15 | Ax32Serv Process | `row` |
| 16 | Ax32Serv CPU | `timeseries` |
| 17 | Ax32Serv Memory | `timeseries` |
| 18 | Ax32Serv Handles and Threads | `timeseries` |
| 19 | Ax32Serv IO | `timeseries` |
| 20 | Ax32Serv Uptime / Page Faults | `timeseries` |
| 21 | Web / IIS (Enterprise Portal nodes) | `row` |
| 22 | W3SVC / WAS State | `table` |
| 23 | w3wp CPU | `timeseries` |
| 24 | w3wp Working Set | `timeseries` |
| 25 | Host Context (AOS capacity) | `row` |
| 26 | Host CPU % | `timeseries` |
| 27 | Memory Available % | `timeseries` |
| 28 | Processor Queue Length | `timeseries` |
| 29 | Disk Free % | `timeseries` |
| 30 | Disk Latency | `timeseries` |
| 31 | Network Throughput | `timeseries` |
| 32 | TCP Connections | `timeseries` |
| 33 | AOS Host Inventory | `table` |

ترکیب نوع پنل‌ها: `row`: 5, `stat`: 8, `state-timeline`: 1, `table`: 3, `timeseries`: 16

## متریک‌های استفاده‌شده

- `windows_cpu_logical_processor`
- `windows_cpu_time_total`
- `windows_exporter_collector_success`
- `windows_logical_disk_free_bytes`
- `windows_logical_disk_read_seconds_total`
- `windows_logical_disk_reads_total`
- `windows_logical_disk_size_bytes`
- `windows_logical_disk_write_seconds_total`
- `windows_logical_disk_writes_total`
- `windows_memory_available_bytes`
- `windows_memory_physical_total_bytes`
- `windows_net_bytes_received_total`
- `windows_net_bytes_sent_total`
- `windows_process_cpu_time_total`
- `windows_process_handles`
- `windows_process_info`
- `windows_process_io_bytes_total`
- `windows_process_io_operations_total`
- `windows_process_page_faults_total`
- `windows_process_page_file_bytes`
- `windows_process_private_bytes`
- `windows_process_start_time`
- `windows_process_threads`
- `windows_process_working_set_bytes`
- `windows_service_start_mode`
- `windows_service_state`
- `windows_system_processor_queue_length`
- `windows_system_system_up_time`
- `windows_tcp_connection_failures_total`
- `windows_tcp_connections_active_total`
- `windows_tcp_connections_established`
- `windows_tcp_connections_passive_total`
- `windows_tcp_connections_reset_total`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
