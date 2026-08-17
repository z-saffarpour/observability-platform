# Collector index_fragmentation

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-index-fragmentation.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Index fragmentation ops view: KPI, rebuild/reorganize action queue, impact-ranked hotspots, and DB inventory. Collector samples LIMITED mode for large indexes (>=10k pages, >=30% frag) about every 6h.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-index-fragmentation` |
| Source file | [`sqlx-index-fragmentation.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-index-fragmentation.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `indexes`, `maintenance` |
| Panel count | 23 |
| Refresh interval | `30m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_index_fragmentation_percent{job="sql_exporter", instance=~"$instance"}, db)` |
| `index_type` | Index Type | `query` | `label_values(mssql_index_fragmentation_percent{job="sql_exporter", instance=~"$instance"}, index_type_desc)` |
| `min_frag` | Min Frag % | `custom` | `30,50,70` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Fragmented Indexes | `stat` |
| 3 | Servers Affected | `stat` |
| 4 | Databases Affected | `stat` |
| 5 | Max Frag % | `stat` |
| 6 | Rebuild >=70% | `stat` |
| 7 | Reorg 30-70% | `stat` |
| 8 | Total Size | `stat` |
| 9 | Worst Impact | `stat` |
| 10 | Action Queue (maintenance candidates) | `row` |
| 11 | Priority list - sort by Impact (Frag% x Pages); REBUILD when Frag >=70, else REORGANIZE | `table` |
| 12 | Hotspots | `row` |
| 13 | Top by Fragmentation % | `bargauge` |
| 14 | Top by Impact (Frag% x Pages) | `bargauge` |
| 15 | Top by Index Size (MB) | `bargauge` |
| 16 | Indexes by Type | `bargauge` |
| 17 | Trends (collector samples ~every 6h) | `row` |
| 18 | Max Fragmentation % by Server | `timeseries` |
| 19 | Fragmented Index Count by Server | `timeseries` |
| 20 | Top Indexes - Fragmentation % | `timeseries` |
| 21 | Top Indexes - Size (MB) | `timeseries` |
| 22 | Database Inventory | `row` |
| 23 | Per-database fragmentation summary | `table` |

Panel type summary: `bargauge`: 4, `row`: 5, `stat`: 8, `table`: 2, `timeseries`: 4

## Metrics used

- `mssql_index_fragmentation_page_count`
- `mssql_index_fragmentation_percent`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
