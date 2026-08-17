# Dynamics / D365

[فهرست داشبوردها](../README.md) · [راهنمای Grafana](../../../../../grafana/README.md) · [English](../../en/windows-exporter/winexp-00-d365.md) · [مستندات فارسی Exporter](../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

AX 2012 AOS, D365 F&O Service Fabric host, and IIS (W3SVC/WAS/w3wp) health from windows_exporter. Windows layer only - not LCS/Service Fabric application health.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-00-d365` |
| فایل منبع | [`winexp-00-d365.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-d365.json) |
| برچسب‌ها | `windows_exporter`, `dynamics`, `d365`, `aos`, `service_fabric` |
| تعداد پنل‌ها | 28 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_process_cpu_time_total{process=~"(?i)(Ax32Serv\|Fabric.*\|Microsoft\\.Dynamics\\.AX\\..*\|w3wp)"}, job)` |
| `instance` | Server | `query` | `label_values(windows_process_cpu_time_total{job=~"${job:regex}",process=~"(?i)(Ax32Serv\|Fabric.*\|Microsoft\\.Dynamics\\.AX\\..*\|w3wp)"}, instance)` |
| `service` | Service | `query` | `label_values(windows_service_state{job=~"${job:regex}",instance=~"${instance:regex}",name=~"(?i)(AOS60\\$.+\|FabricHostSvc\|FabricInstallerSvc\|W3SVC\|WAS)"}, name)` |
| `process` | Process | `query` | `label_values(windows_process_cpu_time_total{job=~"${job:regex}",instance=~"${instance:regex}",process=~"(?i)(Ax32Serv\|Fabric.*\|Microsoft\\.Dynamics\\.AX\\..*\|w3wp)"}, process)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health Snapshot | `row` |
| 2 | Hosts Up | `stat` |
| 3 | Hosts Down | `stat` |
| 4 | Services Down | `stat` |
| 5 | Services Up | `stat` |
| 6 | Auto-Start Stopped | `stat` |
| 7 | Process Missing | `stat` |
| 8 | Dynamics Processes | `stat` |
| 9 | CPU > 85% | `stat` |
| 10 | Dynamics Services | `row` |
| 11 | Service State | `table` |
| 12 | Services Running / Down | `timeseries` |
| 13 | Services Currently Down | `table` |
| 14 | AOS / Fabric / IIS Processes | `row` |
| 15 | Process CPU (cores) | `timeseries` |
| 16 | Working Set | `timeseries` |
| 17 | Private Bytes | `timeseries` |
| 18 | Handles / Threads | `timeseries` |
| 19 | Process IO | `timeseries` |
| 20 | Process Inventory | `table` |
| 21 | Host Pressure | `row` |
| 22 | CPU Utilization % | `timeseries` |
| 23 | Memory Available % | `timeseries` |
| 24 | Disk Latency | `timeseries` |
| 25 | Disk Free % | `timeseries` |
| 26 | Network Bandwidth | `timeseries` |
| 27 | TCP Connections Established | `timeseries` |
| 28 | Processor Queue Length | `timeseries` |

ترکیب نوع پنل‌ها: `row`: 4, `stat`: 8, `table`: 3, `timeseries`: 13

## متریک‌های استفاده‌شده

- `up`
- `windows_cpu_time_total`
- `windows_logical_disk_free_bytes`
- `windows_logical_disk_read_latency_seconds_total`
- `windows_logical_disk_size_bytes`
- `windows_logical_disk_write_latency_seconds_total`
- `windows_memory_available_bytes`
- `windows_memory_physical_total_bytes`
- `windows_net_bytes_received_total`
- `windows_net_bytes_sent_total`
- `windows_process_cpu_time_total`
- `windows_process_handles`
- `windows_process_io_bytes_total`
- `windows_process_private_bytes`
- `windows_process_threads`
- `windows_process_working_set_bytes`
- `windows_service_start_mode`
- `windows_service_state`
- `windows_system_processor_queue_length`
- `windows_tcp_connections_established`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
