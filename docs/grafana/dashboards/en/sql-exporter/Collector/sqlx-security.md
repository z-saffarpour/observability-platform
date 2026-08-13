# Collector security

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-security.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

SQL Server security posture: auth failures, privileged/unexpected sessions, login hygiene, audit, ownership/orphans, encryption, surface area, and fleet rollup. Collector mssql_security @ 300s.

## Details

| Property | Value |
|---|---|
| UID | `sqlx-security` |
| Source file | [`sqlx-security.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-security.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `security` |
| Panel count | 63 |
| Refresh interval | `5m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_encryption_at_rest_enabled{job="sql_exporter", instance=~"${instance:regex}"}, db)` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Security Posture / KPI | `row` |
| 2 | Failed Logins (1h) | `stat` |
| 3 | Privileged Sessions | `stat` |
| 4 | Unexpected Sessions | `stat` |
| 5 | Instances where sa login is enabled. | `stat` |
| 6 | Surface Area ON | `stat` |
| 7 | Orphaned Users | `stat` |
| 8 | Audit Not Started | `stat` |
| 9 | Current sessions with encrypt_option=FALSE. | `stat` |
| 10 | Servers with xp_cmdshell enabled. | `stat` |
| 11 | Servers with Ole Automation Procedures enabled. | `stat` |
| 12 | CLR ON | `stat` |
| 13 | Priority Boost ON | `stat` |
| 14 | Remote Access ON | `stat` |
| 15 | Distributed transaction remote proc option. | `stat` |
| 16 | Recommended ON for plan-cache hygiene. | `stat` |
| 17 | Recommended ON for backup integrity. | `stat` |
| 18 | Authentication Failures | `row` |
| 19 | Failed Logins by Reason | `timeseries` |
| 20 | Security ERRORLOG Signals | `timeseries` |
| 21 | Failed Logins now - Top servers | `bargauge` |
| 22 | Failed Logins by Login - Top 15 | `bargauge` |
| 23 | Failed Logins by Client Host - Top 15 | `bargauge` |
| 24 | Failed Login Details | `table` |
| 25 | Privileged & Unexpected Access | `row` |
| 26 | Privileged Sessions by Login/Role | `timeseries` |
| 27 | Unexpected Login Sessions | `timeseries` |
| 28 | Privileged Sessions - Detail | `table` |
| 29 | Unexpected Logins - Detail | `table` |
| 30 | Login Hygiene | `row` |
| 31 | SA Login Enabled | `table` |
| 32 | SQL Auth Logins Enabled (count) | `table` |
| 33 | SQL Auth Logins - Top servers | `bargauge` |
| 34 | Disabled SQL Logins | `table` |
| 35 | Password Expired SQL Logins | `table` |
| 36 | SQL Server Audit | `row` |
| 37 | Server Audit Enabled | `table` |
| 38 | Audit Runtime Status | `table` |
| 39 | Audit Events (1h window) | `timeseries` |
| 40 | Audit Events Detail | `table` |
| 41 | Ownership, Permissions & Orphans | `row` |
| 42 | DB Owner is sysadmin | `table` |
| 43 | Agent Job Owner is sysadmin | `table` |
| 44 | Orphaned Users (count > 0) | `table` |
| 45 | Public Role Server Permissions | `table` |
| 46 | Agent Proxy Count | `bargauge` |
| 47 | Encryption (TDE / Backup / TLS) | `row` |
| 48 | TLS Sessions by Encrypt Option | `timeseries` |
| 49 | Unencrypted TLS Sessions - Top servers | `bargauge` |
| 50 | TDE Gaps (not encrypted) | `table` |
| 51 | Backup Encryption Gaps | `table` |
| 52 | TDE Status (all selected DBs) | `table` |
| 53 | Surface Area & Linked Servers | `row` |
| 54 | Surface Area Flags | `table` |
| 55 | Linked Servers | `table` |
| 56 | Security Configurations (sp_configure) | `row` |
| 57 | Configuration Matrix (per server) | `table` |
| 58 | Risky Configs ON - Top servers | `bargauge` |
| 59 | Configuration Values Over Time | `timeseries` |
| 60 | Configuration Inventory | `table` |
| 61 | Fleet Security Rollup | `row` |
| 62 | Per-Server Security Rollup | `table` |
| 63 | Hotspot - Failed Logins Top 20 | `table` |

Panel type summary: `bargauge`: 7, `row`: 10, `stat`: 16, `table`: 23, `timeseries`: 7

## Metrics used

- `mssql_agent_job_owner_is_sysadmin`
- `mssql_agent_proxy_count`
- `mssql_audit_events_total`
- `mssql_audit_status`
- `mssql_backup_encryption_enabled`
- `mssql_clr_enabled`
- `mssql_database_owner_is_sysadmin`
- `mssql_encryption_at_rest_enabled`
- `mssql_failed_logins_total`
- `mssql_linked_server_count`
- `mssql_linked_server_rpc_out_enabled`
- `mssql_login_disabled`
- `mssql_login_password_expired`
- `mssql_ole_automation_enabled`
- `mssql_orphaned_users`
- `mssql_privileged_sessions`
- `mssql_public_role_permissions`
- `mssql_sa_login_enabled`
- `mssql_security_configurations`
- `mssql_security_errorlog_signal_count`
- `mssql_server_audit_enabled`
- `mssql_sql_auth_logins_enabled`
- `mssql_tls_encryption_sessions`
- `mssql_unexpected_login_count`
- `mssql_up`
- `mssql_xp_cmdshell_enabled`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
