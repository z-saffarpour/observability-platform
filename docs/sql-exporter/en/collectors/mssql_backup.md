# mssql_backup

## Summary

- File: `collector/mssql_backup.collector.yml`
- collector_name: `mssql_backup`
- min_interval: `900s`
- metric count: `10`
- shared query_ref values: `mssql_backup_age`, `mssql_backup_damaged`, `mssql_backup_job_failed`, `mssql_backup_job_failed_total`, `mssql_backup_log_size_today`, `mssql_backup_recent_performance`, `mssql_backup_size`, `mssql_backup_verify_failed`, `mssql_recent_backup`

## Purpose

- Database backup freshness and size (msdb.dbo.backupset).
- backupset lookback for AGE / last-backup metrics is a rolling 400-day window
  (`DATEADD(DAY, -400, GETDATE())`) so monthly Full backups older than 90 days
  are not reported as "never". Shorter windows remain for today/7d/24h metrics.
- Jobs -> mssql_job_inventory / mssql_job_running / mssql_job_history
- GRANT SELECT ON msdb.dbo.backupset TO

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Read msdb backup metadata (for example backupset).
- Notes from the source file:
  - GRANT SELECT ON msdb.dbo.backupset TO
  - GRANT SELECT ON msdb.dbo.sysjobs / sysjobsteps / sysjobhistory / syscategories TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_recent_backup` | `gauge` | `db` ; value_label=`operation` | `last_full_backup_datetime`, `last_diff_backup_datetime`, `last_log_backup_datetime` | query_ref=`mssql_recent_backup` | Unix epoch of last Full/Diff/Log backup per database (0 = never). |
| `mssql_backup_age_seconds` | `gauge` | `db`, `backup_type`, `recovery_model`, `is_read_only` | `age_seconds` | query_ref=`mssql_backup_age` | Seconds since last backup by type. -1 = never backed up (or log N/A for SIMPLE). is_read_only=1 -> monthly Full policy. |
| `mssql_backup_size_bytes` | `gauge` | `db`, `backup_type` | `backup_size_bytes` | query_ref=`mssql_backup_size` | Size in bytes of the most recent backup by type (0 if none). |
| `mssql_backup_log_size_today_bytes` | `gauge` | `db` | `log_size_today_bytes` | query_ref=`mssql_backup_log_size_today` | Sum of transaction-log backup sizes finished on the local calendar day, per database. |
| `mssql_backup_damaged_7d` | `gauge` | `db`, `backup_type` | `damaged_count` | query_ref=`mssql_backup_damaged` | Damaged backupset rows (is_damaged=1) in last 7 days by database and type. |
| `mssql_backup_job_failed_24h` | `gauge` | `job_name`, `category_name` | `failed_count` | query_ref=`mssql_backup_job_failed` | Failed SQL Agent job outcomes (24h) for jobs that contain a BACKUP step. |
| `mssql_backup_job_failed_total_24h` | `gauge` | - | `failed_count` | query_ref=`mssql_backup_job_failed_total` | Total failed backup-related Agent job outcomes in last 24h. |
| `mssql_backup_throughput_mb_s` | `gauge` | `db`, `backup_type` | `throughput_mb_s` | query_ref=`mssql_backup_recent_performance` | Throughput of the most recent backup by type (MB/s). |
| `mssql_backup_compression_ratio` | `gauge` | `db`, `backup_type` | `compression_ratio` | query_ref=`mssql_backup_recent_performance` | backup_size / compressed_backup_size for the most recent backup by type. |
| `mssql_backup_verify_failed_count` | `gauge` | - | `failed_count` | query_ref=`mssql_backup_verify_failed` | Failed VERIFYONLY-related SQL Agent outcomes in last 24h. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
