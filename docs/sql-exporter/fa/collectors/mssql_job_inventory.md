# mssql_job_inventory

دسترسی خاص:

- فایل: `collector/mssql_job_inventory.collector.yml`
- collector_name: `mssql_job_inventory`
- min_interval: `900s`
- تعداد metric: `5`
- query_refهای مشترک: `mssql_job_activity_monitor`, `mssql_job_count`, `mssql_job_inventory`, `mssql_job_last_outcome`, `mssql_job_next_run`

هدف و کاربرد

- SQL Agent job inventory / last-run snapshot / next schedule.
- Live running → mssql_job_running
- Failures (alerts) → mssql_job_failed
- History / failures → mssql_job_history
- Backups → mssql_backup

نکات عملیاتی

مجوزها و پیش‌نیازها
- Special access: Read SQL Agent job metadata in msdb.
نکات موجود در فایل منبع:
  - GRANT SELECT ON msdb.dbo.sysjobservers TO
  - GRANT SELECT ON msdb.dbo.sysjobs TO
  - GRANT SELECT ON msdb.dbo.syscategories TO
  - GRANT SELECT ON msdb.dbo.sysjobschedules TO

مجوزهای پایه: `mrics`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_job_activity_monitor` | `gauge` | `job_name`, `category_name`, `enabled`, `last_run_status` ; value_label=`operation` | `last_run_date`, `last_run_time`, `last_run_duration`, `last_run_unix` | query_ref=`mssql_job_activity_monitor` | Last run date/time/duration/unix از sysjobservers. `last_run_unix` = تاریخ+ساعت (۰ اگر هرگز اجرا نشده). |
| `mssql_job_enabled` | `gauge` | `job_name`, `category_name` | `enabled` | query_ref=`mssql_job_inventory` | 1 if SQL Agent job is enabled, else 0. |
| `mssql_job_count` | `gauge` | `enabled` | `job_count` | query_ref=`mssql_job_count` | SQL Agent job count by enabled flag. |
| `mssql_job_last_run_outcome` | `gauge` | `job_name`, `category_name`, `enabled` | `last_run_outcome` | query_ref=`mssql_job_last_outcome` | Last run outcome from sysjobservers: 0=Fail 1=Succeed 2=Retry 3=Cancel 4=InProgress 5=Unknown. |
| `mssql_job_next_run_age_seconds` | `gauge` | `job_name`, `category_name`, `enabled` | `next_run_age_seconds` | query_ref=`mssql_job_next_run` | Seconds until next scheduled run (negative = overdue). Only jobs with a next_run_date. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
