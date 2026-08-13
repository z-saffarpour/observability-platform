# mssql_waits

## Summary

- File: `collector/mssql_waits.collector.yml`
- collector_name: `mssql_waits`
- min_interval: `120s`
- metric count: `10`
- shared query_ref values: `mssql_wait_stats`, `mssql_waits_by_class`, `mssql_waits_summary`

## Purpose

- Wait stats metrics for Microsoft SQL Server.
- It is required that the SQL Server user has the following permissions:
- GRANT VIEW SERVER STATE TO
- Auto-loaded via collectors: [mssql_*] and collector_files: ["collector/*.collector.yml"]

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Notes from the source file:
  - It is required that the SQL Server user has the following permissions:
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_wait_time_ms` | `gauge` | `wait_type` | `wait_time_ms` | query_ref=`mssql_wait_stats` | Cumulative wait time (ms) for top wait types (filtered benign waits). |
| `mssql_wait_waiting_tasks` | `gauge` | `wait_type` | `waiting_tasks_count` | query_ref=`mssql_wait_stats` | Cumulative waiting tasks count for top wait types. |
| `mssql_wait_signal_time_ms` | `gauge` | `wait_type` | `signal_wait_time_ms` | query_ref=`mssql_wait_stats` | Cumulative signal wait time (ms) for top wait types. |
| `mssql_wait_resource_time_ms` | `gauge` | `wait_type` | `resource_wait_time_ms` | query_ref=`mssql_wait_stats` | Resource wait time (ms) = wait_time - signal_wait for top wait types. |
| `mssql_wait_max_time_ms` | `gauge` | `wait_type` | `max_wait_time_ms` | query_ref=`mssql_wait_stats` | Max wait time (ms) observed for top wait types. |
| `mssql_waits_nonbenign_percent` | `gauge` | - | `nonbenign_percent` | query_ref=`mssql_waits_summary` | Percent of cumulative wait time that is non-benign. |
| `mssql_waits_top5_share_percent` | `gauge` | - | `top5_share_percent` | query_ref=`mssql_waits_summary` | Share of non-benign wait time contributed by top 5 waits. |
| `mssql_waits_signal_ratio_percent` | `gauge` | - | `signal_ratio_percent` | query_ref=`mssql_waits_summary` | Signal wait ratio percent over non-benign wait time. |
| `mssql_waits_by_class_time_ms` | `gauge` | `wait_class` | `wait_time_ms` | query_ref=`mssql_waits_by_class` | Cumulative wait time (ms) grouped by wait class. |
| `mssql_waits_by_class_tasks` | `gauge` | `wait_class` | `waiting_tasks_count` | query_ref=`mssql_waits_by_class` | Cumulative waiting tasks grouped by wait class. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

