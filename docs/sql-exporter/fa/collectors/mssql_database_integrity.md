# mssql_database_integrity

## خلاصه

- فایل: `collector/mssql_database_integrity.collector.yml`
- collector_name: `mssql_database_integrity`
- min_interval: `3600s`
- تعداد metric: `7`
- query_refهای مشترک: `mssql_checkdb_age`, `mssql_suspect_pages`, `mssql_suspect_pages_total`

## هدف و کاربرد

- سیگنال‌های سلامت دیتابیس: suspect pages (فساد صفحه) + سن/پوشش آخرین CHECKDB موفق.
- `GRANT VIEW SERVER STATE` و `GRANT SELECT ON msdb.dbo.suspect_pages`.
- سن CHECKDB از `DBCC DBINFO` می‌آید (نیاز به حق اجرای DBCC روی هر DB آنلاین).

## مجوزها و پیش‌نیازها

- مجوزهای پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`.
- دسترسی خاص: `suspect_pages` + `DBCC DBINFO` برای هر دیتابیس Online.
- دیتابیس‌های غیرقابل‌دسترسی رد می‌شوند؛ scrape نباید fail شود.

## نحوه استفاده

- این collector را در profile متناسب با نوع سرور فعال کن.
- فاصله جمع‌آوری عمداً یک‌ساعته است؛ در Grafana متغیر SLA (پیش‌فرض ۷ روز، هم‌راستا با آلرت `SqlDatabaseIntegrityAtRisk`) را تنظیم کن.
- اگر metric جدیدی اضافه می‌کنی، قبل از rollout روی یک instance تست کن.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_suspect_pages` | `gauge` | `db`, `event_type`, `event_type_desc` | `page_count` | تعداد ردیف‌های `suspect_pages` بر اساس دیتابیس و نوع رویداد. |
| `mssql_suspect_pages_error_count` | `gauge` | `db`, `event_type`, `event_type_desc` | `error_count` | جمع `error_count` (چند بار صفحه خراب دیده شده). |
| `mssql_suspect_pages_last_seen_age_seconds` | `gauge` | `db`, `event_type`, `event_type_desc` | `last_seen_age_seconds` | ثانیه از جدیدترین `last_update_date`. `-1` اگر نامشخص. |
| `mssql_suspect_pages_total` | `gauge` | — | `page_count` | مجموع ردیف‌های suspect_pages. |
| `mssql_checkdb_age_seconds` | `gauge` | `db` | `age_seconds` | ثانیه از `dbi_dbccLastKnownGood`. `-1` اگر هرگز / نامشخص. |
| `mssql_checkdb_last_good_timestamp` | `gauge` | `db` | `last_good_unix` | زمان Unix آخرین CHECKDB موفق. `0` اگر هرگز / نامشخص. |
| `mssql_checkdb_never_run` | `gauge` | `db` | `never_run` | `1` اگر CHECKDB ثبت نشده، وگرنه `0`. |

## نکات عملکرد

- `min_interval` جلوی اجرای مکرر حلقه سنگین `DBCC DBINFO` را می‌گیرد.
- انواع رویداد suspect: `1`=823/824، `2`=bad checksum، `3`=torn page، `4`=restored، `5`=repaired، `7`=deallocated.
- داشبورد Grafana: `grafana/dashboards/sql-exporter/Collector/sqlx-database-integrity.json`.
