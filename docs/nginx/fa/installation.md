# نصب Nginx در Windows با NSSM

[English](../en/installation.md)

این استقرار Nginx را به‌عنوان Reverse Proxy مقابل Grafana و Prometheus اجرا می‌کند:

- `http://server/grafana/` به `127.0.0.1:3000`
- `http://server/prometheus/` به `127.0.0.1:9090`
- `http://server/healthz` برای health check خود Nginx

نسخه Windows به توصیه مستند رسمی Nginx از شاخه mainline انتخاب شده است. باینری رسمی `1.31.4`، مجوزها، منبع دانلود و SHA-256 در `nginx/bin/windows-amd64/` نگه‌داری می‌شوند. Nginx روی Windows محدودیت مقیاس‌پذیری دارد؛ این روش برای استقرار داخلی این پلتفرم مناسب است، ولی برای بار سنگین Linux توصیه می‌شود.

## تنظیم Backendها

برای محدودکردن دسترسی مستقیم، Grafana و Prometheus را روی loopback اجرا کنید.

در `grafana.ini`:

```ini
[server]
http_addr = 127.0.0.1
http_port = 3000
domain = monitoring.example.local
root_url = %(protocol)s://%(domain)s/grafana/
serve_from_sub_path = true
```

Prometheus باید با این آرگومان‌ها اجرا شود:

```text
--web.listen-address=127.0.0.1:9090
--web.external-url=http://monitoring.example.local/prometheus/
--web.route-prefix=/prometheus/
```

اگر hostname یا HTTPS متفاوت است، `root_url` و `external-url` را با URL عمومی واقعی جایگزین کنید. قبل از انتقال کامل، پورت‌های مستقیم `3000` و `9090` را در Firewall نبندید.

## نصب سرویس

PowerShell را با **Run as Administrator** در ریشه مخزن باز کنید:

```powershell
.\scripts\powershell\nginx\Install-Nginx.ps1 `
  -DependencyServiceNames prometheus,Grafana `
  -OpenFirewall
```

نام داخلی سرویس Grafana را با `Get-Service *grafana*` بررسی کنید. اگر سرویس‌ها هنوز نصب نشده‌اند یا نام دیگری دارند، `DependencyServiceNames` را حذف یا اصلاح کنید.

مسیر نصب پیش‌فرض:

```text
C:\Program Files\Observability\Nginx\
├── bin\       nginx.exe، nssm.exe و مجوزها
├── config\    nginx.conf، mime.types و conf.d
├── html\
├── temp\      فایل‌های موقت داخلی Nginx
└── logs\      access/error و stdout/stderr مربوط به NSSM
```

اجرای مجدد installer باینری را ارتقا می‌دهد ولی کانفیگ نصب‌شده را حفظ می‌کند. برای جایگزینی کانفیگ:

```powershell
.\scripts\powershell\nginx\Install-Nginx.ps1 -ForceConfig
```

گزینه‌های مهم:

| پارامتر | پیش‌فرض | کاربرد |
|---|---|---|
| `InstallRoot` | `C:\Program Files\Observability\Nginx` | مسیر نصب مستقل از checkout |
| `LogRoot` | `<InstallRoot>\logs` | مسیر لاگ‌ها |
| `ListenPort` | `80` | پورت Nginx و Firewall rule |
| `DependencyServiceNames` | خالی | سرویس‌هایی که باید قبل از Nginx اجرا شوند |
| `ForceConfig` | خاموش | بازنویسی کانفیگ نصب‌شده |
| `OpenFirewall` | خاموش | بازکردن پورت در profileهای Domain و Private |
| `WhatIf` | خاموش | شبیه‌سازی بدون تغییر سیستم |

## اعتبارسنجی و عیب‌یابی

```powershell
& 'C:\Program Files\Observability\Nginx\bin\nginx.exe' `
  -t -p 'C:\Program Files\Observability\Nginx\' -c config/nginx.conf

Get-Service nginx
Invoke-WebRequest http://localhost/healthz
Get-Content 'C:\Program Files\Observability\Nginx\logs\error.log' -Tail 50
```

برای reload بدون قطع اتصال‌ها:

```powershell
& 'C:\Program Files\Observability\Nginx\bin\nginx.exe' `
  -p 'C:\Program Files\Observability\Nginx\' -c config/nginx.conf -s reload
```

سرویس با `LocalSystem`، شروع delayed automatic، recovery سه‌مرحله‌ای و rotation لاگ ۱۰ مگابایتی NSSM نصب می‌شود. برای production، HTTPS و کنترل دسترسی را قبل از بازکردن Firewall عمومی اضافه کنید.

## نصب در Linux با systemd

اسکریپت Linux روی توزیع‌های دارای `apt-get`، `dnf` یا `yum` کار می‌کند. اگر Nginx نصب نباشد، بسته را از repository تنظیم‌شده سیستم‌عامل دریافت می‌کند؛ سپس کانفیگ پروژه را مستقر، با `nginx -t` اعتبارسنجی و سرویس را enable/start می‌کند:

```bash
sudo bash scripts/bash/nginx/install-nginx.sh
```

مقادیر قابل تنظیم از طریق environment:

| متغیر | پیش‌فرض | کاربرد |
|---|---|---|
| `NGINX_SOURCE_ROOT` | ریشه محاسبه‌شده پروژه | اجرای اسکریپت خارج از ساختار اصلی |
| `NGINX_LISTEN_PORT` | `80` | پورت IPv4 و IPv6 |
| `NGINX_OPEN_FIREWALL` | `0` | با مقدار `1`، افزودن rule از طریق firewalld یا UFW |

نمونه:

```bash
sudo env NGINX_LISTEN_PORT=8080 NGINX_OPEN_FIREWALL=1 \
  bash scripts/bash/nginx/install-nginx.sh
```

فایل کانفیگ مقصد `/etc/nginx/conf.d/observability.conf` است. unit موجود در `deployment/systemd/nginx.service` نیز در `/etc/systemd/system/nginx.service` نصب و سپس `systemctl daemon-reload` اجرا می‌شود. چون این سایت باید ورودی پیش‌فرض باشد، installer کانفیگ پیش‌فرض بسته را غیرفعال می‌کند. همه فایل‌های جایگزین‌شده، از جمله unit قبلی، پیش از تغییر در مسیر timestampدار زیر نگه‌داری می‌شوند:

```text
/var/backups/observability-nginx/
```

اگر `nginx -t` یا مرحله بعدی خطا بدهد، trap اسکریپت کانفیگ قبلی را برمی‌گرداند. بررسی پس از نصب:

```bash
sudo nginx -t
sudo systemctl status nginx --no-pager
sudo systemctl cat nginx
curl -fsS http://127.0.0.1/healthz
sudo tail -n 50 /var/log/nginx/observability.error.log
```

در Linux نیز Grafana و Prometheus باید مطابق بخش «تنظیم Backendها» روی loopback و subpath مربوط به خود تنظیم شوند. سرویس Nginx برای start شدن به dependency صریح آن‌ها نیاز ندارد؛ در زمان unavailable بودن backend پاسخ `502` می‌دهد و پس از بالا آمدن backend بدون restart مجدد قابل استفاده است.
