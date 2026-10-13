# mssql_deadlock_details

## خلاصه

- فایل: `collector/mssql_deadlock_details.collector.yml`
- collector_name: `mssql_deadlock_details`
- min_interval: `60s`
- تعداد متریک: `2`
- query_ref مشترک: `mssql_deadlock_pairs`

## هدف

- جفت‌های اخیر Deadlock (قربانی ↔ طرف مقابل) از ring buffer نشست `system_health` (`xml_deadlock_report`).
- مکمل شمارندهٔ سطح instance یعنی `mssql_deadlocks` در `mssql_standard` با labelهای تشخیصی (spid/login/host/program/db/statement_snip/`process_count`).
- بافر به‌صورت متن جستجو می‌شود و فقط پنج تکهٔ آخر به XML تبدیل می‌شود تا scrape روی instanceهای شلوغ از مهلت خارج نشود.

## مجوزها و پیش‌نیازها

- مجوز پایه: `VIEW SERVER STATE`.
- نکات فایل منبع:
  - `GRANT VIEW SERVER STATE TO`
- نشست پیش‌فرض Extended Events با نام `system_health` و target از نوع `ring_buffer` لازم است.
- Portal / refresh-data متریک `mssql_deadlock_pair_info` را از Prometheus می‌خواند (بدون SQL مستقیم).

## نحوه استفاده

- این collector را در profile متناسب با نوع سرور (OLTP / DWH / alert) فعال کنید.
- برای حجم از `rate(mssql_deadlocks[5m])` یا `increase(mssql_deadlocks[1h])` استفاده کنید؛ این متریک‌ها برای آخرین جفت‌ها هستند.
- فیلتر `victim_db` / `other_db` را در PromQL یا داشبورد بگذارید. دیتابیس‌های ReadOnly را در scrape حذف نکنید (Deadlock می‌تواند بین RO و writable باشد).
- `process_count` یک label است (اندازهٔ گراف). طول `statement_snip` حداکثر ۱۲۰ کاراکتر است (مشابه `mssql_blocking` / `mssql_locks`).

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_deadlock_pair_info` | `gauge` | `event_time`, `victim_spid`, `victim_login`, `victim_host`, `victim_program`, `victim_db`, `victim_statement_snip`, `other_spid`, `other_login`, `other_host`, `other_program`, `other_db`, `other_statement_snip`, `process_count` | `static_value=1` | query_ref=`mssql_deadlock_pairs` | مقدار ۱ برای یک جفت اخیر xml_deadlock_report از system_health. |
| `mssql_deadlock_pair_age_seconds` | `gauge` | `event_time`, `victim_spid`, `victim_login`, `victim_host`, `victim_program`, `victim_db`, `victim_statement_snip`, `other_spid`, `other_login`, `other_host`, `other_program`, `other_db`, `other_statement_snip`, `process_count` | `age_seconds` | query_ref=`mssql_deadlock_pairs` | ثانیه از زمان گزارش (UTC)؛ در صورت نامشخص `-1`. |

## نکات عملیاتی

- `min_interval` جلوی اجرای مکرر query سنگین را می‌گیرد.
- هر دو متریک از یک `query_ref` (`mssql_deadlock_pairs`) تغذیه می‌شوند.
- تعداد زیاد label (از جمله statement و `event_time` و `process_count`) یعنی cardinality بالاتر؛ کران TOP(5) را حفظ کنید و seriesهای بلااستفاده را طولانی نگه ندارید.
- اگر `system_health` یا ring_buffer موجود نباشد، خروجی خالی است و scrape نباید fail شود.
- اگر بیش از دو process در گراف باشد، labelها یک قربانی و یک طرف غیرقربانی را نشان می‌دهند؛ `process_count` همچنان اندازهٔ کامل گراف است.
