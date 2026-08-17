# Collector documentation

This folder contains a dedicated guide for each collector.

| Collector | min_interval | metric count | summary |
|---|---|---|---|
| `mssql_alwayson.md` | `30s` | `32` | Always On Availability Groups — comprehensive monitoring. |
| `mssql_alwayson_events.md` | `300s` | `1` | AlwaysOn_health replica state-change flaps (24h). |
| `mssql_autogrowth.md` | `300s` | `8` | Data/Log autogrowth events from the default trace (last ~hours of trace files). |
| `mssql_backup.md` | `900s` | `10` | Database backup freshness and size (msdb.dbo.backupset). |
| `mssql_blocking.md` | `30s` | `6` | Blocking / head-blocker metrics for Microsoft SQL Server. |
| `mssql_buffer_pool.md` | `180s` | `5` | Buffer pool / buffer manager health. |
| `mssql_cdc_change_tracking.md` | `300s` | `17` | CDC and Change Tracking health and configuration. |
| `mssql_certificates.md` | `300s` | `2` | Certificate expiry days and TDE encryption_state. |
| `mssql_columnstore.md` | `300s` | `12` | Columnstore rowgroup health (useful on DWH / BI hosts). |
| `mssql_connections_detail.md` | `60s` | `10` | Client connection breakdown — shared for DWH and OLTP. |
| `mssql_cpu.md` | `30s` | `4` | SQL Server process CPU vs system idle / other — from ring buffer. |
| `mssql_database_integrity.md` | `3600s` | `7` | Database integrity: suspect pages + CHECKDB age/coverage + last-good timestamp. |
| `mssql_database_configuration.md` | `300s` | `17` | Database settings and configuration-drift signals. |
| `mssql_database_size_growth.md` | `300s` | `3` | Database data/log size and used space — growth tracking via Prometheus. |
| `mssql_database_space.md` | `300s` | `10` | Database file capacity, free space, autogrowth, and VLF count. |
| `mssql_errorlog_signals.md` | `300s` | `1` | ERRORLOG signal counters for selected SQL errors (last N hours). |
| `mssql_file_io.md` | `180s` | `16` | Per-file I/O latency metrics for Microsoft SQL Server. |
| `mssql_hadr_cluster.md` | `30s` | `11` | AG listeners, WSFC quorum/members, and FCI node ownership. |
| `mssql_heavy_queries.md` | `60s` | `13` | Heavy / active query metrics for Microsoft SQL Server. |
| `mssql_index_fragmentation.md` | `21600s` | `2` | Index fragmentation sample (LIMITED) — EXPENSIVE. Run rarely. |
| `mssql_index_usage.md` | `300s` | `19` | Index usage ops: hot indexes, ratios, unused/write-heavy candidates, DB rollup. |
| `mssql_instance_configuration.md` | `300s` | `7` | Instance sp_configure drift (value vs in_use), IFI, uptime, global trace flags. |
| `mssql_job_failed.md` | `60s` | `7` | SQL Agent job failures — dedicated alerting surface. |
| `mssql_job_history.md` | `120s` | `8` | SQL Agent job history (sysjobhistory) — failures, run counts, last durations. |
| `mssql_job_inventory.md` | `900s` | `5` | SQL Agent job inventory / last-run snapshot / next schedule. |
| `mssql_job_running.md` | `30s` | `5` | Currently running SQL Agent jobs (+ Agent service state). |
| `mssql_locks.md` | `30s` | `7` | Lock inventory and waiting locks. |
| `mssql_log_shipping.md` | `60s` | `6` | Log Shipping secondary lag / restore age / copy lag / thresholds. |
| `mssql_log_usage.md` | `60s` | `3` | Transaction log usage — shared for DWH and OLTP. |
| `mssql_memory.md` | `60s` | `16` | Memory metrics for Microsoft SQL Server. |
| `mssql_missing_index.md` | `600s` | `11` | Missing index DMV sample (TOP N) + cost/compiles + per-DB rollup. |
| `mssql_parallelism.md` | `60s` | `6` | Parallelism related waits, configs, and active parallel requests. |
| `mssql_plan_cache.md` | `120s` | `13` | Plan cache size, object-type breakdown, and single-use plan pressure. |
| `mssql_polybase.md` | `60s` | `39` | PolyBase install, node/DMS health, distributed workload, catalog inventory, and recent errors. |
| `mssql_query_store.md` | `300s` | `11` | Query Store enablement, health options, and top queries. |
| `mssql_replication.md` | `60s` | `21` | SQL Server Replication (Transactional Push / Pull) |
| `mssql_resource_governor.md` | `60s` | `27` | Resource-pool and workload-group configuration and pressure. |
| `mssql_restore.md` | `300s` | `14` | Restore / backup-sync freshness (msdb.dbo.restorehistory + backupset). |
| `mssql_scheduler.md` | `30s` | `12` | Scheduler / SOS worker pressure and CPU topology. |
| `mssql_security.md` | `300s` | `25` | SQL Server security posture: login failures, audit, privileged access, encryption, surface area, and moved security metrics. |
| `mssql_service_broker.md` | `60s` | `65` | Service Broker queues, transmission, conversations, endpoint/transport, activation and forwarding. |
| `mssql_ssis.md` | `60s` | `32` | SSIS catalog + SSISDB health monitoring. |
| `mssql_standard.md` | `30s` | `25` | Core instance identity + unique counters not owned by specialized collectors. |
| `mssql_stats.md` | `600s` | `6` | Stale / heavily modified statistics (TOP N across online user databases). |
| `mssql_tempdb.md` | `60s` | `13` | tempdb metrics for Microsoft SQL Server. |
| `mssql_transactions_long.md` | `30s` | `3` | Long-running open transactions. |
| `mssql_waits.md` | `120s` | `10` | Wait stats metrics for Microsoft SQL Server. |

## Quick start

1. Read [install-config-guide](../install-config-guide.md) first.
2. Open the relevant collector doc.
3. If you add a new collector, also read [collector-guide](../collector-guide.md).
