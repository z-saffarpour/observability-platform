# Collector scheduler

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-scheduler.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Scheduler / SOS worker pressure: KPI, fleet trends, hot scheduler tables, and CPU topology. Collector: mssql_scheduler (30s).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-scheduler` |
| Source file | [`sqlx-scheduler.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-scheduler.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `scheduler` |
| Panel count | 31 |
| Refresh interval | `30s` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `scheduler_id` | Scheduler | `query` | `label_values(mssql_scheduler_runnable_tasks{job="sql_exporter", instance=~"$instance"}, scheduler_id)` |
| `min_runnable` | Min Runnable | `custom` | `0,1,2,5` |
| `over_avg_factor` | Over Avg x | `custom` | `1.2,1.5,2,3` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Total Runnable | `stat` |
| 3 | Total Work Queue | `stat` |
| 4 | Hot Schedulers | `stat` |
| 5 | Instances with total runnable > 10 right now. | `stat` |
| 6 | Highest runnable count on any single scheduler. | `stat` |
| 7 | Max Load Factor | `stat` |
| 8 | Pending Disk IO | `stat` |
| 9 | Online Schedulers | `stat` |
| 10 | Fleet Pressure - trends | `row` |
| 11 | Total Runnable by Server | `timeseries` |
| 12 | Total Work Queue by Server | `timeseries` |
| 13 | Signal Wait % | `timeseries` |
| 14 | Runnable per CPU | `timeseries` |
| 15 | Max Scheduler Runnable | `timeseries` |
| 16 | Hot Schedulers - investigate now | `row` |
| 17 | Scheduler Snapshot (all metrics) | `table` |
| 18 | Top Runnable Schedulers | `bargauge` |
| 19 | Top Work Queue | `bargauge` |
| 20 | Top Load Factor | `bargauge` |
| 21 | Fleet Snapshot - per server | `row` |
| 22 | Server Pressure Summary | `table` |
| 23 | Hot Schedulers (above avg) | `table` |
| 24 | Scheduler Detail - time series | `row` |
| 25 | Runnable (top 8 or filtered) | `timeseries` |
| 26 | Work Queue (top 8 or filtered) | `timeseries` |
| 27 | Load Factor (top 8 or filtered) | `timeseries` |
| 28 | Active Workers & Current Tasks | `timeseries` |
| 29 | Pending Disk IO (top 8 or filtered) | `timeseries` |
| 30 | CPU Topology & Memory | `row` |
| 31 | Server CPU Topology | `table` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 4, `timeseries`: 10

## Metrics used

- `mssql_cpu_signal_wait_percent`
- `mssql_os_cpu_count`
- `mssql_os_hyperthread_ratio`
- `mssql_os_physical_memory_kb`
- `mssql_scheduler_active_workers`
- `mssql_scheduler_current_tasks`
- `mssql_scheduler_load_factor`
- `mssql_scheduler_online_count`
- `mssql_scheduler_pending_disk_io`
- `mssql_scheduler_runnable_tasks`
- `mssql_scheduler_total_runnable`
- `mssql_scheduler_total_work_queue`
- `mssql_scheduler_work_queue`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
