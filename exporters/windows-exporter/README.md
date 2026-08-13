# windows_exporter — مانیتورینگ Windows Server

[English](README_en.md) | [مستندات کامل](../../docs/windows-exporter/README.md)

پکیج استاندارد **windows_exporter 0.31.8** برای جمع‌آوری متریک‌های سیستم‌عامل، دیسک، شبکه، سرویس‌ها، پردازش‌ها، Terminal Services، SQL Server و نقش‌های مرتبط Data Platform است.

پورت scrape پیش‌فرض: **`9182`** — مسیر: **`/metrics`** (Basic Auth به‌صورت پیش‌فرض غیرفعال است)

## محتویات

| مسیر | کاربرد |
|---|---|
| `windows_exporter.exe` | باینری نسخه 0.31.8 |
| `windows_exporter.yml` | collectorها، logging، telemetry و listen address |
| `web-config.yml` | Basic Auth و تنظیمات اختیاری TLS |
| `prometheus/alert-rules/windows-exporter/` | recording و alerting ruleها (P0/P1/P2 و بسته‌های نقش) |
| `prometheus/scrape-configs/windows-exporter/` | پروفایل‌های آمادهٔ `rule_files` بر اساس اولویت و نقش |
| `alertmanager/windows-exporter/` | routing اولویت‌دار برای SMS و Email |
| `profiles/` | Profileهای نقش‌محور Windows، SQL، SSAS، PBIRS، Dynamics، Terminal Server و Cluster |
| `scripts/` | تشخیص نقش، نصب/آپگرید ریموت، دسترسی‌ها، collectorهای SSAS و همگام‌سازی داشبورد |
| `textfile_inputs/` | خروجی `.prom` collectorهای سفارشی (روی سرور مقصد هنگام نصب/آپگرید ساخته می‌شود) |
| `../../docs/windows-exporter/fa/` | مستندات فارسی |
| `../../docs/windows-exporter/en/` | مستندات انگلیسی |

## اجرای آزمایشی

```powershell
.\windows_exporter.exe `
  --config.file=.\windows_exporter.yml `
  --web.config.file=.\web-config.yml
```

## انتخاب Profile

روی خود سرور:

```powershell
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1
.\windows_exporter.exe --config.file=.\profiles\sql-server.yml --web.config.file=.\web-config.yml
```

از کلاینت، با WinRM (exporter را روی کلاینت اجرا نکنید):

```powershell
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1 -ComputerName SQL01,SQL02 -Credential (Get-Credential)

.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01,SQL02 `
  -Profile sql-server.yml `
  -RemoteCredential (Get-Credential)
```

برای سرورهای دارای چند نقش از `data-platform.yml` و برای Nodeهای Windows Cluster از
`data-platform-cluster.yml` استفاده کنید. جزئیات در
[`../../docs/windows-exporter/fa/profiles.md`](../../docs/windows-exporter/fa/profiles.md) آمده است.

> وجود `web-config.yml` به‌تنهایی احراز هویت را فعال نمی‌کند؛ آرگومان `--web.config.file` باید در ImagePath سرویس وجود داشته باشد.
> راهنمای کامل ایجاد bcrypt، فعال‌سازی Basic Auth و نمونه scrape_config: [`../../docs/windows-exporter/fa/install-config-guide.md`](../../docs/windows-exporter/fa/install-config-guide.md#basic-auth-اختیاری).

## بررسی سلامت

```powershell
Invoke-WebRequest http://localhost:9182/metrics
```

اگر Basic Auth فعال باشد:

```powershell
$cred = Get-Credential
Invoke-WebRequest http://localhost:9182/metrics -Credential $cred
```

متریک‌های مهم سلامت:

- `up` در Prometheus برای دسترس‌پذیری target
- `windows_exporter_collector_success` برای موفقیت هر collector
- `windows_exporter_collector_duration_seconds` برای زمان اجرای collector

## نکات نسخه 0.31.8

- کانفیگ در startup اعتبارسنجی می‌شود و کلید ناشناخته باعث توقف exporter می‌شود.
- `telemetry.max-requests` دیگر معتبر نیست.
- collector قدیمی `logon` با `terminal_services` جایگزین شده است.
- قبل از rollout روی همه سرورها، روی یک سرور آزمایشی اجرا و ruleها و dashboardها از نظر نام metric بررسی شوند.

## نصب و آپگرید ریموت

جزئیات کامل، پارامترها و چک‌لیست rollout در
[`../../docs/windows-exporter/fa/install-upgrade-guide.md`](../../docs/windows-exporter/fa/install-upgrade-guide.md)
([HTML](../../docs/windows-exporter/fa/install-upgrade-guide.html))
آمده است. خلاصه:

```powershell
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 `
  -WhatIf

.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)

.\scripts\powershell\windows-exporter\Uninstall-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 `
  -WhatIf
```

هر دو اسکریپت مبتنی بر WinRM هستند و به دسترسی Administrator نیاز دارند. نصب idempotent است؛ `profiles/` و `scripts/` را deploy می‌کند، `collector/` و `textfile_inputs/` را می‌سازد، Native/NSSM را تشخیص می‌دهد، بکاپ می‌گیرد و در صورت شکست rollback می‌کند. جمع‌آوری SSAS جداگانه با `Install-SsasMetricsTask.ps1` به‌صورت سرویس ویندوز `prometheus_windows_ssas` نصب می‌شود و تنظیمات آن در `collector/ssas-collector.json` قرار می‌گیرد.

نصب‌کننده، Event Source با نام `prometheus_windows_ssas` را در لاگ Application ثبت می‌کند؛ بنابراین رویدادهای چرخه اجرا و خطاهای Collector با نام سرویس دیده می‌شوند. رویدادهای داخلی Wrapper در NSSM به‌علت نام کامپایل‌شده آن همچنان Source برابر `nssm` دارند. اگر وجود هیچ رویدادی با این Source قابل قبول نیست، حالت پیش‌فرض `ServiceBase` را انتخاب کنید.

برای نصب و حذف ریموت SSAS از `Install-SsasMetricsRemote.ps1` و `Uninstall-SsasMetricsRemote.ps1` استفاده کنید. Uninstall به‌صورت پیش‌فرض فایل‌های مشترک windows_exporter را حفظ می‌کند؛ گزینه `-RemoveFiles` فقط فایل‌های اختصاصی SSAS را پس از بکاپ حذف می‌کند. نمونه‌های کامل در [راهنمای SSAS](../../docs/windows-exporter/fa/ssas-monitoring.md#چرخه-نصب-و-حذف-ریموت-سرویس) قرار دارند.

## دسترسی‌های لازم

```powershell
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -ShowRequirements
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1
```

`Set-WindowsExporterRequiredAccess.ps1` برای ایجاد ACL، Firewall و در صورت نیاز حق Log on as a service / Performance Monitor Users است؛ `Test-WindowsExporterRequiredAccess.ps1` برای audit. جزئیات در [`../../docs/windows-exporter/fa/install-upgrade-guide.md`](../../docs/windows-exporter/fa/install-upgrade-guide.md).

## راهنماها

- [نصب، آپگرید و حذف](../../docs/windows-exporter/fa/install-upgrade-guide.md) ([HTML](../../docs/windows-exporter/fa/install-upgrade-guide.html))
- [نصب و تنظیمات](../../docs/windows-exporter/fa/install-config-guide.md) ([Basic Auth](../../docs/windows-exporter/fa/install-config-guide.md#basic-auth-اختیاری))
- [راهنمای collectorها](../../docs/windows-exporter/fa/collector-guide.md)
- [Profileهای نقش‌محور](../../docs/windows-exporter/fa/profiles.md)
- [مانیتورینگ SSAS](../../docs/windows-exporter/fa/ssas-monitoring.md)
- [Prometheus و Alertها](../../docs/windows-exporter/fa/prometheus-rules.md)
- [پوشه prometheus/](../../docs/windows-exporter/fa/prometheus.md)
- [کاتالوگ Alertها](../../docs/windows-exporter/fa/alerting.md)
- [Alertmanager](../../docs/windows-exporter/fa/alertmanager.md)
- [عیب‌یابی](../../docs/windows-exporter/fa/troubleshooting.md)
