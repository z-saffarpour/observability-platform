# Collector cdc

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-cdc.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Change Data Capture ops: enablement, capture lag, retained LSN age, capture/cleanup jobs, trends. Collector: mssql_cdc_change_tracking (300s).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-cdc` |
| Source file | [`sqlx-cdc.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-cdc.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `cdc` |
| Panel count | 24 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_cdc_enabled{job="sql_exporter", instance=~"$instance"}, db)` |
| `lag_warn` | Lag Warn (s) | `custom` | `300,900,1800,3600` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Databases with is_cdc_enabled = 1. | `stat` |
| 3 | Sum of CDC capture instances / change tables. | `stat` |
| 4 | Seconds since CDC high endpoint was processed. | `stat` |
| 5 | CDC DBs with capture lag >= Lag Warn. | `stat` |
| 6 | CDC capture Agent jobs that are disabled. | `stat` |
| 7 | Continuous capture jobs that are not running. | `stat` |
| 8 | CDC cleanup Agent jobs that are disabled. | `stat` |
| 9 | Oldest retained capture-instance LSN age. | `stat` |
| 10 | CDC Inventory | `row` |
| 11 | CDC Databases | `table` |
| 12 | Top CDC Capture Lag | `bargauge` |
| 13 | Top Retained LSN Age | `bargauge` |
| 14 | CDC Capture / Cleanup Jobs | `row` |
| 15 | CDC Jobs (capture + cleanup) | `table` |
| 16 | CDC Capture Job Running | `timeseries` |
| 17 | CDC Cleanup Job Running | `timeseries` |
| 18 | Trends | `row` |
| 19 | CDC Capture Lag | `timeseries` |
| 20 | CDC Retained LSN Age | `timeseries` |
| 21 | CDC Capture Instances | `timeseries` |
| 22 | CDC Capture Polling Interval | `timeseries` |
| 23 | CDC Cleanup Retention (minutes) | `timeseries` |
| 24 | CDC Enabled (1/0) | `timeseries` |

Panel type summary: `bargauge`: 2, `row`: 4, `stat`: 8, `table`: 2, `timeseries`: 8

## Metrics used

- `mssql_cdc_capture_continuous_enabled`
- `mssql_cdc_capture_lag_seconds`
- `mssql_cdc_capture_polling_interval_seconds`
- `mssql_cdc_change_table_count`
- `mssql_cdc_cleanup_retention_minutes`
- `mssql_cdc_cleanup_threshold`
- `mssql_cdc_enabled`
- `mssql_cdc_job_enabled`
- `mssql_cdc_job_running`
- `mssql_cdc_retained_lsn_age_seconds`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
