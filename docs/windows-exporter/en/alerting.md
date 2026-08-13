# windows_exporter alert catalog

[فارسی](../fa/alerting.md)

Install and `rule_files`: [Prometheus rules](prometheus-rules.md).

Every alert carries these labels:

| Label | Values |
|---|---|
| `severity` | `critical` or `warning` |
| `priority` | `P0` (page), `P1` (high), `P2` (medium) |
| `alert_profile` | `availability` / `host` / `mssql` / `ssas` / `cluster` / `terminal` / `dynamics` / `data-platform` |

## Recommended profiles by priority

| Priority | Profile | When |
|---|---|---|
| P0 | `prometheus/scrape-configs/windows-exporter/p0-critical.yml` | First rollout; outage and immediate risk only |
| P0+P1 | `p1-high.yml` | Stable production |
| P0+P1+P2 | `p2-medium.yml` or `mssql.yml` / `host.yml` | Full coverage without role packs |
| Role | `ssas.yml`, `cluster.yml`, `terminal.yml`, `dynamics.yml` | Add on top of a base profile |
| All | `all.yml` | Canary / lab |

## P0 — Critical

| Alert | File | Summary condition | for |
|---|---|---|---|
| `WindowsExporterDown` | p0-availability | `up{job=~"windows.*"} == 0` | 5m |
| `WindowsExporterCollectorFailed` | p0-availability | `windows_exporter_collector_success == 0` | 10m |
| `DataPlatformServiceNotRunning` | p0-availability | SQL/SSAS/PBIRS/ClusSvc not running | 3m |
| `MssqlCollectorFailed` | p0-availability | `windows_mssql_collector_success == 0` | 10m |
| `WindowsTimeSkewCritical` | p0-availability | \|time offset\| > 5s | 5m |
| `WindowsDiskSpaceCritical` | p0-host | free disk < 5% | 10m |
| `WindowsCommitChargeCritical` | p0-host | commit ratio > 95% | 10m |
| `MssqlLogUsedCritical` | p0-mssql | log used > 90% | 5m |
| `MssqlAgSendQueueGrowing` | p0-mssql | log send queue > 100MB | 10m |
| `MssqlAgRedoLagHigh` | p0-mssql | redo remaining > 100MB | 10m |
| `MssqlAgTransactionDelayHigh` | p0-mssql | AG transaction delay > 5s | 5m |

## P1 — High

| Alert | File | Summary condition | for |
|---|---|---|---|
| `WindowsHighCPU` | p1-host | CPU util > 85% | 15m |
| `WindowsLowAvailableMemory` | p1-host | available memory < 10% | 10m |
| `WindowsDiskSpaceLow` | p1-host | free disk < 10% | 15m |
| `WindowsDiskReadLatencyHigh` | p1-host | read latency > 50ms | 15m |
| `WindowsDiskWriteLatencyHigh` | p1-host | write latency > 50ms | 15m |
| `WindowsCommitChargeHigh` | p1-host | commit ratio > 90% | 15m |
| `MssqlBufferCacheLow` | p1-mssql | buffer hit ratio < 95% | 15m |
| `MssqlPageLifeExpectancyLow` | p1-mssql | PLE < 300s | 15m |
| `MssqlDeadlocks` | p1-mssql | deadlock increase > 0 / 15m | — |
| `MssqlBlockedProcesses` | p1-mssql | blocked processes > 0 | 10m |
| `MssqlPendingMemoryGrants` | p1-mssql | pending memory grants > 0 | 10m |
| `MssqlLogUsedHigh` | p1-mssql | log used > 85% | 10m |
| `MssqlFreeListStalls` | p1-mssql | free list stalls increased | 5m |

## P2 — Medium

| Alert | File | Summary condition | for |
|---|---|---|---|
| `WindowsProcessorQueueHigh` | p2-host | processor queue > 4 | 15m |
| `WindowsNetworkErrors` | p2-host | NIC errors/discards | 15m |
| `WindowsPagefileLow` | p2-host | pagefile free < 10% | 20m |
| `WindowsLicenseNotGenuine` | p2-host | genuine == 0 | 1h |
| `MssqlLongRunningTransaction` | p2-mssql | longest tran > 1h | 15m |
| `MssqlSqlErrors` | p2-mssql | SQL errors > 5 / 15m | — |
| `MssqlPageIoLatchWaitsHigh` | p2-mssql | elevated PAGEIOLATCH | 15m |
| `MssqlLockWaitsHigh` | p2-mssql | elevated lock waits | 15m |
| `MssqlTempdbFreeSpaceLow` | p2-mssql | tempdb free < 1GB | 15m |
| `MssqlUserConnectionsHigh` | p2-mssql | user connections > 500 | 20m |

## Role packs

### Cluster (`role-cluster`)

| Alert | Priority | Condition |
|---|---|---|
| `WindowsClusterNodeNotUp` | P0 | node state ≠ Up |
| `WindowsClusterResourceFailed` | P0 | resource state = Failed |
| `WindowsClusterResourceGroupUnhealthy` | P0 | group state = Failed |
| `WindowsClusterNetworkNotUp` | P1 | network state ≠ Up |

### Terminal (`role-terminal`)

| Alert | Priority | Condition |
|---|---|---|
| `TerminalServicesNotRunning` | P0 | TermService not running |
| `TerminalServerDisconnectedSessionsHigh` | P2 | disconnected sessions > 20 |
| `TerminalServerActiveSessionsHigh` | P2 | active sessions > 50 |

### Dynamics (`role-dynamics`)

| Alert | Priority | Condition |
|---|---|---|
| `DynamicsServiceNotRunning` | P0 | AOS / FabricHost / W3SVC / WAS down |
| `DynamicsProcessMissing` | P1 | service up but process missing |

### SSAS (`role-ssas`)

| Alert | Priority |
|---|---|
| `SsasInstanceDown`, `SsasMetricsCollectorStale`, `SsasServiceStopped`, `SsasEndpointUnreachable`, `SsasReadOnlyProbeFailed`, `SsasPanicMode` | P0 |
| `SsasMetricsPartialFailure`, `SsasDatabaseProcessingStale`, `SsasProcessingOverdue`, `SsasProcessingDurationIncreased`, `SsasBackupStale`, `SsasMemoryPressure`, `SsasThreadPoolQueueGrowing`, `SsasQueryFailures`, `SsasProcessingFailures`, `SsasPerformanceMetricsStale` | P1 |
| `SsasLoginFailures`, `SsasPrivilegedAccessChanged`, `SsasUnexpectedHighPrivilegeGrowth` | P2 |

SSAS metric details: [SSAS monitoring](ssas-monitoring.md).

## Required recording rules

| Record | Used by |
|---|---|
| `instance:windows_cpu_utilisation:rate5m` | `WindowsHighCPU` |
| `instance:windows_memory_available_ratio` | `WindowsLowAvailableMemory` |
| `instance:windows_memory_commit_ratio` | commit charge alerts |
| `instance_volume:windows_disk_free_ratio` | disk space alerts |
| `instance_volume:windows_logical_disk_*_latency_seconds:rate5m` | disk latency alerts |
| `instance:windows_pagefile_free_ratio` | `WindowsPagefileLow` |
| `instance:windows_terminal_services_*_sessions` | RDS session alerts |
| `instance_mssql:buffer_cache_hit_ratio:rate5m` | `MssqlBufferCacheLow` |

## Tuning guidance

1. Tune AG (100MB), PLE (300s), and user-connection (500) thresholds per instance baseline.
2. Load role packs only for jobs/targets that expose those metrics, or constrain them with Alertmanager inhibit/mute.

## Alertmanager — SMS and Email routing

Sample config: `alertmanager/windows-exporter/alertmanager.yml`  
Full details: [Alertmanager](alertmanager.md)

| Priority | Channels | Repeat |
|---|---|---|
| P0 | SMS (webhook) + Email | 15m |
| P1 | Email + SMS (webhook) | 1h |
| P2 | Email only | 12h |

Replace every `CHANGE_ME_*` before production. Alertmanager has no native SMS transport; SMS uses `webhook_configs` against your gateway.

Wire Prometheus:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["CHANGE_ME_ALERTMANAGER_HOST:9093"]
```

Validate:

```powershell
amtool check-config .\prometheus\alertmanager\alertmanager.yml
```
