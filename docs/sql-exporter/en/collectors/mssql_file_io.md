# mssql_file_io

## Summary

- File: `collector/mssql_file_io.collector.yml`
- collector_name: `mssql_file_io`
- min_interval: `180s`
- metric count: `16`
- shared query_ref values: `mssql_file_io_latency_p95`, `mssql_file_io_pending`, `mssql_file_io_stats`, `mssql_volume_space`

## Purpose

- Per-file I/O latency metrics for Microsoft SQL Server.
- It is required that the SQL Server user has the following permissions:
- GRANT VIEW SERVER STATE TO
- GRANT VIEW ANY DEFINITION TO
- Auto-loaded via collectors: [mssql_*] and collector_files: ["collector/*.collector.yml"]

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Notes from the source file:
  - It is required that the SQL Server user has the following permissions:
  - GRANT VIEW SERVER STATE TO
  - GRANT VIEW ANY DEFINITION TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_file_io_stall_read_ms` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `io_stall_read_ms` | query_ref=`mssql_file_io_stats` | Cumulative IO stall read time (ms) per database file. |
| `mssql_file_io_stall_write_ms` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `io_stall_write_ms` | query_ref=`mssql_file_io_stats` | Cumulative IO stall write time (ms) per database file. |
| `mssql_file_io_stall_ms` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `io_stall_ms` | query_ref=`mssql_file_io_stats` | Cumulative IO stall total time (ms) per database file. |
| `mssql_file_io_num_of_reads` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `num_of_reads` | query_ref=`mssql_file_io_stats` | Cumulative number of reads per database file. |
| `mssql_file_io_num_of_writes` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `num_of_writes` | query_ref=`mssql_file_io_stats` | Cumulative number of writes per database file. |
| `mssql_file_io_read_bytes` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `num_of_bytes_read` | query_ref=`mssql_file_io_stats` | Cumulative bytes read per database file. |
| `mssql_file_io_write_bytes` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `num_of_bytes_written` | query_ref=`mssql_file_io_stats` | Cumulative bytes written per database file. |
| `mssql_file_io_avg_read_latency_ms` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `avg_read_latency_ms` | query_ref=`mssql_file_io_stats` | Lifetime average since SQL startup (stall/ops); prefer rate(stall)/rate(ops) for interval latency. |
| `mssql_file_io_avg_write_latency_ms` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `avg_write_latency_ms` | query_ref=`mssql_file_io_stats` | Lifetime average since SQL startup (stall/ops); prefer rate(stall)/rate(ops) for interval latency. |
| `mssql_volume_total_bytes` | `gauge` | `volume_mount_point` | `total_bytes` | query_ref=`mssql_volume_space` | Volume total bytes for SQL data/log mounts. |
| `mssql_volume_available_bytes` | `gauge` | `volume_mount_point` | `available_bytes` | query_ref=`mssql_volume_space` | Volume available bytes for SQL data/log mounts. |
| `mssql_volume_used_percent` | `gauge` | `volume_mount_point` | `used_percent` | query_ref=`mssql_volume_space` | Volume used percent for SQL data/log mounts. |
| `mssql_file_io_pending_requests` | `gauge` | - | `pending_requests` | query_ref=`mssql_file_io_pending` | Current number of pending IO requests. |
| `mssql_file_io_pending_wait_ms` | `gauge` | - | `pending_wait_ms` | query_ref=`mssql_file_io_pending` | Sum of io_pending_ms_ticks for currently pending IO requests (wait time, not bytes). |
| `mssql_file_io_read_latency_p95_ms` | `gauge` | - | `read_latency_p95_ms` | query_ref=`mssql_file_io_latency_p95` | 95th percentile of per-file average read latency (ms). |
| `mssql_file_io_write_latency_p95_ms` | `gauge` | - | `write_latency_p95_ms` | query_ref=`mssql_file_io_latency_p95` | 95th percentile of per-file average write latency (ms). |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

