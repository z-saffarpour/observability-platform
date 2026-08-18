# mssql_log_usage

## Summary

- File: `collector/mssql_log_usage.collector.yml`
- collector_name: `mssql_log_usage`
- min_interval: `60s`
- metric count: `6`
- shared query_ref values: `mssql_log_space`, `mssql_log_space_system`

## Purpose

- Transaction log usage - shared for DWH and OLTP.
- User-database metrics exclude `master`, `model`, `tempdb`, `msdb`, `DWConfiguration`, `DWDiagnostics`, and `DWQueue`.
- System databases are exported as `mssql_log_*_system`.
- GRANT VIEW SERVER STATE TO

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Notes from the source file:
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_log_used_percent` | `gauge` | `db`, `log_reuse_wait_desc`, `recovery_model_desc` | `used_percent` | query_ref=`mssql_log_space` | Transaction log used percent per user database (excludes master, model, tempdb, msdb, DWConfiguration, DWDiagnostics, DWQueue). |
| `mssql_log_used_mb` | `gauge` | `db`, `log_reuse_wait_desc`, `recovery_model_desc` | `used_mb` | query_ref=`mssql_log_space` | Transaction log used size (MB) per user database (excludes master, model, tempdb, msdb, DWConfiguration, DWDiagnostics, DWQueue). |
| `mssql_log_total_mb` | `gauge` | `db`, `log_reuse_wait_desc`, `recovery_model_desc` | `total_mb` | query_ref=`mssql_log_space` | Transaction log total size (MB) per user database (excludes master, model, tempdb, msdb, DWConfiguration, DWDiagnostics, DWQueue). |
| `mssql_log_used_percent_system` | `gauge` | `db`, `log_reuse_wait_desc`, `recovery_model_desc` | `used_percent` | query_ref=`mssql_log_space_system` | Transaction log used percent for system databases (master, model, tempdb, msdb, DWConfiguration, DWDiagnostics, DWQueue). |
| `mssql_log_used_mb_system` | `gauge` | `db`, `log_reuse_wait_desc`, `recovery_model_desc` | `used_mb` | query_ref=`mssql_log_space_system` | Transaction log used size (MB) for system databases (master, model, tempdb, msdb, DWConfiguration, DWDiagnostics, DWQueue). |
| `mssql_log_total_mb_system` | `gauge` | `db`, `log_reuse_wait_desc`, `recovery_model_desc` | `total_mb` | query_ref=`mssql_log_space_system` | Transaction log total size (MB) for system databases (master, model, tempdb, msdb, DWConfiguration, DWDiagnostics, DWQueue). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

