# mssql_restore

دسترسی خاص:

- فایل: `collector/mssql_restore.collector.yml`
- collector_name: `mssql_restore`
- min_interval: `300s`
- تعداد metric: `14`
- query_refهای مشترک: `mssql_restore_db_state`, `mssql_restore_job_failed`, `mssql_restore_job_failed_total`, `mssql_restore_last`, `mssql_restore_last_by_type`

هدف و کاربرد

- Restore / backup-sync freshness (msdb.dbo.restorehistory + backupset).
- Mirrors the Power BI restore monitor: last restore per destination DB,
- lag since restored backup (Difference Restore), source server/db, type, size.
- Intended for secondary / standby hosts that continuously RESTORE Full/Diff/Log
- from another instance (log-shipping-like), e.g. sql-host-02\NODE.
- lookback برای restorehistory پنجره غلتان ۴۰۰ روزه است (نه سال تقویمی).

نکات عملیاتی

مجوزها و پیش‌نیازها
- Special access: Read msdb restore metadata (for example restorehistory).
نکات موجود در فایل منبع:
  - GRANT SELECT ON msdb.dbo.restorehistory TO
  - GRANT SELECT ON msdb.dbo.backupset TO
  - GRANT SELECT ON msdb.dbo.backupmediafamily TO
  - GRANT SELECT ON msdb.dbo.sysjobs / sysjobsteps / sysjobhistory / syscategories TO

مجوزهای پایه: `mrics`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_restore_lag_seconds` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `lag_seconds` | query_ref=`mssql_restore_last` | Seconds since backup_finish_date of the most recent restore (Power BI Difference Restore). -1 = none in last 400 days. |
| `mssql_restore_gap_to_rpo_seconds` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `lag_seconds` | query_ref=`mssql_restore_last` | Alias of `mssql_restore_lag_seconds` برای آلرت/داشبوردهای موجود. |
| `mssql_restore_age_seconds` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `age_seconds` | query_ref=`mssql_restore_last` | Seconds since restore_date of the most recent restore per destination database. -1 = never. |
| `mssql_restore_last_unix` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `restore_unix` | query_ref=`mssql_restore_last` | Unix epoch of last restore_date (0 = never). |
| `mssql_restore_backup_unix` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `backup_unix` | query_ref=`mssql_restore_last` | Unix epoch of backup_finish_date for the last restored backup (0 = never). |
| `mssql_restore_backup_size_bytes` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `backup_size_bytes` | query_ref=`mssql_restore_last` | backup_size of the most recent restored backup (0 if unknown). |
| `mssql_restore_throughput_mb_s` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `throughput_mb_s` | query_ref=`mssql_restore_last` | Throughput of the source backup for the most recently restored backup (MB/s). |
| `mssql_restore_last_by_type_lag_seconds` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `lag_seconds` | query_ref=`mssql_restore_last_by_type` | Seconds since backup_finish_date of last restore by backup type (full/diff/log). -1 = none in last 400 days. |
| `mssql_restore_last_by_type_age_seconds` | `gauge` | `db`, `original_db`, `backup_type`, `original_server`, `recovery_model` | `age_seconds` | query_ref=`mssql_restore_last_by_type` | Seconds since restore_date of last restore by backup type. -1 = none in last 400 days. |
| `mssql_restore_db_standby` | `gauge` | `db`, `state_desc` | `is_in_standby` | query_ref=`mssql_restore_db_state` | 1 if database is in standby / read-only restoring mode (is_in_standby=1). |
| `mssql_restore_db_state` | `gauge` | `db`, `state_desc` | `state` | query_ref=`mssql_restore_db_state` | sys.databases.state for DBs that are RESTORING/RECOVERING/standby or have restorehistory in last 400 days. |
| `mssql_restore_job_failed_24h` | `gauge` | `job_name`, `category_name` | `failed_count` | query_ref=`mssql_restore_job_failed` | خروجی‌های ناموفق jobهای SQL Agent (۲۴ ساعت) برای jobهایی که مرحله RESTORE دارند. |
| `mssql_restore_job_executions_24h` | `gauge` | `job_name`, `category_name` | `execution_count` | query_ref=`mssql_restore_job_failed` | تعداد کل اجرای jobهای RESTORE در ۲۴ ساعت (فقط jobهایی که حداقل یک fail داشته‌اند). |
| `mssql_restore_job_failed_total_24h` | `gauge` | — | `failed_count` | query_ref=`mssql_restore_job_failed_total` | Total failed restore-related Agent job outcomes in last 24h. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
