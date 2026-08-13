# Collector textfile

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-textfile.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Textfile collector payloads (SSAS metrics pushed by the PowerShell collectors). Verifies the pipeline is alive and surfaces SSAS sessions, queries and memory.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-textfile` |
| Source file | [`winexp-col-textfile.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-textfile.json) |
| Tags | `windows_exporter`, `collector`, `textfile` |
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
| 3 | SSAS Down | `stat` |
| 4 | Service Not Running | `stat` |
| 5 | Collector Errors | `stat` |
| 6 | Processing Failures | `stat` |
| 7 | Total Sessions | `stat` |
| 8 | Total Connections | `stat` |
| 9 | Max Memory | `stat` |
| 10 | Fleet Query/s | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Top SSAS Memory (topk 15) | `bargauge` |
| 13 | Most Sessions (topk 15) | `bargauge` |
| 14 | Highest Query Rate (topk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | SSAS Health by Host | `table` |
| 17 | Hotspot: SSAS Down or Erroring | `table` |
| 18 | Hotspot: Heaviest SSAS Hosts | `table` |
| 19 | Trends | `row` |
| 20 | SSAS Up (bottomk 10) | `timeseries` |
| 21 | Sessions & Connections (topk 10) | `timeseries` |
| 22 | Query Rate (topk 10) | `timeseries` |
| 23 | SSAS Memory (topk 10) | `timeseries` |
| 24 | Deep Dive | `row` |
| 25 | Collector Errors (topk 10) | `timeseries` |
| 26 | Processing Failures (topk 10) | `timeseries` |
| 27 | SSAS Metric Detail by Counter Set | `table` |
| 28 | Collector scrape health | `row` |
| 29 | Scrape Health by Host | `table` |
| 30 | Scrape Duration (topk 10) | `timeseries` |
| 31 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 5, `timeseries`: 8

## Metrics used

- `ssas_collector_errors`
- `ssas_connections`
- `ssas_memory_usage_kilobytes`
- `ssas_processing_failures_total`
- `ssas_query_rate`
- `ssas_service_running`
- `ssas_sessions`
- `ssas_up`
- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
