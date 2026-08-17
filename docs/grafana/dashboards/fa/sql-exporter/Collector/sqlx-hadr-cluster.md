# Collector hadr_cluster

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-hadr-cluster.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Named WSFC / AG listeners / FCI only. Servers without cluster_name are excluded. FCI panels stay empty on AG-on-WSFC unless SQL is an FCI instance.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-hadr-cluster` |
| فایل منبع | [`sqlx-hadr-cluster.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-hadr-cluster.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `hadr`, `alwayson`, `wsfc`, `fci`, `listener` |
| تعداد پنل‌ها | 26 |
| بازهٔ تازه‌سازی | `30s` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_hadr_cluster_quorum_state{job="sql_exporter", cluster_name=~".+"}, instance)` |
| `ag` | AG | `query` | `label_values(mssql_hadr_listener_info{job="sql_exporter", instance=~"$instance"}, availability_group_name)` |
| `cluster` | Cluster | `query` | `label_values(mssql_hadr_cluster_quorum_state{job="sql_exporter", instance=~"$instance", cluster_name=~".+"}, cluster_name)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | بدون عنوان | `stat` |
| 3 | بدون عنوان | `stat` |
| 4 | بدون عنوان | `stat` |
| 5 | بدون عنوان | `stat` |
| 6 | بدون عنوان | `stat` |
| 7 | بدون عنوان | `stat` |
| 8 | بدون عنوان | `stat` |
| 9 | بدون عنوان | `stat` |
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

ترکیب نوع پنل‌ها: `row`: 6, `stat`: 8, `table`: 6, `timeseries`: 6

## متریک‌های استفاده‌شده

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

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
