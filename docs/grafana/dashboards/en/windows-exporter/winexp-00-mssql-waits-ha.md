# SQL Waits & HA

[Dashboard index](../README.md) · [Grafana guide](../../../../../grafana/README.md) · [فارسی](../../fa/windows-exporter/winexp-00-mssql-waits-ha.md) · [Exporter documentation](../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

The dashboard JSON does not provide a description.

## Details

| Property | Value |
|---|---|
| UID | `winexp-00-mssql-waits-ha` |
| Source file | [`winexp-00-mssql-waits-ha.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-mssql-waits-ha.json) |
| Tags | `windows_exporter`, `mssql`, `waits`, `availability` |
| Panel count | 17 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_os_info, job)` |
| `owner` | Owner | `query` | `label_values(windows_os_info{job=~"$job"}, owner)` |
| `instance` | Server | `query` | `label_values(windows_os_info{job=~"$job",owner=~"${owner:regex}"}, instance)` |
| `mssql_instance` | SQL Instance | `query` | `label_values(windows_mssql_genstats_user_connections{job=~"$job",instance=~"${instance:regex}"}, mssql_instance)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Wait Statistics | `row` |
| 2 | Page IO Latch Waits / sec | `timeseries` |
| 3 | Page Latch / Nonpage Latch Waits | `timeseries` |
| 4 | Lock / Memory Grant / Network IO Waits | `timeseries` |
| 5 | Log Write / Log Buffer Waits | `timeseries` |
| 6 | Worker / Workspace Sync Waits | `timeseries` |
| 7 | Access Methods | `row` |
| 8 | Scans / Index Searches / sec | `timeseries` |
| 9 | Page Splits / Forwarded Records | `timeseries` |
| 10 | Availability / Replica | `row` |
| 11 | AG Replica Bytes Sent / Received | `timeseries` |
| 12 | DB Replica Send / Apply Queues | `timeseries` |
| 13 | Redo / Transaction Delay | `timeseries` |
| 14 | Flow Control | `timeseries` |
| 15 | Version Store & Errors | `row` |
| 16 | Version Store Size | `timeseries` |
| 17 | SQL Errors / sec | `timeseries` |

Panel type summary: `row`: 4, `timeseries`: 13

## Metrics used

- `windows_mssql_accessmethods_forwarded_records`
- `windows_mssql_accessmethods_full_scans`
- `windows_mssql_accessmethods_index_searches`
- `windows_mssql_accessmethods_page_splits`
- `windows_mssql_accessmethods_range_scans`
- `windows_mssql_availreplica_initiated_flow_controls`
- `windows_mssql_availreplica_received_from_replica_bytes`
- `windows_mssql_availreplica_sent_to_replica_bytes`
- `windows_mssql_dbreplica_database_initiated_flow_controls`
- `windows_mssql_dbreplica_log_apply_pending_queue`
- `windows_mssql_dbreplica_log_send_queue`
- `windows_mssql_dbreplica_recovery_queue_records`
- `windows_mssql_dbreplica_redone_bytes`
- `windows_mssql_dbreplica_transaction_delay_seconds`
- `windows_mssql_genstats_user_connections`
- `windows_mssql_sql_errors_total`
- `windows_mssql_transactions_version_store_size_bytes`
- `windows_mssql_waitstats_lock_waits`
- `windows_mssql_waitstats_log_buffer_waits`
- `windows_mssql_waitstats_log_write_waits`
- `windows_mssql_waitstats_memory_grant_queue_waits`
- `windows_mssql_waitstats_network_io_waits`
- `windows_mssql_waitstats_nonpage_latch_waits`
- `windows_mssql_waitstats_page_io_latch_waits`
- `windows_mssql_waitstats_page_latch_waits`
- `windows_mssql_waitstats_wait_for_the_worker_waits`
- `windows_mssql_waitstats_workspace_synchronization_waits`
- `windows_os_info`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
