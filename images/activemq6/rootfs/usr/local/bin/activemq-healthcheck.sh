#!/command/with-contenv bash
# shellcheck shell=bash

set -euo pipefail

# shellcheck disable=SC1091
source /usr/local/share/libops/environment.sh
require_environment_variables ACTIVEMQ_WEB_ADMIN_NAME ACTIVEMQ_WEB_ADMIN_PASSWORD

umask 077
curl_config=$(mktemp -t activemq-healthcheck.XXXXXXXXXX)
trap 'rm -f -- "${curl_config}"' EXIT
chmod 0600 "${curl_config}"

# Keep the credential out of curl's argv. The temporary curl configuration is
# root-only and contains only a derived Basic authorization value.
authorization=$(printf '%s:%s' "${ACTIVEMQ_WEB_ADMIN_NAME}" "${ACTIVEMQ_WEB_ADMIN_PASSWORD}" | base64 | tr -d '\n')
{
    printf '%s\n' 'fail' 'silent' 'show-error'
    printf 'header = "Origin: localhost"\n'
    printf 'header = "Authorization: Basic %s"\n' "${authorization}"
    printf 'url = "%s"\n' 'http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,service=Health/CurrentStatus'
} >"${curl_config}"

curl --config "${curl_config}" | jq -e '.value == "Good"' >/dev/null
