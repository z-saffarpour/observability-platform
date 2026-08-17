# Collector job_inventory

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-job-inventory.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

SQL Agent job inventory: failed-at / next-run date-time, overdue schedule, fleet counts, activity monitor. Snapshot collector (15m).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-job-inventory` |
| Source file | [`sqlx-job-inventory.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-job-inventory.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `jobs` |
| Panel count | 29 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `category` | Category | `query` | `label_values(mssql_job_enabled{job="sql_exporter", instance=~"${instance:regex}"}, category_name)` |
| `enabled` | Enabled | `custom` | `1,0` |
| `overdue_sec` | Overdue sec | `custom` | `60,300,900,3600,86400` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Total Jobs | `stat` |
| 3 | True | `stat` |
| 4 | False | `stat` |
| 5 | Failed Last | `stat` |
| 6 | Succeeded | `stat` |
| 7 | Overdue | `stat` |
| 8 | Cancel/Unknown | `stat` |
| 9 | Servers | `stat` |
| 10 | Attention - Failed last run & overdue schedule | `row` |
| 11 | Failed Last Run by Server | `bargauge` |
| 12 | Overdue Jobs by Server | `bargauge` |
| 13 | Failed Jobs - last fail time & next run | `table` |
| 14 | Overdue Schedule - next run already passed | `table` |
| 15 | Upcoming Schedule - next run after now | `table` |
| 16 | Fleet inventory - counts by server / category | `row` |
| 17 | True vs False Jobs by Server | `timeseries` |
| 18 | Last-Run Outcome Counts (fleet) | `timeseries` |
| 19 | Top Categories (job count) | `bargauge` |
| 20 | Top Servers (total jobs) | `bargauge` |
| 21 | Schedule - next run (date + time) | `row` |
| 22 | Most Overdue - next run date/time | `table` |
| 23 | Upcoming Next Run (next 24h) - date/time | `table` |
| 24 | Activity Monitor - last run / end / next run | `row` |
| 25 | Longest Last Run Duration | `bargauge` |
| 26 | Longest Duration by Category | `bargauge` |
| 27 | Activity Monitor (last run / end / next run / duration) | `table` |
| 28 | Full inventory (filter Server/Category/Enabled first) | `row` |
| 29 | Job Inventory (last run / end / next run / duration / outcome) | `table` |

Panel type summary: `bargauge`: 6, `row`: 6, `stat`: 8, `table`: 7, `timeseries`: 2

## Metrics used

- `mssql_job_activity_monitor`
- `mssql_job_count`
- `mssql_job_enabled`
- `mssql_job_last_run_outcome`
- `mssql_job_next_run_age_seconds`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
