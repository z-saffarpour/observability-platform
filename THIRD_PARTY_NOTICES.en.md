# Third-Party Software Notices

[فارسی](THIRD_PARTY_NOTICES.md) | **English**

This repository redistributes the following third-party binaries for deployment
convenience. These components remain subject to their respective upstream
licenses; the repository's primary license does not replace those licenses.

## Prometheus and Promtool

- Version: `3.14.0`
- Platforms: `windows/amd64` and `linux/amd64`
- Windows paths: `prometheus/bin/windows-amd64/prometheus.exe` and `prometheus/bin/windows-amd64/promtool.exe`
- Linux paths: `prometheus/bin/linux-amd64/prometheus` and `prometheus/bin/linux-amd64/promtool`
- License: Apache License 2.0
- Copyright: Copyright 2012-2015 The Prometheus Authors
- Source code and license: <https://github.com/prometheus/prometheus/tree/v3.14.0>
- Windows Prometheus SHA-256: `CDAC9D751A8B5DC978F9D1C1B708185F98EA3A4E42ECA6E0B2C8EBF4CB472EEB`
- Windows Promtool SHA-256: `78B0D964CE421256AE3FAB858194F890541553D59FEBA0E5AE24550A1704197A`
- Linux Prometheus SHA-256: `30576B9BD5FC4E4FAA8BDA23CB29F48A24CA27CBE9788C392CCF403F945163DC`
- Linux Promtool SHA-256: `9C752BB87EEC945B2D7797D20815E2DC54B0D3FED2D2F17DF019DBD74560F743`

The complete Apache License 2.0 terms and upstream attribution notices,
including notices for third-party components embedded in the web UI, are kept
in the `LICENSE` and `NOTICE` files next to each platform's binaries. The
`NOTICE` file is part of Prometheus's redistribution requirements and must
remain with the binaries.

## windows_exporter

- Version: `0.31.8`
- Path: `exporters/windows-exporter/bin/windows_exporter.exe`
- Platform: `windows/amd64`
- License: MIT
- Copyright: Copyright (c) 2016 Martin Lindhe; Copyright (c) 2021 The Prometheus Authors
- Source code and license: <https://github.com/prometheus-community/windows_exporter/tree/v0.31.8>
- SHA-256: `03BB0FE80B8AD0B4E39606B96C4C5CC56B1F766760011EA2B00111157C6EF077`

## sql_exporter

- Version: `0.24.4`
- Path: `exporters/sql-exporter/bin/sql_exporter.exe`
- Platform: `windows/amd64`
- License: MIT
- Source code and license: <https://github.com/burningalchemist/sql_exporter/tree/v0.24.4>
- SHA-256: `0DB8A2BC67C71645815588AA223A4C33410EC09FAB76B3D21520874803BD53FC`

## NSSM — the Non-Sucking Service Manager

- Version: `2.24`
- Path: `deployment/windows/tools/nssm/nssm.exe`
- License status: Public Domain
- Website, source code, and license declaration: <https://nssm.cc/download>
- SHA-256: `F689EE9AF94B00E9E3F0BB072B34CAAF207F32DCB4F5782FC9CA351DF9A06C97`

The upstream project declares NSSM to be in the public domain and permits its
binary and source code to be used unconditionally for any purpose.

## MIT License Text

The following terms apply to the MIT-licensed components listed above. Each
component's copyright notices must be retained with these terms.

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

## Reproducibility Note

The versions and hashes identify the files currently included in this
repository. Whenever a binary is replaced or upgraded, this document's version,
source link, copyright notice, license text, and SHA-256 value must also be
reviewed and updated.
