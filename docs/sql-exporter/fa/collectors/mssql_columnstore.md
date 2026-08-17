# mssql_columnstore

## Summary

- فایل: `collector/mssql_columnstore.collector.yml`
- collector_name: `mssql_columnstore`
- min_interval: `300s`
- تعداد متریک: `12`
- query_refهای مشترک: `mssql_columnstore_rowgroups`, `mssql_columnstore_health`, `mssql_columnstore_top_objects`
- پروفایل: `profiles/dwh.yml`

## Purpose

- سلامت rowgroupهای columnstore برای هاست‌های DWH / BI.
- تشخیص backlog تورپل‌موور (`OPEN` / `CLOSED`)، bloated بودن COMPRESSED، rowgroupهای کوچک، و اهداف REORGANIZE.
- اگر columnstore نباشد نتیجه خالی است.

## Permissions and prerequisites

- دسترسی پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`.
- دسترسی به دیتابیس‌های کاربری که columnstore دارند.
- یادداشت از فایل منبع:
  - GRANT VIEW SERVER STATE TO

## How to use

- این collector را در پروفایل DWH (`dwh.yml`) یا هر سروری که واقعاً columnstore دارد فعال کنید.
- داشبورد Grafana: `grafana/dashboards/sql-exporter/Collector/sqlx-columnstore.json` (`sqlx-columnstore`).
- آلرت `SqlColumnstoreDeletedRowsHigh` وقتی `mssql_columnstore_deleted_ratio > 0.2` برای ۳۰ دقیقه باشد.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_columnstore_rowgroups` | `gauge` | `db`, `state_desc` | `rowgroup_count` | query_ref=`mssql_columnstore_rowgroups` | تعداد rowgroup بر اساس state. |
| `mssql_columnstore_total_rows` | `gauge` | `db`, `state_desc` | `total_rows` | query_ref=`mssql_columnstore_rowgroups` | مجموع ردیف‌ها بر اساس state. |
| `mssql_columnstore_deleted_rows` | `gauge` | `db`, `state_desc` | `deleted_rows` | query_ref=`mssql_columnstore_rowgroups` | ردیف‌های حذف‌شده (سیگنال bloat در COMPRESSED). |
| `mssql_columnstore_size_mb` | `gauge` | `db`, `state_desc` | `size_mb` | query_ref=`mssql_columnstore_rowgroups` | حجم rowgroup (MB) بر اساس state. |
| `mssql_columnstore_deleted_ratio` | `gauge` | `db` | `deleted_ratio` | query_ref=`mssql_columnstore_health` | نسبت deleted در COMPRESSED برای هر DB. |
| `mssql_columnstore_avg_rows_per_rg` | `gauge` | `db` | `avg_rows_per_rg` | query_ref=`mssql_columnstore_health` | میانگین ردیف در هر COMPRESSED RG (ایده‌آل ~۱٬۰۴۸٬۵۷۶). |
| `mssql_columnstore_underfilled_rg` | `gauge` | `db` | `underfilled_rg` | query_ref=`mssql_columnstore_health` | تعداد COMPRESSED با total_rows < ۱۰۰۰۰۰. |
| `mssql_columnstore_object_deleted_ratio` | `gauge` | `db`, `schema_name`, `table_name`, `index_name` | `deleted_ratio` | query_ref=`mssql_columnstore_top_objects` | اشیای پرتراکم بر اساس نسبت deleted. |
| `mssql_columnstore_object_deleted_rows` | `gauge` | `db`, `schema_name`, `table_name`, `index_name` | `deleted_rows` | query_ref=`mssql_columnstore_top_objects` | تعداد deleted برای اشیای پرتراکم. |
| `mssql_columnstore_object_total_rows` | `gauge` | `db`, `schema_name`, `table_name`, `index_name` | `total_rows` | query_ref=`mssql_columnstore_top_objects` | تعداد کل ردیف برای اشیای پرتراکم. |
| `mssql_columnstore_object_rowgroups` | `gauge` | `db`, `schema_name`, `table_name`, `index_name` | `rowgroup_count` | query_ref=`mssql_columnstore_top_objects` | تعداد COMPRESSED RG برای اشیای پرتراکم. |
| `mssql_columnstore_object_size_mb` | `gauge` | `db`, `schema_name`, `table_name`, `index_name` | `size_mb` | query_ref=`mssql_columnstore_top_objects` | حجم COMPRESSED (MB) برای اشیای پرتراکم. |

## Operational notes

- `min_interval` جلوی اجرای مکرر کوئری‌های سنگین را می‌گیرد.
- کوئری اشیاء حداکثر ۱۵ ایندکس در هر دیتابیس با `deleted_rows > 0` برمی‌گرداند.
- اگر فیچر روی instance نباشد خروجی معمولاً خالی است و scrape نباید fail شود.
- بخش‌های داشبورد: KPI → روند backlog/bloat → inventory هر DB → کاندیدهای REORGANIZE.
