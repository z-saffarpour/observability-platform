# Collector standard

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-standard.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Core SQL Server instance health: UP/workload/errors, memory, selected perf counters, database inventory, and fleet rollup. Collector mssql_standard @ 30s.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-standard` |
| Source file | [`sqlx-standard.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-standard.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `standard` |
| Panel count | 51 |
| Refresh interval | `30s` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_database_state{job="sql_exporter", instance=~"${instance:regex}"}, db)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Instances reporting mssql_up=1. | `stat` |
| 3 | Exporter reachable but SQL target down. | `stat` |
| 4 | Peak batch requests/sec across selected servers. | `stat` |
| 5 | Total user connections (perf counter snapshot). | `stat` |
| 6 | Peak deadlock rate across fleet. | `stat` |
| 7 | Peak user error rate. | `stat` |
| 8 | Log Reuse Blocked | `stat` |
| 9 | Bad DB State | `stat` |
| 10 | Workload & Throughput | `row` |
| 11 | Batch Requests /s | `timeseries` |
| 12 | User Connections | `timeseries` |
| 13 | Compilations & Recompilations /s | `timeseries` |
| 14 | Transactions /s - Top 10 DBs | `timeseries` |
| 15 | Checkpoint Pages /s | `timeseries` |
| 16 | Batch /s now - Top 10 servers | `bargauge` |
| 17 | Errors & Transaction Log | `row` |
| 18 | User Errors /s | `timeseries` |
| 19 | Kill Connection Errors /s | `timeseries` |
| 20 | Log Growths /s - Top 10 DBs | `timeseries` |
| 21 | Growing Logs (rate > 0) | `table` |
| 22 | SQL Process & OS Memory | `row` |
| 23 | SQL Memory Utilization % | `timeseries` |
| 24 | SQL Resident Memory | `timeseries` |
| 25 | OS Memory Used % | `timeseries` |
| 26 | Virtual Memory (committed) | `timeseries` |
| 27 | Page Faults /s | `timeseries` |
| 28 | OS Memory - Used / Available / Total | `timeseries` |
| 29 | Locks & Blocking Signals | `row` |
| 30 | Lock Waits /s | `timeseries` |
| 31 | Lock Wait Time rate (ms/s) | `timeseries` |
| 32 | Processes Blocked | `timeseries` |
| 33 | Table Lock Escalations /s | `timeseries` |
| 34 | Write Transactions /s | `timeseries` |
| 35 | Query Efficiency Counters | `row` |
| 36 | Full Scans /s | `timeseries` |
| 37 | Index Searches /s | `timeseries` |
| 38 | Page Splits /s | `timeseries` |
| 39 | Workfiles / Worktables /s | `timeseries` |
| 40 | Forwarded Records /s | `timeseries` |
| 41 | Database Inventory | `row` |
| 42 | Database State (0=ONLINE) | `table` |
| 43 | Recovery Model (1=FULL 2=BULK 3=SIMPLE) | `table` |
| 44 | Read-Only Databases | `table` |
| 45 | Log Reuse Wait (!= NOTHING) | `table` |
| 46 | Attention - DB state != ONLINE | `table` |
| 47 | Fleet - Instance Identity | `row` |
| 48 | Instance Versions | `table` |
| 49 | Instance Versions (legacy exporter - redeploy) | `table` |
| 50 | Per-Server Rollup | `table` |
| 51 | Bad Databases - detail (Server + Database) | `table` |

Panel type summary: `bargauge`: 1, `row`: 8, `stat`: 8, `table`: 10, `timeseries`: 24

## Metrics used

- `mssql_batch_requests`
- `mssql_checkpoint_pages_per_sec`
- `mssql_compilations_per_sec`
- `mssql_database_is_read_only`
- `mssql_database_recovery_model`
- `mssql_database_state`
- `mssql_deadlocks`
- `mssql_hostname`
- `mssql_kill_connection_errors`
- `mssql_log_growths`
- `mssql_log_reuse_wait`
- `mssql_memory_utilization_percentage`
- `mssql_os_memory`
- `mssql_page_fault_count`
- `mssql_perf_counter`
- `mssql_product_version`
- `mssql_recompilations_per_sec`
- `mssql_resident_memory_bytes`
- `mssql_transactions`
- `mssql_up`
- `mssql_user_connections_current`
- `mssql_user_errors`
- `mssql_virtual_memory_bytes`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
