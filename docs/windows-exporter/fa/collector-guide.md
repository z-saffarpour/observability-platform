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
| `update` | آپدیت‌های در انتظار و تازگی جمع‌آوری اطلاعات | همه Profileها و نمونه ریشه |
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
  enabled: "cpu,memory,pagefile,logical_disk,physical_disk,net,os,service,system,time,update"
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

## Windows Update

در تنظیمات اصلی و تمام Profileهای کامل، Collector به نام `update` با تنظیم زیر فعال است:

```yaml
collector:
  update:
    online: false
    scrape_interval: 6h
```

اطلاعات محلی Windows Update هر شش ساعت خوانده می‌شود؛ جست‌وجوی آنلاین یا نصب آپدیت انجام نمی‌شود. تازگی اطلاعات محلی به سامانه مدیریت آپدیت سازمان وابسته است. این Collector در نسخه `0.31.8` آزمایشی است؛ پیش از انتشار، روی canary با حساب سرویس exporter و دسترسی به `wuauserv` بررسی شود. خطای initialization ممکن است مانع شروع exporter شود. این تغییر مخزن، تنظیمات سرورها را deploy یا سرویس‌ها را restart نمی‌کند.

| Metric | معنی |
|---|---|
| `windows_update_pending_info` | اطلاعات آپدیت در انتظار با labelهای `id`, `revision`, `category`, `severity`, `title` |
| `windows_update_pending_published_timestamp` | زمان انتشار به Unix seconds با labelهای `id`, `revision` |
| `windows_update_scrape_query_duration_seconds` | مدت آخرین query از Windows Update |
| `windows_update_scrape_timestamp_seconds` | زمان آخرین اطلاعات جمع‌آوری‌شده |

خروجی `/metrics` و `windows_exporter_collector_success{collector="update"}` را بررسی کنید. مقدار `time() - windows_update_scrape_timestamp_seconds` باید با فاصله شش‌ساعته و حاشیه عملیاتی مقایسه شود. ممکن است پس از شکست refresh، اطلاعات cache همچنان ارائه شود؛ موفقیت Collector به‌تنهایی تازگی داده را اثبات نمی‌کند. نبود سری pending تنها همراه با جمع‌آوری موفق و تازه می‌تواند به معنی نبود آپدیت شناخته‌شده باشد؛ داده missing یا stale را صفر نکنید. اطلاعات offline اثبات patch compliance نیست. تغییر title و revision موجب رشد و گردش سری‌ها می‌شود؛ labelهای هویتی را حفظ و برای خلاصه‌سازی بر اساس میزبان/category/severity تجمیع کنید.

Prometheus فعلی همه Collectorهای فعال را scrape می‌کند و نیاز به تغییر ندارد. برای سرورهای موجود، فایل تنظیمات فعال باید از مسیر مالک پیکربندی به‌روزرسانی شود؛ کپی Profile غیرفعال کافی نیست. برای rollback، از همان مسیر `update` و بلوک تنظیمات آن را از فایل فعال حذف کنید.

مراجع: [متریک‌های نسخه 0.31.8](https://github.com/prometheus-community/windows_exporter/blob/v0.31.8/docs/collector.update.md)، [تنظیمات و labelها در کد](https://github.com/prometheus-community/windows_exporter/blob/v0.31.8/internal/collector/update/update.go). کلید YAML برابر `scrape_interval` و گزینه CLI برابر `--collector.update.scrape-interval` است.
