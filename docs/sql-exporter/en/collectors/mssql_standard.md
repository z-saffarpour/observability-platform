# mssql_standard

## Summary

- File: `collector/mssql_standard.collector.yml`
- collector_name: `mssql_standard`
- min_interval: `30s`
- metric count: `25`
- shared query_ref values: `mssql_perf_counters`, `mssql_process_memory`, `mssql_standard_checkpoint_pages`, `mssql_standard_compilation_counters`, `mssql_standard_connection_counters`, `mssql_standard_log_reuse_wait`

## Purpose

- Core instance identity + unique counters not owned by specialized collectors.
- buffer_pool  -> PLE, page read/write, lazy write, checkpoint, buffer cache hit
- file_io      -> IO stall (per file / latency)
- database_size_growth -> database/file sizes
- connections_detail   -> sessions by host/login/program/db

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Notes from the source file:
  - GRANT VIEW ANY DEFINITION TO
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_up` | `gauge` | - | `count` | query | UP Status. |
| `mssql_hostname` | `gauge` | `hostname` | static_value=`1` | static_value | Database server hostname |
| `mssql_product_version` | `gauge` | `product_version_major`, `product_version_minor`, `product_version_build`, `product_version_batch`, `product_version`, `edition` | static_value=`1` | static_value | Instance version (Major.Minor). |
| `mssql_local_time_seconds` | `gauge` | - | `unix_time` | query | UTC epoch seconds (Unix time from GETUTCDATE). |
| `mssql_database_state` | `gauge` | `db`, `state_desc` | `db_state` | query | Databases states: 0=ONLINE 1=RESTORING 2=RECOVERING 3=RECOVERY_PENDING 4=SUSPECT 5=EMERGENCY 6=OFFLINE 7=COPYING 10=OFFLINE_SECONDARY. |
| `mssql_database_is_read_only` | `gauge` | `db` | `is_read_only` | query | 1 if database is read_only (monthly Full backup policy), else 0. |
| `mssql_database_recovery_model` | `gauge` | `db`, `recovery_model_desc` | `recovery_model` | query | Databases recovery_model: 1=FULL 2=BULK_LOGGED 3=SIMPLE |
| `mssql_transactions` | `counter` | `db` | `cntr_value` | query | Transactions/sec per database (raw cntr_value; use rate()). |
| `mssql_log_growths` | `counter` | `db` | `cntr_value` | query | Number of times the transaction log has been expanded, per database. |
| `mssql_deadlocks` | `counter` | - | `cntr_value` | query | Number of lock requests that resulted in a deadlock (raw cntr_value; use rate()). |
| `mssql_user_errors` | `counter` | - | `cntr_value` | query | Number of user errors (raw cntr_value; use rate()). |
| `mssql_kill_connection_errors` | `counter` | - | `cntr_value` | query | Severe errors that caused SQL Server to kill the connection (raw cntr_value; use rate()). |
| `mssql_batch_requests` | `counter` | - | `cntr_value` | query | Number of command batches received (raw cntr_value; use rate()). |
| `mssql_user_connections_current` | `gauge` | - | `user_connections_current` | query_ref=`mssql_standard_connection_counters` | Current number of user connections. |
| `mssql_compilations_per_sec` | `counter` | - | `compilations_per_sec` | query_ref=`mssql_standard_compilation_counters` | SQL compilations/sec raw cntr_value (cumulative); use rate(). |
| `mssql_recompilations_per_sec` | `counter` | - | `recompilations_per_sec` | query_ref=`mssql_standard_compilation_counters` | SQL re-compilations/sec raw cntr_value (cumulative); use rate(). |
| `mssql_checkpoint_pages_per_sec` | `counter` | - | `checkpoint_pages_per_sec` | query_ref=`mssql_standard_checkpoint_pages` | Checkpoint pages/sec raw cntr_value (cumulative); use rate(). |
| `mssql_log_reuse_wait` | `gauge` | `db`, `log_reuse_wait_desc` | `log_reuse_wait` | query_ref=`mssql_standard_log_reuse_wait` | Current log_reuse_wait value per database. |
| `mssql_perf_counter` | `gauge` | `object`, `counter`, `instance` | `cntr_value` | query_ref=`mssql_perf_counters` | Selected SQL Server performance counters (raw cntr_value). Use rate() for /sec counters. |
| `mssql_resident_memory_bytes` | `gauge` | - | `resident_memory_bytes` | query_ref=`mssql_process_memory` | SQL Server resident memory size (AKA working set). |
| `mssql_virtual_memory_bytes` | `gauge` | - | `virtual_memory_bytes` | query_ref=`mssql_process_memory` | SQL Server committed virtual memory size. |
| `mssql_memory_utilization_percentage` | `gauge` | - | `memory_utilization_percentage` | query_ref=`mssql_process_memory` | The percentage of committed memory that is in the working set. |
| `mssql_page_fault_count` | `counter` | - | `page_fault_count` | query_ref=`mssql_process_memory` | The number of page faults that were incurred by the SQL Server process. |
| `mssql_os_memory` | `gauge` | - ; value_label=`'state'` | `used`, `available`, `total` | query | OS physical memory, used and available. |
| `mssql_os_page_file` | `gauge` | - ; value_label=`'state'` | `used`, `available`, `total` | query | OS page file, used and available. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
