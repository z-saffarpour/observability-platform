# Collector memory

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-memory.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Ops-first SQL memory: pending grants, live large-grant sessions (table), fleet triage, workspace pressure, breakdowns. Start at Investigate Now, then Fleet Triage. Collector: mssql_memory (60s).

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-memory` |
| فایل منبع | [`sqlx-memory.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-memory.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `memory` |
| تعداد پنل‌ها | 35 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_memory_active_grant_mb{job="sql_exporter", instance=~"$instance"}, db)` |
| `min_grant_mb` | Min Grant MB | `custom` | `100,512,1024,4096,8192` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Pending Grants | `stat` |
| 3 | Fleet count with grant backlog. | `stat` |
| 4 | Sessions with grant >= Min Grant MB threshold. | `stat` |
| 5 | Largest live query memory grant right now. | `stat` |
| 6 | At Memory Cap | `stat` |
| 7 | Memory Waits | `stat` |
| 8 | Granted / Maximum workspace pool. | `stat` |
| 9 | Queries currently holding a memory grant. | `stat` |
| 10 | Investigate Now - who holds memory? | `row` |
| 11 | Largest Grants (top 15) | `bargauge` |
| 12 | Active Large Memory Grants | `table` |
| 13 | Large Grants by Server / Database | `table` |
| 14 | Memory Wait Sessions (RESOURCE_SEMAPHORE / CMEMTHREAD) | `table` |
| 15 | Fleet Triage - which servers? | `row` |
| 16 | Highest Memory Util % (top 15 servers) | `bargauge` |
| 17 | Most Large Grants by Server | `bargauge` |
| 18 | Memory Health by Server | `table` |
| 19 | Servers Needing Attention | `table` |
| 20 | Trends (server aggregates) | `row` |
| 21 | Memory Util % - worst servers | `timeseries` |
| 22 | Grants Pending | `timeseries` |
| 23 | Workspace Memory - Granted vs Max | `timeseries` |
| 24 | Large Grant Sessions (count) | `timeseries` |
| 25 | Breakdowns | `row` |
| 26 | Grant Total by Database | `table` |
| 27 | Grant Total by Login | `table` |
| 28 | Deep Dive - Memory Clerks | `row` |
| 29 | Top Clerk Types (MB, fleet aggregate) | `bargauge` |
| 30 | Top Clerks by Server | `table` |
| 31 | Deep Dive - Semaphore & Stolen | `row` |
| 32 | Semaphore Waiters | `timeseries` |
| 33 | Semaphore Granted MB | `timeseries` |
| 34 | Semaphore Available MB | `timeseries` |
| 35 | Stolen Server Memory | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 4, `row`: 7, `stat`: 8, `table`: 8, `timeseries`: 8

## متریک‌های استفاده‌شده

- `mssql_memory_active_grant_mb`
- `mssql_memory_clerk_size_kb`
- `mssql_memory_grants_outstanding`
- `mssql_memory_grants_pending`
- `mssql_memory_manager_mb`
- `mssql_memory_stolen_mb`
- `mssql_memory_target_server_mb`
- `mssql_memory_total_server_mb`
- `mssql_resource_semaphore_available_mb`
- `mssql_resource_semaphore_granted_mb`
- `mssql_resource_semaphore_waiter_count`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
