#!/command/with-contenv bash
# shellcheck shell=bash
JAVA_OPTS="${TOMCAT_JAVA_OPTS}"
export JAVA_OPTS
CATALINA_OPTS="${TOMCAT_CATALINA_OPTS}"
CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.home=/data/home"
CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.velocity.runtime.log=/dev/stdout"
CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.jms.baseUrl=http://${HOSTNAME}/fcrepo/rest"
CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.external.content.allowed=/opt/tomcat/conf/allowed-external-content.txt"
CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.autoversioning.enabled=false"
CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.activemq.directory=file:///data/home/data/Activemq"
CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.activemq.configuration=file:///opt/tomcat/conf/activemq.xml"
CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.session.timeout=${FCREPO_SESSION_TIMEOUT:-180000}"
CATALINA_OPTS="${CATALINA_OPTS} -DconnectionTimeout=${FCREPO_CATALINA_TIMEOUT:=-1}"
CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.db.url=jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}"
CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.db.user=${DB_USER}"
CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.db.password=${DB_PASSWORD}"

if [[ "${FCREPO_DISABLE_SYN}" == "true" ]]; then
    CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.properties.management=relaxed"
fi

CATALINA_OPTS="${CATALINA_OPTS} -Dfcrepo.storage=ocfl-fs"

export CATALINA_OPTS
