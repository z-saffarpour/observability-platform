# Collector locks

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-locks.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Locks / latch ops view: fleet KPIs, wait trends, waiting sessions, lock-related requests with statement snippets, lock inventory breakdowns, and latch rates. Collector: mssql_locks (30s). Pair with Blocking when WAIT > 0.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-locks` |
| Source file | [`sqlx-locks.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-locks.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `locks` |
| Panel count | 31 |
| Refresh interval | `30s` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_locks_waiting{job="sql_exporter"} or mssql_up{job="sql_exporter"}, instance)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Waiting Locks | `stat` |
| 3 | Servers Affected | `stat` |
| 4 | Total Locks | `stat` |
| 5 | Max Wait | `stat` |
| 6 | Waiting lock sessions longer than 30 seconds. | `stat` |
| 7 | Waits > 5m | `stat` |
| 8 | Lock-related Reqs | `stat` |
| 9 | Wait Types | `stat` |
| 10 | Trends | `row` |
| 11 | Waiting Locks | `timeseries` |
| 12 | Total Locks Held | `timeseries` |
| 13 | Max Lock Wait Time | `timeseries` |
| 14 | Lock-related Request Wait | `timeseries` |
| 15 | Fleet - where are locks waiting? | `row` |
| 16 | Servers with Lock Pressure (fleet) | `table` |
| 17 | Waiting Sessions - who is blocked on a lock? | `row` |
| 18 | Waiting Lock Sessions (wait time + resource) | `table` |
| 19 | Lock-related Requests - active work with lock/latch pressure | `row` |
| 20 | Active Lock/Latch-related Requests (wait + elapsed + statement) | `table` |
| 21 | Lock Inventory - what is held? | `row` |
| 22 | Top Lock Counts | `table` |
| 23 | By Resource Type | `table` |
| 24 | By Request Mode | `table` |
| 25 | By Status | `table` |
| 26 | Waiting by Database | `table` |
| 27 | Max Wait by Wait Type | `table` |
| 28 | Latches - BUFFER / ACCESS_METHODS pressure | `row` |
| 29 | Latch Wait Time Rate | `timeseries` |
| 30 | Latch Waits Rate | `timeseries` |
| 31 | Latch Classes (cumulative + rate) | `table` |

Panel type summary: `row`: 7, `stat`: 8, `table`: 10, `timeseries`: 6

## Metrics used

- `mssql_latch_wait_time_ms`
- `mssql_latch_waits`
- `mssql_lock_related_request_elapsed_ms`
- `mssql_lock_related_request_wait_ms`
- `mssql_locks_count`
- `mssql_locks_wait_time_ms`
- `mssql_locks_waiting`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
