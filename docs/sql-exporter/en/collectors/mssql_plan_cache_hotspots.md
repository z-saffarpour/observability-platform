# mssql_plan_cache_hotspots

## Summary

- File: `collector/mssql_plan_cache_hotspots.collector.yml`
- Collector: `mssql_plan_cache_hotspots`
- Interval: `5m`
- Purpose: historical plan-cache rankings by CPU, elapsed time, and memory grant.

## Metrics

- CPU: `mssql_top_query_total_worker_ms`, `mssql_top_query_avg_elapsed_ms`, `mssql_top_query_execution_count`
- Duration: `mssql_top_query_total_elapsed_ms`, `mssql_top_query_avg_duration_ms`, `mssql_top_query_elapsed_execution_count`
- Grant: `mssql_top_query_max_grant_mb`, `mssql_top_query_max_used_grant_mb`, `mssql_top_query_grant_execution_count`

Each ranking first bounds `sys.dm_exec_query_stats` to 250 candidates and only then expands SQL text and plan attributes. `statement_snip` preserves up to 8000 Unicode characters.

## Permissions

The exporter login requires `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.

