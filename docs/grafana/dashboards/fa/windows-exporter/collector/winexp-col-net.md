# Collector net

[فهرست داشبوردها](../../README.md) · [راهنمای Grafana](../../../../../../grafana/README.md) · [English](../../../en/windows-exporter/collector/winexp-col-net.md) · [مستندات فارسی Exporter](../../../../../windows-exporter/fa/README.md)

> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.

Network throughput, link utilisation and error/discard counters per NIC. Any non-zero error rate is worth a driver / cabling / vSwitch check.

## مشخصات

| ویژگی | مقدار |
|---|---|
| UID | `winexp-col-net` |
| فایل منبع | [`winexp-col-net.json`](../../../../../../grafana/dashboards/windows-exporter/collector/winexp-col-net.json) |
| برچسب‌ها | `windows_exporter`, `collector`, `net` |
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
| 3 | Hosts with Errors | `stat` |
| 4 | Hosts with Discards | `stat` |
| 5 | NICs Util > 70% | `stat` |
| 6 | Max NIC Util % | `stat` |
| 7 | Fleet RX | `stat` |
| 8 | Fleet TX | `stat` |
| 9 | Total Errors/s | `stat` |
| 10 | Max Output Queue | `stat` |
| 11 | Fleet Ranking (now) | `row` |
| 12 | Top RX Bps (topk 15) | `bargauge` |
| 13 | Top TX Bps (topk 15) | `bargauge` |
| 14 | Top Errors + Discards/s (topk 15) | `bargauge` |
| 15 | Fleet Snapshot & Hotspots | `row` |
| 16 | Network Health by Host | `table` |
| 17 | Per-NIC Detail | `table` |
| 18 | Hotspots: Errors or Discards > 0 | `table` |
| 19 | Trends | `row` |
| 20 | RX Bps (topk 10) | `timeseries` |
| 21 | TX Bps (topk 10) | `timeseries` |
| 22 | NIC Utilisation % (topk 10) | `timeseries` |
| 23 | Errors/s (topk 10) | `timeseries` |
| 24 | Discards/s (topk 10) | `timeseries` |
| 25 | Output Queue Length (topk 10) | `timeseries` |
| 26 | Deep Dive | `row` |
| 27 | Packets RX / TX per second (topk 10) | `timeseries` |
| 28 | Unknown Protocol Packets/s (topk 10) | `timeseries` |
| 29 | Average Packet Size (topk 10) | `timeseries` |
| 30 | Inbound vs Outbound Errors (fleet) | `timeseries` |
| 31 | NIC Inventory & Link Speed | `table` |
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
- `windows_net_bytes_received_total`
- `windows_net_bytes_sent_total`
- `windows_net_bytes_total`
- `windows_net_current_bandwidth_bytes`
- `windows_net_output_queue_length_packets`
- `windows_net_packets_outbound_discarded_total`
- `windows_net_packets_outbound_errors_total`
- `windows_net_packets_received_discarded_total`
- `windows_net_packets_received_errors_total`
- `windows_net_packets_received_total`
- `windows_net_packets_received_unknown_total`
- `windows_net_packets_sent_total`
- `windows_net_packets_total`

## استفاده

1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.
2. datasource متصل به Prometheus را انتخاب کنید.
3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.
