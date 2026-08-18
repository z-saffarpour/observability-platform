# mssql_buffer_pool_database

## Summary

- File: `collector/mssql_buffer_pool_database.collector.yml`
- collector_name: `mssql_buffer_pool_database`
- min_interval: `30m`
- metric count: `2`
- query_ref values: `mssql_buffer_pool_by_db`

## Purpose

- Per-database buffer-pool occupancy (cached pages and dirty pages).
- GRANT VIEW SERVER STATE TO
- EXPENSIVE: `sys.dm_os_buffer_descriptors` has one row per cached page.

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.

## How to use

- Do not enable this collector on every busy host by default.
- Time the query on the target, then add `mssql_buffer_pool_database` explicitly to the role profile.
- Role profiles include `mssql_buffer_pool` only; this collector is opt-in.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_buffer_pool_database_pages` | `gauge` | `db` | `page_count` | query_ref=`mssql_buffer_pool_by_db` | Cached pages in the buffer pool per database (8 KB pages). Label `db=_Free` is free buffer pages (`database_id` 32767). |
| `mssql_buffer_pool_database_dirty_pages` | `gauge` | `db` | `dirty_page_count` | query_ref=`mssql_buffer_pool_by_db` | Dirty (modified) cached pages in the buffer pool per database (8 KB pages). |

## Operational notes

- Dashboard: `grafana/dashboards/sql-exporter/Collector/sqlx-buffer-pool.json`
- `min_interval` is `30m` to keep the heavy DMV off the scrape path.
- Scanning `sys.dm_os_buffer_descriptors` can exceed `scrape_timeout` on large buffer pools.
- `collectors: [mssql_*]` also selects this collector; prefer an explicit profile list in production.
