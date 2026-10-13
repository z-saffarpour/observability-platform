# mssql_deadlock_details

## Summary

- File: `collector/mssql_deadlock_details.collector.yml`
- collector_name: `mssql_deadlock_details`
- min_interval: `60s`
- metric count: `2`
- shared query_ref values: `mssql_deadlock_pairs`

## Purpose

- Recent deadlock victim ↔ other process pairs from the `system_health` ring buffer (`xml_deadlock_report`).
- Complements the instance counter `mssql_deadlocks` in `mssql_standard` with forensic labels (spid/login/host/program/db/statement_snip/`process_count`).
- The ring buffer is searched as text; only the last five event fragments are cast to XML so scrapes stay inside the deadline on busy instances.

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE`.
- Notes from the source file:
  - `GRANT VIEW SERVER STATE TO`
- Requires the default `system_health` Extended Events session with a `ring_buffer` target.
- Portal / refresh-data reads `mssql_deadlock_pair_info` from Prometheus (no direct SQL).

## How to use

- Enable this collector in the profile that matches the server type (OLTP / DWH / alert packs).
- Use `rate(mssql_deadlocks[5m])` or `increase(mssql_deadlocks[1h])` for volume; use these series for the latest pairs.
- Prefer PromQL / dashboard filters on `victim_db` / `other_db`. Do not exclude read-only databases at scrape time (a deadlock can span RO and writable databases).
- `process_count` is a label (graph size). Statement snippets are capped at 120 characters (same idea as `mssql_blocking` / `mssql_locks`).

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_deadlock_pair_info` | `gauge` | `event_time`, `victim_spid`, `victim_login`, `victim_host`, `victim_program`, `victim_db`, `victim_statement_snip`, `other_spid`, `other_login`, `other_host`, `other_program`, `other_db`, `other_statement_snip`, `process_count` | `static_value=1` | query_ref=`mssql_deadlock_pairs` | 1 for a recent xml_deadlock_report pair (victim vs other) from system_health. |
| `mssql_deadlock_pair_age_seconds` | `gauge` | `event_time`, `victim_spid`, `victim_login`, `victim_host`, `victim_program`, `victim_db`, `victim_statement_snip`, `other_spid`, `other_login`, `other_host`, `other_program`, `other_db`, `other_statement_snip`, `process_count` | `age_seconds` | query_ref=`mssql_deadlock_pairs` | Seconds since the xml_deadlock_report timestamp (UTC); `-1` if unknown. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- Both metrics share one `query_ref` (`mssql_deadlock_pairs`).
- Many labels (including statement snippets, `event_time`, and `process_count`) mean higher cardinality; keep the TOP(5) bound and avoid long retention of unused series.
- If `system_health` / ring_buffer is missing, the output is empty and scrape should not fail.
- When more than two processes appear in the graph, labels expose one victim and one non-victim process; `process_count` still reflects the full graph size.
