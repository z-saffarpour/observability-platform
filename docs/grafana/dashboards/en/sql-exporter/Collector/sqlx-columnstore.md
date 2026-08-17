# Collector columnstore

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-columnstore.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Columnstore rowgroup health for DWH/BI: OPEN/CLOSED backlog, COMPRESSED deleted-row bloat, underfilled RGs, and top REORGANIZE candidates.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-columnstore` |
| Source file | [`sqlx-columnstore.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-columnstore.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `columnstore`, `dwh` |
| Panel count | 24 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_columnstore_rowgroups{job="sql_exporter", instance=~"$instance"}, db)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | CS Databases | `stat` |
| 3 | OPEN RGs | `stat` |
| 4 | CLOSED RGs | `stat` |
| 5 | COMPRESSED RGs | `stat` |
| 6 | Max Deleted % | `stat` |
| 7 | DBs >=20% Deleted | `stat` |
| 8 | Underfilled RGs | `stat` |
| 9 | Total Size | `stat` |
| 10 | State Backlog & Bloat Trends | `row` |
| 11 | Rowgroups by State | `timeseries` |
| 12 | Size by State (MB) | `timeseries` |
| 13 | Deleted Ratio (COMPRESSED) | `timeseries` |
| 14 | OPEN + CLOSED Backlog | `timeseries` |
| 15 | Avg Rows per COMPRESSED RG | `timeseries` |
| 16 | Underfilled COMPRESSED RGs (<100k rows) | `timeseries` |
| 17 | Total Rows by State | `timeseries` |
| 18 | Deleted Rows by State | `timeseries` |
| 19 | Database Health Inventory | `row` |
| 20 | Per-database columnstore health | `table` |
| 21 | REORGANIZE Candidates (top bloated objects) | `row` |
| 22 | Top objects by deleted-row ratio (COMPRESSED) | `table` |
| 23 | Object Deleted Ratio Trend | `timeseries` |
| 24 | Object Deleted Rows Trend | `timeseries` |

Panel type summary: `row`: 4, `stat`: 8, `table`: 2, `timeseries`: 10

## Metrics used

- `mssql_columnstore_avg_rows_per_rg`
- `mssql_columnstore_deleted_ratio`
- `mssql_columnstore_deleted_rows`
- `mssql_columnstore_object_deleted_ratio`
- `mssql_columnstore_object_deleted_rows`
- `mssql_columnstore_object_rowgroups`
- `mssql_columnstore_object_size_mb`
- `mssql_columnstore_object_total_rows`
- `mssql_columnstore_rowgroups`
- `mssql_columnstore_size_mb`
- `mssql_columnstore_total_rows`
- `mssql_columnstore_underfilled_rg`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
