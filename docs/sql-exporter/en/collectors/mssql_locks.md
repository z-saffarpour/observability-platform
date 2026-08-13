# mssql_locks

## Summary

- File: `collector/mssql_locks.collector.yml`
- collector_name: `mssql_locks`
- min_interval: `30s`
- metric count: `7`
- shared query_ref values: `mssql_latch_stats`, `mssql_lock_related_requests`, `mssql_locks_summary`, `mssql_locks_waiting_count`, `mssql_locks_waiting_detail`

## Purpose

- Lock inventory and waiting locks.
- GRANT VIEW SERVER STATE TO

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Access to user databases.
- Notes from the source file:
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_locks_count` | `gauge` | `resource_type`, `request_mode`, `request_status`, `db` | `lock_count` | query_ref=`mssql_locks_summary` | Lock counts by resource type, mode and status. |
| `mssql_locks_waiting` | `gauge` | - | `waiting_locks` | query_ref=`mssql_locks_waiting_count` | Number of lock requests in WAIT status. |
| `mssql_locks_wait_time_ms` | `gauge` | `session_id`, `db`, `resource_type`, `request_mode`, `wait_type`, `login_name` | `wait_time_ms` | query_ref=`mssql_locks_waiting_detail` | Wait time (ms) for sessions waiting on locks. |
| `mssql_latch_wait_time_ms` | `gauge` | `latch_class` | `wait_time_ms` | query_ref=`mssql_latch_stats` | Cumulative latch wait time (ms) for selected latch classes. |
| `mssql_latch_waits` | `gauge` | `latch_class` | `waiting_requests_count` | query_ref=`mssql_latch_stats` | Cumulative latch waits for selected latch classes. |
| `mssql_lock_related_request_elapsed_ms` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `status`, `wait_type`, `command`, `statement_snip` | `elapsed_ms` | query_ref=`mssql_lock_related_requests` | Active user requests with lock/latch waits or elapsed >= 3s. |
| `mssql_lock_related_request_wait_ms` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `status`, `wait_type`, `command`, `statement_snip` | `wait_time_ms` | query_ref=`mssql_lock_related_requests` | Wait time (ms) for active lock/latch-related requests. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

