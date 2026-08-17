# mssql_stats

دسترسی خاص:

- فایل: `collector/mssql_stats.collector.yml`
- collector_name: `mssql_stats`
- min_interval: `600s`
- تعداد metric: `6`
- query_refهای مشترک: `mssql_stats_stale`, `mssql_stats_stale_count`

هدف و کاربرد

- Stale / heavily modified statistics (TOP N across online user databases).
- لازم است کاربر SQL Server مجوزهای زیر را داشته باشد:
- GRANT VIEW SERVER STATE TO
- Access to user databases required
- به‌صورت خودکار از طریق collectors: [mssql_*] and collector_files: ["collector/*.collector.yml"]

نکات عملیاتی

مجوزها و پیش‌نیازها
- Special access: Access to user databases.
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
| `mssql_stats_age_seconds` | `gauge` | `db`, `schema_name`, `table_name`, `stats_name` | `age_seconds` | query_ref=`mssql_stats_stale` | TOP statistics by age (seconds since last update). |
| `mssql_stats_modification_counter` | `gauge` | `db`, `schema_name`, `table_name`, `stats_name` | `modification_counter` | query_ref=`mssql_stats_stale` | modification_counter for TOP stale/changed statistics. |
| `mssql_stats_rows` | `gauge` | `db`, `schema_name`, `table_name`, `stats_name` | `rows` | query_ref=`mssql_stats_stale` | Row count snapshot for TOP stale/changed statistics. |
| `mssql_stats_rows_sampled` | `gauge` | `db`, `schema_name`, `table_name`, `stats_name` | `rows_sampled` | query_ref=`mssql_stats_stale` | rows_sampled for TOP stale/changed statistics. |
| `mssql_stats_sample_percent` | `gauge` | `db`, `schema_name`, `table_name`, `stats_name` | `sample_percent` | query_ref=`mssql_stats_stale` | Sample percent (rows_sampled/rows*100) for TOP stale/changed statistics. |
| `mssql_stats_stale_count` | `gauge` | `db` | `stale_count` | query_ref=`mssql_stats_stale_count` | Count of stale/heavily-modified statistics per database (matching collector thresholds). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
