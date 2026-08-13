# Collector logon

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/windows-exporter/collector/winexp-col-logon.md) · [مستندات فارسی Exporter](../../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Logon activity by type. Spikes in network or remote-interactive logons are useful for capacity and for security triage.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-col-logon` |
| فایل منبع | [`winexp-col-logon.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-logon.json) |
| برچسب‌ها | `windows_exporter`, `collector`, `logon` |
| تعداد پنل‌ها | 27 |
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
| 3 | Total Logon Sessions | `stat` |
| 4 | Interactive | `stat` |
| 5 | Network | `stat` |
| 6 | Service / Batch | `stat` |
| 7 | Clear-text Logons | `stat` |
| 8 | Max Interactive on a Host | `stat` |
| 9 | Hosts Reporting | `stat` |
| 10 | Fleet Ranking (now) | `row` |
| 11 | Most Logon Sessions (topk 15) | `bargauge` |
| 12 | Most Interactive Sessions (topk 15) | `bargauge` |
| 13 | Logons by Type (fleet) | `bargauge` |
| 14 | Fleet Snapshot & Hotspots | `row` |
| 15 | Logon Profile by Host | `table` |
| 16 | Logon Types Detail | `table` |
| 17 | Trends | `row` |
| 18 | Logons by Type (fleet composition) | `timeseries` |
| 19 | Interactive Logons (topk 10) | `timeseries` |
| 20 | Network Logons (topk 10) | `timeseries` |
| 21 | Deep Dive | `row` |
| 22 | Service / Batch Logons (topk 10) | `timeseries` |
| 23 | Clear-text Logons (topk 10) | `timeseries` |
| 24 | Collector scrape health | `row` |
| 25 | Scrape Health by Host | `table` |
| 26 | Scrape Duration (topk 10) | `timeseries` |
| 27 | Scrape Success (bottomk 10) | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 3, `timeseries`: 7

## متریک‌های استفاده‌شده

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_logon_logon_type`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
