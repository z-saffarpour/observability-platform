# Collector net

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-net.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Network throughput, link utilisation and error/discard counters per NIC. Any non-zero error rate is worth a driver / cabling / vSwitch check.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-net` |
| Source file | [`winexp-col-net.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-net.json) |
| Tags | `windows_exporter`, `collector`, `net` |
| Panel count | 35 |
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
| 3 | Hosts with Errors | `stat` |
| 4 | Hosts with Discards | `stat` |
| 5 | NICs Util > 70% | `stat` |
| 6 | Max NIC Util % | `stat` |
| 7 | Fleet RX | `stat` |
| 8 | Fleet TX | `stat` |
| 9 | Total Errors/s | `stat` |
| 10 | Max Output Queue | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Top RX Bps (topk 15) | `bargauge` |
| 13 | Top TX Bps (topk 15) | `bargauge` |
| 14 | Top Errors + Discards/s (topk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | Network Health by Host | `table` |
| 17 | Per-NIC Detail | `table` |
| 18 | Hotspots: Errors or Discards > 0 | `table` |
| 19 | Trends | `row` |
| 20 | RX Bps (topk 10) | `timeseries` |
| 21 | TX Bps (topk 10) | `timeseries` |
| 22 | NIC Utilisation % (topk 10) | `timeseries` |
| 23 | Errors/s (topk 10) | `timeseries` |
| 24 | Discards/s (topk 10) | `timeseries` |
| 25 | Output Queue Length (topk 10) | `timeseries` |
| 26 | Deep Dive | `row` |
| 27 | Packets RX / TX per second (topk 10) | `timeseries` |
| 28 | Unknown Protocol Packets/s (topk 10) | `timeseries` |
| 29 | Average Packet Size (topk 10) | `timeseries` |
| 30 | Inbound vs Outbound Errors (fleet) | `timeseries` |
| 31 | NIC Inventory & Link Speed | `table` |
| 32 | Collector scrape health | `row` |
| 33 | Scrape Health by Host | `table` |
| 34 | Scrape Duration (topk 10) | `timeseries` |
| 35 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 5, `timeseries`: 12

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_net_bytes_received_total`
- `windows_net_bytes_sent_total`
- `windows_net_bytes_total`
- `windows_net_current_bandwidth_bytes`
- `windows_net_output_queue_length_packets`
- `windows_net_packets_outbound_discarded_total`
- `windows_net_packets_outbound_errors_total`
- `windows_net_packets_received_discarded_total`
- `windows_net_packets_received_errors_total`
- `windows_net_packets_received_total`
- `windows_net_packets_received_unknown_total`
- `windows_net_packets_sent_total`
- `windows_net_packets_total`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
