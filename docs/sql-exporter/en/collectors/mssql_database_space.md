# mssql_database_space

## Summary

- File: `collector/mssql_database_space.collector.yml`
- collector_name: `mssql_database_space`
- min_interval: `300s`
- metric count: `10`
- shared query_ref values: `mssql_database_space_capacity`, `mssql_database_space_used`, `mssql_database_vlf`

## Purpose

- Database file capacity, free space, autogrowth, and VLF count.
- GRANT VIEW SERVER STATE TO
- GRANT VIEW ANY DEFINITION TO
- Databases must be ONLINE with HAS_DBACCESS for used/free (FILEPROPERTY).

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
| `mssql_database_space_size_mb` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `size_mb` | query_ref=`mssql_database_space_capacity` | Database file size (MB) from sys.master_files. |
| `mssql_database_space_max_size_mb` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `max_size_mb` | query_ref=`mssql_database_space_capacity` | Database file max_size (MB). -1 means unlimited. |
| `mssql_database_space_growth_mb` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `growth_mb` | query_ref=`mssql_database_space_capacity` | Autogrowth increment in MB when growth is fixed-size; 0 if percent growth. |
| `mssql_database_space_growth_percent` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `growth_percent` | query_ref=`mssql_database_space_capacity` | Autogrowth percent when is_percent_growth=1; else 0. |
| `mssql_database_space_is_percent_growth` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `is_percent_growth` | query_ref=`mssql_database_space_capacity` | 1 if file grows by percent, else 0. |
| `mssql_database_space_pct_of_max` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `pct_of_max` | query_ref=`mssql_database_space_capacity` | size as percent of max_size. -1 if unlimited max_size. |
| `mssql_database_space_used_mb` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc` | `used_mb` | query_ref=`mssql_database_space_used` | Used space (MB) via FILEPROPERTY SpaceUsed (ONLINE DBs with access). |
| `mssql_database_space_free_mb` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc` | `free_mb` | query_ref=`mssql_database_space_used` | Free space (MB) = size - SpaceUsed (ONLINE DBs with access). |
| `mssql_database_space_used_percent` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc` | `used_percent` | query_ref=`mssql_database_space_used` | Used percent of file size (ONLINE DBs with access). |
| `mssql_database_vlf_count` | `gauge` | `db` | `vlf_count` | query_ref=`mssql_database_vlf` | Virtual log file count per database (sys.dm_db_log_info). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
