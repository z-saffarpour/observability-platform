# mssql_standard

دسترسی خاص:

**فایل:** `collector/mssql_standard.collector.yml`
- نام collector: `mssql_standard`
- حداقل فاصله اجرا: `30s`
- تعداد metric: `25`
- query_refهای مشترک: `mssql_perf_counters`, `mssql_process_memory`, `mssql_standard_checkpoint_pages`, `mssql_standard_compilation_counters`, `mssql_standard_connection_counters`, `mssql_standard_log_reuse_wait`

## هدف و کاربرد

- هویت اصلی instance و counterهای یکتا که به collectorهای تخصصی تعلق ندارند.
- buffer_pool → PLE، page read/write، lazy write، checkpoint، buffer cache hit
- file_io → توقف I/O (به‌ازای هر فایل / latency)
- database_size_growth → اندازه دیتابیس/فایل‌ها
- connections_detail → sessionها بر اساس host/login/program/db

## مجوزها و پیش‌نیازها
- نکات موجود در فایل منبع:
  - GRANT VIEW ANY DEFINITION TO
  - GRANT VIEW SERVER STATE TO

مجوزهای پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_up` | `gauge` | — | `count` | query | وضعیت UP. |
| `mssql_hostname` | `gauge` | `hostname` | static_value=`1` | static_value | نام میزبان سرور دیتابیس |
| `mssql_product_version` | `gauge` | `product_version_major`, `product_version_minor`, `product_version_build`, `product_version_batch`, `product_version`, `edition` | static_value=`1` | static_value | نسخه instance (Major.Minor). |
| `mssql_local_time_seconds` | `gauge` | — | `unix_time` | query | ثانیه epoch UTC (از GETUTCDATE). |
| `mssql_database_state` | `gauge` | `db`, `state_desc` | `db_state` | query | وضعیت دیتابیس‌ها: 0=ONLINE 1=RESTORING 2=RECOVERING 3=RECOVERY_PENDING 4=SUSPECT 5=EMERGENCY 6=OFFLINE 7=COPYING 10=OFFLINE_SECONDARY. |
| `mssql_database_is_read_only` | `gauge` | `db` | `is_read_only` | query | اگر دیتابیس read_only باشد 1، در غیر این صورت 0. |
| `mssql_database_recovery_model` | `gauge` | `db`, `recovery_model_desc` | `recovery_model` | query | recovery_model دیتابیس‌ها: 1=FULL 2=BULK_LOGGED 3=SIMPLE |
| `mssql_transactions` | `gauge` | `db` | `cntr_value` | query | تراکنش/ثانیه برای هر دیتابیس (cntr_value خام؛ در صورت نیاز از rate() استفاده کنید). |
| `mssql_log_growths` | `counter` | `db` | `cntr_value` | query | تعداد دفعاتی که transaction log برای هر دیتابیس expand شده است. |
| `mssql_deadlocks` | `counter` | — | `cntr_value` | query | تعداد درخواست‌های lock که به deadlock منجر شده‌اند (cntr_value خام؛ در صورت نیاز از rate() استفاده کنید). |
| `mssql_user_errors` | `counter` | — | `cntr_value` | query | تعداد خطاهای کاربر (cntr_value خام؛ در صورت نیاز از rate() استفاده کنید). |
| `mssql_kill_connection_errors` | `counter` | — | `cntr_value` | query | خطاهای شدیدی که باعث شد SQL Server connection را قطع کند (cntr_value خام؛ در صورت نیاز از rate() استفاده کنید). |
| `mssql_batch_requests` | `counter` | — | `cntr_value` | query | تعداد batchهای دستوری دریافت‌شده (cntr_value خام؛ در صورت نیاز از rate() استفاده کنید). |
| `mssql_user_connections_current` | `gauge` | — | `user_connections_current` | query_ref=`mssql_standard_connection_counters` | تعداد فعلی connectionهای کاربر. |
| `mssql_compilations_per_sec` | `gauge` | — | `compilations_per_sec` | query_ref=`mssql_standard_compilation_counters` | SQL compilation/sec (مقدار counter خام؛ در صورت نیاز از rate() استفاده کنید). |
| `mssql_recompilations_per_sec` | `gauge` | — | `recompilations_per_sec` | query_ref=`mssql_standard_compilation_counters` | SQL recompilation/sec (مقدار counter خام؛ در صورت نیاز از rate() استفاده کنید). |
| `mssql_checkpoint_pages_per_sec` | `gauge` | — | `checkpoint_pages_per_sec` | query_ref=`mssql_standard_checkpoint_pages` | صفحات checkpoint/sec (مقدار counter خام؛ در صورت نیاز از rate() استفاده کنید). |
| `mssql_log_reuse_wait` | `gauge` | `db`, `log_reuse_wait_desc` | `log_reuse_wait` | query_ref=`mssql_standard_log_reuse_wait` | مقدار فعلی log_reuse_wait برای هر دیتابیس. |
| `mssql_perf_counter` | `gauge` | `object`, `counter`, `instance` | `cntr_value` | query_ref=`mssql_perf_counters` | performance counterهای منتخب SQL Server (cntr_value خام). برای counterهای /sec از rate() استفاده کنید. |
| `mssql_resident_memory_bytes` | `gauge` | — | `resident_memory_bytes` | query_ref=`mssql_process_memory` | اندازه resident memory SQL Server (همان working set). |
| `mssql_virtual_memory_bytes` | `gauge` | — | `virtual_memory_bytes` | query_ref=`mssql_process_memory` | اندازه committed virtual memory SQL Server. |
| `mssql_memory_utilization_percentage` | `gauge` | — | `memory_utilization_percentage` | query_ref=`mssql_process_memory` | درصدی از حافظه committed که در working set قرار دارد. |
| `mssql_page_fault_count` | `counter` | — | `page_fault_count` | query_ref=`mssql_process_memory` | تعداد page faultهایی که توسط فرایند SQL Server ایجاد شده است. |
| `mssql_os_memory` | `gauge` | — ; value_label=`'state'` | `used`, `available`, `total` | query | حافظه فیزیکی سیستم‌عامل، مصرف‌شده و در دسترس. |
| `mssql_os_page_file` | `gauge` | — ; value_label=`'state'` | `used`, `available`, `total` | query | page file سیستم‌عامل، مصرف‌شده و در دسترس. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
