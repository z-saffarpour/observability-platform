# mssql_plan_cache_hotspots

## خلاصه

- فایل: `collector/mssql_plan_cache_hotspots.collector.yml`
- Collector: `mssql_plan_cache_hotspots`
- فاصله اجرا: `5m`
- کاربرد: رتبه‌بندی تاریخی plan cache بر اساس CPU، elapsed time و memory grant.

## متریک‌ها

- CPU: `mssql_top_query_total_worker_ms`، `mssql_top_query_avg_elapsed_ms`، `mssql_top_query_execution_count`
- Duration: `mssql_top_query_total_elapsed_ms`، `mssql_top_query_avg_duration_ms`، `mssql_top_query_elapsed_execution_count`
- Grant: `mssql_top_query_max_grant_mb`، `mssql_top_query_max_used_grant_mb`، `mssql_top_query_grant_execution_count`

هر رتبه‌بندی ابتدا `sys.dm_exec_query_stats` را به ۲۵۰ candidate محدود می‌کند و سپس متن SQL و plan attributeها را استخراج می‌کند. `statement_snip` تا ۸۰۰۰ کاراکتر Unicode حفظ می‌شود.

## دسترسی‌ها

login مربوط به exporter به `VIEW SERVER STATE` و `VIEW ANY DEFINITION` نیاز دارد.

