# Prometheus Rule و Alert برای windows_exporter

[English](../en/prometheus-rules.md)

کاتالوگ کامل Alertها، اولویت‌ها و Thresholdها: [راهنمای Alerting](alerting.md).  
راهنمای پوشه و پروفایل‌ها: [prometheus/](prometheus.md) · Routing SMS/Email: [Alertmanager](alertmanager.md)

## ساختار

| مسیر | کاربرد |
|---|---|
| `prometheus/alert-rules/windows-exporter/` | Recording و Alerting ruleها (قابل ارجاع در `rule_files`) |
| `prometheus/scrape-configs/windows-exporter/` | پروفایل‌های آمادهٔ `rule_files` بر اساس اولویت و نقش |
| `alertmanager/windows-exporter/` | Routing بر اساس P0/P1/P2 برای SMS و Email |

### Rule files

| فایل | اولویت / نقش | محتوا |
|---|---|---|
| `windows_exporter-recording.rules.yml` | — | CPU، memory، disk free/latency، pagefile، RDS sessions، buffer cache |
| `windows_exporter-p0-availability.rules.yml` | P0 | Target down، collector fail، سرویس Data Platform، time skew، MSSQL collector |
| `windows_exporter-p0-host.rules.yml` | P0 | Disk < ۵٪، commit charge بحرانی |
| `windows_exporter-p0-mssql.rules.yml` | P0 | Log used بحرانی، AG send/redo/delay |
| `windows_exporter-p1-host.rules.yml` | P1 | CPU، memory، disk ۱۰٪، latency، commit |
| `windows_exporter-p1-mssql.rules.yml` | P1 | Buffer cache، PLE، deadlock، blocking، memory grant، log ۸۵٪ |
| `windows_exporter-p2-host.rules.yml` | P2 | Processor queue، network errors، pagefile، license |
| `windows_exporter-p2-mssql.rules.yml` | P2 | Long tran، SQL errors، latch/lock waits، tempdb، connections |
| `windows_exporter-role-cluster.rules.yml` | نقش | Failover Cluster node/network/resource |
| `windows_exporter-role-terminal.rules.yml` | نقش | TermService و sessionهای RDS |
| `windows_exporter-role-dynamics.rules.yml` | نقش | AX / D365 services و process |
| `windows_exporter-role-ssas.rules.yml` | نقش | دسترس‌پذیری، processing، backup، امنیت و حافظه SSAS |

### Alert profiles (`prometheus/scrape-configs/windows-exporter/`)

هر فایل یک بلوک آمادهٔ `rule_files` است. محتوای آن را در `prometheus.yml` کپی/ادغام کنید.

| پروفایل | کاربرد پیشنهادی |
|---|---|
| `p0-critical.yml` | فقط صفحه‌شدن فوری (P0) |
| `p1-high.yml` | P0 + P1 |
| `p2-medium.yml` | پشته کامل اولویت بدون نقش |
| `host.yml` | سرور Windows عمومی |
| `mssql.yml` | SQL Server |
| `data-platform.yml` | SQL + SSAS + Cluster |
| `ssas.yml` / `cluster.yml` / `terminal.yml` / `dynamics.yml` | بسته‌های نقش (روی پروفایل پایه اضافه شوند) |
| `all.yml` | همه ruleها (برای lab / canary) |

## نصب در Prometheus

مسیرها نسبت به working directoryای هستند که پوشهٔ `rules/` داخل آن قرار دارد (مثلاً کپی `prometheus/` این پکیج).

نمونهٔ پروفایل SQL:

```yaml
rule_files:
  - "rules/windows_exporter-recording.rules.yml"
  - "rules/windows_exporter-p0-availability.rules.yml"
  - "rules/windows_exporter-p0-host.rules.yml"
  - "rules/windows_exporter-p0-mssql.rules.yml"
  - "rules/windows_exporter-p1-host.rules.yml"
  - "rules/windows_exporter-p1-mssql.rules.yml"
  - "rules/windows_exporter-p2-host.rules.yml"
  - "rules/windows_exporter-p2-mssql.rules.yml"
```

یا محتوای یکی از فایل‌های `prometheus/scrape-configs/windows-exporter/*.yml` را عیناً استفاده کنید.

قبل از reload:

```powershell
promtool check rules .\prometheus\rules\*.rules.yml
```

## نکات

- Thresholdها نمونه‌اند و باید با baseline و SLA تنظیم شوند.
- اگر نام job برابر `windows` یا `windows_exporter` نیست، selector `job=~"windows.*"` را اصلاح کنید.
- نبود یک metric لزوماً به معنی سلامت نیست؛ `up` و collector success مستقل کنترل شوند.
- Recording ruleها پیش‌نیاز alertهای CPU / memory / disk / RDS / buffer cache هستند.
- Ruleهای SSAS به متریک‌های textfile وابسته‌اند. تا قبل از نصب `Install-SsasMetricsTask.ps1` فقط روی targetهای SSAS فعال کنید. جزئیات: [مانیتورینگ SSAS](ssas-monitoring.md).
- بسته‌های Cluster / Terminal / Dynamics را فقط وقتی collector/profile مربوطه scrape می‌شود اضافه کنید تا noise کم شود.
