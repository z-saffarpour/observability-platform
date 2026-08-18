# sql_exporter alert catalog

[فارسی](../fa/alerting.md)

Install and `rule_files`: [Prometheus rules](prometheus-rules.md).

Layout mirrors `windows_exporter`:

| Path | Purpose |
|---|---|
| `prometheus/alert-rules/sql-exporter/` | Recording and alerting rules |
| `prometheus/scrape-configs/sql-exporter/` | Ready-made `rule_files` blocks by priority / role |
| `profiles/alert-p0.yml` … `alert-p2.yml` | Minimum exporter collectors per priority |

Every alert carries these labels:

| Label | Values |
|---|---|
| `severity` | `critical` / `warning` / `info` |
| `priority` | `P0` (page), `P1` (high), `P2` (medium) |
| `alert_profile` | `availability` / `hadr` / `jobs` / `performance` / `space` / `signals` / `maintenance` / `config` / `replication` / `ssis` / `security` / `cdc` |
| `collector` | Owning collector name |

## Recommended profiles by priority

| Priority | Prometheus profile | Exporter profile | When |
|---|---|---|---|
| P0 | `prometheus/scrape-configs/sql-exporter/p0-critical.yml` | `profiles/alert-p0.yml` | First rollout; outage and immediate risk only |
| P0+P1 | `p1-high.yml` | `alert-p1.yml` | Stable production (recommended) |
| P0+P1+P2 | `p2-medium.yml` or `oltp.yml` | `alert-p2.yml` or `oltp.yml` | Full coverage without role packs |
| Role | `replication.yml` / `ssis.yml` / `security.yml` / `cdc.yml` | matching role exporter profile | Add on top of a base profile |
| All | `all.yml` | `collectors: [mssql_*]` | Canary / lab |

## P0 — Critical

| Alert | File | Summary condition | for |
|---|---|---|---|
| `SqlExporterDown` | p0-availability | `up{job=~"sql.*"} == 0` | 5m |
| `SqlDatabaseNotOnline` | p0-availability | `mssql_database_state != 0` | 5m |
| `SqlBackupFullTooOld` | p0-availability | Full backup > 25h or missing | 15m |
| `SqlDatabaseIntegrityAtRisk` | p0-availability | suspect pages or CHECKDB > 7d | 5m |
| `SqlRestoreSecondaryBehindRpo` | p0-availability | restore gap > 30m | 10m |
| `SqlAlwaysOnReplicaUnhealthy` | p0-hadr | sync health == 0 | 2m |
| `SqlHadrClusterQuorumNotNormal` | p0-hadr | quorum_state != 1 | 2m |
| `SqlHadrClusterMemberDown` | p0-hadr | member_state != 1 | 2m |
| `SqlHadrListenerIpNotOnline` | p0-hadr | listener IP != ONLINE | 2m |
| `SqlHadrFciNodeNotUp` | p0-hadr | FCI node not up | 2m |
| `SqlAgentJobFailed` | p0-jobs | `mssql_job_failed_current > 0` | 2m |

## P1 — High

| Alert | File | Summary condition | for |
|---|---|---|---|
| `SqlServerCpuHigh` | p1-performance | CPU > 80% | 10m |
| `SqlFileIoLatencyHigh` | p1-performance | latency > 20ms | 10m |
| `SqlTransactionLogUsageHigh` | p1-performance | user-db log used > 80% | 10m |
| `SqlSystemDbTransactionLogUsageHigh` | p1-performance | tempdb/msdb log used > 80% | 10m |
| `SqlBlockingPersistent` | p1-performance | blocking > 0 | 5m |
| `SqlMemoryGrantPressure` | p1-performance | pending grants > 0 | 5m |
| `SqlTempdbPressure` | p1-performance | waiters or version store > 10 GiB | 10m |
| `SqlBufferPoolLifeExpectancyLow` | p1-performance | PLE < 300s | 10m |
| `SqlSchedulerPressure` | p1-performance | runnable > 4 or work queue | 10m |
| `SqlLockWaitPersistent` | p1-performance | locks waiting > 0 | 5m |
| `SqlLongRunningRequest` | p1-performance | request > 5m | 5m |
| `SqlDatabaseFileSpaceHigh` | p1-space | file used > 85% | 15m |
| `SqlAgentJobRecentFailure` | p1-jobs | history failures > 0 | 5m |
| `SqlAgentJobLastRunFailed` | p1-jobs | last outcome == 0 | 5m |
| `SqlErrorlogSignalDetected` | p1-signals | errorlog signal > 0 | 5m |

## P2 — Medium

| Alert | File | Summary condition | for |
|---|---|---|---|
| `SqlConnectionCountHigh` | p2-performance | sessions > 500 | 10m |
| `SqlParallelismQueueHigh` | p2-performance | waiting tasks > 10 | 10m |
| `SqlPlanCacheSingleUseRatioHigh` | p2-performance | single-use ratio > 50% | 15m |
| `SqlResourceGovernorPressure` | p2-performance | RG waiters/queued | 5m |
| `SqlLongTransaction` | p2-performance | open tran > 15m | 5m |
| `SqlWaitPressureHigh` | p2-performance | non-benign waits > 80% | 15m |
| `SqlAutogrowthFrequent` | p2-maintenance | autogrowth > 10 / 24h | 15m |
| `SqlColumnstoreDeletedRowsHigh` | p2-maintenance | deleted ratio > 20% | 30m |
| `SqlIndexHighlyFragmented` | p2-maintenance | fragmentation > 30% | 30m |
| `SqlIndexWriteHeavy` | p2-maintenance | updates > 1M | 30m |
| `SqlMissingIndexHighImpact` | p2-maintenance | score > 1M | 30m |
| `SqlStatisticsStale` | p2-maintenance | stale stats > 20 | 30m |
| `SqlQueryStoreDisabled` | p2-maintenance | Query Store off | 30m |
| `SqlAgentJobRunningTooLong` | p2-maintenance | running > 2h | 10m |
| `SqlDatabaseConfigurationUnsafe` | p2-config | AUTO_SHRINK/CLOSE or PAGE_VERIFY | 10m |
| `SqlDatabaseGrowingRapidly` | p2-config | growth > 10 GiB / 24h | 15m |

## Role packs

### Replication (`role-replication`)

| Alert | Priority | Condition |
|---|---|---|
| `SqlReplicationBacklog` | P0 | pending > 10k or latency > 5m |

### SSIS (`role-ssis`)

| Alert | Priority | Condition |
|---|---|---|
| `SqlSsisExecutionFailed` | P0 | failed_count > 0 |

### Security (`role-security`)

| Alert | Priority | Condition |
|---|---|---|
| `SqlSecurityRiskDetected` | P1 | sa / xp_cmdshell / db owner sysadmin |

### CDC (`role-cdc`)

| Alert | Priority | Condition |
|---|---|---|
| `SqlCdcCaptureBehind` | P1 | capture lag > 5m |

## Tuning guidance

1. Thresholds are samples; tune to each instance baseline and SLA.
2. Load role packs only on targets that scrape the related collectors.
3. Route in Alertmanager with `priority` and `severity` (P0 → page, P1 → ticket, P2 → daily channel).
4. If the scrape job is not named `sql_exporter`, adjust `job=~"sql.*"` on `SqlExporterDown`.
5. `severity: info` alerts should not page on-call.

## Alertmanager — SMS and Email routing

Sample config: `alertmanager/sql-exporter/alertmanager.yml`  
Full details: [Alertmanager](alertmanager.md)

| Priority | Channels | Repeat |
|---|---|---|
| P0 | SMS webhook + Email | 15m |
| P1 | Email + SMS webhook | 1h |
| P2 | Email only | 12h |

Replace every `CHANGE_ME_*` before production. Alertmanager has no native SMS
transport; SMS is sent through `webhook_configs` to your gateway.

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

