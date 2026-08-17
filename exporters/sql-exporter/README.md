# sql_exporter — مانیتورینگ SQL Server

مستند اختصاصی پکیج **sql_exporter** در این پوشه.

پورت scrape پیش‌فرض: **`9399`**  
Basic Auth پیش‌فرض: **غیرفعال** (جزئیات ساخت و فعال‌سازی: [../../docs/sql-exporter/fa/install-config-guide.md](../../docs/sql-exporter/fa/install-config-guide.md) — بخش «پورت scrape و Basic Auth»)

---

## محتویات پوشه

| فایل / پوشه | توضیح |
|------|--------|
| `sql_exporter.exe` | باینری exporter |
| `sql_exporter.yml` | تنظیمات اتصال SQL + لیست collectors |
| `web-config.yml` | TLS و Basic Auth (پیش‌فرض بدون auth) |
| `collector/` | تعریف متریک‌ها (`mssql_*.collector.yml`) |
| `profiles/` | پروفایل‌های آماده collectors (مثلاً `oltp.yml`, `alert-p1.yml`) |
| `prometheus/` | `rules/` + `profiles/` + `alertmanager/` برای `rule_files` و routing SMS/Email |
| `grafana/dashboards/` | داشبوردهای Grafana (Overview/NOC در ریشه؛ collectorها در `Collector/`) |
| `scripts/powershell/sql-exporter/` | اسکریپت‌های استقرار و همگام‌سازی PowerShell |
| `scripts/sql/` | اسکریپت‌های SQL کمکی (مثلاً ایجاد لاگین exporter) |
| `../../docs/sql-exporter/en/README.md` | ورودی مستندات English |
| `../../docs/sql-exporter/fa/README.md` | ورودی مستندات Persian |
| `../../docs/sql-exporter/en/collector-guide.md` | راهنمای ساخت/ویرایش collector (English) |
| `../../docs/sql-exporter/fa/collector-guide.md` | راهنمای ساخت/ویرایش collector (Persian) |
| `../../docs/sql-exporter/en/install-upgrade-guide.md` | راهنمای نصب و ارتقا (English) |
| `../../docs/sql-exporter/en/install-upgrade-guide.html` | نسخه HTML راهنمای نصب و ارتقا (English) |
| `../../docs/sql-exporter/fa/install-upgrade-guide.md` | راهنمای نصب و ارتقا (Persian) |
| `../../docs/sql-exporter/fa/install-upgrade-guide.html` | نسخه HTML راهنمای نصب و ارتقا (Persian) |
| `../../docs/sql-exporter/en/install-config-guide.md` | راهنمای نصب و کانفیگ sql_exporter (English) |
| `../../docs/sql-exporter/fa/install-config-guide.md` | راهنمای نصب و کانفیگ sql_exporter (Persian) |
| `../../docs/sql-exporter/en/profiles.md` | راهنمای پروفایل‌های Collector (English) |
| `../../docs/sql-exporter/fa/profiles.md` | راهنمای پروفایل‌های Collector (Persian) |
| `../../docs/sql-exporter/en/prometheus.md` | راهنمای پوشه prometheus/ (English) |
| `../../docs/sql-exporter/fa/prometheus.md` | راهنمای پوشه prometheus/ (Persian) |
| `../../docs/sql-exporter/en/alerting.md` | کاتالوگ Alert P0/P1/P2 (English) |
| `../../docs/sql-exporter/fa/alerting.md` | کاتالوگ Alert P0/P1/P2 (Persian) |
| `../../docs/sql-exporter/en/alertmanager.md` | Alertmanager SMS/Email routing (English) |
| `../../docs/sql-exporter/fa/alertmanager.md` | Alertmanager SMS/Email routing (Persian) |
| `../../docs/sql-exporter/en/prometheus-rules.md` | Recording Rule و Alert (English) |
| `../../docs/sql-exporter/fa/prometheus-rules.md` | Recording Rule و Alert (Persian) |
| `../../docs/sql-exporter/en/grafana.md` | داشبوردهای Grafana (English) |
| `../../docs/sql-exporter/fa/grafana.md` | داشبوردهای Grafana (Persian) |
| `../../docs/sql-exporter/en/collectors/README.md` | فهرست و راهنمای هر collector (English) |
| `../../docs/sql-exporter/fa/collectors/README.md` | فهرست و راهنمای هر collector (Persian) |
| `../../docs/sql-exporter/README.md` | ورودی مستندات English / Persian |
| `README.md` | همین مستند |

بارگذاری collectorها:

```yaml
collector_files:
  - "collector/*.collector.yml"

collectors: [mssql_*]   # یا لیست صریح پروفایل
```

---

## نصب ریموت (پیشنهادی)

برای نصب و ارتقا از اسکریپت‌های WinRM استفاده کنید. جزئیات کامل:
[راهنمای نصب و ارتقا](../../docs/sql-exporter/fa/install-upgrade-guide.md)

### نصب / به‌روزرسانی سرویس

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 -Computers sql-host-01,sql-host-02 -WhatIf
```

اجرای واقعی:

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)
```

با پروفایل collector (مثل `-Profile sql-server.yml` در Windows exporter):

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -Profile oltp.yml `
  -RemoteCredential (Get-Credential)
```

با آدرس Listen و Basic Auth:

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -ListenAddress ':9399' `
  -BasicAuthUsername 'scrape_user' `
  -BasicAuthHash '$2a$12$REPLACE_WITH_BCRYPT_HASH' `
  -RemoteCredential (Get-Credential)
```

### ارتقای نسخه روی نصب موجود

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 -Computers sql-host-01,sql-host-02 -WhatIf
```

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)
```

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -Profile oltp.yml `
  -RemoteCredential (Get-Credential)
```

حفظ web-config و تغییر پورت در اپگرید:

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -ListenAddress ':9399' `
  -PreserveWebConfig `
  -RemoteCredential (Get-Credential)
```

نکات:
- نیازمند دسترسی PowerShell Remoting (WinRM) به سرورهای مقصد است.
- سرویس `prometheus_sql_exporter` را با API استاندارد ویندوز ایجاد/به‌روزرسانی می‌کند.
- فایل‌های `sql_exporter.exe`، `sql_exporter.yml`، `web-config.yml`، `profiles\` و پوشه `collector\` را deploy می‌کند (مگر با `-SkipCollectors` در Install).
- `-ListenAddress` مقدار `--web.listen-address` را تنظیم می‌کند (پیش‌فرض `:9399`).
- `-BasicAuthUsername` + `-BasicAuthHash` (یا `-BasicAuthPassword` / `-WebConfigPath`) Basic Auth را در نصب/اپگرید فعال می‌کند؛ `-PreserveWebConfig` در اپگرید فایل ریموت را حفظ می‌کند.
- با `-Profile <name>.yml` فهرست collectors از `profiles/` داخل `sql_exporter.yml` نوشته می‌شود.
- اسکریپت Upgrade بدون `-Profile` کانفیگ ریموت را حفظ می‌کند؛ قبل از جایگزینی بکاپ می‌گیرد و در خطا rollback می‌کند.

### حذف نصب ریموت

```powershell
.\scripts\powershell\sql-exporter\Uninstall-SqlExporterRemote.ps1 `
  -Computers sql-host-01,sql-host-02 `
  -ServiceMode Preserve `
  -WhatIf
```

حالت پیش‌فرض پس از ساخت ZIP بکاپ، سرویس و پوشه نصب را حذف می‌کند. برای حذف فقط سرویس از `-KeepFiles` استفاده کنید. جزئیات در [راهنمای نصب، ارتقا و حذف](../../docs/sql-exporter/fa/install-upgrade-guide.md#حذف-ریموت) آمده است.

### همگام‌سازی فقط collectorها

پیش‌فرض مطابق `collector_files: collector/*.collector.yml` است. با `-Layout` بین دو حالت سوییچ کنید:

```powershell
# پیش‌فرض: کپی به collector\ و پاک‌کردن ymlهای ریشه
.\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 -Computers sql-host-01,sql-host-02 -Layout Collector

# حالت ریشه: کپی به root و حذف پوشه collector\
.\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 -Computers sql-host-01 -Layout Root -WhatIf
```

جزئیات: [راهنمای نصب و ارتقا](../../docs/sql-exporter/fa/install-upgrade-guide.md)

### Export داشبوردهای Grafana به repo

```powershell
# نیاز به GRAFANA_URL و GRAFANA_SERVICE_ACCOUNT_TOKEN
.\scripts\powershell\sql-exporter\Export-GrafanaDashboards.ps1
.\scripts\powershell\sql-exporter\Export-GrafanaDashboards.ps1 -RemoveOrphans
```

راهنما: [../../docs/sql-exporter/fa/grafana.md](../../docs/sql-exporter/fa/grafana.md)

---

## راهنماهای تکمیلی

- [مستندات اصلی docs](../../docs/sql-exporter/README.md)
- [English docs](../../docs/sql-exporter/en/README.md)
- [Persian docs](../../docs/sql-exporter/fa/README.md)
- [راهنمای نصب و ارتقا](../../docs/sql-exporter/fa/install-upgrade-guide.md) ([HTML](../../docs/sql-exporter/fa/install-upgrade-guide.html)) — [دسترسی‌های لازم](../../docs/sql-exporter/fa/install-upgrade-guide.md#دسترسیهای-لازم)
- [راهنمای نصب و کانفیگ](../../docs/sql-exporter/fa/install-config-guide.md)
- [راهنمای پروفایل‌ها](../../docs/sql-exporter/fa/profiles.md)
- [راهنمای پوشه prometheus/](../../docs/sql-exporter/fa/prometheus.md)
- [کاتالوگ Alerting](../../docs/sql-exporter/fa/alerting.md)
- [Alertmanager — SMS و Email](../../docs/sql-exporter/fa/alertmanager.md)
- [راهنمای Prometheus Rule و Alert](../../docs/sql-exporter/fa/prometheus-rules.md)
- [داشبوردهای Grafana](../../docs/sql-exporter/fa/grafana.md)
- [فهرست مستندات Collectorها](../../docs/sql-exporter/fa/collectors/README.md)

---

## اتصال به SQL Server

در `sql_exporter.yml`:

```yaml
data_source_name: 'sqlserver://127.0.0.1:49149?trusted+connection=yes&app+name=sql_exporter'
```

- از Windows Authentication استفاده می‌شود.
- پورت را با پورت واقعی instance عوض کنید.
- سرویس exporter باید با حسابی اجرا شود که به SQL دسترسی دارد.

### دسترسی‌های لازم

```sql
GRANT VIEW SERVER STATE TO [DOMAIN\SqlExporterAccount];
GRANT VIEW ANY DEFINITION TO [DOMAIN\SqlExporterAccount];
```

| Collector | دسترسی اضافه |
|-----------|--------------|
| `mssql_backup`, `mssql_restore`, `mssql_job_inventory`, `mssql_job_running`, `mssql_job_history`, `mssql_job_failed` | خواندن جداول `msdb` (`restorehistory` / `backupset` برای restore) |
| `mssql_database_integrity` | `suspect_pages` + `DBCC DBINFO` |
| `mssql_ssis` | `db_datareader` روی `SSISDB` |
| `mssql_replication` | خواندن `distribution` (اگر Distributor باشد) |
| `mssql_errorlog_signals` | `xp_readerrorlog` |
| `mssql_security` | `xp_readerrorlog` (لاگین ناموفق)، `CONTROL SERVER` (خواندن SQL Audit file) |
| `mssql_index_fragmentation` | دسترسی به DBهای کاربر |

---

## Collectorهای حذف‌شده (ادغام‌شده)

این فایل‌ها به `sql_exporter_removed/` منتقل شده‌اند؛ محتوای یکتایشان در collectorهای فعال ادغام شده است:

| حذف‌شده | ادغام در |
|---------|----------|
| `mssql_availability_sync` | `mssql_alwayson` |
| `mssql_workspace_memory` | `mssql_memory` |
| `mssql_performance_counters` | `mssql_standard` (`mssql_perf_counter`) + `mssql_memory` / `mssql_buffer_pool` |
| `mssql_ssis` / `mssql_ssisdb` (قدیمی) | `mssql_ssis` (+ Agent در `mssql_job_running`) |
| `mssql_oltp` | `mssql_locks` + `mssql_transactions_long` |
| `mssql_dwh` | `mssql_parallelism` + `mssql_ssis` + `mssql_job_running` |

---

## فهرست Collectorها

### مشترک (همه نوع سرور)

| Collector | `min_interval` | کاربرد |
|-----------|----------------|--------|
| `mssql_standard` | ۳۰s | up، version، DB state/recovery، transactions، errors، batch، perf_counter، process/OS memory، user connections، compilations/recompilations، checkpoint/log reuse wait |
| `mssql_backup` | ۹۰۰s | backup age/size + damaged + failed backup jobs + throughput/compression/verify |
| `mssql_restore` | ۳۰۰s | آخرین restore از `restorehistory` (lag/age/size/source) + standby state + throughput/gap-to-RPO + failed restore jobs — مناسب secondaryهای backup-sync مثل sql-host-02\\NODE |
| `mssql_job_inventory` | ۹۰۰s | job enabled/count / last outcome / next run |
| `mssql_waits` | ۱۲۰s | Top wait types + nonbenign/signal ratio + top5 share |
| `mssql_memory` | ۶۰s | clerks، resource semaphore، grants، Reserved Server Memory، active grants ≥۱۰۰MB، target/total/stolen/locked pages |
| `mssql_tempdb` | ۶۰s | فضای tempdb، version store، top sessions، waiting tasks، spill/load contention |
| `mssql_file_io` | ۱۸۰s | stall/latency per file + volume space + pending requests/bytes + queue depth + p95 latency |
| `mssql_blocking` | ۳۰s | blocked sessions / head blocker |
| `mssql_heavy_queries` | ۶۰s | درخواست‌های فعال سنگین + Top plan cache |
| `mssql_log_usage` | ۶۰s | درصد و حجم log |
| `mssql_connections_detail` | ۶۰s | نشست‌ها بر اساس login/program/host/db |
| `mssql_database_size_growth` | ۳۰۰s | رشد حجم data/log و فایل‌ها |
| `mssql_cpu` | ۳۰s | CPU پروسس SQL از ring buffer |
| `mssql_buffer_pool` | ۱۸۰s | PLE (NUMA) و Buffer Manager |
| `mssql_parallelism` | ۶۰s | wait موازی‌سازی، MAXDOP/memory config، DOP + grant |
| `mssql_job_running` | ۳۰s | Agent service + Jobهای در حال اجرا (+ step) |
| `mssql_job_failed` | ۶۰s | failهای Job (1h/24h) + last fail + current failed |
| `mssql_job_history` | ۱۲۰s | تاریخچه اجرا / last duration / avg success |
| `mssql_database_space` | ۳۰۰s | used/free، max_size، autogrowth، VLF |
| `mssql_database_integrity` | ۳۶۰۰s | suspect_pages + age آخرین CHECKDB |
| `mssql_scheduler` | ۳۰s | runnable / work_queue / CPU topology |
| `mssql_plan_cache` | ۱۲۰s | اندازه cache، single-use ratio |
| `mssql_columnstore` | ۳۰۰s | سلامت rowgroup (مفید برای DWH) |
| `mssql_autogrowth` | ۳۰۰s | رویدادهای autogrowth از default trace |
| `mssql_stats` | ۶۰۰s | TOP آمار قدیمی / modification_counter / sample% + تعداد stale per DB |
| `mssql_index_usage` | ۳۰۰s | TOP index seeks/scans/lookups/updates |
| `mssql_instance_configuration` | ۳۰۰s | drift تنظیمات instance (value در برابر in_use) + IFI + uptime + Trace Flagهای Global |
| `mssql_missing_index` | ۶۰۰s | TOP ۳۰ پیشنهاد missing index + cost/compiles + rollup سطح DB |
| `mssql_query_store` | ۳۰۰s | وضعیت QS + Top کوئری‌ها |
| `mssql_errorlog_signals` | ۳۰۰s | شمارش سیگنال‌های ERRORLOG |
| `mssql_security` | ۳۰۰s | وضعیت امنیت: failed login، نشست‌های privileged، audit، رمزنگاری، surface area، linked server |

### Always On

| Collector | `min_interval` | کاربرد |
|-----------|----------------|--------|
| `mssql_alwayson` | ۳۰s | مانیتور کامل AG (lag / sync / seeding) |
| `mssql_alwayson_events` | ۳۰۰s | flaps تغییر وضعیت replica از AlwaysOn_health (۲۴ساعت) |
| `mssql_hadr_cluster` | ۳۰s | AG Listener + WSFC quorum/اعضا + نودهای FCI |

**`mssql_alwayson` شامل:**  
estimated data loss، secondary lag، `log_send_queue/rate`، `redo_queue/rate`، `commit_latency`، filestream send rate، زمان تقریبی خالی‌شدن صف، suspend، disconnected time، flap count، متریک per-replica، سلامت replica و AG.  
متریک قدیمی `mssql_alwayson_data_loss` برای سازگاری داشبوردها حفظ شده است.

**`mssql_hadr_cluster` شامل:**  
پرچم‌های `IsClustered` / `IsHadrEnabled`، وضعیت quorum و اعضای WSFC، DNS/پورت/وضعیت IP لیسنر AG، وضعیت و owner نودهای FCI.

### مخصوص OLTP

| Collector | `min_interval` | کاربرد |
|-----------|----------------|--------|
| `mssql_locks` | ۳۰s | قفل‌ها، waiting locks، latch stats، lock-related requests |
| `mssql_transactions_long` | ۳۰s | تراکنش باز ≥ ۳۰s |
| `mssql_index_fragmentation` | **۲۱۶۰۰s (۶h)** | فرگمنت ایندکس — خیلی سنگین |
| `mssql_replication` | ۶۰s | Push/Pull: نقش DB، inventory، Log Reader / Distribution / Snapshot latency+status، pending cmds، Jobهای REPL-* (مناسب Publisher+Subscriber مثل sql-pub-01 و Pull مثل sql-sub-01) |

### مخصوص DWH / SSIS

| Collector | `min_interval` | کاربرد |
|-----------|----------------|--------|
| `mssql_ssis` | ۶۰s | کاتالوگ SSIS + سلامت/حجم SSISDB |

اگر `SSISDB` / `distribution` / AG نباشد، نتیجه خالی است و scrape fail نمی‌شود.

---

## پروفایل‌ها

پیش‌فرض فعلی همه را لود می‌کند:

```yaml
collectors: [mssql_*]
```

برای سرور پرترافیک یکی از پروفایل‌های زیر را در `sql_exporter.yml` فعال کنید (یا با `-Profile oltp.yml` روی اسکریپت‌های Install/Upgrade/Deploy). فهرست کامل در پوشه `profiles/` موجود است؛ جزئیات در [راهنمای پروفایل‌ها](../../docs/sql-exporter/fa/profiles.md).

### DWH / BI

```yaml
collectors:
  - mssql_standard
  - mssql_backup
  - mssql_restore
  - mssql_job_inventory
  - mssql_alwayson
  - mssql_heavy_queries
  - mssql_waits
  - mssql_memory
  - mssql_tempdb
  - mssql_file_io
  - mssql_blocking
  - mssql_log_usage
  - mssql_connections_detail
  - mssql_database_size_growth
  - mssql_cpu
  - mssql_buffer_pool
  - mssql_parallelism
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_scheduler
  - mssql_plan_cache
  - mssql_columnstore
  - mssql_autogrowth
  - mssql_stats
  - mssql_index_usage
  - mssql_missing_index
  - mssql_ssis
```

### Restore / backup-sync secondary (مثال sql-host-02\\NODE)

```yaml
collectors:
  - mssql_standard
  - mssql_database_configuration
  - mssql_instance_configuration
  - mssql_backup
  - mssql_job_inventory
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_file_io
  - mssql_waits
  - mssql_memory
  - mssql_cpu
  - mssql_scheduler
  - mssql_autogrowth
  - mssql_restore
  - mssql_log_shipping
  - mssql_errorlog_signals
  - mssql_alwayson
  - mssql_alwayson_events
  - mssql_hadr_cluster
  - mssql_log_usage
  - mssql_connections_detail
```

### Replication (Publisher / Distributor / Subscriber)

```yaml
collectors:
  - mssql_standard
  - mssql_database_configuration
  - mssql_instance_configuration
  - mssql_cdc_change_tracking
  - mssql_backup
  - mssql_job_inventory
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_file_io
  - mssql_waits
  - mssql_memory
  - mssql_cpu
  - mssql_scheduler
  - mssql_autogrowth
  - mssql_replication
  - mssql_errorlog_signals
  - mssql_alwayson
  - mssql_alwayson_events
  - mssql_hadr_cluster
  - mssql_log_usage
  - mssql_blocking
  - mssql_connections_detail
  - mssql_transactions_long
```

### Security / audit

```yaml
collectors:
  - mssql_standard
  - mssql_database_configuration
  - mssql_instance_configuration
  - mssql_backup
  - mssql_job_inventory
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_autogrowth
  - mssql_security
  - mssql_errorlog_signals
  - mssql_certificates
```

### OLTP

```yaml
collectors:
  - mssql_standard
  - mssql_database_configuration
  - mssql_instance_configuration
  - mssql_cdc_change_tracking
  - mssql_resource_governor
  - mssql_backup
  - mssql_job_inventory
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_file_io
  - mssql_waits
  - mssql_memory
  - mssql_cpu
  - mssql_scheduler
  - mssql_autogrowth
  - mssql_alwayson
  - mssql_alwayson_events
  - mssql_hadr_cluster
  - mssql_heavy_queries
  - mssql_tempdb
  - mssql_blocking
  - mssql_log_usage
  - mssql_connections_detail
  - mssql_locks
  - mssql_transactions_long
  - mssql_buffer_pool
  - mssql_plan_cache
  - mssql_stats
  - mssql_index_usage
  - mssql_query_store
```

### SSIS جدا

```yaml
collectors:
  - mssql_standard
  - mssql_backup
  - mssql_job_inventory
  - mssql_waits
  - mssql_memory
  - mssql_tempdb
  - mssql_file_io
  - mssql_blocking
  - mssql_log_usage
  - mssql_connections_detail
  - mssql_cpu
  - mssql_job_running
  - mssql_job_failed
  - mssql_job_history
  - mssql_database_space
  - mssql_database_integrity
  - mssql_autogrowth
  - mssql_ssis
```

---

## استقرار

1. کل محتویات این پوشه را روی سرور کپی کنید.
2. `data_source_name` و در صورت نیاز `collectors` را در `sql_exporter.yml` تنظیم کنید.
3. سرویس Windows مربوط به `sql_exporter` را Restart کنید.
4. تست:

```text
http://HOSTNAME:9399/metrics
```

اگر Basic Auth فعال باشد، بدون credential پاسخ 401 می‌گیری. راهنما: [../../docs/sql-exporter/fa/install-config-guide.md](../../docs/sql-exporter/fa/install-config-guide.md) — بخش «پورت scrape و Basic Auth».

نمونه‌های مفید برای جستجو در `/metrics`:

- `mssql_up`
- `mssql_alwayson_`
- `mssql_hadr_`
- `mssql_requests_` / `mssql_top_query_`
- `mssql_wait_`
- `mssql_tempdb_`
- `mssql_perf_counter`
- `mssql_parallelism_`
- `mssql_memory_active_grant_mb`
- `mssql_memory_target_server_mb`
- `mssql_memory_stolen_mb`
- `mssql_tempdb_waiting_tasks_count`
- `mssql_tempdb_spill_writes_mb`
- `mssql_file_io_pending_requests`
- `mssql_file_io_read_latency_p95_ms`
- `mssql_backup_throughput_mb_s`
- `mssql_restore_gap_to_rpo_seconds`
- `mssql_waits_nonbenign_percent`
- `mssql_ssis_failed_total`
- `mssql_ssis_failed_count`
- `mssql_ssis_failed_last_age_seconds`
- `mssql_job_history_`
- `mssql_backup_age_seconds`
- `mssql_backup_log_size_today_bytes`
- `mssql_restore_lag_seconds`
- `mssql_restore_age_seconds`
- `mssql_restore_job_failed_total_24h`
- `mssql_job_failed_total`
- `mssql_job_failed_current`
- `mssql_database_space_`
- `mssql_checkdb_age_seconds`
- `mssql_scheduler_total_runnable`
- `mssql_plan_cache_single_use_ratio`
- `mssql_columnstore_`
- `mssql_autogrowth_`
- `mssql_stats_`
- `mssql_missing_index_`
- `mssql_alwayson_is_failover_ready`
- `mssql_backup_job_failed_total_24h`

---

## افزودن Collector جدید

1. فایل `collector/mssql_NAME.collector.yml` بسازید (`collector_name` باید با نام فایل هم‌خوان باشد).
2. اگر `collectors: [mssql_*]` است → فقط Restart کافی است.
3. اگر پروفایل صریح دارید → نام را به لیست `collectors` اضافه کنید.
4. روی یک سرور تست کنید، بعد rollout کنید.

قالب حداقلی:

```yaml
collector_name: mssql_example
min_interval: 60s
metrics:
  - metric_name: mssql_example_value
    type: gauge
    help: 'Example metric'
    values: [value]
    query: |
      SELECT CAST(1 AS float) AS value;
```

---

## نکات عملکرد

- `min_interval` جلوی اجرای بیش‌ازحد کوئری‌های سنگین را می‌گیرد (حتی اگر scrape هر ۱۵s باشد).
- متریک‌های تجمعی را با `rate()` / `increase()` ببینید.
- متریک‌های لحظه‌ای (blocking، AG lag، grants pending) را مستقیم آلرت کنید.
- از label کردن متن کامل کوئری خودداری شده؛ فقط `statement_snip` کوتاه استفاده شود.
- روی سرور خیلی شلوغ ترجیحاً غیرفعال کنید مگر لازم باشد:
  - `mssql_index_fragmentation`
  - `mssql_errorlog_signals`

---

## عیب‌یابی

| مشکل | اقدام |
|------|--------|
| تارگت `up=0` | سرویس exporter، پورت 9399، فایروال، Basic Auth |
| اتصال به SQL برقرار نیست | DSN، پورت instance، حساب سرویس |
| `scrape_errors_total` بالا | لاگ سرویس؛ یک collector کوئری معیوب دارد |
| متریک AG خالی | instance عضو AG نیست |
| متریک SSIS خالی | `SSISDB` نیست یا دسترسی ندارد |
| متریک restore خالی | روی این instance `restorehistory` امسال نیست (primary بدون restore) |
| سری‌های خیلی زیاد | پروفایل را محدود کنید |

---

## نمونه آلرت Always On

```promql
mssql_alwayson_secondary_lag_seconds > 30
mssql_alwayson_log_send_queue_kb > 102400
mssql_alwayson_redo_queue_kb > 102400
mssql_alwayson_is_suspended == 1
mssql_alwayson_replica_connected_state == 0
mssql_alwayson_group_synchronization_health < 2
mssql_hadr_cluster_quorum_state != 1
mssql_hadr_cluster_member_state != 1
mssql_hadr_listener_ip_state != 0
mssql_hadr_fci_node_status != 0
```

## نمونه آلرت Restore / backup-sync

معادل ستون **Difference Restore** در گزارش Power BI (`GETDATE() - backup_finish_date`):

```promql
# تأخیر بیش از ۲ ساعت (مثل هشدار نارنجی Power BI)
mssql_restore_lag_seconds > 7200

# تأخیر بحرانی (روزها بدون restore موفق)
mssql_restore_lag_seconds > 86400

# Jobهای RESTORE ناموفق در ۲۴ ساعت
mssql_restore_job_failed_total_24h > 0
```

---

## خلاصه

| نوع سرور | پیشنهاد |
|----------|---------|
| DWH / BI | مشترک + `mssql_parallelism` + `mssql_ssis` + `mssql_alwayson` (+ `mssql_restore` اگر secondary هم باشد) |
| Restore secondary | `profiles/restore-secondary.yml`: restore + log shipping + AG/HADR |
| Replication | `profiles/replication.yml`: replication + AG/HADR + CDC |
| Security / audit | `profiles/security-audit.yml`: security + errorlog + certificates (بدون perf-detail سنگین) |
| OLTP | `profiles/oltp.yml`: مشترک + locks/transactions + AlwaysOn/HADR + Query Store |
| Alert P0 (Critical) | `profiles/alert-p0.yml` + `prometheus/scrape-configs/sql-exporter/p0-critical.yml` |
| Alert P0+P1 | `profiles/alert-p1.yml` + `prometheus/scrape-configs/sql-exporter/p1-high.yml` |
| Alert P0+P1+P2 | `profiles/alert-p2.yml` + `prometheus/scrape-configs/sql-exporter/p2-medium.yml` / `oltp.yml` |
| SSIS جدا | مشترک سبک + `mssql_ssis` + `mssql_job_running` |
| همه (تست) | `collectors: [mssql_*]` |
