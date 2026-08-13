# mssql_replication

## Summary

- File: `collector/mssql_replication.collector.yml`
- collector_name: `mssql_replication`
- min_interval: `60s`
- metric count: `21`
- shared query_ref values: `mssql_repl_agent_jobs`, `mssql_repl_db_flags`, `mssql_repl_distributor_latency`, `mssql_repl_is_distributor`, `mssql_repl_logreader`, `mssql_repl_pending`, `mssql_repl_publications`, `mssql_repl_snapshot`, `mssql_repl_subscriptions`

## Purpose

- SQL Server Replication (Transactional Push / Pull)
- Covers instances that are Publisher, Subscriber, Distributor, or mixed
- (e.g. sql-pub-01 = Publisher+Subscriber Push; sql-sub-01 = Pull Subscriber).
- When distribution DB is local: agent latency, pending cmds, inventory.
- When only subscribed (remote distributor): DB flags + local pull-agent jobs.

## Permissions and prerequisites

- Base permissions: `VIEW SERVER STATE` and `VIEW ANY DEFINITION`.
- Special access: Read distribution when the instance is a Distributor.
- Notes from the source file:
  - When distribution DB is local: agent latency, pending cmds, inventory.
  - Permissions:
  - SELECT on distribution.* (if Distributor)

## How to use

- Enable this collector in the profile that matches the server type.
- On busy servers, run heavy collectors with care and longer intervals.
- If you add a new metric, test it on one instance before rollout.

## Metrics

| metric | type | labels / values | source | help |
|---|---|---|---|---|
| `mssql_replication_published_databases` | `gauge` | `db` | `is_published` | query_ref=`mssql_repl_db_flags` | 1 if database is published (sys.databases.is_published). |
| `mssql_replication_subscribed_databases` | `gauge` | `db` | `is_subscribed` | query_ref=`mssql_repl_db_flags` | 1 if database is subscribed (sys.databases.is_subscribed). |
| `mssql_replication_merge_published_databases` | `gauge` | `db` | `is_merge_published` | query_ref=`mssql_repl_db_flags` | 1 if database is merge-published. |
| `mssql_replication_is_distributor` | `gauge` | - | `is_distributor` | query_ref=`mssql_repl_is_distributor` | 1 if this instance hosts the distribution database. |
| `mssql_replication_publication` | `gauge` | `publisher`, `publisher_db`, `publication` | `info` | query_ref=`mssql_repl_publications` | 1 per transactional publication known to the local Distributor. |
| `mssql_replication_subscription` | `gauge` | `publisher`, `publisher_db`, `publication`, `subscriber`, `subscriber_db`, `subscription_type` | `info` | query_ref=`mssql_repl_subscriptions` | 1 per subscription. subscription_type: Push / Pull / Anonymous. |
| `mssql_replication_distributor_latency_seconds` | `gauge` | `publisher`, `publisher_db`, `publication`, `subscriber`, `subscriber_db`, `agent_name`, `subscription_type` | `latency_seconds` | query_ref=`mssql_repl_distributor_latency` | Latest Distribution Agent delivery_latency (seconds) from MSdistribution_history. |
| `mssql_replication_pending_commands` | `gauge` | `publisher`, `publisher_db`, `subscriber`, `subscriber_db`, `agent_name`, `subscription_type` | `UndelivCmdsInDistDB` | query_ref=`mssql_repl_pending` | Undelivered commands in distribution DB (MSdistribution_status). |
| `mssql_replication_distribution_delivered_commands` | `gauge` | `publisher_db`, `subscriber_db`, `agent_name`, `subscription_type` | `delivered_commands` | query_ref=`mssql_repl_distributor_latency` | Commands delivered in the latest Distribution Agent history row. |
| `mssql_replication_distribution_agent_status` | `gauge` | `publisher_db`, `subscriber_db`, `agent_name`, `subscription_type`, `status_desc` | `runstatus` | query_ref=`mssql_repl_distributor_latency` | Latest Distribution Agent runstatus (1=start 2=succeed 3=in progress 4=idle 5=retry 6=fail). |
| `mssql_replication_distribution_agent_last_run_age_seconds` | `gauge` | `publisher_db`, `subscriber_db`, `agent_name`, `subscription_type` | `last_run_age_seconds` | query_ref=`mssql_repl_distributor_latency` | Seconds since last Distribution Agent history entry. |
| `mssql_replication_logreader_latency_seconds` | `gauge` | `publisher`, `publisher_db`, `agent_name` | `latency_seconds` | query_ref=`mssql_repl_logreader` | Latest Log Reader Agent delivery_latency (seconds). |
| `mssql_replication_logreader_delivered_commands` | `gauge` | `publisher_db`, `agent_name` | `delivered_commands` | query_ref=`mssql_repl_logreader` | Commands delivered in the latest Log Reader history row. |
| `mssql_replication_logreader_agent_status` | `gauge` | `publisher_db`, `agent_name`, `status_desc` | `runstatus` | query_ref=`mssql_repl_logreader` | Latest Log Reader runstatus (1=start 2=succeed 3=in progress 4=idle 5=retry 6=fail). |
| `mssql_replication_logreader_agent_last_run_age_seconds` | `gauge` | `publisher_db`, `agent_name` | `last_run_age_seconds` | query_ref=`mssql_repl_logreader` | Seconds since last Log Reader history entry. |
| `mssql_replication_snapshot_agent_status` | `gauge` | `publisher_db`, `publication`, `agent_name`, `status_desc` | `runstatus` | query_ref=`mssql_repl_snapshot` | Latest Snapshot Agent runstatus (1=start 2=succeed 3=in progress 4=idle 5=retry 6=fail). |
| `mssql_replication_snapshot_agent_last_run_age_seconds` | `gauge` | `publisher_db`, `publication`, `agent_name` | `last_run_age_seconds` | query_ref=`mssql_repl_snapshot` | Seconds since last Snapshot Agent history entry. |
| `mssql_replication_agent_job_enabled` | `gauge` | `job_name`, `category_name`, `agent_role` | `is_enabled` | query_ref=`mssql_repl_agent_jobs` | 1 if replication-related SQL Agent job is enabled (local instance). |
| `mssql_replication_agent_job_last_run_status` | `gauge` | `job_name`, `category_name`, `agent_role`, `last_run_outcome_desc` | `last_run_outcome` | query_ref=`mssql_repl_agent_jobs` | Last SQL Agent run outcome for replication jobs (0=fail 1=succeed 2=retry 3=cancel 4=in progress; -1=never). |
| `mssql_replication_agent_job_last_run_age_seconds` | `gauge` | `job_name`, `category_name`, `agent_role` | `last_run_age_seconds` | query_ref=`mssql_repl_agent_jobs` | Seconds since last SQL Agent run of a replication job (-1 if never). |
| `mssql_replication_agent_job_running` | `gauge` | `job_name`, `category_name`, `agent_role` | `is_running` | query_ref=`mssql_repl_agent_jobs` | 1 if replication SQL Agent job is currently executing. |

## Operational notes

- `min_interval` prevents frequent execution of heavy queries.
- If the collector uses `query_ref`, several metrics share one query.
- Collectors with many labels are not suitable for high-cardinality use cases.
- If the feature does not exist on the instance, the output is usually empty and scrape should not fail.

