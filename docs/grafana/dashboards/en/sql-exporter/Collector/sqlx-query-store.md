# Collector query_store

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-query-store.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Query Store ops view: QS enablement, fleet rollup, last_execution_time per query_id, and top queries by avg duration / CPU / executions (6h QS window, 300s scrape). Collector: mssql_query_store.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-query-store` |
| Source file | [`sqlx-query-store.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-query-store.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `query_store` |
| Panel count | 31 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_query_store_enabled{job="sql_exporter", instance=~"${instance:regex}"}, db)` |
| `over_avg_factor` | Over Avg x | `custom` | `1.2,1.5,2,3` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI (Query Store - last 6h window) | `row` |
| 2 | User databases with Query Store ON. | `stat` |
| 3 | QS Disabled DBs | `stat` |
| 4 | Tracked Queries | `stat` |
| 5 | Worst average duration among tracked queries. | `stat` |
| 6 | Worst average CPU among tracked queries. | `stat` |
| 7 | Sum of execution counts in the QS window. | `stat` |
| 8 | Newest Last Exec | `stat` |
| 9 | Oldest Last Exec | `stat` |
| 10 | Hotspots (right now) | `row` |
| 11 | Top DBs - Max Avg Duration | `bargauge` |
| 12 | Top Queries - Oldest Last Exec | `bargauge` |
| 13 | Top Objects - Avg Duration | `bargauge` |
| 14 | Trends (aggregated - safe for 300s scrape) | `row` |
| 15 | Max Avg Duration by Server | `timeseries` |
| 16 | Max Avg CPU by Server | `timeseries` |
| 17 | Oldest Last Exec Age by Server | `timeseries` |
| 18 | Newest Last Exec Age by Server | `timeseries` |
| 19 | Fleet rollup | `row` |
| 20 | Servers - QS coverage / hotspots / last exec age | `table` |
| 21 | Query Store enablement | `row` |
| 22 | All User Databases - QS Status | `table` |
| 23 | QS Disabled - Action List | `table` |
| 24 | Top queries - investigate (last 6h QS window) | `row` |
| 25 | Top Queries - Duration / CPU / Exec / Last Executed / Age / Statement | `table` |
| 26 | Ranked views | `row` |
| 27 | Top by Avg Duration | `table` |
| 28 | Top by Avg CPU | `table` |
| 29 | Top by Executions | `table` |
| 30 | Regressions vs fleet average | `row` |
| 31 | Queries Slower than Fleet Avg x Factor | `table` |

Panel type summary: `bargauge`: 3, `row`: 8, `stat`: 8, `table`: 8, `timeseries`: 4

## Metrics used

- `mssql_query_store_enabled`
- `mssql_query_store_top_cpu_ms`
- `mssql_query_store_top_duration_ms`
- `mssql_query_store_top_execution_count`
- `mssql_query_store_top_last_execution_age_seconds`
- `mssql_query_store_top_last_execution_unix`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
