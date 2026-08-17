# Collector terminal_services

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/windows-exporter/collector/winexp-col-terminal-services.md) · [مستندات فارسی Exporter](../../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Remote Desktop / session host health: session counts by state and per-session resource usage. Disconnected sessions that never reap are the usual culprit.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-col-terminal-services` |
| فایل منبع | [`winexp-col-terminal-services.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-terminal-services.json) |
| برچسب‌ها | `windows_exporter`, `collector`, `terminal_services` |
| تعداد پنل‌ها | 31 |
| بازهٔ تازه‌سازی | `1m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `job` | Job | `query` | `label_values(windows_exporter_build_info, job)` |
| `instance` | Server | `query` | `label_values(windows_exporter_build_info{job=~"${job:regex}"}, instance)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | Health / KPI | `row` |
| 2 | Scrape FAIL | `stat` |
| 3 | Active Sessions | `stat` |
| 4 | Disconnected Sessions | `stat` |
| 5 | Total Sessions | `stat` |
| 6 | Hosts > 50 Sessions | `stat` |
| 7 | Max Sessions on a Host | `stat` |
| 8 | Session Memory | `stat` |
| 9 | Session CPU (cores) | `stat` |
| 10 | Max Session Handles | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Most Sessions (topk 15) | `bargauge` |
| 13 | Most Disconnected Sessions (topk 15) | `bargauge` |
| 14 | Highest Session Memory (topk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | Session Host Health | `table` |
| 17 | Hotspot: Many Disconnected Sessions | `table` |
| 18 | Sessions by State | `table` |
| 19 | Trends | `row` |
| 20 | Sessions by State (fleet) | `timeseries` |
| 21 | Total Sessions (topk 10) | `timeseries` |
| 22 | Session Memory (topk 10) | `timeseries` |
| 23 | Session CPU cores (topk 10) | `timeseries` |
| 24 | Deep Dive | `row` |
| 25 | Session Handles & Threads (topk 10) | `timeseries` |
| 26 | Private Bytes (topk 10) | `timeseries` |
| 27 | Disconnected Sessions (topk 10) | `timeseries` |
| 28 | Collector scrape health | `row` |
| 29 | Scrape Health by Host | `table` |
| 30 | Scrape Duration (topk 10) | `timeseries` |
| 31 | Scrape Success (bottomk 10) | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 4, `timeseries`: 9

## متریک‌های استفاده‌شده

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_terminal_services_handles`
- `windows_terminal_services_private_bytes`
- `windows_terminal_services_processor_time_seconds_total`
- `windows_terminal_services_session_info`
- `windows_terminal_services_threads`
- `windows_terminal_services_working_set_bytes`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
