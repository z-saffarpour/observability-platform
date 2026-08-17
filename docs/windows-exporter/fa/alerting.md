# کاتالوگ Alertهای windows_exporter

[English](../en/alerting.md)

نصب و `rule_files`: [Prometheus rules](prometheus-rules.md).

هر Alert دارای labelهای زیر است:

| Label | مقادیر |
|---|---|
| `severity` | `critical` یا `warning` |
| `priority` | `P0` (فوری)، `P1` (بالا)، `P2` (متوسط) |
| `alert_profile` | `availability` / `host` / `mssql` / `ssas` / `cluster` / `terminal` / `dynamics` / `data-platform` |

## پروفایل پیشنهادی بر اساس اولویت

| اولویت | پروفایل | چه زمانی |
|---|---|---|
| P0 | `prometheus/scrape-configs/windows-exporter/p0-critical.yml` | شروع rollout؛ فقط قطع سرویس و ریسک فوری |
| P0+P1 | `p1-high.yml` | محیط production پایدار |
| P0+P1+P2 | `p2-medium.yml` یا `mssql.yml` / `host.yml` | پوشش کامل بدون بسته‌های نقش |
| نقش‌محور | `ssas.yml`، `cluster.yml`، `terminal.yml`، `dynamics.yml` | اضافه روی پروفایل پایه |
| همه | `all.yml` | canary / lab |

## P0 — Critical

| Alert | فایل | شرط خلاصه | for |
|---|---|---|---|
| `WindowsExporterDown` | p0-availability | `up{job=~"windows.*"} == 0` | 5m |
| `WindowsExporterCollectorFailed` | p0-availability | `windows_exporter_collector_success == 0` | 10m |
| `DataPlatformServiceNotRunning` | p0-availability | سرویس SQL/SSAS/PBIRS/ClusSvc running نیست | 3m |
| `MssqlCollectorFailed` | p0-availability | `windows_mssql_collector_success == 0` | 10m |
| `WindowsTimeSkewCritical` | p0-availability | \|time offset\| > 5s | 5m |
| `WindowsDiskSpaceCritical` | p0-host | free disk < 5% | 10m |
| `WindowsCommitChargeCritical` | p0-host | commit ratio > 95% | 10m |
| `MssqlLogUsedCritical` | p0-mssql | log used > 90% | 5m |
| `MssqlAgSendQueueGrowing` | p0-mssql | log send queue > 100MB | 10m |
| `MssqlAgRedoLagHigh` | p0-mssql | redo remaining > 100MB | 10m |
| `MssqlAgTransactionDelayHigh` | p0-mssql | AG transaction delay > 5s | 5m |

## P1 — High

| Alert | فایل | شرط خلاصه | for |
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
| `MssqlFreeListStalls` | p1-mssql | free list stalls افزایش | 5m |

## P2 — Medium

| Alert | فایل | شرط خلاصه | for |
|---|---|---|---|
| `WindowsProcessorQueueHigh` | p2-host | processor queue > 4 | 15m |
| `WindowsNetworkErrors` | p2-host | NIC errors/discards | 15m |
| `WindowsPagefileLow` | p2-host | pagefile free < 10% | 20m |
| `WindowsLicenseNotGenuine` | p2-host | genuine == 0 | 1h |
| `MssqlLongRunningTransaction` | p2-mssql | longest tran > 1h | 15m |
| `MssqlSqlErrors` | p2-mssql | SQL errors > 5 / 15m | — |
| `MssqlPageIoLatchWaitsHigh` | p2-mssql | PAGEIOLATCH افزایش زیاد | 15m |
| `MssqlLockWaitsHigh` | p2-mssql | lock waits افزایش زیاد | 15m |
| `MssqlTempdbFreeSpaceLow` | p2-mssql | tempdb free < 1GB | 15m |
| `MssqlUserConnectionsHigh` | p2-mssql | user connections > 500 | 20m |

## بسته‌های نقش

### Cluster (`role-cluster`)

| Alert | اولویت | شرط |
|---|---|---|
| `WindowsClusterNodeNotUp` | P0 | node state ≠ Up |
| `WindowsClusterResourceFailed` | P0 | resource state = Failed |
| `WindowsClusterResourceGroupUnhealthy` | P0 | group state = Failed |
| `WindowsClusterNetworkNotUp` | P1 | network state ≠ Up |

### Terminal (`role-terminal`)

| Alert | اولویت | شرط |
|---|---|---|
| `TerminalServicesNotRunning` | P0 | TermService not running |
| `TerminalServerDisconnectedSessionsHigh` | P2 | disconnected sessions > 20 |
| `TerminalServerActiveSessionsHigh` | P2 | active sessions > 50 |

### Dynamics (`role-dynamics`)

| Alert | اولویت | شرط |
|---|---|---|
| `DynamicsServiceNotRunning` | P0 | AOS / FabricHost / W3SVC / WAS down |
| `DynamicsProcessMissing` | P1 | سرویس بالاست ولی process دیده نمی‌شود |

### SSAS (`role-ssas`)

| Alert | اولویت |
|---|---|
| `SsasInstanceDown`, `SsasMetricsCollectorStale`, `SsasServiceStopped`, `SsasEndpointUnreachable`, `SsasReadOnlyProbeFailed`, `SsasPanicMode` | P0 |
| `SsasMetricsPartialFailure`, `SsasDatabaseProcessingStale`, `SsasProcessingOverdue`, `SsasProcessingDurationIncreased`, `SsasBackupStale`, `SsasMemoryPressure`, `SsasThreadPoolQueueGrowing`, `SsasQueryFailures`, `SsasProcessingFailures`, `SsasPerformanceMetricsStale` | P1 |
| `SsasLoginFailures`, `SsasPrivilegedAccessChanged`, `SsasUnexpectedHighPrivilegeGrowth` | P2 |

جزئیات متریک‌های SSAS: [مانیتورینگ SSAS](ssas-monitoring.md).

## Recording rules مورد نیاز

| Record | استفاده در |
|---|---|
| `instance:windows_cpu_utilisation:rate5m` | `WindowsHighCPU` |
| `instance:windows_memory_available_ratio` | `WindowsLowAvailableMemory` |
| `instance:windows_memory_commit_ratio` | commit charge alerts |
| `instance_volume:windows_disk_free_ratio` | disk space alerts |
| `instance_volume:windows_logical_disk_*_latency_seconds:rate5m` | disk latency alerts |
| `instance:windows_pagefile_free_ratio` | `WindowsPagefileLow` |
| `instance:windows_terminal_services_*_sessions` | RDS session alerts |
| `instance_mssql:buffer_cache_hit_ratio:rate5m` | `MssqlBufferCacheLow` |

## راهنمای tuning

1. Thresholdهای AG (100MB) و PLE (300s) و user connections (500) را با baseline هر instance تنظیم کنید.
2. Alertهای نقش را فقط روی job/targetهایی که متریک مربوطه دارند load کنید، یا با `inhibit`/`mute` در Alertmanager محدود کنید.

## Alertmanager — routing با SMS و Email

کانفیگ نمونه: `alertmanager/windows-exporter/alertmanager.yml`  
جزئیات کامل: [Alertmanager](alertmanager.md)

| اولویت | کانال | تکرار |
|---|---|---|
| P0 | SMS (webhook) + Email | ۱۵ دقیقه |
| P1 | Email + SMS (webhook) | ۱ ساعت |
| P2 | فقط Email | ۱۲ ساعت |

قبل از production همهٔ `CHANGE_ME_*` را جایگزین کنید. Alertmanager SMS بومی ندارد؛ SMS از طریق `webhook_configs` به gateway شما می‌رود.

اتصال Prometheus:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["CHANGE_ME_ALERTMANAGER_HOST:9093"]
```

اعتبارسنجی:

```powershell
amtool check-config .\prometheus\alertmanager\alertmanager.yml
```
