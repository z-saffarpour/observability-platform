# mssql_index_fragmentation

دسترسی خاص:

- فایل: `collector/mssql_index_fragmentation.collector.yml`
- collector_name: `mssql_index_fragmentation`
- min_interval: `21600s`
- تعداد metric: `2`
- query_refهای مشترک: `mssql_index_fragmentation_top`

هدف و کاربرد

- Index fragmentation sample (LIMITED) — EXPENSIVE. Run rarely.
- Prefer off-hours; do not enable on every busy OLTP host without need.
- GRANT VIEW SERVER STATE TO
- GRANT VIEW ANY DEFINITION TO

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
| `mssql_index_fragmentation_percent` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc`, `alloc_unit_type_desc` | `avg_fragmentation_percent` | query_ref=`mssql_index_fragmentation_top` | Avg fragmentation percent (LIMITED mode) for large indexes above threshold. |
| `mssql_index_fragmentation_page_count` | `gauge` | `db`, `schema_name`, `table_name`, `index_name`, `index_type_desc`, `alloc_unit_type_desc` | `page_count` | query_ref=`mssql_index_fragmentation_top` | Page count for fragmented indexes reported by this collector. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
