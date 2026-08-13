# sql_exporter docs

This folder contains the full documentation set in English and Persian.

Current documented SQL Exporter version: **0.24.4**.

## Collector docs

- English: [collectors/README.md](collectors/README.md)
- Persian: [../fa/collectors/README.md](../fa/collectors/README.md)

## Setup docs

- [Collector authoring guide](collector-guide.md)
- [Install and upgrade guide](install-upgrade-guide.md) ([HTML](install-upgrade-guide.html)) — [Required access](install-upgrade-guide.md#required-access)
- [Install and config guide](install-config-guide.md) (includes default port `9399` and how to create Basic Auth)
- [Collector profile guide](profiles.md)
- [prometheus/ folder guide](prometheus.md)
- [Alerting catalog](alerting.md)
- [Alertmanager — SMS and Email](alertmanager.md)
- [Prometheus rules and alerts](prometheus-rules.md)
- [Grafana dashboards](grafana.md)

## Grafana

- Dashboard JSON files: [`../../../grafana/dashboards/sql-exporter/`](../../../grafana/dashboards/sql-exporter/) (Overview/NOC) and [`../../../grafana/dashboards/sql-exporter/Collector/`](../../../grafana/dashboards/sql-exporter/Collector/)
- Import / sync guide: [grafana.md](grafana.md)
- Export from Grafana: `scripts/powershell/sql-exporter/Export-GrafanaDashboards.ps1`

