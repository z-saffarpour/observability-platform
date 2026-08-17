# Collector replication

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-replication.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Transactional replication health: latency, pending commands, Dist/LogReader/Snapshot agents, inventory, and local REPL SQL Agent jobs.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-replication` |
| Source file | [`sqlx-replication.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-replication.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `replication` |
| Panel count | 30 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `subscription_type` | Type | `query` | `label_values(mssql_replication_distributor_latency_seconds{job="sql_exporter", instance=~"$instance"}, subscription_type)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Published DBs | `stat` |
| 3 | Subscribed DBs | `stat` |
| 4 | Distributors | `stat` |
| 5 | Publications | `stat` |
| 6 | Max Dist Latency | `stat` |
| 7 | Max Pending Cmds | `stat` |
| 8 | Dist Fail/Retry | `stat` |
| 9 | LR Fail/Retry | `stat` |
| 10 | Jobs Failed | `stat` |
| 11 | Jobs Running | `stat` |
| 12 | Latency & Backlog Trends | `row` |
| 13 | Distribution Agent Latency | `timeseries` |
| 14 | Pending Commands (undelivered) | `timeseries` |
| 15 | Log Reader Latency | `timeseries` |
| 16 | Delivered Commands (latest history) | `timeseries` |
| 17 | Distribution Agents (operational) | `row` |
| 18 | Distribution Agents - status / latency / freshness | `table` |
| 19 | Pending Commands by Agent | `table` |
| 20 | Log Reader & Snapshot Agents | `row` |
| 21 | Log Reader Agents | `table` |
| 22 | Snapshot Agents | `table` |
| 23 | Inventory (roles & publications) | `row` |
| 24 | Database Replication Roles | `table` |
| 25 | Distributor Hosts | `table` |
| 26 | Publications (local distribution DB) | `table` |
| 27 | Subscriptions (local distribution DB) | `table` |
| 28 | Local REPL SQL Agent Jobs (Pull / mixed) | `row` |
| 29 | Replication Agent Jobs | `table` |
| 30 | Agent Job Last Run Age | `timeseries` |

Panel type summary: `row`: 6, `stat`: 10, `table`: 9, `timeseries`: 5

## Metrics used

- `mssql_replication_agent_job_enabled`
- `mssql_replication_agent_job_last_run_age_seconds`
- `mssql_replication_agent_job_last_run_status`
- `mssql_replication_agent_job_running`
- `mssql_replication_distribution_agent_last_run_age_seconds`
- `mssql_replication_distribution_agent_status`
- `mssql_replication_distribution_delivered_commands`
- `mssql_replication_distributor_latency_seconds`
- `mssql_replication_is_distributor`
- `mssql_replication_logreader_agent_last_run_age_seconds`
- `mssql_replication_logreader_agent_status`
- `mssql_replication_logreader_delivered_commands`
- `mssql_replication_logreader_latency_seconds`
- `mssql_replication_merge_published_databases`
- `mssql_replication_pending_commands`
- `mssql_replication_publication`
- `mssql_replication_published_databases`
- `mssql_replication_snapshot_agent_last_run_age_seconds`
- `mssql_replication_snapshot_agent_status`
- `mssql_replication_subscribed_databases`
- `mssql_replication_subscription`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
