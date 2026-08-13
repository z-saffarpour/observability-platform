# Alertmanager — routing اولویت‌دار (SMS و Email)

[English](../en/alertmanager.md)

کانفیگ نمونه برای Alertهایی که labelهای `priority`، `severity` و `alert_profile` دارند.

| اولویت | کانال‌ها | تکرار |
|---|---|---|
| **P0** | SMS (webhook) + Email | ۱۵ دقیقه |
| **P1** | Email + SMS (webhook) | ۱ ساعت |
| **P2** | فقط Email | ۱۲ ساعت |

فایل‌های کانفیگ در `alertmanager/sql-exporter/`:

| مسیر | کاربرد |
|---|---|
| `alertmanager.yml` | Route، receiver و inhibit |
| `templates/sql_exporter.tmpl` | قالب HTML ایمیل (+ helper متن SMS) |

کاتالوگ Alertها: [Alerting](alerting.md) · نصب ruleها: [Prometheus rules](prometheus-rules.md)

## اتصال به Prometheus

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "CHANGE_ME_ALERTMANAGER_HOST:9093"
```

## قبل از production

1. همهٔ مقادیر `CHANGE_ME_*` را عوض کنید (SMTP، گیرندگان ایمیل، URL گیت‌وی SMS).
2. Webhook مربوط به SMS را به gateway یا یک notifier کوچک که JSON Alertmanager را به SMS تبدیل می‌کند وصل کنید.
3. اعتبارسنجی:

```powershell
amtool check-config .\prometheus\alertmanager\alertmanager.yml
```

4. پس از استقرار، Alertmanager را reload کنید.

## نکات

- Alertmanager کانال SMS بومی ندارد؛ SMS از طریق `webhook_configs` ارسال می‌شود.
- برای غیرفعال‌کردن SMS در P1، بلوک `webhook_configs` زیر `email-sms-p1` را حذف کنید.
- Inhibit ruleها وقتی P0 یا `severity=critical` برای همان `alertname` + `instance` فعال است، اعلان‌های اولویت پایین‌تر را سرکوب می‌کنند.
- قالب `sms.sql_exporter.text` برای notifierهایی است که از template سمت Alertmanager استفاده می‌کنند؛ بسیاری از gatewayها فقط JSON webhook را parse می‌کنند.
