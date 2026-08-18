# mssql_buffer_pool_database

## خلاصه

- فایل: `collector/mssql_buffer_pool_database.collector.yml`
- collector_name: `mssql_buffer_pool_database`
- min_interval: `30m`
- تعداد metric: `2`
- query_refها: `mssql_buffer_pool_by_db`

## هدف

- اشغال buffer pool به‌ازای هر دیتابیس (صفحات cacheشده و dirty).
- نیاز به `GRANT VIEW SERVER STATE`.
- سنگین: `sys.dm_os_buffer_descriptors` برای هر صفحهٔ cache یک سطر دارد.

## متریک‌ها

| متریک | نوع | برچسب‌ها | توضیح |
|---|---|---|---|
| `mssql_buffer_pool_database_pages` | gauge | `db` | صفحات cacheشده در buffer pool به‌ازای هر دیتابیس (صفحات ۸ کیلوبایتی). برچسب `db=_Free` صفحات آزاد است (`database_id` 32767). |
| `mssql_buffer_pool_database_dirty_pages` | gauge | `db` | صفحات dirty (تغییرکرده) در buffer pool به‌ازای هر دیتابیس (صفحات ۸ کیلوبایتی). |

## نکات عملیاتی

- داشبورد: `grafana/dashboards/sql-exporter/Collector/sqlx-buffer-pool.json`
- این collector را به‌صورت پیش‌فرض روی هر میزبان شلوغ فعال نکنید.
- پس از اندازه‌گیری زمان کوئری روی مقصد، نام `mssql_buffer_pool_database` را صریحاً به profile اضافه کنید.
- پروفایل‌های نقش فقط `mssql_buffer_pool` را دارند؛ این collector اختیاری است.
- `min_interval` برابر `30m` است تا این DMV سنگین روی مسیر هر scrape اجرا نشود.
- اسکن `sys.dm_os_buffer_descriptors` روی buffer poolهای بزرگ ممکن است از `scrape_timeout` عبور کند.
- تنظیم `collectors: [mssql_*]` این collector را هم انتخاب می‌کند؛ در production فهرست صریح پروفایل را ترجیح دهید.
