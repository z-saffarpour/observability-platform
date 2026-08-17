# mssql_alwayson

دسترسی خاص:

**فایل:** `collector/mssql_alwayson.collector.yml`
- نام collector: `mssql_alwayson`
- حداقل فاصله اجرا: `30s`
- تعداد metric: `32`
- query_refهای مشترک: `mssql_alwayson_groups`, `mssql_alwayson_pair`, `mssql_alwayson_replica_db`, `mssql_alwayson_replicas`, `mssql_alwayson_seeding`

## هدف و کاربرد

- پایش جامع گروه‌های Always On Availability.
- تاخیر جفت Primary/Secondary (متریک legacy `mssql_alwayson_data_loss` + gaugeهای صریح)
- صف‌های دیتابیس به‌ازای replica: `log_send` / `redo` / `filestream` + نرخ‌ها
- سلامت connected/sync/operational replica
- سلامت synchronization در سطح AG

## مجوزها و پیش‌نیازها
- نکات موجود در فایل منبع:
  - Permissions: VIEW SERVER STATE, VIEW ANY DEFINITION

مجوزهای پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_alwayson_data_loss` | `gauge` | `availability_group_name`, `server_primary`, `db`, `primary_connected_state`, `server_secondary`, `secondary_connected_state`, `synchronization_state_desc`, `synchronization_health_desc`, `availability_mode_desc` ; value_label=`operation` | `Estimated_data_loss_second`, `secondary_lag_seconds`, `redo_queue_size`, `redo_queue_size_kb`, `log_send_queue_size_kb`, `redo_rate_kb_s`, `log_send_rate_kb_s`, `filestream_send_rate_kb_s`, `redo_queue_remaining_seconds`, `log_send_queue_remaining_seconds`, `is_suspended`, `primary_last_commit_datetime`, `secondary_last_commit_datetime`, `secondary_last_hardened_datetime`, `secondary_last_redone_datetime`, `secondary_last_sent_datetime`, `secondary_last_received_datetime` | query_ref=`mssql_alwayson_pair` | Always On lag/queues/timestamps per primary-secondary database pair. |
| `mssql_alwayson_estimated_data_loss_seconds` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary`, `availability_mode_desc` | `Estimated_data_loss_second` | query_ref=`mssql_alwayson_pair` | Estimated data loss seconds (primary last_commit - secondary last_commit). |
| `mssql_alwayson_secondary_lag_seconds` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary`, `availability_mode_desc` | `secondary_lag_seconds` | query_ref=`mssql_alwayson_pair` | secondary_lag_seconds from dm_hadr_database_replica_states. |
| `mssql_alwayson_redo_queue_kb` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary` | `redo_queue_size_kb` | query_ref=`mssql_alwayson_pair` | Secondary redo_queue_size (KB). |
| `mssql_alwayson_log_send_queue_kb` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary` | `log_send_queue_size_kb` | query_ref=`mssql_alwayson_pair` | log_send_queue_size (KB) for the secondary pair. |
| `mssql_alwayson_log_send_rate_kb_s` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary` | `log_send_rate_kb_s` | query_ref=`mssql_alwayson_pair` | log_send_rate (KB/s) for the secondary pair. |
| `mssql_alwayson_redo_rate_kb_s` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary` | `redo_rate_kb_s` | query_ref=`mssql_alwayson_pair` | redo_rate (KB/s) for the secondary pair. |
| `mssql_alwayson_redo_queue_growth_kb_s` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary` | `redo_queue_growth_kb_s` | query_ref=`mssql_alwayson_pair` | Approx redo queue growth KB/s = max(log_send_rate - redo_rate, 0). |
| `mssql_alwayson_commit_latency_ms` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary` | `commit_latency_ms` | query_ref=`mssql_alwayson_pair` | Commit visibility lag proxy in ms (primary last_commit vs secondary last_hardened). |
| `mssql_alwayson_filestream_send_rate_kb_s` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary` | `filestream_send_rate_kb_s` | query_ref=`mssql_alwayson_pair` | filestream_send_rate (KB/s) for the secondary pair. |
| `mssql_alwayson_redo_queue_remaining_seconds` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary` | `redo_queue_remaining_seconds` | query_ref=`mssql_alwayson_pair` | Approx seconds to drain redo queue (queue_kb / redo_rate_kb_s). |
| `mssql_alwayson_log_send_queue_remaining_seconds` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary` | `log_send_queue_remaining_seconds` | query_ref=`mssql_alwayson_pair` | Approx seconds to drain log send queue (queue_kb / log_send_rate_kb_s). |
| `mssql_alwayson_is_suspended` | `gauge` | `availability_group_name`, `server_primary`, `db`, `server_secondary`, `suspend_reason_desc` | `is_suspended` | query_ref=`mssql_alwayson_pair` | 1 if data movement is suspended on the secondary database. |
| `mssql_alwayson_replica_db_log_send_queue_kb` | `gauge` | `availability_group_name`, `replica_server`, `db`, `role_desc`, `is_local`, `synchronization_state_desc` | `log_send_queue_size_kb` | query_ref=`mssql_alwayson_replica_db` | Per-replica log_send_queue_size (KB). |
| `mssql_alwayson_replica_db_log_send_rate_kb_s` | `gauge` | `availability_group_name`, `replica_server`, `db`, `role_desc`, `is_local`, `synchronization_state_desc` | `log_send_rate_kb_s` | query_ref=`mssql_alwayson_replica_db` | Per-replica log_send_rate (KB/s). |
| `mssql_alwayson_replica_db_redo_queue_kb` | `gauge` | `availability_group_name`, `replica_server`, `db`, `role_desc`, `is_local`, `synchronization_state_desc` | `redo_queue_size_kb` | query_ref=`mssql_alwayson_replica_db` | Per-replica redo_queue_size (KB). |
| `mssql_alwayson_replica_db_redo_rate_kb_s` | `gauge` | `availability_group_name`, `replica_server`, `db`, `role_desc`, `is_local`, `synchronization_state_desc` | `redo_rate_kb_s` | query_ref=`mssql_alwayson_replica_db` | Per-replica redo_rate (KB/s). |
| `mssql_alwayson_replica_db_secondary_lag_seconds` | `gauge` | `availability_group_name`, `replica_server`, `db`, `role_desc`, `is_local`, `synchronization_state_desc` | `secondary_lag_seconds` | query_ref=`mssql_alwayson_replica_db` | Per-replica secondary_lag_seconds. |
| `mssql_alwayson_replica_db_synchronization_health` | `gauge` | `availability_group_name`, `replica_server`, `db`, `role_desc`, `is_local`, `synchronization_state_desc`, `synchronization_health_desc` | `synchronization_health` | query_ref=`mssql_alwayson_replica_db` | Per-replica DB synchronization_health (0=NOT_HEALTHY,1=PARTIALLY,2=HEALTHY). |
| `mssql_alwayson_replica_db_is_suspended` | `gauge` | `availability_group_name`, `replica_server`, `db`, `role_desc`, `suspend_reason_desc` | `is_suspended` | query_ref=`mssql_alwayson_replica_db` | Per-replica DB is_suspended flag. |
| `mssql_alwayson_replica_connected_state` | `gauge` | `availability_group_name`, `replica_server`, `role_desc`, `availability_mode_desc`, `failover_mode_desc`, `connected_state_desc`, `synchronization_health_desc`, `operational_state_desc` | `connected_state` | query_ref=`mssql_alwayson_replicas` | Replica connected_state (0=DISCONNECTED,1=CONNECTED). |
| `mssql_alwayson_disconnected_seconds` | `gauge` | `availability_group_name`, `replica_server`, `role_desc`, `connected_state_desc` | `disconnected_seconds` | query_ref=`mssql_alwayson_replicas` | Seconds since last connection error when replica is disconnected, else 0. |
| `mssql_alwayson_replica_synchronization_health` | `gauge` | `availability_group_name`, `replica_server`, `role_desc`, `availability_mode_desc`, `failover_mode_desc`, `connected_state_desc`, `synchronization_health_desc`, `operational_state_desc` | `synchronization_health` | query_ref=`mssql_alwayson_replicas` | Replica synchronization_health (0/1/2). |
| `mssql_alwayson_replica_operational_state` | `gauge` | `availability_group_name`, `replica_server`, `role_desc`, `availability_mode_desc`, `failover_mode_desc`, `connected_state_desc`, `synchronization_health_desc`, `operational_state_desc` | `operational_state` | query_ref=`mssql_alwayson_replicas` | Replica operational_state (NULL on remote sometimes; local usually set). |
| `mssql_alwayson_replica_role` | `gauge` | `availability_group_name`, `replica_server`, `role_desc`, `availability_mode_desc`, `failover_mode_desc`, `connected_state_desc`, `synchronization_health_desc`, `operational_state_desc` | `role` | query_ref=`mssql_alwayson_replicas` | Replica role (0=RESOLVING,1=PRIMARY,2=SECONDARY). |
| `mssql_alwayson_group_synchronization_health` | `gauge` | `availability_group_name`, `primary_replica`, `primary_recovery_health_desc`, `synchronization_health_desc` | `synchronization_health` | query_ref=`mssql_alwayson_groups` | AG synchronization_health (0/1/2). |
| `mssql_alwayson_group_primary_recovery_health` | `gauge` | `availability_group_name`, `primary_replica`, `primary_recovery_health_desc`, `synchronization_health_desc` | `primary_recovery_health` | query_ref=`mssql_alwayson_groups` | AG primary_recovery_health. |
| `mssql_alwayson_is_failover_ready` | `gauge` | `availability_group_name`, `replica_server`, `db`, `role_desc`, `is_local`, `synchronization_state_desc` | `is_failover_ready` | query_ref=`mssql_alwayson_replica_db` | 1 if database replica is failover-ready (dm_hadr_database_replica_cluster_states). |
| `mssql_alwayson_synchronization_state` | `gauge` | `availability_group_name`, `replica_server`, `db`, `role_desc`, `is_local`, `synchronization_state_desc` | `synchronization_state` | query_ref=`mssql_alwayson_replica_db` | synchronization_state: 0=NOT SYNCHRONIZING,1=SYNCHRONIZING,2=SYNCHRONIZED,3=REVERTING,4=INITIALIZING. |
| `mssql_alwayson_seeding_transferred_bytes` | `gauge` | `local_database_name`, `remote_machine_name`, `role_desc`, `internal_state_desc` | `transferred_size_bytes` | query_ref=`mssql_alwayson_seeding` | Bytes transferred for active physical seeding. |
| `mssql_alwayson_seeding_database_size_bytes` | `gauge` | `local_database_name`, `remote_machine_name`, `role_desc`, `internal_state_desc` | `database_size_bytes` | query_ref=`mssql_alwayson_seeding` | Total database size bytes for active physical seeding. |
| `mssql_alwayson_seeding_percent` | `gauge` | `local_database_name`, `remote_machine_name`, `role_desc`, `internal_state_desc` | `seeding_percent` | query_ref=`mssql_alwayson_seeding` | Approximate seeding percent complete (transferred/database_size*100). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
