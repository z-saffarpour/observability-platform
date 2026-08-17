# mssql_alwayson_events

## Summary

- File: `collector/mssql_alwayson_events.collector.yml`
- collector_name: `mssql_alwayson_events`
- min_interval: `300s`
- metric count: `1`
- shared query_ref values: `mssql_alwayson_sync_state_flaps`
- Profiles: `oltp`, `dwh`, `restore-secondary`, `replication` (alongside `mssql_alwayson`)

## Purpose

- Replica state-change flaps from the built-in `AlwaysOn_health` Extended Events session.
- Separated from `mssql_alwayson` (30s) so XEL file reads stay on a longer interval.
- Empty when the instance has no Availability Groups.

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE`.
- Requires the `AlwaysOn_health` session with an `event_file` target (default on AG-capable instances).

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_alwayson_sync_state_flaps_24h` | `gauge` | `availability_group_name`, `replica_server`, `role_desc` | `sync_state_flaps_24h` | query_ref=`mssql_alwayson_sync_state_flaps` | Count of `availability_replica_state_change` events in AlwaysOn_health over 24h. `-1` = AlwaysOn_health unavailable. |

## Operational notes

- Ensure `AlwaysOn_health` is running (`STARTUP_STATE = ON`) so flaps are not stuck at `-1`.
- Use together with `mssql_alwayson` for live lag/health plus historical flap counts.
