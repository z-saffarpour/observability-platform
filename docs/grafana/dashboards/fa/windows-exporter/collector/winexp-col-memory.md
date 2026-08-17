# Collector memory

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/windows-exporter/collector/winexp-col-memory.md) · [مستندات فارسی Exporter](../../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Memory pressure: available vs commit, paging and swap activity, kernel pool growth and cache composition. Low Available % plus rising page faults means the host is trimming working sets.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-col-memory` |
| فایل منبع | [`winexp-col-memory.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-memory.json) |
| برچسب‌ها | `windows_exporter`, `collector`, `memory` |
| تعداد پنل‌ها | 35 |
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
| 3 | Available < 10% | `stat` |
| 4 | Available < 15% | `stat` |
| 5 | Commit > 85% | `stat` |
| 6 | Min Available % | `stat` |
| 7 | Median Available % | `stat` |
| 8 | Max Commit % | `stat` |
| 9 | Faults > 5k/s | `stat` |
| 10 | Fleet RAM | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Lowest Available % (bottomk 15) | `bargauge` |
| 13 | Highest Commit % (topk 15) | `bargauge` |
| 14 | Highest Page Faults/s (topk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | Memory Health by Host | `table` |
| 17 | Hotspots: Available < 15% | `table` |
| 18 | Hotspots: Commit > 85% | `table` |
| 19 | Trends | `row` |
| 20 | Available % (bottomk 10) | `timeseries` |
| 21 | Commit % (topk 10) | `timeseries` |
| 22 | Page Faults/s (topk 10) | `timeseries` |
| 23 | Swap Read / Write per second (topk 10) | `timeseries` |
| 24 | Kernel Pool Bytes (topk 10) | `timeseries` |
| 25 | Cache Composition (fleet totals) | `timeseries` |
| 26 | Deep Dive | `row` |
| 27 | Free System Page Table Entries (bottomk 10) | `timeseries` |
| 28 | Demand Zero Faults/s (topk 10) | `timeseries` |
| 29 | Transition Faults/s (topk 10) | `timeseries` |
| 30 | Cache Faults/s (topk 10) | `timeseries` |
| 31 | Memory Composition Detail | `table` |
| 32 | Collector scrape health | `row` |
| 33 | Scrape Health by Host | `table` |
| 34 | Scrape Duration (topk 10) | `timeseries` |
| 35 | Scrape Success (bottomk 10) | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 5, `timeseries`: 12

## متریک‌های استفاده‌شده

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_memory_available_bytes`
- `windows_memory_cache_bytes`
- `windows_memory_cache_faults_total`
- `windows_memory_commit_limit`
- `windows_memory_committed_bytes`
- `windows_memory_demand_zero_faults_total`
- `windows_memory_free_and_zero_page_list_bytes`
- `windows_memory_free_system_page_table_entries`
- `windows_memory_modified_page_list_bytes`
- `windows_memory_page_faults_total`
- `windows_memory_physical_total_bytes`
- `windows_memory_pool_nonpaged_bytes`
- `windows_memory_pool_paged_bytes`
- `windows_memory_standby_cache_core_bytes`
- `windows_memory_standby_cache_normal_priority_bytes`
- `windows_memory_standby_cache_reserve_bytes`
- `windows_memory_swap_page_operations_total`
- `windows_memory_swap_page_reads_total`
- `windows_memory_swap_page_writes_total`
- `windows_memory_system_cache_resident_bytes`
- `windows_memory_transition_faults_total`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
