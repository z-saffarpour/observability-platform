# هدف‌های File-based Service Discovery در Prometheus

[English](../en/targets.md)

فایل‌های این پوشه فقط نمونه‌های عمومی و امن هستند. Prometheus تنها فایل‌هایی را
که پسوند `.json` دارند بارگذاری می‌کند؛ بنابراین فایل‌های دارای پسوند
`.template` به‌صورت خودکار خوانده نمی‌شوند.

برای استفاده در محیط واقعی:

1. فایل `example.json.template` مربوط به exporter را کپی کنید.
2. نام فایل کپی‌شده را به یک نام مشخص با پسوند `.json`، مانند
   `production.json`، تغییر دهید.
3. hostname، پورت، labelها و تنظیمات نمونه را با مقادیر محیط خود جایگزین کنید.
4. اگر فایل شامل inventory خصوصی زیرساخت است، آن را خارج از Git نگه دارید.

## تنظیمات scrape برای هر target

labelهای ویژه‌ای که با `__` شروع می‌شوند، مقدار متناظر در `scrape_config` را
برای همان target بازنویسی می‌کنند. Prometheus این labelهای داخلی را پیش از
ذخیره metricها حذف می‌کند.

| Label | کاربرد |
|---|---|
| `__address__` | آدرس target به‌شکل `host:port`؛ معمولاً برابر مقدار موجود در `targets` است |
| `__scheme__` | پروتکل درخواست؛ `http` یا `https` |
| `__metrics_path__` | مسیر endpoint متریک، مانند `/metrics` |
| `__scrape_interval__` | فاصله زمانی scrape برای همان target |
| `__scrape_timeout__` | مهلت scrape؛ نباید از interval بیشتر باشد |
| `__param_<name>` | اولین مقدار پارامتر URL با نام `<name>`؛ مقدار `__param_module` فقط نمونه است |
| `__convert_classic_histograms_to_nhcb__` | تبدیل classic histogram به native histogram با bucketهای سفارشی |
| `__always_scrape_classic_histograms__` | دریافت classic histogram در کنار native histogram |
| `__scrape_native_histograms__` | فعال‌کردن دریافت native histogram برای target |

تمام مقادیر labelها در JSON باید string باشند؛ حتی مقادیر boolean مانند
`"true"` و `"false"`. labelهای اختیاری غیرضروری را حذف کنید. به‌خصوص اگر
exporter پارامتر `module` را قبول نمی‌کند، `__param_module` را حذف کنید.

## محدودیت احراز هویت

قرار دادن `username` و `password_file` متفاوت برای هر target در فایل File SD
امکان‌پذیر نیست. تنظیمات احراز هویت در سطح `scrape_config` تعریف می‌شوند.
targetهایی را که credential مشترک دارند در یک فایل یا پوشه قرار دهید و برای هر
گروه credential یک `scrape_config` جدا بسازید. رمز عبور را داخل فایل target
قرار ندهید و محتوای پوشه `secrets` را وارد Git نکنید.
