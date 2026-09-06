FROM java17

ARG TARGETARCH
# renovate: datasource=custom.apache-downloads depName=apache-activemq5 packageName=activemq
ARG SOFTWARE_VERSION=5.19.11
ARG ACTIVEMQ_FILE="apache-activemq-${SOFTWARE_VERSION}-bin.tar.gz"
ARG ACTIVEMQ_URL="https://archive.apache.org/dist/activemq/${SOFTWARE_VERSION}/${ACTIVEMQ_FILE}"
ARG ACTIVEMQ_FILE_SHA256="c279c5a589962e8fc2463b2b6869de0a08ee9a341487de5072b66b370d85371c"

EXPOSE 61616 5672 61613 1883 61614 8161

WORKDIR /opt/activemq

RUN --mount=type=cache,id=activemq-downloads-${TARGETARCH},sharing=locked,target=/opt/downloads \
    download.sh \
        --url "${ACTIVEMQ_URL}" \
        --sha256 "${ACTIVEMQ_FILE_SHA256}" \
        --dest /opt/activemq \
        --strip \
        examples webapps-demo docs \
    && \
    sed -i '/transportConnector name="stomp"/ s/^[[:space:]]*<!-- \(.*\) -->$/            \1/' conf/activemq.xml \
    && \
    cleanup.sh

# Defaults environment variables to be overloaded.
ENV \
    ACTIVEMQ_AUDIT_LOG_LEVEL=INFO \
    ACTIVEMQ_LOG_LEVEL=INFO \
    ACTIVEMQ_PASSWORD= \
    ACTIVEMQ_USER=admin \
    ACTIVEMQ_WEB_ADMIN_NAME=admin \
    ACTIVEMQ_WEB_ADMIN_PASSWORD= \
    ACTIVEMQ_WEB_ADMIN_ROLES=admin

COPY --link rootfs /

RUN create-service-user.sh --name activemq && \
    cleanup.sh

HEALTHCHECK CMD activemq-healthcheck.sh
