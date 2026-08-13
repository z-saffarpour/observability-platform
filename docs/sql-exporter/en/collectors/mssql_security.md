# mssql_security

## Summary

- File: `collector/mssql_security.collector.yml`
- collector_name: `mssql_security`
- min_interval: `300s`
- metric count: `25`
- shared query_ref values:
  `mssql_security_failed_logins`, `mssql_security_privileged_sessions`,
  `mssql_security_unexpected_logins`, `mssql_security_sql_auth_enabled`,
  `mssql_security_sa_enabled`, `mssql_security_sql_logins_state`,
  `mssql_security_server_audit_state`, `mssql_security_audit_events`,
  `mssql_security_db_owner_sysadmin`, `mssql_security_public_server_permissions`,
  `mssql_security_orphaned_users`, `mssql_security_agent_proxy_count`,
  `mssql_security_job_owner_sysadmin`, `mssql_security_tde_state`,
  `mssql_security_backup_encryption`, `mssql_security_tls_sessions`,
  `mssql_security_surface_area`, `mssql_security_linked_servers`

## Purpose

- Security posture monitoring for SQL Server instances using native catalog, DMV,
  SQL Agent metadata, encryption metadata, and audit/errorlog signals.
- Covers failed logins, privileged sessions, SQL login state, SQL Audit state,
  owner/permission hygiene, encryption controls, surface-area options, and
  linked-server exposure.
- Also includes security metrics moved from other collectors:
  - selected configuration flags from `mssql_standard`
  - login-related ERRORLOG security signals from `mssql_errorlog_signals`

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Optional:
  - `xp_readerrorlog` permission for `mssql_failed_logins_total`.
  - `CONTROL SERVER` for `mssql_audit_events_total` (reads audit files via
    `sys.fn_get_audit_file`).
- Notes from source file:
  - Collector is designed to return empty sets (not fail scrape) when optional
    features are unavailable or permissions are not granted.

## Dashboard

- Grafana dashboard: `grafana/dashboards/sql-exporter/Collector/sqlx-security.json` (deep investigation)
- NOC dashboard: `grafana/dashboards/sql-exporter/sqlx-security-noc.json` (fleet wallboard: KPI + rollup + hotspots)

## How to use

- Enable this collector in the profile that matches the server type (typically
  `profiles/security-audit.yml`).
- Keep `min_interval` at `300s` or higher on very busy servers.
- **Before alerting on `mssql_unexpected_login_count`, configure the allow-list**
  (see next section). The default list only covers built-in accounts; every
  application login will appear as “unexpected” until you add it.

## Allow-list for `mssql_unexpected_login_count`

This metric counts **current user sessions** whose `login_name` is not on the
allow-list. It is **not** stored in a separate config file — you edit the SQL
CTE inline in the collector YAML.

| Item | Value |
|---|---|
| File | `collector/mssql_security.collector.yml` |
| Query | `mssql_security_unexpected_logins` |
| Metric | `mssql_unexpected_login_count` |

### What is already excluded

- Exact matches in the CTE: `sa`, `NT AUTHORITY\SYSTEM`,
  `NT SERVICE\SQLSERVERAGENT`, `NT SERVICE\MSSQLSERVER`
- Any login matching `NT SERVICE\%` or `NT AUTHORITY\%` (LIKE filter in the
  query)

### How to add site-specific logins

Add one line per allowed login inside the `allowlist` CTE:

```sql
;WITH allowlist AS (
    SELECT N'sa' AS login_name
    UNION ALL SELECT N'NT AUTHORITY\SYSTEM'
    UNION ALL SELECT N'NT SERVICE\SQLSERVERAGENT'
    UNION ALL SELECT N'NT SERVICE\MSSQLSERVER'
    -- Site-specific (uncomment and edit):
    UNION ALL SELECT N'MyAppUser'
    UNION ALL SELECT N'DOMAIN\sql_monitor'
    UNION ALL SELECT N'reporting_svc'
)
```

### Rules

1. **Exact name** — must match `sys.dm_exec_sessions.login_name` (e.g. Windows
   logins as `DOMAIN\user`).
2. **No wildcards in the CTE** — only exact `UNION ALL SELECT N'...'` rows; broad
   exclusions use the existing `NOT LIKE` patterns above.
3. **Reload required** — after editing the YAML, reload or restart sql_exporter
   (`-web.enable-reload` or service restart).
4. **Review regularly** — when new apps connect to SQL Server, add their service
   accounts here or alerts will fire on every legitimate session.

To discover current login names:

```sql
SELECT DISTINCT login_name
FROM sys.dm_exec_sessions
WHERE is_user_process = 1 AND login_name IS NOT NULL
ORDER BY login_name;
```

See also: [mssql_security (FA)](../../fa/collectors/mssql_security.md#allow-list-برای-mssql_unexpected_login_count).

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_failed_logins_total` | `gauge` | `login_name`, `client_host`, `reason` | `event_count` | query_ref=`mssql_security_failed_logins` | Failed login rows parsed from ERRORLOG in the last 60 minutes, grouped by login/client/reason. |
| `mssql_privileged_sessions` | `gauge` | `login_name`, `host_name`, `program_name`, `server_role` | `session_count` | query_ref=`mssql_security_privileged_sessions` | Current user sessions whose login is member of sysadmin or securityadmin. |
| `mssql_unexpected_login_count` | `gauge` | `login_name` | `session_count` | query_ref=`mssql_security_unexpected_logins` | Current user sessions with login names outside the inline allow-list CTE in this collector. |
| `mssql_sql_auth_logins_enabled` | `gauge` | (none) | `enabled_count` | query_ref=`mssql_security_sql_auth_enabled` | Number of enabled SQL-authentication logins (type_desc = SQL_LOGIN). |
| `mssql_security_configurations` | `gauge` | `config_name` | `cntr_value` | query_ref=`mssql_security_configurations` | Selected security/behavior configuration values moved from mssql_standard. |
| `mssql_sa_login_enabled` | `gauge` | (none) | `is_enabled` | query_ref=`mssql_security_sa_enabled` | 1 if sa login is enabled; 0 otherwise. |
| `mssql_login_disabled` | `gauge` | `login_name` | `is_disabled` | query_ref=`mssql_security_sql_logins_state` | 1 if SQL login is disabled. |
| `mssql_login_password_expired` | `gauge` | `login_name` | `is_password_expired` | query_ref=`mssql_security_sql_logins_state` | 1 if SQL login password is expired. |
| `mssql_server_audit_enabled` | `gauge` | `audit_name` | `is_enabled` | query_ref=`mssql_security_server_audit_state` | 1 if SQL Server Audit object is enabled. |
| `mssql_audit_status` | `gauge` | `audit_name`, `status_desc` | `status` | query_ref=`mssql_security_server_audit_state` | Audit runtime status from dm_server_audit_status (1=started). |
| `mssql_audit_events_total` | `gauge` | `action_id`, `principal_name`, `database_name` | `event_count` | query_ref=`mssql_security_audit_events` | Audit event rows in the last 60 minutes grouped by action/principal/database (requires CONTROL SERVER). |
| `mssql_security_errorlog_signal_count` | `gauge` | `signal` | `event_count` | query_ref=`mssql_security_errorlog_signals` | Security-specific ERRORLOG signal count in the last 6 hours (failed/disabled/anonymous login). |
| `mssql_database_owner_is_sysadmin` | `gauge` | `db`, `owner_login` | `is_sysadmin_owner` | query_ref=`mssql_security_db_owner_sysadmin` | 1 when database owner login is member of sysadmin. |
| `mssql_public_role_permissions` | `gauge` | `permission_name`, `state_desc` | `permission_count` | query_ref=`mssql_security_public_server_permissions` | Count of granted server-level permissions for public role. |
| `mssql_orphaned_users` | `gauge` | `db` | `orphan_count` | query_ref=`mssql_security_orphaned_users` | Orphaned users per online user database (INSTANCE-authenticated principals without matching server login SID). Skips Always On / HADR secondaries and standby DBs (`fn_hadr_is_primary_replica=1` only) to avoid false positives. |
| `mssql_agent_proxy_count` | `gauge` | (none) | `proxy_count` | query_ref=`mssql_security_agent_proxy_count` | Number of SQL Agent proxies defined in msdb. |
| `mssql_agent_job_owner_is_sysadmin` | `gauge` | `job_name`, `owner_login` | `is_sysadmin_owner` | query_ref=`mssql_security_job_owner_sysadmin` | 1 when SQL Agent job owner is member of sysadmin. |
| `mssql_encryption_at_rest_enabled` | `gauge` | `db` | `is_encrypted` | query_ref=`mssql_security_tde_state` | 1 when database encryption key is present and encryption_state indicates active/in-progress TDE. |
| `mssql_backup_encryption_enabled` | `gauge` | `db`, `backup_type` | `is_encrypted` | query_ref=`mssql_security_backup_encryption` | 1 when the most recent Full/Diff/Log backup is encrypted. |
| `mssql_tls_encryption_sessions` | `gauge` | `encrypt_option` | `session_count` | query_ref=`mssql_security_tls_sessions` | Current session count by encrypt_option from dm_exec_connections. |
| `mssql_xp_cmdshell_enabled` | `gauge` | (none) | `is_enabled` | query_ref=`mssql_security_surface_area` | 1 if xp_cmdshell is enabled. |
| `mssql_ole_automation_enabled` | `gauge` | (none) | `ole_automation_enabled` | query_ref=`mssql_security_surface_area` | 1 if OLE Automation Procedures is enabled. |
| `mssql_clr_enabled` | `gauge` | (none) | `clr_enabled` | query_ref=`mssql_security_surface_area` | 1 if CLR integration is enabled. |
| `mssql_linked_server_count` | `gauge` | (none) | `linked_server_count` | query_ref=`mssql_security_linked_servers` | Count of configured linked servers (excluding local server entry). |
| `mssql_linked_server_rpc_out_enabled` | `gauge` | (none) | `rpc_out_enabled_count` | query_ref=`mssql_security_linked_servers` | Count of linked servers with RPC OUT enabled. |

## Operational notes

- Keep cardinality controlled:
  - If failed-login labels become high-cardinality, aggregate by reason or
    trim labels in dashboards/alerts.
  - Keep `unexpected_login` allow-list aligned with your service-account policy.
- `mssql_orphaned_users` intentionally skips AG secondary / standby databases;
  evaluate orphans on the primary replica where instance logins are authoritative.
- Recommended alert candidates:
  - `mssql_sa_login_enabled > 0`
  - `mssql_xp_cmdshell_enabled > 0`
  - sudden rise in `mssql_failed_logins_total`
  - `mssql_audit_status != 1` for enabled audits
