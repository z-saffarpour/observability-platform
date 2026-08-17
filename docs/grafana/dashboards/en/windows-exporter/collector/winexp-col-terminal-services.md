# Collector terminal_services

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-terminal-services.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Remote Desktop / session host health: session counts by state and per-session resource usage. Disconnected sessions that never reap are the usual culprit.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-terminal-services` |
| Source file | [`winexp-col-terminal-services.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-terminal-services.json) |
| Tags | `windows_exporter`, `collector`, `terminal_services` |
| Panel count | 31 |
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
| 3 | Active Sessions | `stat` |
| 4 | Disconnected Sessions | `stat` |
| 5 | Total Sessions | `stat` |
| 6 | Hosts > 50 Sessions | `stat` |
| 7 | Max Sessions on a Host | `stat` |
| 8 | Session Memory | `stat` |
| 9 | Session CPU (cores) | `stat` |
| 10 | Max Session Handles | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Most Sessions (topk 15) | `bargauge` |
| 13 | Most Disconnected Sessions (topk 15) | `bargauge` |
| 14 | Highest Session Memory (topk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | Session Host Health | `table` |
| 17 | Hotspot: Many Disconnected Sessions | `table` |
| 18 | Sessions by State | `table` |
| 19 | Trends | `row` |
| 20 | Sessions by State (fleet) | `timeseries` |
| 21 | Total Sessions (topk 10) | `timeseries` |
| 22 | Session Memory (topk 10) | `timeseries` |
| 23 | Session CPU cores (topk 10) | `timeseries` |
| 24 | Deep Dive | `row` |
| 25 | Session Handles & Threads (topk 10) | `timeseries` |
| 26 | Private Bytes (topk 10) | `timeseries` |
| 27 | Disconnected Sessions (topk 10) | `timeseries` |
| 28 | Collector scrape health | `row` |
| 29 | Scrape Health by Host | `table` |
| 30 | Scrape Duration (topk 10) | `timeseries` |
| 31 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 4, `timeseries`: 9

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_terminal_services_handles`
- `windows_terminal_services_private_bytes`
- `windows_terminal_services_processor_time_seconds_total`
- `windows_terminal_services_session_info`
- `windows_terminal_services_threads`
- `windows_terminal_services_working_set_bytes`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
