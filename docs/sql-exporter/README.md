# sql_exporter docs

This folder contains the full documentation set in English and Persian.

Current documented SQL Exporter version: **0.24.4**.

Default scrape port: **9399**. Basic Auth is **disabled** by default — see the install/config guides.

## Collector docs

- English: [en/collectors/README.md](en/collectors/README.md)
- Persian: [fa/collectors/README.md](fa/collectors/README.md)

## Setup docs

- English entry: [en/README.md](en/README.md)
- Persian entry: [fa/README.md](fa/README.md)
- English collector guide: [en/collector-guide.md](en/collector-guide.md)
- Persian collector guide: [fa/collector-guide.md](fa/collector-guide.md)
- English install and upgrade guide: [en/install-upgrade-guide.md](en/install-upgrade-guide.md) ([HTML](en/install-upgrade-guide.html)) — includes [Required access](en/install-upgrade-guide.md#required-access)
- Persian install and upgrade guide: [fa/install-upgrade-guide.md](fa/install-upgrade-guide.md) ([HTML](fa/install-upgrade-guide.html)) — شامل [دسترسی‌های لازم](fa/install-upgrade-guide.md#دسترسیهای-لازم)
- English install/config guide: [en/install-config-guide.md](en/install-config-guide.md) (port `9399` + Basic Auth)
- Persian install/config guide: [fa/install-config-guide.md](fa/install-config-guide.md) (پورت `9399` + Basic Auth)
- English profiles: [en/profiles.md](en/profiles.md)
- Persian profiles: [fa/profiles.md](fa/profiles.md)
- English prometheus/ guide: [en/prometheus.md](en/prometheus.md)
- Persian prometheus/ guide: [fa/prometheus.md](fa/prometheus.md)
- English alerting catalog: [en/alerting.md](en/alerting.md)
- Persian alerting catalog: [fa/alerting.md](fa/alerting.md)
- English Alertmanager: [en/alertmanager.md](en/alertmanager.md)
- Persian Alertmanager: [fa/alertmanager.md](fa/alertmanager.md)
- English Prometheus rules: [en/prometheus-rules.md](en/prometheus-rules.md)
- Persian Prometheus rules: [fa/prometheus-rules.md](fa/prometheus-rules.md)
- English Grafana dashboards: [en/grafana.md](en/grafana.md)
- Persian Grafana dashboards: [fa/grafana.md](fa/grafana.md)

## Grafana

- Dashboard JSON: [`../../grafana/dashboards/sql-exporter/`](../../grafana/dashboards/sql-exporter/) (Overview/NOC) and [`../../grafana/dashboards/sql-exporter/Collector/`](../../grafana/dashboards/sql-exporter/Collector/)
- Import / sync: [en/grafana.md](en/grafana.md) · [fa/grafana.md](fa/grafana.md)
- Export from Grafana: `../../scripts/powershell/sql-exporter/Export-GrafanaDashboards.ps1`
