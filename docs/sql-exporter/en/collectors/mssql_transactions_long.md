# mssql_transactions_long

## Summary

- File: `collector/mssql_transactions_long.collector.yml`
- collector_name: `mssql_transactions_long`
- min_interval: `30s`
- metric count: `3`
- shared query_ref values: `mssql_active_transactions_counter`, `mssql_long_transaction_count`, `mssql_long_transactions`

## Purpose

- Long-running open transactions.
- GRANT VIEW SERVER STATE TO

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Access to user databases.
- Notes from the source file:
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_long_transaction_seconds` | `gauge` | `session_id`, `db`, `login_name`, `program_name`, `host_name`, `transaction_type`, `transaction_state`, `name` | `open_seconds` | query_ref=`mssql_long_transactions` | Open user transactions older than 30 seconds. |
| `mssql_long_transaction_count` | `gauge` | - | `long_tran_count` | query_ref=`mssql_long_transaction_count` | Count of open user transactions older than 30 seconds. |
| `mssql_active_transactions_per_db` | `gauge` | `db` | `cntr_value` | query_ref=`mssql_active_transactions_counter` | Active transactions counter per database (perf counter). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

