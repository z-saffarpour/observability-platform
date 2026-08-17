# mssql_database_space

دسترسی خاص:

- فایل: `collector/mssql_database_space.collector.yml`
- collector_name: `mssql_database_space`
- min_interval: `300s`
- تعداد metric: `10`
- query_refهای مشترک: `mssql_database_space_capacity`, `mssql_database_space_used`, `mssql_database_vlf`

هدف و کاربرد

- Database file capacity, free space, autogrowth, and VLF count.
- GRANT VIEW SERVER STATE TO
- GRANT VIEW ANY DEFINITION TO
- Databases must be ONLINE with HAS_DBACCESS for used/free (FILEPROPERTY).

نکات عملیاتی

مجوزها و پیش‌نیازها
- Special access: Access to user databases.
نکات موجود در فایل منبع:
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
| `mssql_database_space_size_mb` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `size_mb` | query_ref=`mssql_database_space_capacity` | Database file size (MB) from sys.master_files. |
| `mssql_database_space_max_size_mb` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `max_size_mb` | query_ref=`mssql_database_space_capacity` | Database file max_size (MB). -1 means unlimited. |
| `mssql_database_space_growth_mb` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `growth_mb` | query_ref=`mssql_database_space_capacity` | Autogrowth increment in MB when growth is fixed-size; 0 if percent growth. |
| `mssql_database_space_growth_percent` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `growth_percent` | query_ref=`mssql_database_space_capacity` | Autogrowth percent when is_percent_growth=1; else 0. |
| `mssql_database_space_is_percent_growth` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `is_percent_growth` | query_ref=`mssql_database_space_capacity` | 1 if file grows by percent, else 0. |
| `mssql_database_space_pct_of_max` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc`, `physical_name` | `pct_of_max` | query_ref=`mssql_database_space_capacity` | size as percent of max_size. -1 if unlimited max_size. |
| `mssql_database_space_used_mb` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc` | `used_mb` | query_ref=`mssql_database_space_used` | Used space (MB) via FILEPROPERTY SpaceUsed (ONLINE DBs with access). |
| `mssql_database_space_free_mb` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc` | `free_mb` | query_ref=`mssql_database_space_used` | Free space (MB) = size - SpaceUsed (ONLINE DBs with access). |
| `mssql_database_space_used_percent` | `gauge` | `db`, `file_id`, `logical_name`, `type_desc` | `used_percent` | query_ref=`mssql_database_space_used` | Used percent of file size (ONLINE DBs with access). |
| `mssql_database_vlf_count` | `gauge` | `db` | `vlf_count` | query_ref=`mssql_database_vlf` | Virtual log file count per database (sys.dm_db_log_info). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
