# Collector cpu

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-cpu.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

SQL Server CPU from ring buffer: process vs other vs idle, host busy, signal-wait pressure, fleet ranking and hotspot tables. Source: mssql_cpu (30s).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-cpu` |
| Source file | [`sqlx-cpu.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-cpu.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `cpu` |
| Panel count | 26 |
| Refresh interval | `30s` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | High SQL CPU (>=80%) | `stat` |
| 3 | High Signal Wait (>=20%) | `stat` |
| 4 | Low Idle (<15%) | `stat` |
| 5 | Max SQL CPU | `stat` |
| 6 | Median SQL CPU | `stat` |
| 7 | Max Host Busy | `stat` |
| 8 | Max Signal Wait | `stat` |
| 9 | Max Other CPU | `stat` |
| 10 | Fleet Ranking (now) | `row` |
| 11 | Top SQL Process CPU % | `bargauge` |
| 12 | Top Host Busy % (100-Idle) | `bargauge` |
| 13 | Top Signal Wait % | `bargauge` |
| 14 | CPU Composition & Trends | `row` |
| 15 | CPU Composition (SQL + Other + Idle) | `timeseries` |
| 16 | SQL Process CPU % | `timeseries` |
| 17 | Host Busy % (100 - Idle) | `timeseries` |
| 18 | Other Process CPU % | `timeseries` |
| 19 | System Idle % | `timeseries` |
| 20 | CPU Pressure (Signal Waits) | `row` |
| 21 | Signal Wait % (CPU pressure) | `timeseries` |
| 22 | SQL CPU vs Signal Wait | `timeseries` |
| 23 | Fleet Snapshot & Hotspots | `row` |
| 24 | CPU Health by Server | `table` |
| 25 | Hotspots: SQL CPU >= 50% | `table` |
| 26 | Hotspots: Signal Wait >= 10% | `table` |

Panel type summary: `bargauge`: 3, `row`: 5, `stat`: 8, `table`: 3, `timeseries`: 7

## Metrics used

- `mssql_cpu_other_process_percent`
- `mssql_cpu_signal_wait_percent`
- `mssql_cpu_sqlserver_process_percent`
- `mssql_cpu_system_idle_percent`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
