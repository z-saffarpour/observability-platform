# mssql_database_size_growth

## Summary

- File: `collector/mssql_database_size_growth.collector.yml`
- collector_name: `mssql_database_size_growth`
- min_interval: `300s`
- metric count: `3`
- shared query_ref values: `mssql_database_files`, `mssql_database_sizes`

## Purpose

- Database data/log size and used space - growth tracking via Prometheus.
- GRANT VIEW ANY DEFINITION TO
- GRANT VIEW SERVER STATE TO
- Note: mf.size/growth are int (8KB pages). Always cast before SUM/multiply
- to avoid arithmetic overflow on large databases.

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Access to user databases.
- Notes from the source file:
  - GRANT VIEW ANY DEFINITION TO
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_database_data_size_mb` | `gauge` | `db`, `state_desc`, `recovery_model_desc` | `data_size_mb` | query_ref=`mssql_database_sizes` | Total data file size (MB) per database. |
| `mssql_database_log_size_mb` | `gauge` | `db`, `state_desc`, `recovery_model_desc` | `log_size_mb` | query_ref=`mssql_database_sizes` | Total log file size (MB) per database. |
| `mssql_database_file_size_mb` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `growth_mb`, `is_percent_growth` | `size_mb` | query_ref=`mssql_database_files` | Per-file size (MB) for growth analysis. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

