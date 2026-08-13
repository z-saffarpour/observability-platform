# SQL Exporter sample rules and alerts

[نسخه فارسی](../fa/prometheus-rules.md)

Full alert catalog, priorities and thresholds: [Alerting guide](alerting.md).
SMS/Email routing: [Alertmanager](alertmanager.md).
Folder guide: [prometheus/](prometheus.md).

Layout mirrors `windows_exporter`. Treat thresholds as a starting point and tune
them to each server’s SLA, baseline and role before production.

## Layout

| Path | Purpose |
|---|---|
| `prometheus/alert-rules/sql-exporter/` | Recording and alerting rules (`rule_files`) |
| `prometheus/scrape-configs/sql-exporter/` | Ready-made `rule_files` packs by priority and role |
| `alertmanager/sql-exporter/` | P0/P1/P2 routing for SMS and Email |
| `prometheus/prometheus.yml` | Default sample (P0+P1) + Alertmanager wiring |

### Rule files

| File | Priority / role | Content |
|---|---|---|
| `sql_exporter-recording.rules.yml` | — | Rates and KPIs |
| `sql_exporter-p0-availability.rules.yml` | P0 | Target down, DB state, backup, integrity, restore |
| `sql_exporter-p0-hadr.rules.yml` | P0 | Always On / WSFC / FCI |
| `sql_exporter-p0-jobs.rules.yml` | P0 | SQL Agent job failed |
| `sql_exporter-p1-performance.rules.yml` | P1 | CPU, I/O, log, blocking, memory, tempdb, … |
| `sql_exporter-p1-space.rules.yml` | P1 | File space usage |
| `sql_exporter-p1-jobs.rules.yml` | P1 | Job history / last-run failures |
| `sql_exporter-p1-signals.rules.yml` | P1 | ERRORLOG signals |
| `sql_exporter-p2-performance.rules.yml` | P2 | Sessions, parallelism, plan cache, waits, … |
| `sql_exporter-p2-maintenance.rules.yml` | P2 | Index, stats, autogrowth, Query Store |
| `sql_exporter-p2-config.rules.yml` | P2 | Unsafe config, rapid growth |
| `sql_exporter-role-*.rules.yml` | Role | Replication, SSIS, Security, CDC |

### Alert profiles (`prometheus/scrape-configs/sql-exporter/`)

Each file is a ready `rule_files` block. Copy/merge it into `prometheus.yml`.

| Profile | Suggested use |
|---|---|
| `p0-critical.yml` | Immediate paging only (P0) |
| `p1-high.yml` | P0 + P1 (recommended production) |
| `p2-medium.yml` / `oltp.yml` | Full priority stack without roles |
| `restore-secondary.yml` | Restore / log-shipping secondaries |
| `replication.yml` / `ssis.yml` / `security.yml` / `cdc.yml` | Role packs |
| `all.yml` | Every rule (lab / canary) |

Exporter collector profiles for these alerts: `profiles/alert-p0.yml`,
`alert-p1.yml`, `alert-p2.yml` — see [profiles.md](profiles.md).

## Prometheus installation

Paths are relative to the working directory that contains the `rules/` folder.

Sample P1 profile:

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

Or use any file under `prometheus/scrape-configs/sql-exporter/*.yml` as-is.

Validate before reload:

```powershell
promtool check rules .\prometheus\rules\*.rules.yml
promtool check config .\prometheus\prometheus.yml
```

## Notes

- Thresholds are samples and must be tuned to baseline and SLA.
- If the scrape job is not `sql_exporter`, adjust `job=~"sql.*"`.
- A missing metric does not necessarily mean healthy; monitor `up` and scrape errors separately.
- Add role packs only when the related collectors are scraped, to reduce noise.
- Route in Alertmanager using `priority` and `severity`.
