# Collector waits

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-waits.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Wait stats ops view: class composition, signal vs resource pressure, top wait types with avg/max, and fleet hotspot tables. Benign waits filtered in collector. Source: mssql_waits (120s). Rates are ms/s from cumulative DMVs.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-waits` |
| فایل منبع | [`sqlx-waits.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-waits.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `waits` |
| تعداد پنل‌ها | 31 |
| بازهٔ تازه‌سازی | `30s` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `wait_class` | Wait Class | `query` | `label_values(mssql_waits_by_class_time_ms{job="sql_exporter", instance=~"$instance"}, wait_class)` |
| `wait_type` | Wait Type | `query` | `label_values(mssql_wait_time_ms{job="sql_exporter", instance=~"$instance"}, wait_type)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | High Signal (>=25%) | `stat` |
| 3 | High Nonbenign (>=70%) | `stat` |
| 4 | Concentrated Top5 (>=90%) | `stat` |
| 5 | Max Signal Ratio | `stat` |
| 6 | Highest share of wait time that is non-benign. | `stat` |
| 7 | Max Top5 Share | `stat` |
| 8 | Hot Wait Types | `stat` |
| 9 | Max Wait Rate | `stat` |
| 10 | Wait Classes - where time goes | `row` |
| 11 | Wait Time by Class (ms/s) | `timeseries` |
| 12 | Top Classes Now | `bargauge` |
| 13 | Waiting Tasks by Class (ops/s) | `timeseries` |
| 14 | Total Wait Rate by Server | `timeseries` |
| 15 | Pressure Indicators | `row` |
| 16 | Signal Wait Ratio % | `timeseries` |
| 17 | Nonbenign Wait % | `timeseries` |
| 18 | Top5 Share of Nonbenign % | `timeseries` |
| 19 | Signal vs Resource Wait Rate (ms/s) | `timeseries` |
| 20 | Top Wait Types - investigate | `row` |
| 21 | Top Wait Rates (ms/s) | `bargauge` |
| 22 | Top Max Wait Time | `bargauge` |
| 23 | Top Avg Wait / Task | `bargauge` |
| 24 | Wait Type Detail (rate + signal/resource + avg) | `table` |
| 25 | Top Wait Types Trend (ms/s) | `timeseries` |
| 26 | Waiting Tasks Rate by Type | `timeseries` |
| 27 | Fleet Snapshot & Hotspots | `row` |
| 28 | Wait Health by Server | `table` |
| 29 | Hotspots: Signal Ratio >= 15% | `table` |
| 30 | Hotspots: Wait Rate Leaders | `table` |
| 31 | Class Mix by Server | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 4, `row`: 5, `stat`: 8, `table`: 5, `timeseries`: 9

## متریک‌های استفاده‌شده

- `mssql_up`
- `mssql_wait_max_time_ms`
- `mssql_wait_resource_time_ms`
- `mssql_wait_signal_time_ms`
- `mssql_wait_time_ms`
- `mssql_wait_waiting_tasks`
- `mssql_waits_by_class_tasks`
- `mssql_waits_by_class_time_ms`
- `mssql_waits_nonbenign_percent`
- `mssql_waits_signal_ratio_percent`
- `mssql_waits_top5_share_percent`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
