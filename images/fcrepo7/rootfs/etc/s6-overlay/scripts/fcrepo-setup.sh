#!/command/with-contenv bash
# shellcheck shell=bash
set -e

# shellcheck disable=SC1091
source /usr/local/share/libops/database.sh
# shellcheck disable=SC1091
source /usr/local/share/libops/environment.sh

function mysql_create_database {
    DB_CHARACTER_SET=utf8 \
        DB_COLLATION=utf8_general_ci \
        render-database-bootstrap-sql.sh | create-database.sh
}

function wait_for_broker {
    local tcp="${FCREPO_ACTIVEMQ_BROKER%:*}"
    local host="${tcp##*/}"
    local port="${FCREPO_ACTIVEMQ_BROKER##*:}"

    if timeout 300 wait-for-open-port.sh "${host}" "${port}"; then
        echo "Broker Found at ${host}:${port}"
        return 0
    else
        echo "Could not connect to broker at ${host}:${port}"
        exit 1
    fi
}

function main {
    require_environment_variables DB_HOST DB_NAME DB_USER DB_PASSWORD
    if [ "${DB_HOST}" = "mariadb" ]; then
        database_bootstrap_if_enabled mysql_create_database
    fi
    LIBOPS_DATABASE_PASSWORD="${DB_PASSWORD}" wait-for-database.sh \
        --host "${DB_HOST}" \
        --port "${DB_PORT}" \
        --user "${DB_USER}"
    # When bind mounting we need to ensure that we
    # actually can write to the folder.
    chown tomcat:tomcat /data
    # Fcrepo can fail to start if it cannot connect to an broker on startup.
    wait_for_broker
}
main
