# mssql_slow_query_history

## خلاصه

- فایل: `collector/mssql_slow_query_history.collector.yml`
- Collector: `mssql_slow_query_history`
- فاصله اجرا: `300s`
- کاربرد: ۵۰ اجرای کندِ شش ساعت اخیر. آستانه session همان `-DurationMs` نصب است. پیش‌فرض ۵۰۰۰ است و برای فروشگاه `-DurationMs 100` داده می‌شود.

## چرا نوع متریک gauge است

هر سری یک اجراست. elapsed جمع نمی‌شود، پس نوع آن gauge است. هر scrape فایل‌های XEL را دوباره می‌خواند و تا وقتی آن اجرا داخل پنجره و بین ۵۰ تای کندتر است، همان `event_time` را منتشر می‌کند. سری حداکثر شش ساعت در فهرست جاری می‌ماند. بعد از شش ساعت، با roll شدن فایل XEL، یا وقتی ۵۰ اجرای کندتر جایش را بگیرند، از فهرست خارج می‌شود.

`mssql_heavy_queries` نمای زنده `sys.dm_exec_requests` است.

## متریک‌ها

- `mssql_slow_query_xe_up`
- `mssql_slow_query_elapsed_ms`
- `mssql_slow_query_cpu_ms`
- `mssql_slow_query_logical_reads`
- `mssql_slow_query_age_seconds`

`xe_up` فقط وقتی ۱ است که session به نام `observability_slow_queries` در حال اجرا باشد و target آن `event_file` باشد. فهرست خالی همراه با `xe_up = 0` یعنی capture خاموش است.

برچسب‌های اجرای کند: `event_time` (ساعت محلی SQL Server با شکل `yyyy-mm-dd hh:mm:ss.fff`)، `db`، `obj`، `query_hash`، `statement_snip` (۴۰۰ کاراکتر)، `session_id` و `event_name` با مقدار `statement` یا `rpc` یا `proc_statement`. elapsed و CPU میلی‌ثانیه هستند. age ثانیه از timestamp رویداد به وقت UTC است.

## Session

نصب، بدون ساختن دوباره session موجود:

`scripts/powershell/sql-exporter/Install-SlowQueryEventSession.ps1 -SqlInstance <instance>`

این session رویدادهای `sql_statement_completed`، `rpc_completed` و `sp_statement_completed` را با آستانه `-DurationMs` ذخیره می‌کند. `Install-SqlExporterRemote.ps1` همان پارامتر را عبور می‌دهد. پیش‌فرض ۵۰۰۰ است. `sql_exporter`، `telegraf` و خود اسکریپت نصب حذف می‌شوند. فایل‌ها زیر `{drive}:\Databases\Temp\XEvent\Machine\Instance\observability_slow_queries\` ساخته می‌شوند، مگر اینکه `-XelDirectory` داده شود. بافر ۲۰ مگابایت در ۸ فایل است. `STARTUP_STATE` روشن است.

`-Replace` session را از نو می‌سازد و فایل‌های XEL قبلی را روی دیسک نگه می‌دارد. `-Uninstall` session را متوقف و حذف می‌کند و فایل‌ها را پاک نمی‌کند.

`Install-SqlExporterRemote.ps1` وقتی این collector در profile انتخاب‌شده باشد و `-SqlInstance` داده شده باشد، همین نصب را اجرا می‌کند.

## دسترسی‌ها

login مربوط به exporter به `VIEW SERVER STATE` نیاز دارد. در SQL Server 2022 و جدیدتر `VIEW SERVER PERFORMANCE STATE` هم لازم است که `Create-SqlExporterLogin.sql` آن را می‌دهد.

ساختن session به principalی نیاز دارد که بتواند event session و پوشه را بسازد. در عمل این دسترسی sysadmin است.

## محدودیت‌ها

- فقط فایل‌های فعلی XEL دیده می‌شوند. اگر ۲۰ مگابایت در ۸ فایل زودتر از شش ساعت roll شود، فهرست کوتاه‌تر از شش ساعت است.
- `ALLOW_SINGLE_EVENT_LOSS` می‌تواند در burst یک رویداد را قبل از نوشتن روی دیسک حذف کند.
- یک فراخوانی procedure ممکن است هم به شکل `rpc` و هم `proc_statement` بیاید.
- این فهرست از `sys.dm_exec_query_stats` استفاده نمی‌کند.
- پنل‌های فعلی داشبورد `sqlx-heavy-queries` هنوز فقط `mssql_heavy_queries` را می‌خوانند.
