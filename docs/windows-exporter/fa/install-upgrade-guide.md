# راهنمای نصب، آپگرید و حذف windows_exporter

[English](../en/install-upgrade-guide.md) · [HTML فارسی](install-upgrade-guide.html) · [HTML English](../en/install-upgrade-guide.html)

این راهنما نصب و آپگرید **ریموت** (WinRM) تا نسخه **0.31.8** را پوشش می‌دهد. پورت scrape پیش‌فرض: **9182** (Basic Auth غیرفعال).

برای نصب دستی سرویس روی خود سرور، Firewall، **ایجاد و فعال‌سازی Basic Auth** و نمونه `scrape_config` به [راهنمای نصب و تنظیمات](install-config-guide.md#basic-auth-اختیاری) مراجعه کنید.

## پیش‌نیازها

| مورد | توضیح |
|---|---|
| کلاینت | PowerShell 5.1+؛ پکیج کامل در مسیر محلی (exe، yml، `profiles/`، اسکریپت‌ها) |
| مقصد | Windows Server 2016+؛ Administrator؛ WinRM/PowerShell Remoting فعال |
| شبکه | دسترسی کلاینت به مقصد روی WinRM؛ دسترسی Prometheus به TCP/9182 |
| پکیج | `windows_exporter.exe`، `windows_exporter.yml`، `web-config.yml`، `profiles/`، `scripts/powershell/windows-exporter/` (و در صورت وجود `scripts/ssas/windows-exporter/`) |

اسکریپت‌ها را **از کلاینت** اجرا کنید؛ `windows_exporter.exe` را روی کلاینت start نکنید.

```powershell
# تست WinRM قبل از نصب
Test-WSMan -ComputerName SERVER01
```

## دسترسی‌های لازم

ماتریس دسترسی، ایجاد ACL/Firewall/حقوق حساب، سپس audit:

```powershell
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -ShowRequirements
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20 -WhatIf
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 `
  -ComputerName SQL01 `
  -Credential (Get-Credential) `
  -ServiceAccount 'DOMAIN\svc-winexporter$' `
  -PrometheusRemoteAddress 10.10.10.20 `
  -GrantPerformanceMonitorUsers
```

`Set-WindowsExporterRequiredAccess.ps1` دسترسی را ایجاد می‌کند؛ `Test-WindowsExporterRequiredAccess.ps1` نتیجه را بررسی می‌کند. حق Admin داخل SSAS جداگانه در Analysis Services تنظیم می‌شود.

## انتخاب Profile

| روش | پارامتر | رفتار |
|---|---|---|
| پیش‌فرض نصب | بدون `-Profile` | `windows_exporter.yml` در ریشه نصب |
| ثابت | `-Profile sql-server.yml` | کانفیگ نقش از `profiles/` |
| خودکار | `-AutoProfile` | کشف نقش با `Discover-WindowsExporterRole.ps1` روی هر سرور |
| آپگرید بدون تغییر | بدون `-Profile` / `-AutoProfile` | `--config.file` فعلی حفظ می‌شود؛ `profiles/` و `scripts/` به‌روز و `textfile_inputs/` تضمین می‌شود |

`-Profile` و `-AutoProfile` را هم‌زمان استفاده نکنید. جزئیات نقش‌ها: [Profileهای نقش‌محور](profiles.md). برای سرورهای SSAS پس از نصب exporter، Task جمع‌آوری متریک را طبق [مانیتورینگ SSAS](ssas-monitoring.md) جداگانه نصب کنید.

```powershell
# کشف نقش (محلی یا ریموت)
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1
.\scripts\powershell\windows-exporter\Discover-WindowsExporterRole.ps1 -ComputerName SQL01,SQL02 -Credential (Get-Credential)
```

## نصب ریموت

اسکریپت: `scripts/powershell/windows-exporter/Install-WindowsExporterRemote.ps1`

### چه کاری انجام می‌دهد

1. فایل‌های پکیج، `profiles/` و `scripts/` (powershell + ssas) را از کلاینت کپی می‌کند و پوشه `textfile_inputs` را می‌سازد
2. از فایل‌های موجود بکاپ timestamped می‌گیرد (`_backup\install_...`)
3. سرویس native `windows_exporter` را ایجاد یا ImagePath را به‌روز می‌کند
4. حساب سرویس را تنظیم و سرویس را start می‌کند
5. اجرای مجدد برای refresh فایل‌ها امن است (idempotent)

> نصب exporter به‌تنهایی سرویس متریک SSAS را ایجاد نمی‌کند. پس از نصب با Profile مربوط به SSAS، روی سرور `Install-SsasMetricsTask.ps1` را با دسترسی Administrator اجرا کنید تا سرویس `prometheus_windows_ssas` نصب شود. جزئیات: [مانیتورینگ SSAS](ssas-monitoring.md).

مسیر پیش‌فرض نصب:

```text
C:\Program Files\Observability\PrometheusExporters\windows-exporter
```

### پارامترهای مهم

| پارامتر | پیش‌فرض | توضیح |
|---|---|---|
| `-Computers` | (الزامی) | نام سرورها یا لیست از فایل |
| `-SourceRoot` | ریشه پکیج | مسیر پکیج روی کلاینت |
| `-InstallRoot` | مسیر Program Files بالا | مسیر نصب روی مقصد |
| `-Profile` / `-AutoProfile` | — | انتخاب کانفیگ نقش |
| `-ServiceAccountMode` | `LocalSystem` | `LocalSystem`، `LocalService`، `NetworkService`، `Credential`، `gMSA`، `NtService` |
| `-ServiceCredential` | — | برای حالت `Credential` |
| `-ServiceAccount` | — | gMSA با پسوند `$`؛ برای `NtService` اختیاری به‌صورت `NT SERVICE\<ServiceName>` |
| `-RemoteCredential` | — | credential WinRM به مقصد |
| `-ServiceTimeoutSec` | `60` | مهلت انتظار برای Stop/Start سرویس |
| `-WhatIf` | — | شبیه‌سازی بدون تغییر |

### نمونه‌ها

```powershell
# شبیه‌سازی
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 `
  -WhatIf

# نصب از لیست سرورها
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)

# Profile ثابت برای SQL
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01,SQL02 `
  -Profile sql-server.yml `
  -RemoteCredential (Get-Credential)

# کشف خودکار Profile روی هر سرور
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01,APP01 `
  -AutoProfile `
  -RemoteCredential (Get-Credential)

# حساب سرویس دامینی
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01 `
  -Profile sql-server.yml `
  -ServiceAccountMode Credential `
  -ServiceCredential (Get-Credential) `
  -RemoteCredential (Get-Credential)

# gMSA
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01 `
  -ServiceAccountMode gMSA `
  -ServiceAccount 'DOMAIN\svc-winexporter$' `
  -RemoteCredential (Get-Credential)

# Virtual service account (NT SERVICE\windows_exporter)
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SQL01 `
  -ServiceAccountMode NtService `
  -RemoteCredential (Get-Credential)
# پس از NtService، ACL مسیر نصب را برای حساب مجازی تنظیم کنید:
# .\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -ComputerName SQL01 -Credential (Get-Credential) -ServiceAccount 'NT SERVICE\windows_exporter'
```

## آپگرید ریموت

اسکریپت: `scripts/powershell/windows-exporter/Upgrade-WindowsExporterRemote.ps1`

### چه کاری انجام می‌دهد

1. نصب **Native** یا **NSSM** و مسیر باینری را خودکار تشخیص می‌دهد
2. قبل از جایگزینی بکاپ می‌گیرد (`_backup\upgrade_<version>_...`)
3. exe، ymlها، `profiles/` و `scripts/` را به‌روز می‌کند و `textfile_inputs` را تضمین می‌کند
4. نسخه نصب‌شده را با `-ExpectedVersion` (پیش‌فرض `0.31.8`) مطابقت می‌دهد
5. در صورت شکست validation یا startup، فایل‌ها (و در صورت تغییر Profile، ImagePath/AppParameters) را rollback می‌کند
6. بکاپ‌های قدیمی upgrade را تا `-KeepBackups` نگه می‌دارد (پیش‌فرض 5)

### پارامترهای مهم

| پارامتر | پیش‌فرض | توضیح |
|---|---|---|
| `-Computers` | (الزامی) | سرورهای هدف |
| `-ExpectedVersion` | `0.31.8` | نسخه مورد انتظار باینری پکیج و پس از نصب |
| `-InstallRoot` | (تشخیص خودکار) | فقط اگر مسیر exe قابل تشخیص نباشد |
| `-Profile` / `-AutoProfile` | حفظ فعلی | تغییر `--config.file` |
| `-ServiceAccountMode` | حفظ فعلی | `LocalSystem`، `LocalService`، `NetworkService`، `Credential`، `gMSA`، `NtService` |
| `-ServiceCredential` | — | برای حالت `Credential` |
| `-ServiceAccount` | — | gMSA با پسوند `$`؛ برای `NtService` اختیاری به‌صورت `NT SERVICE\<ServiceName>` |
| `-KeepBackups` | `5` | تعداد بکاپ‌های `upgrade_*` |
| `-RemoteCredential` | — | credential WinRM |
| `-ServiceTimeoutSec` | `60` | مهلت انتظار برای Stop/Start سرویس |
| `-WhatIf` | — | شبیه‌سازی |

### نمونه‌ها

```powershell
# شبیه‌سازی
.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 `
  -WhatIf

# آپگرید با حفظ Profile فعلی
.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)

# آپگرید + تغییر Profile
.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers SQL01,SQL02 `
  -Profile sql-server.yml `
  -RemoteCredential (Get-Credential)

# آپگرید + AutoProfile
.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers SQL01,SQL02 `
  -AutoProfile `
  -RemoteCredential (Get-Credential)

# نسخه پکیج جدیدتر از پیش‌فرض اسکریپت
.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers SERVER01 `
  -ExpectedVersion 0.32.0 `
  -RemoteCredential (Get-Credential)

# آپگرید + تغییر حساب به NT SERVICE\windows_exporter
.\scripts\powershell\windows-exporter\Upgrade-WindowsExporterRemote.ps1 `
  -Computers SQL01 `
  -ServiceAccountMode NtService `
  -RemoteCredential (Get-Credential)
```

## حذف ریموت

اسکریپت: `scripts/powershell/windows-exporter/Uninstall-WindowsExporterRemote.ps1`

این اسکریپت از WinRM استفاده می‌کند، نوع `ServiceBase` یا `NSSM` را تشخیص می‌دهد، سرویس `prometheus_windows_exporter` را متوقف و حذف می‌کند و در صورت درخواست فایل‌ها را نیز پاک می‌کند. اگر `-SkipBackup` داده نشود، ابتدا یک ZIP در `C:\ProgramData\Observability\PrometheusExporters\uninstall-backups` می‌سازد. Event Source به‌صورت پیش‌فرض حفظ می‌شود تا رخدادهای قبلی Event Viewer قابل خواندن بمانند.

```powershell
# فقط شبیه‌سازی
.\scripts\powershell\windows-exporter\Uninstall-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 -WhatIf

# حذف سرویس و فایل‌های نصب با حفظ Event Source
.\scripts\powershell\windows-exporter\Uninstall-WindowsExporterRemote.ps1 `
  -Computers SERVER01,SERVER02 `
  -ServiceMode Preserve `
  -RemoteCredential (Get-Credential)

# فقط حذف سرویس و حفظ فایل‌ها
.\scripts\powershell\windows-exporter\Uninstall-WindowsExporterRemote.ps1 `
  -Computers SERVER01 -KeepFiles
```

سوییچ‌های مهم: `-KeepFiles`، `-SkipBackup` و `-RemoveEventSource`. گزینه آخر فقط زمانی استفاده شود که دیگر به Source ثبت‌شده رخدادهای قبلی Application نیاز نیست.

## ترتیب پیشنهادی rollout

1. روی **یک سرور آزمایشی** با `-WhatIf` سپس نصب/آپگرید واقعی
2. `Get-Service windows_exporter` و `/metrics` را بررسی کنید
3. در Prometheus مقدار `up` و `windows_exporter_collector_success` را کنترل کنید
4. dashboard و ruleها را از نظر نام metric نسخه جدید بررسی کنید
5. سپس روی بقیه سرورها rollout کنید

## کنترل پس از نصب / آپگرید

```powershell
Get-Service windows_exporter
Get-CimInstance Win32_Service -Filter "Name='windows_exporter'" |
  Select-Object Name, State, StartName, PathName

.\windows_exporter.exe --version

Invoke-WebRequest http://localhost:9182/metrics
```

از سرور Prometheus:

```powershell
Test-NetConnection SERVER01 -Port 9182
```

متریک‌های سلامت:

- `up` — دسترس‌پذیری target
- `windows_exporter_collector_success` — موفقیت هر collector
- `windows_exporter_collector_duration_seconds` — زمان اجرای collector

## نکات نسخه 0.31.8

- کانفیگ در startup اعتبارسنجی می‌شود؛ کلید ناشناخته باعث توقف سرویس می‌شود
- `telemetry.max-requests` معتبر نیست
- collector قدیمی `logon` با `terminal_services` جایگزین شده است
- وجود `web-config.yml` به‌تنهایی کافی نیست؛ `--web.config.file` باید در ImagePath باشد

## عیب‌یابی سریع

| علامت | اقدام |
|---|---|
| خطای WinRM / دسترسی | `Test-WSMan`؛ `Test-WindowsExporterRequiredAccess.ps1`؛ در صورت نیاز `Set-WindowsExporterRequiredAccess.ps1` |
| سرویس start نمی‌شود | Event Log Application؛ اجرای دستی با همان آرگومان‌های ImagePath |
| نسخه mismatch در آپگرید | تطابق `-ExpectedVersion` با `--version` باینری پکیج |
| آپگرید شکست + rollback | پیام خطا علت را نشان می‌دهد؛ بکاپ در `_backup\upgrade_...` |
| 401 روی `/metrics` | فقط اگر Basic Auth فعال باشد: hash/رمز و وجود `--web.config.file` را بررسی کنید |

جزئیات بیشتر: [عیب‌یابی](troubleshooting.md).

## مستندات مرتبط

- [نصب و تنظیمات دستی / Basic Auth](install-config-guide.md#basic-auth-اختیاری)
- [دسترسی‌های لازم (Set/Test)](#دسترسیهای-لازم)
- [Profileهای نقش‌محور](profiles.md)
- [مانیتورینگ SSAS](ssas-monitoring.md)
- [Prometheus و Alertها](prometheus-rules.md)
- [عیب‌یابی](troubleshooting.md)
