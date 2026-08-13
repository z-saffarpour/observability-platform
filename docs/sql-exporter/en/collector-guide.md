# Collector authoring guide for `sql_exporter`

This guide is for new team members who want to add a collector or modify an existing one.

## Goal of a collector

Each collector should solve one clear problem:
- instance health
- performance
- Always On
- backup / restore
- waits / blocking
- tempdb / file I/O
- jobs and maintenance

Key principle:
- Keep each collector small, readable, and maintainable.
- If a metric belongs to another collector, do not duplicate it.

## File structure

Each file in `collector/` is an independent collector:

```yaml
collector_name: mssql_example
min_interval: 60s

metrics:
  - metric_name: mssql_example_value
    type: gauge
    help: 'Example metric'
    values: [value]
    query: |
      SELECT CAST(1 AS float) AS value;
```

### Important fields

- `collector_name`: must match the file name.
- `min_interval`: minimum execution interval. Use a higher value for heavy queries.
- `metrics`: list of metrics.
- `metric_name`: Prometheus metric name.
- `type`: usually `gauge` or `counter`.
- `help`: short, precise description.
- `key_labels`: labels that separate series.
- `values`: numeric output columns.
- `value_label`: when one query returns multiple values of the same type and you want them as a label.
- `static_value`: when a metric only carries labels and has a fixed value.
- `query`: the main query.
- `query_ref`: when several metrics share one query.

## Recommended design pattern

### 1) Organize collectors by topic

Examples:
- `mssql_standard` for base signals
- `mssql_memory` for memory
- `mssql_tempdb` for tempdb
- `mssql_file_io` for I/O
- `mssql_alwayson` for AG

### 2) Keep metrics at the right level

Avoid highly cardinal metrics:
- `query_text`
- `session_id`
- `plan_handle`
- open/unbounded labels

### 3) Use `query_ref` for shared metrics

If multiple metrics are produced from the same CTE or query, define the query once and link metrics to it with `query_ref`.

This pattern is used in `mssql_alwayson`, where several metrics come from the shared `mssql_alwayson_pair` query.

### 4) Use `counter` or derived rates for time-based signals

Examples:
- deadlocks
- job failures
- log growth

### 5) Use `gauge` for instantaneous signals

Examples:
- lag
- queue size
- tempdb usage
- memory pressure

## Naming rules

Common pattern:

```text
mssql_<area>_<signal>_<unit>
```

Examples:
- `mssql_memory_target_server_mb`
- `mssql_tempdb_waiting_tasks_count`
- `mssql_file_io_read_latency_p95_ms`
- `mssql_alwayson_secondary_lag_seconds`

## Quality checklist

Before adding a new metric, answer:

- Is this useful for alerting or troubleshooting?
- Is it duplicated elsewhere?
- Is the cardinality controlled?
- Is `min_interval` appropriate?
- Can it run safely on a busy server?

## Pre-merge checklist

- File name and `collector_name` match.
- Metric names are clear and consistent.
- Labels are limited and meaningful.
- Queries do not fail on an empty instance.
- The collector does not overlap with existing profiles.
- `min_interval` matches query cost.

## Common mistakes

- Putting a heavy query in `mssql_standard`
- Creating metrics with too many labels
- Using vague names like `value1` and `value2`
- Mixing multiple responsibilities in one collector
- Forgetting to set `help`

## Suggested first steps for new contributors

If you are new to the team:
1. Read [README.md](../README.md) first.
2. Open a simple collector such as `mssql_standard`.
3. Add one small, low-risk metric.
4. Test it through `/metrics`.
5. Then move on to heavier collectors.

