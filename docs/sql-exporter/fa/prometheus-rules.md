# نمونه Rule و Alert برای SQL Exporter

[English version](../en/prometheus-rules.md)

کاتالوگ کامل Alertها، اولویت‌ها و Thresholdها: [راهنمای Alerting](alerting.md).
Routing SMS/Email: [Alertmanager](alertmanager.md).
راهنمای پوشه: [prometheus/](prometheus.md).

ساختار مانند `windows_exporter` است. Thresholdها باید پیش از Production بر اساس
SLA، Baseline و نقش هر سرور تنظیم شوند.

## ساختار

| مسیر | کاربرد |
|---|---|
| `prometheus/alert-rules/sql-exporter/` | Recording و Alerting ruleها (قابل ارجاع در `rule_files`) |
| `prometheus/scrape-configs/sql-exporter/` | پروفایل‌های آمادهٔ `rule_files` بر اساس اولویت و نقش |
| `alertmanager/sql-exporter/` | Routing بر اساس P0/P1/P2 برای SMS و Email |
| `prometheus/prometheus.yml` | نمونه پیش‌فرض (P0+P1) + اتصال Alertmanager |

### Rule files

| فایل | اولویت / نقش | محتوا |
|---|---|---|
| `sql_exporter-recording.rules.yml` | — | نرخ‌ها و KPIها |
| `sql_exporter-p0-availability.rules.yml` | P0 | Target down، DB state، backup، integrity، restore |
| `sql_exporter-p0-hadr.rules.yml` | P0 | Always On / WSFC / FCI |
| `sql_exporter-p0-jobs.rules.yml` | P0 | SQL Agent job failed |
| `sql_exporter-p1-performance.rules.yml` | P1 | CPU، I/O، log، blocking، memory، tempdb، … |
| `sql_exporter-p1-space.rules.yml` | P1 | استفاده فضای فایل |
| `sql_exporter-p1-jobs.rules.yml` | P1 | تاریخچه / آخرین اجرای ناموفق Job |
| `sql_exporter-p1-signals.rules.yml` | P1 | سیگنال ERRORLOG |
| `sql_exporter-p2-performance.rules.yml` | P2 | sessions، parallelism، plan cache، waits، … |
| `sql_exporter-p2-maintenance.rules.yml` | P2 | index، stats، autogrowth، Query Store |
| `sql_exporter-p2-config.rules.yml` | P2 | تنظیمات ناایمن، رشد سریع |
| `sql_exporter-role-*.rules.yml` | نقش | Replication، SSIS، Security، CDC |

### Alert profiles (`prometheus/scrape-configs/sql-exporter/`)

هر فایل یک بلوک آمادهٔ `rule_files` است. محتوای آن را در `prometheus.yml` کپی/ادغام کنید.

| پروفایل | کاربرد پیشنهادی |
|---|---|
| `p0-critical.yml` | فقط صفحه‌شدن فوری (P0) |
| `p1-high.yml` | P0 + P1 (پیشنهادی production) |
| `p2-medium.yml` / `oltp.yml` | پشته کامل اولویت بدون نقش |
| `restore-secondary.yml` | ثانویه restore / log shipping |
| `replication.yml` / `ssis.yml` / `security.yml` / `cdc.yml` | بسته‌های نقش |
| `all.yml` | همه ruleها (lab / canary) |

پروفایل‌های Collector exporter برای همین Alertها: `profiles/alert-p0.yml`،
`alert-p1.yml`، `alert-p2.yml` — جزئیات در [profiles.md](profiles.md).

## نصب در Prometheus

مسیرها نسبت به working directoryای هستند که پوشهٔ `rules/` داخل آن قرار دارد.

نمونهٔ پروفایل P1:

```yaml
rule_files:
  - "rules/sql_exporter-recording.rules.yml"
  - "rules/sql_exporter-p0-availability.rules.yml"
  - "rules/sql_exporter-p0-hadr.rules.yml"
  - "rules/sql_exporter-p0-jobs.rules.yml"
  - "rules/sql_exporter-p1-performance.rules.yml"
  - "rules/sql_exporter-p1-space.rules.yml"
  - "rules/sql_exporter-p1-jobs.rules.yml"
  - "rules/sql_exporter-p1-signals.rules.yml"
```

یا محتوای یکی از فایل‌های `prometheus/scrape-configs/sql-exporter/*.yml` را عیناً استفاده کنید.

قبل از reload:

```powershell
promtool check rules .\prometheus\rules\*.rules.yml
promtool check config .\prometheus\prometheus.yml
```

## نکات

- Thresholdها نمونه‌اند و باید با baseline و SLA تنظیم شوند.
- اگر نام job برابر `sql_exporter` نیست، selector `job=~"sql.*"` را اصلاح کنید.
- نبود یک metric لزوماً به معنی سلامت نیست؛ `up` و scrape errors مستقل کنترل شوند.
- بسته‌های نقش را فقط وقتی collector مربوطه scrape می‌شود اضافه کنید تا noise کم شود.
- برای routing در Alertmanager از labelهای `priority` و `severity` استفاده کنید.
