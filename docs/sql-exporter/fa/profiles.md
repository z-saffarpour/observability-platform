# پروفایل‌های SQL Exporter

[English version](../en/profiles.md)

هر فایل در پوشه `profiles/` شامل فهرست کامل `target.collectors` برای یکی از نقش‌های سرور است.
SQL Exporter فایل‌های پروفایل را با یکدیگر ترکیب نمی‌کند و قابلیت inheritance
ندارد؛ به همین دلیل Collectorهای پایه عمداً در پروفایل‌های تخصصی تکرار شده‌اند.

## پروفایل‌ها

| پروفایل | کاربرد |
|---|---|
| `core.yml` | مانیتورینگ پایه برای تمام Instanceهای SQL Server (شامل drift تنظیمات instance) |
| `oltp.yml` | بارهای تراکنشی، عیب‌یابی Query فعال، Always On/HADR، Query Store |
| `dwh.yml` | Data Warehouse و BI، پردازش Columnstore و بارهای Parallel |
| `ssis.yml` | سرورهای اختصاصی SSIS Catalog |
| `polybase.yml` | Instanceهایی با PolyBase نصب‌شده یا Query روی داده خارجی |
| `replication.yml` | سرورهای Publisher، Distributor یا Subscriber (شامل AG/HADR + CDC) |
| `service-broker.yml` | سرورهای Service Broker (صف، transmission، activation، transport) |
| `restore-secondary.yml` | Instanceهای ثانویه Restore یا Backup Sync (restore، log shipping، AG/HADR) |
| `security-audit.yml` | وضعیت امنیت، Audit، سیگنال‌های Error Log و certificates (بدون perf-detail سنگین) |
| `alert-p0.yml` | حداقل Collector برای Alertهای P0 (Critical) |
| `alert-p1.yml` | Collectorهای P0 + P1 |
| `alert-p2.yml` | Collectorهای P0 + P1 + P2 (بدون بسته‌های نقش) |

## نحوه استفاده

### اسکریپت‌ها (پیشنهادی)

همان سبک پارامتر Windows Exporter (`-Profile sql-server.yml`):

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 -Computers SQL01 -Profile oltp.yml
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 -Computers SQL01 -Profile oltp.yml
.\scripts\powershell\sql-exporter\Deploy-SqlExporterConfig.ps1  -Computers SQL01 -Profile oltp.yml

# حداقل متریک برای Alertهای اولویت‌دار (جزئیات: alerting.md)
.\scripts\powershell\sql-exporter\Deploy-SqlExporterConfig.ps1 -Computers SQL01 -Profile alert-p1.yml
```

اسکریپت‌ها پوشه `profiles/` را به مسیر نصب کپی می‌کنند و فهرست `collectors:`
پروفایل انتخابی را داخل `sql_exporter.yml` می‌نویسند.

### دستی

بلوک کامل `collectors:` را از پروفایل انتخابی کپی کرده و جایگزین
`target.collectors` در فایل `sql_exporter.yml` کنید. خط زیر را تغییر ندهید تا
تعریف تمام Collectorها همچنان قابل بارگذاری باشد:

```yaml
collector_files:
  - "collector/*.collector.yml"
```

برای هر Instance از exporter یک پروفایل نقش استفاده کنید. اگر یک Instance چند
نقش دارد، نزدیک‌ترین پروفایل را انتخاب کرده و فقط Collector تخصصی موردنیاز،
مانند `mssql_replication`، `mssql_ssis`، `mssql_polybase` یا `mssql_service_broker`، را به آن اضافه کنید.

پروفایل `security-audit` ممکن است برای خواندن SQL Audit، فایل ERRORLOG و
Metadata امنیتی سرور به دسترسی بالاتری نیاز داشته باشد. **قبل از آلرت روی
`mssql_unexpected_login_count`، allow-list داخل
`collector/mssql_security.collector.yml` (query `mssql_security_unexpected_logins`)
را تنظیم کن**؛ جزئیات در
[mssql_security.md](collectors/mssql_security.md#allow-list-برای-mssql_unexpected_login_count).
Collector
`database_integrity` نیز `DBCC DBINFO` را روی دیتابیس‌های Online و قابل‌دسترسی
اجرا می‌کند.

پروفایل‌های `alert-p0.yml`، `alert-p1.yml` و `alert-p2.yml` حداقل Collector لازم برای
ارزیابی Alertهای P0/P1/P2 را فراهم می‌کنند. بلوک‌های `rule_files` در
`prometheus/scrape-configs/sql-exporter/` هستند. جزئیات در [alerting.md](alerting.md).

## Timeout برای Collectorهای سنگین

نسخه 0.24.4 نرم‌افزار SQL Exporter، گزینه `scrape_timeout` را فقط در سطح
Global پشتیبانی می‌کند و برای هر Collector به‌صورت مستقل قابل تنظیم نیست.
تنظیمات این مخزن حداکثر ۵۵ ثانیه برای یک Collection زمان در نظر می‌گیرد.
برای Job متناظر در Prometheus نیز timeout کمی بزرگ‌تر تنظیم کنید:

```yaml
scrape_configs:
  - job_name: sql_exporter
    scrape_interval: 90s
    scrape_timeout: 60s
```

Prometheus در هر درخواست timeout خود را برای exporter ارسال می‌کند. timeout
نهایی exporter برابر مقدار کوچک‌تر میان محدودیت محلی ۵۵ ثانیه و timeout سمت
Prometheus منهای `scrape_timeout_offset` خواهد بود.

Collectorهایی مانند `mssql_index_fragmentation`،
`mssql_buffer_pool_database`، `mssql_database_integrity`، `mssql_query_store`،
`mssql_stats`، `mssql_columnstore`، `mssql_security` و
`mssql_errorlog_signals` دارای `min_interval` طولانی مختص خود هستند؛ بنابراین
افزایش timeout باعث اجرای آن‌ها در تمام Scrapeهای Prometheus نمی‌شود.

## اعتبارسنجی در نسخه 0.24.4

باینری نسخه 0.24.4 می‌تواند فایل تنظیمات اصلی و تمام تعریف‌های Collector که
از طریق `collector_files` بارگذاری می‌شوند را بدون راه‌اندازی HTTP Listener
اعتبارسنجی کند:

```powershell
.\sql_exporter.exe "-config.file=sql_exporter.yml" -config.check
```

تنظیم `collectors: [mssql_*]` تمام Collectorها را در دسترس قرار می‌دهد، اما
برای محیط عملیاتی همچنان استفاده از پروفایل متناسب با نقش سرور توصیه می‌شود.
Collectorهای وابسته به Feature مانند CDC، Replication، SSIS، PolyBase، Service
Broker، Query Store، Always On و Resource Governor ممکن است در صورت غیرفعال بودن
Feature یا نبودن دیتابیس مربوطه هیچ سری زمانی تولید نکنند؛ این وضعیت لزوماً خطا نیست.

برای عیب‌یابی هنگام Rollout می‌توان متریک‌های سطح Query را موقتاً فعال کرد:

```yaml
global:
  enable_query_metrics: true
```

با این تنظیم متریک‌های `query_duration_seconds` و `query_rows_returned` منتشر
می‌شوند. پیش از فعال نگه‌داشتن دائمی، اثر Cardinality و فضای ذخیره‌سازی آن‌ها
را بررسی کنید.
