# mssql_index_usage

## خلاصه

- فایل: `collector/mssql_index_usage.collector.yml`
- collector_name: `mssql_index_usage`
- min_interval: `300s`
- تعداد متریک: `19`
- query_refهای مشترک: `mssql_index_usage_hot`, `mssql_index_usage_stale`, `mssql_index_usage_db`

## هدف

- نمای عملیاتی مصرف ایندکس (نه fragmentation): ایندکس‌های داغ، نسبت scan/lookup/write، کاندیدهای unused یا write-heavy برای بررسی drop/disable، و رول‌آپ سطح دیتابیس.
- `dm_db_index_usage_stats` با ری‌استارت اینستنس، آفلاین شدن دیتابیس، یا recreate ایندکس ریست می‌شود.
- SSISDB / Distribution حذف شده‌اند تا لیست TOP را اشغال نکنند.
- GRANT VIEW SERVER STATE TO / دسترسی DB برای نام ایندکس

## دسترسی‌ها و پیش‌نیازها

- دسترسی پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`.
- دسترسی ویژه: دسترسی به دیتابیس‌های کاربر (برای نام از `sys.indexes`).
- یادداشت‌های فایل منبع:
  - GRANT VIEW SERVER STATE TO
  - VIEW ANY DEFINITION / DB access for index names

## نحوه استفاده

- این collector را در پروفایل مناسب نوع سرور فعال کنید.
- روی سرورهای شلوغ، collectorهای سنگین را با احتیاط و interval بلندتر اجرا کنید.
- اگر متریک جدید اضافه می‌کنید، اول روی یک اینستنس تست کنید.
- داشبورد Grafana با UID `sqlx-index-usage` برای triage عملیاتی: KPI → hotspots → hot inventory → stale candidates → DB rollup.

## متریک‌ها

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_index_usage_seeks` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `user_seeks` | query_ref=`mssql_index_usage_hot` | user_seeks for TOP hot indexes by total read activity. |
| `mssql_index_usage_scans` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `user_scans` | query_ref=`mssql_index_usage_hot` | user_scans for TOP hot indexes by total read activity. |
| `mssql_index_usage_lookups` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `user_lookups` | query_ref=`mssql_index_usage_hot` | user_lookups for TOP hot indexes by total read activity. |
| `mssql_index_usage_updates` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `user_updates` | query_ref=`mssql_index_usage_hot` | user_updates for TOP hot indexes by total read activity. |
| `mssql_index_usage_reads` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `user_reads` | query_ref=`mssql_index_usage_hot` | user_seeks+scans+lookups for TOP hot indexes. |
| `mssql_index_usage_scan_ratio` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `scan_ratio` | query_ref=`mssql_index_usage_hot` | user_scans / NULLIF(user_reads,0) for TOP hot indexes (scan-heavy signal). |
| `mssql_index_usage_lookup_ratio` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `lookup_ratio` | query_ref=`mssql_index_usage_hot` | user_lookups / NULLIF(user_reads,0) for TOP hot indexes (bookmark-lookup signal). |
| `mssql_index_usage_write_read_ratio` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc` | `write_read_ratio` | query_ref=`mssql_index_usage_hot` | user_updates / NULLIF(user_reads,0) for TOP hot indexes. |
| `mssql_index_usage_stale_updates` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc`, `candidate_kind` | `user_updates` | query_ref=`mssql_index_usage_stale` | user_updates for unused or write-heavy indexes (drop/disable review candidates). |
| `mssql_index_usage_stale_reads` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc`, `candidate_kind` | `user_reads` | query_ref=`mssql_index_usage_stale` | user_reads for unused or write-heavy indexes (drop/disable review candidates). |
| `mssql_index_usage_stale_write_read_ratio` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc`, `candidate_kind` | `write_read_ratio` | query_ref=`mssql_index_usage_stale` | updates/reads (reads=0 → updates) for unused or write-heavy indexes. |
| `mssql_index_usage_db_reads` | `gauge` | `db` | `user_reads` | query_ref=`mssql_index_usage_db` | Sum of user_seeks+scans+lookups across indexes with usage stats in the database. |
| `mssql_index_usage_db_updates` | `gauge` | `db` | `user_updates` | query_ref=`mssql_index_usage_db` | Sum of user_updates across indexes with usage stats in the database. |
| `mssql_index_usage_db_scans` | `gauge` | `db` | `user_scans` | query_ref=`mssql_index_usage_db` | Sum of user_scans across indexes with usage stats in the database. |
| `mssql_index_usage_db_seeks` | `gauge` | `db` | `user_seeks` | query_ref=`mssql_index_usage_db` | Sum of user_seeks across indexes with usage stats in the database. |
| `mssql_index_usage_db_lookups` | `gauge` | `db` | `user_lookups` | query_ref=`mssql_index_usage_db` | Sum of user_lookups across indexes with usage stats in the database. |
| `mssql_index_usage_db_tracked_indexes` | `gauge` | `db` | `tracked_indexes` | query_ref=`mssql_index_usage_db` | Count of non-MS-shipped indexes present in dm_db_index_usage_stats for the database. |
| `mssql_index_usage_db_unused_indexes` | `gauge` | `db` | `unused_indexes` | query_ref=`mssql_index_usage_db` | Count of nonclustered indexes with user_reads=0 and user_updates>0 (since last stats reset). |
| `mssql_index_usage_db_scan_ratio` | `gauge` | `db` | `scan_ratio` | query_ref=`mssql_index_usage_db` | db user_scans / NULLIF(user_reads,0) — database-level scan pressure. |

## نکات عملیاتی

- `min_interval` جلوی اجرای مکرر کوئری‌های سنگین را می‌گیرد.
- اگر collector از `query_ref` استفاده کند، چند متریک یک کوئری مشترک دارند.
- collector با لیبل زیاد برای cardinality بالا مناسب نیست (سقف TOP N اعمال شده).
- کاندیدهای stale، heap / clustered / PK / unique constraint را کنار می‌گذارند و `user_updates >= 1000` لازم است.
- اگر قابلیت روی اینستنس نباشد، خروجی معمولاً خالی است و scrape نباید fail شود.
