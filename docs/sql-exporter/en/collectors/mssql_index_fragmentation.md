# mssql_index_fragmentation

## Summary

- File: `collector/mssql_index_fragmentation.collector.yml`
- collector_name: `mssql_index_fragmentation`
- min_interval: `21600s`
- metric count: `2`
- shared query_ref values: `mssql_index_fragmentation_top`

## Purpose

- Index fragmentation sample (LIMITED) - EXPENSIVE. Run rarely.
- Prefer off-hours; do not enable on every busy OLTP host without need.
- GRANT VIEW SERVER STATE TO
- GRANT VIEW ANY DEFINITION TO

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Access to user databases.
- Notes from the source file:
  - GRANT VIEW SERVER STATE TO
  - GRANT VIEW ANY DEFINITION TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_index_fragmentation_percent` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc`, `alloc_unit_type_desc` | `avg_fragmentation_percent` | query_ref=`mssql_index_fragmentation_top` | Avg fragmentation percent (LIMITED mode) for large indexes above threshold. |
| `mssql_index_fragmentation_page_count` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc`, `alloc_unit_type_desc` | `page_count` | query_ref=`mssql_index_fragmentation_top` | Page count for fragmented indexes reported by this collector. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

