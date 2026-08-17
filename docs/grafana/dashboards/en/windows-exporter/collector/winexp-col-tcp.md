# Collector tcp

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-tcp.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

TCP connection health: established sessions, connection failures, resets and retransmits. Rising resets or retransmits point at network or backlog problems.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-tcp` |
| Source file | [`winexp-col-tcp.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-tcp.json) |
| Tags | `windows_exporter`, `collector`, `tcp` |
| Panel count | 30 |
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
| 3 | Hosts with Failures | `stat` |
| 4 | Resets > 1/s | `stat` |
| 5 | Retransmit > 1% | `stat` |
| 6 | Max Established | `stat` |
| 7 | Total Established | `stat` |
| 8 | Max Retransmit % | `stat` |
| 9 | Total Failures/s | `stat` |
| 10 | Fleet Ranking (now) | `row` |
| 11 | Most Established Connections (topk 15) | `bargauge` |
| 12 | Highest Retransmit % (topk 15) | `bargauge` |
| 13 | Most Resets + Failures/s (topk 15) | `bargauge` |
| 14 | Fleet Snapshot & Hotspots | `row` |
| 15 | TCP Health by Host | `table` |
| 16 | Hotspots: Failures or Retransmits | `table` |
| 17 | Trends | `row` |
| 18 | Established Connections (topk 10) | `timeseries` |
| 19 | Connection Failures/s (topk 10) | `timeseries` |
| 20 | Resets/s (topk 10) | `timeseries` |
| 21 | Retransmit % (topk 10) | `timeseries` |
| 22 | New Connections In / Out per second (fleet) | `timeseries` |
| 23 | Deep Dive | `row` |
| 24 | Segments RX / TX per second (topk 10) | `timeseries` |
| 25 | Retransmitted Segments/s (topk 10) | `timeseries` |
| 26 | Connection Churn Detail | `table` |
| 27 | Collector scrape health | `row` |
| 28 | Scrape Health by Host | `table` |
| 29 | Scrape Duration (topk 10) | `timeseries` |
| 30 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 4, `timeseries`: 9

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_tcp_connection_failures_total`
- `windows_tcp_connections_active_total`
- `windows_tcp_connections_established`
- `windows_tcp_connections_passive_total`
- `windows_tcp_connections_reset_total`
- `windows_tcp_segments_received_total`
- `windows_tcp_segments_retransmitted_total`
- `windows_tcp_segments_sent_total`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
