# Collector mssql

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-mssql.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

SQL Server engine health from windows_exporter: buffer pool (PLE, cache hit), blocking, batch/compile rates, log space, memory grants and lock/wait pressure.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-mssql` |
| Source file | [`winexp-col-mssql.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-mssql.json) |
| Tags | `windows_exporter`, `collector`, `mssql` |
| Panel count | 37 |
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
| 2 | MSSQL Scrape FAIL | `stat` |
| 3 | Blocking Now | `stat` |
| 4 | PLE < 300s | `stat` |
| 5 | Pending Grants | `stat` |
| 6 | Min PLE | `stat` |
| 7 | Max Log Used % | `stat` |
| 8 | Max Batch/s | `stat` |
| 9 | Total Connections | `stat` |
| 10 | Deadlocks/s | `stat` |
| 11 | Longest Txn | `stat` |
| 12 | Fleet Ranking (now) | `row` |
| 13 | Lowest PLE (bottomk 15) | `bargauge` |
| 14 | Highest Batch Requests/s (topk 15) | `bargauge` |
| 15 | Highest Log Used % (topk 15) | `bargauge` |
| 16 | Fleet Snapshot & Hotspots | `row` |
| 17 | SQL Health by Instance | `table` |
| 18 | Hotspots: PLE < 600s or Blocking | `table` |
| 19 | Hotspot: Transaction Log > 80% Used | `table` |
| 20 | Trends | `row` |
| 21 | Page Life Expectancy (bottomk 10) | `timeseries` |
| 22 | Batch Requests/s (topk 10) | `timeseries` |
| 23 | Blocked Processes (topk 10) | `timeseries` |
| 24 | Transaction Log Used % (topk 10) | `timeseries` |
| 25 | Server Memory vs Target (topk 10) | `timeseries` |
| 26 | Buffer Cache Hit % (bottomk 10) | `timeseries` |
| 27 | Deep Dive | `row` |
| 28 | Compilations / Recompilations per second (topk 10) | `timeseries` |
| 29 | Lock Waits / Timeouts / Deadlocks per second (topk 10) | `timeseries` |
| 30 | Access Methods: Page Splits & Full Scans per second (topk 10) | `timeseries` |
| 31 | Free List Stalls & Lazy Writes per second (topk 10) | `timeseries` |
| 32 | Memory Grants & Active Transactions (topk 10) | `timeseries` |
| 33 | Wait Statistics & Errors | `table` |
| 34 | Collector scrape health | `row` |
| 35 | Scrape Health by Host | `table` |
| 36 | Scrape Duration (topk 10) | `timeseries` |
| 37 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 10, `table`: 5, `timeseries`: 13

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_mssql_accessmethods_full_scans`
- `windows_mssql_accessmethods_page_splits`
- `windows_mssql_bufman_buffer_cache_hits`
- `windows_mssql_bufman_buffer_cache_lookups`
- `windows_mssql_bufman_free_list_stalls`
- `windows_mssql_bufman_lazywrites`
- `windows_mssql_bufman_page_life_expectancy_seconds`
- `windows_mssql_bufman_page_reads`
- `windows_mssql_bufman_page_writes`
- `windows_mssql_collector_success`
- `windows_mssql_databases_log_files_size_bytes`
- `windows_mssql_databases_log_files_used_size_bytes`
- `windows_mssql_databases_log_used_percent`
- `windows_mssql_genstats_blocked_processes`
- `windows_mssql_genstats_user_connections`
- `windows_mssql_locks_deadlocks`
- `windows_mssql_locks_lock_timeouts`
- `windows_mssql_locks_lock_waits`
- `windows_mssql_memmgr_outstanding_memory_grants`
- `windows_mssql_memmgr_pending_memory_grants`
- `windows_mssql_memmgr_target_server_memory_bytes`
- `windows_mssql_memmgr_total_server_memory_bytes`
- `windows_mssql_sql_errors_total`
- `windows_mssql_sqlstats_batch_requests`
- `windows_mssql_sqlstats_sql_compilations`
- `windows_mssql_sqlstats_sql_recompilations`
- `windows_mssql_transactions_active`
- `windows_mssql_transactions_longest_transaction_running_seconds`
- `windows_mssql_waitstats_lock_waits`
- `windows_mssql_waitstats_log_write_waits`
- `windows_mssql_waitstats_memory_grant_queue_waits`
- `windows_mssql_waitstats_network_io_waits`
- `windows_mssql_waitstats_page_io_latch_waits`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
