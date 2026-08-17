# Collector file_io

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-file-io.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

File I/O ops view: KPI (slow files / pending / p95 / volume), lifetime + 15m interval latency hotspots, fleet snapshot, throughput/IOPS by server. Per-file timeseries avoided; file detail is collapsed. Threshold via Lat ms variable (alert baseline 20ms).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-file-io` |
| فایل منبع | [`sqlx-file-io.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-file-io.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `io` |
| تعداد پنل‌ها | 53 |
| بازهٔ تازه‌سازی | `3m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_file_io_avg_write_latency_ms{job="sql_exporter", instance=~"${instance:regex}"}, db)` |
| `type_desc` | File Type | `custom` | `ROWS,LOG,FILESTREAM,FULLTEXT` |
| `volume` | Volume | `query` | `label_values(mssql_volume_used_percent{job="sql_exporter", instance=~"${instance:regex}"}, volume_mount_point)` |
| `lat_ms` | Lat ms | `custom` | `10,20,50,100` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Slow Read >= thr | `stat` |
| 3 | Slow Write >= thr | `stat` |
| 4 | Critical Read >=50 | `stat` |
| 5 | Critical Write >=50 | `stat` |
| 6 | Pending IO (max) | `stat` |
| 7 | Pending Wait (max) | `stat` |
| 8 | Read p95 (max) | `stat` |
| 9 | Write p95 (max) | `stat` |
| 10 | Vol Used >=85% | `stat` |
| 11 | Vol Used >=95% | `stat` |
| 12 | Interval R >= thr | `stat` |
| 13 | Interval W >= thr | `stat` |
| 14 | Read thruput | `stat` |
| 15 | Write thruput | `stat` |
| 16 | Read IOPS | `stat` |
| 17 | Write IOPS | `stat` |
| 18 | Hotspots | `row` |
| 19 | Top Files - Lifetime Write Latency | `bargauge` |
| 20 | Top Files - Lifetime Read Latency | `bargauge` |
| 21 | Top Servers - Pending IO | `bargauge` |
| 22 | Top Files - Interval Write Lat (15m) | `bargauge` |
| 23 | Top Files - Interval Read Lat (15m) | `bargauge` |
| 24 | Top Servers - Slow Write Files | `bargauge` |
| 25 | Slow Files & Pressure | `row` |
| 26 | Slow Writes (lifetime >= threshold) | `table` |
| 27 | Slow Reads (lifetime >= threshold) | `table` |
| 28 | Server Trends (aggregated) | `row` |
| 29 | Max Lifetime Write Latency by Server | `timeseries` |
| 30 | Max Lifetime Read Latency by Server | `timeseries` |
| 31 | Max Interval Write Latency (15m) | `timeseries` |
| 32 | Max Interval Read Latency (15m) | `timeseries` |
| 33 | Pending IO Requests | `timeseries` |
| 34 | Pending IO Wait (ms) | `timeseries` |
| 35 | Write Throughput by Server | `timeseries` |
| 36 | Read Throughput by Server | `timeseries` |
| 37 | Write IOPS by Server | `timeseries` |
| 38 | Read IOPS by Server | `timeseries` |
| 39 | Write Stall Rate (ms/s) | `timeseries` |
| 40 | Read Stall Rate (ms/s) | `timeseries` |
| 41 | Fleet Snapshot | `row` |
| 42 | Volumes | `row` |
| 43 | Top Volumes - Used % | `bargauge` |
| 44 | Volume Used % | `timeseries` |
| 45 | Volume Space | `table` |
| 46 | I/O Health by Server | `table` |
| 47 | File Detail (expand to load) | `row` |
| 48 | Top Interval Write Latency Files (topk 40) | `table` |
| 49 | Top Interval Read Latency Files (topk 40) | `table` |
| 50 | Top Write Throughput Files | `table` |
| 51 | Top Read Throughput Files | `table` |
| 52 | Top Write Stall Rate Files | `table` |
| 53 | Top Read Stall Rate Files | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 7, `row`: 7, `stat`: 16, `table`: 10, `timeseries`: 13

## متریک‌های استفاده‌شده

- `FULLTEXT`
- `mssql_file_io_avg_read_latency_ms`
- `mssql_file_io_avg_write_latency_ms`
- `mssql_file_io_num_of_reads`
- `mssql_file_io_num_of_writes`
- `mssql_file_io_pending_requests`
- `mssql_file_io_pending_wait_ms`
- `mssql_file_io_read_bytes`
- `mssql_file_io_read_latency_p95_ms`
- `mssql_file_io_stall_read_ms`
- `mssql_file_io_stall_write_ms`
- `mssql_file_io_write_bytes`
- `mssql_file_io_write_latency_p95_ms`
- `mssql_up`
- `mssql_volume_available_bytes`
- `mssql_volume_total_bytes`
- `mssql_volume_used_percent`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
