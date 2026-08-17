# mssql_service_broker

- File: `collector/mssql_service_broker.collector.yml`
- `collector_name`: `mssql_service_broker`
- `min_interval`: `30s`
- Metric count: `65`
- Profile: `profiles/service-broker.yml`

Monitors Service Broker enablement and metadata, queue configuration/backlog/activation, transmission backlog (aggregate and per destination service), conversation endpoints and lifetime, broker endpoint/transport, network connections, message forwarding, Broker Activation/Statistics/Transport performance counters, and certificate expiry. Safe when Service Broker is absent: database/queue queries skip or catch errors; optional DMVs return empty sets.

## Metric groups

| Group | Examples |
| --- | --- |
| Database | `enabled`, `accessible`, `queues`, `services`, `honor_broker_priority`, `info{broker_guid}`, `routes`, `remote_bindings`, conversation groups / orphaned |
| Queue | receive/enqueue/activation/retention/poison flags, `max_readers`, activation procedure configured, messages, monitor state, tasks waiting, activated tasks, last activation age, oldest message age |
| Transmission | messages/errors/conversation errors/bytes/oldest age; per-`to_service` + `status_class` breakdown |
| Conversation | endpoints by `state` + `is_initiator`, min lifetime remaining |
| Endpoint | started, forwarding, forwarding size, encryption, port |
| Connections | count + flow control + byte/fragment counters by connection/login state |
| Forwarding | in-flight count, min hops remaining, max time consumed; pending/discarded from Broker Statistics |
| Perf counters | activation tasks/limit/aborts; enqueued/dequeued transmission; SQL SEND/RECEIVE; transport fragment send/receive |
| Certificates | days to expiry for endpoint and user-DB certificates with private keys |

## Permissions

- `VIEW ANY DATABASE`
- `CONNECT` and `VIEW DATABASE STATE` on each Service Broker database
- `VIEW SERVER STATE` (SQL Server 2019 and older) or `VIEW SERVER PERFORMANCE STATE` (SQL Server 2022+) for broker DMVs and performance counters
- SQL Server 2022+: `VIEW DATABASE PERFORMANCE STATE` where applicable

The repository's `Create-SqlExporterLogin.sql` already grants these permissions when user-database access is enabled.

## Suggested alerts

```promql
mssql_service_broker_enabled == 1 and mssql_service_broker_database_accessible == 0
mssql_service_broker_queue_receive_enabled == 0
mssql_service_broker_queue_oldest_message_age_seconds > 300
mssql_service_broker_transmission_errors > 0
mssql_service_broker_transmission_oldest_age_seconds > 300
mssql_service_broker_queue_messages > 1000
mssql_service_broker_conversation_endpoints{state=~"ERROR|DISCONNECTED_.*"} > 0
mssql_service_broker_endpoint_started == 0
mssql_service_broker_connection_send_flow_controlled > 0
or mssql_service_broker_connection_receive_flow_controlled > 0
increase(mssql_service_broker_activation_task_limit_reached_total[15m]) > 0
increase(mssql_service_broker_forwarded_discarded_total[15m]) > 0
mssql_service_broker_certificate_expiry_days < 30
```

Tune backlog and age thresholds to the application's normal message rate. `queue_messages` can include retained messages when `queue_retention_enabled == 1`.
