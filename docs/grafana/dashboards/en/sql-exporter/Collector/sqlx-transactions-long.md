# Collector transactions_long

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-transactions-long.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Long-open user transactions (>=30s): fleet KPIs, age trends, session detail (login/program/host/status), and breakdowns. Cross-link Blocking / Locks when victims appear. Collector: mssql_transactions_long (30s). Alert: SqlLongTransaction at 15m.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-transactions-long` |
| Source file | [`sqlx-transactions-long.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-transactions-long.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `transactions` |
| Panel count | 26 |
| Refresh interval | `30s` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_active_transactions_per_db{job="sql_exporter", instance=~"$instance"}, db)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Long Tx Count | `stat` |
| 3 | Servers Affected | `stat` |
| 4 | Max Open Age | `stat` |
| 5 | Open transactions older than 5 minutes. | `stat` |
| 6 | Open > 15m | `stat` |
| 7 | Open > 1h | `stat` |
| 8 | Sleeping Holders | `stat` |
| 9 | Active Tx (perf) | `stat` |
| 10 | Trends | `row` |
| 11 | Long Tx Count by Server | `timeseries` |
| 12 | Max Open Age by Server | `timeseries` |
| 13 | Long Tx by Database | `timeseries` |
| 14 | Active Tx per DB (perf) | `timeseries` |
| 15 | Fleet - where are the long transactions? | `row` |
| 16 | Servers with Long Transactions (fleet) | `table` |
| 17 | Open Sessions - investigate / kill candidates | `row` |
| 18 | Oldest Open Transactions (Top 15) | `bargauge` |
| 19 | Long-Open Transactions (detail) | `table` |
| 20 | Breakdowns | `row` |
| 21 | By Database | `table` |
| 22 | By Login | `table` |
| 23 | By Program | `table` |
| 24 | By Host | `table` |
| 25 | By Session Status | `table` |
| 26 | Oldest Age by Database | `table` |

Panel type summary: `bargauge`: 1, `row`: 5, `stat`: 8, `table`: 8, `timeseries`: 4

## Metrics used

- `mssql_active_transactions_per_db`
- `mssql_long_transaction_count`
- `mssql_long_transaction_seconds`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
