# Collector resource_governor

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-resource-governor.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Resource Governor ops view: enablement, reconfiguration pending, pool CPU/memory caps, memgrant waiters/timeouts/OOM, workload-group queueing and CPU-limit violations. Collector: mssql_resource_governor (60s).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-resource-governor` |
| Source file | [`sqlx-resource-governor.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-resource-governor.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `resource_governor`, `memory`, `cpu` |
| Panel count | 29 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_resource_governor_enabled{job="sql_exporter"}, instance)` |
| `pool` | Pool | `query` | `label_values(mssql_resource_governor_pool_max_cpu_percent{job="sql_exporter", instance=~"$instance"}, pool)` |
| `workload_group` | Workload Group | `query` | `label_values(mssql_resource_governor_group_active_requests{job="sql_exporter", instance=~"$instance", pool=~"$pool"}, workload_group)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | RG Enabled | `stat` |
| 3 | Reconfig Pending | `stat` |
| 4 | Memgrant Waiters | `stat` |
| 5 | Queued Requests | `stat` |
| 6 | Timeouts 10m | `stat` |
| 7 | OOM 10m | `stat` |
| 8 | CPU Limit Hits 10m | `stat` |
| 9 | Active Requests | `stat` |
| 10 | Pressure Hotspots | `row` |
| 11 | Pool Memory Pressure | `table` |
| 12 | Workload Group Queue / CPU Limit Pressure | `table` |
| 13 | Fleet Resource Governor Status | `table` |
| 14 | Resource Pools | `row` |
| 15 | Pool Configuration (CPU / Memory %) | `table` |
| 16 | Pool Runtime Snapshot | `table` |
| 17 | Workload Groups | `row` |
| 18 | Workload Group Configuration | `table` |
| 19 | Workload Group Runtime Snapshot | `table` |
| 20 | Trends | `row` |
| 21 | Pool Memgrant Waiters | `timeseries` |
| 22 | Group Queued Requests | `timeseries` |
| 23 | Pool CPU Usage (s/s) | `timeseries` |
| 24 | Group CPU Usage (s/s) | `timeseries` |
| 25 | Pool Used Memgrant | `timeseries` |
| 26 | Pool Max Workspace Memory | `timeseries` |
| 27 | Memgrant Timeouts /s | `timeseries` |
| 28 | Out of Memory /s | `timeseries` |
| 29 | CPU Limit Violations /s | `timeseries` |

Panel type summary: `row`: 5, `stat`: 8, `table`: 7, `timeseries`: 9

## Metrics used

- `mssql_resource_governor_enabled`
- `mssql_resource_governor_group_active_requests`
- `mssql_resource_governor_group_cpu_limit_violations_total`
- `mssql_resource_governor_group_cpu_usage_ms_total`
- `mssql_resource_governor_group_max_dop`
- `mssql_resource_governor_group_max_requests`
- `mssql_resource_governor_group_queued_requests`
- `mssql_resource_governor_group_queued_requests_total`
- `mssql_resource_governor_group_request_max_cpu_seconds`
- `mssql_resource_governor_group_request_max_memory_percent`
- `mssql_resource_governor_group_requests_total`
- `mssql_resource_governor_pool_active_memgrant_count`
- `mssql_resource_governor_pool_active_memgrant_kb`
- `mssql_resource_governor_pool_cache_memory_kb`
- `mssql_resource_governor_pool_compile_memory_kb`
- `mssql_resource_governor_pool_cpu_usage_ms_total`
- `mssql_resource_governor_pool_max_cpu_percent`
- `mssql_resource_governor_pool_max_memory_kb`
- `mssql_resource_governor_pool_max_memory_percent`
- `mssql_resource_governor_pool_memgrant_timeouts_total`
- `mssql_resource_governor_pool_memgrant_waiter_count`
- `mssql_resource_governor_pool_min_cpu_percent`
- `mssql_resource_governor_pool_min_memory_percent`
- `mssql_resource_governor_pool_out_of_memory_total`
- `mssql_resource_governor_pool_used_memgrant_kb`
- `mssql_resource_governor_reconfiguration_pending`
- `mssql_resource_governor_workload_group_info`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
