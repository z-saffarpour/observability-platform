# Collector Jobs Hub

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-jobs-hub.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

SQL Agent Jobs Hub: fleet KPI + Failed / Running / History / Inventory sections (collapsible rows). Merges mssql_job_failed, mssql_job_running, mssql_job_history, mssql_job_inventory.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-jobs-hub` |
| Source file | [`sqlx-jobs-hub.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-jobs-hub.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `jobs`, `hub` |
| Panel count | 120 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `job_name` | Job | `query` | `label_values(mssql_job_failed_count{job="sql_exporter", instance=~"$instance"}, job_name)` |
| `category` | Category | `query` | `label_values(mssql_job_failed_count{job="sql_exporter", instance=~"$instance"}, category_name)` |
| `enabled` | Enabled | `custom` | `1,0` |
| `window` | Window | `custom` | `1h,24h` |
| `over_avg_factor` | Over Avg x | `custom` | `1.2,1.5,2,3` |
| `overdue_sec` | Overdue sec | `custom` | `60,300,900,3600,86400` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Jobs Hub / Fleet KPI | `row` |
| 2 | Agents Down | `stat` |
| 3 | Jobs Running | `stat` |
| 4 | OverAvg | `stat` |
| 5 | Sticky Failed | `stat` |
| 6 | Failed 1h | `stat` |
| 7 | Failed 24h | `stat` |
| 8 | Overdue | `stat` |
| 9 | Total Jobs | `stat` |
| 10 | Failed - sticky outcomes, volume, recent messages | `row` |
| 11 | Health / KPI | `row` |
| 12 | Failed 1h | `stat` |
| 13 | Failed 24h | `stat` |
| 14 | Sticky Failed | `stat` |
| 15 | Sticky Enabled | `stat` |
| 16 | Jobs Failed 24h | `stat` |
| 17 | Servers w/ Fail | `stat` |
| 18 | Recent Events | `stat` |
| 19 | Worst Job 24h | `stat` |
| 20 | Sticky Failures (sysjobservers.last_run_outcome = Failed) | `row` |
| 21 | Sticky Failed Jobs by Server | `timeseries` |
| 22 | Sticky Count by Server | `bargauge` |
| 23 | Currently Failed Jobs (sticky) | `table` |
| 24 | Failure Volume (1h / 24h windows) | `row` |
| 25 | Fleet Failed Totals | `timeseries` |
| 26 | Failed 24h by Server | `timeseries` |
| 27 | Top Failing Jobs | `bargauge` |
| 28 | Failures by Category | `bargauge` |
| 29 | Fail Count by Job (window filter) | `table` |
| 30 | Recent Failures (last 24h, TOP 50 / scrape, with message) | `row` |
| 31 | Longest Recent Fail Durations | `bargauge` |
| 32 | Recent Fail Count by Server | `bargauge` |
| 33 | Recent Fail Detail (message snip) | `table` |
| 34 | Last Failure Recency (jobs that failed in last 7 days) | `row` |
| 35 | Most Recent Fails (age) | `bargauge` |
| 36 | Longest Last-Fail Duration | `bargauge` |
| 37 | Last Fail Age + Duration | `table` |
| 38 | Running - live Agent jobs, OverAvg, Agent service | `row` |
| 39 | Health / KPI | `row` |
| 40 | Agents Down | `stat` |
| 41 | Agents OK | `stat` |
| 42 | Jobs Running | `stat` |
| 43 | OverAvg | `stat` |
| 44 | Long >=30m | `stat` |
| 45 | Max Duration | `stat` |
| 46 | Servers Busy | `stat` |
| 47 | Fleet Count | `stat` |
| 48 | Live Running Now | `row` |
| 49 | Running Jobs by Server | `timeseries` |
| 50 | Longest Running (topk 15) | `bargauge` |
| 51 | Jobs Currently Running (Duration vs Avg) | `table` |
| 52 | Runtime Trend (topk 20) | `timeseries` |
| 53 | OverAvg Anomalies (vs own 24h success average) | `row` |
| 54 | OverAvg Ratio (topk 15) | `bargauge` |
| 55 | Long w/o Baseline (>=30m) | `bargauge` |
| 56 | Jobs Over Avg (Duration vs Avg) | `table` |
| 57 | SQL Server Agent Service | `row` |
| 58 | Agent Up (1=Running) | `timeseries` |
| 59 | Running Jobs per Server | `bargauge` |
| 60 | Agent Status by Server | `table` |
| 61 | Agents Down / Not Running | `table` |
| 62 | History - outcomes, last run, duration vs avg | `row` |
| 63 | Health / KPI | `row` |
| 64 | Failed (window) | `stat` |
| 65 | Failed 1h | `stat` |
| 66 | Failed 24h | `stat` |
| 67 | Last = Failed | `stat` |
| 68 | Success % | `stat` |
| 69 | Over Avg | `stat` |
| 70 | Jobs Tracked | `stat` |
| 71 | Canceled (win) | `stat` |
| 72 | Failures (sysjobhistory step_id=0) | `row` |
| 73 | Failed Outcomes by Server | `timeseries` |
| 74 | Runs by Status (fleet) | `timeseries` |
| 75 | Top Failed Jobs (window) | `bargauge` |
| 76 | Servers with Most Failures | `bargauge` |
| 77 | Recent Failures (24h TOP 40) | `table` |
| 78 | Last Outcome Snapshot | `row` |
| 79 | Last Status + Run At + Duration + Age | `table` |
| 80 | Jobs Whose Last Run Failed | `table` |
| 81 | Failed Last Run - Duration + Age + Run At | `table` |
| 82 | Duration vs 24h Success Average | `row` |
| 83 | Top Last Durations | `bargauge` |
| 84 | Over Avg Ratio (jobs above factor) | `bargauge` |
| 85 | Jobs Over Avg (last duration) | `table` |
| 86 | Avg Success Duration 24h (sample) | `timeseries` |
| 87 | Run Volume | `row` |
| 88 | Succeeded Runs by Server | `timeseries` |
| 89 | Failed Runs by Server | `timeseries` |
| 90 | Top Busy Jobs (all statuses) | `bargauge` |
| 91 | Inventory - schedule, overdue, activity monitor | `row` |
| 92 | Health / KPI | `row` |
| 93 | Total Jobs | `stat` |
| 94 | True | `stat` |
| 95 | False | `stat` |
| 96 | Failed Last | `stat` |
| 97 | Succeeded | `stat` |
| 98 | Overdue | `stat` |
| 99 | Cancel/Unknown | `stat` |
| 100 | Servers | `stat` |
| 101 | Attention - Failed last run & overdue schedule | `row` |
| 102 | Failed Last Run by Server | `bargauge` |
| 103 | Overdue Jobs by Server | `bargauge` |
| 104 | Failed Jobs - last fail time & next run | `table` |
| 105 | Overdue Schedule - next run already passed | `table` |
| 106 | Upcoming Schedule - next run after now | `table` |
| 107 | Fleet inventory - counts by server / category | `row` |
| 108 | True vs False Jobs by Server | `timeseries` |
| 109 | Last-Run Outcome Counts (fleet) | `timeseries` |
| 110 | Top Categories (job count) | `bargauge` |
| 111 | Top Servers (total jobs) | `bargauge` |
| 112 | Schedule - next run (date + time) | `row` |
| 113 | Most Overdue - next run date/time | `table` |
| 114 | Upcoming Next Run (next 24h) - date/time | `table` |
| 115 | Activity Monitor - last run / end / next run | `row` |
| 116 | Longest Last Run Duration | `bargauge` |
| 117 | Longest Duration by Category | `bargauge` |
| 118 | Activity Monitor (last run / end / next run / duration) | `table` |
| 119 | Full inventory (filter Server/Category/Enabled first) | `row` |
| 120 | Job Inventory (last run / end / next run / duration / outcome) | `table` |

Panel type summary: `bargauge`: 22, `row`: 25, `stat`: 40, `table`: 20, `timeseries`: 13

## Metrics used

- `mssql_job_activity_monitor`
- `mssql_job_count`
- `mssql_job_enabled`
- `mssql_job_failed_count`
- `mssql_job_failed_current`
- `mssql_job_failed_last_age_seconds`
- `mssql_job_failed_last_duration_seconds`
- `mssql_job_failed_recent_duration_seconds`
- `mssql_job_failed_total`
- `mssql_job_history_avg_duration_seconds_24h`
- `mssql_job_history_failed_duration_seconds`
- `mssql_job_history_failed_total`
- `mssql_job_history_last_age_seconds`
- `mssql_job_history_last_duration_seconds`
- `mssql_job_history_last_status`
- `mssql_job_history_runs`
- `mssql_job_last_run_outcome`
- `mssql_job_next_run_age_seconds`
- `mssql_job_running_count`
- `mssql_job_running_seconds`
- `mssql_job_running_start_timestamp`
- `mssql_sqlagent_running`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
