# Collector missing_index

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-missing-index.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Missing-index ops view: KPIs, score/impact/seeks hotspots, filtered action queue, suggestion inventory, and per-DB rollup. DMV sample TOP 30 - advisory only; validate before CREATE INDEX. Stats reset on restart.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-missing-index` |
| Source file | [`sqlx-missing-index.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-missing-index.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `indexes` |
| Panel count | 30 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_missing_index_score{job="sql_exporter", instance=~"$instance"}, db)` |
| `min_score` | Min Score | `custom` | `0,10000,100000,1000000,5000000` |
| `min_impact` | Min Impact % | `custom` | `0,50,70,90` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Servers | `stat` |
| 3 | Suggestions | `stat` |
| 4 | Databases | `stat` |
| 5 | High Impact (>=1M) | `stat` |
| 6 | Max Score | `stat` |
| 7 | Max Impact % | `stat` |
| 8 | Total Seeks | `stat` |
| 9 | Total Scans | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top by Improvement Score | `bargauge` |
| 12 | Top by Avg User Impact % | `bargauge` |
| 13 | Top by User Seeks | `bargauge` |
| 14 | Top DBs by Suggestion Count | `bargauge` |
| 15 | Action Queue (filter with Min Score / Min Impact) | `row` |
| 16 | Review candidates - create only after validating workload / existing indexes / write cost | `table` |
| 17 | Trends | `row` |
| 18 | Top Improvement Scores | `timeseries` |
| 19 | Top User Seeks | `timeseries` |
| 20 | DB Sum Score | `timeseries` |
| 21 | DB Suggestion Count | `timeseries` |
| 22 | Suggestion Inventory (TOP sample) | `row` |
| 23 | All sampled missing-index suggestions (equality / inequality / included columns) | `table` |
| 24 | Per-Database Rollup | `row` |
| 25 | Database rollup - suggestion pressure and high-impact count | `table` |
| 26 | Impact / Cost Detail | `row` |
| 27 | Top Impact % | `timeseries` |
| 28 | Top Cost Score (after redeploy) | `timeseries` |
| 29 | Top Avg Cost (after redeploy) | `timeseries` |
| 30 | Top Unique Compiles (after redeploy) | `timeseries` |

Panel type summary: `bargauge`: 4, `row`: 7, `stat`: 8, `table`: 3, `timeseries`: 8

## Metrics used

- `mssql_missing_index_avg_cost`
- `mssql_missing_index_cost_score`
- `mssql_missing_index_db_max_impact`
- `mssql_missing_index_db_max_score`
- `mssql_missing_index_db_suggestions`
- `mssql_missing_index_db_sum_score`
- `mssql_missing_index_impact`
- `mssql_missing_index_score`
- `mssql_missing_index_unique_compiles`
- `mssql_missing_index_user_scans`
- `mssql_missing_index_user_seeks`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
