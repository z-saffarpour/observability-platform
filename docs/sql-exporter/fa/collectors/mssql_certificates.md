# mssql_certificates

## Summary

- File: `collector/mssql_certificates.collector.yml`
- collector_name: `mssql_certificates`
- min_interval: `300s`
- metric count: `2`
- shared query_ref values: `mssql_certificate_expiry`, `mssql_tde_encryption_state`
- Profiles: `security-audit`

## Purpose

- روز تا انقضای certificate در دیتابیس‌های آنلاین user.
- وضعیت TDE از `sys.dm_database_encryption_keys`.

## Permissions and prerequisites

- `VIEW ANY DEFINITION`, `VIEW SERVER STATE`
- در نبود certificate / کلید TDE خروجی خالی و scrape سالم است.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_certificate_expiry_days` | `gauge` | `db`, `certificate`, `subject` | `expiry_days` | روز تا انقضای certificate (منفی = منقضی شده). |
| `mssql_tde_encryption_state` | `gauge` | `db` | `encryption_state` | وضعیت رمزنگاری TDE (0–6). |
