# mssql_errorlog_signals

دسترسی خاص:

- فایل: `collector/mssql_errorlog_signals.collector.yml`
- collector_name: `mssql_errorlog_signals`
- min_interval: `300s`
- تعداد metric: `1`
- query_refهای مشترک: `mssql_errorlog_signals`

هدف و کاربرد

- ERRORLOG signal counters for selected SQL errors (last N hours).
- سیگنال‌ها شامل پرشدن فضای دیسک دستگاه backup (خطای سیستم‌عامل 112) و پر شدن
  filegroup دیتابیس هستند.
- Uses xp_readerrorlog — keep interval high on busy hosts.
- VIEW SERVER STATE; xp_readerrorlog permission (sysadmin or secured equivalent)

نکات عملیاتی

مجوزها و پیش‌نیازها
- Special access: xp_readerrorlog.
نکات موجود در فایل منبع:
  - Uses xp_readerrorlog — keep interval high on busy hosts.
  - VIEW SERVER STATE; xp_readerrorlog permission (sysadmin or secured equivalent)

مجوزهای پایه: `mrics`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_errorlog_signal_count` | `gauge` | `signal` | `event_count` | query_ref=`mssql_errorlog_signals` | تعداد سیگنال‌های ERRORLOG منتخب در ۶ ساعت اخیر. |

مقادیر فعلی label `signal`:

- `backup_disk_full_112`
- `filegroup_full_1105`
- `transaction_log_full_9002` (مثلاً پر شدن به دلیل `LOG_BACKUP`)
- `buffer_latch_timeout_845`
- `ag_suspend_from_redo` (توقف data movement در Always On / `SUSPEND_FROM_REDO`)
- `redo_error_3313`
- `redo_worker_failure`

سیگنال‌های امنیتی login شامل `18456_login_failed`، `18470_login_disabled` و
`anonymous_login_failed` به `mssql_security_errorlog_signal_count` در
`mssql_security` منتقل شده‌اند.

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
