# SQL Server

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/windows-exporter/winexp-00-mssql.md) · [Exporter documentation](../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

The dashboard JSON does not provide a description.

## Details

| Property | Value |
|---|---|
| UID | `winexp-00-mssql` |
| Source file | [`winexp-00-mssql.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-mssql.json) |
| Tags | `windows_exporter`, `mssql`, `sqlserver`, `operations` |
| Panel count | 49 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_mssql_genstats_user_connections, job)` |
| `owner` | Owner | `query` | `label_values(windows_mssql_genstats_user_connections{job=~"${job:regex}"}, owner)` |
| `instance` | Server | `query` | `label_values(windows_mssql_genstats_user_connections{job=~"${job:regex}",owner=~"${owner:regex}"}, instance)` |
| `mssql_instance` | SQL Instance | `query` | `label_values(windows_mssql_genstats_user_connections{job=~"${job:regex}",owner=~"${owner:regex}",instance=~"${instance:regex}"}, mssql_instance)` |
| `database` | Database | `query` | `label_values(windows_mssql_databases_log_used_percent{job=~"${job:regex}",owner=~"${owner:regex}",instance=~"${instance:regex}",mssql_instance=~"${mssql_instance:regex}"}, database)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health KPIs (fleet totals) | `row` |
| 2 | User Connections | `stat` |
| 3 | Blocked Processes | `stat` |
| 4 | Pending Memory Grants | `stat` |
| 5 | Longest Transaction | `stat` |
| 6 | Max Log Used | `stat` |
| 7 | Min Buffer Hit | `stat` |
| 8 | Min PLE | `stat` |
| 9 | Collector Failed | `stat` |
| 10 | Fleet Pivot (instant tables - filter Owner/Server to narrow) | `row` |
| 11 | SQL Instance Health Pivot | `table` |
| 12 | Top Log Used % (Pivot) | `table` |
| 13 | Blocked / Grants / Long Tx Hotspots | `table` |
| 14 | Failed MSSQL Collectors | `table` |
| 15 | Memory Pressure Pivot | `table` |
| 16 | Graphs: Workload & Throughput (collapsed - filter Server first) | `row` |
| 17 | Batch Requests / Compilations / Recompilations | `timeseries` |
| 18 | Connections, Logins and Logouts | `timeseries` |
| 19 | SQL Errors / Attentions | `timeseries` |
| 20 | Transactions Activity | `timeseries` |
| 21 | Graphs: Buffer Manager & Memory (collapsed - filter Server first) | `row` |
| 22 | Page Life Expectancy | `timeseries` |
| 23 | Buffer Cache Hit Ratio | `timeseries` |
| 24 | Page Reads / Writes / Lazy Writes | `timeseries` |
| 25 | Total vs Target Server Memory | `timeseries` |
| 26 | Memory Clerks Breakdown | `timeseries` |
| 27 | Memory Grants Pending / Outstanding | `timeseries` |
| 28 | Free List Stalls / Read Ahead | `timeseries` |
| 29 | Graphs: Databases (collapsed - filter Server/Database first) | `row` |
| 30 | Log Used % Trend | `timeseries` |
| 31 | Data / Log File Size | `timeseries` |
| 32 | DB Transactions / Active / Write Transactions | `timeseries` |
| 33 | Log Flushes / Growths / Truncations | `timeseries` |
| 34 | Graphs: Locks & Blocking (collapsed - filter Server first) | `row` |
| 35 | Blocked Processes | `timeseries` |
| 36 | Deadlocks by Resource | `timeseries` |
| 37 | Lock Waits / Timeouts / Requests | `timeseries` |
| 38 | Average Lock Wait Time | `timeseries` |
| 39 | Lock Count by Resource | `timeseries` |
| 40 | Graphs: Access Methods (collapsed - filter Server first) | `row` |
| 41 | Full Scans vs Index Searches | `timeseries` |
| 42 | Page Splits / Forwarded Records / Lock Escalations | `timeseries` |
| 43 | Graphs: TempDB & Version Store (collapsed - filter Server first) | `row` |
| 44 | Version Store Size / Generation / Cleanup | `timeseries` |
| 45 | TempDB Free Space / Active Temp Tables | `timeseries` |
| 46 | Graphs: Process & Collector (collapsed - filter Server first) | `row` |
| 47 | sqlservr CPU | `timeseries` |
| 48 | sqlservr Working Set / Private Bytes | `timeseries` |
| 49 | Collector Duration | `timeseries` |

Panel type summary: `row`: 9, `stat`: 8, `table`: 5, `timeseries`: 27

## Metrics used

- `windows_mssql_accessmethods_forwarded_records`
- `windows_mssql_accessmethods_full_scans`
- `windows_mssql_accessmethods_index_searches`
- `windows_mssql_accessmethods_page_splits`
- `windows_mssql_accessmethods_range_scans`
- `windows_mssql_accessmethods_table_lock_escalations`
- `windows_mssql_bufman_buffer_cache_hits`
- `windows_mssql_bufman_buffer_cache_lookups`
- `windows_mssql_bufman_free_list_stalls`
- `windows_mssql_bufman_lazywrites`
- `windows_mssql_bufman_page_life_expectancy_seconds`
- `windows_mssql_bufman_page_reads`
- `windows_mssql_bufman_page_writes`
- `windows_mssql_bufman_read_ahead_pages`
- `windows_mssql_collector_duration_seconds`
- `windows_mssql_collector_success`
- `windows_mssql_databases_active_transactions`
- `windows_mssql_databases_data_files_size_bytes`
- `windows_mssql_databases_log_files_size_bytes`
- `windows_mssql_databases_log_flushes`
- `windows_mssql_databases_log_growths`
- `windows_mssql_databases_log_truncations`
- `windows_mssql_databases_log_used_percent`
- `windows_mssql_databases_transactions`
- `windows_mssql_genstats_active_temp_tables`
- `windows_mssql_genstats_blocked_processes`
- `windows_mssql_genstats_logins`
- `windows_mssql_genstats_logouts`
- `windows_mssql_genstats_temp_tables_creations`
- `windows_mssql_genstats_user_connections`
- `windows_mssql_locks_count`
- `windows_mssql_locks_deadlocks`
- `windows_mssql_locks_lock_requests`
- `windows_mssql_locks_lock_timeouts`
- `windows_mssql_locks_lock_wait_seconds`
- `windows_mssql_locks_lock_waits`
- `windows_mssql_memmgr_database_cache_memory_bytes`
- `windows_mssql_memmgr_free_memory_bytes`
- `windows_mssql_memmgr_granted_workspace_memory_bytes`
- `windows_mssql_memmgr_outstanding_memory_grants`
- `windows_mssql_memmgr_pending_memory_grants`
- `windows_mssql_memmgr_stolen_server_memory_bytes`
- `windows_mssql_memmgr_target_server_memory_bytes`
- `windows_mssql_memmgr_total_server_memory_bytes`
- `windows_mssql_sql_errors_total`
- `windows_mssql_sqlstats_batch_requests`
- `windows_mssql_sqlstats_sql_attentions`
- `windows_mssql_sqlstats_sql_compilations`
- `windows_mssql_sqlstats_sql_recompilations`
- `windows_mssql_transactions_active`
- `windows_mssql_transactions_longest_transaction_running_seconds`
- `windows_mssql_transactions_tempdb_free_space_bytes`
- `windows_mssql_transactions_version_cleanup_rate_bytes`
- `windows_mssql_transactions_version_generation_rate_bytes`
- `windows_mssql_transactions_version_store_size_bytes`
- `windows_process_cpu_time_total`
- `windows_process_private_bytes`
- `windows_process_working_set_bytes`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
