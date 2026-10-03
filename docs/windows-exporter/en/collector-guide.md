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
| `update` | Pending Windows updates and collection freshness | All profiles and root sample |
| `process` | Per-process resources | SQL / SSAS / PBIRS / Dynamics / data-platform |
| `terminal_services` | RDP sessions | `terminal-server.yml` (+ root sample) |
| `license` | Windows license state | Root `windows_exporter.yml` sample only; not in role profiles |
| `mssql` | SQL performance counters | `sql-server.yml` and `data-platform*.yml` |
| `textfile` | Local `.prom` files | `ssas.yml` and `data-platform*.yml` |
| `mscluster` | Windows Failover Cluster metrics | `windows-cluster.yml` and `data-platform-cluster.yml` |

Baseline profile (`windows-base.yml`):

```yaml
collectors:
  enabled: "cpu,memory,pagefile,logical_disk,physical_disk,net,os,service,system,time,update"
```

Add role-specific collectors. For SSAS or combined data-platform hosts, keep `textfile` enabled and install the scheduled task that writes `ssas_*` into `textfile_inputs`; see [SSAS monitoring](ssas-monitoring.md). Enabling `mssql` without a registered SQL instance produces an initialization warning. Filter `process`, volumes, NICs, and disks; baseline `windows_exporter_collector_duration_seconds`; alert on `windows_exporter_collector_success == 0`. Canary every change and verify metric names against the actual 0.31.8 `/metrics` output.

## Windows Update

The root configuration and all complete role profiles enable `update` with:

```yaml
collector:
  update:
    online: false
    scrape_interval: 6h
```

This queries the local Windows Update inventory every six hours, without an online search or update installation. Inventory freshness still depends on the organization's update manager. The collector is experimental in 0.31.8; validate under the exporter service account on a canary with `wuauserv` available before rollout. Initialization failure can prevent exporter startup. These repository changes do not deploy configuration or restart services.

| Metric | Meaning |
|---|---|
| `windows_update_pending_info` | Pending update information; labels: `id`, `revision`, `category`, `severity`, `title` |
| `windows_update_pending_published_timestamp` | Publication time in Unix seconds; labels: `id`, `revision` |
| `windows_update_scrape_query_duration_seconds` | Duration of the last Windows Update query |
| `windows_update_scrape_timestamp_seconds` | Timestamp of the last collected inventory |

Validate `/metrics` and `windows_exporter_collector_success{collector="update"}`. Check `time() - windows_update_scrape_timestamp_seconds` against the six-hour interval plus an operational margin. Cached data may outlive a failed background refresh; collector success alone does not prove freshness. Missing pending series mean no known updates only after a successful, fresh inventory; do not replace missing or stale telemetry with zero. Offline inventory is not proof of patch compliance. Update titles and revisions add series churn; retain identity labels and aggregate by host/category/severity for summaries.

Prometheus currently scrapes all enabled collectors, so no scrape change is required. Existing deployments need the updated active configuration applied through their configuration owner; merely copying inactive profiles does not enable collection. Rollback removes `update` and its configuration block from the active file through that same process.

References: [0.31.8 metrics](https://github.com/prometheus-community/windows_exporter/blob/v0.31.8/docs/collector.update.md), [configuration and labels in source](https://github.com/prometheus-community/windows_exporter/blob/v0.31.8/internal/collector/update/update.go). YAML uses `scrape_interval`; the executable's CLI uses `--collector.update.scrape-interval`.
