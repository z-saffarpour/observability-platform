# Collector polybase

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-polybase.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

PolyBase ops view: install/enable, compute-node health, DMS workers, distributed requests/steps, external work/operations, catalog inventory lists, and full recent node error details. Collector: mssql_polybase.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-polybase` |
| فایل منبع | [`sqlx-polybase.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-polybase.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `polybase` |
| تعداد پنل‌ها | 54 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values({__name__=~"mssql_polybase_external_tables\|mssql_polybase_external_data_source_info\|mssql_polybase_external_table_info", job="sql_exporter", instance=~"$instance"}, db)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Installed Servers | `stat` |
| 3 | Configured Servers | `stat` |
| 4 | In Use Servers | `stat` |
| 5 | Compute Nodes | `stat` |
| 6 | Unavailable Nodes | `stat` |
| 7 | Recent Errors 15m | `stat` |
| 8 | Failed Requests | `stat` |
| 9 | Running Requests | `stat` |
| 10 | Failed Workers | `stat` |
| 11 | External Tables | `stat` |
| 12 | Data Sources | `stat` |
| 13 | File Formats | `stat` |
| 14 | DBs with Tables | `stat` |
| 15 | Compute Nodes | `row` |
| 16 | Node process status | `table` |
| 17 | Node inventory (HEAD / COMPUTE) | `table` |
| 18 | Node Memory Used Ratio | `timeseries` |
| 19 | Node Received Age | `timeseries` |
| 20 | Node Threads | `timeseries` |
| 21 | Process CPU (rate) | `timeseries` |
| 22 | Total CPU (rate) | `timeseries` |
| 23 | Distributed Requests & Steps | `row` |
| 24 | Requests by Status | `timeseries` |
| 25 | Max Request Elapsed by Status | `timeseries` |
| 26 | Max Request Start Age by Status | `timeseries` |
| 27 | Running Request Start Age (per server) | `table` |
| 28 | Request Steps by Location/Op | `timeseries` |
| 29 | Request Step Max Elapsed | `timeseries` |
| 30 | SQL Steps by Status | `timeseries` |
| 31 | SQL Step Rows by Status | `timeseries` |
| 32 | Data Movement Service (DMS) | `row` |
| 33 | DMS services by node/status | `table` |
| 34 | DMS Workers by Status/Type | `timeseries` |
| 35 | DMS Bytes Processed | `timeseries` |
| 36 | DMS Rows Processed | `timeseries` |
| 37 | DMS Max Elapsed | `timeseries` |
| 38 | Failed DMS Workers (per server) | `table` |
| 39 | External Work & Operations | `row` |
| 40 | External Workers by Status/Type | `timeseries` |
| 41 | External Bytes Processed | `timeseries` |
| 42 | External Max Elapsed | `timeseries` |
| 43 | External Operations Count | `timeseries` |
| 44 | External Map Progress (avg) | `timeseries` |
| 45 | Failed External Workers (per server) | `table` |
| 46 | Catalog Inventory | `row` |
| 47 | Counts by database | `table` |
| 48 | External tables (full list) | `table` |
| 49 | External data sources (full list) | `table` |
| 50 | External file formats (full list) | `table` |
| 51 | Recent Node Errors | `row` |
| 52 | Error details (like query investigation - click Details to inspect full text) | `table` |
| 53 | Error counts by type (rolling 15 minutes) | `table` |
| 54 | Recent Errors Trend | `timeseries` |

ترکیب نوع پنل‌ها: `row`: 7, `stat`: 13, `table`: 12, `timeseries`: 22

## متریک‌های استفاده‌شده

- `mssql_polybase_compute_node_info`
- `mssql_polybase_dms_bytes_processed`
- `mssql_polybase_dms_max_elapsed_seconds`
- `mssql_polybase_dms_rows_processed`
- `mssql_polybase_dms_services`
- `mssql_polybase_dms_workers`
- `mssql_polybase_enabled`
- `mssql_polybase_external_data_source_info`
- `mssql_polybase_external_data_sources`
- `mssql_polybase_external_file_format_info`
- `mssql_polybase_external_file_formats`
- `mssql_polybase_external_operation_map_progress`
- `mssql_polybase_external_operations`
- `mssql_polybase_external_table_info`
- `mssql_polybase_external_tables`
- `mssql_polybase_external_worker_bytes_processed`
- `mssql_polybase_external_worker_max_elapsed_seconds`
- `mssql_polybase_external_workers`
- `mssql_polybase_installed`
- `mssql_polybase_node_allocated_memory`
- `mssql_polybase_node_available`
- `mssql_polybase_node_available_memory`
- `mssql_polybase_node_error_age_seconds`
- `mssql_polybase_node_errors_recent`
- `mssql_polybase_node_handles`
- `mssql_polybase_node_memory_used_ratio`
- `mssql_polybase_node_process_cpu_ticks_total`
- `mssql_polybase_node_received_age_seconds`
- `mssql_polybase_node_threads`
- `mssql_polybase_node_total_cpu_ticks_total`
- `mssql_polybase_request_max_elapsed_seconds`
- `mssql_polybase_request_max_start_age_seconds`
- `mssql_polybase_request_step_max_elapsed_seconds`
- `mssql_polybase_request_steps`
- `mssql_polybase_requests`
- `mssql_polybase_sql_step_rows`
- `mssql_polybase_sql_steps`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
