# mssql_cpu

دسترسی خاص:

- فایل: `collector/mssql_cpu.collector.yml`
- collector_name: `mssql_cpu`
- min_interval: `30s`
- تعداد metric: `4`
- query_refهای مشترک: `mssql_cpu_ring_buffer`, `mssql_cpu_signal_waits`

هدف و کاربرد

- SQL Server process CPU vs system idle / other — from ring buffer.
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
| `mssql_cpu_sqlserver_process_percent` | `gauge` | — | `sqlserver_process_cpu` | query_ref=`mssql_cpu_ring_buffer` | SQL Server process CPU percent (ring buffer). |
| `mssql_cpu_system_idle_percent` | `gauge` | — | `system_idle_cpu` | query_ref=`mssql_cpu_ring_buffer` | System idle CPU percent (ring buffer). |
| `mssql_cpu_other_process_percent` | `gauge` | — | `other_process_cpu` | query_ref=`mssql_cpu_ring_buffer` | Other process CPU percent (ring buffer). |
| `mssql_cpu_signal_wait_percent` | `gauge` | — | `signal_wait_percent` | query_ref=`mssql_cpu_signal_waits` | Signal wait percent of total waits (CPU pressure indicator). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
