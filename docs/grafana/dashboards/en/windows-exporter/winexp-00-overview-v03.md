# Overview

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/windows-exporter/winexp-00-overview-v03.md) · [Exporter documentation](../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

The dashboard JSON does not provide a description.

## Details

| Property | Value |
|---|---|
| UID | `winexp-00-overview-v03` |
| Source file | [`winexp-00-overview-v03.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-overview-v03.json) |
| Tags | `windows_exporter`, `overview`, `operations`, `v03` |
| Panel count | 51 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(windows_exporter_build_info{job="windows_exporter"}, instance)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Untitled | `stat` |
| 2 | Untitled | `stat` |
| 3 | Untitled | `stat` |
| 4 | Untitled | `stat` |
| 5 | Untitled | `stat` |
| 6 | Untitled | `stat` |
| 7 | Untitled | `stat` |
| 8 | Untitled | `stat` |
| 9 | Untitled | `stat` |
| 10 | Untitled | `stat` |
| 11 | Untitled | `stat` |
| 12 | Untitled | `stat` |
| 13 | Untitled | `stat` |
| 14 | Untitled | `stat` |
| 15 | Untitled | `stat` |
| 16 | Untitled | `stat` |
| 17 | Untitled | `stat` |
| 18 | Untitled | `stat` |
| 19 | Untitled | `stat` |
| 20 | Untitled | `stat` |
| 21 | Untitled | `stat` |
| 22 | Untitled | `stat` |
| 23 | Untitled | `stat` |
| 24 | Untitled | `stat` |
| 25 | Untitled | `stat` |
| 26 | Untitled | `stat` |
| 27 | Fleet Status | `row` |
| 28 | Target State | `table` |
| 29 | Failed Collectors | `table` |
| 30 | All Collectors | `table` |
| 31 | Critical Service State | `table` |
| 32 | Host Resources | `row` |
| 33 | CPU % | `table` |
| 34 | Memory Available % | `table` |
| 35 | Disk Free % | `table` |
| 36 | Processor Queue | `table` |
| 37 | Disk Latency (s/op) | `table` |
| 38 | License Status | `table` |
| 39 | SQL Server | `row` |
| 40 | MSSQL Collector State | `table` |
| 41 | Blocked Processes | `table` |
| 42 | Memory Grants Pending | `table` |
| 43 | Longest Transaction (s) | `table` |
| 44 | Log Used % | `table` |
| 45 | Page Life Expectancy (s) | `table` |
| 46 | Deadlocks /h | `table` |
| 47 | User Connections | `table` |
| 48 | Exporter Health | `row` |
| 49 | Scrape Duration (s) | `table` |
| 50 | Collector Duration (s) | `table` |
| 51 | Exporter Build Info | `table` |

Panel type summary: `row`: 4, `stat`: 26, `table`: 21

## Metrics used

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

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
