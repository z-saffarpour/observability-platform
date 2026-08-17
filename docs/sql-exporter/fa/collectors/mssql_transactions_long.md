# mssql_transactions_long

دسترسی خاص:

- فایل: `collector/mssql_transactions_long.collector.yml`
- collector_name: `mssql_transactions_long`
- min_interval: `30s`
- تعداد metric: `3`
- query_refهای مشترک: `mssql_active_transactions_counter`, `mssql_long_transaction_count`, `mssql_long_transactions`

هدف و کاربرد

- Long-running open transactions.
- GRANT VIEW SERVER STATE TO

نکات عملیاتی

مجوزها و پیش‌نیازها
- Special access: Access to user databases.
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
| `mssql_long_transaction_seconds` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `host_name`, `transaction_type`, `transaction_state`, `name` | `open_seconds` | query_ref=`mssql_long_transactions` | Open user transactions older than 30 seconds. |
| `mssql_long_transaction_count` | `gauge` | — | `long_tran_count` | query_ref=`mssql_long_transaction_count` | Count of open user transactions older than 30 seconds. |
| `mssql_active_transactions_per_db` | `gauge` | `db` | `cntr_value` | query_ref=`mssql_active_transactions_counter` | Active transactions counter per database (perf counter). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
