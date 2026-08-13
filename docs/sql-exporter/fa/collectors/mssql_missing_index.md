# mssql_missing_index

## خلاصه

- فایل: `collector/mssql_missing_index.collector.yml`
- collector_name: `mssql_missing_index`
- min_interval: `600s`
- تعداد metric: `11`
- query_refهای مشترک: `mssql_missing_index_top`, `mssql_missing_index_db`

## هدف

- نمونه DMV ایندکس‌های گمشده (TOP N با سقف cardinality) به‌همراه rollup سطح دیتابیس.
- فقط توصیه‌ای است — قبل از CREATE INDEX حتماً اعتبارسنجی کنید.
- نیاز به `VIEW SERVER STATE`.

## مجوزها و پیش‌نیازها

- مجوز پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`.
- دسترسی به دیتابیس‌های کاربری برای resolve نام objectها.

## نحوه استفاده

- این collector را در profile متناسب با نوع سرور فعال کنید.
- روی سرورهای شلوغ، `min_interval` طولانی (پیش‌فرض ۶۰۰s) را حفظ کنید.
- در داشبورد Grafana از فیلترهای Min Score / Min Impact برای صف اقدام استفاده کنید.
- `mssql_missing_index_score` با آلرت فعلی سازگار می‌ماند؛ `cost_score` بعد از redeploy فرمول مایکروسافت را می‌دهد.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_missing_index_impact` | `gauge` | `db`, `schema_name`, `table_name`, `equality_columns`, `inequality_columns`, `included_columns` | `avg_user_impact` | درصد impact برای پیشنهادهای TOP |
| `mssql_missing_index_user_seeks` | `gauge` | همان | `user_seeks` | user_seeks |
| `mssql_missing_index_user_scans` | `gauge` | همان | `user_scans` | user_scans |
| `mssql_missing_index_score` | `gauge` | همان | `improvement_score` | امتیاز ساده = impact × (seeks + scans) |
| `mssql_missing_index_avg_cost` | `gauge` | همان | `avg_total_user_cost` | میانگین cost |
| `mssql_missing_index_unique_compiles` | `gauge` | همان | `unique_compiles` | unique_compiles |
| `mssql_missing_index_cost_score` | `gauge` | همان | `cost_score` | cost × impact × (seeks + scans) |
| `mssql_missing_index_db_suggestions` | `gauge` | `db` | `suggestion_count` | تعداد پیشنهاد نمونه‌گیری‌شده per DB |
| `mssql_missing_index_db_max_score` | `gauge` | `db` | `max_score` | بیشینه امتیاز ساده per DB |
| `mssql_missing_index_db_sum_score` | `gauge` | `db` | `sum_score` | جمع امتیازها per DB |
| `mssql_missing_index_db_max_impact` | `gauge` | `db` | `max_impact` | بیشینه impact (%) per DB |

## نکات عملیاتی

- `min_interval` جلوی اجرای مکرر queryهای سنگین را می‌گیرد.
- چند metric از یک query با `query_ref` استفاده می‌کنند.
- برچسب ستون‌ها تا ۸۰ کاراکتر truncate می‌شوند.
- objectهای بدون نام فیلتر می‌شوند.
- اگر DMV خالی باشد، خروجی خالی است و scrape نباید fail شود.
