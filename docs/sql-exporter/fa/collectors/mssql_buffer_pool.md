# mssql_buffer_pool

## خلاصه

- فایل: `collector/mssql_buffer_pool.collector.yml`
- collector_name: `mssql_buffer_pool`
- min_interval: `180s`
- تعداد metric: `5`
- query_refهای مشترک: `mssql_buffer_by_db`, `mssql_buffer_counters`, `mssql_buffer_hit_ratio`, `mssql_buffer_ple`

## هدف

- سلامت Buffer pool / Buffer Manager + اشغال buffer به‌ازای هر دیتابیس.
- نیاز به `GRANT VIEW SERVER STATE`.

## متریک‌ها

| متریک | نوع | برچسب‌ها | توضیح |
|---|---|---|---|
| `mssql_buffer_pool_page_life_expectancy` | gauge | `numa_node` | PLE (ثانیه)؛ `_Total` و per-NUMA |
| `mssql_buffer_pool_cache_hit_ratio` | gauge | — | درصد hit cache (۰–۱۰۰) |
| `mssql_buffer_pool_counter` | gauge | `counter` | شمارنده‌های Buffer Manager؛ `/sec` تجمعی است → `rate(...[5m])` |
| `mssql_buffer_pool_database_pages` | gauge | `db` | صفحات cacheشده هر دیتابیس؛ `db=_Free` = صفحات آزاد |
| `mssql_buffer_pool_database_dirty_pages` | gauge | `db` | صفحات dirty هر دیتابیس |

## نکات عملیاتی

- داشبورد: `grafana/dashboards/sql-exporter/Collector/sqlx-buffer-pool.json`
- اندازه بایت: `pages * 8192`
- اسکن `sys.dm_os_buffer_descriptors` روی buffer poolهای خیلی بزرگ می‌تواند سنگین باشد؛ `min_interval` حداقل ۶۰ ثانیه بماند.
