# Failover Cluster

[فهرست داشبوردها](../README.md) · [راهنمای Grafana](../../../../../grafana/README.md) · [English](../../en/windows-exporter/winexp-00-cluster.md) · [مستندات فارسی Exporter](../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Windows Failover Cluster (mscluster) health: nodes, networks, resource groups, resources, quorum and ClusSvc. Aligns with windows_exporter.mscluster alert rules. Requires cluster/data-platform-cluster profiles.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-00-cluster` |
| فایل منبع | [`winexp-00-cluster.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-cluster.json) |
| برچسب‌ها | `windows_exporter`, `cluster`, `mscluster`, `ha` |
| تعداد پنل‌ها | 41 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_mscluster_node_state, job)` |
| `instance` | Server | `query` | `label_values(windows_mscluster_node_state{job=~"${job:regex}"}, instance)` |
| `owner_group` | Group | `query` | `label_values(windows_mscluster_resource_state{job=~"${job:regex}",instance=~"${instance:regex}"}, owner_group)` |
| `resource` | Resource | `query` | `label_values(windows_mscluster_resource_state{job=~"${job:regex}",instance=~"${instance:regex}",owner_group=~"${owner_group:regex}"}, name)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health Snapshot | `row` |
| 2 | Nodes Up | `stat` |
| 3 | Nodes Not Up | `stat` |
| 4 | Networks Not Up | `stat` |
| 5 | Failed Resources | `stat` |
| 6 | Failed Groups | `stat` |
| 7 | Offline Groups | `stat` |
| 8 | Drain In Progress | `stat` |
| 9 | ClusSvc Not Running | `stat` |
| 10 | Inventory / Triage | `row` |
| 11 | Cluster Nodes | `table` |
| 12 | Resource Groups | `table` |
| 13 | Not-Online Resources | `table` |
| 14 | Nodes | `row` |
| 15 | Node State | `timeseries` |
| 16 | Node Drain Status | `timeseries` |
| 17 | Node Weight | `timeseries` |
| 18 | Dynamic Weight | `timeseries` |
| 19 | Networks | `row` |
| 20 | Cluster Network State | `timeseries` |
| 21 | Cluster Network Role | `timeseries` |
| 22 | Networks Inventory | `table` |
| 23 | Resource Groups | `row` |
| 24 | Resource Group State | `timeseries` |
| 25 | Group Owner Node | `table` |
| 26 | Failover Threshold | `timeseries` |
| 27 | Failover Period (hours) | `timeseries` |
| 28 | Resources | `row` |
| 29 | Resource State | `timeseries` |
| 30 | Resource Owner Node | `table` |
| 31 | Restart Threshold | `timeseries` |
| 32 | Restart Delay (ms) | `timeseries` |
| 33 | Cluster Quorum / Meta | `row` |
| 34 | Quorum Type | `stat` |
| 35 | Dynamic Quorum | `stat` |
| 36 | Fix Quorum | `stat` |
| 37 | Backup In Progress | `stat` |
| 38 | Functional Level | `stat` |
| 39 | Cluster Service (ClusSvc) | `row` |
| 40 | ClusSvc State by Host | `table` |
| 41 | ClusSvc Running (1=yes) | `timeseries` |

ترکیب نوع پنل‌ها: `row`: 8, `stat`: 13, `table`: 7, `timeseries`: 13

## متریک‌های استفاده‌شده

- `windows_mscluster_cluster_backup_in_progress`
- `windows_mscluster_cluster_cluster_functional_level`
- `windows_mscluster_cluster_dynamic_quorum_enabled`
- `windows_mscluster_cluster_fix_quorum`
- `windows_mscluster_cluster_quorum_type_value`
- `windows_mscluster_network_role`
- `windows_mscluster_network_state`
- `windows_mscluster_node_dynamic_weight`
- `windows_mscluster_node_node_drain_status`
- `windows_mscluster_node_node_weight`
- `windows_mscluster_node_state`
- `windows_mscluster_resource_owner_node`
- `windows_mscluster_resource_restart_delay`
- `windows_mscluster_resource_restart_threshold`
- `windows_mscluster_resource_state`
- `windows_mscluster_resourcegroup_failover_period`
- `windows_mscluster_resourcegroup_failover_threshold`
- `windows_mscluster_resourcegroup_owner_node`
- `windows_mscluster_resourcegroup_state`
- `windows_service_state`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
