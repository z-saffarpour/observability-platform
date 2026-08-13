# mssql_job_running

## Summary

- File: `collector/mssql_job_running.collector.yml`
- collector_name: `mssql_job_running`
- min_interval: `30s`
- metric count: `5`
- shared query_ref values: `mssql_job_running_count`, `mssql_job_running_jobs`, `mssql_sqlagent_service`

## Purpose

- Currently running SQL Agent jobs (+ Agent service state).
- Inventory / last outcome -> mssql_job_inventory
- History -> mssql_job_history | Failures (alerts) -> mssql_job_failed
- SELECT on msdb.dbo.sysjobactivity, sysjobs, sysjobsteps, syscategories, syssessions
- VIEW SERVER STATE for dm_server_services (Agent status)

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Read SQL Agent job metadata in msdb.

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_sqlagent_running` | `gauge` | - | `is_running` | query_ref=`mssql_sqlagent_service` | 1 if SQL Server Agent service status_desc is Running, else 0. Empty if dm_server_services unavailable. |
| `mssql_job_running_count` | `gauge` | - | `running_count` | query_ref=`mssql_job_running_count` | Number of currently running SQL Agent jobs. |
| `mssql_job_running_seconds` | `gauge` | `job_name`, `category_name`, `enabled`, `step_id`, `step_name` | `running_seconds` | query_ref=`mssql_job_running_jobs` | Seconds since start for currently running SQL Agent jobs. |
| `mssql_job_running_start_timestamp` | `gauge` | `job_name`, `category_name`, `enabled`, `step_id`, `step_name` | `start_unix` | query_ref=`mssql_job_running_jobs` | Unix seconds when the job started (`sysjobactivity.start_execution_date`). |
| `mssql_job_running_step` | `gauge` | `job_name`, `category_name`, `enabled`, `step_id`, `step_name` | `step_id_value` | query_ref=`mssql_job_running_jobs` | Current/last-executed step_id for running jobs (0 if none yet). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
