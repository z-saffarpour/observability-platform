# mssql_buffer_pool

## Summary

- File: `collector/mssql_buffer_pool.collector.yml`
- collector_name: `mssql_buffer_pool`
- min_interval: `180s`
- metric count: `5`
- shared query_ref values: `mssql_buffer_by_db`, `mssql_buffer_counters`, `mssql_buffer_hit_ratio`, `mssql_buffer_ple`

## Purpose

- Buffer pool / buffer manager health, including per-database occupancy.
- GRANT VIEW SERVER STATE TO

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers with very large buffer pools, `sys.dm_os_buffer_descriptors` can be expensive; keep `min_interval` at least `180s` (per-DB buffer descriptors).
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_buffer_pool_page_life_expectancy` | `gauge` | `numa_node` | `cntr_value` | query_ref=`mssql_buffer_ple` | Page life expectancy (seconds). `_Total` = overall; `000`/`001`/… = per-NUMA. |
| `mssql_buffer_pool_cache_hit_ratio` | `gauge` | — | `hit_ratio_pct` | query_ref=`mssql_buffer_hit_ratio` | Buffer cache hit ratio percent (0–100). |
| `mssql_buffer_pool_counter` | `gauge` | `counter` | `cntr_value` | query_ref=`mssql_buffer_counters` | Buffer Manager counters. Names ending in `/sec` are cumulative — use `rate(...[5m])`. |
| `mssql_buffer_pool_database_pages` | `gauge` | `db` | `page_count` | query_ref=`mssql_buffer_by_db` | Cached 8 KB pages per database. `db=_Free` = free buffer pages (database_id 32767). |
| `mssql_buffer_pool_database_dirty_pages` | `gauge` | `db` | `dirty_page_count` | query_ref=`mssql_buffer_by_db` | Dirty (modified) cached pages per database. |

## Operational notes

- Dashboard: `grafana/dashboards/sql-exporter/Collector/sqlx-buffer-pool.json`
- Size in bytes: `mssql_buffer_pool_database_pages * 8192`
- Do **not** plot raw Buffer cache hit ratio counter — use `mssql_buffer_pool_cache_hit_ratio`.
