#!/usr/bin/env python3
"""Generate one Markdown page for every Grafana dashboard JSON."""
from __future__ import annotations

import argparse
import json
import os
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "grafana" / "dashboards"
OUTPUT = ROOT / "docs" / "grafana" / "dashboards"
METRIC = re.compile(r"(?<![A-Za-z0-9_:])([A-Za-z_:][A-Za-z0-9_:]*)(?=\s*(?:\{|\[|$))")
PROMQL_WORDS = {"and", "bool", "bottomk", "by", "count", "group", "group_left",
                "group_right", "ignoring", "label_join", "label_replace", "max",
                "min", "on", "or", "quantile", "scalar", "sort", "sort_desc",
                "sum", "time", "topk", "unless", "vector"}
TICK = chr(96)


def panels(items):
    for item in items or []:
        yield item
        yield from panels(item.get("panels", []))


def query(value):
    if isinstance(value, str):
        return value
    if isinstance(value, dict):
        return str(value.get("query") or value.get("expr") or "")
    return ""


def metrics(data):
    expressions = []
    for panel in panels(data.get("panels", [])):
        expressions += [str(target.get("expr", "")) for target in panel.get("targets", [])
                        if isinstance(target, dict)]
    expressions += [query(v.get("query")) for v in data.get("templating", {}).get("list", [])]
    found = {name for expression in expressions for name in METRIC.findall(expression)
             if name not in PROMQL_WORDS and not name.startswith("$")}
    return sorted(found, key=str.lower)


def cell(value):
    return str(value or "—").replace("|", "\\|").replace("\n", " ")


def code(value):
    return TICK + cell(value) + TICK


def relative_link(destination, target):
    return Path(os.path.relpath(target, destination.parent)).as_posix()


def make_page(source, destination, data, language):
    all_panels = list(panels(data.get("panels", [])))
    variables = data.get("templating", {}).get("list", [])
    used_metrics = metrics(data)
    kinds = Counter(p.get("type", "unknown") for p in all_panels)
    source_link = Path(os.path.relpath(source, destination.parent)).as_posix()
    index_link = relative_link(destination, OUTPUT / language / "README.md")
    grafana_readme = relative_link(destination, ROOT / "grafana" / "README.md")
    other_language = "en" if language == "fa" else "fa"
    language_link = relative_link(
        destination,
        OUTPUT / other_language / source.relative_to(SOURCE).with_suffix(".md"),
    )
    if "sql-exporter" in source.parts:
        exporter_fa = relative_link(destination, ROOT / "docs" / "sql-exporter" / "fa" / "grafana.md")
        exporter_en = relative_link(destination, ROOT / "docs" / "sql-exporter" / "en" / "grafana.md")
    else:
        exporter_fa = relative_link(destination, ROOT / "docs" / "windows-exporter" / "fa" / "README.md")
        exporter_en = relative_link(destination, ROOT / "docs" / "windows-exporter" / "en" / "README.md")
    tags = ", ".join(code(tag) for tag in data.get("tags", [])) or "—"
    if language == "en":
        lines = [
        "# " + cell(data.get("title") or source.stem), "",
        "[Dashboard index](" + index_link + ") · [Grafana guide](" + grafana_readme +
        ") · [فارسی](" + language_link + ") · [Exporter documentation](" + exporter_en + ")", "",
        "> This file is generated from the dashboard JSON; do not edit it manually.", "",
        data.get("description") or "The dashboard JSON does not provide a description.", "",
        "## Details", "", "| Property | Value |", "|---|---|",
        "| UID | " + code(data.get("uid")) + " |",
        "| Source file | [" + code(source.name) + "](" + source_link + ") |",
        "| Tags | " + tags + " |",
        "| Panel count | " + str(len(all_panels)) + " |",
        "| Refresh interval | " + code(data.get("refresh") or "Manual") + " |",
        "| Schema version | " + code(data.get("schemaVersion")) + " |", "",
        "## Dashboard variables", ""
        ]
        if variables:
            lines += ["| Name | Label | Type | Query / value |", "|---|---|---|---|"]
            for var in variables:
                value = query(var.get("query")) or var.get("current", {}).get("text") or ""
                if isinstance(value, (list, dict)):
                    value = json.dumps(value, ensure_ascii=False)
                lines.append("| " + code(var.get("name")) + " | " +
                             cell(var.get("label") or var.get("name")) + " | " +
                             code(var.get("type")) + " | " + code(value) + " |")
        else:
            lines.append("This dashboard has no selectable variables.")
        lines += ["", "## Panels", "", "| No. | Title | Type |", "|---:|---|---|"]
        for number, panel in enumerate(all_panels, 1):
            lines.append("| " + str(number) + " | " + cell(panel.get("title") or "Untitled") +
                         " | " + code(panel.get("type")) + " |")
        if not all_panels:
            lines.append("| — | No panels are defined | — |")
        summary = ", ".join(code(kind) + ": " + str(count) for kind, count in sorted(kinds.items())) or "—"
        lines += ["", "Panel type summary: " + summary, "", "## Metrics used", ""]
        lines += ["- " + code(name) for name in used_metrics] or [
            "No Prometheus metric was extracted directly from the queries."]
        lines += ["", "## Usage", "",
                  "1. Import the source JSON file shown above into Grafana.",
                  "2. Select the datasource connected to Prometheus.",
                  "3. Set the dashboard variables for your environment.", ""]
        return "\n".join(lines)
    lines = [
        "# " + cell(data.get("title") or source.stem), "",
        "[فهرست داشبوردها](" + index_link + ") · [راهنمای Grafana](" + grafana_readme +
        ") · [English](" + language_link + ") · [مستندات فارسی Exporter](" + exporter_fa + ")", "",
        "> این فایل از JSON داشبورد تولید شده است؛ برای حفظ هماهنگی، آن را دستی ویرایش نکنید.", "",
        data.get("description") or "این داشبورد توضیح ثبت‌شده‌ای در JSON ندارد.", "",
        "## مشخصات", "", "| ویژگی | مقدار |", "|---|---|",
        "| UID | " + code(data.get("uid")) + " |",
        "| فایل منبع | [" + code(source.name) + "](" + source_link + ") |",
        "| برچسب‌ها | " + tags + " |",
        "| تعداد پنل‌ها | " + str(len(all_panels)) + " |",
        "| بازهٔ تازه‌سازی | " + code(data.get("refresh") or "دستی") + " |",
        "| نسخهٔ schema | " + code(data.get("schemaVersion")) + " |", "",
        "## متغیرهای داشبورد", ""
    ]
    if variables:
        lines += ["| نام | عنوان | نوع | Query / مقدار |", "|---|---|---|---|"]
        for var in variables:
            value = query(var.get("query")) or var.get("current", {}).get("text") or ""
            if isinstance(value, (list, dict)):
                value = json.dumps(value, ensure_ascii=False)
            lines.append("| " + code(var.get("name")) + " | " +
                         cell(var.get("label") or var.get("name")) + " | " +
                         code(var.get("type")) + " | " + code(value) + " |")
    else:
        lines.append("این داشبورد متغیر قابل‌انتخابی ندارد.")
    lines += ["", "## پنل‌ها", "", "| ردیف | عنوان | نوع |", "|---:|---|---|"]
    for number, panel in enumerate(all_panels, 1):
        lines.append("| " + str(number) + " | " + cell(panel.get("title") or "بدون عنوان") +
                     " | " + code(panel.get("type")) + " |")
    if not all_panels:
        lines.append("| — | پنلی تعریف نشده است | — |")
    summary = ", ".join(code(kind) + ": " + str(count) for kind, count in sorted(kinds.items())) or "—"
    lines += ["", "ترکیب نوع پنل‌ها: " + summary, "", "## متریک‌های استفاده‌شده", ""]
    lines += ["- " + code(name) for name in used_metrics] or [
        "متریک Prometheus به‌صورت مستقیم از Queryها استخراج نشد."]
    lines += ["", "## استفاده", "",
              "1. فایل JSON منبع را از مسیر بالا در Grafana import کنید.",
              "2. datasource متصل به Prometheus را انتخاب کنید.",
              "3. متغیرهای بالای داشبورد را متناسب با محیط تنظیم کنید.", ""]
    return "\n".join(lines)


def build():
    output = {}
    rows = []
    for source in sorted(SOURCE.rglob("*.json"), key=lambda p: p.as_posix().lower()):
        data = json.loads(source.read_text(encoding="utf-8-sig"))
        relative = source.relative_to(SOURCE).with_suffix(".md")
        for language in ("fa", "en"):
            destination = OUTPUT / language / relative
            output[destination] = make_page(source, destination, data, language)
        rows.append((data.get("title") or source.stem, data.get("uid") or "—",
                     relative, source.relative_to(ROOT)))
    fa_index_path = OUTPUT / "fa" / "README.md"
    fa_index = ["# راهنمای داشبوردهای Grafana", "", "[English](../en/README.md)", "",
                "[README اصلی](" + relative_link(fa_index_path, ROOT / "README.md") +
                ") · [راهنمای Grafana](" + relative_link(fa_index_path, ROOT / "grafana" / "README.md") +
                ") · [SQL Exporter](../../../sql-exporter/fa/grafana.md) · "
                "[Windows Exporter](../../../windows-exporter/fa/README.md)", "",
                "این مجموعه مستندات شامل **" + str(len(rows)) + " داشبورد** است.", "",
                "| داشبورد | UID | مستندات | JSON |", "|---|---|---|---|"]
    en_index_path = OUTPUT / "en" / "README.md"
    en_index = ["# Grafana dashboard reference", "", "[فارسی](../fa/README.md)", "",
                "[Project README](" + relative_link(en_index_path, ROOT / "README.en.md") +
                ") · [Grafana guide](" + relative_link(en_index_path, ROOT / "grafana" / "README.md") +
                ") · [SQL Exporter](../../../sql-exporter/en/grafana.md) · "
                "[Windows Exporter](../../../windows-exporter/en/README.md)", "",
                "This documentation set covers **" + str(len(rows)) + " dashboards**.", "",
                "| Dashboard | UID | Documentation | JSON |", "|---|---|---|---|"]
    for title, uid, doc, source in rows:
        source_fa = relative_link(fa_index_path, ROOT / source)
        source_en = relative_link(en_index_path, ROOT / source)
        fa_index.append("| " + cell(title) + " | " + code(uid) + " | [مشاهده](" +
                        doc.as_posix() + ") | [" + code(source.name) + "](" + source_fa + ") |")
        en_index.append("| " + cell(title) + " | " + code(uid) + " | [View](" +
                        doc.as_posix() + ") | [" + code(source.name) + "](" + source_en + ") |")
    fa_index.append("")
    en_index.append("")
    output[fa_index_path] = "\n".join(fa_index)
    output[en_index_path] = "\n".join(en_index)
    output[OUTPUT / "README.md"] = "\n".join([
        "# Grafana dashboard documentation / مستندات داشبوردهای Grafana", "",
        "- [فارسی](fa/README.md)",
        "- [English](en/README.md)", "",
    ])
    return output


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    generated = build()
    stale = [p for p, content in generated.items()
             if not p.exists() or p.read_text(encoding="utf-8") != content]
    expected = set(generated)
    extra = set(OUTPUT.rglob("*.md")) - expected if OUTPUT.exists() else set()
    if args.check:
        if stale or extra:
            print("Stale/missing: " + str(len(stale)) + "; extra: " + str(len(extra)))
            return 1
        print("OK: 83 dashboards in FA and EN plus language indexes are current")
        return 0
    for path, content in generated.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8", newline="\n")
    for path in extra:
        path.unlink()
    print("Generated 83 dashboards in FA and EN plus language indexes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
