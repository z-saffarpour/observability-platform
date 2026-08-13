# Third-Party Software Notices

[فارسی](THIRD_PARTY_NOTICES.md) | **English**

This repository redistributes the following third-party binaries for deployment
convenience. These components remain subject to their respective upstream
licenses; the repository's primary license does not replace those licenses.

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
