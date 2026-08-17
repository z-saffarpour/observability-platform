# mssql_memory

دسترسی خاص:

- فایل: `collector/mssql_memory.collector.yml`
- collector_name: `mssql_memory`
- min_interval: `60s`
- تعداد metric: `16`
- query_refهای مشترک: `mssql_memory_active_grants`, `mssql_memory_clerk_topn_ratio`, `mssql_memory_clerks`, `mssql_memory_manager_mb`, `mssql_memory_server_summary`, `mssql_resource_semaphores`

هدف و کاربرد

- Memory metrics for Microsoft SQL Server.
- لازم است کاربر SQL Server مجوزهای زیر را داشته باشد:
- GRANT VIEW SERVER STATE TO
- به‌صورت خودکار از طریق collectors: [mssql_*] and collector_files: ["collector/*.collector.yml"]

نکات عملیاتی

مجوزها و پیش‌نیازها
نکات موجود در فایل منبع:
  - لازم است کاربر SQL Server مجوزهای زیر را داشته باشد:
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
| `mssql_memory_clerk_size_kb` | `gauge` | `clerk_type`, `clerk_name` | `size_kb` | query_ref=`mssql_memory_clerks` | Memory clerk size in KB (top clerks; SUM(pages_kb)). |
| `mssql_resource_semaphore_available_mb` | `gauge` | `resource_semaphore_id`, `pool_id` | `available_memory_mb` | query_ref=`mssql_resource_semaphores` | Query memory grant available (MB) per resource semaphore. |
| `mssql_resource_semaphore_granted_mb` | `gauge` | `resource_semaphore_id`, `pool_id` | `granted_memory_mb` | query_ref=`mssql_resource_semaphores` | Query memory currently granted (MB) per resource semaphore. |
| `mssql_resource_semaphore_grantee_count` | `gauge` | `resource_semaphore_id`, `pool_id` | `grantee_count` | query_ref=`mssql_resource_semaphores` | Number of queries currently granted memory. |
| `mssql_resource_semaphore_waiter_count` | `gauge` | `resource_semaphore_id`, `pool_id` | `waiter_count` | query_ref=`mssql_resource_semaphores` | Number of queries waiting for memory grant (RESOURCE_SEMAPHORE risk). |
| `mssql_resource_semaphore_target_mb` | `gauge` | `resource_semaphore_id`, `pool_id` | `target_memory_mb` | query_ref=`mssql_resource_semaphores` | Target memory (MB) for resource semaphore. |
| `mssql_resource_semaphore_max_mb` | `gauge` | `resource_semaphore_id`, `pool_id` | `max_memory_mb` | query_ref=`mssql_resource_semaphores` | Max memory (MB) for resource semaphore. |
| `mssql_memory_manager_mb` | `gauge` | `counter` | `value_mb` | query_ref=`mssql_memory_manager_mb` | SQL Memory Manager counters converted to MB. |
| `mssql_memory_grants_outstanding` | `gauge` | — | `cntr_value` | query | Memory grants currently outstanding. |
| `mssql_memory_grants_pending` | `gauge` | — | `cntr_value` | query | Memory grants currently pending (RESOURCE_SEMAPHORE pressure). |
| `mssql_memory_target_server_mb` | `gauge` | — | `target_server_mb` | query_ref=`mssql_memory_server_summary` | Target Server Memory (MB). |
| `mssql_memory_total_server_mb` | `gauge` | — | `total_server_mb` | query_ref=`mssql_memory_server_summary` | Total Server Memory (MB). |
| `mssql_memory_stolen_mb` | `gauge` | — | `stolen_server_mb` | query_ref=`mssql_memory_server_summary` | Stolen Server Memory (MB). |
| `mssql_memory_locked_pages_mb` | `gauge` | — | `locked_pages_mb` | query_ref=`mssql_memory_server_summary` | Locked pages allocated (MB). |
| `mssql_memory_clerk_topn_ratio` | `gauge` | — | `topn_ratio_percent` | query_ref=`mssql_memory_clerk_topn_ratio` | Percent of total clerk pages held by top N clerks by size. |
| `mssql_memory_active_grant_mb` | `gauge` | `session_id`, `db`, `login_name`, `wait_type`, `statement_snip` | `granted_mb` | query_ref=`mssql_memory_active_grants` | Active requests with significant memory grant (>= 100MB). `statement_snip` تا ۸۰۰۰ کاراکتر. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
