# Collector connections

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-connections.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Client connections / sessions - KPI strip (running vs sleeping), top login/program/host/db, open transactions, and long-idle sleeping (connection-pool leak). Filter by Server. New idle/open-tran panels need mssql_connections_detail collector redeploy.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-connections` |
| Source file | [`sqlx-connections.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-connections.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `connections` |
| Panel count | 26 |
| Refresh interval | `30s` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Overview | `row` |
| 2 | Total Sessions | `stat` |
| 3 | Running | `stat` |
| 4 | Sleeping | `stat` |
| 5 | Dormant | `stat` |
| 6 | User Connections | `stat` |
| 7 | Open Tran | `stat` |
| 8 | Idle >=5m | `stat` |
| 9 | Idle >=1h | `stat` |
| 10 | Trends | `row` |
| 11 | Sessions by Status (stacked) | `timeseries` |
| 12 | Total Sessions vs User Connections | `timeseries` |
| 13 | Running Sessions | `timeseries` |
| 14 | Sleeping Sessions | `timeseries` |
| 15 | Status Mix (now) | `piechart` |
| 16 | Idle Age Buckets (sleeping) | `timeseries` |
| 17 | Who is connected (Top) | `row` |
| 18 | Top Logins (Total / Running / Sleeping) | `table` |
| 19 | Top Programs (Total / Running / Sleeping) | `table` |
| 20 | Top Hosts (Total / Running / Sleeping) | `table` |
| 21 | Top Databases (Total / Running / Sleeping) | `table` |
| 22 | Risk: Open Transactions & Long Idle | `row` |
| 23 | Open Transactions (total) | `timeseries` |
| 24 | Idle >=5m (sleeping) | `timeseries` |
| 25 | Open Transactions by Login / DB | `table` |
| 26 | Long Idle Sleeping (>=5m) by Login / Program / Host | `table` |

Panel type summary: `piechart`: 1, `row`: 4, `stat`: 8, `table`: 6, `timeseries`: 7

## Metrics used

- `mssql_sessions_by_db`
- `mssql_sessions_by_host`
- `mssql_sessions_by_login`
- `mssql_sessions_by_program`
- `mssql_sessions_by_status`
- `mssql_sessions_idle_bucket`
- `mssql_sessions_idle_long`
- `mssql_sessions_idle_long_max_seconds`
- `mssql_sessions_open_tran`
- `mssql_sessions_open_tran_total`
- `mssql_up`
- `mssql_user_connections_current`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
