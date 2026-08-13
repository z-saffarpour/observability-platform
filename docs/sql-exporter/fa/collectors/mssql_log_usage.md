# mssql_log_usage

دسترسی خاص:

- فایل: `collector/mssql_log_usage.collector.yml`
- collector_name: `mssql_log_usage`
- min_interval: `60s`
- تعداد metric: `3`
- query_refهای مشترک: `mssql_log_space`

هدف و کاربرد

- Transaction log usage — shared for DWH and OLTP.
- GRANT VIEW SERVER STATE TO

نکات عملیاتی

مجوزها و پیش‌نیازها
نکات موجود در فایل منبع:
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
| `mssql_log_used_percent` | `gauge` | `db`, `log_reuse_wait_desc`, `recovery_model_desc` | `used_percent` | query_ref=`mssql_log_space` | Transaction log used percent per database. |
| `mssql_log_used_mb` | `gauge` | `db`, `log_reuse_wait_desc`, `recovery_model_desc` | `used_mb` | query_ref=`mssql_log_space` | Transaction log used size (MB) per database. |
| `mssql_log_total_mb` | `gauge` | `db`, `log_reuse_wait_desc`, `recovery_model_desc` | `total_mb` | query_ref=`mssql_log_space` | Transaction log total size (MB) per database. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
