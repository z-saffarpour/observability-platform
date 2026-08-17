# mssql_plan_cache

## Summary

- File: `collector/mssql_plan_cache.collector.yml`
- collector_name: `mssql_plan_cache`
- min_interval: `120s`
- metric count: `13`
- shared query_ref values: `mssql_plan_cache_by_type`, `mssql_plan_cache_totals`, `mssql_plan_cache_by_db`

## Purpose

- Plan cache size, object-type breakdown, single-use plan pressure, and per-database context rollup.
- GRANT VIEW SERVER STATE TO

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Notes from the source file:
  - GRANT VIEW SERVER STATE TO
- Per-database metrics resolve database context from `sys.dm_exec_plan_attributes` (`attribute = dbid`), same approach as `mssql_heavy_queries`.

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.
- Redeploy sql_exporter after collector changes so Grafana per-database panels receive `mssql_plan_cache_db_*` series.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_plan_cache_size_mb` | `gauge` | `objtype` | `size_mb` | query_ref=`mssql_plan_cache_by_type` | Plan cache size (MB) by objtype. |
| `mssql_plan_cache_plan_count` | `gauge` | `objtype` | `plan_count` | query_ref=`mssql_plan_cache_by_type` | Cached plan count by objtype. |
| `mssql_plan_cache_single_use_count` | `gauge` | `objtype` | `single_use_count` | query_ref=`mssql_plan_cache_by_type` | Plans with usecounts = 1 by objtype (ad-hoc pollution signal). |
| `mssql_plan_cache_total_size_mb` | `gauge` | - | `size_mb` | query_ref=`mssql_plan_cache_totals` | Total plan cache size (MB). |
| `mssql_plan_cache_total_plans` | `gauge` | - | `plan_count` | query_ref=`mssql_plan_cache_totals` | Total cached plans. |
| `mssql_plan_cache_single_use_ratio` | `gauge` | - | `single_use_ratio` | query_ref=`mssql_plan_cache_totals` | Fraction of cached plans with usecounts = 1 (0..1). |
| `mssql_plan_cache_use_counts_sum` | `gauge` | - | `use_counts_sum` | query_ref=`mssql_plan_cache_totals` | Sum of usecounts across all cached plans. |
| `mssql_plan_cache_db_size_mb` | `gauge` | `db` | `size_mb` | query_ref=`mssql_plan_cache_by_db` | Plan cache size (MB) by database context. |
| `mssql_plan_cache_db_plan_count` | `gauge` | `db` | `plan_count` | query_ref=`mssql_plan_cache_by_db` | Cached plan count by database context. |
| `mssql_plan_cache_db_single_use_count` | `gauge` | `db` | `single_use_count` | query_ref=`mssql_plan_cache_by_db` | Single-use cached plans by database context. |
| `mssql_plan_cache_db_single_use_ratio` | `gauge` | `db` | `single_use_ratio` | query_ref=`mssql_plan_cache_by_db` | Fraction of cached plans with usecounts = 1 by database context (0..1). |
| `mssql_plan_cache_db_adhoc_size_mb` | `gauge` | `db` | `adhoc_size_mb` | query_ref=`mssql_plan_cache_by_db` | Adhoc plan cache size (MB) by database context. |
| `mssql_plan_cache_db_adhoc_single_use_ratio` | `gauge` | `db` | `adhoc_single_use_ratio` | query_ref=`mssql_plan_cache_by_db` | Fraction of adhoc cached plans with usecounts = 1 by database context (0..1). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
- Empty `db` label means database context could not be resolved for that plan batch.
