#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo 'Run this installer as root (for example: sudo bash ...).' >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${NGINX_SOURCE_ROOT:-$(cd -- "${SCRIPT_DIR}/../../.." && pwd)}"
LISTEN_PORT="${NGINX_LISTEN_PORT:-80}"
OPEN_FIREWALL="${NGINX_OPEN_FIREWALL:-0}"
CONFIG_SOURCE="${SOURCE_ROOT}/nginx/config/linux/observability.conf"
CONFIG_TARGET='/etc/nginx/conf.d/observability.conf'
UNIT_SOURCE="${SOURCE_ROOT}/deployment/systemd/nginx.service"
UNIT_TARGET='/etc/systemd/system/nginx.service'

if [[ ! ${LISTEN_PORT} =~ ^[0-9]+$ ]] || (( LISTEN_PORT < 1 || LISTEN_PORT > 65535 )); then
  echo "Invalid NGINX_LISTEN_PORT: ${LISTEN_PORT}" >&2
  exit 1
fi
if [[ ! -f ${CONFIG_SOURCE} ]]; then
  echo "Required configuration not found: ${CONFIG_SOURCE}" >&2
  exit 1
fi
if [[ ! -f ${UNIT_SOURCE} ]]; then
  echo "Required systemd unit not found: ${UNIT_SOURCE}" >&2
  exit 1
fi
if ! command -v systemctl >/dev/null 2>&1; then
  echo 'systemd is required by this installer.' >&2
  exit 1
fi

install_package() {
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y nginx
  elif command -v yum >/dev/null 2>&1; then
    yum install -y nginx
  else
    echo 'Supported package manager not found (apt-get, dnf, or yum).' >&2
    exit 1
  fi
}

if ! command -v nginx >/dev/null 2>&1; then
  install_package
fi

install -d -m 0755 /etc/nginx/conf.d /var/backups/observability-nginx
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir="/var/backups/observability-nginx/${timestamp}"
install -d -m 0700 "${backup_dir}"

restore_needed=1
restore_config() {
  if (( restore_needed == 0 )); then return; fi
  rm -f -- "${CONFIG_TARGET}"
  if [[ -f ${backup_dir}/observability.conf ]]; then
    cp -a -- "${backup_dir}/observability.conf" "${CONFIG_TARGET}"
  fi
  for entry in default-site default-conf; do
    if [[ -e ${backup_dir}/${entry} || -L ${backup_dir}/${entry} ]]; then
      case ${entry} in
        default-site) mv -- "${backup_dir}/${entry}" /etc/nginx/sites-enabled/default ;;
        default-conf) mv -- "${backup_dir}/${entry}" /etc/nginx/conf.d/default.conf ;;
      esac
    fi
  done
  rm -f -- "${UNIT_TARGET}"
  if [[ -f ${backup_dir}/nginx.service ]]; then
    cp -a -- "${backup_dir}/nginx.service" "${UNIT_TARGET}"
  fi
  systemctl daemon-reload || true
}
trap restore_config ERR

if [[ -f ${CONFIG_TARGET} ]]; then
  cp -a -- "${CONFIG_TARGET}" "${backup_dir}/observability.conf"
fi
if [[ -f ${UNIT_TARGET} ]]; then
  cp -a -- "${UNIT_TARGET}" "${backup_dir}/nginx.service"
fi
if [[ -e /etc/nginx/sites-enabled/default || -L /etc/nginx/sites-enabled/default ]]; then
  mv -- /etc/nginx/sites-enabled/default "${backup_dir}/default-site"
fi
if [[ -f /etc/nginx/conf.d/default.conf ]]; then
  mv -- /etc/nginx/conf.d/default.conf "${backup_dir}/default-conf"
fi

sed -E \
  -e "s/listen [0-9]+ default_server;/listen ${LISTEN_PORT} default_server;/" \
  -e "s/listen \[::\]:[0-9]+ default_server;/listen [::]:${LISTEN_PORT} default_server;/" \
  "${CONFIG_SOURCE}" > "${CONFIG_TARGET}.tmp"
chown root:root "${CONFIG_TARGET}.tmp"
chmod 0644 "${CONFIG_TARGET}.tmp"
mv -f -- "${CONFIG_TARGET}.tmp" "${CONFIG_TARGET}"
install -o root -g root -m 0644 "${UNIT_SOURCE}" "${UNIT_TARGET}"

nginx -t
systemctl daemon-reload
systemctl enable nginx
if systemctl is-active --quiet nginx; then
  systemctl reload nginx
else
  systemctl start nginx
fi

if [[ ${OPEN_FIREWALL} == 1 ]]; then
  if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port="${LISTEN_PORT}/tcp"
    firewall-cmd --reload
  elif command -v ufw >/dev/null 2>&1; then
    ufw allow "${LISTEN_PORT}/tcp"
  else
    echo 'Warning: no supported firewall manager found; no firewall rule was created.' >&2
  fi
fi

restore_needed=0
trap - ERR
echo "Nginx is active on port ${LISTEN_PORT}. Backup: ${backup_dir}"
