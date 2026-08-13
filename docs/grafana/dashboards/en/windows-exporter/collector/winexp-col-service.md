# Collector service

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-service.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Windows service availability. The one metric that matters: auto-start services that are not running. Everything else supports the triage.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-service` |
| Source file | [`winexp-col-service.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-service.json) |
| Tags | `windows_exporter`, `collector`, `service` |
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
| 3 | Auto-start NOT Running | `stat` |
| 4 | Hosts Affected | `stat` |
| 5 | Running Services | `stat` |
| 6 | Stopped Services | `stat` |
| 7 | Auto-start Services | `stat` |
| 8 | Monitored Services | `stat` |
| 9 | Pending / Paused | `stat` |
| 10 | Fleet Ranking (now) | `row` |
| 11 | Most Stopped Auto Services (topk 15) | `bargauge` |
| 12 | Auto-start Availability % (bottomk 15) | `bargauge` |
| 13 | Most Running Services (topk 15) | `bargauge` |
| 14 | Fleet Snapshot & Hotspots | `row` |
| 15 | Hotspot: Auto-start Services Not Running | `table` |
| 16 | Service Availability by Host | `table` |
| 17 | Service State Matrix | `table` |
| 18 | Trends | `row` |
| 19 | Auto-start Services Not Running (fleet) | `timeseries` |
| 20 | Not Running by Host (topk 10) | `timeseries` |
| 21 | Running Service Count (bottomk 10) | `timeseries` |
| 22 | Service States (fleet totals) | `timeseries` |
| 23 | Deep Dive | `row` |
| 24 | Service Inventory | `table` |
| 25 | Service Process IDs | `table` |
| 26 | Start Mode Configuration | `table` |
| 27 | Paused / Pending Services (topk 10) | `timeseries` |
| 28 | Collector scrape health | `row` |
| 29 | Scrape Health by Host | `table` |
| 30 | Scrape Duration (topk 10) | `timeseries` |
| 31 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 7, `timeseries`: 7

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_service_info`
- `windows_service_process`
- `windows_service_start_mode`
- `windows_service_state`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
