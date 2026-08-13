# mssql_log_shipping

## Summary

- File: `collector/mssql_log_shipping.collector.yml`
- collector_name: `mssql_log_shipping`
- min_interval: `60s`
- metric count: `6`
- shared query_ref values: `mssql_log_shipping_secondary`, `mssql_log_shipping_primary`
- Profiles: `restore-secondary`

## Purpose

- تأخیر Log Shipping از جداول monitor در msdb.
- ثانویه: latency بازگردانی، سن آخرین restore، copy lag، آستانه restore.
- اولیه: سن آخرین backup و آستانه backup.
- وقتی Log Shipping پیکربندی نشده باشد خروجی خالی است.

## Permissions and prerequisites

- `SELECT` روی `msdb.dbo.log_shipping_monitor_primary` / `log_shipping_monitor_secondary`

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_log_shipping_secondary_lag_seconds` | `gauge` | `primary_server`, `primary_database`, `secondary_server`, `secondary_database` | `lag_seconds` | last_restored_latency (دقیقه → ثانیه). |
| `mssql_log_shipping_last_restored_age_seconds` | `gauge` | همان | `restored_age_seconds` | ثانیه از last_restored_date (۱- اگر نباشد). |
| `mssql_log_shipping_copy_lag_seconds` | `gauge` | همان | `copy_lag_seconds` | ثانیه از last_copied_date (۱- اگر نباشد). |
| `mssql_log_shipping_restore_threshold_minutes` | `gauge` | همان | `restore_threshold_minutes` | آستانه restore پیکربندی‌شده. |
| `mssql_log_shipping_primary_last_backup_age_seconds` | `gauge` | `primary_server`, `primary_database` | `backup_age_seconds` | ثانیه از last_backup_date. |
| `mssql_log_shipping_backup_threshold_minutes` | `gauge` | `primary_server`, `primary_database` | `backup_threshold_minutes` | آستانه backup پیکربندی‌شده. |
