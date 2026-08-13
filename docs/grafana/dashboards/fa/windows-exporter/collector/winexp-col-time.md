# Collector time

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/windows-exporter/collector/winexp-col-time.md) · [مستندات فارسی Exporter](../../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Time synchronisation health. Clock offset above ~1s breaks Kerberos, AG failover and log correlation - treat offenders as incidents.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-col-time` |
| فایل منبع | [`winexp-col-time.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-time.json) |
| برچسب‌ها | `windows_exporter`, `collector`, `time` |
| تعداد پنل‌ها | 29 |
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
| 3 | Offset > 1s | `stat` |
| 4 | Offset > 50ms | `stat` |
| 5 | Max \|Offset\| | `stat` |
| 6 | Median \|Offset\| | `stat` |
| 7 | Max NTP RTT | `stat` |
| 8 | No NTP Source | `stat` |
| 9 | Min NTP Sources | `stat` |
| 10 | Fleet Ranking (now) | `row` |
| 11 | Worst \|Offset\| (topk 15) | `bargauge` |
| 12 | Highest NTP RTT (topk 15) | `bargauge` |
| 13 | Fewest NTP Sources (bottomk 15) | `bargauge` |
| 14 | Fleet Snapshot & Hotspots | `row` |
| 15 | Time Sync Health by Host | `table` |
| 16 | Hotspots: \|Offset\| > 50ms | `table` |
| 17 | Trends | `row` |
| 18 | Computed Time Offset (topk 10 by \|offset\|) | `timeseries` |
| 19 | NTP Round Trip Delay (topk 10) | `timeseries` |
| 20 | Clock Frequency Adjustment (topk 10) | `timeseries` |
| 21 | NTP Time Sources (bottomk 10) | `timeseries` |
| 22 | Deep Dive | `row` |
| 23 | NTP Server Requests / Responses per second | `timeseries` |
| 24 | Host Clock vs Prometheus Clock (topk 10) | `timeseries` |
| 25 | Timezone by Host | `table` |
| 26 | Collector scrape health | `row` |
| 27 | Scrape Health by Host | `table` |
| 28 | Scrape Duration (topk 10) | `timeseries` |
| 29 | Scrape Success (bottomk 10) | `timeseries` |

ترکیب نوع پنل‌ها: `bargauge`: 3, `row`: 6, `stat`: 8, `table`: 4, `timeseries`: 8

## متریک‌های استفاده‌شده

- `windows_exporter_build_info`
- `windows_exporter_collector_duration_seconds`
- `windows_exporter_collector_success`
- `windows_exporter_collector_timeout`
- `windows_os_timezone`
- `windows_time_clock_frequency_adjustment_ppb_total`
- `windows_time_computed_time_offset_seconds`
- `windows_time_current_timestamp_seconds`
- `windows_time_ntp_client_time_sources`
- `windows_time_ntp_round_trip_delay_seconds`
- `windows_time_ntp_server_incoming_requests_total`
- `windows_time_ntp_server_outgoing_responses_total`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
