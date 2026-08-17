# mssql_job_running

دسترسی خاص:

- فایل: `collector/mssql_job_running.collector.yml`
- collector_name: `mssql_job_running`
- min_interval: `30s`
- تعداد metric: `5`
- query_refهای مشترک: `mssql_job_running_count`, `mssql_job_running_jobs`, `mssql_sqlagent_service`

هدف و کاربرد

- Currently running SQL Agent jobs (+ Agent service state).
- Inventory / last outcome → mssql_job_inventory
- History → mssql_job_history | Failures (alerts) → mssql_job_failed
- SELECT on msdb.dbo.sysjobactivity, sysjobs, sysjobsteps, syscategories, syssessions
- VIEW SERVER STATE for dm_server_services (Agent status)

نکات عملیاتی

مجوزها و پیش‌نیازها
- Special access: Read SQL Agent job metadata in msdb.

مجوزهای پایه: `mrics`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_sqlagent_running` | `gauge` | — | `is_running` | query_ref=`mssql_sqlagent_service` | 1 if SQL Server Agent service status_desc is Running, else 0. Empty if dm_server_services unavailable. |
| `mssql_job_running_count` | `gauge` | — | `running_count` | query_ref=`mssql_job_running_count` | Number of currently running SQL Agent jobs. |
| `mssql_job_running_seconds` | `gauge` | `job_name`, `category_name`, `enabled`, `step_id`, `step_name` | `running_seconds` | query_ref=`mssql_job_running_jobs` | Seconds since start for currently running SQL Agent jobs. |
| `mssql_job_running_start_timestamp` | `gauge` | `job_name`, `category_name`, `enabled`, `step_id`, `step_name` | `start_unix` | query_ref=`mssql_job_running_jobs` | Unix seconds زمان شروع جاب (`sysjobactivity.start_execution_date`). |
| `mssql_job_running_step` | `gauge` | `job_name`, `category_name`, `enabled`, `step_id`, `step_name` | `step_id_value` | query_ref=`mssql_job_running_jobs` | Current/last-executed step_id for running jobs (0 if none yet). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
