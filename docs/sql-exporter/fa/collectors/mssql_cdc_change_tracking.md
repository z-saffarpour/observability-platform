# mssql_cdc_change_tracking

## خلاصه

- فایل: `collector/mssql_cdc_change_tracking.collector.yml`
- `collector_name`: `mssql_cdc_change_tracking`
- `min_interval`: `300s`
- تعداد metric: `17`
- پروفایل‌ها: `oltp`، `dwh` و `replication`

## هدف

این Collector وضعیت و تنظیمات Change Data Capture و Change Tracking را بدون
تولید label به‌ازای هر جدول یا Capture Instance پایش می‌کند.

CDC شامل موارد زیر است:

- فعال بودن قابلیت به‌ازای دیتابیس
- تعداد Capture Instanceها
- فاصله زمانی آخرین LSN پردازش‌شده
- سن قدیمی‌ترین LSN نگهداری‌شده
- وضعیت فعال و درحال‌اجرابودن Jobهای Capture و Cleanup
- حالت Continuous، Polling Interval، Retention و Cleanup Threshold

Change Tracking شامل موارد زیر است:

- فعال بودن، Retention و Auto Cleanup
- تعداد جدول‌های Track‌شده
- Current Version و قدیمی‌ترین Min Valid Version قابل مشاهده
- Version Window

## دسترسی‌ها

- `VIEW ANY DATABASE`
- دسترسی `CONNECT` به دیتابیس‌های مربوطه
- `VIEW DATABASE STATE` و دسترسی خواندن metadataهای CDC توصیه می‌شود
- برای Jobها دسترسی خواندن `msdb.dbo.cdc_jobs`، `sysjobs`، `sysjobactivity` و
  `syssessions` لازم است

اگر بخشی از metadata قابل‌خواندن نباشد، مقدارهای تشخیصی آن بخش `-1` یا خروجی
خالی خواهند بود و Queryهای سایر بخش‌ها ادامه پیدا می‌کنند.

## نکات Alerting

```promql
mssql_cdc_enabled == 1 and mssql_cdc_capture_lag_seconds > 300
mssql_cdc_job_enabled{job_type="capture"} == 0
mssql_cdc_job_running{job_type="capture"} == 0
mssql_change_tracking_enabled == 1 and mssql_change_tracking_auto_cleanup_enabled == 0
```

برای Capture Job پیوسته، `job_running == 0` معمولاً خطاست؛ ولی در حالت one-shot
باید Rule با برنامه اجرای Job هماهنگ شود. همچنین Version Window جایگزین
`last_sync_version` مصرف‌کننده نیست؛ اعتبار هر Consumer باید با
`CHANGE_TRACKING_MIN_VALID_VERSION` کنترل شود.
