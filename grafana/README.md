# Grafana

Grafana can be installed as an automatic Windows service with NSSM. The
installer provisions the Prometheus datasource and all dashboards in this
directory, configures persistent data and rotating logs, and verifies
`/api/health` after startup.

Runtime layout follows the same platform convention as Prometheus and Nginx:

- `bin/windows-amd64/`: Windows executable, license, and version metadata
- `bin/linux-amd64/`: Linux executable, license, and version metadata
- `runtime/`: shared `public`, `conf`, and bundled plugin assets

- Windows installation: [فارسی](../docs/grafana/fa/installation.md) · [English](../docs/grafana/en/installation.md)
- Linux systemd installation is covered in the same bilingual guides.

Documentation (FA / EN):

- Per-dashboard reference (83 dashboards): [فارسی](../docs/grafana/dashboards/fa/README.md) · [English](../docs/grafana/dashboards/en/README.md)
- SQL Exporter: [فارسی](../docs/sql-exporter/fa/grafana.md) · [English](../docs/sql-exporter/en/grafana.md)
- Windows Exporter: داشبوردها در [مستندات فارسی](../docs/windows-exporter/fa/README.md) و [English docs](../docs/windows-exporter/en/README.md) معرفی شده‌اند.

Dashboard JSON files live under `dashboards/sql-exporter/` and `dashboards/windows-exporter/`. Collector-level dashboards use the `Collector/` or `collector/` subdirectory of the relevant exporter.
