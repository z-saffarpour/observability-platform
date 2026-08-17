# mssql_stats

## Summary

- File: `collector/mssql_stats.collector.yml`
- collector_name: `mssql_stats`
- min_interval: `600s`
- metric count: `6`
- shared query_ref values: `mssql_stats_stale`, `mssql_stats_stale_count`

## Purpose

- Stale / heavily modified statistics (TOP N across online user databases).
- It is required that the SQL Server user has the following permissions:
- GRANT VIEW SERVER STATE TO
- Access to user databases required
- Auto-loaded via collectors: [mssql_*] and collector_files: ["collector/*.collector.yml"]

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Access to user databases.
- Notes from the source file:
  - It is required that the SQL Server user has the following permissions:
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_stats_age_seconds` | `gauge` | `db`, `schema_name`, `table_name`, `stats_name` | `age_seconds` | query_ref=`mssql_stats_stale` | TOP statistics by age (seconds since last update). |
| `mssql_stats_modification_counter` | `gauge` | `db`, `schema_name`, `table_name`, `stats_name` | `modification_counter` | query_ref=`mssql_stats_stale` | modification_counter for TOP stale/changed statistics. |
| `mssql_stats_rows` | `gauge` | `db`, `schema_name`, `table_name`, `stats_name` | `rows` | query_ref=`mssql_stats_stale` | Row count snapshot for TOP stale/changed statistics. |
| `mssql_stats_rows_sampled` | `gauge` | `db`, `schema_name`, `table_name`, `stats_name` | `rows_sampled` | query_ref=`mssql_stats_stale` | rows_sampled for TOP stale/changed statistics. |
| `mssql_stats_sample_percent` | `gauge` | `db`, `schema_name`, `table_name`, `stats_name` | `sample_percent` | query_ref=`mssql_stats_stale` | Sample percent (rows_sampled/rows*100) for TOP stale/changed statistics. |
| `mssql_stats_stale_count` | `gauge` | `db` | `stale_count` | query_ref=`mssql_stats_stale_count` | Count of stale/heavily-modified statistics per database (matching collector thresholds). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
