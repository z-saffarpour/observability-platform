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
| `WindowsExporterDown` | p0-availability | `up{job=~"windows.*"} == 0`. فقط target مربوط به exporter. قطع هر دو exporter یعنی `InstanceDown` | 5m |
| `WindowsHostRestarted` | p0-availability | boot time بیشتر از ۱۲۰ ثانیه جلو رفته و uptime هنوز کمتر از ۳۰ دقیقه است | 2m |
| `WindowsExporterCollectorFailed` | p0-availability | `windows_exporter_collector_success == 0` | 10m |
| `DataPlatformServiceNotRunning` | p0-availability | سرویس SQL/SSAS/PBIRS/ClusSvc running نیست | 3m |
| `MssqlCollectorFailed` | p0-availability | `windows_mssql_collector_success == 0` | 10m |
| `WindowsTimeSkewCritical` | p0-availability | \|time offset\| > 5s | 5m |
| `WindowsDiskSpaceCritical` | p0-host | درایو fixed یا مسیر mount حداقل ۱۰ GiB؛ فضای آزاد کمتر از ۵٪ و کمتر از ۳۰ GiB. دیسک‌های SQL Data، SQL Tempdb Data، Olap Data، SQL Tempdb Log، SQL Log و SQL Backup جدا هستند | 10m |
| `WindowsSqlDataDiskSpaceCritical` | p0-host | `volume_name` برابر SQL Data، شامل `SQL Data 01` و `SQL Data01`. همان آستانه ۵٪ و ۳۰ GiB | 10m |
| `WindowsSqlTempdbDataDiskSpaceCritical` | p0-host | `volume_name` برابر SQL Tempdb Data، شامل `SQL Tempdb Data 01` و `SQL TempdbData01`. همان آستانه | 10m |
| `WindowsOlapDataDiskSpaceCritical` | p0-host | `volume_name` برابر Olap Data، شامل `OLAP Data 01` و `SQL Olap Data 01`. OLAP Cache روی alert عمومی می‌ماند. همان آستانه | 10m |
| `WindowsSqlTempdbLogDiskSpaceCritical` | p0-host | `volume_name` برابر SQL Tempdb Log، شامل `SQL Tempdblog 01`. همان آستانه | 10m |
| `WindowsSqlLogDiskSpaceCritical` | p0-host | `volume_name` برابر SQL Log، شامل `SQL Log 01` و `SQL Log03`. همان آستانه | 10m |
| `WindowsSqlBackupDiskSpaceCritical` | p0-host | `volume_name` برابر SQL Backup، شامل `SQL Backup` و `SQL Backup 01`، روی `U:` یا درایو دیگر. همان آستانه. volume با نام فقط `Backup` خارج است | 10m |
| `WindowsOlapDiskFreeSpaceCritical` | p0-host | دیسک OLAP هنوز در حال پر شدن است و کندترِ رشد ۱روزه و رشد کامل ۷روزه کمتر از ۳ روز جا می‌گذارد | 30m |
| `WindowsBackupDiskFreeSpaceCritical` | p0-host | فضای خالی دیسک بکاپ U کمتر از ۳ روز رشد خودش | 30m |
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
| `WindowsDiskSpaceLow` | p1-host | درایو fixed غیر از `U:` و شش نام نقش SQL/Olap، فضای آزاد کمتر از ۱۰٪ و کمتر از ۱۰۰ GiB، مگر اینکه شرط بحرانی برقرار باشد | 15m |
| `WindowsSqlDataDiskSpaceLow` | p1-host | دیسک SQL Data، همان هشدار ۱۰٪ و ۱۰۰ GiB، مگر اینکه شرط alert بحرانی خودش برقرار باشد | 15m |
| `WindowsSqlTempdbDataDiskSpaceLow` | p1-host | دیسک SQL Tempdb Data، همان هشدار، مگر اینکه شرط alert بحرانی خودش برقرار باشد | 15m |
| `WindowsOlapDataDiskSpaceLow` | p1-host | دیسک Olap Data، همان هشدار، مگر اینکه شرط alert بحرانی خودش برقرار باشد | 15m |
| `WindowsSqlTempdbLogDiskSpaceLow` | p1-host | دیسک SQL Tempdb Log، همان هشدار، مگر اینکه شرط alert بحرانی خودش برقرار باشد | 15m |
| `WindowsSqlLogDiskSpaceLow` | p1-host | دیسک SQL Log، همان هشدار، مگر اینکه شرط alert بحرانی خودش برقرار باشد | 15m |
| `WindowsSqlBackupDiskSpaceLow` | p1-host | دیسک SQL Backup روی `U:` یا درایو دیگر، همان هشدار، مگر اینکه شرط alert بحرانی خودش برقرار باشد | 15m |
| `WindowsOlapDiskFreeSpaceLow` | p1-host | دیسک OLAP هنوز در حال پر شدن است و کندترِ رشد ۱روزه و رشد کامل ۷روزه کمتر از ۱۴ روز جا می‌گذارد | 1h |
| `WindowsBackupDiskFreeSpaceLow` | p1-host | فضای خالی دیسک بکاپ U کمتر از ۱۴ روز رشد خودش | 1h |
| `WindowsDiskReadLatencyHigh` | p1-host | read latency > 50ms؛ اولویت P3، بدون SMS و Email | 15m |
| `WindowsDiskWriteLatencyHigh` | p1-host | write latency > 50ms؛ اولویت P3، بدون SMS و Email | 15m |
| `WindowsCommitChargeHigh` | p1-host | commit ratio > 90%؛ اولویت P3، بدون SMS و Email | 15m |
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
| `WindowsBackupDiskFreeWarning` | p2-host | فضای آزاد `U:` بین ۱۰٪ و ۱۵٪ (فقط ایمیل) | 30m |
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
| `instance_volume:windows_disk_free_bytes` | `WindowsDiskSpaceLow`، `WindowsDiskSpaceCritical`، alertهای بحرانی نقش SQL و Olap Data |
| `instance_volume:windows_disk_size_bytes` | `WindowsDiskSpaceLow`، `WindowsDiskSpaceCritical`، alertهای بحرانی نقش SQL و Olap Data |
| `instance_volume:windows_disk_free_ratio` | `WindowsDiskSpaceLow`، `WindowsDiskSpaceCritical`، alertهای بحرانی نقش SQL و Olap Data |
| `instance_volume:windows_olap_disk_free_days` | هشدار باند پر شدن دیسک OLAP |
| `instance_volume:windows_backup_disk_free_days` | `WindowsBackupDiskFreeSpaceCritical` |
| `instance_volume:windows_disk_free_ratio` | disk space alerts |
| `instance_volume:windows_backup_disk_free_percent` | درصد آزاد مسیر بکاپ |
| `instance_volume:windows_backup_disk_capacity_state` | `WindowsBackupDiskFreeCritical`، `WindowsBackupDiskFreeWarning` |
| `instance_volume:windows_logical_disk_*_latency_seconds:rate5m` | disk latency alerts |
| `instance:windows_pagefile_free_ratio` | `WindowsPagefileLow` |
| `instance:windows_terminal_services_*_sessions` | RDS session alerts |
| `instance_mssql:buffer_cache_hit_ratio:rate5m` | `MssqlBufferCacheLow` |

`instance_volume:windows_disk_free_*` درایو fixed و مسیر mount را نگه می‌دارد (`volume=~"[A-Za-z]:.*"` و `type="fixed"`) با اندازه حداقل ۱۰ GiB، از جمله `C:` و `E:\Data01`، و `volume_name` را هم دارد. `U:`، `HarddiskVolume*`، CD و دیسک removable حذف می‌شوند. `WindowsDiskSpaceCritical` شش کلاس `volume_name` را کنار می‌گذارد و هر کلاس alert جداگانه P0 با همان شرط ۵٪ و ۳۰ GiB دارد: SQL Data (`SQL Data 01`، `SQL Data01`)، SQL Tempdb Data (`SQL Tempdb Data 01`، `SQL TempdbData01`)، Olap Data (`OLAP Data`، `OLAP Data 01`، `SQL Olap Data 01`)، SQL Tempdb Log (`SQL Tempdb Log`، `SQL Tempdblog 01`)، SQL Log (`SQL Log 01`، `SQL Log03`) و SQL Backup (`SQL Backup`، `SQL Backup 01`). `U:` از سری عمومی حذف شده، بنابراین `WindowsSqlBackupDiskSpaceCritical` برای این volumeها از `instance_volume:windows_backup_disk_*` می‌خواند و برای SQL Backup روی درایو دیگر از سری عمومی. هر volume فقط با یکی از این alertها جور می‌شود. `SQL Tempdata`، `OLAP Cache`، `Olap`، volume با نام فقط `Backup`، `Postgresql Backup`، binary و OS وقتی در سری عمومی باشند روی `WindowsDiskSpaceCritical` می‌مانند. silence روی `WindowsDiskSpaceCritical` این شش alert را نمی‌پوشاند. `WindowsDiskSpaceLow` همین شش کلاس را کنار می‌گذارد. هر کلاس alert جداگانه P1 با همان شرط ۱۰٪ و ۱۰۰ GiB دارد و وقتی volume از قبل زیر ۵٪ و ۳۰ GiB باشد خاموش می‌ماند. `instance_volume:windows_backup_disk_*` حجم‌های fixed روی `U:` را نگه می‌دارد، از جمله `U:\Databases\Backup01`. رشد روزانه ۶۴ MiB یا کمتر هشدار runway نمی‌سازد. باند پرواز OLAP کندترِ نرخ خالص ۱روزه و نرخ کامل ۷روزه است و فقط وقتی ۶ ساعت اخیر هنوز در حال رشد باشد ثبت می‌شود. volume جوان‌تر از ۷ روز، یا بارگذاری تمام‌شده، هشدار نمی‌سازد. باند پرواز بکاپ هنوز deriv هفت‌روزه است. هشدار runway در ۱۴ روز و ۳ روز است. Alertmanager هشدار ۱۴ روز و page درصد ۱۰٪ را وقتی هشدار ۳ روز برای همان volume فعال است خاموش می‌کند.

## راهنمای tuning

1. Thresholdهای AG (100MB) و PLE (300s) و user connections (500) را با baseline هر instance تنظیم کنید.
2. Alertهای نقش را فقط روی job/targetهایی که متریک مربوطه دارند load کنید، یا با `inhibit`/`mute` در Alertmanager محدود کنید.
3. `WindowsExporterDown` یعنی target مربوط به windows_exporter قطع است. shutdown، crash، قطع شبکه و توقف exporter از روی `up` قابل تفکیک نیستند. page مربوط به down بودن سرور `InstanceDown` است و وقتی هر دو exporter قطع باشند فعال می‌شود. `WindowsHostRestarted` فقط reboot را بعد از برگشتن scrape می‌بیند.

## Alertmanager — routing با SMS و Email

کانفیگ نمونه: `alertmanager/windows-exporter/alertmanager.yml`  
جزئیات کامل: [Alertmanager](alertmanager.md)

| اولویت | کانال | تکرار |
|---|---|---|
| P0 | SMS (webhook) + Email | ۱۵ دقیقه |
| P1 | Email + SMS (webhook) | ۱ ساعت |
| P2 | فقط Email | ۱۲ ساعت |
| P3 | فقط لیست alert | ندارد |

`WindowsOlapDiskFreeSpaceCritical` و `WindowsBackupDiskFreeSpaceCritical` هر ۱۲ ساعت تکرار می‌شوند. `WindowsOlapDiskFreeSpaceLow` و `WindowsBackupDiskFreeSpaceLow` هر ۲۴ ساعت. اولین اعلان همین چهار آلرت هنوز بعد از ۳۰ ثانیه می‌رود. `Windows*DiskSpaceCritical` هر ۱ ساعت و `Windows*DiskSpaceLow` هر ۴ ساعت تکرار می‌شود. اولین اعلان این‌ها همچنان سریع است.

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
