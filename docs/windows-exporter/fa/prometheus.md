# راهنمای پوشه prometheus/

[English](../en/prometheus.md)

این پوشه را کنار کانفیگ Prometheus کپی کنید (یا مسیر مطلق به `rule_files` بدهید).

کاتالوگ Alert: [Alerting](alerting.md) · نصب ruleها: [Prometheus rules](prometheus-rules.md) · Alertmanager: [Alertmanager](alertmanager.md)

## شروع سریع (SQL Server)

محتوای [`prometheus/scrape-configs/windows-exporter/mssql.yml`](../../../prometheus/scrape-configs/windows-exporter/mssql.yml) را در `prometheus.yml` ادغام کنید:

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
| `profiles/host.yml` | پشته Host |
| `profiles/mssql.yml` | Host + MSSQL |
| `profiles/data-platform.yml` | MSSQL + SSAS + Cluster |
| `profiles/ssas.yml` | بسته نقش SSAS |
| `profiles/cluster.yml` | بسته نقش Cluster |
| `profiles/terminal.yml` | بسته نقش Terminal |
| `profiles/dynamics.yml` | بسته نقش Dynamics |
| `profiles/all.yml` | همه |

## Alertmanager (SMS و Email)

| اولویت | کانال‌ها |
|---|---|
| P0 | SMS webhook + Email |
| P1 | Email + SMS webhook |
| P2 | فقط Email |

جزئیات و placeholderها: [Alertmanager](alertmanager.md)
