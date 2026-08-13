# mssql_resource_governor

## Summary

- File: `collector/mssql_resource_governor.collector.yml`
- `collector_name`: `mssql_resource_governor`
- `min_interval`: `60s`
- Metric count: `27`
- Profiles: `oltp` and `dwh`

## Purpose

This collector exposes SQL Server Resource Governor state, configuration and
runtime pressure at resource-pool and workload-group level.

Coverage includes:

- Resource Governor enabled and reconfiguration-pending state
- Pool CPU and memory limits
- Pool cumulative CPU, cache, compile memory and memory grants
- Memory grant waiters, timeouts and out-of-memory events
- Group importance, MAXDOP, CPU, memory-grant and concurrency limits
- Active/queued requests, CPU usage and CPU-limit violations

Labels are limited to `pool`, `workload_group` and `importance`, keeping series
cardinality bounded by the configured pools and groups.

## Permissions

```sql
GRANT VIEW ANY DEFINITION TO [monitoring_user];
GRANT VIEW SERVER STATE TO [monitoring_user];
```

SQL Server 2022 and later require the following permission for runtime DMVs:

```sql
GRANT VIEW SERVER PERFORMANCE STATE TO [monitoring_user];
```

## Example rules

```promql
mssql_resource_governor_reconfiguration_pending == 1
mssql_resource_governor_pool_memgrant_waiter_count > 0
increase(mssql_resource_governor_pool_memgrant_timeouts_total[10m]) > 0
increase(mssql_resource_governor_pool_out_of_memory_total[10m]) > 0
mssql_resource_governor_group_queued_requests > 0
increase(mssql_resource_governor_group_cpu_limit_violations_total[10m]) > 0
```

Cumulative counters reset after a SQL Server service restart or
`ALTER RESOURCE GOVERNOR RESET STATISTICS`.
