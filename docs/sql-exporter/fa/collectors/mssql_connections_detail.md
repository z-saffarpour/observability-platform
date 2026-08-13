# mssql_connections_detail

## خلاصه

- فایل: `collector/mssql_connections_detail.collector.yml`
- collector_name: `mssql_connections_detail`
- min_interval: `60s`
- تعداد metric: `10`
- query_refهای مشترک: `mssql_sessions_by_db`, `mssql_sessions_by_host`, `mssql_sessions_by_login`, `mssql_sessions_by_program`, `mssql_sessions_by_status`, `mssql_sessions_idle_long`, `mssql_sessions_idle_bucket`, `mssql_sessions_open_tran`, `mssql_sessions_open_tran_total`

## هدف و کاربرد

- تفکیک اتصال‌های کلاینت — مشترک برای DWH و OLTP.
- نشان می‌دهد چه کسی نشست دارد (login/program/host/db)، نسبت running در برابر sleeping، تراکنش‌های باز، و sleepingهای طولانی‌idle (هدررفت connection pool).
- GRANT VIEW SERVER STATE TO

## مجوزها و پیش‌نیازها

- مجوزهای پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`.
- نکات موجود در فایل منبع:
  - GRANT VIEW SERVER STATE TO

## نحوه استفاده

- این collector را در profile متناسب با نوع سرور فعال کن.
- روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
- اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
- داشبورد Grafana: `sqlx-connections` (SQL Exporter - Connections).

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_sessions_by_status` | `gauge` | `status` | `session_count` | نشست‌های کاربر بر اساس status. |
| `mssql_sessions_by_login` | `gauge` | `login_name`, `status` | `session_count` | Top loginها بر اساس تعداد نشست. |
| `mssql_sessions_by_program` | `gauge` | `program_name`, `status` | `session_count` | Top programها بر اساس تعداد نشست. |
| `mssql_sessions_by_host` | `gauge` | `host_name`, `status` | `session_count` | Top hostهای کلاینت بر اساس تعداد نشست. |
| `mssql_sessions_by_db` | `gauge` | `db`, `status` | `session_count` | نشست‌ها بر اساس database. |
| `mssql_sessions_open_tran_total` | `gauge` | — | `session_count` | نشست‌هایی با `open_transaction_count > 0`. |
| `mssql_sessions_open_tran` | `gauge` | `login_name`, `db` | `session_count` | Top login/DB با تراکنش باز. |
| `mssql_sessions_idle_bucket` | `gauge` | `idle_bucket` | `session_count` | sleeping بر اساس سن idle (`lt_1m`, `1_5m`, `5_30m`, `30_60m`, `1_4h`, `gt_4h`). |
| `mssql_sessions_idle_long` | `gauge` | `login_name`, `program_name`, `host_name` | `session_count` | Top sleepingهایی که حداقل ۵ دقیقه idle هستند. |
| `mssql_sessions_idle_long_max_seconds` | `gauge` | `login_name`, `program_name`, `host_name` | `max_idle_seconds` | بیشینه ثانیه idle در همان گروه‌ها. |

## نکات عملکرد

- `min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
- اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
- collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
- **Sleeping** بالا همراه با **Idle ≥5m/1h** معمولاً نشانه نشتی connection pool است (جداول Top Logins / Long Idle).
- اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.
