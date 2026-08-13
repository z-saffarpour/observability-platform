# Collector resource_governor

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-resource-governor.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Resource Governor ops view: enablement, reconfiguration pending, pool CPU/memory caps, memgrant waiters/timeouts/OOM, workload-group queueing and CPU-limit violations. Collector: mssql_resource_governor (60s).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-resource-governor` |
| فایل منبع | [`sqlx-resource-governor.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-resource-governor.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `resource_governor`, `memory`, `cpu` |
| تعداد پنل‌ها | 29 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_resource_governor_enabled{job="sql_exporter"}, instance)` |
| `pool` | Pool | `query` | `label_values(mssql_resource_governor_pool_max_cpu_percent{job="sql_exporter", instance=~"$instance"}, pool)` |
| `workload_group` | Workload Group | `query` | `label_values(mssql_resource_governor_group_active_requests{job="sql_exporter", instance=~"$instance", pool=~"$pool"}, workload_group)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | RG Enabled | `stat` |
| 3 | Reconfig Pending | `stat` |
| 4 | Memgrant Waiters | `stat` |
| 5 | Queued Requests | `stat` |
| 6 | Timeouts 10m | `stat` |
| 7 | OOM 10m | `stat` |
| 8 | CPU Limit Hits 10m | `stat` |
| 9 | Active Requests | `stat` |
| 10 | Pressure Hotspots | `row` |
| 11 | Pool Memory Pressure | `table` |
| 12 | Workload Group Queue / CPU Limit Pressure | `table` |
| 13 | Fleet Resource Governor Status | `table` |
| 14 | Resource Pools | `row` |
| 15 | Pool Configuration (CPU / Memory %) | `table` |
| 16 | Pool Runtime Snapshot | `table` |
| 17 | Workload Groups | `row` |
| 18 | Workload Group Configuration | `table` |
| 19 | Workload Group Runtime Snapshot | `table` |
| 20 | Trends | `row` |
| 21 | Pool Memgrant Waiters | `timeseries` |
| 22 | Group Queued Requests | `timeseries` |
| 23 | Pool CPU Usage (s/s) | `timeseries` |
| 24 | Group CPU Usage (s/s) | `timeseries` |
| 25 | Pool Used Memgrant | `timeseries` |
| 26 | Pool Max Workspace Memory | `timeseries` |
| 27 | Memgrant Timeouts /s | `timeseries` |
| 28 | Out of Memory /s | `timeseries` |
| 29 | CPU Limit Violations /s | `timeseries` |

ترکیب نوع پنل‌ها: `row`: 5, `stat`: 8, `table`: 7, `timeseries`: 9

## متریک‌های استفاده‌شده

- `mssql_resource_governor_enabled`
- `mssql_resource_governor_group_active_requests`
- `mssql_resource_governor_group_cpu_limit_violations_total`
- `mssql_resource_governor_group_cpu_usage_ms_total`
- `mssql_resource_governor_group_max_dop`
- `mssql_resource_governor_group_max_requests`
- `mssql_resource_governor_group_queued_requests`
- `mssql_resource_governor_group_queued_requests_total`
- `mssql_resource_governor_group_request_max_cpu_seconds`
- `mssql_resource_governor_group_request_max_memory_percent`
- `mssql_resource_governor_group_requests_total`
- `mssql_resource_governor_pool_active_memgrant_count`
- `mssql_resource_governor_pool_active_memgrant_kb`
- `mssql_resource_governor_pool_cache_memory_kb`
- `mssql_resource_governor_pool_compile_memory_kb`
- `mssql_resource_governor_pool_cpu_usage_ms_total`
- `mssql_resource_governor_pool_max_cpu_percent`
- `mssql_resource_governor_pool_max_memory_kb`
- `mssql_resource_governor_pool_max_memory_percent`
- `mssql_resource_governor_pool_memgrant_timeouts_total`
- `mssql_resource_governor_pool_memgrant_waiter_count`
- `mssql_resource_governor_pool_min_cpu_percent`
- `mssql_resource_governor_pool_min_memory_percent`
- `mssql_resource_governor_pool_out_of_memory_total`
- `mssql_resource_governor_pool_used_memgrant_kb`
- `mssql_resource_governor_reconfiguration_pending`
- `mssql_resource_governor_workload_group_info`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
