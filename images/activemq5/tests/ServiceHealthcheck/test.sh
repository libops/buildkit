#!/command/with-contenv bash
# shellcheck shell=bash

# Invoked indirectly by the SIGTERM trap below.
# shellcheck disable=SC2317,SC2329
on_terminate() {
    echo "Termination signal received. Exiting..."
    exit 0
}
trap 'on_terminate' SIGTERM

grep -Fqx 'broker\:user\=name=\ broker:p\\a=ss:word' /opt/activemq/conf/users.properties
grep -Fqx 'operators\:admin\=team=broker:user=name' /opt/activemq/conf/groups.properties

sleep 60

# The kotlin check should be stopping this container
exit 1
