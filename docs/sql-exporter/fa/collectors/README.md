# مستندات Collectorها

این پوشه شامل راهنمای جداگانه برای هر collector است.

| فایل | حداقل فاصله اجرا | تعداد metric | خلاصه |
|---|---|---|---|
| `mssql_alwayson.md` | `30s` | `32` | پایش جامع گروه‌های Always On Availability |
| `mssql_alwayson_events.md` | `300s` | `1` | flaps تغییر وضعیت replica از AlwaysOn_health (۲۴ساعت) |
| `mssql_autogrowth.md` | `300s` | `8` | رویدادهای autogrowth داده/لاگ از default trace |
| `mssql_backup.md` | `900s` | `10` | تازگی و اندازه بکاپ دیتابیس (msdb.dbo.backupset) |
| `mssql_blocking.md` | `30s` | `6` | متریک‌های blocking / head-blocker برای Microsoft SQL Server |
| `mssql_buffer_pool.md` | `180s` | `5` | سلامت buffer pool / buffer manager |
| `mssql_cdc_change_tracking.md` | `300s` | `17` | سلامت و تنظیمات CDC و Change Tracking |
| `mssql_certificates.md` | `300s` | `2` | انقضای certificate و وضعیت TDE |
| `mssql_columnstore.md` | `300s` | `12` | سلامت rowgroupهای columnstore (مفید برای DWH / BI) |
| `mssql_connections_detail.md` | `60s` | `10` | تفکیک اتصال‌های کلاینت — مشترک برای DWH و OLTP |
| `mssql_cpu.md` | `30s` | `4` | CPU پروسس SQL Server در برابر idle سیستم / سایر — از ring buffer |
| `mssql_database_integrity.md` | `3600s` | `7` | سیگنال‌های سلامت دیتابیس: suspect pages + سن آخرین CHECKDB |
| `mssql_database_configuration.md` | `300s` | `17` | تنظیمات دیتابیس و تشخیص Configuration Drift |
| `mssql_database_size_growth.md` | `300s` | `3` | اندازه data/log دیتابیس و فضای مصرف‌شده — ردیابی رشد با Prometheus |
| `mssql_database_space.md` | `300s` | `10` | ظرفیت فایل‌های دیتابیس، فضای آزاد، autogrowth و تعداد VLF |
| `mssql_errorlog_signals.md` | `300s` | `1` | شمارنده‌های سیگنال ERRORLOG برای خطاهای منتخب SQL |
| `mssql_file_io.md` | `180s` | `16` | متریک‌های تأخیر I/O به‌ازای هر فایل برای Microsoft SQL Server |
| `mssql_hadr_cluster.md` | `30s` | `11` | AG Listener، quorum/اعضای WSFC و مالکیت نود FCI |
| `mssql_heavy_queries.md` | `60s` | `4` | متریک‌های درخواست‌های فعال و سنگین SQL Server |
| `mssql_plan_cache_hotspots.md` | `5m` | `9` | نقاط داغ تاریخی plan cache بر اساس CPU، duration و memory grant |
| `mssql_index_fragmentation.md` | `21600s` | `2` | نمونه fragmentation ایندکس (LIMITED) — خیلی سنگین، فقط گاهی اجرا شود |
| `mssql_index_usage.md` | `300s` | `19` | مصرف سبک ایندکس (TOP ایندکس‌های داغ) — نه fragmentation |
| `mssql_instance_configuration.md` | `300s` | `7` | drift تنظیمات instance (value در برابر in_use)، IFI، uptime، Trace Flagهای Global |
| `mssql_job_failed.md` | `60s` | `7` | ناموفق‌های SQL Agent — سطح اختصاصی برای alerting |
| `mssql_job_history.md` | `120s` | `8` | تاریخچه jobهای SQL Agent (sysjobhistory) — خطاها، تعداد اجرا و آخرین مدت اجرا |
| `mssql_job_inventory.md` | `900s` | `5` | فهرست jobهای SQL Agent / snapshot آخرین اجرا / برنامه بعدی |
| `mssql_job_running.md` | `30s` | `5` | jobهای در حال اجرای SQL Agent (+ وضعیت سرویس Agent) |
| `mssql_locks.md` | `30s` | `7` | فهرست lockها و lockهای در انتظار |
| `mssql_log_shipping.md` | `60s` | `6` | تأخیر Log Shipping ثانویه / سن restore / copy lag / آستانه‌ها |
| `mssql_log_usage.md` | `60s` | `6` | مصرف transaction log — مشترک برای DWH و OLTP |
| `mssql_memory.md` | `60s` | `16` | متریک‌های حافظه برای Microsoft SQL Server |
| `mssql_missing_index.md` | `600s` | `11` | نمونه DMV ایندکس‌های گمشده (TOP N با محدودیت cardinality) |
| `mssql_parallelism.md` | `60s` | `6` | waitها، تنظیمات و درخواست‌های فعال مرتبط با parallelism |
| `mssql_plan_cache.md` | `120s` | `13` | اندازه plan cache، تفکیک نوع object و فشار planهای single-use |
| `mssql_polybase.md` | `60s` | `39` | نصب PolyBase، سلامت Node/DMS، بار توزیع‌شده، inventory کاتالوگ و خطاهای اخیر |
| `mssql_query_store.md` | `300s` | `11` | فعال‌بودن Query Store + کوئری‌های برتر از DBهایی که QS روشن دارند |
| `mssql_replication.md` | `60s` | `21` | Replication در SQL Server (Transactional Push / Pull) |
| `mssql_resource_governor.md` | `60s` | `27` | پیکربندی و فشار Runtime در Resource Pool و Workload Group |
| `mssql_restore.md` | `300s` | `14` | تازگی restore / backup-sync (msdb.dbo.restorehistory + backupset) |
| `mssql_scheduler.md` | `30s` | `12` | فشار scheduler / SOS worker و توپولوژی CPU |
| `mssql_security.md` | `300s` | `25` | وضعیت امنیت SQL Server: failed login، audit، دسترسی privileged، رمزنگاری، surface area و متریک‌های امنیتی منتقل‌شده |
| `mssql_service_broker.md` | `60s` | `65` | Service Broker: صف‌ها، transmission، conversation، endpoint/transport، activation و forwarding |
| `mssql_ssis.md` | `60s` | `32` | کاتالوگ SSIS + مانیتورینگ سلامت SSISDB |
| `mssql_standard.md` | `30s` | `25` | هویت اصلی instance و counterهای یکتا که به collectorهای تخصصی تعلق ندارند |
| `mssql_stats.md` | `600s` | `6` | statistics قدیمی / زیاد تغییرکرده (TOP N در دیتابیس‌های آنلاین user) |
| `mssql_tempdb.md` | `60s` | `13` | متریک‌های tempdb برای Microsoft SQL Server |
| `mssql_transactions_long.md` | `30s` | `3` | تراکنش‌های بازِ طولانی |
| `mssql_waits.md` | `120s` | `10` | متریک‌های wait stats برای Microsoft SQL Server |

## شروع سریع

1. ابتدا [install-config-guide](../install-config-guide.md) را بخوان.
2. مستند collector مربوطه را باز کن.
3. اگر collector جدید اضافه می‌کنی، [collector-guide](../collector-guide.md) را هم بخوان.
