# داشبوردهای Grafana — SQL Exporter

[English](../en/grafana.md)

آینهٔ پوشه‌های Grafana زیر **AI-SQL Exporter**:

| پوشه Grafana | مسیر در ریپو |
|----------------|-----------|
| `AI-SQL Exporter` (ریشه) | `grafana/dashboards/` |
| `Collector` (`sqlx-collector`) | `grafana/dashboards/sql-exporter/Collector/` |

**Datasource:** `prometheus` (UID `ce0xqwhy35wqod`)  
**Job:** `sql_exporter`  
**Variable:** `Server` (`instance`) — چندانتخابی + All  
**Variable:** `Over Avg x` (`over_avg_factor`، پیش‌فرض `1.5`) — برای پنل‌های Jobs Over Avg / Long

## ریشه (Overview + NOC)

| فایل / Grafana UID | نقش |
|------|------|
| `sqlx-00-overview.json` | Overview اصلی (KPI + inventory ناوگان) |
| `sqlx-00-overview-exceptions.json` | Overview Exceptions |
| `sqlx-00-overview-exceptions-lite.json` | Overview Exceptions Lite |
| `sqlx-00-overview-ops.json` | Overview Live Ops (رفرش ۱۵s) |
| `sqlx-00-overview-classic.json` | Overview Classic |
| `sqlx-security-noc.json` | Security NOC wallboard |

## Collector/

| فایل | Collector |
|------|-----------|
| `sqlx-standard.json` | mssql_standard |
| `sqlx-cpu.json` | mssql_cpu |
| `sqlx-scheduler.json` | mssql_scheduler |
| `sqlx-connections.json` | mssql_connections_detail |
| `sqlx-alwayson.json` | mssql_alwayson |
| `sqlx-hadr-cluster.json` | mssql_hadr_cluster |
| `sqlx-blocking.json` | mssql_blocking |
| `sqlx-locks.json` | mssql_locks |
| `sqlx-transactions-long.json` | mssql_transactions_long |
| `sqlx-waits.json` | mssql_waits |
| `sqlx-heavy-queries.json` | mssql_heavy_queries + mssql_plan_cache_hotspots |
| `sqlx-parallelism.json` | mssql_parallelism |
| `sqlx-plan-cache.json` | mssql_plan_cache |
| `sqlx-query-store.json` | mssql_query_store |
| `sqlx-memory.json` | mssql_memory |
| `sqlx-resource-governor.json` | mssql_resource_governor |
| `sqlx-buffer-pool.json` | mssql_buffer_pool + mssql_buffer_pool_database |
| `sqlx-database-space.json` | mssql_database_space |
| `sqlx-database-size-growth.json` | mssql_database_size_growth |
| `sqlx-log-usage.json` | mssql_log_usage |
| `sqlx-file-io.json` | mssql_file_io |
| `sqlx-tempdb.json` | mssql_tempdb |
| `sqlx-autogrowth.json` | mssql_autogrowth |
| `sqlx-backup.json` | mssql_backup |
| `sqlx-database-integrity.json` | mssql_database_integrity |
| `sqlx-database-configuration.json` | mssql_database_configuration |
| `sqlx-instance-configuration.json` | mssql_instance_configuration |
| `sqlx-restore.json` | mssql_restore |
| `sqlx-job-inventory.json` | mssql_job_inventory |
| `sqlx-job-running.json` | mssql_job_running |
| `sqlx-job-failed.json` | mssql_job_failed |
| `sqlx-job-history.json` | mssql_job_history |
| `sqlx-jobs-hub.json` | Jobs hub (ناوبری بین Jobها) |
| `sqlx-index-usage.json` | mssql_index_usage |
| `sqlx-missing-index.json` | mssql_missing_index |
| `sqlx-stats.json` | mssql_stats |
| `sqlx-index-fragmentation.json` | mssql_index_fragmentation |
| `sqlx-columnstore.json` | mssql_columnstore |
| `sqlx-ssis.json` | mssql_ssis |
| `sqlx-replication.json` | mssql_replication |
| `sqlx-polybase.json` | mssql_polybase |
| `sqlx-service-broker.json` | mssql_service_broker |
| `sqlx-errorlog-signals.json` | mssql_errorlog_signals |
| `sqlx-cdc.json` | mssql_cdc (CDC) |
| `sqlx-change-tracking.json` | mssql_change_tracking |
| `sqlx-security.json` | mssql_security |

## Import

1. در Grafana از پوشه **AI-SQL Exporter** استفاده کنید؛ داشبوردهای collector را در زیرپوشه **Collector** بگذارید.
2. **Dashboards → Import → Upload JSON file**
3. ابتدا Overview (ریشه)، سپس فایل‌های `grafana/dashboards/sql-exporter/Collector/` را import کنید.
4. با متغیر **Server** بالای هر داشبورد فیلتر کنید.

### همگام‌سازی از Grafana → ریپو

```powershell
# نیاز به GRAFANA_URL + GRAFANA_SERVICE_ACCOUNT_TOKEN
# ریشه + Collector/ را مطابق پوشه‌های Grafana می‌نویسد
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\powershell\sql-exporter\Export-GrafanaDashboards.ps1
# اختیاری: حذف sqlx-*.json محلی که دیگر در Grafana نیست
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\powershell\sql-exporter\Export-GrafanaDashboards.ps1 -RemoveOrphans
```

### Import انبوه از طریق API

```powershell
$base = 'https://YOUR-GRAFANA'
$token = 'YOUR_TOKEN'
$rootFolderUid = 'ffunk7atj72m8c'      # AI-SQL Exporter
$collectorFolderUid = 'sqlx-collector' # Collector

function Import-DashDir([string]$dir, [string]$folderUid) {
  Get-ChildItem $dir -Filter 'sqlx-*.json' -File | Sort-Object Name | ForEach-Object {
    $dash = Get-Content $_.FullName -Raw | ConvertFrom-Json
    $body = @{
      dashboard = $dash
      folderUid = $folderUid
      overwrite = $true
      message = "Import $($dash.title)"
    } | ConvertTo-Json -Depth 40
    Invoke-RestMethod -Method POST -Uri "$base/api/dashboards/db" `
      -Headers @{ Authorization = "Bearer $token" } `
      -ContentType 'application/json' -Body $body
  }
}

Import-DashDir .\grafana\dashboards $rootFolderUid
Import-DashDir .\grafana\dashboards\Collector $collectorFolderUid
```
