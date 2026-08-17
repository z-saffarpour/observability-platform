# راهنمای نصب، ارتقا و حذف `sql_exporter`

این سند مراحل **نصب اولیه**، **ارتقای نسخه** و **حذف امن ریموت** `sql_exporter` روی سرورهای SQL Server را پوشش می‌دهد.

نسخه مستند و اعتبارسنجی‌شده در این پروژه: **0.24.4**

برای جزئیات کانفیگ، پروفایل collector و عیب‌یابی، ببینید: [راهنمای نصب و کانفیگ](install-config-guide.md)

نسخه HTML (مناسب مرورگر / چاپ): [install-upgrade-guide.html](install-upgrade-guide.html)

---

## کدام اسکریپت را استفاده کنم؟

| هدف | اسکریپت | توضیح |
|-----|---------|--------|
| نصب تازه یا نصب/به‌روزرسانی سرویس از صفر | `scripts/powershell/sql-exporter/Install-SqlExporterRemote.ps1` | سرویس را می‌سازد یا به‌روز می‌کند؛ مسیر نصب پیش‌فرض را می‌داند |
| ارتقای نسخه روی نصب موجود | `scripts/powershell/sql-exporter/Upgrade-SqlExporterRemote.ps1` | مسیر exe را از سرویس تشخیص می‌دهد؛ بکاپ می‌گیرد؛ در خطا rollback می‌کند |
| حذف سرویس و در صورت نیاز فایل‌ها | `scripts/powershell/sql-exporter/Uninstall-SqlExporterRemote.ps1` | تشخیص ServiceBase/NSSM؛ بکاپ ZIP پیش‌فرض؛ پشتیبانی از `-WhatIf` |
| فقط کانفیگ / پروفایل (بدون تعویض باینری) | `scripts/powershell/sql-exporter/Deploy-SqlExporterConfig.ps1` | `sql_exporter.yml` (و در صورت `-Profile`، `profiles\`) را deploy می‌کند |
| فقط همگام‌سازی فایل‌های collector | `scripts/powershell/sql-exporter/Deploy-Collectors.ps1` | `-Layout Collector` (پیش‌فرض) یا `-Layout Root` — بخش بعد |
| Export داشبوردهای Grafana → repo | `scripts/powershell/sql-exporter/Export-GrafanaDashboards.ps1` | داشبوردهای زنده `sqlx-*` را در `grafana/dashboards/` می‌نویسد |

اسکریپت‌های Install / Upgrade / Deploy-Config از **WinRM** استفاده می‌کنند. `Deploy-Collectors` هم برای stop/start سرویس از WinRM استفاده می‌کند. `Export-GrafanaDashboards` به API گرافانا وصل می‌شود (`GRAFANA_URL` + `GRAFANA_SERVICE_ACCOUNT_TOKEN`).

---

## فقط همگام‌سازی collector (`Deploy-Collectors.ps1`)

پیش‌فرض با `sql_exporter.yml` هم‌خوان است (`collector_files: collector/*.collector.yml`).

| `-Layout` | رفتار |
|-----------|--------|
| `Collector` (پیش‌فرض) | کپی به `collector\` ریموت؛ حذف `*.collector.yml` از ریشه نصب |
| `Root` | کپی به ریشه نصب؛ حذف کامل پوشه `collector\` |

```powershell
# Layout پیش‌فرض (collector\)
.\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 -Computers sql-host-01,sql-host-02 -WhatIf

.\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -Layout Collector

# Layout ریشه (legacy)
.\scripts\powershell\sql-exporter\Deploy-Collectors.ps1 -Computers sql-host-01 -Layout Root
```

فیلترهای داخل اسکریپت:
- `ExcludeEverywhere` — هرگز deploy نمی‌شود؛ از ریموت هم پاک می‌شود
- `AllowOnlyOn` — فقط روی هاست‌های مشخص (مثلاً `mssql_restore` → `sql-host-02`)

---

## پیش‌نیازها

- دسترسی WinRM / PowerShell Remoting به سرور مقصد
- حسابی با حق نصب/مدیریت سرویس ویندوز روی مقصد
- فایل‌های پکیج در ریشه پروژه:
  - `sql_exporter.exe`
  - `sql_exporter.yml`
  - `web-config.yml`
  - `collector/*.collector.yml`
  - `profiles/*.yml`
- دسترسی SQL برای حساب اجرای سرویس (`VIEW SERVER STATE` و `VIEW ANY DEFINITION` در حداقل حالت)
- پورت scrape باز برای Prometheus (پیش‌فرض upstream: **9399**)

```powershell
# تست WinRM قبل از نصب
Test-WSMan -ComputerName sql-host-01
```

---

## دسترسی‌های لازم

ماتریس دسترسی، ایجاد ACL/Firewall/حقوق حساب، سپس audit؛ مجوز SQL جداگانه با اسکریپت T-SQL:

```powershell
.\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1 -ShowRequirements
.\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20 -WhatIf
.\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 -PrometheusRemoteAddress 10.10.10.20
.\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1
.\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 `
  -ComputerName sql-host-01 `
  -Credential (Get-Credential) `
  -ServiceAccount 'DOMAIN\SqlExporterAccount' `
  -PrometheusRemoteAddress 10.10.10.20 `
  -GrantLogonAsService
```

| نقش | دسترسی | ابزار |
|-----|--------|--------|
| اپراتور نصب/ارتقا | Administrator روی مقصد | حساب WinRM |
| کلاینت استقرار | WinRM / PowerShell Remoting | `Install-` / `Upgrade-` / `Deploy-*` |
| سرویس ویندوز | Read روی مسیر نصب و `web-config.yml` | `Set-SqlExporterRequiredAccess.ps1` |
| سرویس → SQL Server | `VIEW SERVER STATE`، `VIEW ANY DEFINITION` (+ اختیاری msdb/SSISDB/DBهای کاربر) | `scripts/sql/Create-SqlExporterLogin.sql` |
| Prometheus | TCP/**9399** (+ Basic Auth در صورت فعال بودن) | Firewall rule در `Set-…RequiredAccess.ps1` |

`Set-SqlExporterRequiredAccess.ps1` دسترسی ویندوز/شبکه را ایجاد می‌کند؛ `Test-SqlExporterRequiredAccess.ps1` نتیجه را بررسی می‌کند. مجوزهای داخل SQL Server با `Create-SqlExporterLogin.sql` (به‌عنوان sysadmin) داده می‌شوند — نه با اسکریپت‌های Set/Test.

جزئیات GRANTها و collectorهای وابسته: [راهنمای نصب و کانفیگ — دسترسی‌ها](install-config-guide.md#4-دسترسیها-را-بده).

---

## نصب اولیه (ریموت — پیشنهادی)

### ۱) Dry-run با WhatIf

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 -Computers sql-host-01,sql-host-02 -WhatIf
```

### ۲) اجرای واقعی

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)
```

### ۲ب) نصب با پروفایل collector

همان UX ویندوز اکسپورتر (`-Profile sql-server.yml`). پروفایل‌های SQL Exporter در `profiles/` هستند (مثلاً `oltp.yml`، `dwh.yml`):

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers OKDC34017 `
  -Profile oltp.yml `
  -RemoteCredential (Get-Credential)
```

پوشه `profiles\` کپی می‌شود و فهرست `collectors:` پروفایل داخل `sql_exporter.yml` نوشته می‌شود.

### ۳) آدرس Listen و Basic Auth (اختیاری)

اسکریپت‌های نصب ریموت `--web.listen-address` را تنظیم می‌کنند و `web-config.yml` را در آرگومان‌های سرویس deploy می‌کنند.

**آدرس Listen** — پیش‌فرض `:9399`. مثال: `:9399`، `127.0.0.1:9399`، `0.0.0.0:9399`.

**Basic Auth** — در پکیج پیش‌فرض غیرفعال است. برای فعال‌سازی هنگام نصب یکی از روش‌های زیر را بدهید:

| روش | پارامترها |
|-----|-----------|
| hash bcrypt آماده (پیشنهادی) | `-BasicAuthUsername` + `-BasicAuthHash` |
| hash از رمز روی کلاینت | `-BasicAuthUsername` + `-BasicAuthPassword` (نیاز به Python با ماژول `bcrypt` روی ماشینی که اسکریپت اجرا می‌شود) |
| فایل سفارشی | `-WebConfigPath` (مسیر کامل `web-config.yml`؛ با پارامترهای Basic Auth ترکیب نشود) |

```powershell
# نصب با پورت و Basic Auth (hash bcrypt)
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -ListenAddress ':9399' `
  -BasicAuthUsername 'scrape_user' `
  -BasicAuthHash '$2a$12$REPLACE_WITH_BCRYPT_HASH' `
  -RemoteCredential (Get-Credential)

# نصب با رمز (کلاینت باید Python + bcrypt داشته باشد)
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -ListenAddress '127.0.0.1:9399' `
  -BasicAuthUsername 'scrape_user' `
  -BasicAuthPassword (Read-Host -AsSecureString 'Password') `
  -RemoteCredential (Get-Credential)

# deploy فایل web-config.yml سفارشی
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -WebConfigPath 'C:\Secrets\sql-exporter-web-config.yml' `
  -RemoteCredential (Get-Credential)
```

راهنمای ساخت hash دستی و تنظیم Prometheus: [راهنمای نصب و کانفیگ — پورت scrape و Basic Auth](install-config-guide.md).

### ۴) حساب سرویس (اختیاری)

پیش‌فرض: `LocalSystem`

با credential دامنه:

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -ServiceAccountMode Credential `
  -ServiceCredential (Get-Credential 'DOMAIN\SqlExporterAccount')
```

با gMSA:

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -ServiceAccountMode gMSA `
  -ServiceAccount 'DOMAIN\SqlExporterAccount$'
```

### آنچه نصب می‌کند

- مسیر پیش‌فرض نصب:  
  `C:\Program Files\Observability\PrometheusExporters\sql-exporter`
- نام سرویس: `prometheus_sql_exporter`
- فایل‌ها: `sql_exporter.exe`، `sql_exporter.yml`، `web-config.yml`، `profiles\`، و پوشه `collector\` (مگر `-SkipCollectors`)
- Listen پیش‌فرض: `:9399`

### پارامترهای مهم نصب

| پارامتر | پیش‌فرض | کاربرد |
|---------|---------|--------|
| `-Computers` | لیست سرورهای نمونه در اسکریپت | هدف‌ها |
| `-SourceRoot` | ریشه پروژه | منبع پکیج |
| `-InstallRoot` | مسیر Program Files بالا | مسیر نصب روی مقصد |
| `-ServiceName` | `prometheus_sql_exporter` | نام سرویس ویندوز |
| `-ListenAddress` | `:9399` | آدرس/پورت scrape (`--web.listen-address`) |
| `-WebConfigPath` | (خالی) | deploy فایل `web-config.yml` سفارشی از کلاینت |
| `-BasicAuthUsername` | (خالی) | نام کاربر Basic Auth (با `-BasicAuthHash` یا `-BasicAuthPassword`) |
| `-BasicAuthHash` | (خالی) | hash bcrypt آماده |
| `-BasicAuthPassword` | (خالی) | رمز SecureString؛ روی کلاینت hash می‌شود (نیاز به Python + `bcrypt`) |
| `-Profile` | (خالی) | اعمال collectors از `profiles/<name>.yml` داخل `sql_exporter.yml` |
| `-ServiceAccountMode` | `LocalSystem` | نوع حساب سرویس |
| `-RemoteCredential` | (خالی) | اعتبار WinRM |
| `-SkipCollectors` | خاموش | عدم کپی پوشه collector |
| `-ServiceMode` | `ServiceBase` | روش میزبانی سرویس: `ServiceBase` یا `NSSM` |

---

## ارتقا (ریموت)

وقتی سرویس از قبل روی سرور هست و می‌خواهید به نسخه پکیج فعلی (مثلاً **0.24.4**) برسید، از اسکریپت ارتقا استفاده کنید.

### رفتار اسکریپت ارتقا

1. نسخه باینری منبع را با `-ExpectedVersion` مقایسه می‌کند
2. مسیر `sql_exporter.exe` را از سرویس تشخیص می‌دهد (Native یا NSSM)
3. از `sql_exporter.exe`، `sql_exporter.yml`، `web-config.yml`، `collector\` و `profiles\` بکاپ می‌گیرد
4. سرویس را متوقف می‌کند، باینری/web-config/collectors/profiles را جایگزین می‌کند، نسخه را تأیید می‌کند، سرویس را استارت می‌کند
5. بدون `-Profile`، collectors داخل `sql_exporter.yml` ریموت دست‌نخورده می‌ماند؛ با `-Profile` فقط collectors اعمال می‌شود و DSN حفظ می‌شود
6. اگر استارت یا تأیید نسخه شکست بخورد، فایل‌ها را از بکاپ برمی‌گرداند
7. بکاپ‌های قدیمی‌تر از `-KeepBackups` را پاک می‌کند (پیش‌فرض: ۵)

مسیر بکاپ نمونه:

```text
<InstallPath>\_backup\upgrade_<oldVersion>_yyyyMMdd_HHmmss\
```

### ۱) Dry-run

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 -Computers sql-host-01,sql-host-02 -WhatIf
```

### ۲) ارتقای واقعی

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers (Get-Content .\servers.txt) `
  -RemoteCredential (Get-Credential)
```

### ۲ب) ارتقا و تنظیم پروفایل collector

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers OKDC34017 `
  -Profile oltp.yml `
  -RemoteCredential (Get-Credential)
```

### ۳) اگر مسیر exe از سرویس پیدا نشد

```powershell
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -InstallRoot 'D:\Monitoring\sql_exporter'
```

### ۴) آدرس Listen و Basic Auth (اختیاری)

در اپگرید، اگر `-ListenAddress` ندهید، آدرس از سرویس فعلی **حفظ** می‌شود. بدون پارامتر web-config، پیش‌فرض پکیج deploy می‌شود (Basic Auth خاموش). با `-PreserveWebConfig` فایل `web-config.yml` ریموت دست‌نخورده می‌ماند (با `-WebConfigPath` یا پارامترهای Basic Auth هم‌زمان استفاده نشود).

```powershell
# فقط باینری؛ حفظ listen و web-config.yml فعلی
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -PreserveWebConfig `
  -RemoteCredential (Get-Credential)

# تغییر پورت؛ حفظ Basic Auth موجود
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -ListenAddress ':9399' `
  -PreserveWebConfig `
  -RemoteCredential (Get-Credential)

# فعال‌سازی یا جایگزینی Basic Auth
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 `
  -Computers sql-host-01 `
  -BasicAuthUsername 'scrape_user' `
  -BasicAuthHash '$2a$12$REPLACE_WITH_BCRYPT_HASH' `
  -RemoteCredential (Get-Credential)
```

### پارامترهای مهم ارتقا

| پارامتر | پیش‌فرض | کاربرد |
|---------|---------|--------|
| `-Computers` | لیست نمونه در اسکریپت | هدف‌ها |
| `-SourceRoot` | ریشه پروژه | منبع پکیج |
| `-ExpectedVersion` | `0.24.4` | نسخه مورد انتظار باینری |
| `-ServiceName` | `prometheus_sql_exporter` | نام سرویس |
| `-InstallRoot` | (خالی = تشخیص خودکار) | اجبار مسیر نصب |
| `-ListenAddress` | (خالی = حفظ سرویس) | override `--web.listen-address` |
| `-WebConfigPath` | (خالی) | deploy `web-config.yml` سفارشی |
| `-BasicAuthUsername` / `-BasicAuthHash` / `-BasicAuthPassword` | (خالی) | فعال‌سازی یا جایگزینی Basic Auth |
| `-PreserveWebConfig` | خاموش | حفظ `web-config.yml` ریموت؛ با web-config/Basic Auth ترکیب نشود |
| `-Profile` | (خالی) | اعمال collectors از `profiles/<name>.yml`؛ بدون آن کانفیگ ریموت حفظ می‌شود |
| `-RemoteCredential` | (خالی) | اعتبار WinRM |
| `-ServiceTimeoutSec` | `60` | مهلت stop/start سرویس |
| `-KeepBackups` | `5` | تعداد بکاپ‌های نگه داشته‌شده |

### خروجی وضعیت

| Status | معنی |
|--------|------|
| `Upgraded` | نسخه عوض شد |
| `Refreshed` | همان نسخه؛ فایل‌ها/collectorها تازه شدند |
| `WhatIf` | فقط شبیه‌سازی |
| `Failed` | خطا؛ در صورت امکان rollback انجام شده |

---

## حذف ریموت

اسکریپت: `scripts/powershell/sql-exporter/Uninstall-SqlExporterRemote.ps1`

اسکریپت نوع `ServiceBase` یا `NSSM` را تشخیص می‌دهد، سرویس `prometheus_sql_exporter` را حذف می‌کند و در صورت عدم استفاده از `-KeepFiles` مسیر `C:\Program Files\Observability\PrometheusExporters\sql-exporter` را نیز پاک می‌کند. اگر `-SkipBackup` داده نشود، ZIP بکاپ در `C:\ProgramData\Observability\PrometheusExporters\uninstall-backups` ساخته می‌شود. Event Source به‌صورت پیش‌فرض حفظ خواهد شد.

```powershell
# شبیه‌سازی
.\scripts\powershell\sql-exporter\Uninstall-SqlExporterRemote.ps1 `
  -Computers sql-host-01,sql-host-02 -WhatIf

# حذف سرویس و فایل‌ها
.\scripts\powershell\sql-exporter\Uninstall-SqlExporterRemote.ps1 `
  -Computers sql-host-01,sql-host-02 `
  -ServiceMode Preserve `
  -RemoteCredential (Get-Credential)

# فقط حذف سرویس
.\scripts\powershell\sql-exporter\Uninstall-SqlExporterRemote.ps1 `
  -Computers sql-host-01 -KeepFiles
```

سوییچ‌های اختیاری: `-SkipBackup` و `-RemoveEventSource`.

---

## نصب / ارتقای دستی (بدون WinRM)

فقط وقتی دسترسی ریموت ندارید.

### نصب دستی

1. پوشه پکیج را روی سرور کپی کنید.
2. `data_source_name` را در `sql_exporter.yml` تنظیم کنید.
3. دسترسی‌های SQL را بدهید (جزئیات: [install-config-guide](install-config-guide.md)).
4. سرویس ویندوز را بسازید یا از اسکریپت نصب با `-Computers` محلی معادل استفاده کنید.
5. قبل از شروع سرویس:

```powershell
.\sql_exporter.exe "-config.file=sql_exporter.yml" -config.check
```

### ارتقای دستی

1. سرویس را Stop کنید.
2. از پوشه نصب بکاپ بگیرید.
3. `sql_exporter.exe` (و در صورت نیاز `collector\` / ymlها) را جایگزین کنید.
4. نسخه را چک کنید:

```powershell
.\sql_exporter.exe --version
```

5. سرویس را Start کنید. اگر بالا نیامد، از بکاپ برگردانید.

---

## چک سلامت بعد از نصب یا ارتقا

1. وضعیت سرویس:

```powershell
Get-Service prometheus_sql_exporter
```

2. نسخه:

```powershell
& 'C:\Program Files\Observability\PrometheusExporters\sql-exporter\sql_exporter.exe' --version
```

3. متریک‌ها:

```text
http://HOSTNAME:9399/metrics
```

اگر Basic Auth در `web-config.yml` فعال باشد، باید با username/password تست کنید. راهنمای ساخت hash و تنظیم Prometheus: [راهنمای نصب و کانفیگ](install-config-guide.md) (بخش «پورت scrape و Basic Auth»).

باید حداقل این‌ها را ببینید:

- `mssql_up`
- `mssql_hostname`
- `mssql_product_version`

4. در Prometheus هدف scrape باید `up=1` باشد.

---

## عیب‌یابی سریع استقرار

| مشکل | بررسی |
|------|--------|
| WinRM وصل نمی‌شود | Remoting، فایروال، credential؛ `Test-WSMan`؛ `Test-SqlExporterRequiredAccess.ps1` |
| سرویس Start نمی‌شود | Event Viewer، `config.check`، مسیر ImagePath؛ برای حساب سفارشی `-GrantLogonAsService` |
| ارتقا مسیر exe را پیدا نمی‌کند | `-InstallRoot` را بدهید |
| بعد از ارتقا متریک نیست | پورت 9399، `sql_exporter.yml`، دسترسی SQL، Basic Auth / scrape job؛ `Test-SqlExporterRequiredAccess.ps1` |
| خطای دسترسی SQL / متریک خالی | `Create-SqlExporterLogin.sql`؛ جدول دسترسی collectorها در [install-config-guide](install-config-guide.md) |
| Rollback خودکار | پیام خطا در خروجی اسکریپت + پوشه `_backup` |

---

## ترتیب پیشنهادی Rollout

1. یک سرور غیرحساس را با `-WhatIf` سپس اجرای واقعی تست کنید.
2. سلامت `/metrics` و scrape Prometheus را تأیید کنید.
3. بقیه سرورها را از روی `servers.txt` بچرخانید.
4. برای تغییر کانفیگ/پروفایل بدون تعویض باینری، از `Deploy-SqlExporterConfig.ps1` (با یا بدون `-Profile`) و [راهنمای کانفیگ](install-config-guide.md) استفاده کنید.
5. برای فقط به‌روزرسانی YAMLهای collector از `Deploy-Collectors.ps1` با `-Layout Collector` یا `-Layout Root` استفاده کنید.
