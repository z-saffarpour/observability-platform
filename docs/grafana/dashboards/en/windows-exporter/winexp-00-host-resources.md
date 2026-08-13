# Host Resources

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/windows-exporter/winexp-00-host-resources.md) · [Exporter documentation](../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Fleet-safe: Pivot tables first (instant). Graphs are collapsed - filter Server (1-5 hosts) before expanding.

## Details

| Property | Value |
|---|---|
| UID | `winexp-00-host-resources` |
| Source file | [`winexp-00-host-resources.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-host-resources.json) |
| Tags | `windows_exporter`, `cpu`, `memory`, `disk`, `network`, `host`, `pivot` |
| Panel count | 27 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_exporter_build_info, job)` |
| `instance` | Server | `query` | `label_values(windows_exporter_build_info{job=~"${job:regex}"}, instance)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health Snapshot | `row` |
| 2 | Hosts Up | `stat` |
| 3 | Hosts Down | `stat` |
| 4 | CPU > 85% | `stat` |
| 5 | Mem Avail < 10% | `stat` |
| 6 | Disk Free < 10% | `stat` |
| 7 | Disk Lat > 20ms | `stat` |
| 8 | Queue > 5 | `stat` |
| 9 | Commit > 85% | `stat` |
| 10 | Pivot - Host Resources | `row` |
| 11 | Host Pivot (CPU / Memory / System) | `table` |
| 12 | Pivot - Disk | `row` |
| 13 | Disk Pivot (Free % / Latency / Busy %) | `table` |
| 14 | Pivot - Network | `row` |
| 15 | Network Pivot (RX / TX / Errors) | `table` |
| 16 | Graphs - CPU | `row` |
| 17 | CPU % (topk 10) | `timeseries` |
| 18 | Processor Queue (topk 10) | `timeseries` |
| 19 | Graphs - Memory | `row` |
| 20 | Mem Available % (bottomk 10) | `timeseries` |
| 21 | Commit % (topk 10) | `timeseries` |
| 22 | Graphs - Disk | `row` |
| 23 | Disk Throughput (topk 10) | `timeseries` |
| 24 | Disk Latency (topk 10) | `timeseries` |
| 25 | Disk Busy % (topk 10) | `timeseries` |
| 26 | Graphs - Network | `row` |
| 27 | Network Bandwidth (topk 10) | `timeseries` |

Panel type summary: `row`: 8, `stat`: 8, `table`: 3, `timeseries`: 8

## Metrics used

- `up`
- `windows_cpu_logical_processor`
- `windows_cpu_time_total`
- `windows_exporter_build_info`
- `windows_logical_disk_free_bytes`
- `windows_logical_disk_idle_seconds_total`
- `windows_logical_disk_read_bytes_total`
- `windows_logical_disk_read_latency_seconds_total`
- `windows_logical_disk_size_bytes`
- `windows_logical_disk_write_bytes_total`
- `windows_logical_disk_write_latency_seconds_total`
- `windows_memory_available_bytes`
- `windows_memory_commit_limit`
- `windows_memory_committed_bytes`
- `windows_memory_physical_total_bytes`
- `windows_net_bytes_received_total`
- `windows_net_bytes_sent_total`
- `windows_net_packets_outbound_discarded_total`
- `windows_net_packets_outbound_errors_total`
- `windows_net_packets_received_discarded_total`
- `windows_net_packets_received_errors_total`
- `windows_system_processes`
- `windows_system_processor_queue_length`
- `windows_system_system_up_time`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
