# Collector database_integrity

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-database-integrity.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Database integrity ops view: suspect_pages corruption signals, CHECKDB coverage vs SLA (never/stale/ok), PAGE_VERIFY risks. Collector scrapes hourly via DBCC DBINFO + msdb.dbo.suspect_pages.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-database-integrity` |
| فایل منبع | [`sqlx-database-integrity.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-database-integrity.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `integrity`, `checkdb` |
| تعداد پنل‌ها | 24 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_checkdb_age_seconds{job="sql_exporter", instance=~"$instance"}, db)` |
| `event_type` | Suspect Event | `custom` | `823_or_824_other_than_bad_checksum_or_torn,bad_checksum,torn_page,restored,repaired,deallocated,other` |
| `checkdb_sla` | CHECKDB SLA (sec) | `custom` | `86400,604800,1209600,2592000` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Suspect Pages | `stat` |
| 3 | Servers w/ Suspect | `stat` |
| 4 | Never CHECKDB | `stat` |
| 5 | Stale > SLA | `stat` |
| 6 | Within SLA | `stat` |
| 7 | Max Age | `stat` |
| 8 | PAGE_VERIFY Risk | `stat` |
| 9 | DBs Monitored | `stat` |
| 10 | Corruption / Suspect Pages (msdb.dbo.suspect_pages) | `row` |
| 11 | Suspect Pages Total by Server | `timeseries` |
| 12 | Suspect Pages by Event | `timeseries` |
| 13 | Top Suspect Page Counts | `bargauge` |
| 14 | Top Error Counts (hits) | `bargauge` |
| 15 | Suspect Pages Detail | `table` |
| 16 | Suspect Errors + Last Seen | `table` |
| 17 | CHECKDB Coverage (dbi_dbccLastKnownGood) | `row` |
| 18 | Fleet Coverage Counts | `timeseries` |
| 19 | Worst CHECKDB Age (days) | `bargauge` |
| 20 | Never Run CHECKDB | `table` |
| 21 | Stale Beyond SLA | `table` |
| 22 | CHECKDB Inventory (age + last good) | `table` |
| 23 | PAGE_VERIFY Risks (from mssql_database_configuration) | `row` |
| 24 | PAGE_VERIFY != CHECKSUM | `table` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 4, `stat`: 8, `table`: 6, `timeseries`: 3

## متریک‌های استفاده‌شده

- `mssql_checkdb_age_seconds`
- `mssql_checkdb_last_good_timestamp`
- `mssql_checkdb_never_run`
- `mssql_database_page_verify_option`
- `mssql_suspect_pages`
- `mssql_suspect_pages_error_count`
- `mssql_suspect_pages_last_seen_age_seconds`
- `mssql_suspect_pages_total`
- `mssql_up`
- `other`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
