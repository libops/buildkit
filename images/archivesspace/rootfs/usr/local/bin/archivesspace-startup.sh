#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

data_dir="${APPCONFIG_DATA_DIR:-/archivesspace/data}"
mkdir -p "${data_dir}/tmp"
chown -R archivesspace:archivesspace "${data_dir}"

function read_secret {
  local name="$1"
  local default="${2:-}"
  local file_var="${name}_FILE"
  local secret_file="${!file_var:-/run/secrets/${name}}"

  if [ -f "${secret_file}" ]; then
    tr -d '\r\n' <"${secret_file}"
    return
  fi
  if [ -n "${!name:-}" ]; then
    printf '%s' "${!name}"
    return
  fi
  printf '%s' "${default}"
}

function database_password {
  if [ -n "${ARCHIVESSPACE_DB_PASSWORD:-}" ] || [ -f "${ARCHIVESSPACE_DB_PASSWORD_FILE:-/run/secrets/ARCHIVESSPACE_DB_PASSWORD}" ]; then
    read_secret ARCHIVESSPACE_DB_PASSWORD changeme
    return
  fi
  read_secret DB_PASSWORD changeme
}

function root_password {
  read_secret DB_ROOT_PASSWORD
}

function create_archivesspace_database {
  local app_password root_password_value
  app_password="$(database_password)"
  root_password_value="$(root_password)"
  cat <<-SQL | DB_ROOT_PASSWORD="${root_password_value}" DB_PASSWORD="${app_password}" create-database.sh
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${app_password}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* to '${DB_USER}'@'%';
FLUSH PRIVILEGES;

SET PASSWORD FOR '${DB_USER}'@'%' = PASSWORD('${app_password}');
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
