# راهنمای نوشتن Collector برای `sql_exporter`

این راهنما برای کسی نوشته شده که تازه به تیم اضافه شده و می‌خواهد یک collector جدید اضافه کند یا یکی از collectorهای موجود را تغییر دهد.

## هدف collector

هر collector باید یک مسئله روشن را حل کند:
- وضعیت عمومی instance
- عملکرد
- Always On
- backup / restore
- waits / blocking
- tempdb / file I/O
- jobها و نگهداری

اصل مهم:
- هر collector باید کوچک، قابل‌فهم و قابل‌نگهداری باشد.
- اگر یک metric به collector دیگری تعلق دارد، آن را تکراری نسازید.

## ساختار هر فایل

هر فایل در `collector/` یک collector مستقل است:

```yaml
collector_name: mssql_example
min_interval: 60s

metrics:
  - metric_name: mssql_example_value
    type: gauge
    help: 'Example metric'
    values: [value]
    query: |
      SELECT CAST(1 AS float) AS value;
```

### فیلدهای مهم

- `collector_name`: باید با نام فایل هم‌خوان باشد.
- `min_interval`: حداقل فاصله اجرای کوئری. برای کوئری‌های سنگین بزرگ‌تر بگذار.
- `metrics`: لیست metricها.
- `metric_name`: نام metric در Prometheus.
- `type`: معمولاً `gauge` یا `counter`.
- `help`: توضیح کوتاه و دقیق.
- `key_labels`: labelهایی که سری‌ها را از هم جدا می‌کنند.
- `values`: ستون(های) عددی خروجی.
- `value_label`: وقتی یک query چند خروجی هم‌نوع دارد و می‌خواهی نام آن‌ها را به‌صورت label ببری.
- `static_value`: وقتی metric فقط برای حمل labelها استفاده می‌شود و مقدار ثابت دارد.
- `query`: کوئری اصلی.
- `query_ref`: وقتی چند metric از یک query مشترک استفاده می‌کنند.

## الگوی پیشنهادی برای طراحی

### 1) collector را بر اساس موضوع بچین

مثال:
- `mssql_standard` برای سیگنال‌های پایه
- `mssql_memory` برای memory
- `mssql_tempdb` برای tempdb
- `mssql_file_io` برای I/O
- `mssql_alwayson` برای AG

### 2) metricها را در سطح مناسب نگه دار

از metricهای خیلی پرکاردینال خودداری کن:
- `query_text`
- `session_id`
- `plan_handle`
- labelهای باز و unbounded

### 3) برای metricهای مشترک از `query_ref` استفاده کن

اگر چند metric از یک CTE یا query واحد تغذیه می‌شوند، query را یک‌بار تعریف کن و metricها را با `query_ref` به آن وصل کن.

نمونه واقعی این الگو در `mssql_alwayson` استفاده شده است؛ چند metric از query مشترک `mssql_alwayson_pair` تغذیه می‌شوند.

### 4) برای metricهای زمان‌محور از `counter` یا نرخ مشتق‌شده استفاده کن

مثال:
- تعداد deadlock
- job fail
- log growth

### 5) برای metricهای لحظه‌ای از `gauge` استفاده کن

مثال:
- lag
- queue size
- tempdb used
- memory pressure

## قواعد نام‌گذاری

الگوی رایج:

```text
mssql_<area>_<signal>_<unit>
```

نمونه:
- `mssql_memory_target_server_mb`
- `mssql_tempdb_waiting_tasks_count`
- `mssql_file_io_read_latency_p95_ms`
- `mssql_alwayson_secondary_lag_seconds`

## معیارهای کیفیت

قبل از اضافه کردن metric جدید این سؤال‌ها را جواب بده:

- آیا این metric برای alert یا troubleshooting کاربرد دارد؟
- آیا با metric موجود تکراری نیست؟
- آیا cardinality آن کنترل شده است؟
- آیا `min_interval` مناسب دارد؟
- آیا روی سرور شلوغ هم قابل اجراست؟

## چک‌لیست قبل از merge

- نام فایل و `collector_name` یکی است.
- metricها اسم واضح و یکنواخت دارند.
- labelها محدود و معنی‌دار هستند.
- queryها روی instance خالی هم fail نمی‌شوند.
- collector جدید با profileهای موجود تداخل ندارد.
- `min_interval` با سنگینی query هماهنگ است.

## اشتباهات رایج

- گذاشتن query سنگین در `mssql_standard`
- ساختن metric با labelهای زیاد
- استفاده از نام‌های مبهم مثل `value1` و `value2`
- قراردادن چند responsibility در یک collector
- نگذاشتن `help` مناسب

## پیشنهاد برای شروع کار

اگر تازه وارد تیم شدی:
1. اول [README.md](../README.md) را بخوان.
2. بعد یکی از collectorهای ساده مثل `mssql_standard` را باز کن.
3. یک metric کوچک و کم‌ریسک اضافه کن.
4. با `/metrics` آن را تست کن.
5. بعد سراغ collectorهای سنگین‌تر برو.
