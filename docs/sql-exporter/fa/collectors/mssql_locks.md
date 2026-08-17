# mssql_locks

دسترسی خاص:

- فایل: `collector/mssql_locks.collector.yml`
- collector_name: `mssql_locks`
- min_interval: `30s`
- تعداد metric: `7`
- query_refهای مشترک: `mssql_latch_stats`, `mssql_lock_related_requests`, `mssql_locks_summary`, `mssql_locks_waiting_count`, `mssql_locks_waiting_detail`

هدف و کاربرد

- Lock inventory and waiting locks.
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
| `mssql_locks_count` | `gauge` | `resource_type`, `request_mode`, `request_status`, `db` | `lock_count` | query_ref=`mssql_locks_summary` | Lock counts by resource type, mode and status. |
| `mssql_locks_waiting` | `gauge` | — | `waiting_locks` | query_ref=`mssql_locks_waiting_count` | Number of lock requests in WAIT status. |
| `mssql_locks_wait_time_ms` | `gauge` | `session_id`, `db`, `resource_type`, `request_mode`, `wait_type`, `login_name` | `wait_time_ms` | query_ref=`mssql_locks_waiting_detail` | Wait time (ms) for sessions waiting on locks. |
| `mssql_latch_wait_time_ms` | `gauge` | `latch_class` | `wait_time_ms` | query_ref=`mssql_latch_stats` | Cumulative latch wait time (ms) for selected latch classes. |
| `mssql_latch_waits` | `gauge` | `latch_class` | `waiting_requests_count` | query_ref=`mssql_latch_stats` | Cumulative latch waits for selected latch classes. |
| `mssql_lock_related_request_elapsed_ms` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `status`, `wait_type`, `command`, `statement_snip` | `elapsed_ms` | query_ref=`mssql_lock_related_requests` | Active user requests with lock/latch waits or elapsed >= 3s. |
| `mssql_lock_related_request_wait_ms` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `status`, `wait_type`, `command`, `statement_snip` | `wait_time_ms` | query_ref=`mssql_lock_related_requests` | Wait time (ms) for active lock/latch-related requests. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
