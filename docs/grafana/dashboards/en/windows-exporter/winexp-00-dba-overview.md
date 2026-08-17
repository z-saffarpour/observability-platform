# DBA Overview

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/windows-exporter/winexp-00-dba-overview.md) · [Exporter documentation](../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Prometheus replica of classic DBA Overview V02 (InfluxDB hybrid). Fleet KPIs, service state, memory/CPU/disk/network.

## Details

| Property | Value |
|---|---|
| UID | `winexp-00-dba-overview` |
| Source file | [`winexp-00-dba-overview.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-dba-overview.json) |
| Tags | `windows_exporter`, `dba`, `overview`, `operations` |
| Panel count | 15 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `Host` | Host | `query` | `label_values(up{job="windows_exporter"}, instance)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Untitled | `stat` |
| 2 | Untitled | `stat` |
| 3 | Untitled | `stat` |
| 4 | Untitled | `stat` |
| 5 | Untitled | `stat` |
| 6 | Server State | `table` |
| 7 | Server State | `table` |
| 8 | SQL Service State | `table` |
| 9 | SQL Analysis Service State | `table` |
| 10 | Memory | `table` |
| 11 | CPU | `table` |
| 12 | Backup Disk Free | `table` |
| 13 | Processor Queue | `table` |
| 14 | Network | `table` |
| 15 | Disk Free | `table` |

Panel type summary: `stat`: 5, `table`: 10

## Metrics used

- `up`
- `windows_cpu_time_total`
- `windows_logical_disk_free_bytes`
- `windows_logical_disk_size_bytes`
- `windows_memory_available_bytes`
- `windows_memory_physical_total_bytes`
- `windows_net_bytes_received_total`
- `windows_net_bytes_sent_total`
- `windows_service_state`
- `windows_system_processor_queue_length`
- `windows_system_system_up_time`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
