# mssql_security

خلاصه

- فایل: `collector/mssql_security.collector.yml`
- collector_name: `mssql_security`
- min_interval: `300s`
- تعداد metric: `25`
- query_refهای مشترک:
  `mssql_security_failed_logins`, `mssql_security_privileged_sessions`,
  `mssql_security_unexpected_logins`, `mssql_security_sql_auth_enabled`,
  `mssql_security_sa_enabled`, `mssql_security_sql_logins_state`,
  `mssql_security_server_audit_state`, `mssql_security_audit_events`,
  `mssql_security_db_owner_sysadmin`, `mssql_security_public_server_permissions`,
  `mssql_security_orphaned_users`, `mssql_security_agent_proxy_count`,
  `mssql_security_job_owner_sysadmin`, `mssql_security_tde_state`,
  `mssql_security_backup_encryption`, `mssql_security_tls_sessions`,
  `mssql_security_surface_area`, `mssql_security_linked_servers`

هدف و کاربرد

- پایش وضعیت امنیتی SQL Server با استفاده از DMVها، کاتالوگ سیستمی، اطلاعات
  SQL Agent، متادیتای رمزنگاری، SQL Audit و ERRORLOG.
- پوشش fail شدن login، نشست‌های privileged، وضعیت loginهای SQL، سلامت Audit،
  بهداشت owner/permission، رمزنگاری، تنظیمات surface area و linked server.
- همچنین متریک‌های امنیتی منتقل‌شده از collectorهای دیگر را شامل می‌شود:
  - بخشی از تنظیمات امنیت/رفتار از `mssql_standard`
  - سیگنال‌های امنیتی login از `mssql_errorlog_signals`

مجوزها و پیش‌نیازها

- مجوز پایه: `VIEW SERVER STATE` و `VIEW ANY DEFINITION`.
- اختیاری:
  - دسترسی `xp_readerrorlog` برای `mssql_failed_logins_total`.
  - دسترسی `CONTROL SERVER` برای `mssql_audit_events_total` (خواندن فایل audit
    با `sys.fn_get_audit_file`).
- نکته: در نبود قابلیت یا مجوز اختیاری، خروجی معمولاً خالی می‌ماند و scrape
  نباید fail شود.

داشبورد

- داشبورد Grafana: `grafana/dashboards/sql-exporter/Collector/sqlx-security.json` (بررسی عمیق)
- داشبورد NOC: `grafana/dashboards/sql-exporter/sqlx-security-noc.json` (wallboard ناوگان: KPI + رولاپ + هات‌اسپات)

## نحوه استفاده

- این collector را در profile متناسب با نوع سرور فعال کن (معمولاً
  `profiles/security-audit.yml`).
- روی سرورهای بسیار شلوغ، `min_interval` را `300s` یا بیشتر نگه دار.
- **قبل از آلرت روی `mssql_unexpected_login_count` حتماً allow-list را تنظیم
  کن** (بخش بعد). لیست پیش‌فرض فقط اکانت‌های built-in را پوشش می‌دهد؛ تا login
  اپلیکیشن را اضافه نکنید، همه نشست‌ها «unexpected» گزارش می‌شوند.

## Allow-list برای `mssql_unexpected_login_count`

این متریک **نشست‌های کاربری جاری** را می‌شمارد که `login_name` آن‌ها در
allow-list نیست. تنظیم در فایل config جداگانه نیست — مستقیم داخل query در YAML
collector ویرایش می‌شود.

| مورد | مقدار |
|---|---|
| فایل | `collector/mssql_security.collector.yml` |
| Query | `mssql_security_unexpected_logins` |
| متریک | `mssql_unexpected_login_count` |

### چه چیزهایی از قبل حذف می‌شوند

- تطابق دقیق در CTE: `sa`, `NT AUTHORITY\SYSTEM`,
  `NT SERVICE\SQLSERVERAGENT`, `NT SERVICE\MSSQLSERVER`
- هر login مطابق `NT SERVICE\%` یا `NT AUTHORITY\%` (فیلتر LIKE در query)

### افزودن loginهای محیط اپلیکیشن

برای هر login مجاز یک خط داخل CTEی `allowlist` اضافه کن:

```sql
;WITH allowlist AS (
    SELECT N'sa' AS login_name
    UNION ALL SELECT N'NT AUTHORITY\SYSTEM'
    UNION ALL SELECT N'NT SERVICE\SQLSERVERAGENT'
    UNION ALL SELECT N'NT SERVICE\MSSQLSERVER'
    -- مخصوص محیط (کامنت را بردار و ویرایش کن):
    UNION ALL SELECT N'MyAppUser'
    UNION ALL SELECT N'DOMAIN\sql_monitor'
    UNION ALL SELECT N'reporting_svc'
)
```

### نکات مهم

1. **نام دقیق** — باید با `sys.dm_exec_sessions.login_name` یکی باشد (Windows:
   `DOMAIN\user`).
2. **wildcard در CTE نیست** — فقط `UNION ALL SELECT N'...'`؛ حذف گسترده با
   `NOT LIKE`های موجود انجام می‌شود.
3. **بعد از ویرایش YAML** — sql_exporter را reload یا restart کن
   (`-web.enable-reload` یا ری‌استارت سرویس).
4. **به‌روز نگه دار** — با هر اپ/سرویس جدید، login آن را اضافه کن وگرنه آلرت
   کاذب می‌گیری.

برای دیدن loginهای فعلی:

```sql
SELECT DISTINCT login_name
FROM sys.dm_exec_sessions
WHERE is_user_process = 1 AND login_name IS NOT NULL
ORDER BY login_name;
```

مرجع انگلیسی: [mssql_security (EN)](../../en/collectors/mssql_security.md#allow-list-for-mssql_unexpected_login_count).

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_failed_logins_total` | `gauge` | `login_name`, `client_host`, `reason` | `event_count` | query_ref=`mssql_security_failed_logins` | تعداد رخدادهای login ناموفق از ERRORLOG در 60 دقیقه اخیر به تفکیک کاربر/کلاینت/دلیل. |
| `mssql_privileged_sessions` | `gauge` | `login_name`, `host_name`, `program_name`, `server_role` | `session_count` | query_ref=`mssql_security_privileged_sessions` | نشست‌های کاربری جاری که عضو sysadmin یا securityadmin هستند. |
| `mssql_unexpected_login_count` | `gauge` | `login_name` | `session_count` | query_ref=`mssql_security_unexpected_logins` | تعداد نشست‌های جاری loginهایی که در allow-list داخلی query نیستند. |
| `mssql_sql_auth_logins_enabled` | `gauge` | (none) | `enabled_count` | query_ref=`mssql_security_sql_auth_enabled` | تعداد SQL Loginهای فعال. |
| `mssql_security_configurations` | `gauge` | `config_name` | `cntr_value` | query_ref=`mssql_security_configurations` | مقادیر تنظیمات امنیت/رفتار منتقل‌شده از `mssql_standard`. |
| `mssql_sa_login_enabled` | `gauge` | (none) | `is_enabled` | query_ref=`mssql_security_sa_enabled` | اگر `sa` فعال باشد 1. |
| `mssql_login_disabled` | `gauge` | `login_name` | `is_disabled` | query_ref=`mssql_security_sql_logins_state` | اگر SQL Login غیرفعال باشد 1. |
| `mssql_login_password_expired` | `gauge` | `login_name` | `is_password_expired` | query_ref=`mssql_security_sql_logins_state` | اگر پسورد SQL Login منقضی باشد 1. |
| `mssql_server_audit_enabled` | `gauge` | `audit_name` | `is_enabled` | query_ref=`mssql_security_server_audit_state` | اگر شیء SQL Server Audit فعال باشد 1. |
| `mssql_audit_status` | `gauge` | `audit_name`, `status_desc` | `status` | query_ref=`mssql_security_server_audit_state` | وضعیت runtime از dm_server_audit_status (مقدار 1 = started). |
| `mssql_audit_events_total` | `gauge` | `action_id`, `principal_name`, `database_name` | `event_count` | query_ref=`mssql_security_audit_events` | تعداد رخدادهای Audit در 60 دقیقه اخیر به تفکیک action/principal/database. |
| `mssql_security_errorlog_signal_count` | `gauge` | `signal` | `event_count` | query_ref=`mssql_security_errorlog_signals` | تعداد سیگنال‌های امنیتی ERRORLOG در ۶ ساعت اخیر (login fail/disabled/anonymous). |
| `mssql_database_owner_is_sysadmin` | `gauge` | `db`, `owner_login` | `is_sysadmin_owner` | query_ref=`mssql_security_db_owner_sysadmin` | اگر owner دیتابیس عضو sysadmin باشد 1. |
| `mssql_public_role_permissions` | `gauge` | `permission_name`, `state_desc` | `permission_count` | query_ref=`mssql_security_public_server_permissions` | تعداد permissionهای server-level اعطا شده به role `public`. |
| `mssql_orphaned_users` | `gauge` | `db` | `orphan_count` | query_ref=`mssql_security_orphaned_users` | تعداد کاربر orphaned در هر دیتابیس آنلاین کاربری. دیتابیس‌های Secondary در Always On / HADR و standby رد می‌شوند (`fn_hadr_is_primary_replica=1`) تا false positive نیاید. |
| `mssql_agent_proxy_count` | `gauge` | (none) | `proxy_count` | query_ref=`mssql_security_agent_proxy_count` | تعداد proxyهای SQL Agent. |
| `mssql_agent_job_owner_is_sysadmin` | `gauge` | `job_name`, `owner_login` | `is_sysadmin_owner` | query_ref=`mssql_security_job_owner_sysadmin` | اگر owner job عضو sysadmin باشد 1. |
| `mssql_encryption_at_rest_enabled` | `gauge` | `db` | `is_encrypted` | query_ref=`mssql_security_tde_state` | اگر TDE دیتابیس فعال/در حال فعال‌سازی باشد 1. |
| `mssql_backup_encryption_enabled` | `gauge` | `db`, `backup_type` | `is_encrypted` | query_ref=`mssql_security_backup_encryption` | اگر آخرین Full/Diff/Log backup رمزنگاری شده باشد 1. |
| `mssql_tls_encryption_sessions` | `gauge` | `encrypt_option` | `session_count` | query_ref=`mssql_security_tls_sessions` | تعداد نشست‌ها به تفکیک encrypt_option. |
| `mssql_xp_cmdshell_enabled` | `gauge` | (none) | `is_enabled` | query_ref=`mssql_security_surface_area` | اگر xp_cmdshell فعال باشد 1. |
| `mssql_ole_automation_enabled` | `gauge` | (none) | `ole_automation_enabled` | query_ref=`mssql_security_surface_area` | اگر OLE Automation Procedures فعال باشد 1. |
| `mssql_clr_enabled` | `gauge` | (none) | `clr_enabled` | query_ref=`mssql_security_surface_area` | اگر CLR integration فعال باشد 1. |
| `mssql_linked_server_count` | `gauge` | (none) | `linked_server_count` | query_ref=`mssql_security_linked_servers` | تعداد linked serverهای تعریف‌شده (به‌جز local). |
| `mssql_linked_server_rpc_out_enabled` | `gauge` | (none) | `rpc_out_enabled_count` | query_ref=`mssql_security_linked_servers` | تعداد linked serverهایی که RPC OUT آن‌ها فعال است. |

## نکات عملکرد

- برای کنترل cardinality:
  - اگر labelهای failed login زیاد شد، روی dashboard/alert به شکل aggregate
    مصرف شود.
  - allow-list را با policy اکانت‌های سرویس هماهنگ نگه دارید.
- `mssql_orphaned_users` دیتابیس‌های Secondary در AG / standby را رد می‌کند؛
  orphan را روی Primary ارزیابی کنید که loginهای instance معتبرند.
- Alert پیشنهادی:
  - `mssql_sa_login_enabled > 0`
  - `mssql_xp_cmdshell_enabled > 0`
  - جهش ناگهانی در `mssql_failed_logins_total`
  - `mssql_audit_status != 1` برای auditهای فعال
