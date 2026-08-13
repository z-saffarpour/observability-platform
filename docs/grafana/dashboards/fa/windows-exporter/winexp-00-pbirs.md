# Power BI Report Server

[فهرست داشبوردها](../README.md) · [راهنمای Grafana](../../../../../grafana/README.md) · [English](../../en/windows-exporter/winexp-00-pbirs.md) · [مستندات فارسی Exporter](../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

CPU and memory-first view for Power BI Report Server / SSRS hosts: fleet KPIs, color-coded pressure table, live trends, and process-level RS/RSPortal/Mashup consumption. Pair with profiles/powerbi-report-server.yml.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-00-pbirs` |
| فایل منبع | [`winexp-00-pbirs.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-pbirs.json) |
| برچسب‌ها | `windows_exporter`, `pbirs`, `powerbi`, `report-server`, `ssrs` |
| تعداد پنل‌ها | 40 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_exporter_build_info, job)` |
| `instance` | Server | `query` | `label_values(windows_service_state{job=~"${job:regex}",name=~"(?i)(PowerBIReportServer\|PBIRS.+\|SQLServerReportingServices\|ReportServer.+)"}, instance)` |
| `pbirs_service` | Report Server Service | `query` | `label_values(windows_service_state{job=~"${job:regex}",instance=~"${instance:regex}",name=~"(?i)(PowerBIReportServer\|PBIRS.+\|SQLServerReportingServices\|ReportServer.+)"}, name)` |
| `process` | Process | `query` | `label_values(windows_process_info{job=~"${job:regex}",instance=~"${instance:regex}",process=~"(?i)(ReportingServicesService\|Microsoft\\.ReportingServices.*\|RSPortal\|MashupContainer\|msmdsrv)"}, process)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | CPU and Memory at a Glance | `row` |
| 2 | Max CPU % | `stat` |
| 3 | Min Mem Avail % | `stat` |
| 4 | Max Mem Used % | `stat` |
| 5 | Max Commit % | `stat` |
| 6 | Hosts CPU > 85% | `stat` |
| 7 | Hosts Mem < 10% | `stat` |
| 8 | PBIRS Svcs Down | `stat` |
| 9 | Collector Failures | `stat` |
| 10 | CPU / Memory Pressure by Host (sort by CPU % or Mem Used %) | `row` |
| 11 | PBIRS Host Resource Pressure | `table` |
| 12 | Live CPU and Memory Trends | `row` |
| 13 | Host CPU % | `timeseries` |
| 14 | Memory Available % | `timeseries` |
| 15 | Memory Used % and Commit % | `timeseries` |
| 16 | RS Engine Memory (Working Set) | `timeseries` |
| 17 | Report Server Process Resources | `row` |
| 18 | RS Engine CPU (cores) | `timeseries` |
| 19 | All PBIRS Processes CPU | `timeseries` |
| 20 | All PBIRS Processes Memory | `timeseries` |
| 21 | Report Server Services | `row` |
| 22 | PBIRS / SSRS Service State | `table` |
| 23 | Service Availability Timeline | `state-timeline` |
| 24 | Services Running vs Down | `timeseries` |
| 25 | Process Presence by Role | `timeseries` |
| 26 | RS Engine Diagnostics (handles, IO, uptime) | `row` |
| 27 | RS Engine Memory Detail | `timeseries` |
| 28 | RS Engine Handles and Threads | `timeseries` |
| 29 | RS Engine IO | `timeseries` |
| 30 | RS Engine Uptime / Page Faults | `timeseries` |
| 31 | Web Portal and Mashup Engine | `row` |
| 32 | RSPortal CPU | `timeseries` |
| 33 | RSPortal Working Set | `timeseries` |
| 34 | MashupContainer CPU / Memory | `timeseries` |
| 35 | Disk, Network and TCP (secondary) | `row` |
| 36 | Processor Queue Length | `timeseries` |
| 37 | Disk Free % | `timeseries` |
| 38 | Disk Latency | `timeseries` |
| 39 | Network Throughput | `timeseries` |
| 40 | TCP Connections | `timeseries` |

ترکیب نوع پنل‌ها: `row`: 8, `stat`: 8, `state-timeline`: 1, `table`: 2, `timeseries`: 21

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
- `windows_memory_commit_limit`
- `windows_memory_committed_bytes`
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
- `windows_tcp_connection_failures_total`
- `windows_tcp_connections_active_total`
- `windows_tcp_connections_established`
- `windows_tcp_connections_reset_total`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
