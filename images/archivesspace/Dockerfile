# syntax=docker/dockerfile:1.20.0
FROM java17

ARG TARGETARCH

ARG \
    # renovate: datasource=repology depName=alpine_3_24/font-dejavu
    FONT_DEJAVU_VERSION=2.37-r6 \
    # renovate: datasource=repology depName=alpine_3_24/font-liberation
    FONT_LIBERATION_VERSION=2.1.5-r2 \
    # renovate: datasource=repology depName=alpine_3_24/fontconfig
    FONTCONFIG_VERSION=2.17.1-r1 \
    # renovate: datasource=repology depName=alpine_3_24/harfbuzz
    HARFBUZZ_VERSION=13.2.1-r0 \
    # renovate: datasource=repology depName=alpine_3_24/jemalloc
    JEMALLOC_VERSION=5.3.0-r6 \
    # renovate: datasource=repology depName=alpine_3_24/nodejs
    NODEJS_VERSION=24.17.0-r0 \
    # renovate: datasource=repology depName=alpine_3_24/shared-mime-info
    SHARED_MIME_INFO_VERSION=2.4-r7 \
    # renovate: datasource=repology depName=alpine_3_24/unzip
    UNZIP_VERSION=6.0-r16 \
    # renovate: datasource=github-releases depName=archivesspace packageName=archivesspace/archivesspace
    SOFTWARE_VERSION=4.2.0

ARG ARCHIVESSPACE_FILE=archivesspace-v${SOFTWARE_VERSION}.zip
ARG ARCHIVESSPACE_URL=https://github.com/archivesspace/archivesspace/releases/download/v${SOFTWARE_VERSION}/${ARCHIVESSPACE_FILE}
ARG ARCHIVESSPACE_SHA256="46dfd77cbb0643d43ddf2555bd9edbb6b63fd8cbfc140bcf81c1238eb8f9eb7f"
# renovate: datasource=maven depName=mysql-connector-j packageName=com.mysql:mysql-connector-j
ARG MYSQL_CONNECTOR_VERSION=9.1.0
ARG MYSQL_CONNECTOR_FILE=mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.jar
ARG MYSQL_CONNECTOR_URL=https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${MYSQL_CONNECTOR_VERSION}/${MYSQL_CONNECTOR_FILE}
ARG MYSQL_CONNECTOR_SHA256="8776e2ebc46072c9a47ea59d98298c4273bd9f16a7b26b5dfa4744535aa26c62"

EXPOSE 8080 8081 8089 8090 8092
WORKDIR /archivesspace

RUN --mount=type=cache,id=archivesspace-apk-${TARGETARCH},sharing=locked,target=/var/cache/apk \
    apk add \
        font-dejavu=="${FONT_DEJAVU_VERSION}" \
        font-liberation=="${FONT_LIBERATION_VERSION}" \
        fontconfig=="${FONTCONFIG_VERSION}" \
        harfbuzz=="${HARFBUZZ_VERSION}" \
        jemalloc=="${JEMALLOC_VERSION}" \
        nodejs=="${NODEJS_VERSION}" \
        shared-mime-info=="${SHARED_MIME_INFO_VERSION}" \
        unzip=="${UNZIP_VERSION}" \
    && \
    addgroup -S -g 1000 archivesspace && \
    adduser -S -D -H -u 1000 -h /archivesspace -s /sbin/nologin -G archivesspace archivesspace && \
    cleanup.sh

RUN --mount=type=cache,id=archivesspace-downloads-${TARGETARCH},sharing=locked,target=/opt/downloads \
    download.sh \
        --url "${ARCHIVESSPACE_URL}" \
        --sha256 "${ARCHIVESSPACE_SHA256}" \
        --strip \
        --dest /archivesspace \
    && \
    download.sh \
        --url "${MYSQL_CONNECTOR_URL}" \
        --sha256 "${MYSQL_CONNECTOR_SHA256}" \
        --dest /archivesspace/lib \
    && \
    chmod +x /archivesspace/archivesspace.sh /archivesspace/scripts/*.sh && \
    chown -R archivesspace:archivesspace /archivesspace && \
    cleanup.sh

ENV \
    ARCHIVESSPACE_LOGS=/dev/null \
    ASPACE_DB_MIGRATE=true \
    ASPACE_GC_OPTS="-XX:+UseG1GC -XX:NewRatio=1" \
    ASPACE_JAVA_XMX=-Xmx2048m \
    DB_HOST=mariadb \
    DB_NAME=archivesspace \
    DB_PASSWORD=changeme \
    DB_PORT=3306 \
    DB_USER=archivesspace \
    JDK_JAVA_OPTIONS="--add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.io=ALL-UNNAMED" \
    LANG=C.UTF-8 \
    LD_PRELOAD=/usr/lib/libjemalloc.so.2 \
    TZ=UTC

COPY --link rootfs /

HEALTHCHECK CMD wget -q --spider http://localhost:8089/ || exit 1
