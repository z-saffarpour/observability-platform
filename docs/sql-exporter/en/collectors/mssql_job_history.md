# mssql_job_history

## Summary

- File: `collector/mssql_job_history.collector.yml`
- collector_name: `mssql_job_history`
- min_interval: `120s`
- metric count: `9`
- shared query_ref values: `mssql_job_history_avg_success_24h`, `mssql_job_history_avg_success_30d`, `mssql_job_history_failed_recent`, `mssql_job_history_failed_total`, `mssql_job_history_last`, `mssql_job_history_runs`

## Purpose

- SQL Agent job history (sysjobhistory) - failures, run counts, last durations.
- Live running -> mssql_job_running
- Dedicated fail alerts -> mssql_job_failed
- Inventory / last outcome snapshot -> mssql_job_inventory
- Backups -> mssql_backup

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Read SQL Agent job history in msdb.
- Notes from the source file:
  - GRANT SELECT ON msdb.dbo.sysjobhistory TO
  - GRANT SELECT ON msdb.dbo.sysjobs TO
  - GRANT SELECT ON msdb.dbo.syscategories TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_job_history_runs` | `gauge` | `job_name`, `category_name`, `run_status`, `run_status_desc`, `window` | `run_count` | query_ref=`mssql_job_history_runs` | Job outcome rows in lookback window by run_status (step_id=0). 0=Fail 1=Succeed 2=Retry 3=Cancel 4=InProgress. |
| `mssql_job_history_failed_total` | `gauge` | `window` | `failed_count` | query_ref=`mssql_job_history_failed_total` | Failed job outcomes (run_status=0, step_id=0) in lookback window. |
| `mssql_job_history_last_duration_seconds` | `gauge` | `job_name`, `category_name`, `run_status_desc`, `run_date` (YYYY-MM-DD), `run_time` (HH:MM:SS) | `duration_seconds` | query_ref=`mssql_job_history_last` | Duration seconds of the most recent job outcome (step_id=0) per job. |
| `mssql_job_history_last_age_seconds` | `gauge` | `job_name`, `category_name`, `run_status_desc`, `run_date`, `run_time` | `age_seconds` | query_ref=`mssql_job_history_last` | Seconds since the most recent job outcome (step_id=0) per job. |
| `mssql_job_history_last_status` | `gauge` | `job_name`, `category_name`, `run_status_desc`, `run_date`, `run_time` | `run_status` | query_ref=`mssql_job_history_last` | run_status of the most recent job outcome (step_id=0). |
| `mssql_job_history_last_run_timestamp` | `gauge` | `job_name`, `category_name`, `run_status_desc`, `run_date`, `run_time` | `run_unix` | query_ref=`mssql_job_history_last` | Unix seconds of the most recent job outcome start; prefer run_date/run_time labels for display. |
| `mssql_job_history_failed_duration_seconds` | `gauge` | `job_name`, `category_name`, `run_date` (YYYY-MM-DD), `run_time` (HH:MM:SS), `message_snip` | `duration_seconds` | query_ref=`mssql_job_history_failed_recent` | Recent failed job outcomes (last 24h), TOP 40 by finish time. |
| `mssql_job_history_avg_duration_seconds_24h` | `gauge` | `job_name`, `category_name` | `avg_duration_seconds` | query_ref=`mssql_job_history_avg_success_24h` | Average successful job duration (seconds) in last 24h (step_id=0, run_status=1). |
| `mssql_job_history_avg_duration_seconds_30d` | `gauge` | `job_name`, `category_name` | `avg_duration_seconds` | query_ref=`mssql_job_history_avg_success_30d` | Average successful job duration (seconds) in last 30d (step_id=0, run_status=1, duration>=60s). Limited by Agent history retention. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
