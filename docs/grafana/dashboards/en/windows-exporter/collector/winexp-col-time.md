# Collector time

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-time.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Time synchronisation health. Clock offset above ~1s breaks Kerberos, AG failover and log correlation - treat offenders as incidents.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-time` |
| Source file | [`winexp-col-time.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-time.json) |
| Tags | `windows_exporter`, `collector`, `time` |
| Panel count | 29 |
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
| 3 | Offset > 1s | `stat` |
| 4 | Offset > 50ms | `stat` |
| 5 | Max \|Offset\| | `stat` |
| 6 | Median \|Offset\| | `stat` |
| 7 | Max NTP RTT | `stat` |
| 8 | No NTP Source | `stat` |
| 9 | Min NTP Sources | `stat` |
| 10 | Fleet Ranking (now) | `row` |
| 11 | Worst \|Offset\| (topk 15) | `bargauge` |
| 12 | Highest NTP RTT (topk 15) | `bargauge` |
| 13 | Fewest NTP Sources (bottomk 15) | `bargauge` |
| 14 | Fleet Snapshot & Hotspots | `row` |
| 15 | Time Sync Health by Host | `table` |
| 16 | Hotspots: \|Offset\| > 50ms | `table` |
| 17 | Trends | `row` |
| 18 | Computed Time Offset (topk 10 by \|offset\|) | `timeseries` |
| 19 | NTP Round Trip Delay (topk 10) | `timeseries` |
| 20 | Clock Frequency Adjustment (topk 10) | `timeseries` |
| 21 | NTP Time Sources (bottomk 10) | `timeseries` |
| 22 | Deep Dive | `row` |
| 23 | NTP Server Requests / Responses per second | `timeseries` |
| 24 | Host Clock vs Prometheus Clock (topk 10) | `timeseries` |
| 25 | Timezone by Host | `table` |
| 26 | Collector scrape health | `row` |
| 27 | Scrape Health by Host | `table` |
| 28 | Scrape Duration (topk 10) | `timeseries` |
| 29 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 4, `timeseries`: 8

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_os_timezone`
- `windows_time_clock_frequency_adjustment_ppb_total`
- `windows_time_computed_time_offset_seconds`
- `windows_time_current_timestamp_seconds`
- `windows_time_ntp_client_time_sources`
- `windows_time_ntp_round_trip_delay_seconds`
- `windows_time_ntp_server_incoming_requests_total`
- `windows_time_ntp_server_outgoing_responses_total`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
