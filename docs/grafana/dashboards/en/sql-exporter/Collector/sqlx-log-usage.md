# Collector log_usage

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-log-usage.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Transaction log ops view: used%/MB pressure, reuse-wait root cause, FULL+LOG_BACKUP action queue, growth companion metrics, per-server rollup. Collector mssql_log_usage @ 60s.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-log-usage` |
| Source file | [`sqlx-log-usage.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-log-usage.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `log`, `tlog` |
| Panel count | 30 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_log_used_percent{job="sql_exporter", instance=~"$instance"}, db)` |
| `reuse_wait` | Reuse Wait | `query` | `label_values(mssql_log_used_percent{job="sql_exporter", instance=~"$instance", db=~"$db"}, log_reuse_wait_desc)` |
| `warn_pct` | Warn % | `custom` | `60,70,80,85,90` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | DBs >= Warn% | `stat` |
| 3 | DBs >= 85% | `stat` |
| 4 | DBs >= 95% | `stat` |
| 5 | Max Used % | `stat` |
| 6 | Reuse Blocked | `stat` |
| 7 | Wait LOG_BACKUP | `stat` |
| 8 | Wait ACTIVE_TXN | `stat` |
| 9 | Total Log Size | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top 15 DBs by Used % | `bargauge` |
| 12 | Top 15 DBs by Used MB | `bargauge` |
| 13 | Servers - DBs >= 85% | `bargauge` |
| 14 | Reuse Wait Reasons (count) | `bargauge` |
| 15 | FULL recovery >= Warn% | `bargauge` |
| 16 | Pressure / Action Queue | `row` |
| 17 | High Used % (>= Warn) - size + recovery + reuse wait | `table` |
| 18 | Reuse Blocked (wait != NOTHING) - why log cannot truncate | `table` |
| 19 | Inventory (topk 40 by Used %) - filtered by Server/DB/Wait | `table` |
| 20 | Trends (topk - avoids 600+ series) | `row` |
| 21 | Used % - Top 15 | `timeseries` |
| 22 | Used MB - Top 15 | `timeseries` |
| 23 | Total MB - Top 15 (growth / autogrow signal) | `timeseries` |
| 24 | Free MB - Lowest 15 | `timeseries` |
| 25 | Log Growth (from mssql_standard - companion) | `row` |
| 26 | Log Growths rate - Top 15 | `timeseries` |
| 27 | Log Growths rate now - Top 15 | `bargauge` |
| 28 | Growing logs (rate > 0) | `table` |
| 29 | Per-Server Rollup | `row` |
| 30 | Servers - pressure / size / reuse blocked | `table` |

Panel type summary: `bargauge`: 6, `row`: 6, `stat`: 8, `table`: 5, `timeseries`: 5

## Metrics used

- `mssql_log_growths`
- `mssql_log_total_mb`
- `mssql_log_used_mb`
- `mssql_log_used_percent`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
