# Collector replication

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/sql-exporter/Collector/sqlx-replication.md) · [مستندات فارسی Exporter](../../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Transactional replication health: latency, pending commands, Dist/LogReader/Snapshot agents, inventory, and local REPL SQL Agent jobs.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-replication` |
| فایل منبع | [`sqlx-replication.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-replication.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `collector`, `replication` |
| تعداد پنل‌ها | 30 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `subscription_type` | Type | `query` | `label_values(mssql_replication_distributor_latency_seconds{job="sql_exporter", instance=~"$instance"}, subscription_type)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Published DBs | `stat` |
| 3 | Subscribed DBs | `stat` |
| 4 | Distributors | `stat` |
| 5 | Publications | `stat` |
| 6 | Max Dist Latency | `stat` |
| 7 | Max Pending Cmds | `stat` |
| 8 | Dist Fail/Retry | `stat` |
| 9 | LR Fail/Retry | `stat` |
| 10 | Jobs Failed | `stat` |
| 11 | Jobs Running | `stat` |
| 12 | Latency & Backlog Trends | `row` |
| 13 | Distribution Agent Latency | `timeseries` |
| 14 | Pending Commands (undelivered) | `timeseries` |
| 15 | Log Reader Latency | `timeseries` |
| 16 | Delivered Commands (latest history) | `timeseries` |
| 17 | Distribution Agents (operational) | `row` |
| 18 | Distribution Agents - status / latency / freshness | `table` |
| 19 | Pending Commands by Agent | `table` |
| 20 | Log Reader & Snapshot Agents | `row` |
| 21 | Log Reader Agents | `table` |
| 22 | Snapshot Agents | `table` |
| 23 | Inventory (roles & publications) | `row` |
| 24 | Database Replication Roles | `table` |
| 25 | Distributor Hosts | `table` |
| 26 | Publications (local distribution DB) | `table` |
| 27 | Subscriptions (local distribution DB) | `table` |
| 28 | Local REPL SQL Agent Jobs (Pull / mixed) | `row` |
| 29 | Replication Agent Jobs | `table` |
| 30 | Agent Job Last Run Age | `timeseries` |

ترکیب نوع پنل‌ها: `row`: 6, `stat`: 10, `table`: 9, `timeseries`: 5

## متریک‌های استفاده‌شده

- `mssql_replication_agent_job_enabled`
- `mssql_replication_agent_job_last_run_age_seconds`
- `mssql_replication_agent_job_last_run_status`
- `mssql_replication_agent_job_running`
- `mssql_replication_distribution_agent_last_run_age_seconds`
- `mssql_replication_distribution_agent_status`
- `mssql_replication_distribution_delivered_commands`
- `mssql_replication_distributor_latency_seconds`
- `mssql_replication_is_distributor`
- `mssql_replication_logreader_agent_last_run_age_seconds`
- `mssql_replication_logreader_agent_status`
- `mssql_replication_logreader_delivered_commands`
- `mssql_replication_logreader_latency_seconds`
- `mssql_replication_merge_published_databases`
- `mssql_replication_pending_commands`
- `mssql_replication_publication`
- `mssql_replication_published_databases`
- `mssql_replication_snapshot_agent_last_run_age_seconds`
- `mssql_replication_snapshot_agent_status`
- `mssql_replication_subscribed_databases`
- `mssql_replication_subscription`
- `mssql_up`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
