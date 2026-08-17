# پلتفرم مانیتورینگ و مشاهده‌پذیری

**فارسی** | [English](README.en.md)

این مخزن، اجزای مانیتورینگ زیرساخت ویندوز و Microsoft SQL Server را با Prometheus، Grafana و Alertmanager در یک ساختار یکپارچه نگه‌داری می‌کند. زبان پیش‌فرض مستندات فارسی است.

## اجزای پروژه

| مسیر | کاربرد |
|---|---|
| [`exporters/sql-exporter/`](exporters/sql-exporter/) | باینری، تنظیمات، پروفایل‌ها و collectorهای SQL Exporter |
| [`exporters/windows-exporter/`](exporters/windows-exporter/) | باینری، تنظیمات و پروفایل‌های Windows Exporter |
| [`prometheus/`](prometheus/) | scrape configها، recording ruleها و alert ruleها، تفکیک‌شده بر اساس exporter |
| [`grafana/dashboards/`](grafana/dashboards/) | داشبوردهای Grafana برای SQL و Windows Exporter |
| [`alertmanager/`](alertmanager/) | تنظیمات و templateهای Alertmanager برای هر exporter |
| [`scripts/`](scripts/) | اسکریپت‌های PowerShell، SQL و SSAS برای نصب، ارتقا و عملیات |
| [`deployment/`](deployment/) | ابزارها و دارایی‌های استقرار ویندوز |
| [`mcp/`](mcp/) | اجرای MCP Serverهای Grafana و Microsoft SQL Server با Docker Compose |
| [`docs/`](docs/) | مستندات کامل فارسی و انگلیسی |
| [`tests/`](tests/) | تست‌ها و کنترل‌های صحت پروژه |

## شروع سریع

بسته به هدف، از یکی از مسیرهای زیر شروع کنید:

- SQL Server: [مستندات فارسی SQL Exporter](docs/sql-exporter/fa/README.md)
- Windows و سرویس‌های مبتنی بر ویندوز: [مستندات فارسی Windows Exporter](docs/windows-exporter/fa/README.md)
- اتصال ابزارهای هوشمند به Grafana و SQL Server: [راهنمای فارسی MCP](mcp/README.fa.md)

فایل‌های اجرایی و تنظیمات هر exporter در `exporters/<exporter>/` قرار دارند، اما اسکریپت‌های عملیاتی در `scripts/` و تنظیمات سامانه‌های مرکزی در `prometheus/`، `grafana/` و `alertmanager/` نگه‌داری می‌شوند. فرمان‌ها را از ریشهٔ مخزن اجرا کنید، مگر اینکه در راهنمای مربوط خلاف آن ذکر شده باشد.

## مستندات

- [فهرست مستندات SQL Exporter](docs/sql-exporter/README.md)
- [فهرست مستندات Windows Exporter](docs/windows-exporter/README.md)
- [راهنمای Prometheus](prometheus/README.md)
- [راهنمای Grafana](grafana/README.md)

قبل از استقرار، نسخهٔ exporter، دسترسی‌های حساب سرویس، پورت‌ها، آدرس مقصد Prometheus و اطلاعات محرمانه را با محیط خود تطبیق دهید. فایل‌های نمونهٔ `.env` را کپی کنید و فایل حاوی secret واقعی را commit نکنید.
