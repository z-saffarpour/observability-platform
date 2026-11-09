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

این gaugeها فقط تا وقتی درخواست در `sys.dm_exec_requests` است مقدار دارند. با تمام شدن درخواست، سری حذف می‌شود. اجرای تمام‌شده تا شش ساعت در `mssql_slow_query_history` می‌ماند.

آلرت `SqlLongRunningRequest` متریک `mssql_requests_elapsed_ms` را می‌خواند.

## دسترسی‌ها

login مربوط به exporter به `VIEW SERVER STATE` و `VIEW ANY DEFINITION` نیاز دارد.

برای پنل‌های تاریخی plan cache در داشبورد heavy-query، collector `mssql_plan_cache_hotspots` را هم فعال کنید. برای فهرست شش‌ساعته Extended Events، collector `mssql_slow_query_history` را فعال کنید.
