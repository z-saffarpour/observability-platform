# mssql_blocking

## Summary

- File: `collector/mssql_blocking.collector.yml`
- collector_name: `mssql_blocking`
- min_interval: `30s`
- metric count: `6`
- shared query_ref values: `mssql_blocking_details`, `mssql_blocking_summary`, `mssql_head_blockers`

## Purpose

- Blocking / head-blocker metrics for Microsoft SQL Server.
- It is required that the SQL Server user has the following permissions:
- GRANT VIEW SERVER STATE TO
- GRANT VIEW ANY DEFINITION TO
- Auto-loaded via collectors: [mssql_*] and collector_files: ["collector/*.collector.yml"]

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Notes from the source file:
  - It is required that the SQL Server user has the following permissions:
  - GRANT VIEW SERVER STATE TO
  - GRANT VIEW ANY DEFINITION TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_blocking_count` | `gauge` | - | `blocked_count` | query_ref=`mssql_blocking_summary` | Number of currently blocked sessions. |
| `mssql_blocking_head_count` | `gauge` | - | `head_blocker_count` | query_ref=`mssql_blocking_summary` | Number of distinct head blockers. |
| `mssql_blocking_wait_ms` | `gauge` | `session_id`, `blocking_session_id`, `db`, `login_name`, `program_name`, `wait_type`, `status`, `command`, `statement_snip` | `wait_time_ms` | query_ref=`mssql_blocking_details` | Blocked session wait time (ms). |
| `mssql_blocking_elapsed_ms` | `gauge` | `session_id`, `blocking_session_id`, `db`, `login_name`, `program_name`, `wait_type`, `status`, `command`, `statement_snip` | `elapsed_ms` | query_ref=`mssql_blocking_details` | Blocked session elapsed time (ms). |
| `mssql_head_blocker_elapsed_ms` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `status`, `command`, `statement_snip`, `blocked_count` | `elapsed_ms` | query_ref=`mssql_head_blockers` | Head blocker session elapsed time (ms). |
| `mssql_head_blocker_cpu_ms` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `status`, `command`, `statement_snip`, `blocked_count` | `cpu_ms` | query_ref=`mssql_head_blockers` | Head blocker session CPU time (ms). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

