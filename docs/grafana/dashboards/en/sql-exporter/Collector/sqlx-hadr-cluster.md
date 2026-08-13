# Collector hadr_cluster

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-hadr-cluster.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Named WSFC / AG listeners / FCI only. Servers without cluster_name are excluded. FCI panels stay empty on AG-on-WSFC unless SQL is an FCI instance.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-hadr-cluster` |
| Source file | [`sqlx-hadr-cluster.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-hadr-cluster.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `hadr`, `alwayson`, `wsfc`, `fci`, `listener` |
| Panel count | 26 |
| Refresh interval | `30s` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_hadr_cluster_quorum_state{job="sql_exporter", cluster_name=~".+"}, instance)` |
| `ag` | AG | `query` | `label_values(mssql_hadr_listener_info{job="sql_exporter", instance=~"$instance"}, availability_group_name)` |
| `cluster` | Cluster | `query` | `label_values(mssql_hadr_cluster_quorum_state{job="sql_exporter", instance=~"$instance", cluster_name=~".+"}, cluster_name)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Untitled | `stat` |
| 3 | Untitled | `stat` |
| 4 | Untitled | `stat` |
| 5 | Untitled | `stat` |
| 6 | Untitled | `stat` |
| 7 | Untitled | `stat` |
| 8 | Untitled | `stat` |
| 9 | Untitled | `stat` |
| 10 | Instance Flags | `row` |
| 11 | IsHadrEnabled / IsClustered by server | `table` |
| 12 | WSFC Quorum & Members (named cluster_name only) | `row` |
| 13 | Cluster quorum state | `table` |
| 14 | Cluster members / votes | `table` |
| 15 | AG Listeners | `row` |
| 16 | Listener inventory (DNS / IP / port) | `table` |
| 17 | Listener IP state | `table` |
| 18 | FCI nodes (only when IsClustered=1 - not AG-on-WSFC) | `row` |
| 19 | FCI nodes / current owner (empty if AG uses WSFC but SQL is not an FCI) | `table` |
| 20 | Trends | `row` |
| 21 | Quorum State (1=NORMAL) | `timeseries` |
| 22 | Member State (1=UP) | `timeseries` |
| 23 | Listener IP State (0=ONLINE) | `timeseries` |
| 24 | FCI Node Status (0=UP) | `timeseries` |
| 25 | Member Quorum Votes | `timeseries` |
| 26 | FCI Current Owner (1=yes) | `timeseries` |

Panel type summary: `row`: 6, `stat`: 8, `table`: 6, `timeseries`: 6

## Metrics used

- `mssql_hadr_cluster_member_quorum_votes`
- `mssql_hadr_cluster_member_state`
- `mssql_hadr_cluster_quorum_state`
- `mssql_hadr_cluster_quorum_type`
- `mssql_hadr_fci_is_current_owner`
- `mssql_hadr_fci_node_status`
- `mssql_hadr_is_clustered`
- `mssql_hadr_is_hadr_enabled`
- `mssql_hadr_listener_info`
- `mssql_hadr_listener_ip_state`
- `mssql_hadr_listener_port`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
