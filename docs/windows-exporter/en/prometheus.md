# prometheus/ folder guide

[فارسی](../fa/prometheus.md)

Copy this folder next to your Prometheus config (or point `rule_files` at absolute paths).

Alert catalog: [Alerting](alerting.md) · Rule install: [Prometheus rules](prometheus-rules.md) · Alertmanager: [Alertmanager](alertmanager.md)

## Quick start (SQL Server)

Merge the contents of [`prometheus/scrape-configs/windows-exporter/mssql.yml`](../../../prometheus/scrape-configs/windows-exporter/mssql.yml) into `prometheus.yml`:

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

Validate:

```powershell
promtool check rules .\prometheus\rules\*.rules.yml
```

## Alert profiles

| File | Priority / scope |
|---|---|
| `profiles/p0-critical.yml` | P0 only |
| `profiles/p1-high.yml` | P0 + P1 |
| `profiles/p2-medium.yml` | P0 + P1 + P2 |
| `profiles/host.yml` | Host stack |
| `profiles/mssql.yml` | Host + MSSQL |
| `profiles/data-platform.yml` | MSSQL + SSAS + Cluster |
| `profiles/ssas.yml` | SSAS role pack |
| `profiles/cluster.yml` | Cluster role pack |
| `profiles/terminal.yml` | Terminal role pack |
| `profiles/dynamics.yml` | Dynamics role pack |
| `profiles/all.yml` | Everything |

## Alertmanager (SMS and Email)

| Priority | Channels |
|---|---|
| P0 | SMS webhook + Email |
| P1 | Email + SMS webhook |
| P2 | Email only |

Details and placeholders: [Alertmanager](alertmanager.md)
