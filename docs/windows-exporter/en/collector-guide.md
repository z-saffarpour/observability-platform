# windows_exporter collector guide

[فارسی](../fa/collector-guide.md)

Enable a collector only when its metrics support a dashboard, rule, or troubleshooting workflow. More collectors increase scrape cost and cardinality.

Prefer the role files under [`profiles/`](profiles.md) for production. The root `windows_exporter.yml` is a broader sample and is not identical to the base role profile.

| Collector | Purpose | Where enabled |
|---|---|---|
| `cpu`, `memory` | CPU and memory health | All profiles |
| `pagefile` | Page-file usage | Role profiles |
| `logical_disk`, `physical_disk` | Capacity, I/O, and latency | All profiles |
| `net` | NIC traffic, errors, and status | All profiles |
| `tcp` | TCP statistics | Most role profiles |
| `os`, `system`, `time` | OS identity, uptime, and clock | All profiles |
| `service` | Windows service state | All profiles |
| `process` | Per-process resources | SQL / SSAS / PBIRS / Dynamics / data-platform |
| `terminal_services` | RDP sessions | `terminal-server.yml` (+ root sample) |
| `license` | Windows license state | Root `windows_exporter.yml` sample only; not in role profiles |
| `mssql` | SQL performance counters | `sql-server.yml` and `data-platform*.yml` |
| `textfile` | Local `.prom` files | `ssas.yml` and `data-platform*.yml` |
| `mscluster` | Windows Failover Cluster metrics | `windows-cluster.yml` and `data-platform-cluster.yml` |

Baseline profile (`windows-base.yml`):

```yaml
collectors:
  enabled: "cpu,memory,pagefile,logical_disk,physical_disk,net,os,service,system,time"
```

Add role-specific collectors. For SSAS or combined data-platform hosts, keep `textfile` enabled and install the scheduled task that writes `ssas_*` into `textfile_inputs`; see [SSAS monitoring](ssas-monitoring.md). Enabling `mssql` without a registered SQL instance produces an initialization warning. Filter `process`, volumes, NICs, and disks; baseline `windows_exporter_collector_duration_seconds`; alert on `windows_exporter_collector_success == 0`. Canary every change and verify metric names against the actual 0.31.8 `/metrics` output.
