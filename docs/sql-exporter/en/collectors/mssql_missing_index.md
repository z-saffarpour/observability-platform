# mssql_missing_index

## Summary

- File: `collector/mssql_missing_index.collector.yml`
- collector_name: `mssql_missing_index`
- min_interval: `600s`
- metric count: `11`
- shared query_ref values: `mssql_missing_index_top`, `mssql_missing_index_db`

## Purpose

- Missing index DMV sample (cardinality-capped TOP N) plus per-database rollup.
- Advisory only — validate before creating indexes (cost/impact/seeks are hints).
- Requires `VIEW SERVER STATE`.

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: user databases (object name resolution).

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, keep the long `min_interval` (default 600s).
- Use the Grafana dashboard action queue with Min Score / Min Impact filters before CREATE INDEX.
- Simple score (`mssql_missing_index_score`) stays compatible with existing alerts; `cost_score` uses the Microsoft-style formula after redeploy.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_missing_index_impact` | `gauge` | `db`, `schema_name`, `table_name`, `equality_columns`, `inequality_columns`, `included_columns` | `avg_user_impact` | avg_user_impact (%) for TOP suggestions |
| `mssql_missing_index_user_seeks` | `gauge` | same | `user_seeks` | user_seeks for TOP suggestions |
| `mssql_missing_index_user_scans` | `gauge` | same | `user_scans` | user_scans for TOP suggestions |
| `mssql_missing_index_score` | `gauge` | same | `improvement_score` | simple score = impact * (seeks + scans) |
| `mssql_missing_index_avg_cost` | `gauge` | same | `avg_total_user_cost` | avg_total_user_cost for TOP suggestions |
| `mssql_missing_index_unique_compiles` | `gauge` | same | `unique_compiles` | unique_compiles for TOP suggestions |
| `mssql_missing_index_cost_score` | `gauge` | same | `cost_score` | cost * impact * (seeks + scans) |
| `mssql_missing_index_db_suggestions` | `gauge` | `db` | `suggestion_count` | sampled suggestion count per DB |
| `mssql_missing_index_db_max_score` | `gauge` | `db` | `max_score` | max simple score per DB |
| `mssql_missing_index_db_sum_score` | `gauge` | `db` | `sum_score` | sum of simple scores per DB |
| `mssql_missing_index_db_max_impact` | `gauge` | `db` | `max_impact` | max avg_user_impact (%) per DB |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- Several metrics share one query via `query_ref`.
- Column labels are truncated to 80 chars to limit cardinality/label size.
- Empty object names are filtered out.
- If the DMV has no rows, output is empty and scrape should not fail.
