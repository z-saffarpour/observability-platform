# DBA Overview

[فهرست داشبوردها](../README.md) · [راهنمای Grafana](../../../../../grafana/README.md) · [English](../../en/windows-exporter/winexp-00-dba-overview.md) · [مستندات فارسی Exporter](../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Prometheus replica of classic DBA Overview V02 (InfluxDB hybrid). Fleet KPIs, service state, memory/CPU/disk/network.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-00-dba-overview` |
| فایل منبع | [`winexp-00-dba-overview.json`](../../../../../grafana/dashboards/windows-exporter/winexp-00-dba-overview.json) |
| برچسب‌ها | `windows_exporter`, `dba`, `overview`, `operations` |
| تعداد پنل‌ها | 15 |
| بازهٔ تازه‌سازی | `5m` |
| نسخهٔ schema | `39` |

## متغیرهای داشبورد

| نام | عنوان | نوع | Query / مقدار |
|---|---|---|---|
| `Host` | Host | `query` | `label_values(up{job="windows_exporter"}, instance)` |

## پنل‌ها

| ردیف | عنوان | نوع |
|---:|---|---|
| 1 | بدون عنوان | `stat` |
| 2 | بدون عنوان | `stat` |
| 3 | بدون عنوان | `stat` |
| 4 | بدون عنوان | `stat` |
| 5 | بدون عنوان | `stat` |
| 6 | Server State | `table` |
| 7 | Server State | `table` |
| 8 | SQL Service State | `table` |
| 9 | SQL Analysis Service State | `table` |
| 10 | Memory | `table` |
| 11 | CPU | `table` |
| 12 | Backup Disk Free | `table` |
| 13 | Processor Queue | `table` |
| 14 | Network | `table` |
| 15 | Disk Free | `table` |

ترکیب نوع پنل‌ها: `stat`: 5, `table`: 10

## متریک‌های استفاده‌شده

- `up`
- `windows_cpu_time_total`
- `windows_logical_disk_free_bytes`
- `windows_logical_disk_size_bytes`
- `windows_memory_available_bytes`
- `windows_memory_physical_total_bytes`
- `windows_net_bytes_received_total`
- `windows_net_bytes_sent_total`
- `windows_service_state`
- `windows_system_processor_queue_length`
- `windows_system_system_up_time`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
