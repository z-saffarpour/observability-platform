# SQL Exporter profiles

[نسخه فارسی](../fa/profiles.md)

Each file under `profiles/` contains the complete `target.collectors` list for one server role.
SQL Exporter does not merge or inherit profile files, so specialized profiles
repeat their core collectors intentionally.

## Profiles

| Profile | Intended use |
|---|---|
| `core.yml` | Baseline monitoring for every SQL Server instance (includes instance configuration drift) |
| `oltp.yml` | Transactional workloads, live-query diagnostics, Always On/HADR, Query Store |
| `dwh.yml` | Data warehouse / BI, columnstore and parallel workloads |
| `ssis.yml` | Dedicated SSIS catalog hosts |
| `polybase.yml` | Instances with PolyBase installed / external data queries |
| `replication.yml` | Replication publisher, distributor or subscriber (includes AG/HADR + CDC) |
| `service-broker.yml` | Service Broker hosts (queues, transmission, activation, transport) |
| `security-audit.yml` | Security posture, audit, error-log signals, certificates (no heavy perf-detail) |
| `restore-secondary.yml` | Restore / backup-sync secondary instances (restore, log shipping, AG/HADR) |
| `alert-p0.yml` | Minimum collectors for P0 (Critical) alerts |
| `alert-p1.yml` | P0 + P1 collectors |
| `alert-p2.yml` | P0 + P1 + P2 collectors (no role packs) |

## Usage

### Scripts (recommended)

Same parameter style as Windows Exporter (`-Profile sql-server.yml`):

```powershell
.\scripts\powershell\sql-exporter\Install-SqlExporterRemote.ps1 -Computers SQL01 -Profile oltp.yml
.\scripts\powershell\sql-exporter\Upgrade-SqlExporterRemote.ps1 -Computers SQL01 -Profile oltp.yml
.\scripts\powershell\sql-exporter\Deploy-SqlExporterConfig.ps1  -Computers SQL01 -Profile oltp.yml

# Minimum metrics for prioritized alerts (see alerting.md)
.\scripts\powershell\sql-exporter\Deploy-SqlExporterConfig.ps1 -Computers SQL01 -Profile alert-p1.yml
```

The scripts copy `profiles/` to the install path and write the selected
profile’s `collectors:` list into `sql_exporter.yml`.

### Manual

Copy the complete `collectors:` block from the selected profile and replace
`target.collectors` in `sql_exporter.yml`. Keep this line unchanged so all
collector definitions remain available:

```yaml
collector_files:
  - "collector/*.collector.yml"
```

Use one role profile per exporter instance. If an instance has multiple roles,
start with the closest profile and add only the required specialized collector,
for example `mssql_replication`, `mssql_ssis`, `mssql_polybase` or `mssql_service_broker`.

The `security-audit` profile may require elevated permissions for SQL Audit,
ERRORLOG and server security metadata. **Before using alerts on
`mssql_unexpected_login_count`, edit the inline allow-list in
`collector/mssql_security.collector.yml` (query `mssql_security_unexpected_logins`);
see [mssql_security.md](collectors/mssql_security.md#allow-list-for-mssql_unexpected_login_count).
The `database_integrity` collector runs
`DBCC DBINFO` against accessible online databases.

`alert-p0.yml`, `alert-p1.yml` and `alert-p2.yml` provide the minimum collectors
needed to evaluate P0/P1/P2 alerts. Ready `rule_files` packs live under
`prometheus/scrape-configs/sql-exporter/`. See [alerting.md](alerting.md).

## Timeout for expensive collectors

SQL Exporter v0.24.4 supports `scrape_timeout` globally, not per collector. The
repository configuration therefore allows up to 55 seconds for a collection.
Configure the matching Prometheus scrape job with a slightly larger timeout:

```yaml
scrape_configs:
  - job_name: sql_exporter
    scrape_interval: 90s
    scrape_timeout: 60s
```

Prometheus sends its timeout to the exporter on every request. The effective
exporter timeout is the smaller of the local 55-second limit and the Prometheus
timeout minus `scrape_timeout_offset`.

Collectors such as `mssql_index_fragmentation`, `mssql_database_integrity`,
`mssql_query_store`, `mssql_stats`, `mssql_columnstore`, `mssql_security` and
`mssql_errorlog_signals` keep their own long `min_interval`; the increased
timeout does not cause them to execute on every Prometheus scrape.

## v0.24.4 validation

The packaged v0.24.4 binary can validate the main configuration and every
collector definition loaded by `collector_files` without starting the HTTP
listener:

```powershell
.\sql_exporter.exe "-config.file=sql_exporter.yml" -config.check
```

`collectors: [mssql_*]` makes all collector definitions available, but a
role-specific profile remains the recommended production configuration. Some
collectors return no series when their SQL Server feature is disabled or their
required database is absent; examples include CDC, replication, SSIS, PolyBase,
Service Broker, Query Store, Always On and Resource Governor.

For rollout diagnostics, enable per-query exporter metrics temporarily:

```yaml
global:
  enable_query_metrics: true
```

This exposes `query_duration_seconds` and `query_rows_returned`. Review their
cardinality and storage impact before leaving the option enabled permanently.
