# نصب Grafana به‌صورت Windows Service

[English](../en/installation.md)

## پیش‌نیازها

- PowerShell 5.1 یا جدیدتر، با گزینه **Run as Administrator**
- NSSM موجود در `deployment/windows/tools/nssm/nssm.exe`
- runtime مشترک Grafana در `grafana/runtime` و باینری Windows AMD64 در `grafana/bin/windows-amd64`
- دسترسی شبکه از سرور Grafana به Prometheus

runtime آفلاین همراه پروژه است؛ executableهای هر سیستم‌عامل زیر `grafana/bin/<platform>` و assetهای مشترک مانند `public` و `conf` زیر `grafana/runtime` قرار دارند.

## نصب

فرمان‌ها را از ریشهٔ مخزن اجرا کنید. رمز admin به‌صورت `SecureString` دریافت می‌شود:

```powershell
$adminPassword = Read-Host 'Grafana admin password' -AsSecureString
.\scripts\powershell\grafana\Install-Grafana.ps1 `
  -AdminPassword $adminPassword `
  -PrometheusUrl 'http://localhost:9090' `
  -OpenFirewall
```

اگر Prometheus دارای Basic Auth است:

```powershell
$adminPassword = Read-Host 'Grafana admin password' -AsSecureString
$prometheusPassword = Read-Host 'Prometheus password' -AsSecureString
.\scripts\powershell\grafana\Install-Grafana.ps1 `
  -AdminPassword $adminPassword `
  -PrometheusUrl 'http://localhost:9090' `
  -PrometheusUsername admin `
  -PrometheusPassword $prometheusPassword `
  -OpenFirewall
```

در نصب آزمایشی ایزوله می‌توان به‌صورت صریح `-AllowDefaultAdminPassword` را استفاده کرد؛ در این حالت رمز اولیه `admin` است و باید در اولین ورود تغییر کند.

## پارامترهای مهم

| پارامتر | پیش‌فرض | کاربرد |
|---|---|---|
| `-RuntimeArchivePath` | runtime دسته‌بندی‌شدهٔ مخزن | مسیر اختیاری ZIP یا `tar.gz` رسمی برای ارتقای بعدی |
| `-InstallRoot` | `C:\Program Files\Observability\Grafana` | ریشهٔ نصب self-contained |
| `-DataRoot` | `<InstallRoot>\data` | دیتابیس و دادهٔ پایدار Grafana |
| `-LogRoot` | `<InstallRoot>\logs` | خروجی‌های چرخشی NSSM |
| `-HttpAddress` / `-HttpPort` | `0.0.0.0` / `3000` | آدرس bind و پورت HTTP |
| `-Domain` | `localhost` | دامنه‌ای که در URL عمومی استفاده می‌شود. |
| `-RootUrl` | `http://<Domain>:<Port>/` | URL عمومی؛ برای reverse proxy مقدار واقعی را وارد کنید. |
| `-AdminUsername` | `admin` | نام کاربر مدیر اولیه |
| `-AdminPassword` | الزامی | رمز مدیر به‌شکل `SecureString` |
| `-PrometheusUrl` | `http://localhost:9090` | آدرس datasource |
| `-ForceConfig` | خاموش | بازنویسی `grafana.ini` نصب‌شده در upgrade |
| `-OpenFirewall` | خاموش | باز کردن پورت فقط در پروفایل‌های Domain و Private |

اجرای مجدد installer، runtime و داشبوردها را ارتقا می‌دهد. کانفیگ اصلی بدون `-ForceConfig` حفظ می‌شود؛ datasource و dashboard provisioning همیشه با ورودی جدید همگام می‌شوند. سرویس با LocalSystem، Automatic Delayed Start، recovery سه‌مرحله‌ای و چرخش log در ۱۰ مگابایت ساخته می‌شود.

## خروجی و بررسی

```text
C:\Program Files\Observability\Grafana\
├── runtime\
├── config\grafana.ini
├── provisioning\
├── dashboards\
├── plugins\
├── secrets\
├── data\
└── logs\
```

```powershell
Get-Service grafana
sc.exe qc grafana
Invoke-RestMethod http://localhost:3000/api/health
Get-Content 'C:\Program Files\Observability\Grafana\logs\grafana.err.log' -Tail 50
```

رمز admin در فایل ACLشدهٔ `secrets\grafana-admin-password` قرار می‌گیرد. اگر Basic Auth پرومتئوس فعال باشد، فایل datasource تولیدشده نیز فقط برای LocalSystem و Administrators قابل خواندن خواهد بود.

## نصب آفلاین در Linux با systemd

باینری رسمی Linux AMD64 در `grafana/bin/linux-amd64` و assetهای مشترک در `grafana/runtime` قرار دارند؛ نصب به اینترنت یا package repository نیاز ندارد. از ریشهٔ پروژه اجرا کنید:

```bash
sudo GRAFANA_ADMIN_PASSWORD_FILE=/root/secrets/grafana-admin-password \
  bash scripts/bash/grafana/install-grafana.sh
```

installer کاربر سیستمی بدون shell با نام `grafana` می‌سازد، runtime را در `/usr/local/lib/grafana` قرار می‌دهد و تنظیمات و داشبوردها را زیر `/etc/grafana` provision می‌کند. داده و pluginهای قابل‌نوشتن در `/var/lib/grafana` و logها در `/var/log/grafana` قرار می‌گیرند. سرویس به‌صورت خودکار start یا enable نمی‌شود.

### متغیرهای محیطی Linux

| متغیر | پیش‌فرض | توضیح |
|---|---|---|
| `GRAFANA_CONFIG_ROOT` | `/etc/grafana` | تنظیمات، provisioning، داشبوردها و secretها |
| `GRAFANA_DATA_ROOT` | `/var/lib/grafana` | دیتابیس، sessionها و pluginهای نصب‌شده |
| `GRAFANA_LOG_ROOT` | `/var/log/grafana` | مسیر log قابل‌نوشتن سرویس |
| `GRAFANA_RUNTIME_ROOT` | `/usr/local/lib/grafana` | runtime فقط‌خواندنی Grafana |
| `GRAFANA_HTTP_ADDR` | `0.0.0.0` | آدرس bind |
| `GRAFANA_HTTP_PORT` | `3000` | پورت HTTP |
| `GRAFANA_DOMAIN` | `localhost` | دامنهٔ عمومی |
| `GRAFANA_ROOT_URL` | مشتق از domain و port | URL کامل، مخصوصاً پشت reverse proxy |
| `GRAFANA_ADMIN_USER` | `admin` | نام مدیر اولیه |
| `GRAFANA_ADMIN_PASSWORD_FILE` | خالی | فایل رمز مدیر؛ در production هنگام نصب تعیین شود. |
| `GRAFANA_PROMETHEUS_URL` | `http://localhost:9090` | URL datasource پرومتئوس |
| `GRAFANA_PROMETHEUS_USER` | خالی | نام کاربری Basic Auth پرومتئوس |
| `GRAFANA_PROMETHEUS_PASSWORD_FILE` | خالی | فایل رمز Basic Auth؛ همراه username الزامی است. |

اگر Prometheus دارای Basic Auth است:

```bash
sudo \
  GRAFANA_ADMIN_PASSWORD_FILE=/root/secrets/grafana-admin-password \
  GRAFANA_PROMETHEUS_URL=http://127.0.0.1:9090 \
  GRAFANA_PROMETHEUS_USER=admin \
  GRAFANA_PROMETHEUS_PASSWORD_FILE=/root/secrets/prometheus-password \
  bash scripts/bash/grafana/install-grafana.sh
```

سپس سرویس را فعال و بررسی کنید:

```bash
sudo systemctl enable --now grafana
sudo systemctl status grafana
sudo journalctl -u grafana -n 100 --no-pager
curl -fsS http://localhost:3000/api/health
```

unit با `NoNewPrivileges`، `ProtectSystem=strict`، `ProtectHome`، مسیرهای نوشتنی محدود و restart خودکار سخت‌سازی شده است.
