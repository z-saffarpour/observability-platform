# mssql_alwayson_events

## خلاصه

- فایل: `collector/mssql_alwayson_events.collector.yml`
- نام collector: `mssql_alwayson_events`
- حداقل فاصله: `300s`
- تعداد metric: `1`
- query_ref: `mssql_alwayson_sync_state_flaps`
- پروفایل‌ها: `oltp`, `dwh`, `restore-secondary`, `replication` (کنار `mssql_alwayson`)

## هدف

- شمارش تغییر وضعیت replica از session پیش‌فرض Extended Events به نام `AlwaysOn_health`.
- جدا از `mssql_alwayson` (۳۰ثانیه) تا خواندن فایل‌های XEL با فاصله طولانی‌تر انجام شود.
- اگر AG وجود نداشته باشد خروجی خالی است.

## مجوزها و پیش‌نیازها

- `VIEW SERVER STATE`
- session با نام `AlwaysOn_health` و target از نوع `event_file` باید فعال باشد.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_alwayson_sync_state_flaps_24h` | `gauge` | `availability_group_name`, `replica_server`, `role_desc` | `sync_state_flaps_24h` | query_ref=`mssql_alwayson_sync_state_flaps` | تعداد رویداد `availability_replica_state_change` در ۲۴ ساعت. `-1` یعنی AlwaysOn_health در دسترس نیست. |

## نکات عملیاتی

- اگر flaps روی `-1` بماند، `AlwaysOn_health` را با `STARTUP_STATE = ON` فعال کنید.
- همراه با `mssql_alwayson` برای پوشش live + تاریخچه استفاده شود.
