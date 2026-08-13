# Services & Processes

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/windows-exporter/winexp-00-services-processes.md) · [Exporter documentation](../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

The dashboard JSON does not provide a description.

## Details

| Property | Value |
|---|---|
| UID | `winexp-00-services-processes` |
| Source file | [`winexp-00-services-processes.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-services-processes.json) |
| Tags | `windows_exporter`, `services`, `processes`, `logon`, `terminal_services` |
| Panel count | 32 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_exporter_build_info, job)` |
| `instance` | Server | `query` | `label_values(windows_exporter_build_info{job=~"${job:regex}"}, instance)` |
| `service` | Service | `query` | `label_values(windows_service_info{job=~"${job:regex}",instance=~"${instance:regex}"}, name)` |
| `process` | Process | `query` | `label_values(windows_process_info{job=~"${job:regex}",instance=~"${instance:regex}",process!~"(?i)^(Idle\|System)$"}, process)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | At a glance ï¿½fÂ¢ï¿½,ï¿½,ï¿½ï¿½,ï¿½?ï¿½ shows who/what, not fleet totals | `row` |
| 2 | Which critical service is DOWN? | `stat` |
| 3 | Hottest process CPU | `stat` |
| 4 | Biggest process memory | `stat` |
| 5 | Platform processes | `stat` |
| 6 | Most interactive logons | `stat` |
| 7 | Critical DOWN count | `stat` |
| 8 | Auto-start stopped | `stat` |
| 9 | Hosts in view | `stat` |
| 10 | Services | `row` |
| 11 | Critical Services - Not Running | `table` |
| 12 | Auto-start Services - Stopped | `table` |
| 13 | Critical Service Health Matrix | `table` |
| 14 | Service Catalog | `table` |
| 15 | Critical Service Availability | `timeseries` |
| 16 | Service Process Uptime | `timeseries` |
| 17 | Processes | `row` |
| 18 | Top Processes by CPU | `table` |
| 19 | Top Processes by Working Set | `table` |
| 20 | Top Processes by IO | `table` |
| 21 | Process CPU Trend | `timeseries` |
| 22 | Process Memory Trend | `timeseries` |
| 23 | Process IO Trend | `timeseries` |
| 24 | Handles & Threads | `timeseries` |
| 25 | Platform Processes - CPU | `timeseries` |
| 26 | Platform Processes - Working Set | `timeseries` |
| 27 | Process Inventory | `table` |
| 28 | Logons & Sessions | `row` |
| 29 | Logons by Type | `timeseries` |
| 30 | Interactive / RDP Logons by Host | `bargauge` |
| 31 | Current Logons Detail | `table` |
| 32 | RDS Sessions (when terminal_services collector is enabled) | `timeseries` |

Panel type summary: `bargauge`: 1, `row`: 4, `stat`: 8, `table`: 9, `timeseries`: 10

## Metrics used

- `windows_exporter_build_info`
- `windows_logon_logon_type`
- `windows_process_cpu_time_total`
- `windows_process_handles`
- `windows_process_info`
- `windows_process_io_bytes_total`
- `windows_process_private_bytes`
- `windows_process_threads`
- `windows_process_working_set_bytes`
- `windows_service_info`
- `windows_service_process`
- `windows_service_start_mode`
- `windows_service_state`
- `windows_terminal_services_session_info`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
