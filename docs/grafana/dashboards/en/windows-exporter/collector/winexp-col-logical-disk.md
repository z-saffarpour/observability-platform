# Collector logical_disk

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-logical-disk.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Volume capacity and latency per drive letter. Free % answers "will it fill up", latency and busy % answer "is it slow right now".

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-logical-disk` |
| Source file | [`winexp-col-logical-disk.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-logical-disk.json) |
| Tags | `windows_exporter`, `collector`, `logical_disk` |
| Panel count | 36 |
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
| 3 | Free < 10% | `stat` |
| 4 | Free < 15% | `stat` |
| 5 | Latency > 20ms | `stat` |
| 6 | Latency > 50ms | `stat` |
| 7 | Busy > 90% | `stat` |
| 8 | Min Free % | `stat` |
| 9 | Max Latency | `stat` |
| 10 | Max Busy % | `stat` |
| 11 | Fleet Free Space | `stat` |
| 12 | Fleet Ranking (now) | `row` |
| 13 | Lowest Free % (bottomk 15) | `bargauge` |
| 14 | Highest Latency (topk 15) | `bargauge` |
| 15 | Highest Busy % (topk 15) | `bargauge` |
| 16 | Fleet Snapshot & Hotspots | `row` |
| 17 | Volume Health by Host | `table` |
| 18 | Hotspots: Free % < 15 | `table` |
| 19 | Hotspots: Latency > 20ms | `table` |
| 20 | Trends | `row` |
| 21 | Free % (bottomk 10) | `timeseries` |
| 22 | Read / Write Latency (topk 10) | `timeseries` |
| 23 | Busy % (topk 10) | `timeseries` |
| 24 | Throughput Read / Write (topk 10) | `timeseries` |
| 25 | IOPS Read / Write (topk 10) | `timeseries` |
| 26 | Queued Requests (topk 10) | `timeseries` |
| 27 | Deep Dive | `row` |
| 28 | Split IOs/s (topk 10) | `timeseries` |
| 29 | Average Queue Depth Read / Write (topk 10) | `timeseries` |
| 30 | Used % (topk 10) | `timeseries` |
| 31 | Capacity Detail by Volume | `table` |
| 32 | Volume Inventory | `table` |
| 33 | Collector scrape health | `row` |
| 34 | Scrape Health by Host | `table` |
| 35 | Scrape Duration (topk 10) | `timeseries` |
| 36 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 10, `table`: 6, `timeseries`: 11

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_logical_disk_avg_read_requests_queued`
- `windows_logical_disk_avg_write_requests_queued`
- `windows_logical_disk_free_bytes`
- `windows_logical_disk_idle_seconds_total`
- `windows_logical_disk_info`
- `windows_logical_disk_read_bytes_total`
- `windows_logical_disk_read_latency_seconds_total`
- `windows_logical_disk_read_write_latency_seconds_total`
- `windows_logical_disk_reads_total`
- `windows_logical_disk_requests_queued`
- `windows_logical_disk_size_bytes`
- `windows_logical_disk_split_ios_total`
- `windows_logical_disk_write_bytes_total`
- `windows_logical_disk_write_latency_seconds_total`
- `windows_logical_disk_writes_total`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
