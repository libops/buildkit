#!/command/with-contenv bash
# shellcheck shell=bash
set -euo pipefail

# shellcheck disable=SC1091
source /etc/islandora/utilities.sh

readonly SITE="default"

function drush_uri {
    echo "${DRUSH_OPTIONS_URI:-${DRUPAL_DEFAULT_SITE_URL:-http://localhost}}"
}

function rebuild_drupal_cache {
    local uri params
    uri="$(drush_uri)"
    params=$(/var/www/drupal/web/core/scripts/rebuild_token_calculator.sh 2>/dev/null || true)
    if [ -n "${params}" ]; then
        curl -fsSL "${uri}/core/rebuild.php?${params}" >/dev/null || true
    fi
    drush --root=/var/www/drupal --uri="${uri}" cache:rebuild
}

function configure_islandora {
    local uri
    uri="$(drush_uri)"

    rebuild_drupal_cache
    if [ -n "${DRUPAL_DEFAULT_FCREPO_URL:-}" ]; then
        drush --root=/var/www/drupal --uri="${uri}" user:role:add fedoraadmin admin
    fi
    drush --root=/var/www/drupal --uri="${uri}" -y pm:uninstall pgsql sqlite || \
        echo "Could not uninstall unused database drivers; continuing." >&2
    drush --root=/var/www/drupal --uri="${uri}" migrate:import --tag=islandora
    drush --root=/var/www/drupal --uri="${uri}" cron || true
    drush --root=/var/www/drupal --uri="${uri}" search-api:index || true
}

function main {
    cd /var/www/drupal

    configure_islandora
}

main
