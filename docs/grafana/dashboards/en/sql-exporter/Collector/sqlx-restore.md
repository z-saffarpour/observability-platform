# Collector restore

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-restore.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Restore / log-shipping ops view: Difference Restore inventory, lag by type (Full/Diff/Log), RPO gap trends, failed restore jobs, standby/state. Collector: mssql_restore.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-restore` |
| Source file | [`sqlx-restore.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-restore.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `restore`, `log_shipping` |
| Panel count | 24 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_restore_lag_seconds{job="sql_exporter", instance=~"$instance"}, db)` |
| `lag_warn` | Lag Warn (s) | `custom` | `300,900,1800,3600,7200` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Max Restore Lag | `stat` |
| 3 | Hot Lag (>= warn) | `stat` |
| 4 | Failed Jobs 24h | `stat` |
| 5 | DBs Tracked | `stat` |
| 6 | Standby DBs | `stat` |
| 7 | Restoring DBs | `stat` |
| 8 | Database State / Standby | `row` |
| 9 | Standby + State | `table` |
| 10 | Last Restore Inventory (Difference Restore) | `row` |
| 11 | Restore Status - Last Applied Backup per DB | `table` |
| 12 | Lag by Backup Type (Full / Diff / Log) | `row` |
| 13 | Difference Restore by Type | `table` |
| 14 | Trends | `row` |
| 15 | Restore Lag (Difference Restore) | `timeseries` |
| 16 | Restore Age (since restore_date) | `timeseries` |
| 17 | Log Lag by DB | `timeseries` |
| 18 | RPO Gap Trend | `timeseries` |
| 19 | Top Restore Lag (now) | `bargauge` |
| 20 | Top Log Lag (now) | `bargauge` |
| 21 | Restore Job Failures (24h) | `row` |
| 22 | Failed Restore Jobs by Server | `timeseries` |
| 23 | Top Failed Restore Jobs | `bargauge` |
| 24 | Failed Restore Jobs (detail) | `table` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 6, `table`: 4, `timeseries`: 5

## Metrics used

- `mssql_restore_age_seconds`
- `mssql_restore_backup_size_bytes`
- `mssql_restore_backup_unix`
- `mssql_restore_db_standby`
- `mssql_restore_db_state`
- `mssql_restore_gap_to_rpo_seconds`
- `mssql_restore_job_executions_24h`
- `mssql_restore_job_failed_24h`
- `mssql_restore_job_failed_total_24h`
- `mssql_restore_lag_seconds`
- `mssql_restore_last_by_type_lag_seconds`
- `mssql_restore_last_unix`
- `mssql_restore_throughput_mb_s`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
