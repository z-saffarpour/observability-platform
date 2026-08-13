# Collector index_usage

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-index-usage.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Index usage ops view: hot indexes (reads/seeks/scans/lookups), scan & write ratios, unused/write-heavy drop candidates, and per-DB rollup. Stats reset on restart. Not fragmentation.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-index-usage` |
| Source file | [`sqlx-index-usage.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-index-usage.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `indexes` |
| Panel count | 34 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_index_usage_reads{job="sql_exporter", instance=~"$instance"}, db)` |
| `candidate_kind` | Candidate | `custom` | `unused,write_heavy` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Servers | `stat` |
| 3 | DBs Tracked | `stat` |
| 4 | Hot Indexes | `stat` |
| 5 | Unused Indexes | `stat` |
| 6 | Stale Candidates | `stat` |
| 7 | Max Scan % | `stat` |
| 8 | Total Reads | `stat` |
| 9 | Total Updates | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top Indexes by Reads | `bargauge` |
| 12 | Top Indexes by Scan Ratio | `bargauge` |
| 13 | Top DBs by Unused Indexes | `bargauge` |
| 14 | Top Stale by Updates | `bargauge` |
| 15 | Trends | `row` |
| 16 | DB Reads (rollup) | `timeseries` |
| 17 | DB Updates (rollup) | `timeseries` |
| 18 | DB Scan Ratio | `timeseries` |
| 19 | DB Unused Index Count | `timeseries` |
| 20 | Top Hot Index Reads | `timeseries` |
| 21 | Top Hot Index Updates | `timeseries` |
| 22 | Hot Index Inventory (TOP by reads) | `row` |
| 23 | Hot indexes - seeks / scans / lookups / updates / ratios | `table` |
| 24 | Drop / Disable Review Candidates | `row` |
| 25 | Unused (reads=0) or write-heavy (updates >= 10x reads) nonclustered indexes | `table` |
| 26 | Stale Candidate Updates Trend | `timeseries` |
| 27 | Stale Write/Read Ratio Trend | `timeseries` |
| 28 | Per-Database Usage Rollup | `row` |
| 29 | Database rollup - activity + unused nonclustered count | `table` |
| 30 | Access Pattern Detail (seeks / scans / lookups) | `row` |
| 31 | Seeks | `timeseries` |
| 32 | Scans | `timeseries` |
| 33 | Lookups | `timeseries` |
| 34 | Updates (hot set) | `timeseries` |

Panel type summary: `bargauge`: 4, `row`: 7, `stat`: 8, `table`: 3, `timeseries`: 12

## Metrics used

- `mssql_index_usage_db_lookups`
- `mssql_index_usage_db_reads`
- `mssql_index_usage_db_scan_ratio`
- `mssql_index_usage_db_scans`
- `mssql_index_usage_db_seeks`
- `mssql_index_usage_db_tracked_indexes`
- `mssql_index_usage_db_unused_indexes`
- `mssql_index_usage_db_updates`
- `mssql_index_usage_lookup_ratio`
- `mssql_index_usage_lookups`
- `mssql_index_usage_reads`
- `mssql_index_usage_scan_ratio`
- `mssql_index_usage_scans`
- `mssql_index_usage_seeks`
- `mssql_index_usage_stale_reads`
- `mssql_index_usage_stale_updates`
- `mssql_index_usage_stale_write_read_ratio`
- `mssql_index_usage_updates`
- `mssql_index_usage_write_read_ratio`
- `mssql_up`
- `write_heavy`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
