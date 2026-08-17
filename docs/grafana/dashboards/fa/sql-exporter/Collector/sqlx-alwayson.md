# Collector alwayson

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-alwayson.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Always On Availability Groups - Primary-node view only (metrics joined to role_desc=PRIMARY). Lag/queues, replica & group health, commit latency, sync flaps, failover readiness. Filter by Server and AG.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-alwayson` |
| فایل منبع | [`sqlx-alwayson.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-alwayson.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `alwayson` |
| تعداد پنل‌ها | 46 |
| بازهٔ تازه‌سازی | `15s` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `ag` | AG | `query` | `label_values(mssql_alwayson_replica_role{job="sql_exporter", instance=~"$instance"}, availability_group_name)` |

## پنل‌ها

| ردیف | عنوان | نوع |
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

ترکیب نوع پنل‌ها: `row`: 5, `stat`: 12, `table`: 4, `timeseries`: 25

## متریک‌های استفاده‌شده

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

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
