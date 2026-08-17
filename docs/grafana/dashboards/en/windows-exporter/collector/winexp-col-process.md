# Collector process

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-process.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Per-process resource consumers, capped with topk to control cardinality. Use to attribute host-level CPU / memory / handle growth to a process.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-process` |
| Source file | [`winexp-col-process.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-process.json) |
| Tags | `windows_exporter`, `collector`, `process` |
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
| 3 | Distinct Processes | `stat` |
| 4 | Working Set > 4 GB | `stat` |
| 5 | Handles > 10k | `stat` |
| 6 | Threads > 500 | `stat` |
| 7 | Max Working Set | `stat` |
| 8 | Max Private Bytes | `stat` |
| 9 | Max Process CPU (cores) | `stat` |
| 10 | Max Host Handles | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Top CPU (cores, topk 15) | `bargauge` |
| 13 | Top Working Set (topk 15) | `bargauge` |
| 14 | Top Handles (topk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | Top CPU Processes (topk 20) | `table` |
| 17 | Top Memory Processes (topk 20 by working set) | `table` |
| 18 | Hotspot: Handle / Thread Leaks (topk 20 by handles) | `table` |
| 19 | Trends | `row` |
| 20 | Process CPU cores (topk 15) | `timeseries` |
| 21 | Working Set (topk 15) | `timeseries` |
| 22 | Private Bytes (topk 15) | `timeseries` |
| 23 | Handles (topk 15) | `timeseries` |
| 24 | Process IO Bps (topk 15) | `timeseries` |
| 25 | Deep Dive | `row` |
| 26 | Threads (topk 15) | `timeseries` |
| 27 | Page Faults/s (topk 15) | `timeseries` |
| 28 | IO Operations/s (topk 15) | `timeseries` |
| 29 | Virtual & Pagefile Bytes (topk 15) | `timeseries` |
| 30 | Process Inventory (PIDs) | `table` |
| 31 | Collector scrape health | `row` |
| 32 | Scrape Health by Host | `table` |
| 33 | Scrape Duration (topk 10) | `timeseries` |
| 34 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 5, `timeseries`: 11

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_process_cpu_time_total`
- `windows_process_handles`
- `windows_process_info`
- `windows_process_io_bytes_total`
- `windows_process_io_operations_total`
- `windows_process_page_faults_total`
- `windows_process_page_file_bytes`
- `windows_process_private_bytes`
- `windows_process_threads`
- `windows_process_virtual_bytes`
- `windows_process_working_set_bytes`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
