# mssql_index_usage

## Summary

- File: `collector/mssql_index_usage.collector.yml`
- collector_name: `mssql_index_usage`
- min_interval: `300s`
- metric count: `19`
- shared query_ref values: `mssql_index_usage_hot`, `mssql_index_usage_stale`, `mssql_index_usage_db`

## Purpose

- Index usage ops view (not fragmentation): hot indexes, scan/lookup/write ratios, unused or write-heavy drop candidates, and per-database rollup.
- `dm_db_index_usage_stats` resets on instance restart, database offline, or index recreate.
- SSISDB / Distribution are excluded so they do not flood TOP lists.
- GRANT VIEW SERVER STATE TO / DB access for index names

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Access to user databases (for `sys.indexes` names).
- Notes from the source file:
  - GRANT VIEW SERVER STATE TO
  - VIEW ANY DEFINITION / DB access for index names

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.
- Use the Grafana dashboard `sqlx-index-usage` for ops triage: KPI → hotspots → hot inventory → stale candidates → DB rollup.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_index_usage_seeks` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `user_seeks` | query_ref=`mssql_index_usage_hot` | user_seeks for TOP hot indexes by total read activity. |
| `mssql_index_usage_scans` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `user_scans` | query_ref=`mssql_index_usage_hot` | user_scans for TOP hot indexes by total read activity. |
| `mssql_index_usage_lookups` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `user_lookups` | query_ref=`mssql_index_usage_hot` | user_lookups for TOP hot indexes by total read activity. |
| `mssql_index_usage_updates` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `user_updates` | query_ref=`mssql_index_usage_hot` | user_updates for TOP hot indexes by total read activity. |
| `mssql_index_usage_reads` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `user_reads` | query_ref=`mssql_index_usage_hot` | user_seeks+scans+lookups for TOP hot indexes. |
| `mssql_index_usage_scan_ratio` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `scan_ratio` | query_ref=`mssql_index_usage_hot` | user_scans / NULLIF(user_reads,0) for TOP hot indexes (scan-heavy signal). |
| `mssql_index_usage_lookup_ratio` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `lookup_ratio` | query_ref=`mssql_index_usage_hot` | user_lookups / NULLIF(user_reads,0) for TOP hot indexes (bookmark-lookup signal). |
| `mssql_index_usage_write_read_ratio` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `write_read_ratio` | query_ref=`mssql_index_usage_hot` | user_updates / NULLIF(user_reads,0) for TOP hot indexes. |
| `mssql_index_usage_stale_updates` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc`, `candidate_kind` | `user_updates` | query_ref=`mssql_index_usage_stale` | user_updates for unused or write-heavy indexes (drop/disable review candidates). |
| `mssql_index_usage_stale_reads` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc`, `candidate_kind` | `user_reads` | query_ref=`mssql_index_usage_stale` | user_reads for unused or write-heavy indexes (drop/disable review candidates). |
| `mssql_index_usage_stale_write_read_ratio` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc`, `candidate_kind` | `write_read_ratio` | query_ref=`mssql_index_usage_stale` | updates/reads (reads=0 → updates) for unused or write-heavy indexes. |
| `mssql_index_usage_db_reads` | `gauge` | `db` | `user_reads` | query_ref=`mssql_index_usage_db` | Sum of user_seeks+scans+lookups across indexes with usage stats in the database. |
| `mssql_index_usage_db_updates` | `gauge` | `db` | `user_updates` | query_ref=`mssql_index_usage_db` | Sum of user_updates across indexes with usage stats in the database. |
| `mssql_index_usage_db_scans` | `gauge` | `db` | `user_scans` | query_ref=`mssql_index_usage_db` | Sum of user_scans across indexes with usage stats in the database. |
| `mssql_index_usage_db_seeks` | `gauge` | `db` | `user_seeks` | query_ref=`mssql_index_usage_db` | Sum of user_seeks across indexes with usage stats in the database. |
| `mssql_index_usage_db_lookups` | `gauge` | `db` | `user_lookups` | query_ref=`mssql_index_usage_db` | Sum of user_lookups across indexes with usage stats in the database. |
| `mssql_index_usage_db_tracked_indexes` | `gauge` | `db` | `tracked_indexes` | query_ref=`mssql_index_usage_db` | Count of non-MS-shipped indexes present in dm_db_index_usage_stats for the database. |
| `mssql_index_usage_db_unused_indexes` | `gauge` | `db` | `unused_indexes` | query_ref=`mssql_index_usage_db` | Count of nonclustered indexes with user_reads=0 and user_updates>0 (since last stats reset). |
| `mssql_index_usage_db_scan_ratio` | `gauge` | `db` | `scan_ratio` | query_ref=`mssql_index_usage_db` | db user_scans / NULLIF(user_reads,0) — database-level scan pressure. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases (TOP N caps apply).
- Stale candidates exclude heaps, clustered indexes, primary keys, and unique constraints; require `user_updates >= 1000`.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
