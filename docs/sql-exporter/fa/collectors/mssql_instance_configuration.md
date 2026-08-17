# mssql_instance_configuration

## خلاصه

- فایل: `collector/mssql_instance_configuration.collector.yml`
- نام collector: `mssql_instance_configuration`
- حداقل فاصله: `300s`
- تعداد metric: `7`
- query_ref: `mssql_instance_config`, `mssql_instance_ifi`, `mssql_instance_uptime`, `mssql_instance_trace_flags`
- پروفایل‌ها: تمام پروفایل‌های نقش (پایه core)

## هدف

تنظیمات سطح instance برای تشخیص drift بین نودهای AG / FCI:

- گزینه‌های منتخب `sys.configurations` (`value` در برابر `value_in_use`)
- Instant File Initialization برای سرویس Database Engine
- زمان شروع / uptime اینستنس
- Trace Flagهای Global

تنظیمات per-database در `mssql_database_configuration` می‌ماند. گزینه‌های
surface-area مثل `xp_cmdshell` در `mssql_security` می‌ماند. داشبورد parallelism
ممکن است همچنان MAXDOP / حافظه را از `mssql_parallelism_configuration` بخواند؛
منبع حقیقت برای configured در برابر in-use و IFI همین collector است.

## مجوزها و پیش‌نیازها

- `VIEW SERVER STATE`
- Trace Flagهای Global نیاز به اجرای `DBCC TRACESTATUS(-1)` دارند؛ در صورت خطا
  متریک خالی است و scrape fail نمی‌شود.
- IFI از ستون `instant_file_initialization_enabled` در `sys.dm_server_services`
  می‌آید (SQL Server 2016+). نسخه‌های قدیمی `-1` برمی‌گردانند.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_instance_config_value` | `gauge` | `config_name` | `configured` | مقدار تنظیم‌شده `sys.configurations.value`. |
| `mssql_instance_config_value_in_use` | `gauge` | `config_name` | `in_use` | مقدار مؤثر `value_in_use`. |
| `mssql_instance_config_restart_pending` | `gauge` | `config_name` | `restart_pending` | `1` وقتی configured با in-use فرق دارد. |
| `mssql_instance_ifi_enabled` | `gauge` | `service_name` | `ifi_enabled` | `1` فعال، `0` غیرفعال، `-1` در دسترس نیست. |
| `mssql_instance_start_unix` | `gauge` | — | `start_unix` | زمان شروع SQL Server (Unix UTC). |
| `mssql_instance_uptime_seconds` | `gauge` | — | `uptime_seconds` | ثانیه از `sqlserver_start_time`. |
| `mssql_instance_trace_flag` | `gauge` | `trace_flag` | `is_enabled` | Trace Flagهای فعال در سطح Global. |

`config_name`های منتخب شامل max/min server memory، MAXDOP، cost threshold،
optimize for ad hoc، backup compression/checksum، remote admin connections،
Database Mail XPs، Agent XPs، Ad Hoc Distributed Queries، blocked process
threshold، default trace، lightweight pooling، fill factor، max worker threads،
remote query timeout، user connections، contained database authentication،
priority boost، network packet size و scan for startup procs است.

## نکات عملیاتی

- بعد از تغییر تنظیم که اعمال نشده، روی `mssql_instance_config_restart_pending == 1` آلرت بگذارید.
- `mssql_instance_config_value_in_use` را بین replicaهای AG مقایسه کنید تا drift حافظه / MAXDOP / ad-hoc دیده شود.
- `mssql_instance_ifi_enabled == 0` یعنی رشد فایل داده و restore ممکن است روی zero-initialization معطل شود.

## Grafana

- داشبورد: `grafana/dashboards/sql-exporter/Collector/sqlx-instance-configuration.json`
