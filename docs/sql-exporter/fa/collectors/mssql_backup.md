# mssql_backup

دسترسی خاص:

**فایل:** `collector/mssql_backup.collector.yml`
- نام collector: `mssql_backup`
- حداقل فاصله اجرا: `900s`
- تعداد metric: `10`
- query_refهای مشترک: `mssql_backup_age`, `mssql_backup_damaged`, `mssql_backup_job_failed`, `mssql_backup_job_failed_total`, `mssql_backup_log_size_today`, `mssql_backup_recent_performance`, `mssql_backup_size`, `mssql_backup_verify_failed`, `mssql_recent_backup`

## هدف و کاربرد

- تازگی و اندازه بکاپ دیتابیس (msdb.dbo.backupset).
- lookback بکاپ‌ها پنجره غلتان **۴۰۰ روزه** است (`DATEADD(DAY, -400, GETDATE())`)، نه سال تقویمی —
  تا بکاپ Full ماهانهٔ قدیمی‌تر از ۹۰ روز به‌اشتباه «هرگز» گزارش نشود.
- Jobها → mssql_job_inventory / mssql_job_running / mssql_job_history
- GRANT SELECT ON msdb.dbo.backupset TO

## مجوزها و پیش‌نیازها
- دسترسی خاص: خواندن metadata بکاپ در msdb (برای مثال backupset).
- نکات موجود در فایل منبع:
  - GRANT SELECT ON msdb.dbo.backupset TO
  - GRANT SELECT ON msdb.dbo.sysjobs / sysjobsteps / sysjobhistory / syscategories TO

مجوزهای پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_recent_backup` | `gauge` | `db` ; value_label=`operation` | `last_full_backup_datetime`, `last_diff_backup_datetime`, `last_log_backup_datetime` | query_ref=`mssql_recent_backup` | زمان Unix آخرین Full/Diff/Log backup برای هر دیتابیس (0 = هرگز). |
| `mssql_backup_age_seconds` | `gauge` | `db`, `backup_type`, `recovery_model`, `is_read_only` | `age_seconds` | query_ref=`mssql_backup_age` | ثانیه‌های گذشته از آخرین backup بر اساس نوع. ‎-1 = هرگز backup نشده (یا log برای SIMPLE قابل‌استفاده نیست). ‎is_read_only=1 → سیاست Full ماهانه. |
| `mssql_backup_size_bytes` | `gauge` | `db`, `backup_type` | `backup_size_bytes` | query_ref=`mssql_backup_size` | اندازه آخرین backup بر حسب بایت برای هر نوع (0 در صورت نبود backup). |
| `mssql_backup_log_size_today_bytes` | `gauge` | `db` | `log_size_today_bytes` | query_ref=`mssql_backup_log_size_today` | جمع اندازه Log backupهای تمام‌شده در روز جاری (تقویم محلی سرور) برای هر دیتابیس. |
| `mssql_backup_damaged_7d` | `gauge` | `db`, `backup_type` | `damaged_count` | query_ref=`mssql_backup_damaged` | ردیف‌های آسیب‌دیده backupset (is_damaged=1) در ۷ روز گذشته بر اساس دیتابیس و نوع. |
| `mssql_backup_job_failed_24h` | `gauge` | `job_name`, `category_name` | `failed_count` | query_ref=`mssql_backup_job_failed` | نتیجه‌های ناموفق jobهای SQL Agent (۲۴ ساعت) برای jobهایی که مرحله BACKUP دارند. |
| `mssql_backup_job_failed_total_24h` | `gauge` | — | `failed_count` | query_ref=`mssql_backup_job_failed_total` | مجموع خروجی‌های ناموفق Agent مرتبط با backup در ۲۴ ساعت گذشته. |
| `mssql_backup_throughput_mb_s` | `gauge` | `db`, `backup_type` | `throughput_mb_s` | query_ref=`mssql_backup_recent_performance` | Throughput آخرین backup بر اساس نوع (MB/s). |
| `mssql_backup_compression_ratio` | `gauge` | `db`, `backup_type` | `compression_ratio` | query_ref=`mssql_backup_recent_performance` | backup_size / compressed_backup_size برای آخرین backup بر اساس نوع. |
| `mssql_backup_verify_failed_count` | `gauge` | — | `failed_count` | query_ref=`mssql_backup_verify_failed` | خروجی‌های ناموفق SQL Agent مرتبط با VERIFYONLY در ۲۴ ساعت گذشته. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
