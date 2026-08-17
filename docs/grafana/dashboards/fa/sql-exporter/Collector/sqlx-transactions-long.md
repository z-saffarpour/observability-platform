# Collector transactions_long

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-transactions-long.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Long-open user transactions (>=30s): fleet KPIs, age trends, session detail (login/program/host/status), and breakdowns. Cross-link Blocking / Locks when victims appear. Collector: mssql_transactions_long (30s). Alert: SqlLongTransaction at 15m.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-transactions-long` |
| فایل منبع | [`sqlx-transactions-long.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-transactions-long.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `transactions` |
| تعداد پنل‌ها | 26 |
| بازهٔ تازه‌سازی | `30s` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_active_transactions_per_db{job="sql_exporter", instance=~"$instance"}, db)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Long Tx Count | `stat` |
| 3 | Servers Affected | `stat` |
| 4 | Max Open Age | `stat` |
| 5 | Open transactions older than 5 minutes. | `stat` |
| 6 | Open > 15m | `stat` |
| 7 | Open > 1h | `stat` |
| 8 | Sleeping Holders | `stat` |
| 9 | Active Tx (perf) | `stat` |
| 10 | Trends | `row` |
| 11 | Long Tx Count by Server | `timeseries` |
| 12 | Max Open Age by Server | `timeseries` |
| 13 | Long Tx by Database | `timeseries` |
| 14 | Active Tx per DB (perf) | `timeseries` |
| 15 | Fleet - where are the long transactions? | `row` |
| 16 | Servers with Long Transactions (fleet) | `table` |
| 17 | Open Sessions - investigate / kill candidates | `row` |
| 18 | Oldest Open Transactions (Top 15) | `bargauge` |
| 19 | Long-Open Transactions (detail) | `table` |
| 20 | Breakdowns | `row` |
| 21 | By Database | `table` |
| 22 | By Login | `table` |
| 23 | By Program | `table` |
| 24 | By Host | `table` |
| 25 | By Session Status | `table` |
| 26 | Oldest Age by Database | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 1, `row`: 5, `stat`: 8, `table`: 8, `timeseries`: 4

## متریک‌های استفاده‌شده

- `mssql_active_transactions_per_db`
- `mssql_long_transaction_count`
- `mssql_long_transaction_seconds`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
