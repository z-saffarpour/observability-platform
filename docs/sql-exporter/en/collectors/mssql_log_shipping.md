# mssql_log_shipping

## Summary

- File: `collector/mssql_log_shipping.collector.yml`
- collector_name: `mssql_log_shipping`
- min_interval: `60s`
- metric count: `6`
- shared query_ref values: `mssql_log_shipping_secondary`, `mssql_log_shipping_primary`
- Profiles: `restore-secondary`

## Purpose

- Log Shipping monitor lag from `msdb.dbo.log_shipping_monitor_secondary` / `_primary`.
- Secondary: restore latency, last restored age, copy lag, restore threshold.
- Primary: last backup age, backup threshold.
- Empty-safe when Log Shipping is not configured.

## Permissions and prerequisites

- `SELECT` on `msdb.dbo.log_shipping_monitor_primary` / `log_shipping_monitor_secondary`

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_log_shipping_secondary_lag_seconds` | `gauge` | `primary_server`, `primary_database`, `secondary_server`, `secondary_database` | `lag_seconds` | last_restored_latency (minutes → seconds). |
| `mssql_log_shipping_last_restored_age_seconds` | `gauge` | same | `restored_age_seconds` | Seconds since last_restored_date (-1 if none). |
| `mssql_log_shipping_copy_lag_seconds` | `gauge` | same | `copy_lag_seconds` | Seconds since last_copied_date (-1 if none). |
| `mssql_log_shipping_restore_threshold_minutes` | `gauge` | same | `restore_threshold_minutes` | Configured restore_threshold. |
| `mssql_log_shipping_primary_last_backup_age_seconds` | `gauge` | `primary_server`, `primary_database` | `backup_age_seconds` | Seconds since last_backup_date (-1 if none). |
| `mssql_log_shipping_backup_threshold_minutes` | `gauge` | `primary_server`, `primary_database` | `backup_threshold_minutes` | Configured backup_threshold. |
