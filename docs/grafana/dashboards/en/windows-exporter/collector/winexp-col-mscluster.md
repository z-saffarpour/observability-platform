# Collector mscluster

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/windows-exporter/collector/winexp-col-mscluster.md) · [Exporter documentation](../../../../../windows-exporter/en/README.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Failover cluster health: node, network, resource and resource-group states plus quorum configuration. Anything not in the healthy state needs an owner.

## Details

| Property | Value |
|---|---|
| UID | `winexp-col-mscluster` |
| Source file | [`winexp-col-mscluster.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-mscluster.json) |
| Tags | `windows_exporter`, `collector`, `mscluster` |
| Panel count | 30 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_exporter_build_info, job)` |
| `instance` | Server | `query` | `label_values(windows_exporter_build_info{job=~"${job:regex}"}, instance)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Scrape FAIL | `stat` |
| 3 | Nodes Not Up | `stat` |
| 4 | Resources Not Online | `stat` |
| 5 | Groups Not Online | `stat` |
| 6 | Networks Not Up | `stat` |
| 7 | Nodes Up | `stat` |
| 8 | Total Resources | `stat` |
| 9 | Total Groups | `stat` |
| 10 | Fleet Ranking (now) | `row` |
| 11 | Most Unhealthy Resources by Node (topk 15) | `bargauge` |
| 12 | Resources Owned per Node (topk 15) | `bargauge` |
| 13 | Groups Owned per Node (topk 15) | `bargauge` |
| 14 | Fleet Snapshot & Hotspots | `row` |
| 15 | Hotspot: Resources Not Online | `table` |
| 16 | Hotspot: Groups Not Online | `table` |
| 17 | Node State | `table` |
| 18 | Cluster Network State | `table` |
| 19 | Trends | `row` |
| 20 | Unhealthy Counts (fleet) | `timeseries` |
| 21 | Node State (topk 10) | `timeseries` |
| 22 | Unhealthy Resources by Node (topk 10) | `timeseries` |
| 23 | Deep Dive | `row` |
| 24 | All Resources & Owner | `table` |
| 25 | All Groups & Owner | `table` |
| 26 | Quorum Configuration | `table` |
| 27 | Collector scrape health | `row` |
| 28 | Scrape Health by Host | `table` |
| 29 | Scrape Duration (topk 10) | `timeseries` |
| 30 | Scrape Success (bottomk 10) | `timeseries` |

Panel type summary: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 8, `timeseries`: 5

## Metrics used

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_mscluster_cluster_dynamic_quorum_enabled`
- `windows_mscluster_cluster_quorum_type_value`
- `windows_mscluster_network_state`
- `windows_mscluster_node_build_number`
- `windows_mscluster_node_state`
- `windows_mscluster_resource_owner_node`
- `windows_mscluster_resource_state`
- `windows_mscluster_resourcegroup_owner_node`
- `windows_mscluster_resourcegroup_state`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
