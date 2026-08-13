# mssql_waits

دسترسی خاص:

**فایل:** `collector/mssql_waits.collector.yml`
- نام collector: `mssql_waits`
- حداقل فاصله اجرا: `120s`
- تعداد metric: `10`
- query_refهای مشترک: `mssql_wait_stats`, `mssql_waits_by_class`, `mssql_waits_summary`

## هدف و کاربرد

- متریک‌های wait stats برای Microsoft SQL Server.
- لازم است کاربر SQL Server مجوزهای زیر را داشته باشد:
- GRANT VIEW SERVER STATE TO
- به‌صورت خودکار از طریق collectors: [mssql_*] و collector_files: ["collector/*.collector.yml"] بارگذاری می‌شود

## مجوزها و پیش‌نیازها
- نکات موجود در فایل منبع:
  - لازم است کاربر SQL Server مجوزهای زیر را داشته باشد:
  - GRANT VIEW SERVER STATE TO

مجوزهای پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_wait_time_ms` | `gauge` | `wait_type` | `wait_time_ms` | query_ref=`mssql_wait_stats` | زمان تجمعی wait (ms) برای wait typeهای برتر (با فیلتر waitهای benign). |
| `mssql_wait_waiting_tasks` | `gauge` | `wait_type` | `waiting_tasks_count` | query_ref=`mssql_wait_stats` | تعداد تجمعی waiting task برای wait typeهای برتر. |
| `mssql_wait_signal_time_ms` | `gauge` | `wait_type` | `signal_wait_time_ms` | query_ref=`mssql_wait_stats` | زمان تجمعی signal wait (ms) برای wait typeهای برتر. |
| `mssql_wait_resource_time_ms` | `gauge` | `wait_type` | `resource_wait_time_ms` | query_ref=`mssql_wait_stats` | زمان تجمعی resource wait (ms) = wait_time - signal_wait برای wait typeهای برتر. |
| `mssql_wait_max_time_ms` | `gauge` | `wait_type` | `max_wait_time_ms` | query_ref=`mssql_wait_stats` | بیشینه wait time (ms) مشاهده‌شده برای wait typeهای برتر. |
| `mssql_waits_nonbenign_percent` | `gauge` | — | `nonbenign_percent` | query_ref=`mssql_waits_summary` | درصدی از wait time تجمعی که non-benign است. |
| `mssql_waits_top5_share_percent` | `gauge` | — | `top5_share_percent` | query_ref=`mssql_waits_summary` | سهم top 5 wait در wait time non-benign. |
| `mssql_waits_signal_ratio_percent` | `gauge` | — | `signal_ratio_percent` | query_ref=`mssql_waits_summary` | درصد نسبت signal wait به wait time non-benign. |
| `mssql_waits_by_class_time_ms` | `gauge` | `wait_class` | `wait_time_ms` | query_ref=`mssql_waits_by_class` | زمان تجمعی wait (ms) گروه‌بندی‌شده بر اساس wait class. |
| `mssql_waits_by_class_tasks` | `gauge` | `wait_class` | `waiting_tasks_count` | query_ref=`mssql_waits_by_class` | تعداد تجمعی waiting task گروه‌بندی‌شده بر اساس wait class. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
