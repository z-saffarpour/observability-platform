# mssql_errorlog_signals

## Summary

- File: `collector/mssql_errorlog_signals.collector.yml`
- collector_name: `mssql_errorlog_signals`
- min_interval: `300s`
- metric count: `1`
- shared query_ref values: `mssql_errorlog_signals`

## Purpose

- ERRORLOG signal counters for selected SQL errors (last N hours).
- Signals include backup-device disk exhaustion (OS error 112) and full database
  filegroups.
- Uses xp_readerrorlog - keep interval high on busy hosts.
- VIEW SERVER STATE; xp_readerrorlog permission (sysadmin or secured equivalent)

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: xp_readerrorlog.
- Notes from the source file:
  - Uses xp_readerrorlog - keep interval high on busy hosts.
  - VIEW SERVER STATE; xp_readerrorlog permission (sysadmin or secured equivalent)

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_errorlog_signal_count` | `gauge` | `signal` | `event_count` | query_ref=`mssql_errorlog_signals` | Count of selected ERRORLOG signals in the last 6 hours. |

Current `signal` label values:

- `backup_disk_full_112`
- `filegroup_full_1105`
- `transaction_log_full_9002` (e.g. full due to `LOG_BACKUP`)
- `buffer_latch_timeout_845`
- `ag_suspend_from_redo` (Always On data movement suspended / `SUSPEND_FROM_REDO`)
- `redo_error_3313`
- `redo_worker_failure`

Security login signals (`18456_login_failed`, `18470_login_disabled`,
`anonymous_login_failed`) were moved to `mssql_security_errorlog_signal_count`
in `mssql_security`.

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

