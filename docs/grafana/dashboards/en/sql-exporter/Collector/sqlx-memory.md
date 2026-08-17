# Collector memory

[Dashboard index](../../README.md) · [Grafana guide](../../../../../../grafana/README.md) · [فارسی](../../../fa/sql-exporter/Collector/sqlx-memory.md) · [Exporter documentation](../../../../../sql-exporter/en/grafana.md)

> This file is generated from the dashboard JSON; do not edit it manually.

Ops-first SQL memory: pending grants, live large-grant sessions (table), fleet triage, workspace pressure, breakdowns. Start at Investigate Now, then Fleet Triage. Collector: mssql_memory (60s).

## Details

| Property | Value |
|---|---|
| UID | `sqlx-memory` |
| Source file | [`sqlx-memory.json`](../../../../../../grafana/dashboards/sql-exporter/Collector/sqlx-memory.json) |
| Tags | `sql_exporter`, `mssql`, `collector`, `memory` |
| Panel count | 35 |
| Refresh interval | `1m` |
| Schema version | `39` |

## Dashboard variables

| Name | Label | Type | Query / value |
|---|---|---|---|
| `instance` | Server | `query` | `label_values(mssql_up{job="sql_exporter"}, instance)` |
| `db` | Database | `query` | `label_values(mssql_memory_active_grant_mb{job="sql_exporter", instance=~"$instance"}, db)` |
| `min_grant_mb` | Min Grant MB | `custom` | `100,512,1024,4096,8192` |

## Panels

| No. | Title | Type |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Pending Grants | `stat` |
| 3 | Fleet count with grant backlog. | `stat` |
| 4 | Sessions with grant >= Min Grant MB threshold. | `stat` |
| 5 | Largest live query memory grant right now. | `stat` |
| 6 | At Memory Cap | `stat` |
| 7 | Memory Waits | `stat` |
| 8 | Granted / Maximum workspace pool. | `stat` |
| 9 | Queries currently holding a memory grant. | `stat` |
| 10 | Investigate Now - who holds memory? | `row` |
| 11 | Largest Grants (top 15) | `bargauge` |
| 12 | Active Large Memory Grants | `table` |
| 13 | Large Grants by Server / Database | `table` |
| 14 | Memory Wait Sessions (RESOURCE_SEMAPHORE / CMEMTHREAD) | `table` |
| 15 | Fleet Triage - which servers? | `row` |
| 16 | Highest Memory Util % (top 15 servers) | `bargauge` |
| 17 | Most Large Grants by Server | `bargauge` |
| 18 | Memory Health by Server | `table` |
| 19 | Servers Needing Attention | `table` |
| 20 | Trends (server aggregates) | `row` |
| 21 | Memory Util % - worst servers | `timeseries` |
| 22 | Grants Pending | `timeseries` |
| 23 | Workspace Memory - Granted vs Max | `timeseries` |
| 24 | Large Grant Sessions (count) | `timeseries` |
| 25 | Breakdowns | `row` |
| 26 | Grant Total by Database | `table` |
| 27 | Grant Total by Login | `table` |
| 28 | Deep Dive - Memory Clerks | `row` |
| 29 | Top Clerk Types (MB, fleet aggregate) | `bargauge` |
| 30 | Top Clerks by Server | `table` |
| 31 | Deep Dive - Semaphore & Stolen | `row` |
| 32 | Semaphore Waiters | `timeseries` |
| 33 | Semaphore Granted MB | `timeseries` |
| 34 | Semaphore Available MB | `timeseries` |
| 35 | Stolen Server Memory | `timeseries` |

Panel type summary: `bargauge`: 4, `row`: 7, `stat`: 8, `table`: 8, `timeseries`: 8

## Metrics used

- `mssql_memory_active_grant_mb`
- `mssql_memory_clerk_size_kb`
- `mssql_memory_grants_outstanding`
- `mssql_memory_grants_pending`
- `mssql_memory_manager_mb`
- `mssql_memory_stolen_mb`
- `mssql_memory_target_server_mb`
- `mssql_memory_total_server_mb`
- `mssql_resource_semaphore_available_mb`
- `mssql_resource_semaphore_granted_mb`
- `mssql_resource_semaphore_waiter_count`
- `mssql_up`

## Usage

1. Import the source JSON file shown above into Grafana.
2. Select the datasource connected to Prometheus.
3. Set the dashboard variables for your environment.
