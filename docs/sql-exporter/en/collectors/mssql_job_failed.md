# mssql_job_failed

## Summary

- File: `collector/mssql_job_failed.collector.yml`
- collector_name: `mssql_job_failed`
- min_interval: `60s`
- metric count: `7`
- shared query_ref values: `mssql_job_failed_by_job`, `mssql_job_failed_current`, `mssql_job_failed_last`, `mssql_job_failed_recent`, `mssql_job_failed_total`

## Purpose

- SQL Agent job failures - dedicated alerting surface.
- Inventory -> mssql_job_inventory | Running -> mssql_job_running | Full history -> mssql_job_history
- GRANT SELECT ON msdb.dbo.sysjobhistory TO
- GRANT SELECT ON msdb.dbo.sysjobs TO
- GRANT SELECT ON msdb.dbo.sysjobservers TO

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Read SQL Agent job history in msdb.
- Notes from the source file:
  - GRANT SELECT ON msdb.dbo.sysjobhistory TO
  - GRANT SELECT ON msdb.dbo.sysjobs TO
  - GRANT SELECT ON msdb.dbo.sysjobservers TO
  - GRANT SELECT ON msdb.dbo.syscategories TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_job_failed_total` | `gauge` | `window` | `failed_count` | query_ref=`mssql_job_failed_total` | Failed job outcomes (run_status=0, step_id=0) in lookback window. |
| `mssql_job_failed_count` | `gauge` | `job_name`, `category_name`, `enabled`, `window` | `failed_count` | query_ref=`mssql_job_failed_by_job` | Failed job outcomes per job in lookback window. |
| `mssql_job_failed_last_age_seconds` | `gauge` | `job_name`, `category_name`, `enabled` | `age_seconds` | query_ref=`mssql_job_failed_last` | Seconds since the most recent failure for each job that failed in last 7 days. |
| `mssql_job_failed_last_duration_seconds` | `gauge` | `job_name`, `category_name`, `enabled` | `duration_seconds` | query_ref=`mssql_job_failed_last` | Duration seconds of the most recent failure per job (last 7 days). |
| `mssql_job_failed_recent_duration_seconds` | `gauge` | `job_name`, `category_name`, `enabled`, `run_date` (`YYYY-MM-DD`), `run_time` (`HH:MM:SS`), `message_snip` | `duration_seconds` | query_ref=`mssql_job_failed_recent` | Recent failed outcomes in last 24h (TOP 50), with message snip. |
| `mssql_job_failed_current` | `gauge` | `job_name`, `category_name`, `enabled`, `run_date` (`YYYY-MM-DD`), `run_time` (`HH:MM:SS`) | `is_failed` | query_ref=`mssql_job_failed_current` | 1 if last_run_outcome from sysjobservers is Failed (0). Useful for sticky fail alerts. |
| `mssql_job_failed_current_duration_seconds` | `gauge` | `job_name`, `category_name`, `enabled`, `run_date`, `run_time` | `duration_seconds` | query_ref=`mssql_job_failed_current` | Duration seconds of the sticky failed last run. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
