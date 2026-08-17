# Collector os

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-os.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

OS inventory and OS-level resource limits: build/version spread, process and handle headroom, paging and virtual memory. Inventory first, pressure second.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-os` |
| Source file | [`winexp-col-os.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-os.json) |
| Tags | `windows_exporter`, `collector`, `os` |
| Panel count | 33 |
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
| 3 | OS Builds | `stat` |
| 4 | Hosts | `stat` |
| 5 | Process Headroom < 20% | `stat` |
| 6 | Max Processes | `stat` |
| 7 | Max Users | `stat` |
| 8 | Min Paging Free % | `stat` |
| 9 | Virtual Free < 10% | `stat` |
| 10 | Fleet Visible Memory | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Most Processes (topk 15) | `bargauge` |
| 13 | Most Logged-on Users (topk 15) | `bargauge` |
| 14 | Lowest Paging Free % (bottomk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | OS Inventory | `table` |
| 17 | OS Resource Limits by Host | `table` |
| 18 | Hotspots: Paging Free % < 20 | `table` |
| 19 | Trends | `row` |
| 20 | Process Count (topk 10) | `timeseries` |
| 21 | Process Limit Used % (topk 10) | `timeseries` |
| 22 | Logged-on Users (topk 10) | `timeseries` |
| 23 | Paging Free % (bottomk 10) | `timeseries` |
| 24 | Physical / Virtual Free Bytes (bottomk 10) | `timeseries` |
| 25 | Deep Dive | `row` |
| 26 | Hostname & Domain | `table` |
| 27 | Timezone | `table` |
| 28 | OS Clock Skew vs Prometheus (topk 10) | `timeseries` |
| 29 | Process Memory Limit (bottomk 10) | `timeseries` |
| 30 | Collector scrape health | `row` |
| 31 | Scrape Health by Host | `table` |
| 32 | Scrape Duration (topk 10) | `timeseries` |
| 33 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 6, `timeseries`: 9

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_os_hostname`
- `windows_os_info`
- `windows_os_paging_free_bytes`
- `windows_os_paging_limit_bytes`
- `windows_os_physical_memory_free_bytes`
- `windows_os_process_memory_limit_bytes`
- `windows_os_processes`
- `windows_os_processes_limit`
- `windows_os_time`
- `windows_os_timezone`
- `windows_os_users`
- `windows_os_virtual_memory_bytes`
- `windows_os_virtual_memory_free_bytes`
- `windows_os_visible_memory_bytes`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
