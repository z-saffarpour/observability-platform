# prometheus/ folder guide

[فارسی](../fa/prometheus.md)

Copy this folder next to your Prometheus config (or point `rule_files` at absolute paths).

Alert catalog: [Alerting](alerting.md) · Rule install: [Prometheus rules](prometheus-rules.md) · Alertmanager: [Alertmanager](alertmanager.md)

## Quick start (SQL Server / OLTP)

Merge the contents of [`prometheus/scrape-configs/sql-exporter/oltp.yml`](../../../prometheus/scrape-configs/sql-exporter/oltp.yml) or [`p1-high.yml`](../../../prometheus/scrape-configs/sql-exporter/p1-high.yml) into `prometheus.yml`:

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
| `profiles/oltp.yml` | Full priority stack (no role packs) |
| `profiles/restore-secondary.yml` | P0 availability + HADR + jobs |
| `profiles/replication.yml` | Replication role pack |
| `profiles/ssis.yml` | SSIS role pack |
| `profiles/security.yml` | Security role pack |
| `profiles/cdc.yml` | CDC role pack |
| `profiles/all.yml` | Everything |

Exporter collector minimums for these alerts: `profiles/alert-p0.yml`, `alert-p1.yml`, `alert-p2.yml`.

## Alertmanager (SMS and Email)

Routing lives under [`alertmanager/sql-exporter/`](../../../alertmanager/sql-exporter/):

| Priority | Channels | Repeat |
|---|---|---|
| P0 | SMS webhook + Email | 15m |
| P1 | Email + SMS webhook | 1h |
| P2 | Email only | 12h |

Details and placeholders: [Alertmanager](alertmanager.md)
