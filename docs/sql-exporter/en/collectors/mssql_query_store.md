# mssql_query_store

## Summary

- File: `collector/mssql_query_store.collector.yml`
- collector_name: `mssql_query_store`
- min_interval: `300s`
- metric count: `11`
- shared query_ref values: `mssql_qs_enabled`, `mssql_qs_options`, `mssql_qs_top`

## Purpose

- Query Store enablement + health options + top queries from DBs where QS is ON.
- Includes `last_execution_time` (unix + age) per tracked query_id.
- GRANT VIEW SERVER STATE TO
- Per-DB: VIEW DATABASE STATE / access to Query Store catalog views

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Access to user databases and Query Store.
- Notes from the source file:
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_query_store_enabled` | `gauge` | `db` | `enabled` | query_ref=`mssql_qs_enabled` | 1 if Query Store is enabled on the database, else 0. |
| `mssql_query_store_top_duration_ms` | `gauge` | `db`, `query_id`, `object_name`, `query_snip` | `avg_duration_ms` | query_ref=`mssql_qs_top` | Top Query Store queries by average duration (microseconds/1000=ms). |
| `mssql_query_store_top_cpu_ms` | `gauge` | `db`, `query_id`, `object_name`, `query_snip` | `avg_cpu_ms` | query_ref=`mssql_qs_top` | Top Query Store queries by average CPU time (ms). |
| `mssql_query_store_top_execution_count` | `gauge` | `db`, `query_id`, `object_name`, `query_snip` | `execution_count` | query_ref=`mssql_qs_top` | Execution count for top Query Store queries in recent window. |
| `mssql_query_store_top_last_execution_unix` | `gauge` | `db`, `query_id`, `object_name`, `query_snip` | `last_execution_unix` | query_ref=`mssql_qs_top` | Unix epoch (UTC) of last_execution_time for the query in the QS window. |
| `mssql_query_store_top_last_execution_age_seconds` | `gauge` | `db`, `query_id`, `object_name`, `query_snip` | `last_execution_age_seconds` | query_ref=`mssql_qs_top` | Seconds since last_execution_time for the query in the QS window. |
| `mssql_query_store_desired_state` | `gauge` | `db` | `desired_state` | query_ref=`mssql_qs_options` | Query Store desired_state per database. |
| `mssql_query_store_actual_state` | `gauge` | `db` | `actual_state` | query_ref=`mssql_qs_options` | Query Store actual_state per database. |
| `mssql_query_store_readonly_reason` | `gauge` | `db` | `readonly_reason` | query_ref=`mssql_qs_options` | Query Store readonly_reason bitmask. |
| `mssql_query_store_current_storage_size_mb` | `gauge` | `db` | `current_storage_size_mb` | query_ref=`mssql_qs_options` | Current QS storage size (MB). |
| `mssql_query_store_max_storage_size_mb` | `gauge` | `db` | `max_storage_size_mb` | query_ref=`mssql_qs_options` | Configured QS max storage size (MB). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
- Top-query scrape window is last 6 hours of Query Store runtime stats; global cap 40 rows.
