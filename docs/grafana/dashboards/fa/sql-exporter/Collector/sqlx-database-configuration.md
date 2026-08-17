# Collector database_configuration

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-database-configuration.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Database configuration / drift ops view: AUTO_SHRINK/CLOSE, PAGE_VERIFY, RCSI/SI, stats flags, Query Store state, delayed durability/ADR, scoped optimizer settings (MAXDOP/CE/parameter sniffing/hotfixes). Collector: mssql_database_configuration (300s).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-database-configuration` |
| فایل منبع | [`sqlx-database-configuration.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-database-configuration.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `configuration`, `drift` |
| تعداد پنل‌ها | 35 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_database_compatibility_level{job="sql_exporter", instance=~"$instance"}, db)` |
| `configuration` | Scoped Setting | `custom` | `MAXDOP,LEGACY_CARDINALITY_ESTIMATION,PARAMETER_SNIFFING,QUERY_OPTIMIZER_HOTFIXES` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Servers | `stat` |
| 3 | Databases | `stat` |
| 4 | AUTO_SHRINK ON | `stat` |
| 5 | AUTO_CLOSE ON | `stat` |
| 6 | PAGE_VERIFY Risk | `stat` |
| 7 | QS ERROR | `stat` |
| 8 | QS READ_ONLY | `stat` |
| 9 | DD FORCED | `stat` |
| 10 | Unsafe / Alert Risks (SqlDatabaseConfigurationUnsafe) | `row` |
| 11 | AUTO_SHRINK Enabled | `table` |
| 12 | AUTO_CLOSE Enabled | `table` |
| 13 | PAGE_VERIFY != CHECKSUM (excl. tempdb) | `table` |
| 14 | Compatibility Level by Database | `timeseries` |
| 15 | Target Recovery Time (seconds) | `timeseries` |
| 16 | Isolation / Statistics / Parameterization | `row` |
| 17 | Isolation & Stats Flags | `table` |
| 18 | AUTO_CREATE_STATS Off | `table` |
| 19 | AUTO_UPDATE_STATS Off | `table` |
| 20 | Query Store State | `row` |
| 21 | Query Store Actual / Desired / Readonly Reason | `table` |
| 22 | Query Store ERROR | `table` |
| 23 | Query Store READ_ONLY / Reason | `table` |
| 24 | Query Store Actual State | `timeseries` |
| 25 | Query Store Readonly Reason Bitmask | `timeseries` |
| 26 | Database-Scoped Configuration | `row` |
| 27 | Scoped Configuration by Database | `table` |
| 28 | MAXDOP (0 = server default) | `bargauge` |
| 29 | Legacy CE (0=OFF, 1=ON) | `bargauge` |
| 30 | Recovery / ADR / Delayed Durability | `row` |
| 31 | Recovery Settings | `table` |
| 32 | Delayed Durability FORCED | `table` |
| 33 | Delayed Durability Mode | `timeseries` |
| 34 | Full Configuration Inventory | `row` |
| 35 | All Base Flags (AUTO_* / Isolation / Stats) | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 2, `row`: 7, `stat`: 8, `table`: 13, `timeseries`: 5

## متریک‌های استفاده‌شده

- `mssql_database_accelerated_recovery_enabled`
- `mssql_database_auto_close_enabled`
- `mssql_database_auto_create_stats_enabled`
- `mssql_database_auto_shrink_enabled`
- `mssql_database_auto_update_stats_async_enabled`
- `mssql_database_auto_update_stats_enabled`
- `mssql_database_compatibility_level`
- `mssql_database_delayed_durability`
- `mssql_database_forced_parameterization_enabled`
- `mssql_database_page_verify_option`
- `mssql_database_query_store_actual_state`
- `mssql_database_query_store_desired_state`
- `mssql_database_query_store_readonly_reason`
- `mssql_database_read_committed_snapshot_enabled`
- `mssql_database_scoped_configuration`
- `mssql_database_snapshot_isolation_state`
- `mssql_database_target_recovery_time_seconds`
- `mssql_up`
- `QUERY_OPTIMIZER_HOTFIXES`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
