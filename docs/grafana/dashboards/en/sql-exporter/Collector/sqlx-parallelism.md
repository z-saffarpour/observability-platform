# Collector parallelism

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-parallelism.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Parallelism ops view: CX* / memory-grant waits, active parallel requests with statement snippets, MAXDOP config, and triage guidance. Collector: mssql_parallelism (60s).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-parallelism` |
| Source file | [`sqlx-parallelism.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-parallelism.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `parallelism` |
| Panel count | 26 |
| Refresh interval | `30s` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `wait_type` | Wait Type | `query` | `label_values(mssql_parallelism_wait_time_ms{job="sql_exporter", instance=~"$instance"}, wait_type)` |
| `db` | Database | `query` | `label_values(mssql_parallelism_active_request_elapsed_ms{job="sql_exporter", instance=~"$instance"}, db)` |
| `min_dop` | Min DOP | `custom` | `0,2,4,8` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Active Parallel | `stat` |
| 3 | Servers Busy | `stat` |
| 4 | Max DOP Now | `stat` |
| 5 | Largest memory grant among active requests. | `stat` |
| 6 | Long >= 1m | `stat` |
| 7 | Mem Semaphore | `stat` |
| 8 | CX Wait Hot | `stat` |
| 9 | Active requests with DOP 8 or higher. | `stat` |
| 10 | Parallelism Waits - trends | `row` |
| 11 | Wait Time rate (by type) | `timeseries` |
| 12 | Waiting Tasks rate | `timeseries` |
| 13 | Active Requests by Server | `timeseries` |
| 14 | Max DOP by Server | `timeseries` |
| 15 | Active Parallel Requests - investigate now | `row` |
| 16 | Active Parallel / Large-Grant Requests | `table` |
| 17 | Longest Elapsed (top 15) | `bargauge` |
| 18 | Largest Memory Grants (top 15) | `bargauge` |
| 19 | Breakdowns | `row` |
| 20 | Top Wait Types (rate ms/s) | `bargauge` |
| 21 | Active by Database | `table` |
| 22 | Active by Program | `table` |
| 23 | Wait Rate by Server | `table` |
| 24 | Active by Wait Type | `table` |
| 25 | Server Configuration | `row` |
| 26 | Parallelism & Memory Settings (per server) | `table` |

Panel type summary: `bargauge`: 3, `row`: 5, `stat`: 8, `table`: 6, `timeseries`: 4

## Metrics used

- `mssql_parallelism_active_request_dop`
- `mssql_parallelism_active_request_elapsed_ms`
- `mssql_parallelism_active_request_grant_mb`
- `mssql_parallelism_configuration`
- `mssql_parallelism_wait_time_ms`
- `mssql_parallelism_waiting_tasks`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
