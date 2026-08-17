# mssql_file_io

دسترسی خاص:

- فایل: `collector/mssql_file_io.collector.yml`
- collector_name: `mssql_file_io`
- min_interval: `180s`
- تعداد metric: `17`
- query_refهای مشترک: `mssql_file_io_latency_p95`, `mssql_file_io_pending`, `mssql_file_io_stats`, `mssql_volume_space`

هدف و کاربرد

- Per-file I/O latency metrics for Microsoft SQL Server.
- لازم است کاربر SQL Server مجوزهای زیر را داشته باشد:
- GRANT VIEW SERVER STATE TO
- GRANT VIEW ANY DEFINITION TO
- به‌صورت خودکار از طریق collectors: [mssql_*] and collector_files: ["collector/*.collector.yml"]

نکات عملیاتی

مجوزها و پیش‌نیازها
نکات موجود در فایل منبع:
  - لازم است کاربر SQL Server مجوزهای زیر را داشته باشد:
  - GRANT VIEW SERVER STATE TO
  - GRANT VIEW ANY DEFINITION TO

مجوزهای پایه: `mrics`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_file_io_stall_read_ms` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `io_stall_read_ms` | query_ref=`mssql_file_io_stats` | Cumulative IO stall read time (ms) per database file. |
| `mssql_file_io_stall_write_ms` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `io_stall_write_ms` | query_ref=`mssql_file_io_stats` | Cumulative IO stall write time (ms) per database file. |
| `mssql_file_io_stall_ms` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `io_stall_ms` | query_ref=`mssql_file_io_stats` | Cumulative IO stall total time (ms) per database file. |
| `mssql_file_io_num_of_reads` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `num_of_reads` | query_ref=`mssql_file_io_stats` | Cumulative number of reads per database file. |
| `mssql_file_io_num_of_writes` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `num_of_writes` | query_ref=`mssql_file_io_stats` | Cumulative number of writes per database file. |
| `mssql_file_io_read_bytes` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `num_of_bytes_read` | query_ref=`mssql_file_io_stats` | Cumulative bytes read per database file. |
| `mssql_file_io_write_bytes` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `num_of_bytes_written` | query_ref=`mssql_file_io_stats` | Cumulative bytes written per database file. |
| `mssql_file_io_avg_read_latency_ms` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `avg_read_latency_ms` | query_ref=`mssql_file_io_stats` | Average read latency (ms) since startup = stall_read / reads. |
| `mssql_file_io_avg_write_latency_ms` | `gauge` | `db`, `file_id`, `type_desc`, `logical_name`, `physical_name`, `volume_mount_point` | `avg_write_latency_ms` | query_ref=`mssql_file_io_stats` | Average write latency (ms) since startup = stall_write / writes. |
| `mssql_volume_total_bytes` | `gauge` | `volume_mount_point` | `total_bytes` | query_ref=`mssql_volume_space` | Volume total bytes for SQL data/log mounts. |
| `mssql_volume_available_bytes` | `gauge` | `volume_mount_point` | `available_bytes` | query_ref=`mssql_volume_space` | Volume available bytes for SQL data/log mounts. |
| `mssql_volume_used_percent` | `gauge` | `volume_mount_point` | `used_percent` | query_ref=`mssql_volume_space` | Volume used percent for SQL data/log mounts. |
| `mssql_file_io_pending_requests` | `gauge` | — | `pending_requests` | query_ref=`mssql_file_io_pending` | Current number of pending IO requests. |
| `mssql_file_io_pending_wait_ms` | `gauge` | — | `pending_wait_ms` | query_ref=`mssql_file_io_pending` | مجموع io_pending_ms_ticks برای درخواست‌های IO در انتظار (زمان انتظار، نه بایت). |
| `mssql_file_io_read_latency_p95_ms` | `gauge` | — | `read_latency_p95_ms` | query_ref=`mssql_file_io_latency_p95` | 95th percentile of per-file average read latency (ms). |
| `mssql_file_io_write_latency_p95_ms` | `gauge` | — | `write_latency_p95_ms` | query_ref=`mssql_file_io_latency_p95` | 95th percentile of per-file average write latency (ms). |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
