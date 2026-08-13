# Collector cpu

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-cpu.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

CPU pressure across the Windows fleet: busy vs user/kernel composition, interrupt and DPC load, run-queue pressure. Start at the KPI tiles, then Fleet Ranking to pick a host, then Hotspots for the shortlist.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-cpu` |
| Source file | [`winexp-col-cpu.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-cpu.json) |
| Tags | `windows_exporter`, `collector`, `cpu` |
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
| 3 | Hosts CPU >= 85% | `stat` |
| 4 | Hosts CPU >= 70% | `stat` |
| 5 | Max Busy % | `stat` |
| 6 | Median Busy % | `stat` |
| 7 | Fleet Avg Busy % | `stat` |
| 8 | Max Kernel % | `stat` |
| 9 | Run Queue > 5 | `stat` |
| 10 | Logical CPUs | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Top Busy % (100 - Idle) | `bargauge` |
| 13 | Top Kernel (Privileged) % | `bargauge` |
| 14 | Top Interrupts/s | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | CPU Health by Host | `table` |
| 17 | Hotspots: CPU >= 70% | `table` |
| 18 | Hotspots: CPU >= 85% (act now) | `table` |
| 19 | Trends | `row` |
| 20 | CPU Busy % (topk 10) | `timeseries` |
| 21 | CPU Composition (fleet average) | `timeseries` |
| 22 | Kernel vs User % (topk 10 each) | `timeseries` |
| 23 | Interrupts/s (topk 10) | `timeseries` |
| 24 | DPCs/s (topk 10) | `timeseries` |
| 25 | Run Queue Length (topk 10) | `timeseries` |
| 26 | Deep Dive | `row` |
| 27 | Core Frequency MHz (topk 10) | `timeseries` |
| 28 | Processor Performance % (topk 10) | `timeseries` |
| 29 | C-State Residency (fleet avg by state) | `timeseries` |
| 30 | Clock Interrupts/s (topk 10) | `timeseries` |
| 31 | Idle Break Events/s (topk 10) | `timeseries` |
| 32 | Collector scrape health | `row` |
| 33 | Scrape Health by Host | `table` |
| 34 | Scrape Duration (topk 10) | `timeseries` |
| 35 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 4, `timeseries`: 13

## Metrics used

- `windows_cpu_clock_interrupts_total`
- `windows_cpu_core_frequency_mhz`
- `windows_cpu_cstate_seconds_total`
- `windows_cpu_dpcs_total`
- `windows_cpu_idle_break_events_total`
- `windows_cpu_interrupts_total`
- `windows_cpu_logical_processor`
- `windows_cpu_processor_mperf_total`
- `windows_cpu_processor_performance_total`
- `windows_cpu_time_total`
- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_system_processor_queue_length`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
