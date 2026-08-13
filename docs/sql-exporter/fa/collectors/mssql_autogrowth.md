# mssql_autogrowth

## خلاصه

- فایل: `collector/mssql_autogrowth.collector.yml`
- collector_name: `mssql_autogrowth`
- min_interval: `300s`
- تعداد metric: `8`
- query_refهای مشترک: `mssql_autogrowth_events`, `mssql_autogrowth_total`

## هدف

- رویدادهای autogrowth و shrink داده/لاگ از default trace (۲۴ ساعت اخیر).
- شامل تعداد رویداد، حجم MB رشد/جمع‌شدگی (صفحه × ۸KB)، میانگین/حداکثر مدت، و سن آخرین رویداد.
- اگر default trace غیرفعال باشد، خروجی خالی است.

## مجوزها و پیش‌نیازها

- مجوز پایه: `VIEW SERVER STATE`.
- نکته فایل منبع: `GRANT VIEW SERVER STATE TO`

## نحوه استفاده

- این collector را در profile متناسب با نوع سرور فعال کن.
- روی سرورهای شلوغ با `min_interval` بالاتر و احتیاط اجرا کن.
- داشبورد Grafana: `grafana/dashboards/sql-exporter/Collector/sqlx-autogrowth.json` (`sqlx-autogrowth`).
- برای تنظیمات رشد فایل (percent growth، اندازه increment، pct of max) با `mssql_database_space` جفت کن.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_autogrowth_events_24h` | `gauge` | `db`, `file_name`, `event_type` | `event_count` | تعداد رویداد autogrowth/shrink در ۲۴ساعت. |
| `mssql_autogrowth_growth_mb_24h` | `gauge` | `db`, `file_name`, `event_type` | `growth_mb` | مجموع MB رشد/shrink (صفحه×۸KB) در ۲۴ساعت. |
| `mssql_autogrowth_avg_duration_ms_24h` | `gauge` | `db`, `file_name`, `event_type` | `avg_duration_ms` | میانگین مدت (ms). |
| `mssql_autogrowth_max_duration_ms_24h` | `gauge` | `db`, `file_name`, `event_type` | `max_duration_ms` | حداکثر مدت (ms). |
| `mssql_autogrowth_last_age_seconds` | `gauge` | `db`, `file_name`, `event_type` | `age_seconds` | ثانیه از آخرین رویداد. |
| `mssql_autogrowth_total_24h` | `gauge` | — | `event_count` | مجموع autogrowth داده+لاگ (۹۲/۹۳). |
| `mssql_autogrowth_shrink_total_24h` | `gauge` | — | `shrink_count` | مجموع shrink داده+لاگ (۹۴/۹۵). |
| `mssql_autogrowth_growth_mb_total_24h` | `gauge` | — | `growth_mb` | مجموع MB از autogrowth داده+لاگ. |

### مقادیر event_type

| مقدار | EventClass | معنی |
|---|---|---|
| `data_growth` | 92 | رشد فایل داده |
| `log_growth` | 93 | رشد فایل لاگ |
| `data_shrink` | 94 | shrink فایل داده |
| `log_shrink` | 95 | shrink فایل لاگ |

## نکات عملیاتی

- `min_interval` جلوی اسکن مکرر `fn_trace_gettable` را می‌گیرد.
- تعداد بالای رویداد (به‌ویژه `log_growth`) معمولاً یعنی increment کوچک، percent growth، یا فشار log/VLF — ردیف Config Risks داشبورد را ببین.
- متریک‌های MB/duration بعد از reload exporter با YAML جدید ظاهر می‌شوند.
- اگر قابلیت روی instance نباشد، خروجی معمولاً خالی است و scrape نباید fail شود.
