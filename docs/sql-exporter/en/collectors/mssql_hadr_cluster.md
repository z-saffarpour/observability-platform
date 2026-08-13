# mssql_hadr_cluster

## Summary

- File: `collector/mssql_hadr_cluster.collector.yml`
- collector_name: `mssql_hadr_cluster`
- min_interval: `30s`
- metric count: `11`
- shared query_ref values: `mssql_hadr_instance_flags`, `mssql_hadr_cluster`, `mssql_hadr_cluster_members`, `mssql_hadr_listeners`, `mssql_hadr_listener_ips`, `mssql_hadr_fci_nodes`
- Profiles: `oltp`, `dwh` (alongside `mssql_alwayson`)

## Purpose

Complements `mssql_alwayson` (replica lag / sync health) with cluster and listener signals:

- AG listener inventory (DNS name, port, conformant flag)
- Listener IP online / offline / pending / failed state
- WSFC quorum type and quorum state
- WSFC cluster member state and quorum votes
- FCI node status and current resource owner
- Instance flags: `IsClustered`, `IsHadrEnabled`

## Permissions and prerequisites

- `VIEW SERVER STATE`
- `VIEW ANY DEFINITION` (catalog views for listeners)

Empty-safe when AG / WSFC / FCI are absent: listener and cluster queries return no rows; instance flags still emit `0`/`1`.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_hadr_is_clustered` | `gauge` | — | `is_clustered` | query_ref=`mssql_hadr_instance_flags` | 1 if this SQL Server instance is a Failover Cluster Instance (SERVERPROPERTY IsClustered). |
| `mssql_hadr_is_hadr_enabled` | `gauge` | — | `is_hadr_enabled` | query_ref=`mssql_hadr_instance_flags` | 1 if Always On Availability Groups is enabled (SERVERPROPERTY IsHadrEnabled). |
| `mssql_hadr_cluster_quorum_state` | `gauge` | `cluster_name`, `quorum_type_desc`, `quorum_state_desc` | `quorum_state` | query_ref=`mssql_hadr_cluster` | WSFC quorum_state (0=unknown, 1=normal, 2=forced). |
| `mssql_hadr_cluster_quorum_type` | `gauge` | `cluster_name`, `quorum_type_desc`, `quorum_state_desc` | `quorum_type` | query_ref=`mssql_hadr_cluster` | WSFC quorum_type (0=node majority, 1=node+disk, 2=node+file share, 3=disk only, 4=unknown). |
| `mssql_hadr_cluster_member_state` | `gauge` | `cluster_name`, `member_name`, `member_type_desc`, `member_state_desc` | `member_state` | query_ref=`mssql_hadr_cluster_members` | WSFC member_state (0=unknown, 1=up, 2=down, 3=isolated). |
| `mssql_hadr_cluster_member_quorum_votes` | `gauge` | `cluster_name`, `member_name`, `member_type_desc`, `member_state_desc` | `number_of_quorum_votes` | query_ref=`mssql_hadr_cluster_members` | Quorum votes for this WSFC member. |
| `mssql_hadr_listener_info` | `gauge` | `availability_group_name`, `dns_name`, `ip_address`, `is_conformant` | `info` | query_ref=`mssql_hadr_listeners` | 1 per AG listener IP (inventory). |
| `mssql_hadr_listener_port` | `gauge` | `availability_group_name`, `dns_name`, `ip_address` | `port` | query_ref=`mssql_hadr_listeners` | TCP port of the AG listener. |
| `mssql_hadr_listener_ip_state` | `gauge` | `availability_group_name`, `dns_name`, `ip_address`, `state_desc`, `is_dhcp` | `ip_state` | query_ref=`mssql_hadr_listener_ips` | Listener IP state (0=ONLINE, 1=OFFLINE, 2=ONLINE_PENDING, 3=ONLINE_FAILED, -1=unknown/fallback). IP falls back to `ip_configuration_string_from_cluster` or `(dhcp)`/`(unknown)` when catalog IP is empty. |
| `mssql_hadr_fci_node_status` | `gauge` | `node_name`, `status_description` | `status` | query_ref=`mssql_hadr_fci_nodes` | FCI node status (0=up, 1=down, 2=paused, 3=joining, -1=unknown). |
| `mssql_hadr_fci_is_current_owner` | `gauge` | `node_name`, `status_description` | `is_current_owner` | query_ref=`mssql_hadr_fci_nodes` | 1 if this FCI node owns the SQL Server clustered resource. |

## Alerting notes

```promql
mssql_hadr_cluster_quorum_state != 1
mssql_hadr_cluster_member_state != 1
mssql_hadr_listener_ip_state != 0
mssql_hadr_fci_node_status != 0
mssql_hadr_is_hadr_enabled == 1 and mssql_hadr_listener_info == 0
```

The last expression is only useful as a recording/check when every AG is expected to have a listener; skip it for listener-less lab AGs.

## Operational notes

- Use together with `mssql_alwayson` for full HADR coverage (lag + listener/cluster).
- Grafana dashboard `sqlx-hadr-cluster`: **Server** dropdown includes every HADR/Always On host (not only WSFC `cluster_name`). Hosts without WSFC metadata appear in **HADR without WSFC cluster row** with a link to **AlwaysOn**.
- `min_interval` 30s is enough for quorum / listener state; failover detection still depends on scrape interval and Prometheus `for:`.
- Cardinality stays low (few listeners, few cluster members/nodes).
- Servers on **`core` profile** do not scrape `mssql_hadr_cluster` or `mssql_alwayson`; use `oltp`/`dwh` (or add those collectors) for AG hosts.
