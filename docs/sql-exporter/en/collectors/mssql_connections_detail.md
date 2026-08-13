# mssql_connections_detail

## Summary

- File: `collector/mssql_connections_detail.collector.yml`
- collector_name: `mssql_connections_detail`
- min_interval: `60s`
- metric count: `10`
- shared query_ref values: `mssql_sessions_by_db`, `mssql_sessions_by_host`, `mssql_sessions_by_login`, `mssql_sessions_by_program`, `mssql_sessions_by_status`, `mssql_sessions_idle_long`, `mssql_sessions_idle_bucket`, `mssql_sessions_open_tran`, `mssql_sessions_open_tran_total`

## Purpose

- Client connection breakdown — shared for DWH and OLTP.
- Surfaces who holds sessions (login/program/host/db), running vs sleeping mix, open transactions, and long-idle sleeping (connection-pool waste).
- GRANT VIEW SERVER STATE TO

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Notes from the source file:
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.
- Grafana dashboard: `sqlx-connections` (SQL Exporter - Connections).

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_sessions_by_status` | `gauge` | `status` | `session_count` | User sessions grouped by status. |
| `mssql_sessions_by_login` | `gauge` | `login_name`, `status` | `session_count` | Top logins by session count. |
| `mssql_sessions_by_program` | `gauge` | `program_name`, `status` | `session_count` | Top programs by session count. |
| `mssql_sessions_by_host` | `gauge` | `host_name`, `status` | `session_count` | Top client hosts by session count. |
| `mssql_sessions_by_db` | `gauge` | `db`, `status` | `session_count` | Sessions grouped by database. |
| `mssql_sessions_open_tran_total` | `gauge` | — | `session_count` | User sessions with open_transaction_count > 0. |
| `mssql_sessions_open_tran` | `gauge` | `login_name`, `db` | `session_count` | Top logins/databases with open transactions. |
| `mssql_sessions_idle_bucket` | `gauge` | `idle_bucket` | `session_count` | Sleeping sessions by idle age (`lt_1m`, `1_5m`, `5_30m`, `30_60m`, `1_4h`, `gt_4h`). |
| `mssql_sessions_idle_long` | `gauge` | `login_name`, `program_name`, `host_name` | `session_count` | Top sleeping sessions idle ≥ 5 minutes. |
| `mssql_sessions_idle_long_max_seconds` | `gauge` | `login_name`, `program_name`, `host_name` | `max_idle_seconds` | Max idle seconds among those long-idle groups. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- High **Sleeping** with high **Idle ≥5m/1h** usually points to connection-pool leaks (see Top Logins / Long Idle tables).
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
