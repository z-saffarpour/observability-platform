# Collector os

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/windows-exporter/collector/winexp-col-os.md) · [مستندات فارسی Exporter](../../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

OS inventory and OS-level resource limits: build/version spread, process and handle headroom, paging and virtual memory. Inventory first, pressure second.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-col-os` |
| فایل منبع | [`winexp-col-os.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-os.json) |
| برچسب‌ها | `windows_exporter`, `collector`, `os` |
| تعداد پنل‌ها | 33 |
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
| 3 | OS Builds | `stat` |
| 4 | Hosts | `stat` |
| 5 | Process Headroom < 20% | `stat` |
| 6 | Max Processes | `stat` |
| 7 | Max Users | `stat` |
| 8 | Min Paging Free % | `stat` |
| 9 | Virtual Free < 10% | `stat` |
| 10 | Fleet Visible Memory | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Most Processes (topk 15) | `bargauge` |
| 13 | Most Logged-on Users (topk 15) | `bargauge` |
| 14 | Lowest Paging Free % (bottomk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | OS Inventory | `table` |
| 17 | OS Resource Limits by Host | `table` |
| 18 | Hotspots: Paging Free % < 20 | `table` |
| 19 | Trends | `row` |
| 20 | Process Count (topk 10) | `timeseries` |
| 21 | Process Limit Used % (topk 10) | `timeseries` |
| 22 | Logged-on Users (topk 10) | `timeseries` |
| 23 | Paging Free % (bottomk 10) | `timeseries` |
| 24 | Physical / Virtual Free Bytes (bottomk 10) | `timeseries` |
| 25 | Deep Dive | `row` |
| 26 | Hostname & Domain | `table` |
| 27 | Timezone | `table` |
| 28 | OS Clock Skew vs Prometheus (topk 10) | `timeseries` |
| 29 | Process Memory Limit (bottomk 10) | `timeseries` |
| 30 | Collector scrape health | `row` |
| 31 | Scrape Health by Host | `table` |
| 32 | Scrape Duration (topk 10) | `timeseries` |
| 33 | Scrape Success (bottomk 10) | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 6, `timeseries`: 9

## متریک‌های استفاده‌شده

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_os_hostname`
- `windows_os_info`
- `windows_os_paging_free_bytes`
- `windows_os_paging_limit_bytes`
- `windows_os_physical_memory_free_bytes`
- `windows_os_process_memory_limit_bytes`
- `windows_os_processes`
- `windows_os_processes_limit`
- `windows_os_time`
- `windows_os_timezone`
- `windows_os_users`
- `windows_os_virtual_memory_bytes`
- `windows_os_virtual_memory_free_bytes`
- `windows_os_visible_memory_bytes`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
