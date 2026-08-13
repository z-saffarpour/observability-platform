# mssql_parallelism

## Summary

- File: `collector/mssql_parallelism.collector.yml`
- collector_name: `mssql_parallelism`
- min_interval: `60s`
- metric count: `6`
- shared query_ref values: `mssql_parallel_active`, `mssql_parallel_config`, `mssql_parallel_waits`

## Purpose

- Parallelism related waits, configs, and active parallel requests.
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
| `mssql_parallelism_wait_time_ms` | `gauge` | `wait_type` | `wait_time_ms` | query_ref=`mssql_parallel_waits` | Cumulative wait_time_ms for parallelism-related waits. |
| `mssql_parallelism_waiting_tasks` | `gauge` | `wait_type` | `waiting_tasks_count` | query_ref=`mssql_parallel_waits` | Cumulative waiting_tasks_count for parallelism-related waits. |
| `mssql_parallelism_configuration` | `gauge` | `name` | `value` | query_ref=`mssql_parallel_config` | Parallelism and related memory configs (MAXDOP, cost threshold, server memory, ad hoc). |
| `mssql_parallelism_active_request_elapsed_ms` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `dop`, `wait_type`, `statement_snip` | `elapsed_ms` | query_ref=`mssql_parallel_active` | Active parallel / large-grant requests (elapsed >= 5s). |
| `mssql_parallelism_active_request_dop` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `dop`, `wait_type`, `statement_snip` | `dop_value` | query_ref=`mssql_parallel_active` | DOP of active parallel / large-grant requests (elapsed >= 5s). |
| `mssql_parallelism_active_request_grant_mb` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `dop`, `wait_type`, `statement_snip` | `granted_mb` | query_ref=`mssql_parallel_active` | Granted memory MB for active parallel / large-grant requests (elapsed >= 5s). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
