# Collector license

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/windows-exporter/collector/winexp-col-license.md) · [مستندات فارسی Exporter](../../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Windows activation state across the fleet. Non-genuine or offline activation blocks patching and support.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-col-license` |
| فایل منبع | [`winexp-col-license.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-license.json) |
| برچسب‌ها | `windows_exporter`, `collector`, `license` |
| تعداد پنل‌ها | 25 |
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
| 3 | Not Genuine | `stat` |
| 4 | Genuine | `stat` |
| 5 | Offline Activation | `stat` |
| 6 | Tampered | `stat` |
| 7 | Invalid Licence | `stat` |
| 8 | Hosts Reporting | `stat` |
| 9 | Fleet Ranking (now) | `row` |
| 10 | Hosts by Licence State | `bargauge` |
| 11 | Non-genuine Flags per Host (topk 15) | `bargauge` |
| 12 | Fleet Snapshot & Hotspots | `row` |
| 13 | Hotspot: Hosts Not Genuine | `table` |
| 14 | Licence Status Matrix | `table` |
| 15 | Activation State with OS Build | `table` |
| 16 | Trends | `row` |
| 17 | Non-genuine Hosts (fleet) | `timeseries` |
| 18 | Licence States (fleet composition) | `timeseries` |
| 19 | Deep Dive | `row` |
| 20 | Offline / Tampered / Invalid (fleet) | `timeseries` |
| 21 | Per-host Flag Detail | `table` |
| 22 | Collector scrape health | `row` |
| 23 | Scrape Health by Host | `table` |
| 24 | Scrape Duration (topk 10) | `timeseries` |
| 25 | Scrape Success (bottomk 10) | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 2, `row`: 6, `stat`: 7, `table`: 5, `timeseries`: 5

## متریک‌های استفاده‌شده

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_license_status`
- `windows_os_info`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
