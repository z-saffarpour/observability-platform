# اطلاعیه‌های نرم‌افزارهای شخص ثالث

**فارسی** | [English](THIRD_PARTY_NOTICES.en.md)

این مخزن، باینری‌های شخص ثالث زیر را برای تسهیل استقرار بازتوزیع می‌کند. این
مؤلفه‌ها تحت مجوز پروژهٔ اصلی خود باقی می‌مانند و مجوز اصلی این مخزن جایگزین
مجوز آن‌ها نمی‌شود.

## Prometheus و Promtool

- نسخه: `3.14.0`
- پلتفرم‌ها: `windows/amd64` و `linux/amd64`
- مسیرهای Windows: `prometheus/bin/windows-amd64/prometheus.exe` و `prometheus/bin/windows-amd64/promtool.exe`
- مسیرهای Linux: `prometheus/bin/linux-amd64/prometheus` و `prometheus/bin/linux-amd64/promtool`
- مجوز: Apache License 2.0
- صاحبان حق نشر: Copyright 2012-2015 The Prometheus Authors
- کد منبع و مجوز: <https://github.com/prometheus/prometheus/tree/v3.14.0>
- SHA-256 فایل Prometheus در Windows: `CDAC9D751A8B5DC978F9D1C1B708185F98EA3A4E42ECA6E0B2C8EBF4CB472EEB`
- SHA-256 فایل Promtool در Windows: `78B0D964CE421256AE3FAB858194F890541553D59FEBA0E5AE24550A1704197A`
- SHA-256 فایل Prometheus در Linux: `30576B9BD5FC4E4FAA8BDA23CB29F48A24CA27CBE9788C392CCF403F945163DC`
- SHA-256 فایل Promtool در Linux: `9C752BB87EEC945B2D7797D20815E2DC54B0D3FED2D2F17DF019DBD74560F743`

نسخهٔ کامل Apache License 2.0 و اعلان‌های انتساب بالادستی، شامل مؤلفه‌های
شخص ثالث تعبیه‌شده در رابط وب، به‌ترتیب در فایل‌های `LICENSE` و `NOTICE` کنار
باینری‌های هر پلتفرم نگهداری می‌شوند. فایل `NOTICE` بخشی از الزامات بازتوزیع
Prometheus است و باید همراه باینری‌ها باقی بماند.

## windows_exporter

- نسخه: `0.31.8`
- مسیر: `exporters/windows-exporter/bin/windows_exporter.exe`
- پلتفرم: `windows/amd64`
- مجوز: MIT
- صاحبان حق نشر: Copyright (c) 2016 Martin Lindhe؛ Copyright (c) 2021 The Prometheus Authors
- کد منبع و مجوز: <https://github.com/prometheus-community/windows_exporter/tree/v0.31.8>
- SHA-256: `03BB0FE80B8AD0B4E39606B96C4C5CC56B1F766760011EA2B00111157C6EF077`

## sql_exporter

- نسخه: `0.24.4`
- مسیر: `exporters/sql-exporter/bin/sql_exporter.exe`
- پلتفرم: `windows/amd64`
- مجوز: MIT
- کد منبع و مجوز: <https://github.com/burningalchemist/sql_exporter/tree/v0.24.4>
- SHA-256: `0DB8A2BC67C71645815588AA223A4C33410EC09FAB76B3D21520874803BD53FC`

## NSSM — the Non-Sucking Service Manager

- نسخه: `2.24`
- مسیر: `deployment/windows/tools/nssm/nssm.exe`
- وضعیت مجوز: مالکیت عمومی (Public Domain)
- وب‌سایت، کد منبع و اعلام مجوز: <https://nssm.cc/download>
- SHA-256: `F689EE9AF94B00E9E3F0BB072B34CAAF207F32DCB4F5782FC9CA351DF9A06C97`

طبق اعلام رسمی پروژه، NSSM در مالکیت عمومی است و استفاده از آن یا کد منبعش
برای هر منظوری بدون قید و شرط مجاز است.

## متن مجوز MIT

متن زیر برای مؤلفه‌های دارای مجوز MIT در بالا اعمال می‌شود. اعلان‌های حق نشر
هر مؤلفه باید همراه این متن حفظ شوند.

```text
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## یادداشت بازتولیدپذیری

نسخه‌ها و هش‌ها مربوط به فایل‌های موجود در همین مخزن هستند. هنگام جایگزینی یا
ارتقای هر باینری، نسخه، پیوند منبع، اعلان حق نشر، متن مجوز و SHA-256 این سند نیز
باید بازبینی و به‌روزرسانی شود.
