# mssql_memory

## Summary

- File: `collector/mssql_memory.collector.yml`
- collector_name: `mssql_memory`
- min_interval: `60s`
- metric count: `16`
- shared query_ref values: `mssql_memory_active_grants`, `mssql_memory_clerk_topn_ratio`, `mssql_memory_clerks`, `mssql_memory_manager_mb`, `mssql_memory_server_summary`, `mssql_resource_semaphores`

## Purpose

- Memory metrics for Microsoft SQL Server.
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
| `mssql_memory_clerk_size_kb` | `gauge` | `clerk_type`, `clerk_name` | `size_kb` | query_ref=`mssql_memory_clerks` | Memory clerk size in KB (top clerks; SUM(pages_kb)). |
| `mssql_resource_semaphore_available_mb` | `gauge` | `resource_semaphore_id`, `pool_id` | `available_memory_mb` | query_ref=`mssql_resource_semaphores` | Query memory grant available (MB) per resource semaphore. |
| `mssql_resource_semaphore_granted_mb` | `gauge` | `resource_semaphore_id`, `pool_id` | `granted_memory_mb` | query_ref=`mssql_resource_semaphores` | Query memory currently granted (MB) per resource semaphore. |
| `mssql_resource_semaphore_grantee_count` | `gauge` | `resource_semaphore_id`, `pool_id` | `grantee_count` | query_ref=`mssql_resource_semaphores` | Number of queries currently granted memory. |
| `mssql_resource_semaphore_waiter_count` | `gauge` | `resource_semaphore_id`, `pool_id` | `waiter_count` | query_ref=`mssql_resource_semaphores` | Number of queries waiting for memory grant (RESOURCE_SEMAPHORE risk). |
| `mssql_resource_semaphore_target_mb` | `gauge` | `resource_semaphore_id`, `pool_id` | `target_memory_mb` | query_ref=`mssql_resource_semaphores` | Target memory (MB) for resource semaphore. |
| `mssql_resource_semaphore_max_mb` | `gauge` | `resource_semaphore_id`, `pool_id` | `max_memory_mb` | query_ref=`mssql_resource_semaphores` | Max memory (MB) for resource semaphore. |
| `mssql_memory_manager_mb` | `gauge` | `counter` | `value_mb` | query_ref=`mssql_memory_manager_mb` | SQL Memory Manager counters converted to MB. |
| `mssql_memory_grants_outstanding` | `gauge` | - | `cntr_value` | query | Memory grants currently outstanding. |
| `mssql_memory_grants_pending` | `gauge` | - | `cntr_value` | query | Memory grants currently pending (RESOURCE_SEMAPHORE pressure). |
| `mssql_memory_target_server_mb` | `gauge` | - | `target_server_mb` | query_ref=`mssql_memory_server_summary` | Target Server Memory (MB). |
| `mssql_memory_total_server_mb` | `gauge` | - | `total_server_mb` | query_ref=`mssql_memory_server_summary` | Total Server Memory (MB). |
| `mssql_memory_stolen_mb` | `gauge` | - | `stolen_server_mb` | query_ref=`mssql_memory_server_summary` | Stolen Server Memory (MB). |
| `mssql_memory_locked_pages_mb` | `gauge` | - | `locked_pages_mb` | query_ref=`mssql_memory_server_summary` | Locked pages allocated (MB). |
| `mssql_memory_clerk_topn_ratio` | `gauge` | - | `topn_ratio_percent` | query_ref=`mssql_memory_clerk_topn_ratio` | Percent of total clerk pages held by top N clerks by size. |
| `mssql_memory_active_grant_mb` | `gauge` | `session_id`, `db`, `login_name`, `wait_type`, `statement_snip` | `granted_mb` | query_ref=`mssql_memory_active_grants` | Active requests with significant memory grant (>= 100MB). `statement_snip` up to 8000 chars. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

