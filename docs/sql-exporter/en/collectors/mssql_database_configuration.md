# mssql_database_configuration

## Summary

- File: `collector/mssql_database_configuration.collector.yml`
- `collector_name`: `mssql_database_configuration`
- `min_interval`: `300s`
- Metric count: `17`
- Recommended for: every profile

## Purpose

This collector exposes important per-database settings for configuration-drift
detection. It covers compatibility level, page verification, statistics,
isolation, parameterization, recovery, delayed durability, ADR, Query Store and
selected database-scoped optimizer configurations.

## Permissions

- `VIEW ANY DATABASE` to enumerate databases
- `CONNECT` access to each database
- `VIEW DATABASE STATE` is recommended for Query Store and scoped configuration

Inaccessible databases are skipped by per-database queries. A value of `-1`
means that a version-dependent feature is unavailable or could not be read.

## Metrics

| Metric | Meaning |
|---|---|
| `mssql_database_compatibility_level` | Database compatibility level |
| `mssql_database_page_verify_option` | `0=NONE`, `1=TORN_PAGE_DETECTION`, `2=CHECKSUM` |
| `mssql_database_auto_create_stats_enabled` | AUTO_CREATE_STATISTICS state |
| `mssql_database_auto_update_stats_enabled` | AUTO_UPDATE_STATISTICS state |
| `mssql_database_auto_update_stats_async_enabled` | Asynchronous statistics update state |
| `mssql_database_auto_close_enabled` | AUTO_CLOSE state |
| `mssql_database_auto_shrink_enabled` | AUTO_SHRINK state |
| `mssql_database_read_committed_snapshot_enabled` | RCSI state |
| `mssql_database_snapshot_isolation_state` | Snapshot Isolation state |
| `mssql_database_forced_parameterization_enabled` | PARAMETERIZATION FORCED state |
| `mssql_database_target_recovery_time_seconds` | Target recovery time |
| `mssql_database_delayed_durability` | Delayed durability mode |
| `mssql_database_accelerated_recovery_enabled` | ADR state |
| `mssql_database_query_store_actual_state` | Query Store actual state |
| `mssql_database_query_store_desired_state` | Query Store desired state |
| `mssql_database_query_store_readonly_reason` | Query Store read-only reason bitmask |
| `mssql_database_scoped_configuration` | Selected scoped setting value |

## Example rules

```promql
mssql_database_page_verify_option != 2
mssql_database_auto_close_enabled == 1
mssql_database_auto_shrink_enabled == 1
mssql_database_query_store_actual_state == 3
mssql_database_query_store_readonly_reason > 0
```

Scoped configuration values are exported for `MAXDOP`,
`LEGACY_CARDINALITY_ESTIMATION`, `PARAMETER_SNIFFING` and
`QUERY_OPTIMIZER_HOTFIXES`.

## Grafana

- Dashboard: `grafana/dashboards/sql-exporter/Collector/sqlx-database-configuration.json`
