# Security NOC

[فهرست داشبوردها](../README.md) · [راهنمای Grafana](../../../../../grafana/README.md) · [English](../../en/sql-exporter/sqlx-security-noc.md) · [مستندات فارسی Exporter](../../../../sql-exporter/fa/grafana.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Security NOC wallboard: fleet risk KPIs, per-server rollup, auth attack hotspots, privileged/unexpected sessions, surface/encryption/audit gaps, ownership and config snapshot. Deep dive: Collector security.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `sqlx-security-noc` |
| فایل منبع | [`sqlx-security-noc.json`](../../../../../grafana/dashboards/sql-exporter/sqlx-security-noc.json) |
| برچسب‌ها | `sql_exporter`, `mssql`, `security`, `noc` |
| تعداد پنل‌ها | 48 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_encryption_at_rest_enabled{job="sql_exporter", instance=~"${instance:regex}"}, db)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | NOC - Security Posture | `row` |
| 2 | Failed Logins (1h) | `stat` |
| 3 | Live sessions with sysadmin / securityadmin. | `stat` |
| 4 | Sessions outside collector allow-list. | `stat` |
| 5 | Instances where sa login is enabled. | `stat` |
| 6 | Surface Flags ON | `stat` |
| 7 | Orphans on primary/online DBs only. | `stat` |
| 8 | Audit Not Started | `stat` |
| 9 | Sessions with encrypt_option=FALSE. | `stat` |
| 10 | Servers with xp_cmdshell enabled. | `stat` |
| 11 | Servers with OLE Automation Procedures enabled. | `stat` |
| 12 | Linked RPC OUT | `stat` |
| 13 | SQL logins with expired password. | `stat` |
| 14 | DB Owner risk | `stat` |
| 15 | Job Owner risk | `stat` |
| 16 | Selected DBs without active/in-progress TDE. | `stat` |
| 17 | Latest Full/Diff/Log backup not encrypted. | `stat` |
| 18 | NOC - Fleet Triage | `row` |
| 19 | Per-Server Security Rollup | `table` |
| 20 | Risk Score - Top 15 servers | `bargauge` |
| 21 | NOC - Authentication Attacks | `row` |
| 22 | Failed Logins by Reason | `timeseries` |
| 23 | Security ERRORLOG Signals | `timeseries` |
| 24 | Failed - Top servers | `bargauge` |
| 25 | Failed - Top logins | `bargauge` |
| 26 | Failed - Top client hosts | `bargauge` |
| 27 | Failed Login Details (active) | `table` |
| 28 | NOC - Privileged & Unexpected Access | `row` |
| 29 | Privileged Sessions | `timeseries` |
| 30 | Unexpected Login Sessions | `timeseries` |
| 31 | Privileged Sessions - Now | `table` |
| 32 | Unexpected Logins - Now | `table` |
| 33 | NOC - Surface - Encryption - Audit Gaps | `row` |
| 34 | Surface & SA Flags | `table` |
| 35 | Linked Servers | `table` |
| 36 | Audit Runtime (problems) | `table` |
| 37 | TDE Gaps | `table` |
| 38 | Backup Encryption Gaps | `table` |
| 39 | Unencrypted TLS - Top servers | `bargauge` |
| 40 | TLS Sessions by Encrypt Option | `timeseries` |
| 41 | Password Expired SQL Logins | `table` |
| 42 | Orphaned Users (>0) | `table` |
| 43 | NOC - Ownership Hotspots | `row` |
| 44 | DB Owner is sysadmin | `table` |
| 45 | Agent Job Owner is sysadmin | `table` |
| 46 | NOC - Config Snapshot | `row` |
| 47 | Risky Config Matrix | `table` |
| 48 | Risky Surface (xp+OLE) - Top | `bargauge` |

ترکیب نوع پنل‌ها: `bargauge`: 6, `row`: 7, `stat`: 16, `table`: 14, `timeseries`: 5

## متریک‌های استفاده‌شده

- `mssql_agent_job_owner_is_sysadmin`
- `mssql_audit_status`
- `mssql_backup_encryption_enabled`
- `mssql_clr_enabled`
- `mssql_database_owner_is_sysadmin`
- `mssql_encryption_at_rest_enabled`
- `mssql_failed_logins_total`
- `mssql_linked_server_count`
- `mssql_linked_server_rpc_out_enabled`
- `mssql_login_password_expired`
- `mssql_ole_automation_enabled`
- `mssql_orphaned_users`
- `mssql_privileged_sessions`
- `mssql_sa_login_enabled`
- `mssql_security_configurations`
- `mssql_security_errorlog_signal_count`
- `mssql_tls_encryption_sessions`
- `mssql_unexpected_login_count`
- `mssql_up`
- `mssql_xp_cmdshell_enabled`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
