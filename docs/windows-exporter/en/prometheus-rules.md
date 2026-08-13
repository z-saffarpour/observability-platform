# Prometheus rules and alerts for windows_exporter

[فارسی](../fa/prometheus-rules.md)

Full alert catalog, priorities, and thresholds: [Alerting guide](alerting.md).  
Folder and profiles: [prometheus/](prometheus.md) · SMS/Email routing: [Alertmanager](alertmanager.md)

## Layout

| Path | Purpose |
|---|---|
| `prometheus/alert-rules/windows-exporter/` | Recording and alerting rules (for `rule_files`) |
| `prometheus/scrape-configs/windows-exporter/` | Ready-made `rule_files` profiles by priority and role |
| `alertmanager/windows-exporter/` | P0/P1/P2 routing for SMS and Email |

### Rule files

| File | Priority / role | Contents |
|---|---|---|
| `windows_exporter-recording.rules.yml` | — | CPU, memory, disk free/latency, pagefile, RDS sessions, buffer cache |
| `windows_exporter-p0-availability.rules.yml` | P0 | Target down, collector fail, data-platform services, time skew, MSSQL collector |
| `windows_exporter-p0-host.rules.yml` | P0 | Disk < 5%, critical commit charge |
| `windows_exporter-p0-mssql.rules.yml` | P0 | Critical log used, AG send/redo/delay |
| `windows_exporter-p1-host.rules.yml` | P1 | CPU, memory, disk 10%, latency, commit |
| `windows_exporter-p1-mssql.rules.yml` | P1 | Buffer cache, PLE, deadlocks, blocking, memory grants, log 85% |
| `windows_exporter-p2-host.rules.yml` | P2 | Processor queue, network errors, pagefile, license |
| `windows_exporter-p2-mssql.rules.yml` | P2 | Long tran, SQL errors, latch/lock waits, tempdb, connections |
| `windows_exporter-role-cluster.rules.yml` | Role | Failover Cluster node/network/resource |
| `windows_exporter-role-terminal.rules.yml` | Role | TermService and RDS sessions |
| `windows_exporter-role-dynamics.rules.yml` | Role | AX / D365 services and process |
| `windows_exporter-role-ssas.rules.yml` | Role | SSAS availability, processing, backup, security, memory |

### Alert profiles (`prometheus/scrape-configs/windows-exporter/`)

Each file is a ready `rule_files` block. Copy/merge it into `prometheus.yml`.

| Profile | Typical use |
|---|---|
| `p0-critical.yml` | Page-now alerts only (P0) |
| `p1-high.yml` | P0 + P1 |
| `p2-medium.yml` | Full priority stack without role packs |
| `host.yml` | Generic Windows servers |
| `mssql.yml` | SQL Server |
| `data-platform.yml` | SQL + SSAS + Cluster |
| `ssas.yml` / `cluster.yml` / `terminal.yml` / `dynamics.yml` | Role packs (add on top of a base profile) |
| `all.yml` | Every rule (lab / canary) |

## Install in Prometheus

Paths are relative to the working directory that contains the `rules/` folder from this package (for example after copying `prometheus/`).

SQL example:

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

Or use the contents of any `prometheus/scrape-configs/windows-exporter/*.yml` file as-is.

Validate before reload:

```powershell
promtool check rules .\prometheus\rules\*.rules.yml
```

## Notes

- Thresholds are examples and must be tuned to baselines and SLAs.
- Adjust the `job=~"windows.*"` selector if your job name differs from `windows` / `windows_exporter`.
- Missing metrics are not proof of health; monitor `up` and collector success separately.
- Recording rules are required by CPU / memory / disk / RDS / buffer-cache alerts.
- SSAS rules depend on textfile metrics. Until `Install-SsasMetricsTask.ps1` is installed, enable them only on SSAS targets. Details: [SSAS monitoring](ssas-monitoring.md).
- Enable Cluster / Terminal / Dynamics packs only when those collectors are scraped, to avoid noise.
