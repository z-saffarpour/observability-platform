# Collector mscluster

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/windows-exporter/collector/winexp-col-mscluster.md) · [مستندات فارسی Exporter](../../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Failover cluster health: node, network, resource and resource-group states plus quorum configuration. Anything not in the healthy state needs an owner.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-col-mscluster` |
| فایل منبع | [`winexp-col-mscluster.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-mscluster.json) |
| برچسب‌ها | `windows_exporter`, `collector`, `mscluster` |
| تعداد پنل‌ها | 30 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_exporter_build_info, job)` |
| `instance` | Server | `query` | `label_values(windows_exporter_build_info{job=~"${job:regex}"}, instance)` |

## پنل‌ها

| ردیف | عنوان | نوع |
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

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 8, `timeseries`: 5

## متریک‌های استفاده‌شده

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

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
