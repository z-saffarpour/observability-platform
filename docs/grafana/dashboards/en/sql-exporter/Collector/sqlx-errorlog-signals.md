# Collector errorlog_signals

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-errorlog-signals.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

ERRORLOG signal counters (rolling 6h via xp_readerrorlog): capacity criticals (9002/1105/112), I/O & latch, AlwaysOn redo, deadlocks, client disconnects. Filter by Server and Signal.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-errorlog-signals` |
| Source file | [`sqlx-errorlog-signals.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-errorlog-signals.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `errorlog` |
| Panel count | 32 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `signal` | Signal | `query` | `label_values(mssql_errorlog_signal_count{job="sql_exporter", instance=~"$instance"}, signal)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI (rolling 6h ERRORLOG window) | `row` |
| 2 | Total Signals | `stat` |
| 3 | Servers Affected | `stat` |
| 4 | Distinct Signals | `stat` |
| 5 | Capacity Crit | `stat` |
| 6 | I/O / Latch | `stat` |
| 7 | AG Redo | `stat` |
| 8 | Deadlocks | `stat` |
| 9 | Client Drop 4014 | `stat` |
| 10 | Log Full 9002 | `stat` |
| 11 | Filegroup Full | `stat` |
| 12 | Backup Disk Full | `stat` |
| 13 | Slow I/O | `stat` |
| 14 | Latch 845 | `stat` |
| 15 | Mem Grant 8645 | `stat` |
| 16 | Network 178xx | `stat` |
| 17 | AG Suspend | `stat` |
| 18 | Hotspots | `row` |
| 19 | Top Servers by Signal Count | `bargauge` |
| 20 | Top Signal Types (fleet) | `bargauge` |
| 21 | Active Signals > 0 (Server x Signal) | `table` |
| 22 | Trends (rolling 6h gauge over time) | `row` |
| 23 | Fleet Total by Signal | `timeseries` |
| 24 | Capacity Crit (log / FG / backup disk) | `timeseries` |
| 25 | I/O & Latch Pressure | `timeseries` |
| 26 | Session / Network / Deadlock / Mem | `timeseries` |
| 27 | AlwaysOn Redo Failures | `timeseries` |
| 28 | Fleet Matrix (per-server rollup) | `row` |
| 29 | Servers - signal categories (6h window) | `table` |
| 30 | All Signal Series (raw) | `table` |
| 31 | Signal Glossary & Ops Notes | `row` |
| 32 | Untitled | `text` |

Panel type summary: `bargauge`: 2, `row`: 5, `stat`: 16, `table`: 3, `text`: 1, `timeseries`: 5

## Metrics used

- `mssql_errorlog_signal_count`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
