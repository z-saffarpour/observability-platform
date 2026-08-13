# mssql_job_inventory

## Summary

- File: `collector/mssql_job_inventory.collector.yml`
- collector_name: `mssql_job_inventory`
- min_interval: `900s`
- metric count: `5`
- shared query_ref values: `mssql_job_activity_monitor`, `mssql_job_count`, `mssql_job_inventory`, `mssql_job_last_outcome`, `mssql_job_next_run`

## Purpose

- SQL Agent job inventory / last-run snapshot / next schedule.
- Live running -> mssql_job_running
- Failures (alerts) -> mssql_job_failed
- History / failures -> mssql_job_history
- Backups -> mssql_backup

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Read SQL Agent job metadata in msdb.
- Notes from the source file:
  - GRANT SELECT ON msdb.dbo.sysjobservers TO
  - GRANT SELECT ON msdb.dbo.sysjobs TO
  - GRANT SELECT ON msdb.dbo.syscategories TO
  - GRANT SELECT ON msdb.dbo.sysjobschedules TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_job_activity_monitor` | `gauge` | `job_name`, `category_name`, `enabled`, `last_run_status` ; value_label=`operation` | `last_run_date`, `last_run_time`, `last_run_duration`, `last_run_unix` | query_ref=`mssql_job_activity_monitor` | Last run date/time/duration/unix from sysjobservers (Job Activity Monitor style). `last_run_unix` = date+time (0 if never ran). |
| `mssql_job_enabled` | `gauge` | `job_name`, `category_name` | `enabled` | query_ref=`mssql_job_inventory` | 1 if SQL Agent job is enabled, else 0. |
| `mssql_job_count` | `gauge` | `enabled` | `job_count` | query_ref=`mssql_job_count` | SQL Agent job count by enabled flag. |
| `mssql_job_last_run_outcome` | `gauge` | `job_name`, `category_name`, `enabled` | `last_run_outcome` | query_ref=`mssql_job_last_outcome` | Last run outcome from sysjobservers: 0=Fail 1=Succeed 2=Retry 3=Cancel 4=InProgress 5=Unknown. |
| `mssql_job_next_run_age_seconds` | `gauge` | `job_name`, `category_name`, `enabled` | `next_run_age_seconds` | query_ref=`mssql_job_next_run` | Seconds until next scheduled run (negative = overdue). Only jobs with a next_run_date. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
