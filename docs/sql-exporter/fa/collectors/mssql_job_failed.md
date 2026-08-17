# mssql_job_failed

دسترسی خاص:

- فایل: `collector/mssql_job_failed.collector.yml`
- collector_name: `mssql_job_failed`
- min_interval: `60s`
- تعداد metric: `7`
- query_refهای مشترک: `mssql_job_failed_by_job`, `mssql_job_failed_current`, `mssql_job_failed_last`, `mssql_job_failed_recent`, `mssql_job_failed_total`

هدف و کاربرد

- SQL Agent job failures — dedicated alerting surface.
- Inventory → mssql_job_inventory | Running → mssql_job_running | Full history → mssql_job_history
- GRANT SELECT ON msdb.dbo.sysjobhistory TO
- GRANT SELECT ON msdb.dbo.sysjobs TO
- GRANT SELECT ON msdb.dbo.sysjobservers TO

نکات عملیاتی

مجوزها و پیش‌نیازها
- Special access: Read SQL Agent job history in msdb.
نکات موجود در فایل منبع:
  - GRANT SELECT ON msdb.dbo.sysjobhistory TO
  - GRANT SELECT ON msdb.dbo.sysjobs TO
  - GRANT SELECT ON msdb.dbo.sysjobservers TO
  - GRANT SELECT ON msdb.dbo.syscategories TO

مجوزهای پایه: `mrics`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_job_failed_total` | `gauge` | `window` | `failed_count` | query_ref=`mssql_job_failed_total` | Failed job outcomes (run_status=0, step_id=0) in lookback window. |
| `mssql_job_failed_count` | `gauge` | `job_name`, `category_name`, `enabled`, `window` | `failed_count` | query_ref=`mssql_job_failed_by_job` | Failed job outcomes per job in lookback window. |
| `mssql_job_failed_last_age_seconds` | `gauge` | `job_name`, `category_name`, `enabled` | `age_seconds` | query_ref=`mssql_job_failed_last` | Seconds since the most recent failure for each job that failed in last 7 days. |
| `mssql_job_failed_last_duration_seconds` | `gauge` | `job_name`, `category_name`, `enabled` | `duration_seconds` | query_ref=`mssql_job_failed_last` | Duration seconds of the most recent failure per job (last 7 days). |
| `mssql_job_failed_recent_duration_seconds` | `gauge` | `job_name`, `category_name`, `enabled`, `run_date` (`YYYY-MM-DD`), `run_time` (`HH:MM:SS`), `message_snip` | `duration_seconds` | query_ref=`mssql_job_failed_recent` | Recent failed outcomes in last 24h (TOP 50), with message snip. |
| `mssql_job_failed_current` | `gauge` | `job_name`, `category_name`, `enabled`, `run_date` (`YYYY-MM-DD`), `run_time` (`HH:MM:SS`) | `is_failed` | query_ref=`mssql_job_failed_current` | 1 if last_run_outcome from sysjobservers is Failed (0). Useful for sticky fail alerts. |
| `mssql_job_failed_current_duration_seconds` | `gauge` | `job_name`, `category_name`, `enabled`, `run_date`, `run_time` | `duration_seconds` | query_ref=`mssql_job_failed_current` | Duration seconds of the sticky failed last run. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
