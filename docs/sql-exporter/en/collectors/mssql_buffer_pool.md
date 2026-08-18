# mssql_buffer_pool

## Summary

- File: `collector/mssql_buffer_pool.collector.yml`
- collector_name: `mssql_buffer_pool`
- min_interval: `180s`
- metric count: `3`
- query_ref values: `mssql_buffer_counters`, `mssql_buffer_hit_ratio`, `mssql_buffer_ple`

## Purpose

- Buffer pool / buffer manager health.
- GRANT VIEW SERVER STATE TO

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.

## How to use

- Enable this collector in the profile that matches the server type.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_buffer_pool_page_life_expectancy` | `gauge` | `numa_node` | `cntr_value` | query_ref=`mssql_buffer_ple` | Page life expectancy (seconds). `_Total` = overall; `000`/`001`/… = per-NUMA. |
| `mssql_buffer_pool_cache_hit_ratio` | `gauge` | — | `hit_ratio_pct` | query_ref=`mssql_buffer_hit_ratio` | Buffer cache hit ratio percent (0–100). |
| `mssql_buffer_pool_counter` | `gauge` | `counter` | `cntr_value` | query_ref=`mssql_buffer_counters` | Buffer Manager counters. Names ending in `/sec` are cumulative — use `rate(...[5m])`. |

## Operational notes

- Dashboard: `grafana/dashboards/sql-exporter/Collector/sqlx-buffer-pool.json`
- Do **not** plot raw Buffer cache hit ratio counter — use `mssql_buffer_pool_cache_hit_ratio`.
- Per-database metrics live in the opt-in `mssql_buffer_pool_database` collector.
- It is not included in role profiles because scanning `sys.dm_os_buffer_descriptors` can exceed `scrape_timeout` on large buffer pools.
- Add it explicitly to a profile only after timing the query on the target; its `min_interval` is `30m`.
