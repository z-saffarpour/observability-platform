# mssql_database_integrity

## Summary

- File: `collector/mssql_database_integrity.collector.yml`
- collector_name: `mssql_database_integrity`
- min_interval: `3600s`
- metric count: `7`
- shared query_ref values: `mssql_checkdb_age`, `mssql_suspect_pages`, `mssql_suspect_pages_total`

## Purpose

- Database integrity signals: suspect pages (corruption) + last known good CHECKDB age/coverage.
- `GRANT VIEW SERVER STATE` and `GRANT SELECT ON msdb.dbo.suspect_pages`.
- CHECKDB age uses `DBCC DBINFO` (needs rights to run DBCC against each ONLINE DB).

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: `suspect_pages` + `DBCC DBINFO` per online database.
- Inaccessible databases are skipped (empty CATCH); scrape should not fail.

## How to use

- Enable this collector in the profile that matches the server type.
- Scrape is intentionally hourly — pair with the Grafana dashboard SLA variable (default 7d, matches alert `SqlDatabaseIntegrityAtRisk`).
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_suspect_pages` | `gauge` | `db`, `event_type`, `event_type_desc` | `page_count` | Rows in `msdb.dbo.suspect_pages` by database and event_type. |
| `mssql_suspect_pages_error_count` | `gauge` | `db`, `event_type`, `event_type_desc` | `error_count` | Sum of `error_count` (how often SQL Server hit the bad page). |
| `mssql_suspect_pages_last_seen_age_seconds` | `gauge` | `db`, `event_type`, `event_type_desc` | `last_seen_age_seconds` | Seconds since newest `last_update_date` for that db/event. `-1` if unknown. |
| `mssql_suspect_pages_total` | `gauge` | — | `page_count` | Total suspect_pages rows (all databases). |
| `mssql_checkdb_age_seconds` | `gauge` | `db` | `age_seconds` | Seconds since `dbi_dbccLastKnownGood`. `-1` if never / unknown. |
| `mssql_checkdb_last_good_timestamp` | `gauge` | `db` | `last_good_unix` | Unix seconds of last known good CHECKDB. `0` if never / unknown. |
| `mssql_checkdb_never_run` | `gauge` | `db` | `never_run` | `1` when CHECKDB was never recorded, else `0`. |

## Operational notes

- `min_interval` prevents frequent execution of heavy `DBCC DBINFO` loops.
- Suspect page event types: `1`=823/824, `2`=bad checksum, `3`=torn page, `4`=restored, `5`=repaired, `7`=deallocated.
- Grafana dashboard: `grafana/dashboards/sql-exporter/Collector/sqlx-database-integrity.json`.
