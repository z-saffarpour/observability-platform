# mssql_heavy_queries

## Summary

- File: `collector/mssql_heavy_queries.collector.yml`
- Collector: `mssql_heavy_queries`
- Interval: `60s`
- Purpose: near-real-time active requests whose elapsed time is at least five seconds.

## Metrics

- `mssql_requests_elapsed_ms`
- `mssql_requests_cpu_ms`
- `mssql_requests_granted_memory_mb`
- `mssql_requests_logical_reads`

All four metrics share `mssql_active_heavy_requests` and preserve up to 8000 Unicode characters in `statement_snip`.

## Permissions

The exporter login requires `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.

Enable `mssql_plan_cache_hotspots` alongside this collector when the heavy-query dashboard's historical plan-cache panels are required.

