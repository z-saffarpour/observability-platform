# مانیتورینگ SSAS Tabular و Multidimensional

[English](../en/ssas-monitoring.md)

Collector سفارشی `Collect-SsasMetrics.ps1` اطلاعات DMV و AMO را به textfile collector می‌دهد و برای هر دو Storage Mode کار می‌کند. نام کاربران عمداً در labelها منتشر نمی‌شود؛ فقط تعدادها ثبت می‌شوند تا هم اطلاعات امنیتی افشا نشود و هم cardinality کنترل شود.

نصب ریموت windows_exporter با `Install-WindowsExporterRemote.ps1` علاوه بر exporter و Profileها، پوشه‌های `scripts/powershell` و `scripts/ssas` و `textfile_inputs` را هم مستقر می‌کند. روی سرورهای SSAS باید `Install-SsasMetricsTask.ps1` با دسترسی Administrator اجرا شود تا سرویس ویندوز `prometheus_windows_ssas` نصب گردد. برای استقرار خود exporter به [راهنمای نصب و آپگرید](install-upgrade-guide.md) مراجعه کنید.

سرویس می‌تواند از میزبان داخلی `ServiceBase` یا NSSM استفاده کند. فایل NSSM توسط اسکریپت‌های نصب و ارتقا در `C:\Program Files\Observability\Tools\NSSM\nssm.exe` مستقر می‌شود.

```powershell
# حالت داخلی و پیش‌فرض
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 -ServiceMode ServiceBase

# حالت NSSM
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 -ServiceMode NSSM
```

هر دو نصب‌کنندهٔ محلی و ریموت حساب **Log On** سرویس را تنظیم می‌کنند. `-ServiceAccountMode` از `LocalSystem` (پیش‌فرض)، `LocalService`، `NetworkService`، `Credential`، `gMSA` و `NtService` پشتیبانی می‌کند. برای حساب سرویس دامنه از `-ServiceAccountMode Credential -ServiceCredential (Get-Credential 'DOMAIN\svc-ssas-monitoring')` و برای gMSA از `-ServiceAccountMode gMSA -ServiceAccount 'DOMAIN\gmsa-ssas-monitoring$'` استفاده کنید.

نصب‌کننده وضعیت مرحله‌به‌مرحله و خطاها را هم در console و هم در فایل `Log\prometheus_windows_ssas.install.log` زیر مسیر نصب ثبت می‌کند. همچنین Event Source با نام `prometheus_windows_ssas` را در لاگ Application ثبت می‌کند: Event ID `1001` نصب موفق و Event ID `1002` خطای نصب را ثبت می‌کند. رویدادهای چرخه اجرا و خطاهای Collector نیز با همین نام سرویس نوشته می‌شوند. پیام‌های داخلی Wrapper خود NSSM به‌علت نام کامپایل‌شده آن همچنان Source برابر `nssm` دارند. اگر تمام رویدادهای مرتبط باید حتماً نام سرویس را نشان دهند، از `ServiceBase` استفاده کنید.

برای نصب و حذف گروهی از طریق WinRM، اسکریپت‌های ریموت را روی سرور مدیریت اجرا کنید:

```powershell
.\scripts\powershell\windows-exporter\Install-SsasMetricsRemote.ps1 -Computers SSAS01,SSAS02 -ServiceMode ServiceBase
.\scripts\powershell\windows-exporter\Uninstall-SsasMetricsRemote.ps1 -Computers SSAS01,SSAS02 -ServiceMode Preserve
```

### چرخه نصب و حذف ریموت سرویس

اسکریپت `Install-SsasMetricsRemote.ps1` فایل‌های Collector و میزبان سرویس را stage می‌کند، سرویس `prometheus_windows_ssas` را نصب یا به‌روزرسانی می‌کند، فایل `collector/ssas-collector.json` را می‌سازد و در حالت `-ServiceMode NSSM` ابزار مشترک را در `C:\Program Files\Observability\Tools\NSSM\nssm.exe` قرار می‌دهد.

```powershell
# شبیه‌سازی نصب NSSM
.\scripts\powershell\windows-exporter\Install-SsasMetricsRemote.ps1 `
  -Computers SSAS01,SSAS02 -ServiceMode NSSM -WhatIf

# نصب و تنظیم Instanceها
.\scripts\powershell\windows-exporter\Install-SsasMetricsRemote.ps1 `
  -Computers SSAS01,SSAS02 `
  -ServiceMode ServiceBase `
  -Instance 'localhost','SSAS01\TABULAR' `
  -RemoteCredential (Get-Credential)
```

اسکریپت `Uninstall-SsasMetricsRemote.ps1` سرویس و Scheduled Task قدیمی را حذف می‌کند. فایل‌های مشترک windows_exporter حفظ می‌شوند. گزینه `-RemoveFiles` فقط اسکریپت‌ها، `collector/ssas-collector.json`، خروجی‌های textfile و لاگ‌های اختصاصی SSAS را پس از تهیه بکاپ پاک می‌کند. فقط زمانی از `-SkipBackup` استفاده کنید که امکان بازیابی لازم نیست.

```powershell
.\scripts\powershell\windows-exporter\Uninstall-SsasMetricsRemote.ps1 `
  -Computers SSAS01,SSAS02 -ServiceMode Preserve -WhatIf

.\scripts\powershell\windows-exporter\Uninstall-SsasMetricsRemote.ps1 `
  -Computers SSAS01,SSAS02 `
  -ServiceMode Preserve `
  -RemoveFiles `
  -RemoteCredential (Get-Credential)
```

اسکریپت‌های محلی `Install-SsasMetricsTask.ps1` و `Uninstall-SsasMetricsService.ps1` نیز برای اجرای مستقیم روی سرور مقصد حفظ شده‌اند.

## نصب

پیش‌نیاز، نصب SSAS Client Libraries شامل `Microsoft.AnalysisServices.AdomdClient` و AMO است. حساب Log On سرویس باید اجازه اتصال و مشاهده DMVها را داشته باشد؛ برای شمارش کامل role/memberها به دسترسی مدیریتی SSAS نیاز است.

```powershell
Set-Location 'C:\Program Files\Observability\PrometheusExporters\windows-exporter'
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 -Instance localhost
# Named instance یا چند instance:
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 -Instance 'SERVER01\TABULAR','SERVER01\MD'
```

سرویس windows_exporter باید با `profiles/ssas.yml` (یا در نقش ترکیبی با `data-platform.yml` / `data-platform-cluster.yml`) اجرا و سپس restart شود. برای تست دستی:

```powershell
.\scripts\powershell\windows-exporter\Collect-SsasMetrics.ps1 -Instance localhost
Get-Content .\textfile_inputs\ssas.prom
Invoke-WebRequest http://localhost:9182/metrics | Select-String 'ssas_'
```

## متریک‌ها

| متریک | مفهوم |
|---|---|
| `ssas_up`, `ssas_server_info` | اتصال، mode، version و edition |
| `ssas_databases`, `ssas_database_info` | inventory دیتابیس و compatibility level |
| `ssas_database_last_processed_timestamp_seconds` | جدیدترین زمان پردازش پارتیشن/دایمنشن در دیتابیس |
| `ssas_database_processing_stale` | `1` وقتی حداقل یک پارتیشن یا دایمنشن در دیتابیس stale باشد |
| `ssas_database_stale_partitions` | تعداد پارتیشن‌های stale در دیتابیس |
| `ssas_database_stale_dimensions` | تعداد دایمنشن‌های stale در دیتابیس |
| `ssas_object_last_processed_timestamp_seconds` | آخرین زمان پردازش/refresh برای هر پارتیشن یا دایمنشن |
| `ssas_object_processing_stale` | پرچم stale برای هر پارتیشن یا دایمنشن (`object_type` = `partition` یا `dimension`) |
| `ssas_sessions`, `ssas_connections`, `ssas_commands_active` | بار هم‌زمان |
| `ssas_sessions_by_login` | نشست‌های فعال بر اساس `login`، `application`، `database` و `client_host` (IP یا hostname کلاینت از DMV) |
| `ssas_unique_logins` | تعداد login یکتای sessionهای جاری |
| `ssas_session_cpu_time_seconds_total` | CPU تجمیعی sessionهای مشاهده‌شده |
| `ssas_server_administrators` | تعداد اعضای role مدیریتی سرور |
| `ssas_roles`, `ssas_role_members` | تعداد role و اعضا، به تفکیک database و permission (Tabular: `TMSCHEMA_ROLES` از ADOMD؛ Multidimensional: `Database.Roles` از AMO) |
| `ssas_high_privilege_logins` | کاربران یکتای Administrator/Refresh و مدیران سرور |
| `ssas_privileged_active_sessions` | sessionهای جاری کاربران پرسطح |
| `ssas_collector_errors`, `ssas_collector_duration_seconds` | سلامت خود collector |
| `ssas_database_size_bytes` | جمع بایت‌های VertiPaq به ازای هر database در Tabular؛ در Multidimensional از AMO `EstimateSize` |
| `ssas_database_memory_bytes` | جمع حافظه زنده هر database از ردیف‌های `OBJECT_PARENT_PATH` / `ObjectParentPath` (با fallback به `DISCOVER_MEMORYUSAGE` وقتی `DISCOVER_OBJECT_MEMORY_USAGE` overflow می‌دهد) |
| `ssas_memory_object_usage_bytes` | تفکیک حافظه به ازای database و `object_group` از همان DMV |
| `ssas_tabular_object_size_bytes` | بایت segment به ازای database/table_id/column_id |

`high privilege` در این پیاده‌سازی شامل Server Administrator و roleهای دارای `Administrator`، `Refresh` یا `ReadRefresh` است. در Multidimensionalهای قدیمی که property استاندارد permission در AMO قابل خواندن نیست، role با نام شامل `admin` به‌عنوان fallback طبقه‌بندی می‌شود؛ این مورد باید روی canary با ساختار واقعی roleها بازبینی شود.

Ruleهای آماده در `prometheus/alert-rules/windows-exporter/windows_exporter-role-ssas.rules.yml` قرار دارند و با پروفایل `prometheus/scrape-configs/windows-exporter/ssas.yml` به `rule_files` اضافه می‌شوند. آستانه stale پیش‌فرض ۲۴ ساعت است و با تناوب واقعی پردازش مدل‌ها باید تنظیم شود. کاتالوگ: [Alerting](alerting.md).

## داشبورد Grafana

فایل `grafana/dashboards/winexp-00-ssas.json` را از بخش **Dashboards > Import** وارد کنید. داشبورد دارای فیلترهای Prometheus Job، Windows Server، SSAS Instance و Database است و نمای availability، session/login، دسترسی‌های بالا، role membership، freshness پردازش، اطلاعات نسخه و مصرف CPU/Memory پردازش `msmdsrv` را ارائه می‌کند.

UID پیش‌فرض Prometheus datasource مطابق سایر داشبوردهای این پکیج `ce0xqwhy35wqod` است. اگر UID محیط متفاوت است، هنگام Import datasource را map کنید یا مقدار UID را در JSON جایگزین کنید.

## معماری Collectorها

| اسکریپت | داده |
|---|---|
| `Collect-SsasMetrics.ps1` | Service/PID، TCP endpoint، probe واقعی، DMV session/connection/command، AMO database/role و اندازه Segmentهای Tabular |
| `Collect-SsasPerformanceCounters.ps1` | گروه‌های رسمی Connection، Cache، Locks، Memory، Processing، Storage Engine Query، Threads و Reliability |
| `Collect-SsasXEventMetrics.ps1` | شمارنده‌های تجمعی Login/Logout، امنیت، Processing، Backup و Query از فایل‌های XEL |
| `Invoke-SsasCollectors.ps1` | اجرای یکپارچه سه collector توسط سرویس SSAS |
| `Run-SsasMetricsService.ps1` | میزبان Windows ServiceBase برای سرویس `prometheus_windows_ssas` |

علاوه بر aliasهای ثابت، تمام counterهای گروه‌های انتخاب‌شده با متریک `ssas_performance_counter_value` و labelهای محدود `counter_set`، `group`، `counter` و `perf_instance` منتشر می‌شوند. نام objectهای Performance Counter بین نسخه و Named Instance متفاوت است و به همین دلیل در زمان اجرا کشف می‌شود.

## مسیرهای استاندارد فایل‌ها

| نوع | مسیر پیشنهادی |
|---|---|
| نصب collector و config | `C:\Program Files\Observability\PrometheusExporters\windows-exporter\` |
| خروجی Prometheus (`.prom`) | `...\textfile_inputs\` |
| state کوچک collector | `...\state\` |
| فایل‌های XEL/XEM (SSAS می‌نویسد) | `C:\ProgramData\Observability\SSAS\xevents\` |
| connection string probe | `C:\ProgramData\Observability\SSAS\secrets\` |
| audit JSONL برای SIEM | `C:\ProgramData\Observability\SSAS\audit\ssas-security-audit.jsonl` |
| backup SSAS (خارج از Observability) | مسیر واقعی backup سرور (مثلاً `D:\SSAS\Backup`) |

`Install-SsasMetricsTask.ps1` پوشه‌های `ProgramData\Observability\SSAS\` را هنگام نصب می‌سازد. با `-EnableXEvents` اگر `-XelPath` داده نشود، مقدار پیش‌فرض `C:\ProgramData\Observability\SSAS\xevents\*.xel` در `collector\ssas-collector.json` ثبت می‌شود.

## مقداردهی مسیرها هنگام نصب و آپگرید

مسیرهای `ProgramData` و تنظیمات چرخش فایل در `collector\ssas-collector.json` نوشته می‌شوند. هنگام نصب مجدد یا آپگرید، `Instance`، `Endpoint` و timeoutهای موجود حفظ می‌شوند؛ مسیرهای استاندارد و بخش `Rotation` با مقادیر جدید به‌روز می‌شوند.

| پارامتر نصب | مقدار پیش‌فرض |
|---|---|
| `ProgramDataRoot` | `C:\ProgramData\Observability\SSAS` |
| `XEventsDirectory` | `...\SSAS\xevents` |
| `SecretsDirectory` | `...\SSAS\secrets` |
| `AuditDirectory` | `...\SSAS\audit` |
| `SiemOutputPath` | `...\audit\ssas-security-audit.jsonl` |

نمونه override در نصب:

```powershell
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 `
  -Instance 'NODE' `
  -Endpoint 'NODE=localhost:49160' `
  -EnableXEvents `
  -ProgramDataRoot 'D:\Observability\SSAS' `
  -AuditLogMaxBytes 104857600
```

برای به‌روزرسانی فقط config بدون نصب مجدد سرویس:

```powershell
.\scripts\powershell\windows-exporter\Update-SsasCollectorConfig.ps1
```

`Upgrade-WindowsExporterRemote.ps1` در سرورهایی که `prometheus_windows_ssas` نصب است، اسکریپت‌های SSAS را کپی و `ssas-collector.json` را merge می‌کند.

نمونه ساختار `ssas-collector.json`:

```json
{
  "Instance": ["NODE"],
  "Endpoint": ["NODE=localhost:49160"],
  "Paths": {
    "ProgramDataRoot": "C:\\ProgramData\\Observability\\SSAS",
    "XEventsDirectory": "C:\\ProgramData\\Observability\\SSAS\\xevents",
    "SecretsDirectory": "C:\\ProgramData\\Observability\\SSAS\\secrets",
    "AuditDirectory": "C:\\ProgramData\\Observability\\SSAS\\audit"
  },
  "XelPath": ["C:\\ProgramData\\Observability\\SSAS\\xevents\\*.xel"],
  "SiemOutputPath": "C:\\ProgramData\\Observability\\SSAS\\audit\\ssas-security-audit.jsonl",
  "CommandTimeoutSec": 120,
  "Rotation": {
    "AuditLogMaxBytes": 52428800,
    "XelFileMaxBytes": 1073741824,
    "XelDirectoryMaxBytes": 5368709120,
    "KeepRotatedFiles": 10
  }
}
```

## چرخش فایل (Rotation)

وقتی اندازه فایل‌ها از حد تعیین‌شده بیشتر شود، collector به‌صورت خودکار فایل را می‌چرخاند:

| تنظیم | پیش‌فرض | رفتار |
|---|---|---|
| `AuditLogMaxBytes` | 50 MB | فایل audit JSONL به `audit\archive\` منتقل می‌شود |
| `XelFileMaxBytes` | 1 GB | فایل‌های `.xel` قدیمی (غیرفعال) به `xevents\archive\` منتقل می‌شوند |
| `XelDirectoryMaxBytes` | 5 GB | کل حجم پوشه xevents (شامل archive) محدود می‌شود |
| `KeepRotatedFiles` | 10 | حداکثر تعداد فایل‌های archive نگه‌داری‌شده |

Session Extended Events در XMLA نیز `max_file_size=256` MB و `max_rollover_files=10` دارد (چرخش سمت SSAS). چرخش collector مکمل آن است و فایل‌های پردازش‌شده یا بزرگ را archive یا حذف می‌کند.

محدودیت‌ها را در نصب override کنید:

```powershell
.\Install-SsasMetricsRemote.ps1 -Computers SSAS01 `
  -Instance 'NODE' -Endpoint 'NODE=localhost:49160' -EnableXEvents `
  -AuditLogMaxBytes 104857600 -XelDirectoryMaxBytes 10737418240
```


## نصب کامل

برای Default Instance:

```powershell
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 `
  -Instance localhost `
  -Endpoint 'localhost=localhost:2383' `
  -BackupPath 'D:\SSAS\Backup' `
  -EnableXEvents
```

برای Named Instance باید پورت واقعی مشخص شود:

```powershell
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 `
  -Instance 'SERVER01\TABULAR','SERVER01\MD' `
  -Endpoint 'SERVER01\TABULAR=SERVER01:51342','SERVER01\MD=SERVER01:51343' `
  -BackupPath 'E:\SSAS-Backup' `
  -EnableXEvents
```

یا با مسیر صریح در همان دستور نصب:

```powershell
.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 `
  -Instance 'SERVER01\TABULAR' `
  -Endpoint 'SERVER01\TABULAR=SERVER01:51342' `
  -XelPath 'C:\ProgramData\Observability\SSAS\xevents\*.xel'
```

Task به‌صورت پیش‌فرض با `SYSTEM` اجرا می‌شود. برای خواندن کامل `DISCOVER_SESSIONS` و role/memberها، هویت Collector باید دسترسی مدیریتی مناسب SSAS داشته باشد. Probe جداگانه Read-only اختیاری است؛ connection string را در فایلی قرار دهید که ACL آن فقط برای `SYSTEM` و Administrators قابل خواندن باشد و سپس نگاشت بدهید:

```powershell
$probeFile='C:\ProgramData\Observability\SSAS\secrets\readonly-probe.connectionstring'
# نمونه محتوا: Data Source=SERVER01\TABULAR;User ID=DOMAIN\ssas_probe;Password=...;Application Name=Prometheus ReadOnly Probe
icacls $probeFile /inheritance:r /grant:r 'SYSTEM:R' 'Administrators:F'

.\scripts\powershell\windows-exporter\Install-SsasMetricsTask.ps1 `
  -Instance 'SERVER01\TABULAR' `
  -ReadOnlyProbeConnectionStringFile "SERVER01\TABULAR=$probeFile"
```

اگر فایل جدا تعریف نشود، probe با هویت خود Scheduled Task اجرا و با label برابر `probe_mode="collector_identity"` مشخص می‌شود. Password هرگز وارد label یا فایل `.prom` نمی‌شود.

## Extended Events و SIEM

فایل `scripts/ssas/windows-exporter/ssas-monitoring-xevents.xmla` یک template برای Session شامل `AuditLogin`، `AuditLogout`، `AuditServerStartsAndStops`، `AuditObjectPermissionEvent`، `AuditAdminOperationsEvent`، `ProgressReportEnd`، `QueryEnd` و `Error` است. مسیر XEL را بازبینی و XMLA را از یک connection نوع Analysis Services در SSMS اجرا کنید. نام event/action در بعضی buildهای قدیمی متفاوت است؛ در آن حالت session معادل را در **Management > Extended Events** بسازید و با Script خروجی همان نسخه را جایگزین template کنید.

`Collect-SsasXEventMetrics.ps1` به ماژول PowerShell `SqlServer` و cmdlet `Read-SqlXEvent` نیاز دارد. موقعیت خواندن هر فایل و counterهای تجمعی در `state/ssas-xevents-state.json` نگه‌داری می‌شوند. حذف این فایل باعث reset شدن counterها و احتمال بازخوانی XEL می‌شود.

جزئیات username، client، application، database و متن event فقط در `C:\ProgramData\Observability\SSAS\audit\ssas-security-audit.jsonl` نوشته می‌شوند تا به WEC/SIEM منتقل شوند؛ هیچ username یا IP به label پرومتئوس تبدیل نمی‌شود.

## پوشش متریک‌ها

- Availability: `ssas_service_running`، `ssas_service_uptime_seconds`، `ssas_service_restarts_total`، `ssas_endpoint_up`، `ssas_endpoint_response_seconds`، `ssas_readonly_probe_success` و response time.
- Connection/Session: متریک‌های `ssas_active_*`، long/idle، تفکیک database/application و counterهای total/rate اتصال.
- Security history: `ssas_logins_total`، `ssas_logouts_total`، failure، permission/admin operation و privileged change.
- Privilege: server admin، implicit Local Admin، service account direct admin و role memberهای admin/process/readwrite.
- Processing/Backup: LastProcessed هر database، آخرین Processing موفق، مدت آخرین Processing، failure total و آخرین Backup از xEvent یا فایل ABF.
- Performance: Query rate/duration/failure، cache، lock/wait، thread pool، processing rows/partition، DirectQuery، memory usage/limits/pressure و reliability.
- Tabular capacity: `ssas_tabular_object_size_bytes`، `ssas_database_size_bytes`، row و segment count به تفکیک database/table_id/column_id.
- Database memory: `ssas_database_memory_bytes` و `ssas_memory_object_usage_bytes` از `DISCOVER_OBJECT_MEMORY_USAGE` (با fallback برای نام DMV).
- Host capacity: CPU، Working Set/Private Bytes، page fault، disk latency/IOPS و free space از collectorهای استاندارد `process`، `cpu`، `memory` و `logical_disk` ویندوز.

Thresholdهای rule شامل ۲۴ ساعت برای Processing، ۴۸ ساعت برای Backup و افزایش ۵۰٪ مدت Processing نمونه هستند و باید با SLA هر مدل تنظیم شوند.

مراجع رسمی: [Performance Counterهای SSAS](https://learn.microsoft.com/en-us/analysis-services/instances/performance-counters-ssas?view=sql-analysis-services-2025)، [DMVهای Analysis Services](https://learn.microsoft.com/en-us/analysis-services/instances/use-dynamic-management-views-dmvs-to-monitor-analysis-services?view=asallproducts-allversions)، [SSAS Extended Events](https://learn.microsoft.com/en-us/analysis-services/instances/monitor-analysis-services-with-sql-server-extended-events?view=sql-analysis-services-2025)، [Security Audit Events](https://learn.microsoft.com/en-us/analysis-services/trace-events/security-audit-event-category?view=sql-analysis-services-2025) و [Server Administrator](https://learn.microsoft.com/en-us/analysis-services/instances/grant-server-admin-rights-to-an-analysis-services-instance?view=sql-analysis-services-2025).
