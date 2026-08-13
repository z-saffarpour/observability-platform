# Collector instance_configuration

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-instance-configuration.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Instance sp_configure drift ops: value vs value_in_use, AG/FCI fleet spread, Instant File Initialization, uptime, global trace flags. Collector: mssql_instance_configuration (300s).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-instance-configuration` |
| فایل منبع | [`sqlx-instance-configuration.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-instance-configuration.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `configuration`, `drift`, `instance` |
| تعداد پنل‌ها | 38 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `config_name` | Setting | `query` | `label_values(mssql_instance_config_value{job="sql_exporter", instance=~"$instance"}, config_name)` |

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
| 10 | Restart Pending / Fleet Drift | `row` |
| 11 | Restart Pending (configured != in_use) | `table` |
| 12 | Fleet Drift - Server Memory | `table` |
| 13 | Fleet Drift - Other Settings | `table` |
| 14 | Restart Pending Over Time | `timeseries` |
| 15 | In-Use Value (filtered Setting) | `timeseries` |
| 16 | Memory / Parallelism / Workers | `row` |
| 17 | Memory & Parallelism (in_use) | `table` |
| 18 | Max Server Memory In Use | `bargauge` |
| 19 | MAXDOP In Use | `bargauge` |
| 20 | Max / Min Server Memory | `timeseries` |
| 21 | MAXDOP / Cost Threshold | `timeseries` |
| 22 | Timeouts / Packet / Connections (in_use) | `table` |
| 23 | Feature / Surface Flags | `row` |
| 24 | Instance Feature Flags (in_use) | `table` |
| 25 | Lightweight Pooling ON | `table` |
| 26 | Priority Boost ON | `table` |
| 27 | Optimize for Ad Hoc / Backup Defaults | `timeseries` |
| 28 | Risk Flags (Mail / Ad Hoc / Startup / Fiber / Boost) | `timeseries` |
| 29 | IFI / Uptime | `row` |
| 30 | Instant File Initialization | `table` |
| 31 | Start Time / Uptime | `table` |
| 32 | Uptime | `timeseries` |
| 33 | IFI Enabled (1/0/-1) | `timeseries` |
| 34 | Global Trace Flags | `row` |
| 35 | Globally Enabled Trace Flags | `table` |
| 36 | Trace Flag Enabled | `timeseries` |
| 37 | Full Configuration Inventory | `row` |
| 38 | All Selected Settings (configured / in_use / pending) | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 2, `row`: 7, `stat`: 8, `table`: 12, `timeseries`: 9

## متریک‌های استفاده‌شده

- `mssql_instance_config_restart_pending`
- `mssql_instance_config_value`
- `mssql_instance_config_value_in_use`
- `mssql_instance_ifi_enabled`
- `mssql_instance_start_unix`
- `mssql_instance_trace_flag`
- `mssql_instance_uptime_seconds`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
