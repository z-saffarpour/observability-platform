# Collector alwayson

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-alwayson.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Always On Availability Groups - Primary-node view only (metrics joined to role_desc=PRIMARY). Lag/queues, replica & group health, commit latency, sync flaps, failover readiness. Filter by Server and AG.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-alwayson` |
| Source file | [`sqlx-alwayson.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-alwayson.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `alwayson` |
| Panel count | 46 |
| Refresh interval | `15s` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `ag` | AG | `query` | `label_values(mssql_alwayson_replica_role{job="sql_exporter", instance=~"$instance"}, availability_group_name)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | KPI (Primary view) | `row` |
| 2 | Max Lag | `stat` |
| 3 | Max Data Loss | `stat` |
| 4 | Max Redo Drain | `stat` |
| 5 | Max Commit Lat | `stat` |
| 6 | Max Log Send Q | `stat` |
| 7 | Max Redo Q | `stat` |
| 8 | Suspended | `stat` |
| 9 | Not Failover Ready | `stat` |
| 10 | Disconnected | `stat` |
| 11 | Unhealthy Replicas | `stat` |
| 12 | Unhealthy Groups | `stat` |
| 13 | Sync Flaps 24h | `stat` |
| 14 | Inventory (Primary view) | `row` |
| 15 | AG Pair Lag / Queues / Commit (Primary only) | `table` |
| 16 | Replicas from Primary (role / connected / sync / flaps) | `table` |
| 17 | DB Sync / Health / Failover / Suspended (Primary view) | `table` |
| 18 | AG Group Health (Primary view) | `table` |
| 19 | Lag & Queues (Primary view) | `row` |
| 20 | Secondary Lag | `timeseries` |
| 21 | Estimated Data Loss | `timeseries` |
| 22 | Log Send Queue | `timeseries` |
| 23 | Redo Queue | `timeseries` |
| 24 | Log Send Rate | `timeseries` |
| 25 | Redo Rate | `timeseries` |
| 26 | Redo Drain ETA | `timeseries` |
| 27 | Log Send Drain ETA | `timeseries` |
| 28 | Commit Latency | `timeseries` |
| 29 | Log send rate / redo queue growth (KB/s) | `timeseries` |
| 30 | Health & Seeding (Primary view) | `row` |
| 31 | Replica Connected (1=ok) | `timeseries` |
| 32 | Replica Sync Health (2=healthy) | `timeseries` |
| 33 | Disconnected Seconds | `timeseries` |
| 34 | Sync State Flaps 24h | `timeseries` |
| 35 | Group Sync Health | `timeseries` |
| 36 | Primary Recovery Health | `timeseries` |
| 37 | Failover Ready (1=yes) | `timeseries` |
| 38 | Suspended (1=yes) | `timeseries` |
| 39 | Filestream Send Rate | `timeseries` |
| 40 | Seeding % | `timeseries` |
| 41 | Per-replica DB queues (Primary view) | `row` |
| 42 | Replica DB Log Send Queue | `timeseries` |
| 43 | Replica DB Redo Queue | `timeseries` |
| 44 | Replica DB Log Send Rate | `timeseries` |
| 45 | Replica DB Redo Rate | `timeseries` |
| 46 | Replica DB Secondary Lag | `timeseries` |

Panel type summary: `row`: 5, `stat`: 12, `table`: 4, `timeseries`: 25

## Metrics used

- `mssql_alwayson_commit_latency_ms`
- `mssql_alwayson_disconnected_seconds`
- `mssql_alwayson_estimated_data_loss_seconds`
- `mssql_alwayson_filestream_send_rate_kb_s`
- `mssql_alwayson_group_primary_recovery_health`
- `mssql_alwayson_group_synchronization_health`
- `mssql_alwayson_is_failover_ready`
- `mssql_alwayson_is_suspended`
- `mssql_alwayson_log_send_queue_kb`
- `mssql_alwayson_log_send_queue_remaining_seconds`
- `mssql_alwayson_log_send_rate_kb_s`
- `mssql_alwayson_redo_queue_growth_kb_s`
- `mssql_alwayson_redo_queue_kb`
- `mssql_alwayson_redo_queue_remaining_seconds`
- `mssql_alwayson_redo_rate_kb_s`
- `mssql_alwayson_replica_connected_state`
- `mssql_alwayson_replica_db_is_suspended`
- `mssql_alwayson_replica_db_log_send_queue_kb`
- `mssql_alwayson_replica_db_log_send_rate_kb_s`
- `mssql_alwayson_replica_db_redo_queue_kb`
- `mssql_alwayson_replica_db_redo_rate_kb_s`
- `mssql_alwayson_replica_db_secondary_lag_seconds`
- `mssql_alwayson_replica_db_synchronization_health`
- `mssql_alwayson_replica_role`
- `mssql_alwayson_replica_synchronization_health`
- `mssql_alwayson_secondary_lag_seconds`
- `mssql_alwayson_seeding_percent`
- `mssql_alwayson_sync_state_flaps_24h`
- `mssql_alwayson_synchronization_state`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
