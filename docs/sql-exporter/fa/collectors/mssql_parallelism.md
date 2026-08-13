# mssql_parallelism

دسترسی خاص:

- فایل: `collector/mssql_parallelism.collector.yml`
- collector_name: `mssql_parallelism`
- min_interval: `60s`
- تعداد metric: `6`
- query_refهای مشترک: `mssql_parallel_active`, `mssql_parallel_config`, `mssql_parallel_waits`

هدف و کاربرد

- Parallelism related waits, configs, and active parallel requests.
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
| `mssql_parallelism_wait_time_ms` | `gauge` | `wait_type` | `wait_time_ms` | query_ref=`mssql_parallel_waits` | Cumulative wait_time_ms for parallelism-related waits. |
| `mssql_parallelism_waiting_tasks` | `gauge` | `wait_type` | `waiting_tasks_count` | query_ref=`mssql_parallel_waits` | Cumulative waiting_tasks_count for parallelism-related waits. |
| `mssql_parallelism_configuration` | `gauge` | `name` | `value` | query_ref=`mssql_parallel_config` | Parallelism and related memory configs (MAXDOP, cost threshold, server memory, ad hoc). |
| `mssql_parallelism_active_request_elapsed_ms` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `dop`, `wait_type`, `statement_snip` | `elapsed_ms` | query_ref=`mssql_parallel_active` | Active parallel / large-grant requests (elapsed >= 5s). |
| `mssql_parallelism_active_request_dop` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `dop`, `wait_type`, `statement_snip` | `dop_value` | query_ref=`mssql_parallel_active` | DOP of active parallel / large-grant requests (elapsed >= 5s). |
| `mssql_parallelism_active_request_grant_mb` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `dop`, `wait_type`, `statement_snip` | `granted_mb` | query_ref=`mssql_parallel_active` | Granted memory MB for active parallel / large-grant requests (elapsed >= 5s). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
