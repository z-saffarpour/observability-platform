# mssql_job_history

دسترسی خاص:

- فایل: `collector/mssql_job_history.collector.yml`
- collector_name: `mssql_job_history`
- min_interval: `120s`
- تعداد metric: `7`
- query_refهای مشترک: `mssql_job_history_avg_success_24h`, `mssql_job_history_failed_recent`, `mssql_job_history_failed_total`, `mssql_job_history_last`, `mssql_job_history_runs`

هدف و کاربرد

- SQL Agent job history (sysjobhistory) — failures, run counts, last durations.
- Live running → mssql_job_running
- Dedicated fail alerts → mssql_job_failed
- Inventory / last outcome snapshot → mssql_job_inventory
- Backups → mssql_backup

نکات عملیاتی

مجوزها و پیش‌نیازها
- Special access: Read SQL Agent job history in msdb.
نکات موجود در فایل منبع:
  - GRANT SELECT ON msdb.dbo.sysjobhistory TO
  - GRANT SELECT ON msdb.dbo.sysjobs TO
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
| `mssql_job_history_runs` | `gauge` | `job_name`, `category_name`, `run_status`, `run_status_desc`, `window` | `run_count` | query_ref=`mssql_job_history_runs` | Job outcome rows in lookback window by run_status (step_id=0). 0=Fail 1=Succeed 2=Retry 3=Cancel 4=InProgress. |
| `mssql_job_history_failed_total` | `gauge` | `window` | `failed_count` | query_ref=`mssql_job_history_failed_total` | Failed job outcomes (run_status=0, step_id=0) in lookback window. |
| `mssql_job_history_last_duration_seconds` | `gauge` | `job_name`, `category_name`, `run_status_desc`, `run_date` (YYYY-MM-DD), `run_time` (HH:MM:SS) | `duration_seconds` | query_ref=`mssql_job_history_last` | Duration seconds of the most recent job outcome (step_id=0) per job. |
| `mssql_job_history_last_age_seconds` | `gauge` | `job_name`, `category_name`, `run_status_desc`, `run_date`, `run_time` | `age_seconds` | query_ref=`mssql_job_history_last` | Seconds since the most recent job outcome (step_id=0) per job. |
| `mssql_job_history_last_status` | `gauge` | `job_name`, `category_name`, `run_status_desc`, `run_date`, `run_time` | `run_status` | query_ref=`mssql_job_history_last` | run_status of the most recent job outcome (step_id=0). |
| `mssql_job_history_last_run_timestamp` | `gauge` | `job_name`, `category_name`, `run_status_desc`, `run_date`, `run_time` | `run_unix` | query_ref=`mssql_job_history_last` | Unix seconds of the most recent job outcome start; prefer run_date/run_time labels for display. |
| `mssql_job_history_failed_duration_seconds` | `gauge` | `job_name`, `category_name`, `run_date` (YYYY-MM-DD), `run_time` (HH:MM:SS), `message_snip` | `duration_seconds` | query_ref=`mssql_job_history_failed_recent` | Recent failed job outcomes (last 24h), TOP 40 by finish time. |
| `mssql_job_history_avg_duration_seconds_24h` | `gauge` | `job_name`, `category_name` | `avg_duration_seconds` | query_ref=`mssql_job_history_avg_success_24h` | Average successful job duration (seconds) in last 24h (step_id=0, run_status=1). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
