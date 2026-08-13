# mssql_plan_cache

دسترسی خاص:

- فایل: `collector/mssql_plan_cache.collector.yml`
- collector_name: `mssql_plan_cache`
- min_interval: `120s`
- تعداد metric: `13`
- query_refهای مشترک: `mssql_plan_cache_by_type`, `mssql_plan_cache_totals`, `mssql_plan_cache_by_db`

هدف و کاربرد

- Plan cache size, object-type breakdown, single-use plan pressure, and per-database context rollup.
- GRANT VIEW SERVER STATE TO

نکات عملیاتی

مجوزها و پیش‌نیازها
نکات موجود در فایل منبع:
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
| `mssql_plan_cache_size_mb` | `gauge` | `objtype` | `size_mb` | query_ref=`mssql_plan_cache_by_type` | Plan cache size (MB) by objtype. |
| `mssql_plan_cache_plan_count` | `gauge` | `objtype` | `plan_count` | query_ref=`mssql_plan_cache_by_type` | Cached plan count by objtype. |
| `mssql_plan_cache_single_use_count` | `gauge` | `objtype` | `single_use_count` | query_ref=`mssql_plan_cache_by_type` | Plans with usecounts = 1 by objtype (ad-hoc pollution signal). |
| `mssql_plan_cache_total_size_mb` | `gauge` | — | `size_mb` | query_ref=`mssql_plan_cache_totals` | Total plan cache size (MB). |
| `mssql_plan_cache_total_plans` | `gauge` | — | `plan_count` | query_ref=`mssql_plan_cache_totals` | Total cached plans. |
| `mssql_plan_cache_single_use_ratio` | `gauge` | — | `single_use_ratio` | query_ref=`mssql_plan_cache_totals` | Fraction of cached plans with usecounts = 1 (0..1). |
| `mssql_plan_cache_use_counts_sum` | `gauge` | — | `use_counts_sum` | query_ref=`mssql_plan_cache_totals` | Sum of usecounts across all cached plans. |
| `mssql_plan_cache_db_size_mb` | `gauge` | `db` | `size_mb` | query_ref=`mssql_plan_cache_by_db` | Plan cache size (MB) by database context. |
| `mssql_plan_cache_db_plan_count` | `gauge` | `db` | `plan_count` | query_ref=`mssql_plan_cache_by_db` | Cached plan count by database context. |
| `mssql_plan_cache_db_single_use_count` | `gauge` | `db` | `single_use_count` | query_ref=`mssql_plan_cache_by_db` | Single-use cached plans by database context. |
| `mssql_plan_cache_db_single_use_ratio` | `gauge` | `db` | `single_use_ratio` | query_ref=`mssql_plan_cache_by_db` | Fraction of cached plans with usecounts = 1 by database context (0..1). |
| `mssql_plan_cache_db_adhoc_size_mb` | `gauge` | `db` | `adhoc_size_mb` | query_ref=`mssql_plan_cache_by_db` | Adhoc plan cache size (MB) by database context. |
| `mssql_plan_cache_db_adhoc_single_use_ratio` | `gauge` | `db` | `adhoc_single_use_ratio` | query_ref=`mssql_plan_cache_by_db` | Fraction of adhoc cached plans with usecounts = 1 by database context (0..1). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
