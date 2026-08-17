# mssql_autogrowth

## Summary

- File: `collector/mssql_autogrowth.collector.yml`
- collector_name: `mssql_autogrowth`
- min_interval: `300s`
- metric count: `8`
- shared query_ref values: `mssql_autogrowth_events`, `mssql_autogrowth_total`

## Purpose

- Data/Log autogrowth and shrink events from the default trace (last 24h).
- Includes event counts, grown/shrunk MB (pages × 8 KB), avg/max duration, and age of last event.
- Empty when default trace is disabled.

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE`.
- Notes from the source file:
  - GRANT VIEW SERVER STATE TO

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- Grafana: `grafana/dashboards/sql-exporter/Collector/sqlx-autogrowth.json` (`sqlx-autogrowth`).
- Pair with `mssql_database_space` for growth *settings* (percent growth, increment size, pct of max).

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_autogrowth_events_24h` | `gauge` | `db`, `file_name`, `event_type` | `event_count` | Autogrowth/shrink events in default trace (last 24h) by db/file/event. |
| `mssql_autogrowth_growth_mb_24h` | `gauge` | `db`, `file_name`, `event_type` | `growth_mb` | Total MB grown/shrunk (pages×8KB) last 24h by db/file/event. |
| `mssql_autogrowth_avg_duration_ms_24h` | `gauge` | `db`, `file_name`, `event_type` | `avg_duration_ms` | Average growth/shrink duration (ms) last 24h. |
| `mssql_autogrowth_max_duration_ms_24h` | `gauge` | `db`, `file_name`, `event_type` | `max_duration_ms` | Max growth/shrink duration (ms) last 24h. |
| `mssql_autogrowth_last_age_seconds` | `gauge` | `db`, `file_name`, `event_type` | `age_seconds` | Seconds since last event per db/file/event. |
| `mssql_autogrowth_total_24h` | `gauge` | - | `event_count` | Total data+log autogrowth events (92/93) last 24h. |
| `mssql_autogrowth_shrink_total_24h` | `gauge` | - | `shrink_count` | Total data+log shrink events (94/95) last 24h. |
| `mssql_autogrowth_growth_mb_total_24h` | `gauge` | - | `growth_mb` | Total MB from data+log autogrowth last 24h. |

### event_type values

| value | EventClass | meaning |
|---|---|---|
| `data_growth` | 92 | Data file autogrowth |
| `log_growth` | 93 | Log file autogrowth |
| `data_shrink` | 94 | Data file shrink |
| `log_shrink` | 95 | Log file shrink |

## Operational notes

- `min_interval` prevents frequent execution of heavy `fn_trace_gettable` scans.
- High event counts (especially `log_growth`) usually mean tiny growth increments, percent growth, or log backup / VLF pressure — check the Config Risks row on the dashboard.
- New MB/duration metrics appear after exporters reload this collector YAML.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.
