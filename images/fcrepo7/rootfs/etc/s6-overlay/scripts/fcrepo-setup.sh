#!/command/with-contenv bash
# shellcheck shell=bash
set -e

function mysql_create_database {
    cat <<-EOF | create-database.sh
-- Create fcrepo database in mariadb or mysql.
CREATE DATABASE IF NOT EXISTS ${FCREPO_DB_NAME} CHARACTER SET utf8 COLLATE utf8_general_ci;

-- Create fcrepo user and grant rights.
CREATE USER IF NOT EXISTS '${FCREPO_DB_USER}'@'%' IDENTIFIED BY '${FCREPO_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${FCREPO_DB_NAME}.* to '${FCREPO_DB_USER}'@'%';
FLUSH PRIVILEGES;

-- Update fcrepo password if changed.
SET PASSWORD FOR ${FCREPO_DB_USER}@'%' = PASSWORD('${FCREPO_DB_PASSWORD}')
EOF
}

# Some persistence backends require setup.
function setup_persistence_backend {
    case "${DB_DRIVER}" in
    none)
        # No action required.
        ;;
    mysql)
        mysql_create_database
        ;;
    *)
        echo "Only mysql is supported for DB_DRIVER." >&2
        exit 1
        ;;
    esac
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
    setup_persistence_backend
    # When bind mounting we need to ensure that we
    # actually can write to the folder.
    chown tomcat:tomcat /data
    # Fcrepo can fail to start if it cannot connect to an broker on startup.
    wait_for_broker
}
main
