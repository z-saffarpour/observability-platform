# mssql_scheduler

## Summary

- File: `collector/mssql_scheduler.collector.yml`
- collector_name: `mssql_scheduler`
- min_interval: `30s`
- metric count: `12`
- shared query_ref values: `mssql_scheduler_totals`, `mssql_schedulers`, `mssql_sys_info`

## Purpose

- Scheduler / SOS worker pressure and CPU topology.
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
| `mssql_scheduler_runnable_tasks` | `gauge` | `scheduler_id`, `cpu_id` | `runnable_tasks_count` | query_ref=`mssql_schedulers` | Runnable tasks waiting for CPU on visible online schedulers. |
| `mssql_scheduler_current_tasks` | `gauge` | `scheduler_id`, `cpu_id` | `current_tasks_count` | query_ref=`mssql_schedulers` | Current tasks bound to visible online schedulers. |
| `mssql_scheduler_active_workers` | `gauge` | `scheduler_id`, `cpu_id` | `active_workers_count` | query_ref=`mssql_schedulers` | Active workers on visible online schedulers. |
| `mssql_scheduler_work_queue` | `gauge` | `scheduler_id`, `cpu_id` | `work_queue_count` | query_ref=`mssql_schedulers` | Work queue length on visible online schedulers (worker starvation signal). |
| `mssql_scheduler_pending_disk_io` | `gauge` | `scheduler_id`, `cpu_id` | `pending_disk_io_count` | query_ref=`mssql_schedulers` | Pending disk I/O count on visible online schedulers. |
| `mssql_scheduler_load_factor` | `gauge` | `scheduler_id`, `cpu_id` | `load_factor` | query_ref=`mssql_schedulers` | Scheduler load_factor (higher = busier). |
| `mssql_scheduler_total_runnable` | `gauge` | - | `total_runnable` | query_ref=`mssql_scheduler_totals` | Sum of runnable_tasks_count across visible online schedulers. |
| `mssql_scheduler_total_work_queue` | `gauge` | - | `total_work_queue` | query_ref=`mssql_scheduler_totals` | Sum of work_queue_count across visible online schedulers. |
| `mssql_scheduler_online_count` | `gauge` | - | `online_count` | query_ref=`mssql_scheduler_totals` | Count of VISIBLE ONLINE schedulers. |
| `mssql_os_cpu_count` | `gauge` | - | `cpu_count` | query_ref=`mssql_sys_info` | Logical CPU count from sys.dm_os_sys_info. |
| `mssql_os_hyperthread_ratio` | `gauge` | - | `hyperthread_ratio` | query_ref=`mssql_sys_info` | Hyperthread ratio from sys.dm_os_sys_info. |
| `mssql_os_physical_memory_kb` | `gauge` | - | `physical_memory_kb` | query_ref=`mssql_sys_info` | physical_memory_kb from sys.dm_os_sys_info. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

