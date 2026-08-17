# mssql_database_size_growth

دسترسی خاص:

- فایل: `collector/mssql_database_size_growth.collector.yml`
- collector_name: `mssql_database_size_growth`
- min_interval: `300s`
- تعداد metric: `3`
- query_refهای مشترک: `mssql_database_files`, `mssql_database_sizes`

هدف و کاربرد

- Database data/log size and used space — growth tracking via Prometheus.
- GRANT VIEW ANY DEFINITION TO
- GRANT VIEW SERVER STATE TO
- Note: mf.size/growth are int (8KB pages). Always cast before SUM/multiply
- to avoid arithmetic overflow on large databases.

نکات عملیاتی

مجوزها و پیش‌نیازها
- Special access: Access to user databases.
نکات موجود در فایل منبع:
  - GRANT VIEW ANY DEFINITION TO
  - GRANT VIEW SERVER STATE TO

مجوزهای پایه: `mrics`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_database_data_size_mb` | `gauge` | `db`, `state_desc`, `recovery_model_desc` | `data_size_mb` | query_ref=`mssql_database_sizes` | Total data file size (MB) per database. |
| `mssql_database_log_size_mb` | `gauge` | `db`, `state_desc`, `recovery_model_desc` | `log_size_mb` | query_ref=`mssql_database_sizes` | Total log file size (MB) per database. |
| `mssql_database_file_size_mb` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `growth_mb`, `is_percent_growth` | `size_mb` | query_ref=`mssql_database_files` | Per-file size (MB) for growth analysis. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
