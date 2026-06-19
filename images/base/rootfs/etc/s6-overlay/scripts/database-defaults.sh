#!/usr/bin/env bash
set -e

# Dervive DB_HOST/DB_PORT from the given driver if not specified.
DB_DRIVER=$(</var/run/s6/container_environment/DB_DRIVER)
case "${DB_DRIVER}" in
none) ;;

mysql)
    DB_HOST=$(</var/run/s6/container_environment/DB_MYSQL_HOST)
    DB_PORT=$(</var/run/s6/container_environment/DB_MYSQL_PORT)
    ;;
*)
    echo "Only MariaDB/MySQL is supported for DB_DRIVER." >&2
    exit 1
    ;;
esac

# Use what has been provided by the user or default to the derived values.
cat <<EOF | /usr/local/bin/confd-import-environment.sh
DB_HOST="{{ getenv "DB_HOST" "${DB_HOST}" }}"
DB_PORT="{{ getenv "DB_PORT" "${DB_PORT}" }}"
EOF
