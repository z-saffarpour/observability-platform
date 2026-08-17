# mssql_cpu

## Summary

- File: `collector/mssql_cpu.collector.yml`
- collector_name: `mssql_cpu`
- min_interval: `30s`
- metric count: `4`
- shared query_ref values: `mssql_cpu_ring_buffer`, `mssql_cpu_signal_waits`

## Purpose

- SQL Server process CPU vs system idle / other - from ring buffer.
- GRANT VIEW SERVER STATE TO

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Notes from the source file:
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_cpu_sqlserver_process_percent` | `gauge` | - | `sqlserver_process_cpu` | query_ref=`mssql_cpu_ring_buffer` | SQL Server process CPU percent (ring buffer). |
| `mssql_cpu_system_idle_percent` | `gauge` | - | `system_idle_cpu` | query_ref=`mssql_cpu_ring_buffer` | System idle CPU percent (ring buffer). |
| `mssql_cpu_other_process_percent` | `gauge` | - | `other_process_cpu` | query_ref=`mssql_cpu_ring_buffer` | Other process CPU percent (ring buffer). |
| `mssql_cpu_signal_wait_percent` | `gauge` | - | `signal_wait_percent` | query_ref=`mssql_cpu_signal_waits` | Signal wait percent of non-benign waits (CPU pressure indicator; benign idle waits excluded). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

