# Alertmanager — priority routing (SMS and Email)

[فارسی](../fa/alertmanager.md)

Sample config for alerts that carry `priority`, `severity`, and `alert_profile` labels.

| Priority | Channels | Repeat |
|---|---|---|
| **P0** | SMS webhook + Email | 15m |
| **P1** | Email + SMS webhook | 1h |
| **P2** | Email only | 12h |

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
- Inhibit rules drop lower-priority duplicates when a matching P0/critical alert is already firing for the same `alertname` + `instance`.
- The `sms.sql_exporter.text` template helps notifiers that render Alertmanager templates; many gateways only parse the webhook JSON.
