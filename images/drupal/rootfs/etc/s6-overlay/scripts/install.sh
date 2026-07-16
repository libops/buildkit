#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

export PATH="/var/www/drupal/vendor/bin:${PATH}"

# shellcheck source=images/base/rootfs/usr/local/share/libops/database.sh
source "${LIBOPS_DATABASE_LIBRARY:-/usr/local/share/libops/database.sh}"
# shellcheck source=images/base/rootfs/usr/local/share/libops/environment.sh
source "${LIBOPS_ENVIRONMENT_LIBRARY:-/usr/local/share/libops/environment.sh}"

function mysql_create_database {
    DB_CHARACTER_SET=utf8mb4 \
        DB_COLLATION=utf8mb4_unicode_ci \
        render-database-bootstrap-sql.sh | create-database.sh
}

function mysql_count_query {
    cat <<-SQL
SELECT COUNT(DISTINCT table_name)
FROM information_schema.columns
WHERE table_schema = DATABASE();
SQL
}

function installed {
    local count
    count=$(LIBOPS_DATABASE_PASSWORD="${DB_PASSWORD}" execute-sql-file.sh \
        --host "${DB_HOST}" \
        --port "${DB_PORT}" \
        --user "${DB_USER}" \
        --database "${DB_NAME}" \
        <(mysql_count_query) -- -N 2>/dev/null) || return 1
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

    DRUSH_COMMAND_SITE_INSTALL_OPTIONS_ACCOUNT_PASS="${DRUPAL_DEFAULT_ACCOUNT_PASSWORD}" drush \
        -n \
        -r /var/www/drupal/web \
        site:install "${DRUPAL_DEFAULT_PROFILE}" \
        "${existing_config_arg[@]}" \
        --sites-subdir="${DRUPAL_DEFAULT_SUBDIR}" \
        --site-name="${DRUPAL_DEFAULT_NAME}" \
        --site-mail="${DRUPAL_DEFAULT_EMAIL}" \
        --account-name="${DRUPAL_DEFAULT_ACCOUNT_NAME}" \
        --account-mail="${DRUPAL_DEFAULT_ACCOUNT_EMAIL}" \
        --locale="${DRUPAL_DEFAULT_LOCALE}"
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

function ingress_primary_hostname {
    local hostnames hostname
    hostnames="${INGRESS_HOSTNAMES:-localhost}"
    hostname="${hostnames%%,*}"
    hostname="${hostname//[[:space:]]/}"
    echo "${hostname:-localhost}"
}

function ingress_base_url {
    local scheme
    scheme="${INGRESS_SCHEME:-http}"
    echo "${scheme:-http}://$(ingress_primary_hostname)"
}

function drush_uri {
    ingress_base_url
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

    require_environment_variables DB_HOST DB_NAME DB_USER DB_PASSWORD DRUPAL_DEFAULT_SALT

    cd /var/www/drupal
    drush_cache_setup
    setup_directories
    if [ "${DB_HOST}" = "mariadb" ]; then
        database_bootstrap_if_enabled mysql_create_database
    fi

    if installed; then
        echo "Already Installed"
    else
        require_environment_variables DRUPAL_DEFAULT_ACCOUNT_PASSWORD
        echo "Installing"
        install_site
        run_install_hooks
        rebuild_drupal_cache
    fi
    finished
}

if [ "${DRUPAL_SETUP_LIBRARY_ONLY:-false}" != "true" ]; then
    main
fi
