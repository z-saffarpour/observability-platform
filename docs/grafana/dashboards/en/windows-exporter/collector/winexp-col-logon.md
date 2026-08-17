# Collector logon

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-logon.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Logon activity by type. Spikes in network or remote-interactive logons are useful for capacity and for security triage.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-logon` |
| Source file | [`winexp-col-logon.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-logon.json) |
| Tags | `windows_exporter`, `collector`, `logon` |
| Panel count | 27 |
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
| 3 | Total Logon Sessions | `stat` |
| 4 | Interactive | `stat` |
| 5 | Network | `stat` |
| 6 | Service / Batch | `stat` |
| 7 | Clear-text Logons | `stat` |
| 8 | Max Interactive on a Host | `stat` |
| 9 | Hosts Reporting | `stat` |
| 10 | Fleet Ranking (now) | `row` |
| 11 | Most Logon Sessions (topk 15) | `bargauge` |
| 12 | Most Interactive Sessions (topk 15) | `bargauge` |
| 13 | Logons by Type (fleet) | `bargauge` |
| 14 | Fleet Snapshot & Hotspots | `row` |
| 15 | Logon Profile by Host | `table` |
| 16 | Logon Types Detail | `table` |
| 17 | Trends | `row` |
| 18 | Logons by Type (fleet composition) | `timeseries` |
| 19 | Interactive Logons (topk 10) | `timeseries` |
| 20 | Network Logons (topk 10) | `timeseries` |
| 21 | Deep Dive | `row` |
| 22 | Service / Batch Logons (topk 10) | `timeseries` |
| 23 | Clear-text Logons (topk 10) | `timeseries` |
| 24 | Collector scrape health | `row` |
| 25 | Scrape Health by Host | `table` |
| 26 | Scrape Duration (topk 10) | `timeseries` |
| 27 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 3, `timeseries`: 7

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_logon_logon_type`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
