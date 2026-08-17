# mssql_query_store

## خلاصه

- فایل: `collector/mssql_query_store.collector.yml`
- collector_name: `mssql_query_store`
- min_interval: `300s`
- تعداد metric: `11`
- query_refهای مشترک: `mssql_qs_enabled`, `mssql_qs_top`

## هدف و کاربرد

- وضعیت فعال بودن Query Store + top queryها از دیتابیس‌هایی که QS روشن است.
- شامل `last_execution_time` (unix + age) برای هر `query_id`.
- `GRANT VIEW SERVER STATE`
- Per-DB: `VIEW DATABASE STATE` / دسترسی به catalog viewهای Query Store

## مجوزها و پیش‌نیازها

- مجوز پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`.
- دسترسی خاص: دسترسی به دیتابیس‌های کاربری و Query Store.
- نکات فایل منبع:
  - GRANT VIEW SERVER STATE TO

## نحوه استفاده

- این collector را در profile متناسب با نوع سرور فعال کن.
- روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
- اگر metric جدیدی اضافه می‌کنی، قبل از rollout روی یک instance تست کن.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_query_store_enabled` | `gauge` | `db` | `enabled` | query_ref=`mssql_qs_enabled` | 1 اگر Query Store روی دیتابیس فعال باشد، وگرنه 0. |
| `mssql_query_store_top_duration_ms` | `gauge` | `db`, `query_id`, `object_name`, `query_snip` | `avg_duration_ms` | query_ref=`mssql_qs_top` | Top queryها بر اساس میانگین duration (ms). |
| `mssql_query_store_top_cpu_ms` | `gauge` | `db`, `query_id`, `object_name`, `query_snip` | `avg_cpu_ms` | query_ref=`mssql_qs_top` | Top queryها بر اساس میانگین CPU (ms). |
| `mssql_query_store_top_execution_count` | `gauge` | `db`, `query_id`, `object_name`, `query_snip` | `execution_count` | query_ref=`mssql_qs_top` | تعداد اجرا در پنجره اخیر QS. |
| `mssql_query_store_top_last_execution_unix` | `gauge` | `db`, `query_id`, `object_name`, `query_snip` | `last_execution_unix` | query_ref=`mssql_qs_top` | زمان Unix (UTC) آخرین اجرا (`last_execution_time`). |
| `mssql_query_store_top_last_execution_age_seconds` | `gauge` | `db`, `query_id`, `object_name`, `query_snip` | `last_execution_age_seconds` | query_ref=`mssql_qs_top` | ثانیه از آخرین اجرا تا اکنون. |

## نکات عملیاتی

- `min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
- اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
- collectorهایی که label زیاد تولید می‌کنند برای high-cardinality مناسب نیستند.
- اگر قابلیت روی instance نباشد، خروجی معمولاً خالی است و scrape نباید fail شود.
- پنجره top-query: ۶ ساعت آخر runtime stats؛ سقف سراسری ۴۰ ردیف.
