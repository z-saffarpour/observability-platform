# mssql_tempdb

دسترسی خاص:

- فایل: `collector/mssql_tempdb.collector.yml`
- collector_name: `mssql_tempdb`
- min_interval: `60s`
- تعداد metric: `13`
- query_refهای مشترک: `mssql_tempdb_files`, `mssql_tempdb_metadata_contention`, `mssql_tempdb_space`, `mssql_tempdb_space_breakdown`, `mssql_tempdb_spill_proxy`, `mssql_tempdb_top_sessions`, `mssql_tempdb_version_store`, `mssql_tempdb_waiting_tasks`

هدف و کاربرد

- tempdb metrics for Microsoft SQL Server.
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
| `mssql_tempdb_file_size_mb` | `gauge` | `file_id`, `type_desc`, `logical_name`, `physical_name` | `size_mb` | query_ref=`mssql_tempdb_files` | tempdb file size (MB). |
| `mssql_tempdb_file_used_mb` | `gauge` | `file_id`, `type_desc`, `logical_name`, `physical_name` | `used_mb` | query_ref=`mssql_tempdb_files` | tempdb file used space (MB). |
| `mssql_tempdb_file_free_mb` | `gauge` | `file_id`, `type_desc`, `logical_name`, `physical_name` | `free_mb` | query_ref=`mssql_tempdb_files` | tempdb file free space (MB). |
| `mssql_tempdb_space_used_mb` | `gauge` | `usage` | `used_mb` | query_ref=`mssql_tempdb_space` | tempdb space usage by category (MB). |
| `mssql_tempdb_version_store_mb` | `gauge` | — | `version_store_mb` | query_ref=`mssql_tempdb_version_store` | tempdb version store size (MB). |
| `mssql_tempdb_version_cleanup_rate_mb_s` | `gauge` | — | `version_cleanup_rate_mb_s` | query_ref=`mssql_tempdb_version_store` | tempdb version cleanup rate (MB/s) from DMV snapshot values. |
| `mssql_tempdb_version_generation_rate_mb_s` | `gauge` | — | `version_generation_rate_mb_s` | query_ref=`mssql_tempdb_version_store` | tempdb version generation rate (MB/s) from DMV snapshot values. |
| `mssql_tempdb_session_used_mb` | `gauge` | `session_id`, `login_name`, `program_name`, `db` | `used_mb` | query_ref=`mssql_tempdb_top_sessions` | Top sessions by tempdb space used (user + internal objects, MB). |
| `mssql_tempdb_waiting_tasks_count` | `gauge` | — | `waiting_tasks_count` | query_ref=`mssql_tempdb_waiting_tasks` | Current waiting tasks likely blocked by tempdb-related waits. |
| `mssql_tempdb_internal_object_mb` | `gauge` | — | `internal_object_mb` | query_ref=`mssql_tempdb_space_breakdown` | Current internal object space in tempdb (MB). |
| `mssql_tempdb_user_object_mb` | `gauge` | — | `user_object_mb` | query_ref=`mssql_tempdb_space_breakdown` | Current user object space in tempdb (MB). |
| `mssql_tempdb_spill_writes_mb` | `gauge` | — | `spill_writes_mb` | query_ref=`mssql_tempdb_spill_proxy` | Active session tempdb internal allocation footprint (MB), spill pressure proxy. |
| `mssql_tempdb_metadata_contention_count` | `gauge` | — | `contention_count` | query_ref=`mssql_tempdb_metadata_contention` | Current waiting tasks on tempdb allocation-map pages (metadata contention proxy). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
