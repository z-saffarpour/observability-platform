# Collector database_size_growth

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-database-size-growth.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Database capacity & growth: total data/log, 24h/7d growth deltas, top growers, DB/file inventory, recovery model, percent-growth risks. Cross-link Database Space (used%) and Autogrowth (events).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-database-size-growth` |
| Source file | [`sqlx-database-size-growth.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-database-size-growth.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `growth`, `capacity` |
| Panel count | 26 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_database_data_size_mb{job="sql_exporter", instance=~"$instance"}, db)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Capacity / Growth KPI | `row` |
| 2 | Total Data | `stat` |
| 3 | Total Log | `stat` |
| 4 | Total Size | `stat` |
| 5 | Databases | `stat` |
| 6 | Data +24h | `stat` |
| 7 | Log +24h | `stat` |
| 8 | Data +7d | `stat` |
| 9 | Fast Growers (7d>1GB) | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top Databases by Total Size | `bargauge` |
| 12 | Top Data Growth (7d) | `bargauge` |
| 13 | Top Servers by Total Size | `bargauge` |
| 14 | Database Inventory | `row` |
| 15 | Databases - size + growth (24h / 7d) | `table` |
| 16 | Trends | `row` |
| 17 | Data Size by Database | `timeseries` |
| 18 | Log Size by Database | `timeseries` |
| 19 | Fleet Total (Data + Log) | `timeseries` |
| 20 | Data Growth Rate (MB/day) | `timeseries` |
| 21 | Per-Server Rollup | `row` |
| 22 | Servers - capacity + 7d growth | `table` |
| 23 | Files and Growth Settings | `row` |
| 24 | File inventory (size + autogrowth setting) | `table` |
| 25 | Percent Growth Enabled (risky) | `table` |
| 26 | File Size Trend | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 4, `timeseries`: 5

## Metrics used

- `mssql_database_data_size_mb`
- `mssql_database_file_size_mb`
- `mssql_database_log_size_mb`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
