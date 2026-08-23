#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../../.." && pwd)"
config_root="${PROMETHEUS_CONFIG_ROOT:-/etc/prometheus}"
data_root="${PROMETHEUS_DATA_ROOT:-/var/lib/prometheus}"

if [[ "${config_root}" != /* ]] || [[ "${data_root}" != /* ]]; then
  echo "PROMETHEUS_CONFIG_ROOT and PROMETHEUS_DATA_ROOT must be absolute paths." >&2
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this installer as root." >&2
  exit 1
fi

if [[ ! -f "${repo_root}/prometheus/bin/linux-amd64/prometheus" ]] ||
   [[ ! -f "${repo_root}/prometheus/bin/linux-amd64/promtool" ]]; then
  echo "Linux Prometheus binaries are missing." >&2
  exit 1
fi

if ! id prometheus >/dev/null 2>&1; then
  useradd --system --no-create-home --shell /usr/sbin/nologin prometheus
fi

install -m 0755 "${repo_root}/prometheus/bin/linux-amd64/prometheus" /usr/local/bin/prometheus
install -m 0755 "${repo_root}/prometheus/bin/linux-amd64/promtool" /usr/local/bin/promtool

install -d -m 0755 "${config_root}/config"
install -d -m 0755 "${config_root}/alert-rules" "${config_root}/recording-rules" "${config_root}/targets"
install -d -o prometheus -g prometheus -m 0750 "${config_root}/secrets" "${data_root}"

cp -a "${repo_root}/prometheus/alert-rules/." "${config_root}/alert-rules/"
cp -a "${repo_root}/prometheus/recording-rules/." "${config_root}/recording-rules/"
cp -a "${repo_root}/prometheus/targets/." "${config_root}/targets/"
install -m 0644 "${repo_root}/prometheus/config/prometheus.yml" "${config_root}/config/prometheus.yml"
install -m 0644 "${repo_root}/prometheus/config/web-config.example.yml" "${config_root}/config/web-config.yml.example"

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[&|\\]/\\&/g'
}
config_root_escaped="$(escape_sed_replacement "${config_root}")"
data_root_escaped="$(escape_sed_replacement "${data_root}")"
unit_tmp="$(mktemp)"
trap 'rm -f "${unit_tmp}"' EXIT
sed \
  -e "s|/etc/prometheus|${config_root_escaped}|g" \
  -e "s|/var/lib/prometheus|${data_root_escaped}|g" \
  "${repo_root}/deployment/systemd/prometheus.service" > "${unit_tmp}"
install -m 0644 "${unit_tmp}" /etc/systemd/system/prometheus.service

chown -R root:prometheus "${config_root}"
chmod 0750 "${config_root}/secrets"
systemctl daemon-reload

echo "Installation files are ready."
echo "Before starting the service:"
echo "  1. Create ${config_root}/config/web-config.yml from its example."
echo "  2. Create exporter password files under ${config_root}/secrets/."
echo "  3. Copy target templates to .json files and replace sample values."
echo "  4. Run: promtool check config ${config_root}/config/prometheus.yml"
echo "  5. Run: systemctl enable --now prometheus"
