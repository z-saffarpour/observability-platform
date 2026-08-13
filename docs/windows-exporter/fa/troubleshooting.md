# عیب‌یابی windows_exporter

[English](../en/troubleshooting.md)

## سرویس بالا نمی‌آید

```powershell
Get-Service windows_exporter
Get-CimInstance Win32_Service -Filter "Name='windows_exporter'" | Select-Object PathName,StartName,State
Get-WinEvent -LogName Application -MaxEvents 100 | Where-Object ProviderName -Match 'windows_exporter'
```

exporter را با آرگومان‌های ImagePath در console اجرا کنید. خطای `field ... not found` یعنی کانفیگ متعلق به نسخه دیگری است. در 0.31.8، `telemetry.max-requests` معتبر نیست و باید از `terminal_services` به‌جای `logon` استفاده شود.

## پاسخ 401

فقط وقتی رخ می‌دهد که Basic Auth در `web-config.yml` فعال شده باشد. برای نحوهٔ ایجاد و فعال‌سازی به [راهنمای نصب و تنظیمات — Basic Auth](install-config-guide.md#basic-auth-اختیاری) مراجعه کنید.

- آرگومان `--web.config.file` فعال است و `basic_auth_users` خالی نیست.
- username یا رمز Prometheus با `basic_auth_users` هماهنگ نیست.
- bcrypt hash را با رمز قوی بازسازی کنید؛ رمز واضح را داخل Git نگذارید.
- پس از تغییر `web-config.yml` سرویس را `Restart-Service windows_exporter` کنید و `password_file` پرامتهوس را هم به‌روز کنید.

## Connection refused یا timeout

- `web.listen-address`، وضعیت سرویس و Firewall را کنترل کنید.
- از سرور Prometheus دستور `Test-NetConnection SERVER01 -Port 9182` را اجرا کنید.
- زمان scrape را با collector duration مقایسه کنید.

## collector ناموفق

```promql
windows_exporter_collector_success == 0
```

- `mssql`: SQL instance در Registry یافت نشده یا performance counterها قابل دسترسی نیستند.
- `service`: regex روی Service Name است، نه Display Name.
- `process`: دسترسی حساب سرویس و تعداد پردازش‌ها را بررسی کنید.
- `textfile`: مسیر `collector.textfile.directories`، وجود پوشه `textfile_inputs` و اجرای Scheduled Task مربوط به SSAS را بررسی کنید.
- `net`: warning مربوط به experimental بودن sub-collector ممکن است اطلاع‌رسانی باشد، نه failure.

## متریک‌های SSAS ظاهر نمی‌شوند

1. Profile دارای `textfile` باشد (`ssas.yml` یا `data-platform*.yml`) و سرویس restart شده باشد.
2. سرویس `prometheus_windows_ssas` با `Install-SsasMetricsTask.ps1` نصب شده و در وضعیت Running باشد.
3. فایل‌های `textfile_inputs\ssas*.prom` تازه باشند (`ssas_collector_last_run_timestamp_seconds`).
4. کتابخانه‌های ADOMD/AMO و دسترسی حساب Task به Instance بررسی شوند.
5. برای XEvent: ماژول `SqlServer`، مسیر `*.xel` و session مربوط به `scripts/ssas/windows-exporter/ssas-monitoring-xevents.xmla`.

جزئیات بیشتر: [مانیتورینگ SSAS](ssas-monitoring.md).

## ناپدیدشدن metric پس از ارتقا

Release note نسخه‌های بین مبدا و مقصد را بررسی، metric را مستقیماً در `/metrics` جستجو و سپس dashboard/rule را اصلاح کنید. rollback باینری و config باید هماهنگ انجام شود. برای آپگرید ریموت با rollback خودکار به [راهنمای نصب و آپگرید](install-upgrade-guide.md) مراجعه کنید.

## خطای نصب / آپگرید ریموت

- WinRM: `Test-WSMan`، credential Administrator و فعال‌بودن PowerShell Remoting
- فایل پکیج ناقص روی کلاینت: وجود `windows_exporter.exe`، هر دو yml، پوشه `profiles/` و `scripts/powershell/windows-exporter/`
- آپگرید: تطابق `-ExpectedVersion` با `--version` باینری؛ در شکست، بکاپ `_backup\upgrade_...` را بررسی کنید
- Profile نامعتبر یا `performancecounter.example.yml` به‌عنوان Profile سرویس قابل استقرار نیست

برای چک‌لیست و ایجاد دسترسی‌ها:

```powershell
.\scripts\powershell\windows-exporter\Set-WindowsExporterRequiredAccess.ps1 `
  -ComputerName SERVER01 `
  -Credential (Get-Credential) `
  -PrometheusRemoteAddress 10.10.10.20
.\scripts\powershell\windows-exporter\Test-WindowsExporterRequiredAccess.ps1 -ComputerName SERVER01 -Credential (Get-Credential) -IncludeSsasChecks
```
