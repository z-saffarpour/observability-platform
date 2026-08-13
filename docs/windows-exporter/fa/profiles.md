# Profileهای نقش‌محور windows_exporter

[English](../en/profiles.md)

Profile قابلیت داخلی windows_exporter نیست؛ هر Profile یک فایل YAML کامل است که با
`--config.file` انتخاب می‌شود.

| Profile | کاربرد |
|---|---|
| `windows-base.yml` | سرور Windows بدون نقش Data Platform |
| `windows-cluster.yml` | Node کلاستر بدون نقش Data Platform |
| `sql-server.yml` | SQL Server مستقل |
| `ssas.yml` | SSAS Tabular یا Multidimensional |
| `powerbi-report-server.yml` | Power BI Report Server |
| `data-platform.yml` | چند نقش SQL/SSAS/PBIRS روی یک سرور |
| `data-platform-cluster.yml` | Node کلاستر با یک یا چند نقش Data Platform |
| `dynamics-ax-2012.yml` | Microsoft Dynamics AX 2012 AOS |
| `d365-finance-operations.yml` | D365 Finance & Operations On-premises / Service Fabric |
| `dynamics-platform.yml` | سرور دارای اجزای AX 2012 و D365 |
| `terminal-server.yml` | Remote Desktop Session Host / Terminal Server |

## Terminal Server

Profile ترمینال سرور collector اختصاصی `terminal_services` را همراه با CPU، Memory،
Page File، Disk، Network و TCP فعال می‌کند. سرویس‌های اصلی RDS از جمله `TermService`،
`SessionEnv`، `UmRdpService` و سرویس‌های Connection Broker/Gateway نیز جمع‌آوری می‌شوند.

Recording Ruleهای تعداد Session فعال و disconnected اضافه شده‌اند. Alertهای پیش‌فرض
در `prometheus/alert-rules/windows-exporter/windows_exporter-role-terminal.rules.yml` هستند و با پروفایل
`prometheus/scrape-configs/windows-exporter/terminal.yml` به `rule_files` اضافه می‌شوند. Threshold پیش‌فرض
برای Sessionهای disconnected برابر ۲۰ مورد به‌مدت ۳۰ دقیقه است و باید بر اساس ظرفیت
سرور، تعداد کاربران و Group Policy مربوط به Sessionها تنظیم شود. Sessionهای سیستمی با
`user=""` در شمارش لحاظ نمی‌شوند.

## Microsoft Dynamics

داشبورد Grafana نقش‌محور: `grafana/dashboards/winexp-00-d365.json` (UID: `winexp-00-d365`).

در AX 2012 سرویس‌های `AOS60$<instance>` و پردازش `Ax32Serv` مانیتور می‌شوند.
در D365 Finance & Operations On-premises، سرویس‌های میزبان Service Fabric و پردازش‌های
`Fabric*` و `Microsoft.Dynamics.AX.*` جمع‌آوری می‌شوند. `W3SVC`، `WAS` و `w3wp` نیز برای
Nodeهایی که Web workload دارند در Profile قرار گرفته‌اند.

Service Fabric با Windows Failover Cluster متفاوت است. فعال‌کردن Profile D365 به معنی
فعال‌شدن collector `mscluster` نیست. برای سلامت دقیق AOS، Batch، DMF، Reporting و
Replicaها باید علاوه بر windows_exporter، health مربوط به Service Fabric/LCS یا یک
textfile collector سفارشی نیز اضافه شود.

تشخیص `FabricHostSvc` در اسکریپت به معنی وجود Service Fabric است؛ اگر سرور Service
Fabric غیرمرتبط با D365 دارد، Profile پیشنهادی باید دستی بازبینی شود.

## تشخیص نقش

تشخیص بر اساس Service Name انجام می‌شود و تغییری روی سرور ایجاد نمی‌کند:

```powershell
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1 -ComputerName SQL01,SQL02 -Credential (Get-Credential)
```

Profile پیشنهادی را قبل از rollout بازبینی کنید. جزئیات پارامترها و چک‌لیست در [راهنمای نصب و آپگرید](install-upgrade-guide.md) آمده است. از کلاینت، پس از تأیید، نصب یا آپگرید را با `-Profile` یا `-AutoProfile` انجام دهید:

```powershell
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 -Computers SQL01 -Profile sql-server.yml -RemoteCredential (Get-Credential)
.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 -Computers SQL01 -Profile sql-server.yml -RemoteCredential (Get-Credential)
```

وجود `ClusSvc` باعث انتخاب Profile کلاستر می‌شود. بدون `-Profile` / `-AutoProfile`،
آپگرید `profiles/` و `scripts/` را به‌روز می‌کند و `textfile_inputs/` را تضمین می‌کند،
اما `--config.file` فعلی را حفظ می‌کند. برای تغییر Profile سرویس موجود، مسیر
`--config.file` در ImagePath سرویس را تغییر دهید و سپس سرویس را restart کنید.

Collectorهای `cpu_info` و `diskdrive` به‌علت وابستگی به WMI در Profileهای production
فعال نشده‌اند. در صورت نیاز، ابتدا با همان حساب سرویس روی canary تست و سپس اضافه شوند؛
خطای دسترسی WMI ممکن است startup exporter را متوقف کند.

## SSAS و Power BI Report Server

برای SSAS، Profileهای `ssas.yml`، `data-platform.yml` و `data-platform-cluster.yml` علاوه بر سرویس و process، collector `textfile` را روی مسیر `textfile_inputs` فعال می‌کنند. متریک‌های DMV/AMO، Performance Counter و XEvent توسط Scheduled Task جداگانه نوشته می‌شوند؛ راهنمای نصب در [مانیتورینگ SSAS](ssas-monitoring.md) آمده است. نصب ریموت windows_exporter اسکریپت‌ها را مستقر می‌کند اما Task مربوط به SSAS را ایجاد نمی‌کند.

نام Performance Counter Object به نسخه، زبان سیستم و Instance وابسته است. ابتدا روی
یک سرور canary کشف انجام دهید:

```powershell
.\scripts\powershell\windows-exporter\Discover-PerformanceCounters.ps1 -OutputPath .\performance-counters.csv
```

پس از تست مسیرها با `Get-Counter`، از `profiles/performancecounter.example.yml` به‌عنوان
قالب استفاده کنید و `performancecounter` را به `collectors.enabled` همان Profile
اضافه کنید. collector فقط نام انگلیسی Counterها را پشتیبانی می‌کند. فایل example
به‌تنهایی قابل استقرار نیست.

## کنترل پس از استقرار

```powershell
Get-Service windows_exporter
Invoke-WebRequest http://localhost:9182/health
Invoke-WebRequest http://localhost:9182/metrics
```

در Prometheus موارد زیر بررسی شوند:

- `up{job=~"windows.*"} == 1`
- `windows_exporter_collector_success == 1`
- وجود metricهای `windows_mssql_*` روی SQL Server
- وجود metricهای `ssas_*` روی سرورهای SSAS پس از نصب Task collector
- وجود metricهای `windows_mscluster_*` فقط روی Nodeهای Cluster

Ruleهای Cluster، سرویس‌های Data Platform، Host، MSSQL و بسته‌های نقش در
`prometheus/alert-rules/windows-exporter/` با پیشوند اولویت (`p0` / `p1` / `p2`) و نقش (`role-*`) قرار دارند.
پروفایل‌های آمادهٔ `rule_files` در `prometheus/scrape-configs/windows-exporter/` هستند. Alertهای SSAS در
`prometheus/alert-rules/windows-exporter/windows_exporter-role-ssas.rules.yml` هستند. کاتالوگ کامل:
[Alerting](alerting.md). قبل از فعال‌سازی سراسری، نام metricها روی canary و سازگاری
Ruleها با Prometheus بررسی شود.
