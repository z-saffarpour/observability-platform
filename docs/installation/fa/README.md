# راهنمای نصب و راه‌اندازی پلتفرم

[English](../en/README.md)

این راهنما مسیر نصب سرور مرکزی Observability را بر اساس سیستم‌عامل مشخص می‌کند.
فرمان‌ها را از ریشهٔ repository اجرا کنید.

## انتخاب مسیر نصب

| نقش | Windows | Linux |
|---|---|---|
| Prometheus مرکزی | PowerShell + NSSM | Bash + systemd |
| Alertmanager مرکزی | PowerShell + NSSM | نصب آفلاین دستی + systemd |
| Grafana مرکزی | PowerShell + NSSM | Bash + systemd |
| Nginx Reverse Proxy | PowerShell + NSSM | Bash + systemd |
| Windows Exporter روی سرور مقصد | پشتیبانی می‌شود | کاربرد ندارد |
| SQL Exporter برای Microsoft SQL Server | نصب Remote با PowerShell روی Windows | در این مخزن installer لینوکسی ندارد |

> پیشنهاد production: اجزای مرکزی را روی یک Linux Server نصب کنید و exporterها را
> روی سرورهای Windows/SQL Server مقصد مستقر کنید. اگر زیرساخت کاملاً Windows است،
> نصب مرکزی با NSSM نیز پشتیبانی می‌شود.

## پیش‌نیازهای مشترک

- معماری میزبان مرکزی `x86-64/AMD64` باشد.
- repository همراه فایل‌های Git LFS دریافت شده باشد: `git lfs pull`.
- پورت‌های پیش‌فرض بررسی شوند: Prometheus روی `9090`، Alertmanager روی `9093`،
  Grafana روی `3000` و Nginx روی `80` یا `443`.
- DNS، Firewall و دسترسی شبکه از Prometheus به exporterها فراهم باشد.
- رمزها و bcrypt hashهای واقعی خارج از Git نگه‌داری شوند.
- فایل‌های target واقعی از templateها ساخته شوند؛ فایل‌های `.template` توسط
  Prometheus بارگذاری نمی‌شوند.

ترتیب پیشنهادی راه‌اندازی:

1. آماده‌سازی targetها، secretها و تنظیمات Prometheus
2. نصب و اعتبارسنجی Prometheus
3. نصب Alertmanager و اتصال Prometheus به آن
4. نصب Grafana و اتصال datasource به Prometheus
5. نصب Nginx و محدودکردن سرویس‌های داخلی به loopback
6. نصب exporterها روی سرورهای مقصد
7. بررسی Targets، Alertها و داشبوردها

## مسیر Windows

### ۱. آماده‌سازی

PowerShell 5.1 یا جدیدتر را با **Run as Administrator** باز کنید. باینری NSSM باید
در `deployment/windows/tools/nssm/nssm.exe` موجود باشد.

برای آزمایش بدون تغییر سیستم می‌توانید `-WhatIf` را به installerهای PowerShell
اضافه کنید.

### ۲. نصب Prometheus

روش مناسب production، استفاده از یک `web-config.yml` آماده با bcrypt hash است:

```powershell
.\scripts\powershell\prometheus\Install-Prometheus.ps1 `
  -WebConfigPath 'C:\Secure\prometheus-web-config.yml' `
  -OpenFirewall
```

قبل از ادامه، targetها و secretهای موردنیاز را در نصب پیش‌فرض زیر تکمیل کنید:

```text
C:\Program Files\Observability\Prometheus\targets\
C:\Program Files\Observability\Prometheus\secrets\
```

بررسی سرویس:

```powershell
Get-Service prometheus
# اگر Basic Auth فعال است، credential همان web-config را وارد کنید.
Invoke-WebRequest http://localhost:9090/-/healthy -Credential (Get-Credential)
```

جزئیات احراز هویت، مسیرهای سفارشی و upgrade در
[راهنمای Prometheus](../../prometheus/fa/installation.md) آمده است.

### ۳. نصب Alertmanager

دو کانفیگ نمونه در مخزن وجود دارد:

- `alertmanager/sql-exporter/alertmanager.yml` برای هشدارهای SQL Exporter
- `alertmanager/windows-exporter/alertmanager.yml` برای هشدارهای Windows Exporter

پیش از نصب، تمام مقدارهای `CHANGE_ME_*` شامل SMTP، گیرنده‌های Email و URL درگاه
SMS را جایگزین کنید. اگر هر دو exporter را مانیتور می‌کنید، routeها، receiverها و
templateهای موردنیاز را در یک `alertmanager.yml` نهایی ادغام کنید؛ Alertmanager در
هر اجرا فقط یک فایل config اصلی می‌خواند.

اعتبارسنجی کانفیگ انتخابی:

```powershell
.\alertmanager\bin\windows-amd64\amtool.exe check-config `
  .\alertmanager\sql-exporter\alertmanager.yml
```

نصب به‌صورت Windows Service با NSSM:

```powershell
.\scripts\powershell\alertmanager\Install-Alertmanager.ps1 `
  -ConfigPath .\alertmanager\sql-exporter\alertmanager.yml `
  -ListenAddress '127.0.0.1:9093'
```

اگر Prometheus روی میزبان دیگری قرار دارد، به‌جای loopback از
`-ListenAddress '0.0.0.0:9093' -OpenFirewall` استفاده کنید و Firewall را فقط به IP
سرور Prometheus محدود کنید. مسیر نصب پیش‌فرض
`C:\Program Files\Observability\Alertmanager` و نام سرویس
`prometheus_alert_manager` است.

بررسی سرویس:

```powershell
Get-Service prometheus_alert_manager
Invoke-RestMethod http://127.0.0.1:9093/-/ready
& 'C:\Program Files\Observability\Alertmanager\bin\amtool.exe' `
  --alertmanager.url=http://127.0.0.1:9093 alert query
```

فایل `prometheus/config/prometheus.yml` به‌صورت پیش‌فرض Alertmanager را روی
`127.0.0.1:9093` صدا می‌زند. اگر آدرس متفاوت است، target بخش
`alerting.alertmanagers` را تغییر دهید، کانفیگ Prometheus را با `promtool` بررسی و
سرویس آن را restart کنید.

### ۴. نصب Grafana

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

اگر Prometheus بدون Basic Auth است، دو پارامتر `PrometheusUsername` و
`PrometheusPassword` را حذف کنید.

```powershell
Get-Service grafana
Invoke-RestMethod http://localhost:3000/api/health
```

جزئیات: [راهنمای Grafana](../../grafana/fa/installation.md)

### ۵. نصب Nginx (اختیاری ولی توصیه‌شده)

ابتدا `root_url` گرافانا و URL خارجی Prometheus را مطابق hostname نهایی تنظیم
کنید، سپس:

```powershell
.\scripts\powershell\nginx\Install-Nginx.ps1 `
  -DependencyServiceNames prometheus,grafana `
  -OpenFirewall

Get-Service nginx
Invoke-WebRequest http://localhost/healthz
```

پس از موفقیت proxy، پورت‌های `3000` و `9090` را عمومی نکنید. جزئیات subpath،
HTTPS و reload در [راهنمای Nginx](../../nginx/fa/installation.md) است.

### ۶. نصب exporterها روی سرورهای مقصد

Exporterها روی سرور مرکزی نصب نمی‌شوند؛ هر exporter باید روی Windows Server مقصد
یا کنار SQL Server مربوط به خود اجرا شود. استقرار از یک کلاینت مدیریتی Windows و
از ریشهٔ همین repository انجام می‌شود.

#### ۶.۱. آماده‌سازی کلاینت و سرور مقصد

پیش‌نیازها:

- PowerShell 5.1 یا جدیدتر روی کلاینت مدیریتی
- Windows Server 2016 یا جدیدتر روی مقصد
- دسترسی Administrator روی مقصد برای حساب استقرار
- فعال‌بودن WinRM/PowerShell Remoting و resolveشدن نام سرور در DNS
- دسترسی Prometheus به TCP/`9182` برای Windows Exporter و TCP/`9399` برای SQL Exporter
- دریافت کامل باینری‌های repository و Git LFS
- یک حساب سرویس با حداقل دسترسی لازم؛ استفاده از gMSA یا حساب دامنه‌ای مجزا برای
  production توصیه می‌شود.

اتصال به هر مقصد را قبل از نصب بررسی کنید:

```powershell
$servers = 'SERVER01','SQL01'
$remoteCredential = Get-Credential

$servers | ForEach-Object {
  Test-WSMan -ComputerName $_ -Credential $remoteCredential
}
```

اگر مقصد عضو Domain نیست یا از IP استفاده می‌کنید، WinRM نیازمند HTTPS یا تنظیم
کنترل‌شدهٔ `TrustedHosts` است. از افزودن wildcard به `TrustedHosts` خودداری کنید.

#### ۶.۲. انتخاب Profile مناسب

Windows Exporter:

| نقش مقصد | Profile پیشنهادی |
|---|---|
| Windows Server عمومی | `windows-base.yml` |
| SQL Server مستقل | `sql-server.yml` |
| Windows Failover Cluster | `windows-cluster.yml` |
| SSAS | `ssas.yml` |
| Power BI Report Server | `powerbi-report-server.yml` |
| چند نقش Data Platform | `data-platform.yml` یا `data-platform-cluster.yml` |
| Terminal Server | `terminal-server.yml` |

برای محیط‌های ناهمگون می‌توانید به‌جای `-Profile` از `-AutoProfile` استفاده کنید؛
این دو پارامتر هم‌زمان مجاز نیستند. فهرست کامل در
[Profileهای Windows Exporter](../../windows-exporter/fa/profiles.md) قرار دارد.

SQL Exporter:

| نوع workload | Profile پیشنهادی |
|---|---|
| مانیتورینگ پایه | `core.yml` |
| OLTP | `oltp.yml` |
| OLTP سبک برای منابع محدود | `oltp-store-lite.yml` |
| Data Warehouse / BI | `dwh.yml` |
| SSIS | `ssis.yml` |
| Replication | `replication.yml` |
| PolyBase | `polybase.yml` |
| Security audit | `security-audit.yml` |

هر SQL Profile فهرست کامل collectorهای خود را دارد و با Profile دیگری merge
نمی‌شود. جزئیات در [Profileهای SQL Exporter](../../sql-exporter/fa/profiles.md) است.

#### ۶.۳. نصب Windows Exporter

ابتدا اجرای واقعی را برای یک سرور شبیه‌سازی کنید:

```powershell
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SERVER01 `
  -Profile windows-base.yml `
  -RemoteCredential $remoteCredential `
  -WhatIf
```

سپس نصب production را با Basic Auth انجام دهید. bcrypt hash را جایگزین کنید و
رمز متناظر را برای Prometheus نگه دارید:

```powershell
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers SERVER01 `
  -Profile windows-base.yml `
  -ListenAddress ':9182' `
  -BasicAuthUsername 'prometheus_user' `
  -BasicAuthHash '$2a$12$REPLACE_WITH_BCRYPT_HASH' `
  -ServiceAccountMode gMSA `
  -ServiceAccount 'DOMAIN\svc-winexporter$' `
  -RemoteCredential $remoteCredential
```

اگر gMSA ندارید، `ServiceAccountMode` را `Credential` قرار دهید و
`-ServiceCredential (Get-Credential 'DOMAIN\svc-winexporter')` را ارسال کنید.
پیش‌فرض installer حساب `LocalSystem` است.

مجوز فایل‌ها، عضویت Performance Monitor Users و Firewall را ابتدا dry-run و سپس
اعمال و audit کنید. آدرس زیر باید IP سرور Prometheus باشد:

```powershell
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 `
  -ComputerName SERVER01 `
  -Credential $remoteCredential `
  -ServiceAccount 'DOMAIN\svc-winexporter$' `
  -PrometheusRemoteAddress '10.10.10.20' `
  -GrantPerformanceMonitorUsers `
  -WhatIf

# بعد از بررسی خروجی، همان فرمان را بدون WhatIf اجرا کنید.
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 `
  -ComputerName SERVER01 `
  -Credential $remoteCredential
```

#### ۶.۴. نصب SQL Exporter

حساب سرویس باید علاوه بر دسترسی فایل و شبکه، در SQL Server نیز مجوزهای لازم را
داشته باشد. حداقل معمول شامل `VIEW SERVER STATE` و `VIEW ANY DEFINITION` است؛
collectorهای msdb، SSISDB یا database-level ممکن است GRANTهای بیشتری بخواهند.
اسکریپت `scripts/sql/Create-SqlExporterLogin.sql` را پس از بازبینی با یک حساب
`sysadmin` روی Instance مقصد اجرا کنید.

Dry-run:

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers SQL01 `
  -Profile oltp.yml `
  -RemoteCredential $remoteCredential `
  -WhatIf
```

نصب واقعی با Windows Integrated Authentication:

```powershell
$sqlServiceCredential = Get-Credential 'DOMAIN\svc-sqlexporter'

.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 `
  -Computers SQL01 `
  -TargetName 'SQL01' `
  -DataSourceName 'sqlserver://127.0.0.1:1433?trusted+connection=yes&encrypt=true&TrustServerCertificate=true&app+name=sql_exporter' `
  -Profile oltp.yml `
  -ListenAddress ':9399' `
  -BasicAuthUsername 'prometheus_user' `
  -BasicAuthHash '$2a$12$REPLACE_WITH_BCRYPT_HASH' `
  -ServiceAccountMode Credential `
  -ServiceCredential $sqlServiceCredential `
  -RemoteCredential $remoteCredential
```

برای Named Instance، پورت واقعی SQL را در `DataSourceName` قرار دهید یا نام سرویس
را با `-SqlServerServiceName 'MSSQL$INSTANCE01'` مشخص کنید. در production اعتبار
certificate را درست پیکربندی کنید؛ `TrustServerCertificate=true` فقط وقتی مناسب
است که تصمیم امنیتی آگاهانه‌ای برای certificate داخلی گرفته شده باشد.

مجوز سیستم‌عامل و Firewall را نیز اعمال و audit کنید:

```powershell
.\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 `
  -ComputerName SQL01 `
  -Credential $remoteCredential `
  -ServiceAccount 'DOMAIN\svc-sqlexporter' `
  -PrometheusRemoteAddress '10.10.10.20' `
  -GrantLogonAsService `
  -WhatIf

# بعد از بررسی خروجی، همان فرمان را بدون WhatIf اجرا کنید.
.\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1 `
  -ComputerName SQL01 `
  -Credential $remoteCredential
```

#### ۶.۵. تست سرویس و endpoint

وضعیت سرویس‌ها را از کلاینت مدیریتی بررسی کنید:

```powershell
Invoke-Command -ComputerName SERVER01,SQL01 -Credential $remoteCredential -ScriptBlock {
  Get-Service prometheus_windows_exporter,prometheus_sql_exporter -ErrorAction SilentlyContinue
}

Test-NetConnection SERVER01 -Port 9182
Test-NetConnection SQL01 -Port 9399
```

در صورت فعال‌بودن Basic Auth:

```powershell
$scrapeCredential = Get-Credential 'prometheus_user'
Invoke-WebRequest 'http://SERVER01:9182/metrics' -Credential $scrapeCredential
Invoke-WebRequest 'http://SQL01:9399/metrics' -Credential $scrapeCredential
```

پاسخ باید HTTP `200` و شامل متریک‌های `windows_` یا `mssql_` باشد. پاسخ `401`
نشانهٔ عدم تطابق credential و timeout معمولاً نشانهٔ Firewall، DNS یا listen
address نادرست است.

#### ۶.۶. ثبت مقصدها در Prometheus

templateهای زیر را کپی کنید و فایل جدید را با پسوند `.json` بسازید؛ خود فایل
`.template` خوانده نمی‌شود:

```text
prometheus/targets/windows_exporter/example.json.template
prometheus/targets/sql_exporter/example.json.template
```

نمونهٔ حداقلی Windows Exporter:

```json
[
  {
    "targets": ["SERVER01.example.local:9182"],
    "labels": {
      "__scheme__": "http",
      "instance": "SERVER01",
      "environment": "production",
      "owner": "infrastructure-team"
    }
  }
]
```

برای SQL Exporter نیز فایل مشابهی زیر `targets/sql_exporter/` با پورت `9399`
بسازید. مقدار `__scheme__` باید با TLS واقعی exporter برابر باشد. رمز plain-text
متناظر با bcrypt را در فایل‌های زیر قرار دهید و دسترسی filesystem را فقط به حساب
سرویس Prometheus بدهید:

```text
prometheus/secrets/windows-exporter-password
prometheus/secrets/sql-exporter-password
```

پس از کپی فایل‌ها به سرور مرکزی، config را بررسی و reload کنید:

```powershell
# Windows central server
& 'C:\Program Files\Observability\Prometheus\bin\promtool.exe' check config `
  'C:\Program Files\Observability\Prometheus\config\prometheus.yml'
Restart-Service prometheus
```

```bash
# Linux central server
sudo promtool check config /etc/prometheus/config/prometheus.yml
sudo systemctl reload prometheus
```

در پایان صفحهٔ `http://<prometheus>:9090/targets` را بررسی کنید؛ هر دو job باید
`UP` باشند.

#### ۶.۷. rollout و بازگشت

ابتدا فقط یک سرور آزمایشی از هر نقش را deploy کنید. بعد از مشاهده حداقل چند scrape
موفق و صحت داشبورد، فهرست سرورها را به installer بدهید:

```powershell
$productionServers = Get-Content .\servers.txt | Where-Object { $_ -and $_ -notmatch '^\s*#' }
.\scripts\powershell\windows-exporter\Install-WindowsExporterRemote.ps1 `
  -Computers $productionServers `
  -AutoProfile `
  -RemoteCredential $remoteCredential
```

installerها idempotent هستند و اجرای مجدد برای refresh امن است. برای upgrade از
`Upgrade-WindowsExporterRemote.ps1` و `Upgrade-SqlExporterRemote.ps1` و برای حذف
از اسکریپت‌های `Uninstall-*Remote.ps1` استفاده کنید. نصب قبلی در پوشه `_backup`
سرور مقصد نگه‌داری می‌شود؛ قبل از rollback، راهنمای کامل هر exporter را بخوانید:

- [نصب، ارتقا و حذف SQL Exporter](../../sql-exporter/fa/install-upgrade-guide.md)
- [نصب، ارتقا و حذف Windows Exporter](../../windows-exporter/fa/install-upgrade-guide.md)

## مسیر Linux

این مسیر برای توزیع‌های دارای `systemd` طراحی شده است. نصب Nginx همچنین به یکی از
package managerهای `apt-get`، `dnf` یا `yum` نیاز دارد. دستورات را با کاربری اجرا
کنید که اجازه `sudo` دارد.

### ۱. نصب Prometheus

```bash
sudo bash scripts/bash/prometheus/install-prometheus.sh
```

installer سرویس را start نمی‌کند. پیش از start، این فایل‌ها را کامل کنید:

```text
/etc/prometheus/config/web-config.yml
/etc/prometheus/secrets/sql-exporter-password
/etc/prometheus/secrets/windows-exporter-password
/etc/prometheus/targets/*/*.json
```

سپس:

```bash
sudo promtool check web-config /etc/prometheus/config/web-config.yml
sudo promtool check config /etc/prometheus/config/prometheus.yml
sudo systemctl enable --now prometheus
sudo systemctl status prometheus --no-pager
curl -fsS -u admin http://127.0.0.1:9090/-/healthy
```

برای تغییر مسیر config یا TSDB، متغیرهای محیطی مستندشده در
[راهنمای Prometheus](../../prometheus/fa/installation.md) را استفاده کنید.

### ۲. نصب Alertmanager

در Linux، باینری آفلاین موجود در repository را به همراه یک config نهایی نصب کنید.
مثال زیر کانفیگ SQL Exporter را انتخاب می‌کند؛ برای Windows Exporter مسیر را تغییر
دهید و برای استفاده هم‌زمان، ابتدا کانفیگ‌ها و templateها را ادغام کنید.

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin alertmanager 2>/dev/null || true
sudo install -m 0755 alertmanager/bin/linux-amd64/alertmanager /usr/local/bin/alertmanager
sudo install -m 0755 alertmanager/bin/linux-amd64/amtool /usr/local/bin/amtool
sudo install -d -o alertmanager -g alertmanager -m 0750 /etc/alertmanager/templates
sudo install -d -o alertmanager -g alertmanager -m 0750 /var/lib/alertmanager
sudo install -m 0640 -o root -g alertmanager \
  alertmanager/sql-exporter/alertmanager.yml /etc/alertmanager/alertmanager.yml
sudo install -m 0640 -o root -g alertmanager \
  alertmanager/sql-exporter/templates/*.tmpl /etc/alertmanager/templates/

cd /etc/alertmanager
sudo amtool check-config alertmanager.yml
```

تمام `CHANGE_ME_*`ها را قبل از start جایگزین کنید. سپس unit زیر را در
`/etc/systemd/system/alertmanager.service` بسازید:

```ini
[Unit]
Description=Prometheus Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=alertmanager
Group=alertmanager
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager \
  --web.listen-address=127.0.0.1:9093
Restart=on-failure
RestartSec=5s
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/var/lib/alertmanager

[Install]
WantedBy=multi-user.target
```

فعال‌سازی و بررسی:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now alertmanager
sudo systemctl status alertmanager --no-pager
curl -fsS http://127.0.0.1:9093/-/ready
amtool --alertmanager.url=http://127.0.0.1:9093 alert query
```

اگر Alertmanager روی میزبان جداست، listen address و Firewall را متناسب با شبکه
تنظیم و target بخش `alerting.alertmanagers` در Prometheus را به
`<alertmanager-host>:9093` تغییر دهید. سپس:

```bash
sudo promtool check config /etc/prometheus/config/prometheus.yml
sudo systemctl reload prometheus
```

برای تغییر config پس از نصب، ابتدا در `/etc/alertmanager` دستور
`amtool check-config alertmanager.yml` را اجرا و سپس
`sudo systemctl reload alertmanager` را امتحان کنید؛ اگر unit جاری reload را
پشتیبانی نمی‌کند، `sudo systemctl restart alertmanager` اجرا شود.

### ۳. نصب Grafana

ابتدا فایل رمز را خارج از repository بسازید و دسترسی آن را محدود کنید:

```bash
sudo install -d -m 700 /root/secrets
read -rsp 'Grafana admin password: ' GRAFANA_ADMIN_PASSWORD; echo
printf '%s' "$GRAFANA_ADMIN_PASSWORD" | sudo tee /root/secrets/grafana-admin-password >/dev/null
sudo chmod 600 /root/secrets/grafana-admin-password
unset GRAFANA_ADMIN_PASSWORD
```

اگر Prometheus دارای Basic Auth است، فایل رمز آن را نیز به همین روش بسازید و نصب
را اجرا کنید:

```bash
sudo \
  GRAFANA_ADMIN_PASSWORD_FILE=/root/secrets/grafana-admin-password \
  GRAFANA_PROMETHEUS_URL=http://127.0.0.1:9090 \
  GRAFANA_PROMETHEUS_USER=admin \
  GRAFANA_PROMETHEUS_PASSWORD_FILE=/root/secrets/prometheus-password \
  bash scripts/bash/grafana/install-grafana.sh

sudo systemctl enable --now grafana
sudo systemctl status grafana --no-pager
curl -fsS http://127.0.0.1:3000/api/health
```

اگر Prometheus بدون Basic Auth است، دو متغیر مربوط به user/password آن را حذف
کنید. جزئیات: [راهنمای Grafana](../../grafana/fa/installation.md)

### ۴. نصب Nginx

```bash
sudo env NGINX_OPEN_FIREWALL=1 \
  bash scripts/bash/nginx/install-nginx.sh

sudo nginx -t
sudo systemctl status nginx --no-pager
curl -fsS http://127.0.0.1/healthz
```

برای production، TLS را تنظیم کنید و Prometheus/Grafana را فقط روی
`127.0.0.1` در دسترس قرار دهید. جزئیات: [راهنمای Nginx](../../nginx/fa/installation.md)

### ۵. exporterها

Linux میزبان مرکزی است، اما exporterهای این repository برای مانیتورکردن Windows
و Microsoft SQL Server روی سرورهای Windows مقصد مستقر می‌شوند. اسکریپت‌های
PowerShell را از یک ایستگاه مدیریتی Windows اجرا کنید و آدرس endpointهای حاصل را
در targetهای Prometheus روی Linux ثبت کنید.

## چک‌لیست نهایی

- در Prometheus، صفحهٔ `/targets` همه endpointهای مورد انتظار را `UP` نشان دهد.
- در Prometheus، صفحهٔ `/alertmanagers` وضعیت Alertmanager را `UP` نشان دهد.
- `amtool alert query` بدون خطای اتصال اجرا شود و یک هشدار آزمایشی به گیرندهٔ
  کنترل‌شده ارسال شده باشد.
- در Grafana، datasource پرومتئوس نتیجهٔ `Data source is working` بدهد.
- داشبوردهای provisionشده بدون خطای datasource باز شوند.
- `http://<host>/healthz` از مسیر Nginx پاسخ موفق بدهد.
- دسترسی مستقیم `3000` و `9090` از شبکهٔ عمومی مسدود باشد، مگر اینکه طراحی شما
  عمداً خلاف آن باشد.
- restart سرویس‌های Prometheus، Alertmanager، Grafana و Nginx آزمایش و لاگ‌ها بررسی شوند.
- secret واقعی، password یا فایل target حساس در Git ثبت نشده باشد.

## عیب‌یابی سریع

| نشانه | بررسی اولیه |
|---|---|
| Prometheus بالا نمی‌آید | خروجی `promtool check config` و log سرویس |
| Alertmanager بالا نمی‌آید | خروجی `amtool check-config`، باقی‌ماندن `CHANGE_ME_*` و log سرویس |
| هشدار ارسال نمی‌شود | صفحه `/alertmanagers` پرومتئوس، route/receiver، SMTP یا webhook |
| Target برابر `DOWN` است | DNS، Firewall، پورت exporter و تطابق Basic Auth |
| Grafana datasource خطا دارد | URL پرومتئوس و credential ذخیره‌شده |
| Nginx پاسخ `502` می‌دهد | وضعیت Grafana/Prometheus و آدرس backend |
| سرویس Windows ساخته نمی‌شود | اجرای PowerShell به‌صورت Administrator و وجود NSSM |
| سرویس Linux start نمی‌شود | `journalctl -u <service> -n 100 --no-pager` |
