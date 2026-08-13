# mssql_restore

## Summary

- File: `collector/mssql_restore.collector.yml`
- collector_name: `mssql_restore`
- min_interval: `300s`
- metric count: `14`
- shared query_ref values: `mssql_restore_db_state`, `mssql_restore_job_failed`, `mssql_restore_job_failed_total`, `mssql_restore_last`, `mssql_restore_last_by_type`

## Purpose

- Restore / backup-sync freshness (msdb.dbo.restorehistory + backupset).
- Mirrors the Power BI restore monitor: last restore per destination DB,
- lag since restored backup (Difference Restore), source server/db, type, size.
- Intended for secondary / standby hosts that continuously RESTORE Full/Diff/Log
- from another instance (log-shipping-like), e.g. sql-host-02\NODE.
- restorehistory lookback is a rolling 400-day window (not calendar year).

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Read msdb restore metadata (for example restorehistory).
- Notes from the source file:
  - GRANT SELECT ON msdb.dbo.restorehistory TO
  - GRANT SELECT ON msdb.dbo.backupset TO
  - GRANT SELECT ON msdb.dbo.backupmediafamily TO
  - GRANT SELECT ON msdb.dbo.sysjobs / sysjobsteps / sysjobhistory / syscategories TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_restore_lag_seconds` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `lag_seconds` | query_ref=`mssql_restore_last` | Seconds since backup_finish_date of the most recent restore (Power BI Difference Restore). -1 = none in last 400 days. |
| `mssql_restore_gap_to_rpo_seconds` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `lag_seconds` | query_ref=`mssql_restore_last` | Alias of `mssql_restore_lag_seconds` for existing alerts/dashboards. |
| `mssql_restore_age_seconds` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `age_seconds` | query_ref=`mssql_restore_last` | Seconds since restore_date of the most recent restore per destination database. -1 = never. |
| `mssql_restore_last_unix` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `restore_unix` | query_ref=`mssql_restore_last` | Unix epoch of last restore_date (0 = never). |
| `mssql_restore_backup_unix` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `backup_unix` | query_ref=`mssql_restore_last` | Unix epoch of backup_finish_date for the last restored backup (0 = never). |
| `mssql_restore_backup_size_bytes` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `backup_size_bytes` | query_ref=`mssql_restore_last` | backup_size of the most recent restored backup (0 if unknown). |
| `mssql_restore_throughput_mb_s` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `throughput_mb_s` | query_ref=`mssql_restore_last` | Throughput of the source backup for the most recently restored backup (MB/s). |
| `mssql_restore_last_by_type_lag_seconds` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `lag_seconds` | query_ref=`mssql_restore_last_by_type` | Seconds since backup_finish_date of last restore by backup type (full/diff/log). -1 = none in last 400 days. |
| `mssql_restore_last_by_type_age_seconds` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `age_seconds` | query_ref=`mssql_restore_last_by_type` | Seconds since restore_date of last restore by backup type. -1 = none in last 400 days. |
| `mssql_restore_db_standby` | `gauge` | `db`, `state_desc` | `is_in_standby` | query_ref=`mssql_restore_db_state` | 1 if database is in standby / read-only restoring mode (is_in_standby=1). |
| `mssql_restore_db_state` | `gauge` | `db`, `state_desc` | `state` | query_ref=`mssql_restore_db_state` | sys.databases.state for DBs that are RESTORING/RECOVERING/standby or have restorehistory in last 400 days. |
| `mssql_restore_job_failed_24h` | `gauge` | `job_name`, `category_name` | `failed_count` | query_ref=`mssql_restore_job_failed` | Failed SQL Agent job outcomes (24h) for jobs that contain a RESTORE step. |
| `mssql_restore_job_executions_24h` | `gauge` | `job_name`, `category_name` | `execution_count` | query_ref=`mssql_restore_job_failed` | Total SQL Agent job outcomes (24h) for restore jobs that had at least one failure. |
| `mssql_restore_job_failed_total_24h` | `gauge` | - | `failed_count` | query_ref=`mssql_restore_job_failed_total` | Total failed restore-related Agent job outcomes in last 24h. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

