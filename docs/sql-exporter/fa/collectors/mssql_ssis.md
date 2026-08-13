# mssql_ssis

دسترسی خاص:

- فایل: `collector/mssql_ssis.collector.yml`
- collector_name: `mssql_ssis`
- min_interval: `60s`
- تعداد metric: `23`
- query_refهای مشترک: `mssql_ssis_event_errors_24h`, `mssql_ssis_executions_by_status_1h`, `mssql_ssis_failed_by_package`, `mssql_ssis_failed_last`, `mssql_ssis_failed_messages`, `mssql_ssis_failed_recent`, `mssql_ssis_failed_total`, `mssql_ssis_inventory`, `mssql_ssis_operations_24h`, `mssql_ssis_operations_running`, `mssql_ssis_running`, `mssql_ssis_running_count`, `mssql_ssis_succeeded_top`, `mssql_ssisdb_exec_24h`, `mssql_ssisdb_failed_count`, `mssql_ssisdb_files`, `mssql_ssisdb_log`

هدف و کاربرد

- SSIS catalog + SSISDB health monitoring.
- GRANT VIEW SERVER STATE TO
- db_datareader on SSISDB recommended
- Agent running jobs: use mssql_job_running (not duplicated here).

نکات عملیاتی

مجوزها و پیش‌نیازها
- Special access: Read access to SSISDB.
نکات موجود در فایل منبع:
  - SSIS catalog + SSISDB health monitoring.
  - Safe when SSISDB is absent (empty result sets).
  - GRANT VIEW SERVER STATE TO
  - db_datareader on SSISDB recommended

مجوزهای پایه: `mrics`

## نحوه استفاده

`min_interval` جلوی اجرای مکرر queryها را می‌گیرد.
اگر collector از `query_ref` استفاده می‌کند، چند metric از یک query می‌گیرد.
collectorهایی که label زیاد تولید می‌کنند برای سناریوهای high-cardinality مناسب نیستند.
اگر این قابلیت روی instance وجود نداشته باشد، خروجی معمولاً خالی است و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_ssisdb_file_size_mb` | `gauge` | `type_desc`, `logical_name`, `physical_name` | `size_mb` | query_ref=`mssql_ssisdb_files` | SSISDB file sizes (MB). |
| `mssql_ssisdb_log_used_percent` | `gauge` | — | `used_percent` | query_ref=`mssql_ssisdb_log` | SSISDB percent log used. |
| `mssql_ssisdb_executions_24h` | `gauge` | `status_desc` | `execution_count` | query_ref=`mssql_ssisdb_exec_24h` | SSISDB execution counts last 24h by status. |
| `mssql_ssisdb_failed_24h` | `gauge` | — | `failed_count` | query_ref=`mssql_ssisdb_failed_count` | SSISDB failed/canceled/unexpected executions in last 24h. |
| `mssql_ssis_folders` | `gauge` | — | `folder_count` | query_ref=`mssql_ssis_inventory` | Number of SSISDB folders. |
| `mssql_ssis_projects` | `gauge` | — | `project_count` | query_ref=`mssql_ssis_inventory` | Number of SSISDB projects. |
| `mssql_ssis_packages` | `gauge` | — | `package_count` | query_ref=`mssql_ssis_inventory` | Number of SSISDB packages. |
| `mssql_ssis_environments` | `gauge` | — | `environment_count` | query_ref=`mssql_ssis_inventory` | Number of SSISDB environments. |
| `mssql_ssis_executions_1h` | `gauge` | `status_desc` | `execution_count` | query_ref=`mssql_ssis_executions_by_status_1h` | SSISDB executions in last 1 hour grouped by status. |
| `mssql_ssis_running_count` | `gauge` | — | `running_count` | query_ref=`mssql_ssis_running_count` | Number of currently running SSISDB executions. |
| `mssql_ssis_running_duration_seconds` | `gauge` | `folder`, `project`, `package`, `execution_id`, `caller_name` | `duration_seconds` | query_ref=`mssql_ssis_running` | Duration (seconds) of currently running SSISDB executions. |
| `mssql_ssis_failed_duration_seconds` | `gauge` | `folder`, `project`, `package`, `status_desc`, `execution_id` | `duration_seconds` | query_ref=`mssql_ssis_failed_recent` | Duration (seconds) of failed/canceled/unexpected SSIS executions in last 24h. |
| `mssql_ssis_failed_status` | `gauge` | `folder`, `project`, `package`, `status_desc`, `execution_id` | `status` | query_ref=`mssql_ssis_failed_recent` | Status code of failed/canceled/unexpected SSIS executions in last 24h. |
| `mssql_ssis_failed_total` | `gauge` | `window` | `failed_count` | query_ref=`mssql_ssis_failed_total` | Failed/canceled/unexpected SSIS executions in lookback window (status 3,4,6). |
| `mssql_ssis_failed_count` | `gauge` | `folder`, `project`, `package`, `status_desc`, `window` | `failed_count` | query_ref=`mssql_ssis_failed_by_package` | Failed SSIS executions per package in lookback window. |
| `mssql_ssis_failed_last_age_seconds` | `gauge` | `folder`, `project`, `package`, `status_desc`, `execution_id` | `age_seconds` | query_ref=`mssql_ssis_failed_last` | Seconds since the most recent failed/canceled/unexpected execution per package (7d). |
| `mssql_ssis_failed_last_duration_seconds` | `gauge` | `folder`, `project`, `package`, `status_desc`, `execution_id` | `duration_seconds` | query_ref=`mssql_ssis_failed_last` | Duration of the most recent failed/canceled/unexpected execution per package (7d). |
| `mssql_ssis_failed_last_status` | `gauge` | `folder`, `project`, `package`, `status_desc`, `execution_id` | `status` | query_ref=`mssql_ssis_failed_last` | Status code of the most recent failed/canceled/unexpected execution per package (7d). |
| `mssql_ssis_failed_message_count_24h` | `gauge` | `folder`, `project`, `package`, `message_snip` | `message_count` | query_ref=`mssql_ssis_failed_messages` | Error event_messages (message_type=120) linked to failed executions in last 24h. |
| `mssql_ssis_succeeded_duration_seconds` | `gauge` | `folder`, `project`, `package`, `execution_id` | `duration_seconds` | query_ref=`mssql_ssis_succeeded_top` | Top succeeded SSIS executions by duration in last 24h. |
| `mssql_ssis_operations_24h` | `gauge` | `operation_type`, `status_desc` | `operation_count` | query_ref=`mssql_ssis_operations_24h` | SSISDB operations in last 24 hours grouped by type and status. |
| `mssql_ssis_operation_running_seconds` | `gauge` | `operation_id`, `operation_type`, `object_name`, `caller_name` | `duration_seconds` | query_ref=`mssql_ssis_operations_running` | Currently running SSISDB operations duration (seconds). |
| `mssql_ssis_event_errors_24h` | `gauge` | `package`, `message_type_desc` | `message_count` | query_ref=`mssql_ssis_event_errors_24h` | SSISDB event_messages with error/warning in last 24h by package. |

## نکات عملکرد

این collector را در profile متناسب با نوع سرور فعال کن.
روی سرورهای شلوغ، collectorهای سنگین را با فاصله بیشتر و با احتیاط اجرا کن.
اگر metric جدیدی اضافه می‌کنی، قبل از rollout آن را روی یک instance تست کن.
