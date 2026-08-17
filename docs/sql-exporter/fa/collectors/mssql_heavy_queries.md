# mssql_heavy_queries

دسترسی خاص:

- فایل: `collector/mssql_heavy_queries.collector.yml`
- collector_name: `mssql_heavy_queries`
- min_interval: `60s`
- تعداد metric: `13`
- query_refهای مشترک: `mssql_active_heavy_requests`, `mssql_top_cached_by_cpu`, `mssql_top_cached_by_elapsed`, `mssql_top_cached_by_grant`

هدف و کاربرد

- Heavy / active query metrics for Microsoft SQL Server.
- لازم است کاربر SQL Server مجوزهای زیر را داشته باشد:
- GRANT VIEW SERVER STATE TO
- GRANT VIEW ANY DEFINITION TO
- به‌صورت خودکار از طریق collectors: [mssql_*] and collector_files: ["collector/*.collector.yml"]

نکات عملیاتی

مجوزها و پیش‌نیازها
نکات موجود در فایل منبع:
  - لازم است کاربر SQL Server مجوزهای زیر را داشته باشد:
  - GRANT VIEW SERVER STATE TO
  - GRANT VIEW ANY DEFINITION TO

مجوزهای پایه: `mrics`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_requests_elapsed_ms` | `gauge` | `session_id`, `db`, `login_name`, `client_host`, `program_name`, `status`, `wait_type`, `command`, `query_hash`, `statement_snip` | `elapsed_ms` | query_ref=`mssql_active_heavy_requests` | Active request elapsed time in milliseconds (elapsed >= 5s). |
| `mssql_requests_cpu_ms` | `gauge` | `session_id`, `db`, `login_name`, `client_host`, `program_name`, `status`, `wait_type`, `command`, `query_hash`, `statement_snip` | `cpu_ms` | query_ref=`mssql_active_heavy_requests` | Active request CPU time in milliseconds (elapsed >= 5s). |
| `mssql_requests_granted_memory_mb` | `gauge` | `session_id`, `db`, `login_name`, `client_host`, `program_name`, `status`, `wait_type`, `command`, `query_hash`, `statement_snip` | `granted_mb` | query_ref=`mssql_active_heavy_requests` | Active request granted query memory in MB (elapsed >= 5s). |
| `mssql_requests_logical_reads` | `gauge` | `session_id`, `db`, `login_name`, `client_host`, `program_name`, `status`, `wait_type`, `command`, `query_hash`, `statement_snip` | `logical_reads` | query_ref=`mssql_active_heavy_requests` | Active request logical reads (elapsed >= 5s). |
| `mssql_top_query_total_worker_ms` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `total_worker_ms` | query_ref=`mssql_top_cached_by_cpu` | Top cached statements by total CPU/worker time (ms). |
| `mssql_top_query_avg_elapsed_ms` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `avg_elapsed_ms` | query_ref=`mssql_top_cached_by_cpu` | Average elapsed/duration time (ms) for top cached statements by total worker time. |
| `mssql_top_query_execution_count` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `execution_count` | query_ref=`mssql_top_cached_by_cpu` | Execution count for top cached statements by total worker time. |
| `mssql_top_query_total_elapsed_ms` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `total_elapsed_ms` | query_ref=`mssql_top_cached_by_elapsed` | Top cached statements by total elapsed/duration time (ms) — wall-clock query runtime. |
| `mssql_top_query_avg_duration_ms` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `avg_duration_ms` | query_ref=`mssql_top_cached_by_elapsed` | Average duration/elapsed time (ms) for top cached statements ranked by total elapsed. |
| `mssql_top_query_elapsed_execution_count` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `execution_count` | query_ref=`mssql_top_cached_by_elapsed` | Execution count for top cached statements ranked by total elapsed time. |
| `mssql_top_query_max_grant_mb` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `max_grant_mb` | query_ref=`mssql_top_cached_by_grant` | Top cached statements by max memory grant (MB), grant >= 1GB. |
| `mssql_top_query_max_used_grant_mb` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `max_used_grant_mb` | query_ref=`mssql_top_cached_by_grant` | Max used memory grant (MB) for top grant statements. |
| `mssql_top_query_grant_execution_count` | `gauge` | `db`, `obj`, `query_hash`, `statement_snip` | `execution_count` | query_ref=`mssql_top_cached_by_grant` | Execution count for top cached statements ranked by max memory grant. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
