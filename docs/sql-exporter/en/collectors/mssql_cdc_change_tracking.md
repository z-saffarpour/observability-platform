# mssql_cdc_change_tracking

## Summary

- File: `collector/mssql_cdc_change_tracking.collector.yml`
- `collector_name`: `mssql_cdc_change_tracking`
- `min_interval`: `300s`
- Metric count: `17`
- Profiles: `oltp`, `dwh` and `replication`

## Purpose

This collector monitors Change Data Capture and Change Tracking health without
creating a Prometheus label for every table or capture instance.

CDC coverage includes:

- Per-database enablement and capture-instance count
- Time since the CDC high endpoint was processed
- Age of the oldest retained capture-instance LSN
- Capture and cleanup job enabled/running state
- Continuous mode, polling interval, retention and cleanup threshold

Change Tracking coverage includes enablement, retention, automatic cleanup,
tracked-table count, current version, oldest visible minimum valid version and
the resulting version window.

## Permissions

- `VIEW ANY DATABASE`
- `CONNECT` access to relevant databases
- `VIEW DATABASE STATE` and CDC metadata access are recommended
- Job metrics require read access to `msdb.dbo.cdc_jobs`, `sysjobs`,
  `sysjobactivity` and `syssessions`

When metadata cannot be read, diagnostic values for that section are `-1` or
the section returns no rows; other queries continue independently.

## Alerting notes

```promql
mssql_cdc_enabled == 1 and mssql_cdc_capture_lag_seconds > 300
mssql_cdc_job_enabled{job_type="capture"} == 0
mssql_cdc_job_running{job_type="capture"} == 0
mssql_change_tracking_enabled == 1 and mssql_change_tracking_auto_cleanup_enabled == 0
```

For a continuous capture job, `job_running == 0` normally indicates a problem;
one-shot jobs require a schedule-aware rule. The version-window metric is not a
replacement for a consumer's `last_sync_version`; each consumer must still
validate its version with `CHANGE_TRACKING_MIN_VALID_VERSION`.
