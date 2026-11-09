# mssql_slow_query_history

## Summary

- File: `collector/mssql_slow_query_history.collector.yml`
- Collector: `mssql_slow_query_history`
- Interval: `300s`
- Purpose: the 50 slowest completed executions from the last 6 hours. The session threshold is `-DurationMs` on the installer. The default is 5000. A store install passes `-DurationMs 100`.

## Why these stay gauges

Each series is one execution. Elapsed time does not accumulate, so the type is a gauge. Every scrape reads the XEL files again and emits the same `event_time` while that execution is still inside the window and still in the top 50. The series then remains on the current list for up to 6 hours. It leaves the list when it is older than 6 hours, when the XEL files have rolled it off, or when 50 slower executions take the cap.

`mssql_heavy_queries` remains the live view of `sys.dm_exec_requests`.

## Metrics

- `mssql_slow_query_xe_up`
- `mssql_slow_query_elapsed_ms`
- `mssql_slow_query_cpu_ms`
- `mssql_slow_query_logical_reads`
- `mssql_slow_query_age_seconds`

`xe_up` is 1 only when `observability_slow_queries` is running and has an `event_file` target. An empty list together with `xe_up = 0` means capture is off.

Labels on the execution metrics are `event_time` (SQL Server local time, `yyyy-mm-dd hh:mm:ss.fff`), `db`, `obj`, `query_hash`, `statement_snip` (400 characters), `session_id`, and `event_name` (`statement`, `rpc`, or `proc_statement`). Elapsed and CPU are milliseconds. Age is seconds since the UTC event timestamp.

## Session

Install, without recreating an existing session:

`scripts/powershell/sql-exporter/Install-SlowQueryEventSession.ps1 -SqlInstance <instance>`

The session stores `sql_statement_completed`, `rpc_completed`, and `sp_statement_completed` at the installed `-DurationMs`. `Install-SqlExporterRemote.ps1` forwards that parameter. The default is 5000. `sql_exporter`, `telegraf`, and the install script are excluded. Files go under `{drive}:\Databases\Temp\XEvent\Machine\Instance\observability_slow_queries\` unless `-XelDirectory` is set. The buffer is 20 MB x 8. `STARTUP_STATE` is ON.

`-Replace` recreates the session and leaves existing XEL files on disk. `-Uninstall` stops and drops the session and does not delete the files.

`Install-SqlExporterRemote.ps1` runs that install when this collector is in the selected profile and `-SqlInstance` is set.

## Permissions

The exporter login needs `VIEW SERVER STATE`. On SQL Server 2022 and newer it also needs `VIEW SERVER PERFORMANCE STATE`, which `Create-SqlExporterLogin.sql` already grants.

Creating the session needs a principal that can create an event session and the directory. That is sysadmin in practice.

## Limits

- Only the latest cached file set is visible. If 20 MB x 8 rolls over in less than 6 hours, the list is shorter.
- `ALLOW_SINGLE_EVENT_LOSS` can drop a burst before it reaches disk.
- A procedure call can appear both as `rpc` and as `proc_statement`.
- A newer plan-cache execution is not required. This list does not use `sys.dm_exec_query_stats`.
- The current `sqlx-heavy-queries` panels still read `mssql_heavy_queries` only.
