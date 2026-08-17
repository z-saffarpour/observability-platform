# Collector waits

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-waits.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Wait stats ops view: class composition, signal vs resource pressure, top wait types with avg/max, and fleet hotspot tables. Benign waits filtered in collector. Source: mssql_waits (120s). Rates are ms/s from cumulative DMVs.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-waits` |
| Source file | [`sqlx-waits.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-waits.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `waits` |
| Panel count | 31 |
| Refresh interval | `30s` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `wait_class` | Wait Class | `query` | `label_values(mssql_waits_by_class_time_ms{job="sql_exporter", instance=~"$instance"}, wait_class)` |
| `wait_type` | Wait Type | `query` | `label_values(mssql_wait_time_ms{job="sql_exporter", instance=~"$instance"}, wait_type)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | High Signal (>=25%) | `stat` |
| 3 | High Nonbenign (>=70%) | `stat` |
| 4 | Concentrated Top5 (>=90%) | `stat` |
| 5 | Max Signal Ratio | `stat` |
| 6 | Highest share of wait time that is non-benign. | `stat` |
| 7 | Max Top5 Share | `stat` |
| 8 | Hot Wait Types | `stat` |
| 9 | Max Wait Rate | `stat` |
| 10 | Wait Classes - where time goes | `row` |
| 11 | Wait Time by Class (ms/s) | `timeseries` |
| 12 | Top Classes Now | `bargauge` |
| 13 | Waiting Tasks by Class (ops/s) | `timeseries` |
| 14 | Total Wait Rate by Server | `timeseries` |
| 15 | Pressure Indicators | `row` |
| 16 | Signal Wait Ratio % | `timeseries` |
| 17 | Nonbenign Wait % | `timeseries` |
| 18 | Top5 Share of Nonbenign % | `timeseries` |
| 19 | Signal vs Resource Wait Rate (ms/s) | `timeseries` |
| 20 | Top Wait Types - investigate | `row` |
| 21 | Top Wait Rates (ms/s) | `bargauge` |
| 22 | Top Max Wait Time | `bargauge` |
| 23 | Top Avg Wait / Task | `bargauge` |
| 24 | Wait Type Detail (rate + signal/resource + avg) | `table` |
| 25 | Top Wait Types Trend (ms/s) | `timeseries` |
| 26 | Waiting Tasks Rate by Type | `timeseries` |
| 27 | Fleet Snapshot & Hotspots | `row` |
| 28 | Wait Health by Server | `table` |
| 29 | Hotspots: Signal Ratio >= 15% | `table` |
| 30 | Hotspots: Wait Rate Leaders | `table` |
| 31 | Class Mix by Server | `table` |

Panel type summary: `bargauge`: 4, `row`: 5, `stat`: 8, `table`: 5, `timeseries`: 9

## Metrics used

- `mssql_up`
- `mssql_wait_max_time_ms`
- `mssql_wait_resource_time_ms`
- `mssql_wait_signal_time_ms`
- `mssql_wait_time_ms`
- `mssql_wait_waiting_tasks`
- `mssql_waits_by_class_tasks`
- `mssql_waits_by_class_time_ms`
- `mssql_waits_nonbenign_percent`
- `mssql_waits_signal_ratio_percent`
- `mssql_waits_top5_share_percent`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
