#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

data_dir="${APPCONFIG_DATA_DIR:-/archivesspace/data}"
mkdir -p "${data_dir}/tmp"
chown -R archivesspace:archivesspace "${data_dir}" /archivesspace/config

function root_password {
  printf '%s' "${DB_ROOT_PASSWORD:-}"
}

function create_archivesspace_database {
  local root_password_value
  root_password_value="$(root_password)"
  cat <<-SQL | DB_ROOT_PASSWORD="${root_password_value}" create-database.sh
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* to '${DB_USER}'@'%';
FLUSH PRIVILEGES;

SET PASSWORD FOR '${DB_USER}'@'%' = PASSWORD('${DB_PASSWORD}');
SQL
}

if [ -n "${ASPACE_INITIALIZE_PLUGINS:-}" ]; then
  IFS=',' read -r -a plugins <<<"${ASPACE_INITIALIZE_PLUGINS}"
  for plugin in "${plugins[@]}"; do
    s6-setuidgid archivesspace /archivesspace/scripts/initialize-plugin.sh "${plugin}"
  done
fi

rm -rf "${data_dir:?}/tmp"/*

if [ "${ASPACE_DB_MIGRATE:-true}" = "true" ]; then
  if [ -n "$(root_password)" ]; then
    create_archivesspace_database
  fi
  s6-setuidgid archivesspace /archivesspace/scripts/setup-database.sh
fi

exec s6-setuidgid archivesspace /archivesspace/archivesspace.sh
