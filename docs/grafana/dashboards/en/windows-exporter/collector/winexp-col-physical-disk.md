# Collector physical_disk

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-physical-disk.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Physical spindle / LUN service times, queueing and throughput. Use with Collector logical_disk: high physical latency on a shared disk explains slow volumes.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-physical-disk` |
| Source file | [`winexp-col-physical-disk.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-physical-disk.json) |
| Tags | `windows_exporter`, `collector`, `physical_disk` |
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
| 3 | Latency > 20ms | `stat` |
| 4 | Latency > 50ms | `stat` |
| 5 | Busy > 90% | `stat` |
| 6 | Queue > 8 | `stat` |
| 7 | Max Latency | `stat` |
| 8 | Max Busy % | `stat` |
| 9 | Fleet Throughput | `stat` |
| 10 | Fleet IOPS | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Highest Latency (topk 15) | `bargauge` |
| 13 | Highest Busy % (topk 15) | `bargauge` |
| 14 | Deepest Queue (topk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | Physical Disk Health by Host | `table` |
| 17 | Hotspots: Latency > 20ms | `table` |
| 18 | Hotspots: Busy > 90% | `table` |
| 19 | Trends | `row` |
| 20 | Read / Write Latency (topk 10) | `timeseries` |
| 21 | Busy % (topk 10) | `timeseries` |
| 22 | Throughput Read / Write (topk 10) | `timeseries` |
| 23 | IOPS Read / Write (topk 10) | `timeseries` |
| 24 | Queued Requests (topk 10) | `timeseries` |
| 25 | Deep Dive | `row` |
| 26 | Split IOs/s (topk 10) | `timeseries` |
| 27 | Read / Write Seconds per second (topk 10) | `timeseries` |
| 28 | Average I/O Size (topk 10) | `timeseries` |
| 29 | Throughput Detail by Disk | `table` |
| 30 | Collector scrape health | `row` |
| 31 | Scrape Health by Host | `table` |
| 32 | Scrape Duration (topk 10) | `timeseries` |
| 33 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 5, `timeseries`: 10

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_physical_disk_idle_seconds_total`
- `windows_physical_disk_read_bytes_total`
- `windows_physical_disk_read_latency_seconds_total`
- `windows_physical_disk_read_seconds_total`
- `windows_physical_disk_read_write_latency_seconds_total`
- `windows_physical_disk_reads_total`
- `windows_physical_disk_requests_queued`
- `windows_physical_disk_split_ios_total`
- `windows_physical_disk_write_bytes_total`
- `windows_physical_disk_write_latency_seconds_total`
- `windows_physical_disk_write_seconds_total`
- `windows_physical_disk_writes_total`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
