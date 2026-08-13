# mssql_database_configuration

## خلاصه

- فایل: `collector/mssql_database_configuration.collector.yml`
- `collector_name`: `mssql_database_configuration`
- `min_interval`: `300s`
- تعداد metric: `17`
- مناسب برای: تمام پروفایل‌ها

## هدف

این Collector تنظیمات مهم هر دیتابیس را برای تشخیص Configuration Drift منتشر
می‌کند. خروجی آن شامل compatibility level، Page Verify، تنظیمات Statistics،
Isolation، Parameterization، Recovery، Delayed Durability، ADR، Query Store و
تنظیمات منتخب Database Scoped است.

## دسترسی‌ها

- `VIEW ANY DATABASE` برای مشاهده فهرست دیتابیس‌ها
- دسترسی `CONNECT` به هر دیتابیس
- `VIEW DATABASE STATE` برای Query Store و Database Scoped Configuration توصیه می‌شود

دیتابیس‌های غیرقابل‌دسترسی در Queryهای per-database نادیده گرفته می‌شوند. برای
قابلیت‌هایی که نسخه SQL Server پشتیبانی نمی‌کند مقدار `-1` برگردانده می‌شود.

## متریک‌ها

| متریک | مفهوم |
|---|---|
| `mssql_database_compatibility_level` | Compatibility level دیتابیس |
| `mssql_database_page_verify_option` | `0=NONE`، `1=TORN_PAGE_DETECTION`، `2=CHECKSUM` |
| `mssql_database_auto_create_stats_enabled` | وضعیت AUTO_CREATE_STATISTICS |
| `mssql_database_auto_update_stats_enabled` | وضعیت AUTO_UPDATE_STATISTICS |
| `mssql_database_auto_update_stats_async_enabled` | وضعیت به‌روزرسانی Async آمار |
| `mssql_database_auto_close_enabled` | وضعیت AUTO_CLOSE |
| `mssql_database_auto_shrink_enabled` | وضعیت AUTO_SHRINK |
| `mssql_database_read_committed_snapshot_enabled` | وضعیت RCSI |
| `mssql_database_snapshot_isolation_state` | وضعیت Snapshot Isolation |
| `mssql_database_forced_parameterization_enabled` | وضعیت PARAMETERIZATION FORCED |
| `mssql_database_target_recovery_time_seconds` | Target Recovery Time |
| `mssql_database_delayed_durability` | حالت Delayed Durability |
| `mssql_database_accelerated_recovery_enabled` | وضعیت ADR |
| `mssql_database_query_store_actual_state` | وضعیت واقعی Query Store |
| `mssql_database_query_store_desired_state` | وضعیت مطلوب Query Store |
| `mssql_database_query_store_readonly_reason` | Bitmask علت Read-only شدن Query Store |
| `mssql_database_scoped_configuration` | مقدار تنظیمات Scoped منتخب با label تنظیم |

## نمونه Ruleها

```promql
mssql_database_page_verify_option != 2
mssql_database_auto_close_enabled == 1
mssql_database_auto_shrink_enabled == 1
mssql_database_query_store_actual_state == 3
mssql_database_query_store_readonly_reason > 0
```

مقدار scoped configuration برای `MAXDOP`،
`LEGACY_CARDINALITY_ESTIMATION`، `PARAMETER_SNIFFING` و
`QUERY_OPTIMIZER_HOTFIXES` منتشر می‌شود.

## Grafana

- داشبورد: `grafana/dashboards/sql-exporter/Collector/sqlx-database-configuration.json`
