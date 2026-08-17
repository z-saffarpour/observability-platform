# MCP Docker

سرویس‌های Docker Compose برای ارائه‌ی MCPهای Grafana و Prometheus از طریق HTTP.

نسخه انگلیسی: [README.md](./README.md)

## سرویس‌ها

| سرویس | آدرس |
|---|---|
| Grafana | `http://127.0.0.1:8101/mcp` |
| Prometheus | `http://127.0.0.1:8103/mcp` |

تمام پورت‌ها فقط روی loopback منتشر می‌شوند و از شبکه قابل دسترسی نیستند.

## راه‌اندازی با فایل env

```powershell
Set-Location 'D:\path\to\repository\mcp'
Copy-Item mcp-grafana.env.example mcp-grafana.env
```

مقادیر نمونه را در فایل‌های کپی‌شده جایگزین کنید، سپس اجرا کنید:

```powershell
docker compose -f docker-compose.mcp.yml config
docker compose -f docker-compose.mcp.yml up -d
docker compose -f docker-compose.mcp.yml ps
```

## راه‌اندازی با متغیرهای محیطی

برای دریافت تنظیمات از متغیرهای محیطی Process از `docker-compose.mcp.env.yml` استفاده کنید. متغیرهای ضروری مانیتورینگ عبارت‌اند از:

```text
GRAFANA_URL
GRAFANA_SERVICE_ACCOUNT_TOKEN
PROMETHEUS_URL
```

نبودن هر متغیر اجباری باعث می‌شود اعتبارسنجی Compose پیش از اجرا متوقف شود.

## تنظیم کلاینت MCP

```json
{
  "mcpServers": {
    "grafana": { "url": "http://127.0.0.1:8101/mcp" },
    "prometheus": { "url": "http://127.0.0.1:8103/mcp" }
  }
}
```

## عملیات

```powershell
docker compose -f docker-compose.mcp.yml logs -f grafana
docker compose -f docker-compose.mcp.yml logs -f prometheus
docker compose -f docker-compose.mcp.yml down
```

فایل‌های env تکمیل‌شده یا توکن‌های دسترسی را commit نکنید؛ فقط فایل‌های `*.env.example` باید وارد Git شوند.
