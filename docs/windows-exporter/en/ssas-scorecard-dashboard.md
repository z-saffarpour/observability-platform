# SSAS Fleet Scorecard

Import `grafana/dashboards/windows-exporter/winexp-00-ssas-scorecard.json` into Grafana. Prometheus datasource UID: `ce0xqwhy35wqod`. The dashboard is a local artifact and has not been published or visually rendered in Grafana.

Five fleet KPI cards, one complete server status matrix, one numeric evidence table and a rule legend provide the scorecard. There are no overlapping time-series charts. Job and Collector Age columns are not displayed. Server links open SSAS Fleet Overview.

## Status model

Each of 12 checks returns one value per discovered job/server: 0 = OK, 1 = Review, 2 = Unknown, 3 = Critical. The overall status is the maximum across named checks, so a known Critical condition takes priority over missing evidence. Unknown prevents an overall OK. This is a transparent triage classification, not a weighted score or an SLA.

| Check | Review | Critical |
| --- | --- | --- |
| Probe / scrape | — | Fresh probe failure / failed scrape |
| Core / performance collector | Errors > 0 | — |
| CPU / RAM | >= 80% | >= 90% |
| Disk free (drive-letter volumes) | < 20% | < 10% |
| SSAS memory / high limit | >= 85% | >= 100% |
| Queues / lock waits / long sessions | > 0 | — |
| Processing stale database count | > 0 | — |

Thresholds are triage defaults; queue activity and long sessions may be expected. Processing thresholds come from collector configuration. No alert rules are created.

Inventory uses a fixed 24h history of SSAS metrics and SSAS Windows services, plus user-specified additional host regex. It cannot account for hosts never present in Prometheus. Workload queries use the existing fleet freshness and scrape checks. Missing metrics yield an explicit Unknown status. Collector errors can indicate partial data, and an overall Review is not proof of completeness. Backup or restore readiness is outside this scorecard.

## Validation

On 2026-09-07 all 12 check queries and the overall query returned 17 server rows through Prometheus MCP. The observed overall distribution was 12 Review, 4 Unknown and 1 Critical; this is a changing snapshot. All five KPI queries were also executed. JSON parsing, unique IDs, grid bounds and non-overlapping layout passed. Live Grafana import, display and interactive transformations remain unverified.

Queries use only existing metrics and do not require new recording rules. The overall query expands all 12 checks; on much larger fleets consider authorized recording rules after measuring query cost. The current refresh is one minute.
