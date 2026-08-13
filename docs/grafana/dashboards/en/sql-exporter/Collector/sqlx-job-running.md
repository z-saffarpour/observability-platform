# Collector job_running

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-job-running.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Live SQL Agent jobs ops view: Agent service health, currently running jobs with step + Runtime vs 24h success average (OverAvg), longest runners, fleet busy servers. Collector: mssql_job_running (sysjobactivity).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-job-running` |
| Source file | [`sqlx-job-running.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-job-running.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `jobs`, `job_running` |
| Panel count | 23 |
| Refresh interval | `30s` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `category` | Category | `query` | `label_values(mssql_job_running_seconds{job="sql_exporter", instance=~"$instance"}, category_name)` |
| `job_name` | Job | `query` | `label_values(mssql_job_running_seconds{job="sql_exporter", instance=~"$instance", category_name=~"${category:regex}"}, job_name)` |
| `enabled` | Enabled | `custom` | `1,0` |
| `over_avg_factor` | Over Avg x | `custom` | `1.2,1.5,2,3` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Agents Down | `stat` |
| 3 | Agents OK | `stat` |
| 4 | Jobs Running | `stat` |
| 5 | OverAvg | `stat` |
| 6 | Long >=30m | `stat` |
| 7 | Max Duration | `stat` |
| 8 | Servers Busy | `stat` |
| 9 | Fleet Count | `stat` |
| 10 | Live Running Now | `row` |
| 11 | Running Jobs by Server | `timeseries` |
| 12 | Longest Running (topk 15) | `bargauge` |
| 13 | Jobs Currently Running (Duration vs Avg) | `table` |
| 14 | Runtime Trend (topk 20) | `timeseries` |
| 15 | OverAvg Anomalies (vs own 24h success average) | `row` |
| 16 | OverAvg Ratio (topk 15) | `bargauge` |
| 17 | Long w/o Baseline (>=30m) | `bargauge` |
| 18 | Jobs Over Avg (Duration vs Avg) | `table` |
| 19 | SQL Server Agent Service | `row` |
| 20 | Agent Up (1=Running) | `timeseries` |
| 21 | Running Jobs per Server | `bargauge` |
| 22 | Agent Status by Server | `table` |
| 23 | Agents Down / Not Running | `table` |

Panel type summary: `bargauge`: 4, `row`: 4, `stat`: 8, `table`: 4, `timeseries`: 3

## Metrics used

- `mssql_job_history_avg_duration_seconds_24h`
- `mssql_job_running_count`
- `mssql_job_running_seconds`
- `mssql_job_running_start_timestamp`
- `mssql_sqlagent_running`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
