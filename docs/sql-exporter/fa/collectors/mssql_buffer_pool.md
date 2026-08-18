# mssql_buffer_pool

## خلاصه

- فایل: `collector/mssql_buffer_pool.collector.yml`
- collector_name: `mssql_buffer_pool`
- min_interval: `180s`
- تعداد metric: `3`
- query_refها: `mssql_buffer_counters`, `mssql_buffer_hit_ratio`, `mssql_buffer_ple`

## هدف

- سلامت Buffer pool / Buffer Manager.
- نیاز به `GRANT VIEW SERVER STATE`.

## متریک‌ها

| متریک | نوع | برچسب‌ها | توضیح |
|---|---|---|---|
| `mssql_buffer_pool_page_life_expectancy` | gauge | `numa_node` | PLE (ثانیه)؛ `_Total` و per-NUMA |
| `mssql_buffer_pool_cache_hit_ratio` | gauge | — | درصد hit cache (۰–۱۰۰) |
| `mssql_buffer_pool_counter` | gauge | `counter` | شمارنده‌های Buffer Manager؛ `/sec` تجمعی است → `rate(...[5m])` |

## نکات عملیاتی

- داشبورد: `grafana/dashboards/sql-exporter/Collector/sqlx-buffer-pool.json`
- متریک‌های per-database در collector اختیاری `mssql_buffer_pool_database` هستند.
- این collector در پروفایل‌های نقش نیست، چون اسکن `sys.dm_os_buffer_descriptors` روی buffer poolهای بزرگ ممکن است از `scrape_timeout` عبور کند.
- فقط پس از اندازه‌گیری زمان کوئری روی مقصد، نام آن را صریحاً به profile اضافه کنید؛ `min_interval` آن `30m` است.
