# Collector job_failed

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-job-failed.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

SQL Agent job failures ops view: sticky last-outcome fails, 1h/24h volume, recent failures with message snip, last-fail age/duration. Source: msdb sysjobhistory / sysjobservers.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-job-failed` |
| Source file | [`sqlx-job-failed.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-job-failed.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `jobs`, `failures` |
| Panel count | 27 |
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

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Failed 1h | `stat` |
| 3 | Failed 24h | `stat` |
| 4 | Sticky Failed | `stat` |
| 5 | Sticky Enabled | `stat` |
| 6 | Jobs Failed 24h | `stat` |
| 7 | Servers w/ Fail | `stat` |
| 8 | Recent Events | `stat` |
| 9 | Worst Job 24h | `stat` |
| 10 | Sticky Failures (sysjobservers.last_run_outcome = Failed) | `row` |
| 11 | Sticky Failed Jobs by Server | `timeseries` |
| 12 | Sticky Count by Server | `bargauge` |
| 13 | Currently Failed Jobs (sticky) | `table` |
| 14 | Failure Volume (1h / 24h windows) | `row` |
| 15 | Fleet Failed Totals | `timeseries` |
| 16 | Failed 24h by Server | `timeseries` |
| 17 | Top Failing Jobs | `bargauge` |
| 18 | Failures by Category | `bargauge` |
| 19 | Fail Count by Job (window filter) | `table` |
| 20 | Recent Failures (last 24h, TOP 50 / scrape, with message) | `row` |
| 21 | Longest Recent Fail Durations | `bargauge` |
| 22 | Recent Fail Count by Server | `bargauge` |
| 23 | Recent Fail Detail (message snip) | `table` |
| 24 | Last Failure Recency (jobs that failed in last 7 days) | `row` |
| 25 | Most Recent Fails (age) | `bargauge` |
| 26 | Longest Last-Fail Duration | `bargauge` |
| 27 | Last Fail Age + Duration | `table` |

Panel type summary: `bargauge`: 7, `row`: 5, `stat`: 8, `table`: 4, `timeseries`: 3

## Metrics used

- `mssql_job_failed_count`
- `mssql_job_failed_current`
- `mssql_job_failed_last_age_seconds`
- `mssql_job_failed_last_duration_seconds`
- `mssql_job_failed_recent_duration_seconds`
- `mssql_job_failed_total`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
