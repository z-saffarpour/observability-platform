# راهنمای پوشه prometheus/

[English](../en/prometheus.md)

این پوشه را کنار کانفیگ Prometheus کپی کنید (یا مسیر مطلق به `rule_files` بدهید).

کاتالوگ Alert: [Alerting](alerting.md) · نصب ruleها: [Prometheus rules](prometheus-rules.md) · Alertmanager: [Alertmanager](alertmanager.md)

## شروع سریع (SQL Server / OLTP)

محتوای [`prometheus/scrape-configs/sql-exporter/oltp.yml`](../../../prometheus/scrape-configs/sql-exporter/oltp.yml) یا [`p1-high.yml`](../../../prometheus/scrape-configs/sql-exporter/p1-high.yml) را در `prometheus.yml` ادغام کنید:

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

اعتبارسنجی:

```powershell
promtool check rules .\prometheus\rules\*.rules.yml
```

## پروفایل‌های alert

| فایل | اولویت / محدوده |
|---|---|
| `profiles/p0-critical.yml` | فقط P0 |
| `profiles/p1-high.yml` | P0 + P1 |
| `profiles/p2-medium.yml` | P0 + P1 + P2 |
| `profiles/oltp.yml` | پشته کامل اولویت (بدون بسته‌های نقش) |
| `profiles/restore-secondary.yml` | P0 availability + HADR + jobs |
| `profiles/replication.yml` | بسته نقش Replication |
| `profiles/ssis.yml` | بسته نقش SSIS |
| `profiles/security.yml` | بسته نقش Security |
| `profiles/cdc.yml` | بسته نقش CDC |
| `profiles/all.yml` | همه |

حداقل Collectorهای exporter برای این Alertها: `profiles/alert-p0.yml`، `alert-p1.yml`، `alert-p2.yml`.

## Alertmanager (SMS و Email)

Routing در [`alertmanager/sql-exporter/`](../../../alertmanager/sql-exporter/):

| اولویت | کانال‌ها | تکرار |
|---|---|---|
| P0 | SMS webhook + Email | ۱۵ دقیقه |
| P1 | Email + SMS webhook | ۱ ساعت |
| P2 | فقط Email | ۱۲ ساعت |

جزئیات و placeholderها: [Alertmanager](alertmanager.md)
