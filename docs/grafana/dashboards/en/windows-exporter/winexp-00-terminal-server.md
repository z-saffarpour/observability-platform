# Terminal Server

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/windows-exporter/winexp-00-terminal-server.md) · [Exporter documentation](../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

RDS Session Host / Terminal Server only. Host list and capacity panels are scoped to instances that expose windows_terminal_services_session_info (profiles/terminal-server.yml). Ordinary Windows/SQL hosts are excluded even when Server=All.

## Details

| Property | Value |
|---|---|
| UID | `winexp-00-terminal-server` |
| Source file | [`winexp-00-terminal-server.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-terminal-server.json) |
| Tags | `windows_exporter`, `terminal_services`, `rds`, `session-host`, `terminal-server` |
| Panel count | 42 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_exporter_build_info, job)` |
| `instance` | Server | `query` | `label_values(windows_terminal_services_session_info{job=~"${job:regex}"}, instance)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health Snapshot | `row` |
| 2 | TS Hosts Up | `stat` |
| 3 | TermService Down | `stat` |
| 4 | RDS Svcs Down | `stat` |
| 5 | Active Sessions | `stat` |
| 6 | Disconnected | `stat` |
| 7 | Unique Users | `stat` |
| 8 | CPU > 85% | `stat` |
| 9 | Mem Avail < 10% | `stat` |
| 10 | Fleet Ranking (filter Server to drill down) | `row` |
| 11 | Sessions by Host | `table` |
| 12 | Capacity Pressure | `table` |
| 13 | RDS Sessions | `row` |
| 14 | Sessions by State | `timeseries` |
| 15 | Active vs Disconnected | `timeseries` |
| 16 | Session Inventory | `table` |
| 17 | Unique Users by Host | `timeseries` |
| 18 | Per-Session Resources (TerminalServicesSession counters) | `row` |
| 19 | Session Working Set | `timeseries` |
| 20 | Session Private Bytes | `timeseries` |
| 21 | Session CPU (processor time /s) | `timeseries` |
| 22 | Session Page File Bytes | `timeseries` |
| 23 | Session Threads / Handles | `timeseries` |
| 24 | RDS Services | `row` |
| 25 | RDS Service State | `table` |
| 26 | TermService Running | `timeseries` |
| 27 | Connection Broker (role optional) | `row` |
| 28 | Broker Connections /s | `timeseries` |
| 29 | Host Capacity | `row` |
| 30 | CPU Utilization % | `timeseries` |
| 31 | Memory Available % | `timeseries` |
| 32 | Commit Charge % | `timeseries` |
| 33 | Pagefile Free % | `timeseries` |
| 34 | Pages /s (Swap) | `timeseries` |
| 35 | Processor Queue | `timeseries` |
| 36 | Disk Free % | `timeseries` |
| 37 | Disk Latency | `timeseries` |
| 38 | Network Bandwidth | `timeseries` |
| 39 | TCP (RDP connection pressure) | `row` |
| 40 | TCP Connections Established | `timeseries` |
| 41 | TCP Connection Failures /s | `timeseries` |
| 42 | TCP Segments /s | `timeseries` |

Panel type summary: `row`: 8, `stat`: 8, `table`: 4, `timeseries`: 22

## Metrics used

- `up`
- `windows_cpu_time_total`
- `windows_logical_disk_free_bytes`
- `windows_logical_disk_read_latency_seconds_total`
- `windows_logical_disk_size_bytes`
- `windows_logical_disk_write_latency_seconds_total`
- `windows_memory_available_bytes`
- `windows_memory_commit_limit`
- `windows_memory_committed_bytes`
- `windows_memory_physical_total_bytes`
- `windows_memory_swap_pages_read_total`
- `windows_memory_swap_pages_written_total`
- `windows_net_bytes_received_total`
- `windows_net_bytes_sent_total`
- `windows_pagefile_free_bytes`
- `windows_pagefile_limit_bytes`
- `windows_service_state`
- `windows_system_processor_queue_length`
- `windows_tcp_connection_failures_total`
- `windows_tcp_connections_established`
- `windows_tcp_segments_received_total`
- `windows_tcp_segments_retransmitted_total`
- `windows_tcp_segments_sent_total`
- `windows_terminal_services_connection_broker_performance_total`
- `windows_terminal_services_handles`
- `windows_terminal_services_page_file_bytes`
- `windows_terminal_services_private_bytes`
- `windows_terminal_services_processor_time_seconds_total`
- `windows_terminal_services_session_info`
- `windows_terminal_services_threads`
- `windows_terminal_services_working_set_bytes`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
