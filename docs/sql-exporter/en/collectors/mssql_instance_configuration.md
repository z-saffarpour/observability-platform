# mssql_instance_configuration

## Summary

- File: `collector/mssql_instance_configuration.collector.yml`
- collector_name: `mssql_instance_configuration`
- min_interval: `300s`
- metric count: `7`
- shared query_ref values: `mssql_instance_config`, `mssql_instance_ifi`, `mssql_instance_uptime`, `mssql_instance_trace_flags`
- Profiles: all role profiles (core baseline)

## Purpose

Instance-level configuration for drift detection across AG / FCI nodes:

- selected `sys.configurations` values (`value` vs `value_in_use`)
- Instant File Initialization for the Database Engine service
- instance start time / uptime
- globally enabled trace flags

Per-database settings stay in `mssql_database_configuration`. Security surface-area
knobs such as `xp_cmdshell` stay in `mssql_security`. Parallelism dashboards may
still read MAXDOP / server memory from `mssql_parallelism_configuration`; this
collector is the source of truth for configured vs in-use and IFI.

## Permissions and prerequisites

- `VIEW SERVER STATE`
- Global trace flags require permission to run `DBCC TRACESTATUS(-1)`; if that
  fails the metric is empty (scrape still succeeds).
- IFI uses `sys.dm_server_services.instant_file_initialization_enabled` (SQL Server
  2016+). Older versions return `-1`.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_instance_config_value` | `gauge` | `config_name` | `configured` | Configured `sys.configurations.value`. |
| `mssql_instance_config_value_in_use` | `gauge` | `config_name` | `in_use` | Effective `value_in_use`. |
| `mssql_instance_config_restart_pending` | `gauge` | `config_name` | `restart_pending` | `1` when configured differs from in-use. |
| `mssql_instance_ifi_enabled` | `gauge` | `service_name` | `ifi_enabled` | `1` enabled, `0` disabled, `-1` unavailable. |
| `mssql_instance_start_unix` | `gauge` | — | `start_unix` | SQL Server start time (Unix UTC). |
| `mssql_instance_uptime_seconds` | `gauge` | — | `uptime_seconds` | Seconds since `sqlserver_start_time`. |
| `mssql_instance_trace_flag` | `gauge` | `trace_flag` | `is_enabled` | Globally enabled trace flags. |

Selected `config_name` values include max/min server memory, MAXDOP, cost
threshold, optimize for ad hoc, backup compression/checksum, remote admin
connections, Database Mail XPs, Agent XPs, Ad Hoc Distributed Queries, blocked
process threshold, default trace, lightweight pooling, fill factor, max worker
threads, remote query timeout, user connections, contained database
authentication, priority boost, network packet size, and scan for startup procs.

## Operational notes

- Alert on `mssql_instance_config_restart_pending == 1` after a config change
  that did not take effect.
- Compare `mssql_instance_config_value_in_use` across AG replicas to catch
  memory / MAXDOP / ad-hoc drift.
- `mssql_instance_ifi_enabled == 0` means data-file growth and restore can stall
  on zero-initialization.

## Grafana

- Dashboard: `grafana/dashboards/sql-exporter/Collector/sqlx-instance-configuration.json`
