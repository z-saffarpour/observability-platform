# Collector textfile

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/windows-exporter/collector/winexp-col-textfile.md) · [مستندات فارسی Exporter](../../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Textfile collector payloads (SSAS metrics pushed by the PowerShell collectors). Verifies the pipeline is alive and surfaces SSAS sessions, queries and memory.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-col-textfile` |
| فایل منبع | [`winexp-col-textfile.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-textfile.json) |
| برچسب‌ها | `windows_exporter`, `collector`, `textfile` |
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
| 3 | SSAS Down | `stat` |
| 4 | Service Not Running | `stat` |
| 5 | Collector Errors | `stat` |
| 6 | Processing Failures | `stat` |
| 7 | Total Sessions | `stat` |
| 8 | Total Connections | `stat` |
| 9 | Max Memory | `stat` |
| 10 | Fleet Query/s | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Top SSAS Memory (topk 15) | `bargauge` |
| 13 | Most Sessions (topk 15) | `bargauge` |
| 14 | Highest Query Rate (topk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | SSAS Health by Host | `table` |
| 17 | Hotspot: SSAS Down or Erroring | `table` |
| 18 | Hotspot: Heaviest SSAS Hosts | `table` |
| 19 | Trends | `row` |
| 20 | SSAS Up (bottomk 10) | `timeseries` |
| 21 | Sessions & Connections (topk 10) | `timeseries` |
| 22 | Query Rate (topk 10) | `timeseries` |
| 23 | SSAS Memory (topk 10) | `timeseries` |
| 24 | Deep Dive | `row` |
| 25 | Collector Errors (topk 10) | `timeseries` |
| 26 | Processing Failures (topk 10) | `timeseries` |
| 27 | SSAS Metric Detail by Counter Set | `table` |
| 28 | Collector scrape health | `row` |
| 29 | Scrape Health by Host | `table` |
| 30 | Scrape Duration (topk 10) | `timeseries` |
| 31 | Scrape Success (bottomk 10) | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 6, `stat`: 9, `table`: 5, `timeseries`: 8

## متریک‌های استفاده‌شده

- `ssas_collector_errors`
- `ssas_connections`
- `ssas_memory_usage_kilobytes`
- `ssas_processing_failures_total`
- `ssas_query_rate`
- `ssas_service_running`
- `ssas_sessions`
- `ssas_up`
- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
