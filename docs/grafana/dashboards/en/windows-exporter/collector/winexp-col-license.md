# Collector license

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-license.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Windows activation state across the fleet. Non-genuine or offline activation blocks patching and support.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-license` |
| Source file | [`winexp-col-license.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-license.json) |
| Tags | `windows_exporter`, `collector`, `license` |
| Panel count | 25 |
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
| 3 | Not Genuine | `stat` |
| 4 | Genuine | `stat` |
| 5 | Offline Activation | `stat` |
| 6 | Tampered | `stat` |
| 7 | Invalid Licence | `stat` |
| 8 | Hosts Reporting | `stat` |
| 9 | Fleet Ranking (now) | `row` |
| 10 | Hosts by Licence State | `bargauge` |
| 11 | Non-genuine Flags per Host (topk 15) | `bargauge` |
| 12 | Fleet Snapshot & Hotspots | `row` |
| 13 | Hotspot: Hosts Not Genuine | `table` |
| 14 | Licence Status Matrix | `table` |
| 15 | Activation State with OS Build | `table` |
| 16 | Trends | `row` |
| 17 | Non-genuine Hosts (fleet) | `timeseries` |
| 18 | Licence States (fleet composition) | `timeseries` |
| 19 | Deep Dive | `row` |
| 20 | Offline / Tampered / Invalid (fleet) | `timeseries` |
| 21 | Per-host Flag Detail | `table` |
| 22 | Collector scrape health | `row` |
| 23 | Scrape Health by Host | `table` |
| 24 | Scrape Duration (topk 10) | `timeseries` |
| 25 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 2, `row`: 6, `stat`: 7, `table`: 5, `timeseries`: 5

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_license_status`
- `windows_os_info`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
