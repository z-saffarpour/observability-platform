#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../../.." && pwd)"
config_root="${GRAFANA_CONFIG_ROOT:-/etc/grafana}"
data_root="${GRAFANA_DATA_ROOT:-/var/lib/grafana}"
log_root="${GRAFANA_LOG_ROOT:-/var/log/grafana}"
runtime_root="${GRAFANA_RUNTIME_ROOT:-/usr/local/lib/grafana}"
http_addr="${GRAFANA_HTTP_ADDR:-0.0.0.0}"
http_port="${GRAFANA_HTTP_PORT:-3000}"
domain="${GRAFANA_DOMAIN:-localhost}"
root_url="${GRAFANA_ROOT_URL:-http://${domain}:${http_port}/}"
admin_user="${GRAFANA_ADMIN_USER:-admin}"
admin_password_source="${GRAFANA_ADMIN_PASSWORD_FILE:-}"
prometheus_url="${GRAFANA_PROMETHEUS_URL:-http://localhost:9090}"
prometheus_user="${GRAFANA_PROMETHEUS_USER:-}"
prometheus_password_source="${GRAFANA_PROMETHEUS_PASSWORD_FILE:-}"

for path in "${config_root}" "${data_root}" "${log_root}" "${runtime_root}"; do
  if [[ "${path}" != /* ]] || [[ "${path}" == "/" ]]; then
    echo "Grafana installation paths must be safe absolute paths: ${path}" >&2
    exit 1
  fi
done

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this installer as root." >&2
  exit 1
fi
if [[ ! "${http_port}" =~ ^[0-9]+$ ]] || (( http_port < 1 || http_port > 65535 )); then
  echo "GRAFANA_HTTP_PORT must be between 1 and 65535." >&2
  exit 1
fi
if [[ ! "${prometheus_url}" =~ ^https?:// ]]; then
  echo "GRAFANA_PROMETHEUS_URL must start with http:// or https://." >&2
  exit 1
fi
if { [[ -n "${prometheus_user}" ]] && [[ -z "${prometheus_password_source}" ]]; } ||
   { [[ -z "${prometheus_user}" ]] && [[ -n "${prometheus_password_source}" ]]; }; then
  echo "GRAFANA_PROMETHEUS_USER and GRAFANA_PROMETHEUS_PASSWORD_FILE must be set together." >&2
  exit 1
fi
if [[ -n "${admin_password_source}" && ! -f "${admin_password_source}" ]]; then
  echo "Admin password file was not found: ${admin_password_source}" >&2
  exit 1
fi
if [[ -n "${prometheus_password_source}" && ! -f "${prometheus_password_source}" ]]; then
  echo "Prometheus password file was not found: ${prometheus_password_source}" >&2
  exit 1
fi

grafana_binary="${repo_root}/grafana/bin/linux-amd64/grafana"
shared_runtime="${repo_root}/grafana/runtime"
if [[ ! -f "${grafana_binary}" ]]; then
  echo "Linux Grafana binary is missing: ${grafana_binary}" >&2
  exit 1
fi
if [[ ! -d "${shared_runtime}/public" ]] || [[ ! -f "${shared_runtime}/conf/defaults.ini" ]]; then
  echo "Grafana shared runtime is missing: ${shared_runtime}" >&2
  exit 1
fi

if ! id grafana >/dev/null 2>&1; then
  useradd --system --no-create-home --shell /usr/sbin/nologin grafana
fi

install -d -o root -g root -m 0755 "${runtime_root}"
cp -a "${shared_runtime}/." "${runtime_root}/"
install -d -o root -g root -m 0755 "${runtime_root}/bin"
install -m 0755 "${grafana_binary}" "${runtime_root}/bin/grafana"
chmod 0755 "${runtime_root}/bin/grafana"
find "${runtime_root}" -type d -exec chmod go-w {} +
find "${runtime_root}" -type f -exec chmod go-w {} +

install -d -o root -g grafana -m 0750 "${config_root}"
install -d -o root -g grafana -m 0750 \
  "${config_root}/provisioning/datasources" \
  "${config_root}/provisioning/dashboards" \
  "${config_root}/dashboards" \
  "${config_root}/secrets"
install -d -o grafana -g grafana -m 0750 "${data_root}" "${data_root}/plugins" "${log_root}"
cp -a "${repo_root}/grafana/dashboards/." "${config_root}/dashboards/"
chown -R root:grafana "${config_root}/dashboards"
find "${config_root}/dashboards" -type d -exec chmod 0750 {} +
find "${config_root}/dashboards" -type f -exec chmod 0640 {} +

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[&|\\]/\\&/g'
}
yaml_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "${value}"
}

cookie_secure=false
if [[ "${root_url}" == https://* ]]; then cookie_secure=true; fi
config_tmp="$(mktemp)"
datasource_tmp="$(mktemp)"
dashboard_tmp="$(mktemp)"
unit_tmp="$(mktemp)"
trap 'rm -f "${config_tmp}" "${datasource_tmp}" "${dashboard_tmp}" "${unit_tmp}"' EXIT

sed \
  -e "s|__DATA_ROOT__|$(escape_sed_replacement "${data_root}")|g" \
  -e "s|__LOG_ROOT__|$(escape_sed_replacement "${log_root}")|g" \
  -e "s|__PLUGINS_ROOT__|$(escape_sed_replacement "${data_root}/plugins")|g" \
  -e "s|__CONFIG_ROOT__|$(escape_sed_replacement "${config_root}")|g" \
  -e "s|__HTTP_ADDR__|$(escape_sed_replacement "${http_addr}")|g" \
  -e "s|__HTTP_PORT__|${http_port}|g" \
  -e "s|__DOMAIN__|$(escape_sed_replacement "${domain}")|g" \
  -e "s|__ROOT_URL__|$(escape_sed_replacement "${root_url}")|g" \
  -e "s|__ADMIN_USER__|$(escape_sed_replacement "${admin_user}")|g" \
  -e "s|__COOKIE_SECURE__|${cookie_secure}|g" \
  "${repo_root}/grafana/config/grafana.linux.ini.template" > "${config_tmp}"
install -o root -g grafana -m 0640 "${config_tmp}" "${config_root}/grafana.ini"

if [[ -n "${admin_password_source}" ]]; then
  install -o root -g grafana -m 0640 "${admin_password_source}" "${config_root}/secrets/admin-password"
elif [[ ! -f "${config_root}/secrets/admin-password" ]]; then
  install -o root -g grafana -m 0640 /dev/null "${config_root}/secrets/admin-password"
fi

basic_auth_block=""
if [[ -n "${prometheus_user}" ]]; then
  prometheus_password="$(<"${prometheus_password_source}")"
  basic_auth_block="    basicAuth: true
    basicAuthUser: $(yaml_quote "${prometheus_user}")
    secureJsonData:
      basicAuthPassword: $(yaml_quote "${prometheus_password}")"
fi
sed \
  -e "s|{{PROMETHEUS_URL}}|$(escape_sed_replacement "${prometheus_url}")|g" \
  -e "/{{BASIC_AUTH_BLOCK}}/r /dev/stdin" \
  -e "/{{BASIC_AUTH_BLOCK}}/d" \
  "${repo_root}/grafana/provisioning/datasources/prometheus.yml.template" \
  <<< "${basic_auth_block}" > "${datasource_tmp}"
install -o root -g grafana -m 0640 "${datasource_tmp}" "${config_root}/provisioning/datasources/prometheus.yml"

sed "s|__DASHBOARDS_ROOT__|$(escape_sed_replacement "${config_root}/dashboards")|g" \
  "${repo_root}/grafana/provisioning/dashboards/dashboards.linux.yml.template" > "${dashboard_tmp}"
install -o root -g grafana -m 0640 "${dashboard_tmp}" "${config_root}/provisioning/dashboards/dashboards.yml"

sed \
  -e "s|/usr/local/lib/grafana|$(escape_sed_replacement "${runtime_root}")|g" \
  -e "s|/etc/grafana|$(escape_sed_replacement "${config_root}")|g" \
  -e "s|/var/lib/grafana|$(escape_sed_replacement "${data_root}")|g" \
  -e "s|/var/log/grafana|$(escape_sed_replacement "${log_root}")|g" \
  "${repo_root}/deployment/systemd/grafana.service" > "${unit_tmp}"
install -m 0644 "${unit_tmp}" /etc/systemd/system/grafana.service
systemctl daemon-reload

echo "Grafana installation files are ready."
if [[ ! -s "${config_root}/secrets/admin-password" ]]; then
  echo "Before starting, write the admin password to ${config_root}/secrets/admin-password and set mode 0640."
fi
echo "Validate and start:"
echo "  ${runtime_root}/bin/grafana server --homepath=${runtime_root} --config=${config_root}/grafana.ini --packaging=unknown"
echo "  systemctl enable --now grafana"
echo "  systemctl status grafana"
