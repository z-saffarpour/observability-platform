# Collector system

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-system.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

System-wide scheduler pressure: processor queue length, context switches, system calls, process/thread counts and uptime (recent reboots).

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-system` |
| Source file | [`winexp-col-system.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-system.json) |
| Tags | `windows_exporter`, `collector`, `system` |
| Panel count | 34 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_exporter_build_info, job)` |
| `instance` | Server | `query` | `label_values(windows_exporter_build_info{job=~"${job:regex}"}, instance)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Scrape FAIL | `stat` |
| 3 | Run Queue > 5 | `stat` |
| 4 | Run Queue > 2 | `stat` |
| 5 | Max Run Queue | `stat` |
| 6 | Median Run Queue | `stat` |
| 7 | Rebooted < 24h | `stat` |
| 8 | Max Processes | `stat` |
| 9 | Max Threads | `stat` |
| 10 | Max Ctx Switch/s | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Deepest Run Queue (topk 15) | `bargauge` |
| 13 | Run Queue per Logical CPU (topk 15) | `bargauge` |
| 14 | Shortest Uptime (bottomk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | System Health by Host | `table` |
| 17 | Hotspots: Run Queue > 2 | `table` |
| 18 | Hotspots: Rebooted in the last 24h | `table` |
| 19 | Trends | `row` |
| 20 | Run Queue Length (topk 10) | `timeseries` |
| 21 | Context Switches/s (topk 10) | `timeseries` |
| 22 | System Calls/s (topk 10) | `timeseries` |
| 23 | Processes (topk 10) | `timeseries` |
| 24 | Threads (topk 10) | `timeseries` |
| 25 | Uptime (bottomk 10) | `timeseries` |
| 26 | Deep Dive | `row` |
| 27 | Exception Dispatches/s (topk 10) | `timeseries` |
| 28 | Process Limit Used % (topk 10) | `timeseries` |
| 29 | Context Switches per Logical CPU (topk 10) | `timeseries` |
| 30 | Uptime & Boot Detail | `table` |
| 31 | Collector scrape health | `row` |
| 32 | Scrape Health by Host | `table` |
| 33 | Scrape Duration (topk 10) | `timeseries` |
| 34 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 5, `timeseries`: 11

## Metrics used

- `windows_cpu_logical_processor`
- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_system_context_switches_total`
- `windows_system_exception_dispatches_total`
- `windows_system_processes`
- `windows_system_processes_limit`
- `windows_system_processor_queue_length`
- `windows_system_system_calls_total`
- `windows_system_system_up_time`
- `windows_system_threads`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
