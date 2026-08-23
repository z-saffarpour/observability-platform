# نصب Prometheus در Windows و Linux

[English](../en/installation.md)

## پیش‌نیازهای مشترک

- فایل‌های `prometheus/config/prometheus.yml` و ruleها باید با `promtool` معتبر باشند.
- فایل `web-config.yml` واقعی باید دارای bcrypt hash معتبر باشد.
- فایل‌های `sql-exporter-password` و `windows-exporter-password` باید در پوشه
  `secrets` موجود باشند و با web-config همان exporter تطابق داشته باشند.
- فایل‌های target واقعی را از templateها بسازید؛ فایل‌های `.template` بارگذاری نمی‌شوند.

## نصب در Windows به‌صورت سرویس

PowerShell را با گزینه **Run as Administrator** باز کنید. نصب امن با web-config آماده:

```powershell
.\scripts\powershell\prometheus\Install-Prometheus.ps1 `
  -WebConfigPath C:\Secure\prometheus-web-config.yml `
  -OpenFirewall
```

یا hash مربوط به Basic Auth را مستقیم بدهید:

```powershell
.\scripts\powershell\prometheus\Install-Prometheus.ps1 `
  -BasicAuthUsername admin `
  -BasicAuthHash '$2b$12$REPLACE_WITH_VALID_BCRYPT_HASH' `
  -OpenFirewall
```

استفاده از `-BasicAuthPassword` نیز ممکن است، اما تولید bcrypt در این حالت به
Python و ماژول `bcrypt` روی سرور Windows نیاز دارد. برای سرور production استفاده
از `-WebConfigPath` یا `-BasicAuthHash` قابل‌پیش‌بینی‌تر است.

### ورودی‌های installer ویندوز


| پارامتر | نوع | پیش‌فرض | توضیح |
|---|---|---|---|
| `-SourceRoot` | `String` | ریشه پروژه، محاسبه‌شده از محل اسکریپت | مسیر checkout پروژه‌ای که پوشه‌های `prometheus`، `deployment` و `scripts` را دارد. فقط وقتی اسکریپت را جدا از ساختار اصلی اجرا می‌کنید آن را مشخص کنید. |
| `-InstallRoot` | `String` | `C:\Program Files\Observability\Prometheus` | ریشه نصب self-contained؛ باینری، کانفیگ، rules، targets، secrets، data و logs زیر این مسیر قرار می‌گیرند. مسیر root درایو مجاز نیست. |
| `-DataRoot` | `String` | `<InstallRoot>\data` | مسیر TSDB. در صورت نیاز می‌تواند روی دیسک مستقل قرار گیرد. مسیر root درایو مجاز نیست. |
| `-LogRoot` | `String` | `<InstallRoot>\logs` | مسیر stdout و stderr سرویس NSSM. مسیر root درایو مجاز نیست. |
| `-ServiceName` | `String` | `prometheus` | نام داخلی Windows Service که در `Get-Service` و `sc.exe` استفاده می‌شود. |
| `-ServiceDisplayName` | `String` | `Prometheus Monitoring Server` | نام نمایشی سرویس در Services MMC. |
| `-ServiceDescription` | `String` | `Prometheus monitoring and time-series database` | توضیح ثبت‌شده برای سرویس. |
| `-ListenAddress` | `String` | `0.0.0.0:9090` | آدرس و پورت UI/API. قالب‌های مجاز شامل `IP:port`، `localhost:port`، `*:port` و `:port` هستند. |
| `-WebConfigPath` | `String` | ندارد | مسیر یک `web-config.yml` آماده و معتبر. با پارامترهای `BasicAuth*` یا `-AllowUnauthenticated` قابل ترکیب نیست. |
| `-BasicAuthUsername` | `String` | ندارد | نام کاربر UI/API. باید همراه دقیقاً یکی از `-BasicAuthPassword` یا `-BasicAuthHash` باشد. |
| `-BasicAuthPassword` | `SecureString` | ندارد | رمز ورودی امن که installer آن را bcrypt می‌کند؛ نیازمند Python و ماژول `bcrypt` است. هم‌زمان با `-BasicAuthHash` مجاز نیست. |
| `-BasicAuthHash` | `String` | ندارد | bcrypt hash آماده با پیشوند معتبر مانند `$2b$12$`. هم‌زمان با `-BasicAuthPassword` مجاز نیست. |
| `-AllowUnauthenticated` | `Switch` | خاموش | احراز هویت UI/API را عمداً غیرفعال می‌کند؛ فقط برای محیط آزمایشی. با همه پارامترهای authentication ناسازگار است. |
| `-ForceConfig` | `Switch` | خاموش | در upgrade، فایل نصب‌شده `prometheus.yml` را با نسخه سورس بازنویسی می‌کند. بدون این گزینه کانفیگ موجود حفظ می‌شود. |
| `-OpenFirewall` | `Switch` | خاموش | یک inbound rule برای پورت `ListenAddress` در profileهای Domain و Private ایجاد می‌کند. |
| `-ServiceTimeoutSec` | `Int32` | `60` | مهلت توقف/شروع سرویس؛ مقدار مجاز بین ۵ تا ۳۰۰ ثانیه است. |
| `-WhatIf` | پارامتر استاندارد PowerShell | خاموش | عملیات تغییردهنده را شبیه‌سازی می‌کند، بدون نصب یا تغییر سرویس. |
| `-Confirm` | پارامتر استاندارد PowerShell | خودکار | کنترل درخواست تأیید عملیات به‌دلیل استفاده اسکریپت از `SupportsShouldProcess`. |
| `-Verbose` | پارامتر استاندارد PowerShell | خاموش | خروجی تشخیصی بیشتر PowerShell را فعال می‌کند. |

به‌دلیل `CmdletBinding`، Common Parameterهای استاندارد PowerShell مانند
`-Debug`، `-ErrorAction`، `-WarningAction`، `-InformationAction`، متغیرهای متناظر
خطا/هشدار/اطلاعات و `-OutVariable` نیز در دسترس‌اند؛ این ورودی‌ها رفتار عمومی
PowerShell را کنترل می‌کنند و منطق اختصاصی نصب را تغییر نمی‌دهند.

حداقل یکی از این سه روش احراز هویت باید انتخاب شود:

1. `-WebConfigPath`
2. `-BasicAuthUsername` همراه `-BasicAuthHash` یا `-BasicAuthPassword`
3. `-AllowUnauthenticated` فقط برای تست

نمونه با سفارشی‌سازی تمام مسیرهای اصلی:

```powershell
.\scripts\powershell\prometheus\Install-Prometheus.ps1 `
  -InstallRoot 'C:\Program Files\Observability\Prometheus' `
  -DataRoot 'D:\Prometheus\data' `
  -LogRoot 'D:\Prometheus\logs' `
  -ServiceName prometheus `
  -ServiceDisplayName 'Prometheus Monitoring Server' `
  -ListenAddress '0.0.0.0:9090' `
  -WebConfigPath 'C:\Secure\prometheus-web-config.yml' `
  -ServiceTimeoutSec 90 `
  -OpenFirewall
```

مسیرهای پیش‌فرض:

| مورد | مسیر |
|---|---|
| برنامه و کانفیگ | `C:\Program Files\Observability\Prometheus` |
| باینری‌ها | `C:\Program Files\Observability\Prometheus\bin` |
| دیتابیس TSDB | `C:\Program Files\Observability\Prometheus\data` |
| لاگ‌های سرویس | `C:\Program Files\Observability\Prometheus\logs` |
| نام سرویس | `prometheus` |

ساختار نصب Windows مطابق ساختار سورس و کاملاً self-contained است:

```text
C:\Program Files\Observability\Prometheus\
├── bin\
├── config\
├── alert-rules\
├── recording-rules\
├── targets\
├── secrets\
├── data\
└── logs\
```

سرویس با NSSM، حساب `LocalSystem`، حالت Automatic Delayed Start، سه مرحله restart
recovery و چرخش لاگ در اندازه ۱۰ مگابایت نصب می‌شود. اجرای مجدد installer باعث
upgrade باینری‌ها و ruleها می‌شود. کانفیگ موجود فقط با `-ForceConfig` بازنویسی می‌شود.

بررسی وضعیت:

```powershell
Get-Service prometheus
sc.exe qc prometheus
Get-Content 'C:\Program Files\Observability\Prometheus\logs\prometheus.err.log' -Tail 50
```

برای محیط آزمایشی فقط، نصب بدون login باید صریحاً درخواست شود:

```powershell
.\scripts\powershell\prometheus\Install-Prometheus.ps1 -AllowUnauthenticated
```

## نصب در Linux با systemd

از ریشه پروژه اجرا کنید:

```bash
sudo bash scripts/bash/prometheus/install-prometheus.sh
```

### ورودی‌های installer لینوکس

اسکریپت shell آرگومان positional یا flag اختصاصی دریافت نمی‌کند. ورودی‌های آن
از environment variableهای زیر تأمین می‌شوند:

| متغیر | پیش‌فرض | توضیح |
|---|---|---|
| `PROMETHEUS_CONFIG_ROOT` | `/etc/prometheus` | مسیر absolute ریشه کانفیگ نصب‌شده؛ زیرپوشه‌های `config`، `alert-rules`، `recording-rules`، `targets` و `secrets` در آن ساخته می‌شوند و unit نیز با همین مقدار تولید می‌شود. |
| `PROMETHEUS_DATA_ROOT` | `/var/lib/prometheus` | مسیر absolute و قابل‌نوشتن TSDB که مالک آن کاربر سرویس `prometheus` است؛ مقدار در unit نصب‌شده نیز اعمال می‌شود. |

ورودی‌ها و رفتارهای ثابت اسکریپت:

- ریشه پروژه از محل خود اسکریپت محاسبه می‌شود و ورودی جداگانه ندارد.
- باینری‌ها در `/usr/local/bin/prometheus` و `/usr/local/bin/promtool` نصب می‌شوند.
- unit فایل در `/etc/systemd/system/prometheus.service` نصب می‌شود.
- اسکریپت باید با کاربر `root` یا از طریق `sudo` اجرا شود.
- installer فقط `systemctl daemon-reload` را اجرا می‌کند و سرویس را خودکار start یا enable نمی‌کند.

نمونه با مسیرهای سفارشی:

```bash
sudo env \
  PROMETHEUS_CONFIG_ROOT=/opt/prometheus/configuration \
  PROMETHEUS_DATA_ROOT=/data/prometheus \
  bash scripts/bash/prometheus/install-prometheus.sh
```

پیش از start این فایل‌ها را ایجاد یا تکمیل کنید:

```text
/etc/prometheus/config/web-config.yml
/etc/prometheus/secrets/sql-exporter-password
/etc/prometheus/secrets/windows-exporter-password
/etc/prometheus/targets/*/*.json
```

سپس کانفیگ را اعتبارسنجی و سرویس را فعال کنید:

```bash
sudo promtool check web-config /etc/prometheus/config/web-config.yml
sudo promtool check config /etc/prometheus/config/prometheus.yml
sudo systemctl enable --now prometheus
sudo systemctl status prometheus
journalctl -u prometheus -n 100 --no-pager
```

سرویس Linux با کاربر محدود `prometheus` اجرا می‌شود و فقط مسیر
`/var/lib/prometheus` اجازه نوشتن دارد.
