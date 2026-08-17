# Observability Platform

[فارسی (پیش‌فرض)](README.md) | **English**

This repository provides a unified home for monitoring Windows infrastructure and Microsoft SQL Server with Prometheus, Grafana, and Alertmanager. Persian is the default documentation language.

## Project layout

| Path | Purpose |
|---|---|
| [`exporters/sql-exporter/`](exporters/sql-exporter/) | SQL Exporter binary, configuration, profiles, and collectors |
| [`exporters/windows-exporter/`](exporters/windows-exporter/) | Windows Exporter binary, configuration, and profiles |
| [`prometheus/`](prometheus/) | Exporter-specific scrape configs, recording rules, and alert rules |
| [`grafana/dashboards/`](grafana/dashboards/) | Grafana dashboards for SQL and Windows Exporter |
| [`alertmanager/`](alertmanager/) | Exporter-specific Alertmanager configuration and templates |
| [`scripts/`](scripts/) | PowerShell, SQL, and SSAS scripts for deployment, upgrades, and operations |
| [`deployment/`](deployment/) | Windows deployment tools and assets |
| [`mcp/`](mcp/) | Docker Compose setup for Grafana and Microsoft SQL Server MCP servers |
| [`docs/`](docs/) | Complete Persian and English documentation |
| [`tests/`](tests/) | Project tests and validation checks |

## Quick start

Choose the documentation set that matches your target:

- SQL Server: [SQL Exporter documentation](docs/sql-exporter/en/README.md)
- Windows and Windows-hosted services: [Windows Exporter documentation](docs/windows-exporter/en/README.md)
- AI-tool connectivity for Grafana and SQL Server: [MCP guide](mcp/README.md)

Exporter runtime files live under `exporters/<exporter>/`. Operational scripts live under `scripts/`, while central monitoring configuration is organized under `prometheus/`, `grafana/`, and `alertmanager/`. Run commands from the repository root unless a guide explicitly says otherwise.

## Documentation

- [SQL Exporter documentation index](docs/sql-exporter/README.md)
- [Windows Exporter documentation index](docs/windows-exporter/README.md)
- [Prometheus guide](prometheus/README.md)
- [Grafana guide](grafana/README.md)

Before deployment, adapt exporter versions, service-account permissions, ports, Prometheus targets, and secrets to your environment. Copy the example `.env` files and never commit files containing real secrets.
