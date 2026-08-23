# Prometheus file-based service discovery targets

[فارسی](../fa/targets.md)

The files in this directory are safe examples only. Prometheus loads only files
ending in `.json`, so the `.template` files are not loaded automatically.

For a local deployment:

1. Copy the relevant `example.json.template` file.
2. Rename the copy to a descriptive `.json` name, such as `production.json`.
3. Replace the sample hostname, labels, and port with local values.
4. Keep environment-specific target files outside Git when they contain private
   infrastructure inventory.

## Per-target scrape settings

Special labels beginning with `__` override the matching `scrape_config` value
for that target. Prometheus removes these internal labels before storing metrics.

| Label | Purpose |
|---|---|
| `__address__` | Target address in `host:port` form; normally identical to the entry in `targets` |
| `__scheme__` | Request scheme: `http` or `https` |
| `__metrics_path__` | Metrics endpoint path, such as `/metrics` |
| `__scrape_interval__` | Per-target scrape interval |
| `__scrape_timeout__` | Per-target timeout; must not exceed the interval |
| `__param_<name>` | First value of URL query parameter `<name>`; `__param_module` is an example |
| `__convert_classic_histograms_to_nhcb__` | Convert classic histograms to native histograms with custom buckets |
| `__always_scrape_classic_histograms__` | Also scrape classic histograms when native histograms are present |
| `__scrape_native_histograms__` | Enable scraping native histograms for this target |

All label values must be JSON strings, including booleans such as `"true"` and
`"false"`. Remove optional labels that the target does not need. In particular,
remove `__param_module` unless the exporter accepts a `module` query parameter.

## Authentication limitation

`username` and `password_file` cannot be set per target in a file-SD file.
Authentication belongs to `scrape_config`. Put targets that share credentials in
the same file or directory and define a separate `scrape_config` for each
credential group. Never store passwords in target files or commit files from the
`secrets` directory.
