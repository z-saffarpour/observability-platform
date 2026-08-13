# mssql_polybase

## Summary

- File: `collector/mssql_polybase.collector.yml`
- `collector_name`: `mssql_polybase`
- Profile: `polybase`
- Grafana: `/d/sqlx-polybase/collector-polybase`
- `min_interval`: `30s`
- Metric count: `39`

## Purpose

Monitors PolyBase installation and enabled state, compute-node inventory and
resources, DMS service health and workers, distributed requests and request
steps, distributed SQL steps, external workers and operations, catalog counts
for external tables / data sources / file formats, and recent compute-node
errors. Labels are aggregated by node, status, type, or database to keep
cardinality bounded. Optional DMV and catalog queries return no rows when
PolyBase is absent or the object is unavailable, while the installation and
enabled metrics remain available.

## Permissions

```sql
GRANT VIEW SERVER STATE TO [monitoring_user];
```

For SQL Server 2022 and later:

```sql
GRANT VIEW SERVER PERFORMANCE STATE TO [monitoring_user];
```

Catalog metrics also need CONNECT and metadata visibility on databases that
host external tables, data sources, or file formats.

## Useful alerts

```promql
mssql_polybase_installed == 1 and mssql_polybase_enabled == 0
mssql_polybase_node_available == 0
mssql_polybase_node_received_age_seconds > 120
mssql_polybase_node_memory_used_ratio > 0.9
mssql_polybase_node_errors_recent > 0
mssql_polybase_requests{status=~"Failed|Cancelled"} > 0
mssql_polybase_request_max_start_age_seconds{status="Running"} > 3600
mssql_polybase_dms_services{status!~"(?i)ready|running|online|active"} > 0
mssql_polybase_dms_workers{status="Failed"} > 0
mssql_polybase_external_workers{status="Failed"} > 0
mssql_polybase_request_steps{status="Failed"} > 0
mssql_polybase_sql_steps{status="Failed"} > 0
```

CPU counters reset when the PolyBase process or SQL Server service restarts.
The aggregate error metric is a rolling 15-minute gauge, not a monotonic counter.
`mssql_polybase_node_error_age_seconds` exposes the TOP 50 errors from the last
60 minutes with full `details` text (up to 4000 chars) plus `error_id`,
`execution_id` and `spid` for SSMS correlation.
Object inventory metrics list each external table, data source and file format.
DMS / external worker byte and row gauges reflect rows currently retained in
the DMV (last ~1000 requests plus active work), not a lifetime counter.
