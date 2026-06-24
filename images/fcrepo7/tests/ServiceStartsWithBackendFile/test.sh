#!/command/with-contenv bash
# shellcheck shell=bash

# shellcheck disable=SC1091
source /usr/local/share/isle/utilities.sh

function wait_for_fcrepo_rest {
    local address=${1}
    local status

    echo "Waiting for response on ${address}"
    for _ in $(seq 1 48); do
        status=$(curl -s -o /dev/null -w "%{http_code}" "${address}" || true)
        case "${status}" in
            200 | 401)
                return 0
                ;;
        esac
        sleep 5
    done

    echo "Timed out waiting for ${address} (last status: ${status:-none})"
    return 1
}

# Wait for fcrepo to start.
if ! wait_for_fcrepo_rest http://localhost:8080/fcrepo/rest; then
    exit 1
fi

# Add some content.
object=$(curl --fail --user "${TOMCAT_ADMIN_NAME:-admin}:${TOMCAT_ADMIN_PASSWORD:-password}" -X POST -H "Content-Type:text/plain" "http://localhost:8080/fcrepo/rest" 2>/dev/null)
echo "Create Object: $object"

# All tests were successful
exit 0
