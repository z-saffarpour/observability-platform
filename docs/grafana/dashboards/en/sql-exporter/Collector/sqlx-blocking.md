# Collector blocking

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-blocking.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Blocking / head-blocker ops view: fleet KPIs, wait trends, who is blocking whom, statement snippets, and breakdowns by wait type / DB / program. Collector: mssql_blocking (30s).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-blocking` |
| Source file | [`sqlx-blocking.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-blocking.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `blocking` |
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
| 2 | Blocked Sessions | `stat` |
| 3 | Head Blockers | `stat` |
| 4 | Servers Affected | `stat` |
| 5 | Max Wait | `stat` |
| 6 | Blocked sessions waiting longer than 30 seconds. | `stat` |
| 7 | Waits > 5m | `stat` |
| 8 | Max Head Elapsed | `stat` |
| 9 | Distinct Wait Types | `stat` |
| 10 | Trends | `row` |
| 11 | Blocked Sessions | `timeseries` |
| 12 | Head Blockers | `timeseries` |
| 13 | Max Wait Time | `timeseries` |
| 14 | Max Head Blocker Elapsed | `timeseries` |
| 15 | Fleet - who is blocking? | `row` |
| 16 | Servers with Blocking (fleet) | `table` |
| 17 | Head Blockers - investigate / kill first | `row` |
| 18 | Head Blockers (victims / elapsed / CPU / statement) | `table` |
| 19 | Blocked Sessions - who is waiting? | `row` |
| 20 | Blocked Sessions (wait + elapsed + statement) | `table` |
| 21 | Breakdowns | `row` |
| 22 | By Wait Type | `table` |
| 23 | By Database | `table` |
| 24 | By Program | `table` |
| 25 | Max Wait by Wait Type | `table` |
| 26 | Max Wait by Database | `table` |

Panel type summary: `row`: 6, `stat`: 8, `table`: 8, `timeseries`: 4

## Metrics used

- `mssql_blocking_count`
- `mssql_blocking_elapsed_ms`
- `mssql_blocking_head_count`
- `mssql_blocking_wait_ms`
- `mssql_head_blocker_cpu_ms`
- `mssql_head_blocker_elapsed_ms`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
