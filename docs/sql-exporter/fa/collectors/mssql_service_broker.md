# mssql_service_broker

- فایل: `collector/mssql_service_broker.collector.yml`
- نام collector: `mssql_service_broker`
- فاصله اجرا: `30s`
- تعداد metric: `65`
- پروفایل: `profiles/service-broker.yml`

این Collector فعال‌بودن و metadata سرویس بروکر، تنظیمات/backlog/activation صف‌ها، backlog ارسال (تجمیعی و به‌ازای سرویس مقصد)، conversation endpoint و lifetime، endpoint/transport، اتصال‌های شبکه، message forwarding، performance counterهای Activation/Statistics/Transport و انقضای certificate را پایش می‌کند. در سرورهایی که Service Broker ندارند نیز بدون خطا اجرا می‌شود (کوئری‌های DB/صف خطا را می‌گیرند؛ DMVهای اختیاری نتیجه خالی برمی‌گردانند).

## گروه‌های متریک

| گروه | نمونه |
| --- | --- |
| Database | `enabled`، `accessible`، `queues`، `services`، `honor_broker_priority`، `info{broker_guid}`، `routes`، `remote_bindings`، conversation groups / orphaned |
| Queue | فلگ‌های receive/enqueue/activation/retention/poison، `max_readers`، وجود activation procedure، messages، monitor state، tasks waiting، activated tasks، سن آخرین activation، سن قدیمی‌ترین پیام |
| Transmission | messages/errors/conversation errors/bytes/oldest age؛ تفکیک بر اساس `to_service` و `status_class` |
| Conversation | endpoint بر اساس `state` و `is_initiator`، حداقل lifetime باقی‌مانده |
| Endpoint | started، forwarding، اندازه forwarding، encryption، port |
| Connections | تعداد + flow control + counter بایت/fragment بر اساس connection/login state |
| Forwarding | تعداد in-flight، حداقل hops باقی‌مانده، حداکثر time consumed؛ pending/discarded از Broker Statistics |
| Perf counters | activation tasks/limit/aborts؛ enqueued/dequeued transmission؛ SQL SEND/RECEIVE؛ transport fragment send/receive |
| Certificates | روز تا انقضای certificateهای endpoint و دیتابیس‌های کاربری دارای private key |

## دسترسی‌ها

- `VIEW ANY DATABASE`
- دسترسی‌های `CONNECT` و `VIEW DATABASE STATE` روی دیتابیس‌های Service Broker
- `VIEW SERVER STATE` (SQL Server 2019 و قبل) یا `VIEW SERVER PERFORMANCE STATE` (SQL Server 2022 به بعد) برای DMVها و performance counterها
- در SQL Server 2022 به بعد در صورت نیاز: `VIEW DATABASE PERFORMANCE STATE`

اسکریپت `Create-SqlExporterLogin.sql` موجود در پروژه، در صورت فعال‌بودن دسترسی دیتابیس‌های کاربری، این مجوزها را اعطا می‌کند.

## Alertهای پیشنهادی

```promql
mssql_service_broker_enabled == 1 and mssql_service_broker_database_accessible == 0
mssql_service_broker_queue_receive_enabled == 0
mssql_service_broker_queue_oldest_message_age_seconds > 300
mssql_service_broker_transmission_errors > 0
mssql_service_broker_transmission_oldest_age_seconds > 300
mssql_service_broker_queue_messages > 1000
mssql_service_broker_conversation_endpoints{state=~"ERROR|DISCONNECTED_.*"} > 0
mssql_service_broker_endpoint_started == 0
mssql_service_broker_connection_send_flow_controlled > 0
or mssql_service_broker_connection_receive_flow_controlled > 0
increase(mssql_service_broker_activation_task_limit_reached_total[15m]) > 0
increase(mssql_service_broker_forwarded_discarded_total[15m]) > 0
mssql_service_broker_certificate_expiry_days < 30
```

آستانه backlog و سن پیام را متناسب با نرخ عادی پیام‌های برنامه تنظیم کنید. وقتی `queue_retention_enabled == 1` باشد، `queue_messages` ممکن است پیام‌های retained را هم شمارش کند.
