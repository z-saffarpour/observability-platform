# SSAS Overview

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/windows-exporter/winexp-00-ssas.md) · [Exporter documentation](../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

The dashboard JSON does not provide a description.

## Details

| Property | Value |
|---|---|
| UID | `winexp-00-ssas` |
| Source file | [`winexp-00-ssas.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-ssas.json) |
| Tags | `windows_exporter`, `ssas`, `tabular`, `multidimensional`, `analysis-services` |
| Panel count | 32 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `job` | Prometheus Job | `query` | `label_values(ssas_up, job)` |
| `instance` | Windows Server | `query` | `label_values(ssas_up{job=~"${job:regex}"}, instance)` |
| `ssas_instance` | SSAS Instance | `query` | `label_values(ssas_up{job=~"${job:regex}",instance=~"${instance:regex}"}, ssas_instance)` |
| `database` | Database | `query` | `label_values(ssas_database_info{job=~"${job:regex}",instance=~"${instance:regex}",ssas_instance=~"${ssas_instance:regex}"}, database)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | SSAS Availability | `stat` |
| 2 | Databases | `stat` |
| 3 | Active Sessions | `stat` |
| 4 | Connections | `stat` |
| 5 | Unique Logins | `stat` |
| 6 | High-Privilege Logins | `stat` |
| 7 | Privileged Active Sessions | `stat` |
| 8 | Collector Errors | `stat` |
| 9 | Sessions, Connections and Commands | `timeseries` |
| 10 | Login and Privilege Trend | `timeseries` |
| 11 | Database Processing Age | `bargauge` |
| 12 | Database Processing Status | `table` |
| 13 | Role Membership and Permission | `table` |
| 14 | Server Information | `table` |
| 15 | Collector Age and Duration | `timeseries` |
| 16 | msmdsrv CPU Usage | `timeseries` |
| 17 | msmdsrv Working Set | `timeseries` |
| 18 | Service / Endpoint / Auth Probe | `stat` |
| 19 | Service Uptime and Restarts | `timeseries` |
| 20 | Endpoint and Auth Latency | `timeseries` |
| 21 | Historical Login Activity | `timeseries` |
| 22 | Session Quality | `timeseries` |
| 23 | Sessions by Database | `bargauge` |
| 24 | Sessions by Application | `bargauge` |
| 25 | Processing and Backup Age | `timeseries` |
| 26 | Processing Duration / Failures | `timeseries` |
| 27 | Query Rate and Duration | `timeseries` |
| 28 | Memory Usage and Limits | `timeseries` |
| 29 | Cache, Locks and Thread Queues | `timeseries` |
| 30 | Processing, Storage Engine and DirectQuery | `timeseries` |
| 31 | Tabular Object / Segment Size | `table` |
| 32 | Disk Latency / IOPS / Free Space | `timeseries` |

Panel type summary: `bargauge`: 3, `stat`: 9, `table`: 4, `timeseries`: 16

## Metrics used

- `ssas_cache_hit_ratio`
- `ssas_collector_duration_seconds`
- `ssas_collector_errors`
- `ssas_collector_last_run_timestamp_seconds`
- `ssas_commands_active`
- `ssas_connections`
- `ssas_current_lock_waits`
- `ssas_database_info`
- `ssas_database_last_processed_timestamp_seconds`
- `ssas_database_processing_stale`
- `ssas_databases`
- `ssas_directquery_failures_total`
- `ssas_directquery_rate`
- `ssas_endpoint_response_seconds`
- `ssas_endpoint_up`
- `ssas_high_privilege_logins`
- `ssas_idle_sessions`
- `ssas_last_backup_timestamp_seconds`
- `ssas_last_processing_duration_seconds`
- `ssas_last_successful_processing_timestamp_seconds`
- `ssas_login_failures_total`
- `ssas_logins_total`
- `ssas_logouts_total`
- `ssas_long_running_sessions`
- `ssas_memory_limit_hard_kilobytes`
- `ssas_memory_limit_high_kilobytes`
- `ssas_memory_usage_kilobytes`
- `ssas_privileged_active_sessions`
- `ssas_processing_failures_total`
- `ssas_processing_rows_read_per_second`
- `ssas_query_duration_milliseconds`
- `ssas_query_rate`
- `ssas_readonly_probe_response_seconds`
- `ssas_readonly_probe_success`
- `ssas_role_members`
- `ssas_server_info`
- `ssas_service_restarts_total`
- `ssas_service_running`
- `ssas_service_uptime_seconds`
- `ssas_sessions`
- `ssas_sessions_by_application`
- `ssas_sessions_by_database`
- `ssas_storage_engine_queries_active`
- `ssas_tabular_object_size_bytes`
- `ssas_thread_pool_queue_length`
- `ssas_unique_logins`
- `ssas_up`
- `windows_logical_disk_free_bytes`
- `windows_logical_disk_read_seconds_total`
- `windows_logical_disk_reads_total`
- `windows_logical_disk_write_seconds_total`
- `windows_logical_disk_writes_total`
- `windows_process_cpu_time_total`
- `windows_process_working_set_bytes`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
