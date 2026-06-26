# syntax=docker/dockerfile:1.20.0
ARG PHP_BASE=nginx-php83
FROM ${PHP_BASE}

ARG TARGETARCH
ARG PHP_FPM_SOCKET=/run/php-fpm83/php-fpm83.sock
ARG PHP_PACKAGE=php83

ARG \
    # renovate: datasource=repology depName=alpine_3_24/antiword
    ANTIWORD_VERSION=0.37-r6 \
    # renovate: datasource=repology depName=alpine_3_24/ghostscript
    GHOSTSCRIPT_VERSION=10.07.1-r0 \
    # renovate: datasource=repology depName=alpine_3_24/npm
    NPM_VERSION=11.12.1-r0 \
    # renovate: datasource=repology depName=alpine_3_24/poppler-utils
    POPPLER_VERSION=25.12.0-r1

EXPOSE 80
WORKDIR /var/www/ojs

RUN --mount=type=cache,id=ojs-apk-${TARGETARCH},sharing=locked,target=/var/cache/apk \
    apk add \
        antiword=="${ANTIWORD_VERSION}" \
        ghostscript=="${GHOSTSCRIPT_VERSION}" \
        npm=="${NPM_VERSION}" \
        poppler-utils=="${POPPLER_VERSION}" \
        "${PHP_PACKAGE}-bcmath" \
        "${PHP_PACKAGE}-ftp" \
        "${PHP_PACKAGE}-gettext" \
    && \
    mkdir -p /var/www/files /var/www/ojs/cache /var/www/ojs/public && \
    chown -R nginx:nginx /var/www/ojs /var/www/files && \
    cleanup.sh

ENV \
    DB_HOST=mariadb \
    DB_PORT=3306 \
    DB_NAME=ojs \
    DB_USER=ojs \
    DB_PASSWORD=changeme \
    OJS_SALT=changeme \
    OJS_API_KEY_SECRET=changeme \
    OJS_SECRET_KEY=changeme \
    OJS_BASE_URL=http://localhost \
    OJS_ADMIN_USERNAME=admin \
    OJS_ADMIN_EMAIL=admin@localhost \
    OJS_ADMIN_PASSWORD=changeme \
    OJS_LOCALE=en \
    OJS_TIMEZONE=UTC \
    OJS_FILES_DIR=/var/www/files \
    OJS_OAI_REPOSITORY_ID=ojs.localhost \
    OJS_ENABLE_BEACON=1 \
    OJS_SESSION_LIFETIME=30 \
    OJS_X_FORWARDED_FOR=Off \
    OJS_SMTP_SERVER=host.docker.internal \
    OJS_SMTP_PORT=25 \
    OJS_DEFAULT_ENVELOPE_SENDER= \
    OJS_ENABLE_HTTPS=false \
    NGINX_CLIENT_BODY_TIMEOUT=60s \
    NGINX_CLIENT_MAX_BODY_SIZE=0 \
    NGINX_ERROR_LOG_LEVEL=warn \
    NGINX_FASTCGI_CONNECT_TIMEOUT=300s \
    NGINX_FASTCGI_READ_TIMEOUT=300s \
    NGINX_FASTCGI_SEND_TIMEOUT=300s \
    NGINX_KEEPALIVE_TIMEOUT=75s \
    NGINX_LINGERING_TIMEOUT=5s \
    NGINX_PROXY_CONNECT_TIMEOUT=60s \
    NGINX_PROXY_READ_TIMEOUT=60s \
    NGINX_PROXY_SEND_TIMEOUT=60s \
    NGINX_REAL_IP_HEADER=X-Forwarded-For \
    NGINX_REAL_IP_RECURSIVE=off \
    NGINX_SEND_TIMEOUT=60s \
    NGINX_SET_REAL_IP_FROM=172.0.0.0/8 \
    NGINX_SET_REAL_IP_FROM2=172.0.0.0/8 \
    NGINX_SET_REAL_IP_FROM3=172.0.0.0/8 \
    NGINX_WORKER_CONNECTIONS=1024 \
    NGINX_WORKER_PROCESSES=auto \
    PHP_FPM_SOCKET=${PHP_FPM_SOCKET} \
    PHP_MAX_EXECUTION_TIME=300 \
    PHP_MAX_INPUT_TIME=300 \
    PHP_DEFAULT_SOCKET_TIMEOUT=300 \
    PHP_REQUEST_TERMINATE_TIMEOUT=300 \
    PHP_MEMORY_LIMIT=256M \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=600000

COPY --link rootfs /

HEALTHCHECK CMD curl -s http://localhost/status | grep -q pool
