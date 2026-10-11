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
- زبان متن SMS در `sms-gateway.json` با `language` انتخاب می‌شود: `en` یا `fa`. اگر کلید نباشد، متن انگلیسی می‌ماند. در حالت `fa` برچسب‌های پیام فارسی است و annotation با نام `summary_fa` به‌جای `summary` استفاده می‌شود. ruleهای SQL Exporter و Windows Exporter مقدار `summary_fa` دارند. نام alert، نام سرور و نام دیتابیس انگلیسی می‌مانند. تغییر زبان بعد از ری‌استارت gateway اعمال می‌شود. annotation جدید بعد از reload کردن Prometheus به Alertmanager می‌رسد.
- گروه‌بندی پیش‌فرض `[owner, priority, alertname, instance, db, job]` است. اعلانِ دارای label `db` برای هر سرور و دیتابیس جدا می‌رود. اعلان سطح سرور که `db` ندارد همچنان با هم گروه می‌شود. مسیر Filegroup علاوه بر این، `filegroup` را هم جدا می‌کند.
- Inhibit ruleها وقتی P0 یا `severity=critical` برای همان `alertname` + `instance` + `db` فعال است، اعلان‌های اولویت پایین‌تر را سرکوب می‌کنند. یک دیتابیس، دیتابیس دیگر روی همان سرور را سرکوب نمی‌کند.
- مسیریابی گیرنده بر اساس label `owner` است. `FMR-DBA`، `OK-DBA`، `FMR-BI-Develop` و `OK-BI-Develop` هر کدام mailbox و webhook جدا دارند. P0 و P1 همچنان SMS دارند و P2 فقط Email است. owner ناشناخته به receiver مشترک می‌رود.
- هر owner می‌تواند چند شماره SMS داشته باشد. در `sms-gateway.json` مقدار `phones` آرایه‌ای از رشته است، یا یک رشته با شماره‌های جدا شده با کاما. رشته تکی همچنان معتبر است. مقدار `CHANGE_ME` نادیده گرفته می‌شود. gateway برای همان owner یک درخواست `BatchSendSms` با همه شماره‌ها می‌فرستد. بعد از تغییر شماره‌ها gateway را ری‌استارت کنید.
- هر owner می‌تواند چند ایمیل داشته باشد. آدرس‌ها را در فیلد `to` همان owner با کاما جدا کنید، مثلاً `"a@example.com, b@example.com"`. همین فهرست را در receiverهای P0 و P1 و P2 تکرار کنید. بعد از تغییر، Alertmanager را reload کنید.
- قالب `sms.sql_exporter.text` برای notifierهایی است که از template سمت Alertmanager استفاده می‌کنند؛ بسیاری از gatewayها فقط JSON webhook را parse می‌کنند.
