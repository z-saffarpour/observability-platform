# Collector pagefile

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/windows-exporter/collector/winexp-col-pagefile.md) · [مستندات فارسی Exporter](../../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Pagefile headroom. A shrinking Free % with active swap traffic means the host is about to fail allocations - resize the pagefile or reclaim RAM.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-col-pagefile` |
| فایل منبع | [`winexp-col-pagefile.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-pagefile.json) |
| برچسب‌ها | `windows_exporter`, `collector`, `pagefile` |
| تعداد پنل‌ها | 26 |
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
| 3 | Free < 10% | `stat` |
| 4 | Free < 15% | `stat` |
| 5 | Min Free % | `stat` |
| 6 | Median Free % | `stat` |
| 7 | Max Used % | `stat` |
| 8 | Swapping Hosts | `stat` |
| 9 | Fleet Pagefile Size | `stat` |
| 10 | Fleet Ranking (now) | `row` |
| 11 | Lowest Free % (bottomk 15) | `bargauge` |
| 12 | Highest Swap Ops/s (topk 15) | `bargauge` |
| 13 | Fleet Snapshot & Hotspots | `row` |
| 14 | Pagefile Health by Host | `table` |
| 15 | Hotspots: Free % < 15 | `table` |
| 16 | Trends | `row` |
| 17 | Pagefile Free % (bottomk 10) | `timeseries` |
| 18 | Pagefile Used Bytes (topk 10) | `timeseries` |
| 19 | Swap Page Reads / Writes per second (topk 10) | `timeseries` |
| 20 | Deep Dive | `row` |
| 21 | Commit % vs Pagefile Free % (topk 10) | `timeseries` |
| 22 | Pagefile Capacity Detail | `table` |
| 23 | Collector scrape health | `row` |
| 24 | Scrape Health by Host | `table` |
| 25 | Scrape Duration (topk 10) | `timeseries` |
| 26 | Scrape Success (bottomk 10) | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 2, `row`: 6, `stat`: 8, `table`: 4, `timeseries`: 6

## متریک‌های استفاده‌شده

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_memory_commit_limit`
- `windows_memory_committed_bytes`
- `windows_memory_physical_total_bytes`
- `windows_memory_swap_page_operations_total`
- `windows_memory_swap_page_reads_total`
- `windows_memory_swap_page_writes_total`
- `windows_os_paging_free_bytes`
- `windows_os_paging_limit_bytes`
- `windows_pagefile_free_bytes`
- `windows_pagefile_limit_bytes`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
