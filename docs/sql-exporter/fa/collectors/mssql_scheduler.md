# mssql_scheduler

دسترسی خاص:

- فایل: `collector/mssql_scheduler.collector.yml`
- collector_name: `mssql_scheduler`
- min_interval: `30s`
- تعداد metric: `12`
- query_refهای مشترک: `mssql_scheduler_totals`, `mssql_schedulers`, `mssql_sys_info`

هدف و کاربرد

- Scheduler / SOS worker pressure and CPU topology.
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
| `mssql_scheduler_runnable_tasks` | `gauge` | `scheduler_id`, `cpu_id` | `runnable_tasks_count` | query_ref=`mssql_schedulers` | Runnable tasks waiting for CPU on visible online schedulers. |
| `mssql_scheduler_current_tasks` | `gauge` | `scheduler_id`, `cpu_id` | `current_tasks_count` | query_ref=`mssql_schedulers` | Current tasks bound to visible online schedulers. |
| `mssql_scheduler_active_workers` | `gauge` | `scheduler_id`, `cpu_id` | `active_workers_count` | query_ref=`mssql_schedulers` | Active workers on visible online schedulers. |
| `mssql_scheduler_work_queue` | `gauge` | `scheduler_id`, `cpu_id` | `work_queue_count` | query_ref=`mssql_schedulers` | Work queue length on visible online schedulers (worker starvation signal). |
| `mssql_scheduler_pending_disk_io` | `gauge` | `scheduler_id`, `cpu_id` | `pending_disk_io_count` | query_ref=`mssql_schedulers` | Pending disk I/O count on visible online schedulers. |
| `mssql_scheduler_load_factor` | `gauge` | `scheduler_id`, `cpu_id` | `load_factor` | query_ref=`mssql_schedulers` | Scheduler load_factor (higher = busier). |
| `mssql_scheduler_total_runnable` | `gauge` | — | `total_runnable` | query_ref=`mssql_scheduler_totals` | Sum of runnable_tasks_count across visible online schedulers. |
| `mssql_scheduler_total_work_queue` | `gauge` | — | `total_work_queue` | query_ref=`mssql_scheduler_totals` | Sum of work_queue_count across visible online schedulers. |
| `mssql_scheduler_online_count` | `gauge` | — | `online_count` | query_ref=`mssql_scheduler_totals` | Count of VISIBLE ONLINE schedulers. |
| `mssql_os_cpu_count` | `gauge` | — | `cpu_count` | query_ref=`mssql_sys_info` | Logical CPU count from sys.dm_os_sys_info. |
| `mssql_os_hyperthread_ratio` | `gauge` | — | `hyperthread_ratio` | query_ref=`mssql_sys_info` | Hyperthread ratio from sys.dm_os_sys_info. |
| `mssql_os_physical_memory_kb` | `gauge` | — | `physical_memory_kb` | query_ref=`mssql_sys_info` | physical_memory_kb from sys.dm_os_sys_info. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
