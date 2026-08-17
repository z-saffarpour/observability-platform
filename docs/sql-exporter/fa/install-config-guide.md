# راهنمای نصب و کانفیگ `sql_exporter`

این سند برای نصب اولیه و راه‌اندازی دوباره `sql_exporter` روی سرورهای SQL Server نوشته شده است.

نسخه مستند و اعتبارسنجی‌شده Exporter در این پروژه **0.24.4** است.

برای نصب ریموت، ارتقای نسخه، بکاپ و rollback ببینید: [راهنمای نصب و ارتقا](install-upgrade-guide.md)

## پیش‌نیازها

- دسترسی به فایل‌های پکیج `sql_exporter`
- دسترسی به SQL Server مقصد
- حسابی که بتواند `VIEW SERVER STATE` و `VIEW ANY DEFINITION` بگیرد
- پورت scrape باز برای Prometheus (پیش‌فرض upstream: **9399**)

## فایل‌های مهم

- `sql_exporter.exe`
- `sql_exporter.yml`
- `collector/*.collector.yml`
- `profiles/*.yml`
- `web-config.yml` — پورت HTTP جداگانه نیست؛ برای TLS و **Basic Auth** استفاده می‌شود

## مراحل نصب

### 1) فایل‌ها را روی سرور کپی کن

همه فایل‌های پوشه `sql_exporter` را در مسیر نهایی قرار بده.

### 2) اتصال SQL را تنظیم کن

در `sql_exporter.yml` مقدار `data_source_name` را تنظیم کن:

```yaml
data_source_name: 'sqlserver://HOST:PORT?trusted+connection=yes&app+name=sql_exporter'
```

نکته:
- `HOST` و `PORT` باید با SQL Server واقعی هماهنگ باشند.
- اگر instance نام‌دار است، پورت درست را وارد کن.

### 3) collectorها را انتخاب کن

دو حالت داریم:

#### حالت ساده

```yaml
collectors: [mssql_*]
```

یعنی همه collectorهای موجود در `collector/` لود و اجرا می‌شوند.

#### حالت profile محور

برای سرورهای شلوغ بهتر است فقط collectorهای لازم فعال شوند.

پیشنهادی: فهرست آماده از `profiles/` را با همان پارامتر `-Profile` مثل Windows Exporter اعمال کنید:

```powershell
.\scripts\powershell\sql-exporter\Deploy-SqlExporterConfig.ps1 -Computers SQL01 -Profile oltp.yml
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 -Computers SQL01 -Profile oltp.yml
```

فهرست کامل پروفایل‌ها (`oltp.yml`، `dwh.yml`، …) در [راهنمای پروفایل‌ها](profiles.md) است.

مثال OLTP (کپی دستی داخل `sql_exporter.yml`):

```yaml
collectors:
  - mssql_standard
  - mssql_backup
  - mssql_alwayson
  - mssql_alwayson_events
  - mssql_waits
  - mssql_memory
  - mssql_tempdb
  - mssql_file_io
```

### 4) دسترسی‌ها را بده

#### ویندوز / شبکه (مثل windows_exporter)

```powershell
.\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1 -ShowRequirements
.\scripts\powershell\sql-exporter\Set-SqlExporterRequiredAccess.ps1 -PrometheusRemoteAddress '<PROMETHEUS_IP>'
.\scripts\powershell\sql-exporter\Test-SqlExporterRequiredAccess.ps1
```

جزئیات و ماتریس نقش‌ها: [دسترسی‌های لازم](install-upgrade-guide.md#دسترسیهای-لازم).

#### SQL Server

حداقل مجوزهای پایه:

```sql
GRANT VIEW SERVER STATE TO [DOMAIN\SqlExporterAccount];
GRANT VIEW ANY DEFINITION TO [DOMAIN\SqlExporterAccount];
```

پیشنهادی (least-privilege کامل برای collectorهای فعال): در SSMS به‌عنوان sysadmin اسکریپت زیر را با `@LoginName` مناسب اجرا کنید:

```text
scripts/sql/Create-SqlExporterLogin.sql
```

برای حساب ویندوز: `@CreateSqlLogin = 0` و `@LoginName = N'DOMAIN\SqlExporterAccount'`.

برای بعضی collectorها دسترسی اضافه لازم است:

- `mssql_backup`, `mssql_restore`, `mssql_job_*` → `msdb` (فلگ `@GrantMsdbRead`)
- `mssql_ssis` → `SSISDB` (`@GrantSsisdbRead`)
- `mssql_errorlog_signals` / failed logins → `xp_readerrorlog` (`@GrantReadErrorLog`)
- `mssql_index_fragmentation` و collectorهای per-DB → دسترسی DBهای کاربر (`@GrantUserDatabaseAccess`)
- `mssql_security` (خواندن فایل Audit) → معمولاً `CONTROL SERVER` (در اسکریپت least-privilege عمداً داده نمی‌شود)

### 5) سرویس را اجرا یا restart کن

پیش از Restart سرویس، کل تنظیمات را اعتبارسنجی کن:

```powershell
.\sql_exporter.exe "-config.file=sql_exporter.yml" -config.check
```

اگر سرویس از قبل ساخته شده:
- فایل config را جایگزین کن
- سرویس را restart کن

اگر فقط برای تست می‌خواهی اجرا کنی:
- exporter را با config فعلی بالا بیاور

### 6) پورت scrape و Basic Auth (اختیاری)

#### پورت (پیش‌فرض)

پیش‌فرض upstream و اسکریپت نصب: **`:9399`**

- نصب ریموت: پارامتر `-ListenAddress` (مثال: `-ListenAddress ':9399'`)
- Basic Auth در نصب/اپگرید ریموت: `-BasicAuthUsername` + `-BasicAuthHash` (پیشنهادی) یا `-BasicAuthPassword` (نیاز به Python با `bcrypt` روی کلاینت)؛ یا `-WebConfigPath` برای فایل سفارشی
- اپگرید ریموت: بدون `-ListenAddress` آدرس فعلی سرویس حفظ می‌شود؛ با `-PreserveWebConfig` فایل `web-config.yml` ریموت حفظ می‌شود
- دستی: فلگ `--web.listen-address=:9399` روی سرویس / ImagePath

روی فایروال host، پورت انتخاب‌شده را برای scrape از Prometheus باز کن.

#### Basic Auth — پیش‌فرض

در پکیج فعلی، `basic_auth_users` در `web-config.yml` **غیرفعال** است (بدون احراز هویت).  
اگر بخش خالی بماند یا کامنت باشد، `/metrics` بدون username/password در دسترس است.

مرجع رسمی: [Prometheus exporter toolkit — web configuration](https://github.com/prometheus/exporter-toolkit/blob/master/docs/web-configuration.md)

#### فعال‌سازی Basic Auth

1. یک پسورد قوی انتخاب کن و **hash از نوع bcrypt** بساز (نه پسورد خام در فایل).

با Python (اگر `bcrypt` نصب است):

```powershell
python -c "import bcrypt; print(bcrypt.hashpw(b'YOUR_PASSWORD', bcrypt.gensalt(rounds=12)).decode())"
```

یا از یک ابزار تولید bcrypt معتبر (مثلاً [bcrypt-generator.com](https://bcrypt-generator.com/)) با cost حدود **12** استفاده کن.

2. در `web-config.yml` بخش کاربران را فعال کن:

```yaml
basic_auth_users:
  prometheus_user: $2a$12$REPLACE_WITH_BCRYPT_HASH
```

می‌توانی چند کاربر اضافه کنی؛ هر کلید یک username و هر مقدار hash همان کاربر است.

3. مطمئن شو سرویس با `--web.config.file` به همین فایل اشاره می‌کند (`Install-SqlExporterRemote.ps1` و `Upgrade-SqlExporterRemote.ps1` این کار را انجام می‌دهند؛ در صورت امکان به‌جای ویرایش دستی از `-BasicAuthUsername` + `-BasicAuthHash` یا `-WebConfigPath` در نصب/اپگرید استفاده کن).

4. سرویس را Restart کن:

```powershell
Restart-Service prometheus_sql_exporter
```

5. تست محلی با credential:

```powershell
$user = 'prometheus_user'
$pass = 'YOUR_PASSWORD'
$pair = "{0}:{1}" -f $user, $pass
$b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
Invoke-WebRequest -Uri 'http://127.0.0.1:9399/metrics' -Headers @{ Authorization = "Basic $b64" }
```

بدون هدر Authorization باید پاسخ **401** بگیری.

#### تنظیم Prometheus برای scrape با Basic Auth

روی سمت Prometheus (نه روی exporter) پسورد را به‌صورت **متن ساده** در secret/`basic_auth` بگذار:

```yaml
- job_name: sql_exporter
  basic_auth:
    username: prometheus_user
    password: YOUR_PASSWORD
  static_configs:
    - targets:
        - 'HOSTNAME:9399'
```

اگر Basic Auth را روشن کردی ولی در job مربوطه `basic_auth` نگذاشتی، scrape با `up=0` و خطای 401 شکست می‌خورد.

#### نکات امنیتی

- hash را در git commit کن؛ پسورد خام را نه.
- پس از تغییر `web-config.yml` حتماً سرویس را Restart کن.
- برای محیط production، Basic Auth یا TLS (یا هر دو) توصیه می‌شود.

## تست سلامت

بعد از اجرا این آدرس را چک کن:

```text
http://HOSTNAME:9399/metrics
```

اگر Basic Auth فعال است، مرورگر/کلاینت باید username و password بپرسد (یا هدر `Authorization: Basic ...` بفرستی).

چیزهایی که باید ببینی:
- `mssql_up`
- `mssql_hostname`
- `mssql_product_version`
- متریک‌های collectorهای فعال

## انتخاب پروفایل مناسب

### DWH / BI
- `mssql_standard`
- `mssql_backup`
- `mssql_restore`
- `mssql_job_inventory`
- `mssql_alwayson`
- `mssql_alwayson_events`
- `mssql_waits`
- `mssql_memory`
- `mssql_tempdb`
- `mssql_file_io`

### Restore / backup-sync secondary
- `mssql_standard`
- `mssql_restore`
- `mssql_backup`
- `mssql_job_inventory`
- `mssql_job_running`
- `mssql_job_failed`
- `mssql_job_history`
- `mssql_database_space`
- `mssql_file_io`

### OLTP
- `mssql_standard`
- `mssql_backup`
- `mssql_alwayson`
- `mssql_alwayson_events`
- `mssql_waits`
- `mssql_memory`
- `mssql_tempdb`
- `mssql_file_io`
- `mssql_blocking`
- `mssql_log_usage`

### Alert P0 / P1 / P2
حداقل Collector برای Alertهای اولویت‌دار؛ جزئیات در [alerting.md](alerting.md):

```powershell
.\scripts\powershell\sql-exporter\Deploy-SqlExporterConfig.ps1 -Computers SQL01 -Profile alert-p1.yml
```

نمونه `rule_files`: `prometheus/scrape-configs/sql-exporter/p1-high.yml`

## تنظیمات مهم `sql_exporter.yml`

### `scrape_timeout`

زمان اجرا را کنترل می‌کند. برای SQL Serverهای شلوغ، مقدار معقول بگذار.

### `scrape_timeout_offset`

برای اینکه Prometheus زودتر از exporter timeout نکند.

### `min_interval`

برای کنترل اجرای بیش از حد queryهای سنگین.

### `collector_files`

مسیر فایل‌های collector:

```yaml
collector_files:
  - "collector/*.collector.yml"
```

### `enable_query_metrics`

نسخه 0.24.4 می‌تواند زمان اجرای هر Query و تعداد ردیف‌های برگردانده‌شده را
برای عیب‌یابی Rollout و مشکلات کارایی منتشر کند:

```yaml
global:
  enable_query_metrics: true
```

متریک‌های حاصل `query_duration_seconds` و `query_rows_returned` هستند. اگر
Labelهای Query باعث Cardinality نامطلوب می‌شوند، این گزینه را به‌صورت پیش‌فرض
غیرفعال نگه دار.

## عیب‌یابی سریع

### `up=0`
- سرویس exporter down است
- پورت بسته است (پیش‌فرض **9399**)
- config اشتباه است
- Basic Auth روی exporter روشن است ولی در job Prometheus تنظیم نشده (HTTP 401)

### `scrape_errors_total` بالا
- یک query مشکل دارد
- دسترسی SQL کافی نیست
- collector خیلی سنگین است

### متریک خالی است
- instance آن feature را ندارد
- دسترسی لازم وجود ندارد
- collector مربوطه روی آن سرور معنی ندارد

Collectorهای وابسته به Feature مانند CDC، Replication، SSIS، Query Store،
Always On و Resource Governor ممکن است در صورت نبودن Feature یا دیتابیس مربوطه
به‌طور طبیعی هیچ سری زمانی تولید نکنند.

## توصیه عملی برای نیروی جدید

1. اول `sql_exporter.yml` را بخوان.
2. بعد فقط یک profile سبک را فعال کن.
3. `http://HOSTNAME:9399/metrics` را تست کن.
4. بعد collectorهای سنگین‌تر را اضافه کن.
5. همیشه قبل از rollout روی یک سرور تست کن.
