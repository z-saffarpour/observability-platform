# mssql_resource_governor

## خلاصه

- فایل: `collector/mssql_resource_governor.collector.yml`
- `collector_name`: `mssql_resource_governor`
- `min_interval`: `60s`
- تعداد metric: `27`
- پروفایل‌ها: `oltp` و `dwh`

## هدف

این Collector وضعیت، پیکربندی و فشار Runtime مربوط به SQL Server Resource
Governor را در سطح Resource Pool و Workload Group منتشر می‌کند.

پوشش اصلی:

- فعال بودن Resource Governor و Pending بودن Reconfigure
- حداقل/حداکثر CPU و Memory هر Pool
- CPU تجمعی، Cache، Compile Memory و Memory Grant هر Pool
- Memory Grant Waiter، Timeout و Out-of-Memory
- Importance، MAXDOP، سقف CPU، Memory Grant و Concurrent Request هر Group
- درخواست‌های Active/Queued و شمارنده‌های CPU و CPU Limit Violation

Labelها فقط شامل `pool`، `workload_group` و `importance` هستند؛ بنابراین
cardinality به تعداد Poolها و Groupهای تعریف‌شده محدود می‌ماند.

## دسترسی‌ها

```sql
GRANT VIEW ANY DEFINITION TO [monitoring_user];
GRANT VIEW SERVER STATE TO [monitoring_user];
```

در SQL Server 2022 و جدیدتر برای DMVهای Runtime از مجوز زیر استفاده شود:

```sql
GRANT VIEW SERVER PERFORMANCE STATE TO [monitoring_user];
```

## نمونه Ruleها

```promql
mssql_resource_governor_reconfiguration_pending == 1
mssql_resource_governor_pool_memgrant_waiter_count > 0
increase(mssql_resource_governor_pool_memgrant_timeouts_total[10m]) > 0
increase(mssql_resource_governor_pool_out_of_memory_total[10m]) > 0
mssql_resource_governor_group_queued_requests > 0
increase(mssql_resource_governor_group_cpu_limit_violations_total[10m]) > 0
```

شمارنده‌های تجمعی پس از Restart سرویس SQL Server یا اجرای
`ALTER RESOURCE GOVERNOR RESET STATISTICS` از صفر شروع می‌شوند.
