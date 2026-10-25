# Alertmanager — priority routing (SMS and Email)

[فارسی](../fa/alertmanager.md)

Sample config for alerts that carry `priority`, `severity`, and `alert_profile` labels.

| Priority | Channels | Repeat |
|---|---|---|
| **P0** | SMS webhook + Email | 15m |
| **P1** | Email + SMS webhook | 1h |
| **P2** | Email only | 12h |
| **P3** | None; the alert stays in the alert list | — |

Config files live under `alertmanager/sql-exporter/`:

| Path | Purpose |
|---|---|
| `alertmanager.yml` | Routes, receivers, inhibit rules |
| `templates/sql_exporter.tmpl` | Email HTML (+ SMS text helper) |

Alert catalog: [Alerting](alerting.md) · Rule install: [Prometheus rules](prometheus-rules.md)

## Wire Prometheus

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "CHANGE_ME_ALERTMANAGER_HOST:9093"
```

## Before go-live

1. Replace every `CHANGE_ME_*` value (SMTP, email recipients, SMS webhook URL).
2. Point the SMS webhook at your gateway or a small notifier that turns Alertmanager JSON into SMS.
3. Validate:

```powershell
amtool check-config .\prometheus\alertmanager\alertmanager.yml
```

4. Reload Alertmanager after deploy.

## Notes

- Alertmanager has no built-in SMS transport; SMS goes through `webhook_configs`.
- To disable SMS on P1, remove the `webhook_configs` block under `email-sms-p1`.
- SMS wording is selected in `sms-gateway.json` with `language`: `en` or `fa`. A missing key keeps English. `fa` uses Persian field labels and the `summary_fa` annotation. SQL Exporter and Windows Exporter alert rules include `summary_fa`. Alert names, server names, and database names stay in English. Restart the gateway after changing the language. Reload Prometheus after the rule change so new annotations reach Alertmanager.
- The default group is `[owner, priority, alertname, instance, db, job]`. An alert that has a `db` label notifies once per server and database. Server-level alerts with no `db` label still group together. Filegroup routes also split on `filegroup`.
- Inhibit rules drop lower-priority duplicates when a matching P0/critical alert is already firing for the same `alertname` + `instance` + `db`. One database does not suppress another database on the same server.
- Receivers are selected by the `owner` label. `FMR-DBA`, `OK-DBA`, `FMR-BI-Develop`, and `OK-BI-Develop` each have their own mailbox and SMS webhook. P0 and P1 still send SMS; P2 stays email only. P3 matches the empty receiver `none` before any owner route, so it stays in the alert list and sends nothing. An unknown owner uses the shared receivers.
- One owner can have several SMS numbers. In `sms-gateway.json`, `phones` is a JSON array of strings, or one comma-separated string. A single string still works. `CHANGE_ME` entries are skipped. The gateway sends one `BatchSendSms` request with every number for that owner. Restart the gateway after changing numbers.
- One owner can have several email addresses. Separate them with commas in that owner's `to` field, for example `"a@example.com, b@example.com"`. Repeat the same list on the P0, P1, and P2 receivers. Reload Alertmanager after the change.
- The `sms.sql_exporter.text` template helps notifiers that render Alertmanager templates; many gateways only parse the webhook JSON.
