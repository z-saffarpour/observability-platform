# SSAS Fleet Overview

Import `grafana/dashboards/windows-exporter/winexp-00-ssas-fleet.json` using Grafana Dashboards > Import. The dashboard uses Prometheus datasource UID `ce0xqwhy35wqod`; change that UID in the JSON if importing elsewhere. This file has not been published to Grafana HQ.

The dashboard has 28 panels, including section headers and guidance. It provides fleet coverage KPIs, a complete discovered-server triage table, host CPU/RAM/disk pressure, SSAS memory/high-limit ratios, sessions, queues, lock waits, connection failures, processing flags and collector diagnostics. Server links open a focused fleet view or the existing SSAS details dashboard. No alert rules or collector configuration are changed.

## Inventory and missing data

Fleet charts now use horizontal Top 10 rankings of current values instead of overlapping time-series lines. The full fleet remains visible in the triage table. Job is hidden from every table but remains in query grouping. The Collector Age (s) column and its query were removed from the main triage table; collector age remains available in the dedicated diagnostics table. All 12 ranking queries were validated for a maximum of 10 results in descending order through Prometheus MCP. Historical chart validation below refers to the initial version.

- Inventory uses SSAS probe history and Windows SSAS service inventory over a fixed 24-hour window. It is not a complete expected-server inventory.
- Additional SSAS hosts (regex) can include known Prometheus targets without SSAS metrics. Default `^$` adds none. Example: `SSAS01|SSAS02`. Hosts with no target/history cannot be discovered this way.
- Filter by Job, Owner and Server. All and multi-selection use regex-safe interpolation. Additional hosts is intentionally a raw regex.
- Collector freshness defaults to 300 seconds and is selectable. Future timestamps, old embedded collector timestamps and failed scrapes exclude SSAS workload data. Gaps remain Unknown.
- Probe OK means connection success only. Collector errors can indicate incomplete metrics even when the connection succeeds. The triage table exposes those errors separately.
- Performance collector timestamps alone do not prove counter coverage. The coverage KPI additionally requires the memory usage alias. Other counter families may still be missing.

## Metric semantics

Host CPU uses rate of idle CPU seconds; RAM uses available and physical-total bytes. Disk free is the lowest percentage among drive-letter volumes; mounted-folder volumes are outside this panel. Memory/high-limit percentage is calculated per counter set before taking the worst value per server. SSAS memory KB is converted to bytes with 1024. Session, queue and lock totals aggregate across instances/counter sets. Cooked per-second counters are used directly, without another rate(). Collector errors are per-run gauges.

Processing flags use the collector's configured schedule threshold (repository default 24h); they are review candidates, not proof that every flagged model violated a business SLA. High-cardinality per-column metrics and login labels are not queried. Backup and restore readiness are not assessed.

## Validation on 2026-09-07

- JSON parsing, unique panel IDs and 24-column bounds checked locally.
- All 30 distinct panel expressions executed through Prometheus MCP. Changed probe/status and processing filters were rechecked after correcting operator grouping.
- CPU and SSAS memory/high-limit range queries checked over 30 minutes at 60-second steps.
- Live discovery found 17 servers, fewer than the user's stated fleet of more than 20. At the final probe check: 15 fresh successful probes, zero fresh failed probes and two Unknown/stale probes. These counts are a point-in-time observation, not a persisted inventory or an overall health assertion.
- Grafana import/rendering and interactive table transformations have not been tested on a live saved dashboard. Publishing requires separate authorization.

Triage color thresholds are defaults: CPU/RAM 80/90%, disk free 20/10%, SSAS high-limit ratio 85/100%. Tune them to workload; they do not create alerts.
