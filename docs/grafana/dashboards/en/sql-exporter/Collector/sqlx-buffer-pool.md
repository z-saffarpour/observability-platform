# Collector buffer_pool

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-buffer-pool.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Buffer pool health: PLE (incl. NUMA), cache hit %, physical page I/O rates, lazy writes / free-list stalls, fleet snapshot, and per-database buffer occupancy. /sec counters use rate([5m]).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-buffer-pool` |
| Source file | [`sqlx-buffer-pool.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-buffer-pool.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `buffer_pool` |
| Panel count | 30 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_buffer_pool_database_pages{job="sql_exporter", instance=~"${instance:regex}"}, db)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Low PLE (<300s) | `stat` |
| 3 | Min PLE | `stat` |
| 4 | Median PLE | `stat` |
| 5 | Cache Hit % | `stat` |
| 6 | Max Page Reads/s | `stat` |
| 7 | Max Page Writes/s | `stat` |
| 8 | Max Lazy Writes/s | `stat` |
| 9 | Servers w/ Stalls | `stat` |
| 10 | PLE & Buffer Cache | `row` |
| 11 | Page Life Expectancy (_Total) | `timeseries` |
| 12 | PLE by NUMA Node | `timeseries` |
| 13 | Buffer Cache Hit Ratio % | `timeseries` |
| 14 | Buffer Pool Size (Database vs Target) | `timeseries` |
| 15 | Physical I/O (rate of cumulative counters) | `row` |
| 16 | Page Reads /s | `timeseries` |
| 17 | Page Writes /s | `timeseries` |
| 18 | Readahead Pages /s | `timeseries` |
| 19 | Page Lookups /s | `timeseries` |
| 20 | Memory Pressure Signals | `row` |
| 21 | Lazy Writes /s | `timeseries` |
| 22 | Free List Stalls /s | `timeseries` |
| 23 | Checkpoint Pages /s | `timeseries` |
| 24 | Fleet Snapshot | `row` |
| 25 | Buffer Pool Health by Server | `table` |
| 26 | Low PLE Servers (< 300s) | `table` |
| 27 | Buffer usage by database | `row` |
| 28 | Cached Size by Database | `table` |
| 29 | Dirty Size by Database | `table` |
| 30 | Buffer Occupancy by Database | `table` |

Panel type summary: `row`: 6, `stat`: 8, `table`: 5, `timeseries`: 11

## Metrics used

- `mssql_buffer_pool_cache_hit_ratio`
- `mssql_buffer_pool_counter`
- `mssql_buffer_pool_database_dirty_pages`
- `mssql_buffer_pool_database_pages`
- `mssql_buffer_pool_page_life_expectancy`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
