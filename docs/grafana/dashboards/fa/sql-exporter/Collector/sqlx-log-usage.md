# Collector log_usage

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-log-usage.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Transaction log ops view: used%/MB pressure, reuse-wait root cause, FULL+LOG_BACKUP action queue, growth companion metrics, per-server rollup. Collector mssql_log_usage @ 60s.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-log-usage` |
| فایل منبع | [`sqlx-log-usage.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-log-usage.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `log`, `tlog` |
| تعداد پنل‌ها | 30 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_log_used_percent{job="sql_exporter", instance=~"$instance"}, db)` |
| `reuse_wait` | Reuse Wait | `query` | `label_values(mssql_log_used_percent{job="sql_exporter", instance=~"$instance", db=~"$db"}, log_reuse_wait_desc)` |
| `warn_pct` | Warn % | `custom` | `60,70,80,85,90` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | DBs >= Warn% | `stat` |
| 3 | DBs >= 85% | `stat` |
| 4 | DBs >= 95% | `stat` |
| 5 | Max Used % | `stat` |
| 6 | Reuse Blocked | `stat` |
| 7 | Wait LOG_BACKUP | `stat` |
| 8 | Wait ACTIVE_TXN | `stat` |
| 9 | Total Log Size | `stat` |
| 10 | Hotspots | `row` |
| 11 | Top 15 DBs by Used % | `bargauge` |
| 12 | Top 15 DBs by Used MB | `bargauge` |
| 13 | Servers - DBs >= 85% | `bargauge` |
| 14 | Reuse Wait Reasons (count) | `bargauge` |
| 15 | FULL recovery >= Warn% | `bargauge` |
| 16 | Pressure / Action Queue | `row` |
| 17 | High Used % (>= Warn) - size + recovery + reuse wait | `table` |
| 18 | Reuse Blocked (wait != NOTHING) - why log cannot truncate | `table` |
| 19 | Inventory (topk 40 by Used %) - filtered by Server/DB/Wait | `table` |
| 20 | Trends (topk - avoids 600+ series) | `row` |
| 21 | Used % - Top 15 | `timeseries` |
| 22 | Used MB - Top 15 | `timeseries` |
| 23 | Total MB - Top 15 (growth / autogrow signal) | `timeseries` |
| 24 | Free MB - Lowest 15 | `timeseries` |
| 25 | Log Growth (from mssql_standard - companion) | `row` |
| 26 | Log Growths rate - Top 15 | `timeseries` |
| 27 | Log Growths rate now - Top 15 | `bargauge` |
| 28 | Growing logs (rate > 0) | `table` |
| 29 | Per-Server Rollup | `row` |
| 30 | Servers - pressure / size / reuse blocked | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 6, `row`: 6, `stat`: 8, `table`: 5, `timeseries`: 5

## متریک‌های استفاده‌شده

- `mssql_log_growths`
- `mssql_log_total_mb`
- `mssql_log_used_mb`
- `mssql_log_used_percent`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
