# Collector errorlog_signals

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-errorlog-signals.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

ERRORLOG signal counters (rolling 6h via xp_readerrorlog): capacity criticals (9002/1105/112), I/O & latch, AlwaysOn redo, deadlocks, client disconnects. Filter by Server and Signal.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-errorlog-signals` |
| فایل منبع | [`sqlx-errorlog-signals.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-errorlog-signals.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `errorlog` |
| تعداد پنل‌ها | 32 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `signal` | Signal | `query` | `label_values(mssql_errorlog_signal_count{job="sql_exporter", instance=~"$instance"}, signal)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI (rolling 6h ERRORLOG window) | `row` |
| 2 | Total Signals | `stat` |
| 3 | Servers Affected | `stat` |
| 4 | Distinct Signals | `stat` |
| 5 | Capacity Crit | `stat` |
| 6 | I/O / Latch | `stat` |
| 7 | AG Redo | `stat` |
| 8 | Deadlocks | `stat` |
| 9 | Client Drop 4014 | `stat` |
| 10 | Log Full 9002 | `stat` |
| 11 | Filegroup Full | `stat` |
| 12 | Backup Disk Full | `stat` |
| 13 | Slow I/O | `stat` |
| 14 | Latch 845 | `stat` |
| 15 | Mem Grant 8645 | `stat` |
| 16 | Network 178xx | `stat` |
| 17 | AG Suspend | `stat` |
| 18 | Hotspots | `row` |
| 19 | Top Servers by Signal Count | `bargauge` |
| 20 | Top Signal Types (fleet) | `bargauge` |
| 21 | Active Signals > 0 (Server x Signal) | `table` |
| 22 | Trends (rolling 6h gauge over time) | `row` |
| 23 | Fleet Total by Signal | `timeseries` |
| 24 | Capacity Crit (log / FG / backup disk) | `timeseries` |
| 25 | I/O & Latch Pressure | `timeseries` |
| 26 | Session / Network / Deadlock / Mem | `timeseries` |
| 27 | AlwaysOn Redo Failures | `timeseries` |
| 28 | Fleet Matrix (per-server rollup) | `row` |
| 29 | Servers - signal categories (6h window) | `table` |
| 30 | All Signal Series (raw) | `table` |
| 31 | Signal Glossary & Ops Notes | `row` |
| 32 | بدون عنوان | `text` |

ترکیب نوع پنل‌ها: `bargauge`: 2, `row`: 5, `stat`: 16, `table`: 3, `text`: 1, `timeseries`: 5

## متریک‌های استفاده‌شده

- `mssql_errorlog_signal_count`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
