# mssql_columnstore

## Summary

- File: `collector/mssql_columnstore.collector.yml`
- collector_name: `mssql_columnstore`
- min_interval: `300s`
- metric count: `12`
- shared query_ref values: `mssql_columnstore_rowgroups`, `mssql_columnstore_health`, `mssql_columnstore_top_objects`
- Profile: `profiles/dwh.yml`

## Purpose

- Columnstore rowgroup health for DWH / BI hosts.
- Detect tuple-mover backlog (`OPEN` / `CLOSED`), COMPRESSED deleted-row bloat, underfilled rowgroups, and top REORGANIZE candidates.
- Empty result when no columnstore indexes exist.

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Access to user databases that contain columnstore indexes.
- Notes from the source file:
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the DWH profile (`dwh.yml`) or any host that actually has columnstore indexes.
- Pair with Grafana dashboard `grafana/dashboards/sql-exporter/Collector/sqlx-columnstore.json` (`sqlx-columnstore`).
- Alert `SqlColumnstoreDeletedRowsHigh` fires when `mssql_columnstore_deleted_ratio > 0.2` for 30m.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_columnstore_rowgroups` | `gauge` | `db`, `state_desc` | `rowgroup_count` | query_ref=`mssql_columnstore_rowgroups` | Rowgroup count by state (OPEN/CLOSED/COMPRESSED/…). |
| `mssql_columnstore_total_rows` | `gauge` | `db`, `state_desc` | `total_rows` | query_ref=`mssql_columnstore_rowgroups` | Total rows in rowgroups by state. |
| `mssql_columnstore_deleted_rows` | `gauge` | `db`, `state_desc` | `deleted_rows` | query_ref=`mssql_columnstore_rowgroups` | Deleted rows by state (COMPRESSED bloat signal). |
| `mssql_columnstore_size_mb` | `gauge` | `db`, `state_desc` | `size_mb` | query_ref=`mssql_columnstore_rowgroups` | Rowgroup size (MB) by state. |
| `mssql_columnstore_deleted_ratio` | `gauge` | `db` | `deleted_ratio` | query_ref=`mssql_columnstore_health` | deleted_rows / total_rows for COMPRESSED RGs per DB. |
| `mssql_columnstore_avg_rows_per_rg` | `gauge` | `db` | `avg_rows_per_rg` | query_ref=`mssql_columnstore_health` | Average rows per COMPRESSED RG (ideal ~1,048,576). |
| `mssql_columnstore_underfilled_rg` | `gauge` | `db` | `underfilled_rg` | query_ref=`mssql_columnstore_health` | COMPRESSED RGs with total_rows < 100000. |
| `mssql_columnstore_object_deleted_ratio` | `gauge` | `db`, `schema_name`, `table_name`, `index_name` | `deleted_ratio` | query_ref=`mssql_columnstore_top_objects` | Top objects by COMPRESSED deleted-row ratio. |
| `mssql_columnstore_object_deleted_rows` | `gauge` | `db`, `schema_name`, `table_name`, `index_name` | `deleted_rows` | query_ref=`mssql_columnstore_top_objects` | Deleted rows for top bloated objects. |
| `mssql_columnstore_object_total_rows` | `gauge` | `db`, `schema_name`, `table_name`, `index_name` | `total_rows` | query_ref=`mssql_columnstore_top_objects` | Total rows for top bloated objects. |
| `mssql_columnstore_object_rowgroups` | `gauge` | `db`, `schema_name`, `table_name`, `index_name` | `rowgroup_count` | query_ref=`mssql_columnstore_top_objects` | COMPRESSED RG count for top bloated objects. |
| `mssql_columnstore_object_size_mb` | `gauge` | `db`, `schema_name`, `table_name`, `index_name` | `size_mb` | query_ref=`mssql_columnstore_top_objects` | COMPRESSED size (MB) for top bloated objects. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- Top-object query returns at most 15 indexes per database with `deleted_rows > 0`.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
- Dashboard sections: KPI → state backlog/bloat trends → per-DB inventory → REORGANIZE candidates.
