# mssql_certificates

## Summary

- File: `collector/mssql_certificates.collector.yml`
- collector_name: `mssql_certificates`
- min_interval: `300s`
- metric count: `2`
- shared query_ref values: `mssql_certificate_expiry`, `mssql_tde_encryption_state`
- Profiles: `security-audit`

## Purpose

- Certificate expiry (days until `expiry_date`) across online user databases.
- TDE `encryption_state` from `sys.dm_database_encryption_keys`.

## Permissions and prerequisites

- `VIEW ANY DEFINITION`, `VIEW SERVER STATE`
- Empty-safe when no certificates / no TDE keys exist.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_certificate_expiry_days` | `gauge` | `db`, `certificate`, `subject` | `expiry_days` | Days until certificate expiry (negative = already expired). |
| `mssql_tde_encryption_state` | `gauge` | `db` | `encryption_state` | TDE encryption_state (0–6). |
