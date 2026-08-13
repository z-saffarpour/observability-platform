# راهنمای Collectorهای windows_exporter

[English](../en/collector-guide.md)

Collector فقط زمانی فعال شود که metricهای آن در dashboard، rule یا troubleshooting استفاده می‌شوند. collectorهای بیشتر به معنی scrape سنگین‌تر و cardinality بالاتر است.

برای production از فایل‌های [`profiles/`](profiles.md) استفاده کنید. فایل ریشه `windows_exporter.yml` نمونهٔ گسترده‌تری است و لزوماً با Profile پایه یکی نیست.

## Collectorهای استفاده‌شده در این پکیج

| Collector | کاربرد | کجا فعال است |
|---|---|---|
| `cpu` | زمان CPU بر اساس core و mode | همه Profileها |
| `memory` | حافظه available، committed و paging | همه Profileها |
| `pagefile` | مصرف Page File | Profileهای نقش‌محور |
| `logical_disk` | ظرفیت و فعالیت volumeها | همه Profileها |
| `physical_disk` | I/O و latency دیسک فیزیکی | همه Profileها |
| `net` | ترافیک، خطا و وضعیت NIC | همه Profileها |
| `tcp` | آمار TCP | اکثر Profileهای نقش‌محور |
| `os`, `system`, `time` | مشخصات OS، uptime و clock | همه Profileها |
| `service` | وضعیت Windows Service | همه Profileها |
| `process` | مصرف منابع پردازش‌ها | SQL / SSAS / PBIRS / Dynamics / data-platform |
| `terminal_services` | sessionهای RDP | `terminal-server.yml` (+ نمونه ریشه) |
| `license` | وضعیت license ویندوز | فقط در `windows_exporter.yml` نمونه؛ در Profileهای نقش نیست |
| `mssql` | Performance Counterهای SQL Server | `sql-server.yml` و `data-platform*.yml` |
| `textfile` | خواندن فایل‌های `.prom` محلی | `ssas.yml` و `data-platform*.yml` |
| `mscluster` | متریک‌های Windows Failover Cluster | `windows-cluster.yml` و `data-platform-cluster.yml` |

## انتخاب بر اساس نقش سرور

Profile پایه (`windows-base.yml`):

```yaml
collectors:
  enabled: "cpu,memory,pagefile,logical_disk,physical_disk,net,os,service,system,time"
```

برای SQL Server، `mssql` و معمولاً `process`/`tcp` را اضافه کنید (`sql-server.yml`). برای Session Host، `terminal_services` را اضافه کنید. برای SSAS یا نقش ترکیبی Data Platform، `textfile` باید فعال باشد و Scheduled Task متریک‌های `ssas_*` را در `textfile_inputs` بنویسد؛ جزئیات در [مانیتورینگ SSAS](ssas-monitoring.md). اگر SQL نصب نیست، فعال‌بودن `mssql` warning مربوط به registry SQL instance تولید می‌کند.

## فیلتر Service

```yaml
collector:
  service:
    include: "^(MSSQLSERVER|SQLSERVERAGENT|MSSQL\\$.+|SQLAgent\\$.+|SQLTELEMETRY.*)$"
```

regex روی نام واقعی سرویس اعمال می‌شود:

```powershell
Get-Service | Where-Object Name -Match 'SQL|TELEMETRY' | Select-Object Name,DisplayName,Status
```

## کنترل cardinality و زمان scrape

- برای `process` نام پردازش‌های مهم را include کنید.
- volume، NIC و diskهای غیرضروری را exclude کنید.
- `scrape_timeout` از بدترین زمان scrape بیشتر باشد.
- `windows_exporter_collector_duration_seconds` را baseline کنید.
- `windows_exporter_collector_success == 0` را alert کنید.

هر تغییر را ابتدا روی یک canary server تست و نام metricهای 0.31.8 را مستقیماً در `/metrics` تأیید کنید.
