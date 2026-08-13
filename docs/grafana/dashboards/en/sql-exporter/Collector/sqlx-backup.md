# Collector backup

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-backup.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Backup age and coverage for Full/Diff/Log; encryption gaps pair with Security.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-backup` |
| Source file | [`sqlx-backup.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-backup.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `backup` |
| Panel count | 17 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Failed Jobs 24h | `stat` |
| 2 | Verify Fail 24h | `stat` |
| 3 | Damaged 7d | `stat` |
| 4 | Never Full | `stat` |
| 5 | Max Full Age | `stat` |
| 6 | No Enc Full | `stat` |
| 7 | Backup Age RW (Full 7d / Diff / Log) | `table` |
| 8 | Backup Age (Read-Only / Monthly) | `table` |
| 9 | Backup Size | `timeseries` |
| 10 | Throughput | `timeseries` |
| 11 | Compression Ratio | `timeseries` |
| 12 | Backup Age Trend | `timeseries` |
| 13 | Backup Job Failed 24h | `table` |
| 14 | Damaged 7d | `table` |
| 15 | Last Backup Size (Full / Diff / Log today) | `table` |
| 16 | Unencrypted Backup (Full / Diff / Log) | `table` |
| 17 | Backup Performance | `table` |

Panel type summary: `stat`: 6, `table`: 7, `timeseries`: 4

## Metrics used

- `mssql_alwayson_replica_db_synchronization_health`
- `mssql_backup_age_seconds`
- `mssql_backup_compression_ratio`
- `mssql_backup_damaged_7d`
- `mssql_backup_encryption_enabled`
- `mssql_backup_job_failed_24h`
- `mssql_backup_job_failed_total_24h`
- `mssql_backup_log_size_today_bytes`
- `mssql_backup_size_bytes`
- `mssql_backup_throughput_mb_s`
- `mssql_backup_verify_failed_count`
- `mssql_database_is_read_only`
- `mssql_restore_db_standby`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
