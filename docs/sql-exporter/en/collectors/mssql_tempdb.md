# mssql_tempdb

## Summary

- File: `collector/mssql_tempdb.collector.yml`
- collector_name: `mssql_tempdb`
- min_interval: `60s`
- metric count: `13`
- shared query_ref values: `mssql_tempdb_files`, `mssql_tempdb_metadata_contention`, `mssql_tempdb_space`, `mssql_tempdb_space_breakdown`, `mssql_tempdb_spill_proxy`, `mssql_tempdb_top_sessions`, `mssql_tempdb_version_store`, `mssql_tempdb_waiting_tasks`

## Purpose

- tempdb metrics for Microsoft SQL Server.
- It is required that the SQL Server user has the following permissions:
- GRANT VIEW SERVER STATE TO
- GRANT VIEW ANY DEFINITION TO
- Auto-loaded via collectors: [mssql_*] and collector_files: ["collector/*.collector.yml"]

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Notes from the source file:
  - It is required that the SQL Server user has the following permissions:
  - GRANT VIEW SERVER STATE TO
  - GRANT VIEW ANY DEFINITION TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_tempdb_file_size_mb` | `gauge` | `file_id`, `type_desc`, `logical_name`, `physical_name` | `size_mb` | query_ref=`mssql_tempdb_files` | tempdb file size (MB). |
| `mssql_tempdb_file_used_mb` | `gauge` | `file_id`, `type_desc`, `logical_name`, `physical_name` | `used_mb` | query_ref=`mssql_tempdb_files` | tempdb file used space (MB). |
| `mssql_tempdb_file_free_mb` | `gauge` | `file_id`, `type_desc`, `logical_name`, `physical_name` | `free_mb` | query_ref=`mssql_tempdb_files` | tempdb file free space (MB). |
| `mssql_tempdb_space_used_mb` | `gauge` | `usage` | `used_mb` | query_ref=`mssql_tempdb_space` | tempdb space usage by category (MB). |
| `mssql_tempdb_version_store_mb` | `gauge` | - | `version_store_mb` | query_ref=`mssql_tempdb_version_store` | tempdb version store size (MB). |
| `mssql_tempdb_version_cleanup_rate_mb_s` | `gauge` | - | `version_cleanup_rate_mb_s` | query_ref=`mssql_tempdb_version_store` | tempdb version cleanup rate (MB/s) from DMV snapshot values. |
| `mssql_tempdb_version_generation_rate_mb_s` | `gauge` | - | `version_generation_rate_mb_s` | query_ref=`mssql_tempdb_version_store` | tempdb version generation rate (MB/s) from DMV snapshot values. |
| `mssql_tempdb_session_used_mb` | `gauge` | `session_id`, `login_name`, `program_name`, `db` | `used_mb` | query_ref=`mssql_tempdb_top_sessions` | Top sessions by tempdb space used (user + internal objects, MB). |
| `mssql_tempdb_waiting_tasks_count` | `gauge` | - | `waiting_tasks_count` | query_ref=`mssql_tempdb_waiting_tasks` | Current waiting tasks likely blocked by tempdb-related waits. |
| `mssql_tempdb_internal_object_mb` | `gauge` | - | `internal_object_mb` | query_ref=`mssql_tempdb_space_breakdown` | Current internal object space in tempdb (MB). |
| `mssql_tempdb_user_object_mb` | `gauge` | - | `user_object_mb` | query_ref=`mssql_tempdb_space_breakdown` | Current user object space in tempdb (MB). |
| `mssql_tempdb_spill_writes_mb` | `gauge` | - | `spill_writes_mb` | query_ref=`mssql_tempdb_spill_proxy` | Active session tempdb internal allocation footprint (MB), spill pressure proxy. |
| `mssql_tempdb_metadata_contention_count` | `gauge` | - | `contention_count` | query_ref=`mssql_tempdb_metadata_contention` | Current waiting tasks on tempdb allocation-map pages (metadata contention proxy). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

