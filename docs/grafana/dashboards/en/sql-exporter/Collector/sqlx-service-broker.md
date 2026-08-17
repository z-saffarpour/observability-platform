# Collector service-broker

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-service-broker.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Service Broker ops view: database enablement, queue backlog/activation/poison, transmission by service, conversations, endpoint/transport connections, activation counters, forwarding and certificate expiry. Collector: mssql_service_broker. Empty panels usually mean Service Broker is disabled or the profile is not scraped yet.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-service-broker` |
| Source file | [`sqlx-service-broker.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-service-broker.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `service-broker` |
| Panel count | 60 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_service_broker_queue_messages{job="sql_exporter", instance=~"$instance"}, db)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Broker DBs On | `stat` |
| 3 | Meta Inaccessible | `stat` |
| 4 | Receive Disabled | `stat` |
| 5 | Queue Backlog | `stat` |
| 6 | TX Errors | `stat` |
| 7 | Oldest TX Age | `stat` |
| 8 | Conv ERROR/DISC | `stat` |
| 9 | Endpoint Down | `stat` |
| 10 | Databases | `row` |
| 11 | Broker databases (enabled / inventory) | `table` |
| 12 | Broker DBs inferred from queues / transmission (works now) | `table` |
| 13 | Queue Backlog by Database | `timeseries` |
| 14 | Transmission by Database | `timeseries` |
| 15 | Queues / Activation | `row` |
| 16 | Top Queue Backlog | `bargauge` |
| 17 | Oldest Queue Message Age | `bargauge` |
| 18 | Queue detail (config + backlog + monitor) | `table` |
| 19 | Queue Backlog Trend | `timeseries` |
| 20 | Tasks Waiting / Activated | `timeseries` |
| 21 | Transmission Queue | `row` |
| 22 | TX Messages | `stat` |
| 23 | TX Bytes | `stat` |
| 24 | Conv Errors (TX) | `stat` |
| 25 | TX Error Rows | `stat` |
| 26 | Max TX Age | `stat` |
| 27 | Services w/ Errors | `stat` |
| 28 | Transmission Messages | `timeseries` |
| 29 | Transmission Errors | `timeseries` |
| 30 | Transmission by destination service | `table` |
| 31 | Top TX by Service | `bargauge` |
| 32 | Oldest TX by Service | `bargauge` |
| 33 | Conversations | `row` |
| 34 | Endpoints by State | `timeseries` |
| 35 | ERROR / DISCONNECTED | `bargauge` |
| 36 | Conversation endpoints by state / role | `table` |
| 37 | Endpoint / Connections / Transport | `row` |
| 38 | Service Broker endpoints | `table` |
| 39 | Broker network connections | `table` |
| 40 | Bytes Sent/Received rate | `timeseries` |
| 41 | Fragment Send/Receive | `timeseries` |
| 42 | Activation / Broker Statistics | `row` |
| 43 | Activation Tasks Running | `timeseries` |
| 44 | Task Limit Reached (rate) | `timeseries` |
| 45 | Tasks Aborted | `timeseries` |
| 46 | Enqueued / Dequeued TX Msgs | `timeseries` |
| 47 | SQL SEND / RECEIVE rate | `timeseries` |
| 48 | SQL RECEIVE rate | `timeseries` |
| 49 | Forwarding | `row` |
| 50 | Forwarded In-flight | `stat` |
| 51 | Pending (perf) | `stat` |
| 52 | Pending Bytes | `stat` |
| 53 | Min Hops Left | `stat` |
| 54 | Max Time Consumed | `stat` |
| 55 | Discarded rate | `stat` |
| 56 | Forwarded Messages Total rate | `timeseries` |
| 57 | Forwarded Discarded rate | `timeseries` |
| 58 | Certificates | `row` |
| 59 | Days to Certificate Expiry | `bargauge` |
| 60 | Certificate expiry | `table` |

Panel type summary: `bargauge`: 6, `row`: 9, `stat`: 20, `table`: 8, `timeseries`: 17

## Metrics used

- `mssql_service_broker_activation_task_limit_reached_total`
- `mssql_service_broker_activation_tasks_aborted`
- `mssql_service_broker_activation_tasks_running`
- `mssql_service_broker_certificate_expiry_days`
- `mssql_service_broker_connection_bytes_sent_total`
- `mssql_service_broker_connection_receive_flow_controlled`
- `mssql_service_broker_connection_send_flow_controlled`
- `mssql_service_broker_connections`
- `mssql_service_broker_conversation_endpoints`
- `mssql_service_broker_conversation_lifetime_remaining_seconds`
- `mssql_service_broker_database_accessible`
- `mssql_service_broker_enabled`
- `mssql_service_broker_endpoint_encryption_enabled`
- `mssql_service_broker_endpoint_forwarding_enabled`
- `mssql_service_broker_endpoint_forwarding_size_mb`
- `mssql_service_broker_endpoint_port`
- `mssql_service_broker_endpoint_started`
- `mssql_service_broker_enqueued_transmission_msgs`
- `mssql_service_broker_forwarded_discarded_total`
- `mssql_service_broker_forwarded_max_time_consumed`
- `mssql_service_broker_forwarded_messages`
- `mssql_service_broker_forwarded_messages_total`
- `mssql_service_broker_forwarded_min_hops_remaining`
- `mssql_service_broker_forwarded_pending_bytes`
- `mssql_service_broker_forwarded_pending_messages`
- `mssql_service_broker_honor_broker_priority`
- `mssql_service_broker_queue_activated_tasks`
- `mssql_service_broker_queue_activation_enabled`
- `mssql_service_broker_queue_enqueue_enabled`
- `mssql_service_broker_queue_last_activation_age_seconds`
- `mssql_service_broker_queue_max_readers`
- `mssql_service_broker_queue_messages`
- `mssql_service_broker_queue_monitor_state`
- `mssql_service_broker_queue_oldest_message_age_seconds`
- `mssql_service_broker_queue_poison_handling_enabled`
- `mssql_service_broker_queue_receive_enabled`
- `mssql_service_broker_queue_retention_enabled`
- `mssql_service_broker_queue_tasks_waiting`
- `mssql_service_broker_queues`
- `mssql_service_broker_remote_bindings`
- `mssql_service_broker_routes`
- `mssql_service_broker_services`
- `mssql_service_broker_sql_receives_total`
- `mssql_service_broker_sql_sends_total`
- `mssql_service_broker_transmission_by_service`
- `mssql_service_broker_transmission_bytes`
- `mssql_service_broker_transmission_bytes_by_service`
- `mssql_service_broker_transmission_conversation_errors`
- `mssql_service_broker_transmission_errors`
- `mssql_service_broker_transmission_messages`
- `mssql_service_broker_transmission_oldest_age_by_service`
- `mssql_service_broker_transmission_oldest_age_seconds`
- `mssql_service_broker_transport_fragment_sends`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
