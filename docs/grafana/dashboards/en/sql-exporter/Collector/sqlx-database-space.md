# Collector database_space

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-database-space.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Fast space ops view: DB-level used%/free/size + VLF hotspots. File-level detail is collapsed (expand to load). Avoids raw per-file timeseries.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-database-space` |
| Source file | [`sqlx-database-space.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-database-space.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `space` |
| Panel count | 23 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_database_space_size_mb{job="sql_exporter", instance=~"$instance"}, db)` |
| `type_desc` | File Type | `custom` | `ROWS,LOG,FILESTREAM,FULLTEXT` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | DBs Used >=85% | `stat` |
| 3 | DBs Used >=95% | `stat` |
| 4 | Files Near Max | `stat` |
| 5 | High VLF (>500) | `stat` |
| 6 | Percent Growth | `stat` |
| 7 | Tiny Growth | `stat` |
| 8 | Total Size | `stat` |
| 9 | Total Free | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top DBs by Used % | `bargauge` |
| 12 | Top Servers - DBs Used >=85% | `bargauge` |
| 13 | Top DBs by Size | `bargauge` |
| 14 | Trends (DB-level topk) | `row` |
| 15 | Used % - Top 15 Databases | `timeseries` |
| 16 | Free MB - Lowest 15 Databases | `timeseries` |
| 17 | Size MB - Top 15 Databases | `timeseries` |
| 18 | VLF - Top 15 Databases | `timeseries` |
| 19 | Per-Server Rollup | `row` |
| 20 | Servers - pressure / size / free | `table` |
| 21 | File Detail / Config Risks (expand to load) | `row` |
| 22 | Files Used >= 95% (topk 40) | `table` |
| 23 | Near Max Size >=85% (topk 40) | `table` |

Panel type summary: `bargauge`: 3, `row`: 5, `stat`: 8, `table`: 3, `timeseries`: 4

## Metrics used

- `FULLTEXT`
- `mssql_database_space_free_mb`
- `mssql_database_space_growth_mb`
- `mssql_database_space_is_percent_growth`
- `mssql_database_space_pct_of_max`
- `mssql_database_space_size_mb`
- `mssql_database_space_used_percent`
- `mssql_database_vlf_count`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
