# mssql_heavy_queries

## خلاصه

- فایل: `collector/mssql_heavy_queries.collector.yml`
- Collector: `mssql_heavy_queries`
- فاصله اجرا: `60s`
- کاربرد: نمایش نزدیک به لحظه‌ی درخواست‌های فعال با زمان اجرای حداقل پنج ثانیه.

## متریک‌ها

- `mssql_requests_elapsed_ms`
- `mssql_requests_cpu_ms`
- `mssql_requests_granted_memory_mb`
- `mssql_requests_logical_reads`

هر چهار متریک از `mssql_active_heavy_requests` استفاده می‌کنند و `statement_snip` را تا ۸۰۰۰ کاراکتر Unicode نگه می‌دارند.

## دسترسی‌ها

login مربوط به exporter به `VIEW SERVER STATE` و `VIEW ANY DEFINITION` نیاز دارد.

برای فعال بودن پنل‌های تاریخی plan cache در داشبورد heavy-query، collector جدید `mssql_plan_cache_hotspots` را نیز فعال کنید.
