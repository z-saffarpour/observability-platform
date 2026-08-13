# کاتالوگ Alertهای sql_exporter

[English](../en/alerting.md)

نصب و `rule_files`: [Prometheus rules](prometheus-rules.md).

ساختار مانند `windows_exporter` است:

| مسیر | کاربرد |
|---|---|
| `prometheus/alert-rules/sql-exporter/` | Recording و Alerting ruleها |
| `prometheus/scrape-configs/sql-exporter/` | بلوک‌های آمادهٔ `rule_files` بر اساس اولویت / نقش |
| `profiles/alert-p0.yml` … `alert-p2.yml` | حداقل Collectorهای exporter برای هر اولویت |

هر Alert دارای labelهای زیر است:

| Label | مقادیر |
|---|---|
| `severity` | `critical` / `warning` / `info` |
| `priority` | `P0` (فوری)، `P1` (بالا)، `P2` (متوسط) |
| `alert_profile` | `availability` / `hadr` / `jobs` / `performance` / `space` / `signals` / `maintenance` / `config` / `replication` / `ssis` / `security` / `cdc` |
| `collector` | نام collector مربوطه |

## پروفایل پیشنهادی بر اساس اولویت

| اولویت | پروفایل Prometheus | پروفایل exporter | چه زمانی |
|---|---|---|---|
| P0 | `prometheus/scrape-configs/sql-exporter/p0-critical.yml` | `profiles/alert-p0.yml` | شروع rollout؛ فقط قطع سرویس و ریسک فوری |
| P0+P1 | `p1-high.yml` | `alert-p1.yml` | محیط production پایدار (پیشنهادی) |
| P0+P1+P2 | `p2-medium.yml` یا `oltp.yml` | `alert-p2.yml` یا `oltp.yml` | پوشش کامل بدون بسته‌های نقش |
| نقش‌محور | `replication.yml` / `ssis.yml` / `security.yml` / `cdc.yml` | پروفایل نقش exporter | اضافه روی پروفایل پایه |
| همه | `all.yml` | `collectors: [mssql_*]` | canary / lab |

## P0 — Critical

| Alert | فایل | شرط خلاصه | for |
|---|---|---|---|
| `SqlExporterDown` | p0-availability | `up{job=~"sql.*"} == 0` | 5m |
| `SqlDatabaseNotOnline` | p0-availability | `mssql_database_state != 0` | 5m |
| `SqlBackupFullTooOld` | p0-availability | Full backup > ۲۵h یا missing | 15m |
| `SqlDatabaseIntegrityAtRisk` | p0-availability | suspect pages یا CHECKDB > ۷ روز | 5m |
| `SqlRestoreSecondaryBehindRpo` | p0-availability | restore gap > ۳۰m | 10m |
| `SqlAlwaysOnReplicaUnhealthy` | p0-hadr | sync health == 0 | 2m |
| `SqlHadrClusterQuorumNotNormal` | p0-hadr | quorum_state != 1 | 2m |
| `SqlHadrClusterMemberDown` | p0-hadr | member_state != 1 | 2m |
| `SqlHadrListenerIpNotOnline` | p0-hadr | listener IP != ONLINE | 2m |
| `SqlHadrFciNodeNotUp` | p0-hadr | FCI node not up | 2m |
| `SqlAgentJobFailed` | p0-jobs | `mssql_job_failed_current > 0` | 2m |

## P1 — High

| Alert | فایل | شرط خلاصه | for |
|---|---|---|---|
| `SqlServerCpuHigh` | p1-performance | CPU > ۸۰٪ | 10m |
| `SqlFileIoLatencyHigh` | p1-performance | latency > ۲۰ms | 10m |
| `SqlTransactionLogUsageHigh` | p1-performance | log used > ۸۰٪ | 10m |
| `SqlBlockingPersistent` | p1-performance | blocking > 0 | 5m |
| `SqlMemoryGrantPressure` | p1-performance | pending grants > 0 | 5m |
| `SqlTempdbPressure` | p1-performance | waiters یا version store > ۱۰ GiB | 10m |
| `SqlBufferPoolLifeExpectancyLow` | p1-performance | PLE < ۳۰۰s | 10m |
| `SqlSchedulerPressure` | p1-performance | runnable > ۴ یا work queue | 10m |
| `SqlLockWaitPersistent` | p1-performance | locks waiting > 0 | 5m |
| `SqlLongRunningRequest` | p1-performance | request > ۵m | 5m |
| `SqlDatabaseFileSpaceHigh` | p1-space | file used > ۸۵٪ | 15m |
| `SqlAgentJobRecentFailure` | p1-jobs | history failures > 0 | 5m |
| `SqlAgentJobLastRunFailed` | p1-jobs | last outcome == 0 | 5m |
| `SqlErrorlogSignalDetected` | p1-signals | errorlog signal > 0 | 5m |

## P2 — Medium

| Alert | فایل | شرط خلاصه | for |
|---|---|---|---|
| `SqlConnectionCountHigh` | p2-performance | sessions > ۵۰۰ | 10m |
| `SqlParallelismQueueHigh` | p2-performance | waiting tasks > ۱۰ | 10m |
| `SqlPlanCacheSingleUseRatioHigh` | p2-performance | single-use ratio > ۵۰٪ | 15m |
| `SqlResourceGovernorPressure` | p2-performance | RG waiters/queued | 5m |
| `SqlLongTransaction` | p2-performance | open tran > ۱۵m | 5m |
| `SqlWaitPressureHigh` | p2-performance | non-benign waits > ۸۰٪ | 15m |
| `SqlAutogrowthFrequent` | p2-maintenance | autogrowth > ۱۰ / ۲۴h | 15m |
| `SqlColumnstoreDeletedRowsHigh` | p2-maintenance | deleted ratio > ۲۰٪ | 30m |
| `SqlIndexHighlyFragmented` | p2-maintenance | fragmentation > ۳۰٪ | 30m |
| `SqlIndexWriteHeavy` | p2-maintenance | updates > ۱M | 30m |
| `SqlMissingIndexHighImpact` | p2-maintenance | score > ۱M | 30m |
| `SqlStatisticsStale` | p2-maintenance | stale stats > ۲۰ | 30m |
| `SqlQueryStoreDisabled` | p2-maintenance | Query Store off | 30m |
| `SqlAgentJobRunningTooLong` | p2-maintenance | running > ۲h | 10m |
| `SqlDatabaseConfigurationUnsafe` | p2-config | AUTO_SHRINK/CLOSE یا PAGE_VERIFY | 10m |
| `SqlDatabaseGrowingRapidly` | p2-config | رشد > ۱۰ GiB / ۲۴h | 15m |

## بسته‌های نقش

### Replication (`role-replication`)

| Alert | اولویت | شرط |
|---|---|---|
| `SqlReplicationBacklog` | P0 | pending > ۱۰k یا latency > ۵m |

### SSIS (`role-ssis`)

| Alert | اولویت | شرط |
|---|---|---|
| `SqlSsisExecutionFailed` | P0 | failed_count > 0 |

### Security (`role-security`)

| Alert | اولویت | شرط |
|---|---|---|
| `SqlSecurityRiskDetected` | P1 | sa / xp_cmdshell / db owner sysadmin |

### CDC (`role-cdc`)

| Alert | اولویت | شرط |
|---|---|---|
| `SqlCdcCaptureBehind` | P1 | capture lag > ۵m |

## راهنمای tuning

1. Thresholdها نمونه‌اند؛ با baseline و SLA هر instance تنظیم کنید.
2. Alertهای نقش را فقط روی targetهایی که collector مربوطه دارند load کنید.
3. در Alertmanager از `priority` و `severity` برای routing استفاده کنید (P0 → صفحه، P1 → تیکت، P2 → کانال روزانه).
4. اگر `job` برابر `sql_exporter` نیست، selector `job=~"sql.*"` در `SqlExporterDown` را اصلاح کنید.
5. Alertهای `severity: info` معمولاً نباید on-call را بیدار کنند.

## Alertmanager — routing با SMS و Email

کانفیگ نمونه: `alertmanager/sql-exporter/alertmanager.yml`  
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

