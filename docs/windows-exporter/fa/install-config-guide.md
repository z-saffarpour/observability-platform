# راهنمای نصب و تنظیم windows_exporter

[English](../en/install-config-guide.md)

این راهنما برای نسخه **0.31.8** و پورت پیش‌فرض **9182** نوشته شده است. Basic Auth به‌صورت پیش‌فرض غیرفعال است.

برای نصب و آپگرید ریموت با WinRM به [راهنمای نصب و آپگرید](install-upgrade-guide.md) ([HTML](install-upgrade-guide.html)) مراجعه کنید.

## پیش‌نیازها

- Windows Server 2016 یا جدیدتر
- دسترسی Administrator برای نصب سرویس و Firewall
- دسترسی Prometheus به TCP/9182
- حساب سرویس با حداقل دسترسی مورد نیاز collectorها

ماتریس دسترسی، ایجاد ACL/Firewall و بررسی:

```powershell
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -ShowRequirements
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -PrometheusRemoteAddress '<PROMETHEUS_IP>'
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1
```

## فایل‌های الزامی

برای نصب دستی حداقل این سه فایل را در یک مسیر ثابت قرار دهید:

```text
C:\Program Files\Observability\PrometheusExporters\windows-exporter
```

- `windows_exporter.exe`
- `windows_exporter.yml` (یا یک Profile از `profiles/`)
- `web-config.yml`

برای نصب ریموت و استقرار نقش‌محور، پوشه‌های `profiles/` و `scripts/powershell/windows-exporter/` نیز الزامی هستند (و در صورت استفاده از SSAS، `scripts/ssas/windows-exporter/`). جزئیات: [راهنمای نصب و آپگرید](install-upgrade-guide.md).

## اعتبارسنجی قبل از نصب

```powershell
.\windows_exporter.exe --version
.\windows_exporter.exe `
  --config.file=.\windows_exporter.yml `
  --web.listen-address=127.0.0.1:49176 `
  --log.file=stderr
```

سپس `http://127.0.0.1:49176/metrics` را بررسی و پردازش آزمایشی را متوقف کنید. در 0.31.8 هر کلید ناشناخته YAML باعث توقف startup می‌شود.

## ایجاد سرویس

PowerShell را با Run as Administrator اجرا کنید و مسیرها را با مسیر واقعی جایگزین کنید:

```powershell
$exe = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter\windows_exporter.exe'
$config = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter\windows_exporter.yml'
$webConfig = 'C:\Program Files\Observability\PrometheusExporters\windows-exporter\web-config.yml'
$binPath = ('"{0}" --config.file="{1}" --web.config.file="{2}"' -f $exe,$config,$webConfig)

New-Service -Name windows_exporter -BinaryPathName $binPath -DisplayName 'Prometheus Windows Exporter' -StartupType Automatic
sc.exe failure windows_exporter reset= 86400 actions= restart/5000/restart/15000/restart/60000
Start-Service windows_exporter
```

برای سرویس موجود، ImagePath را با `sc.exe config` اصلاح کنید. برای آپگرید ناوگان از اسکریپت ریموت با بکاپ و rollback استفاده کنید: [راهنمای نصب و آپگرید](install-upgrade-guide.md). آپگرید دستی فقط برای canary تک‌سرور توصیه می‌شود؛ قبل از جایگزینی باینری، سرویس را متوقف و از نسخه قبلی backup بگیرید.

## Firewall

ترجیحاً با اسکریپت دسترسی، قانون ورودی را فقط برای IP سرورهای Prometheus ایجاد کنید:

```powershell
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 -PrometheusRemoteAddress '<PROMETHEUS_IP>'
```

معادل دستی:

```powershell
New-NetFirewallRule -DisplayName 'Prometheus windows_exporter 9182' `
  -Direction Inbound -Protocol TCP -LocalPort 9182 `
  -RemoteAddress '<PROMETHEUS_IP>' -Action Allow
```

## Basic Auth (اختیاری)

پکیج با `basic_auth_users: {}` تحویل می‌شود؛ یعنی بدون نام‌کاربری/رمز هم `/metrics` پاسخ می‌دهد. برای محدود کردن scrape، Basic Auth را به‌صورت دستی فعال کنید.

> وجود فایل `web-config.yml` کافی نیست. سرویس باید با `--web.config.file=...` اجرا شود (اسکریپت‌های نصب ریموت این آرگومان را می‌گذارند).

در **نصب یا اپگرید ریموت** می‌توانید Basic Auth را بدون ویرایش دستی فایل روی سرور فعال کنید:

- `-BasicAuthUsername` + `-BasicAuthHash` (پیشنهادی)
- `-BasicAuthUsername` + `-BasicAuthPassword` (hash روی کلاینت؛ نیاز به Python با `bcrypt`)
- `-WebConfigPath` برای deploy فایل `web-config.yml` سفارشی
- `-PreserveWebConfig` در اپگرید برای حفظ فایل ریموت فعلی

پورت scrape با `-ListenAddress` (پیش‌فرض `:9182`) تنظیم می‌شود. نمونه‌ها: [راهنمای نصب و آپگرید](install-upgrade-guide.md).

### ۱) تولید bcrypt hash

رمز واضح را داخل Git یا تیکت نگذارید. فقط hash را در `web-config.yml` قرار دهید.

با `htpasswd` (Apache / prometheus community tools):

```bash
htpasswd -nBC 12 '' | tr -d ':\n'
```

یا با Python:

```powershell
python -c "import bcrypt; print(bcrypt.hashpw(b'YOUR_STRONG_PASSWORD', bcrypt.gensalt(rounds=12)).decode())"
```

یا از یک bcrypt generator معتبر (مثلاً [bcrypt-generator.com](https://bcrypt-generator.com/)) با cost حداقل **12** استفاده کنید و خروجی را کپی کنید.

نمونه خروجی:

```text
$2a$12$abcdefghijklmnopqrstuvABCDEFGHIJKLMNOPQRSTUVWXYZ012345
```

### ۲) ویرایش `web-config.yml`

```yaml
basic_auth_users:
  scrape_user: $2a$12$abcdefghijklmnopqrstuvABCDEFGHIJKLMNOPQRSTUVWXYZ012345
```

چند کاربر مجاز است؛ هر خط یک `username: <bcrypt-hash>` است. برای غیرفعال‌سازی دوباره به حالت پیش‌فرض برگردید:

```yaml
basic_auth_users: {}
```

ACL فایل را محدود کنید:

```powershell
icacls 'C:\Program Files\Observability\PrometheusExporters\windows-exporter\web-config.yml' `
  /inheritance:r `
  /grant:r 'SYSTEM:(R)' 'Administrators:(F)'
```

اگر حساب سرویس غیر از `LocalSystem` است، همان حساب را هم با `(R)` اضافه کنید.

### ۳) ری‌استارت سرویس و تست

```powershell
Restart-Service windows_exporter
# بدون credential باید 401 بگیرید
try { Invoke-WebRequest http://localhost:9182/metrics -UseBasicParsing } catch { $_.Exception.Response.StatusCode }

$cred = Get-Credential   # همان username/رمز واضح
Invoke-WebRequest http://localhost:9182/metrics -Credential $cred -UseBasicParsing
```

### ۴) تنظیم Prometheus

رمز واضح را در `scrape_config` فقط از `password_file` یا secret manager بخوانید:

```yaml
scrape_configs:
  - job_name: windows
    scrape_interval: 30s
    scrape_timeout: 25s
    metrics_path: /metrics
    basic_auth:
      username: scrape_user
      password_file: /etc/prometheus/secrets/windows_exporter_password
    static_configs:
      - targets: ['SERVER01:9182']
```

پس از تغییر، `up{job="windows"}` را در Prometheus بررسی کنید. خطای رایج: username/رمز ناسازگار → HTTP 401 در target.

### نکات امنیتی

- Basic Auth بدون TLS فقط مانع scrape ناشناس است؛ ترافیک همچنان قابل شنود است. در شبکه غیرقابل‌اعتماد TLS یا mTLS را در `web-config.yml` فعال کنید.
- رمز و hash را در commit نگذارید؛ روی هر محیط hash جدا بسازید.
- چرخش رمز: hash جدید بسازید → `web-config.yml` را به‌روز کنید → سرویس را restart کنید → `password_file` پرامتهوس را عوض کنید.

## نمونه Prometheus بدون Basic Auth

```yaml
scrape_configs:
  - job_name: windows
    scrape_interval: 30s
    scrape_timeout: 25s
    metrics_path: /metrics
    static_configs:
      - targets: ['SERVER01:9182']
```

## کنترل پس از نصب

```powershell
Get-Service windows_exporter
Get-CimInstance Win32_Service -Filter "Name='windows_exporter'" | Select-Object Name,State,StartName,PathName
Test-NetConnection localhost -Port 9182
Invoke-WebRequest http://localhost:9182/metrics -UseBasicParsing
```

در Prometheus مقدار `up{job="windows"}` و موفقیت تمام collectorهای مورد انتظار را بررسی کنید.
