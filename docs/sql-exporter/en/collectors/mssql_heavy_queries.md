# mssql_heavy_queries

## Summary

- File: `collector/mssql_heavy_queries.collector.yml`
- collector_name: `mssql_heavy_queries`
- min_interval: `60s`
- metric count: `13`
- shared query_ref values: `mssql_active_heavy_requests`, `mssql_top_cached_by_cpu`, `mssql_top_cached_by_elapsed`, `mssql_top_cached_by_grant`

## Purpose

- Heavy / active query metrics for Microsoft SQL Server.
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
| `mssql_requests_elapsed_ms` | `gauge` | `session_id`, `db`, `login_name`, `client_host`, `program_name`, `status`, `wait_type`, `command`, `query_hash`, `statement_snip` | `elapsed_ms` | query_ref=`mssql_active_heavy_requests` | Active request elapsed time in milliseconds (elapsed >= 5s). |
| `mssql_requests_cpu_ms` | `gauge` | `session_id`, `db`, `login_name`, `client_host`, `program_name`, `status`, `wait_type`, `command`, `query_hash`, `statement_snip` | `cpu_ms` | query_ref=`mssql_active_heavy_requests` | Active request CPU time in milliseconds (elapsed >= 5s). |
| `mssql_requests_granted_memory_mb` | `gauge` | `session_id`, `db`, `login_name`, `client_host`, `program_name`, `status`, `wait_type`, `command`, `query_hash`, `statement_snip` | `granted_mb` | query_ref=`mssql_active_heavy_requests` | Active request granted query memory in MB (elapsed >= 5s). |
| `mssql_requests_logical_reads` | `gauge` | `session_id`, `db`, `login_name`, `client_host`, `program_name`, `status`, `wait_type`, `command`, `query_hash`, `statement_snip` | `logical_reads` | query_ref=`mssql_active_heavy_requests` | Active request logical reads (elapsed >= 5s). |
| `mssql_top_query_total_worker_ms` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `total_worker_ms` | query_ref=`mssql_top_cached_by_cpu` | Top cached statements by total CPU/worker time (ms). |
| `mssql_top_query_avg_elapsed_ms` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `avg_elapsed_ms` | query_ref=`mssql_top_cached_by_cpu` | Average elapsed/duration time (ms) for top cached statements by total worker time. |
| `mssql_top_query_execution_count` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `execution_count` | query_ref=`mssql_top_cached_by_cpu` | Execution count for top cached statements by total worker time. |
| `mssql_top_query_total_elapsed_ms` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `total_elapsed_ms` | query_ref=`mssql_top_cached_by_elapsed` | Top cached statements by total elapsed/duration time (ms) - wall-clock query runtime. |
| `mssql_top_query_avg_duration_ms` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `avg_duration_ms` | query_ref=`mssql_top_cached_by_elapsed` | Average duration/elapsed time (ms) for top cached statements ranked by total elapsed. |
| `mssql_top_query_elapsed_execution_count` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `execution_count` | query_ref=`mssql_top_cached_by_elapsed` | Execution count for top cached statements ranked by total elapsed time. |
| `mssql_top_query_max_grant_mb` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `max_grant_mb` | query_ref=`mssql_top_cached_by_grant` | Top cached statements by max memory grant (MB), grant >= 1GB. |
| `mssql_top_query_max_used_grant_mb` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `max_used_grant_mb` | query_ref=`mssql_top_cached_by_grant` | Max used memory grant (MB) for top grant statements. |
| `mssql_top_query_grant_execution_count` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `execution_count` | query_ref=`mssql_top_cached_by_grant` | Execution count for top cached statements ranked by max memory grant. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

