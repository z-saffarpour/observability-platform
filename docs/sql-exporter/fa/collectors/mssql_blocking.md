# mssql_blocking

دسترسی خاص:

- فایل: `collector/mssql_blocking.collector.yml`
- collector_name: `mssql_blocking`
- min_interval: `30s`
- تعداد metric: `6`
- query_refهای مشترک: `mssql_blocking_details`, `mssql_blocking_summary`, `mssql_head_blockers`

هدف و کاربرد

- متریک‌های blocking / head-blocker برای Microsoft SQL Server.
- لازم است کاربر SQL Server مجوزهای زیر را داشته باشد:
- GRANT VIEW SERVER STATE TO
- GRANT VIEW ANY DEFINITION TO
- به‌صورت خودکار از طریق collectors: [mssql_*] و collector_files: ["collector/*.collector.yml"] بارگذاری می‌شود

نکات عملیاتی

مجوزها و پیش‌نیازها
نکات موجود در فایل منبع:
  - لازم است کاربر SQL Server مجوزهای زیر را داشته باشد:
  - GRANT VIEW SERVER STATE TO
  - GRANT VIEW ANY DEFINITION TO

مجوزهای پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_blocking_count` | `gauge` | — | `blocked_count` | query_ref=`mssql_blocking_summary` | Number of currently blocked sessions. |
| `mssql_blocking_head_count` | `gauge` | — | `head_blocker_count` | query_ref=`mssql_blocking_summary` | Number of distinct head blockers. |
| `mssql_blocking_wait_ms` | `gauge` | `session_id`, `blocking_session_id`, `db`, `login_name`, `program_name`, `wait_type`, `status`, `command`, `statement_snip` | `wait_time_ms` | query_ref=`mssql_blocking_details` | Blocked session wait time (ms). |
| `mssql_blocking_elapsed_ms` | `gauge` | `session_id`, `blocking_session_id`, `db`, `login_name`, `program_name`, `wait_type`, `status`, `command`, `statement_snip` | `elapsed_ms` | query_ref=`mssql_blocking_details` | Blocked session elapsed time (ms). |
| `mssql_head_blocker_elapsed_ms` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `status`, `command`, `statement_snip`, `blocked_count` | `elapsed_ms` | query_ref=`mssql_head_blockers` | Head blocker session elapsed time (ms). |
| `mssql_head_blocker_cpu_ms` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `status`, `command`, `statement_snip`, `blocked_count` | `cpu_ms` | query_ref=`mssql_head_blockers` | Head blocker session CPU time (ms). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
