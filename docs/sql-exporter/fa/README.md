# مستندات sql_exporter

نسخه فعلی SQL Exporter در این مستندات: **0.24.4**.

این پوشه شامل مستندات کامل به زبان انگلیسی و فارسی است.

## مستندات Collectorها

- انگلیسی: [../en/collectors/README.md](../en/collectors/README.md)
- فارسی: [collectors/README.md](collectors/README.md)

## مستندات راه‌اندازی

- [راهنمای نوشتن Collector](collector-guide.md)
- [راهنمای نصب و ارتقا](install-upgrade-guide.md) ([HTML](install-upgrade-guide.html)) — [دسترسی‌های لازم](install-upgrade-guide.md#دسترسیهای-لازم)
- [راهنمای نصب و کانفیگ](install-config-guide.md) (شامل پورت پیش‌فرض `9399` و راهنمای ایجاد Basic Auth)
- [راهنمای پروفایل‌ها](profiles.md)
- [راهنمای پوشه prometheus/](prometheus.md)
- [کاتالوگ Alerting](alerting.md)
- [Alertmanager — SMS و Email](alertmanager.md)
- [راهنمای Prometheus Rule و Alert](prometheus-rules.md)
- [داشبوردهای Grafana](grafana.md)

## Grafana

- فایل‌های JSON داشبورد: [`../../../grafana/dashboards/sql-exporter/`](../../../grafana/dashboards/sql-exporter/) (Overview/NOC) و [`../../../grafana/dashboards/sql-exporter/Collector/`](../../../grafana/dashboards/sql-exporter/Collector/)
- راهنمای Import / sync: [grafana.md](grafana.md)
- Export از Grafana: `scripts/powershell/sql-exporter/Export-GrafanaDashboards.ps1`

