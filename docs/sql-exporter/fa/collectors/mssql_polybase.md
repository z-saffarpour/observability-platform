# mssql_polybase

## خلاصه

- فایل: `collector/mssql_polybase.collector.yml`
- نام Collector: `mssql_polybase`
- پروفایل: `polybase`
- Grafana: `/d/sqlx-polybase/collector-polybase`
- حداقل فاصله اجرا: `30s`
- تعداد Metric: `39`

## کاربرد

این Collector نصب و فعال‌بودن PolyBase، Inventory و منابع Compute Nodeها،
سلامت سرویس DMS و Workerهای آن، Distributed Request و Stepها، مراحل SQL
توزیع‌شده، External Worker و Operationها، تعداد Objectهای کاتالوگ
(External Table / Data Source / File Format) و خطاهای ۱۵ دقیقه اخیر Compute
Node را پایش می‌کند. Labelها در سطح Node، Status، Type یا Database تجمیع
شده‌اند تا Cardinality کنترل شود. روی سروری که PolyBase یا Object مربوطه وجود
ندارد، Queryهای اختیاری خروجی خالی می‌دهند و Metricهای نصب و فعال‌بودن همچنان
منتشر می‌شوند.

## دسترسی لازم

```sql
GRANT VIEW SERVER STATE TO [monitoring_user];
```

برای SQL Server 2022 و جدیدتر:

```sql
GRANT VIEW SERVER PERFORMANCE STATE TO [monitoring_user];
```

Metricهای کاتالوگ به CONNECT و Visibility متادیتا روی دیتابیس‌هایی که External
Table / Data Source / File Format دارند هم نیاز دارند.

## Ruleهای پیشنهادی

```promql
mssql_polybase_installed == 1 and mssql_polybase_enabled == 0
mssql_polybase_node_available == 0
mssql_polybase_node_received_age_seconds > 120
mssql_polybase_node_memory_used_ratio > 0.9
mssql_polybase_node_errors_recent > 0
mssql_polybase_requests{status=~"Failed|Cancelled"} > 0
mssql_polybase_request_max_start_age_seconds{status="Running"} > 3600
mssql_polybase_dms_services{status!~"(?i)ready|running|online|active"} > 0
mssql_polybase_dms_workers{status="Failed"} > 0
mssql_polybase_external_workers{status="Failed"} > 0
mssql_polybase_request_steps{status="Failed"} > 0
mssql_polybase_sql_steps{status="Failed"} > 0
```

Counterهای CPU با Restart شدن Process مربوط به PolyBase یا سرویس SQL Server
Reset می‌شوند. Metric تجمیعی خطا یک Gauge با پنجره متحرک ۱۵ دقیقه‌ای است.
متریک `mssql_polybase_node_error_age_seconds` تا ۵۰ خطای ۶۰ دقیقه اخیر را با
متن کامل `details` (تا ۴۰۰۰ کاراکتر) به‌همراه `error_id`، `execution_id` و
`spid` برای همبستگی در SSMS نشان می‌دهد. متریک‌های inventory هر External
Table / Data Source / File Format را به‌صورت جدا فهرست می‌کنند. Gaugeهای
byte/row مربوط به DMS و External Worker وضعیت فعلی ردیف‌های DMV هستند، نه
Counter مادام‌العمر.
