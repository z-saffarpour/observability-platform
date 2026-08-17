# Collector tempdb

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-tempdb.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

tempdb ops view (HQ-tuned thresholds): Used% warn~p90, Spill warn~p95. KPI/hotspots/fleet/sessions/files. Collector mssql_tempdb @ 60s.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-tempdb` |
| Source file | [`sqlx-tempdb.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-tempdb.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `tempdb` |
| Panel count | 40 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `usage` | Usage | `query` | `label_values(mssql_tempdb_space_used_mb{job="sql_exporter", instance=~"$instance"}, usage)` |
| `warn_pct` | Warn % | `custom` | `10,15,20,25,30,40` |
| `spill_warn_mb` | Spill Warn MB | `custom` | `1,2,8,16,64,256` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Servers >= Warn% | `stat` |
| 3 | Max Used % | `stat` |
| 4 | Waiting Tasks | `stat` |
| 5 | Metadata Contention | `stat` |
| 6 | Max Spill Proxy | `stat` |
| 7 | Max Version Store | `stat` |
| 8 | Max User Objects | `stat` |
| 9 | Max Internal Objects | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top 15 by Used % | `bargauge` |
| 12 | Top 15 by Used MB | `bargauge` |
| 13 | Top 15 by Version Store | `bargauge` |
| 14 | Top 15 Spill Proxy (sort/hash) | `bargauge` |
| 15 | Top 15 Waiting Tasks | `bargauge` |
| 16 | Top 15 Free MB (lowest pressure first) | `bargauge` |
| 17 | Fleet Pressure / Action Queue | `row` |
| 18 | Servers - size / used% / composition / waits / spill | `table` |
| 19 | Hot only (>= Warn% OR waits OR contention OR spill) | `table` |
| 20 | Top Sessions (who is consuming tempdb) | `row` |
| 21 | Top sessions by tempdb used MB | `table` |
| 22 | Top 15 sessions - used MB trend | `timeseries` |
| 23 | Files (data/log) - topk only | `row` |
| 24 | Largest tempdb files (topk 40 by size) | `table` |
| 25 | Data file count per server | `bargauge` |
| 26 | ROWS used % (data files only) | `bargauge` |
| 27 | Trends (topk / aggregated) | `row` |
| 28 | Used % - Top 15 | `timeseries` |
| 29 | Used MB - Top 15 | `timeseries` |
| 30 | Space by category - Top 20 series | `timeseries` |
| 31 | Version Store MB - Top 15 | `timeseries` |
| 32 | User Objects MB - Top 15 | `timeseries` |
| 33 | Internal Objects MB - Top 15 | `timeseries` |
| 34 | Waiting Tasks - Top 15 | `timeseries` |
| 35 | Metadata Contention - Top 15 | `timeseries` |
| 36 | Spill Proxy MB - Top 15 | `timeseries` |
| 37 | Free MB - Lowest 15 | `timeseries` |
| 38 | Version Store Rates (optional DMV - may be empty) | `row` |
| 39 | Version Generation Rate | `timeseries` |
| 40 | Version Cleanup Rate | `timeseries` |

Panel type summary: `bargauge`: 8, `row`: 7, `stat`: 8, `table`: 4, `timeseries`: 13

## Metrics used

- `mssql_tempdb_file_free_mb`
- `mssql_tempdb_file_size_mb`
- `mssql_tempdb_file_used_mb`
- `mssql_tempdb_internal_object_mb`
- `mssql_tempdb_metadata_contention_count`
- `mssql_tempdb_session_used_mb`
- `mssql_tempdb_space_used_mb`
- `mssql_tempdb_spill_writes_mb`
- `mssql_tempdb_user_object_mb`
- `mssql_tempdb_version_cleanup_rate_mb_s`
- `mssql_tempdb_version_generation_rate_mb_s`
- `mssql_tempdb_waiting_tasks_count`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
