#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

export PATH="/var/www/drupal/vendor/bin:${PATH}"

function mysql_create_database {
    cat <<-SQL | create-database.sh
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* to '${DB_USER}'@'%';
FLUSH PRIVILEGES;

SET PASSWORD FOR ${DB_USER}@'%' = PASSWORD('${DB_PASSWORD}');
SQL
}

function mysql_count_query {
    cat <<-SQL
SELECT COUNT(DISTINCT table_name)
FROM information_schema.columns
WHERE table_schema = '${DB_NAME}';
SQL
}

function installed {
    local count
    count=$(execute-sql-file.sh <(mysql_count_query) -- -N 2>/dev/null) || return 1
    [[ ${count:-0} -ne 0 ]]
}

function setup_directories {
    local site_directory public_files_directory private_files_directory twig_cache_directory
    site_directory="/var/www/drupal/web/sites/${DRUPAL_DEFAULT_SUBDIR}"
    public_files_directory="${site_directory}/files"
    private_files_directory="/var/www/drupal/private"
    twig_cache_directory="${private_files_directory}/php"

    mkdir -p "${site_directory}" "${public_files_directory}" "${private_files_directory}" "${twig_cache_directory}"
    chown nginx:nginx "${site_directory}" "${public_files_directory}" "${private_files_directory}" "${twig_cache_directory}"
    chmod ug+rw "${site_directory}" "${public_files_directory}" "${private_files_directory}" "${twig_cache_directory}"
}

function drush_cache_setup {
    mkdir -p /tmp/drush-/cache
    chmod a+rwx /tmp/drush-/cache
}

function install_site {
    local existing_config_arg=()
    if [[ "${DRUPAL_DEFAULT_INSTALL_EXISTING_CONFIG}" == "true" ]]; then
        existing_config_arg=("--existing-config")
    fi

    drush \
        -n \
        -r /var/www/drupal/web \
        site:install "${DRUPAL_DEFAULT_PROFILE}" \
        "${existing_config_arg[@]}" \
        --sites-subdir="${DRUPAL_DEFAULT_SUBDIR}" \
        --site-name="${DRUPAL_DEFAULT_NAME}" \
        --site-mail="${DRUPAL_DEFAULT_EMAIL}" \
        --account-name="${DRUPAL_DEFAULT_ACCOUNT_NAME}" \
        --account-pass="${DRUPAL_DEFAULT_ACCOUNT_PASSWORD}" \
        --account-mail="${DRUPAL_DEFAULT_ACCOUNT_EMAIL}" \
        --locale="${DRUPAL_DEFAULT_LOCALE}" \
        --db-url="mysql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
}

function run_install_hooks {
    local hook
    if [ ! -d /etc/s6-overlay/scripts/install.d ]; then
        return 0
    fi
    for hook in /etc/s6-overlay/scripts/install.d/*; do
        if [ ! -f "${hook}" ] || [ ! -x "${hook}" ]; then
            continue
        fi
        echo "Running Drupal install hook ${hook}"
        "${hook}"
    done
}

function drush_uri {
    echo "${DRUSH_OPTIONS_URI:-${DRUPAL_DEFAULT_SITE_URL:-http://localhost}}"
}

function rebuild_drupal_cache {
    local uri
    uri="$(drush_uri)"
    drush --root=/var/www/drupal/web --uri="${uri}" cache:rebuild
}

function finished {
    touch /installed
    cat <<-EOT


#####################
# Install Completed #
#####################
EOT
}

function main {
    if [ ! -f /var/www/drupal/web/core/lib/Drupal.php ]; then
        echo "Drupal application files are not present. Skipping Drupal setup."
        return 0
    fi
    if ! command -v drush >/dev/null 2>&1; then
        echo "Drush is not present. Skipping Drupal setup."
        return 0
    fi

    cd /var/www/drupal
    drush_cache_setup
    setup_directories
    mysql_create_database

    if installed; then
        echo "Already Installed"
    else
        echo "Installing"
        install_site
        run_install_hooks
        rebuild_drupal_cache
    fi
    finished
}
main
