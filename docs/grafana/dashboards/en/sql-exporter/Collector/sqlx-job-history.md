# Collector job_history

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-job-history.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

SQL Agent job history ops view: failure KPIs, recent fail messages, last outcome snapshot, duration vs 24h success average (Over Avg). Collector: mssql_job_history (sysjobhistory step_id=0).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-job-history` |
| Source file | [`sqlx-job-history.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-job-history.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `jobs`, `job_history` |
| Panel count | 28 |
| Refresh interval | `2m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `job_name` | Job | `query` | `label_values(mssql_job_history_last_status{job="sql_exporter", instance=~"$instance"}, job_name)` |
| `window` | Window | `custom` | `1h,24h` |
| `over_avg_factor` | Over Avg x | `custom` | `1.2,1.5,2,3` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Failed (window) | `stat` |
| 3 | Failed 1h | `stat` |
| 4 | Failed 24h | `stat` |
| 5 | Last = Failed | `stat` |
| 6 | Success % | `stat` |
| 7 | Over Avg | `stat` |
| 8 | Jobs Tracked | `stat` |
| 9 | Canceled (win) | `stat` |
| 10 | Failures (sysjobhistory step_id=0) | `row` |
| 11 | Failed Outcomes by Server | `timeseries` |
| 12 | Runs by Status (fleet) | `timeseries` |
| 13 | Top Failed Jobs (window) | `bargauge` |
| 14 | Servers with Most Failures | `bargauge` |
| 15 | Recent Failures (24h TOP 40) | `table` |
| 16 | Last Outcome Snapshot | `row` |
| 17 | Last Status + Run At + Duration + Age | `table` |
| 18 | Jobs Whose Last Run Failed | `table` |
| 19 | Failed Last Run - Duration + Age + Run At | `table` |
| 20 | Duration vs 24h Success Average | `row` |
| 21 | Top Last Durations | `bargauge` |
| 22 | Over Avg Ratio (jobs above factor) | `bargauge` |
| 23 | Jobs Over Avg (last duration) | `table` |
| 24 | Avg Success Duration 24h (sample) | `timeseries` |
| 25 | Run Volume | `row` |
| 26 | Succeeded Runs by Server | `timeseries` |
| 27 | Failed Runs by Server | `timeseries` |
| 28 | Top Busy Jobs (all statuses) | `bargauge` |

Panel type summary: `bargauge`: 5, `row`: 5, `stat`: 8, `table`: 5, `timeseries`: 5

## Metrics used

- `mssql_job_history_avg_duration_seconds_24h`
- `mssql_job_history_failed_duration_seconds`
- `mssql_job_history_failed_total`
- `mssql_job_history_last_age_seconds`
- `mssql_job_history_last_duration_seconds`
- `mssql_job_history_last_status`
- `mssql_job_history_runs`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
