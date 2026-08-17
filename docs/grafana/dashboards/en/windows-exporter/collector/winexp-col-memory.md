# Collector memory

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-memory.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Memory pressure: available vs commit, paging and swap activity, kernel pool growth and cache composition. Low Available % plus rising page faults means the host is trimming working sets.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-memory` |
| Source file | [`winexp-col-memory.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-memory.json) |
| Tags | `windows_exporter`, `collector`, `memory` |
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
| 3 | Available < 10% | `stat` |
| 4 | Available < 15% | `stat` |
| 5 | Commit > 85% | `stat` |
| 6 | Min Available % | `stat` |
| 7 | Median Available % | `stat` |
| 8 | Max Commit % | `stat` |
| 9 | Faults > 5k/s | `stat` |
| 10 | Fleet RAM | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Lowest Available % (bottomk 15) | `bargauge` |
| 13 | Highest Commit % (topk 15) | `bargauge` |
| 14 | Highest Page Faults/s (topk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | Memory Health by Host | `table` |
| 17 | Hotspots: Available < 15% | `table` |
| 18 | Hotspots: Commit > 85% | `table` |
| 19 | Trends | `row` |
| 20 | Available % (bottomk 10) | `timeseries` |
| 21 | Commit % (topk 10) | `timeseries` |
| 22 | Page Faults/s (topk 10) | `timeseries` |
| 23 | Swap Read / Write per second (topk 10) | `timeseries` |
| 24 | Kernel Pool Bytes (topk 10) | `timeseries` |
| 25 | Cache Composition (fleet totals) | `timeseries` |
| 26 | Deep Dive | `row` |
| 27 | Free System Page Table Entries (bottomk 10) | `timeseries` |
| 28 | Demand Zero Faults/s (topk 10) | `timeseries` |
| 29 | Transition Faults/s (topk 10) | `timeseries` |
| 30 | Cache Faults/s (topk 10) | `timeseries` |
| 31 | Memory Composition Detail | `table` |
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
- `windows_memory_available_bytes`
- `windows_memory_cache_bytes`
- `windows_memory_cache_faults_total`
- `windows_memory_commit_limit`
- `windows_memory_committed_bytes`
- `windows_memory_demand_zero_faults_total`
- `windows_memory_free_and_zero_page_list_bytes`
- `windows_memory_free_system_page_table_entries`
- `windows_memory_modified_page_list_bytes`
- `windows_memory_page_faults_total`
- `windows_memory_physical_total_bytes`
- `windows_memory_pool_nonpaged_bytes`
- `windows_memory_pool_paged_bytes`
- `windows_memory_standby_cache_core_bytes`
- `windows_memory_standby_cache_normal_priority_bytes`
- `windows_memory_standby_cache_reserve_bytes`
- `windows_memory_swap_page_operations_total`
- `windows_memory_swap_page_reads_total`
- `windows_memory_swap_page_writes_total`
- `windows_memory_system_cache_resident_bytes`
- `windows_memory_transition_faults_total`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
