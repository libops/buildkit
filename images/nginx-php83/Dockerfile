FROM php83

ARG TARGETARCH

ARG \
    # renovate: datasource=repology depName=alpine_3_24/nginx
  SOFTWARE_VERSION=1.30.2-r1 \

# Platform specific does require arch specific identifier.
RUN --mount=type=cache,id=nginx-php83-apk-${TARGETARCH},sharing=locked,target=/var/cache/apk \
    apk add \
        nginx=="${SOFTWARE_VERSION}" \
    && \
    if ! id -nG nginx | tr ' ' '\n' | grep -qx jwt; then addgroup nginx jwt; fi && \
    cleanup.sh

ENV \
    NGINX_CLIENT_BODY_TIMEOUT=60s \
    NGINX_CLIENT_MAX_BODY_SIZE=0 \
    NGINX_ERROR_LOG_LEVEL=warn \
    NGINX_FASTCGI_CONNECT_TIMEOUT=60s \
    NGINX_FASTCGI_READ_TIMEOUT=60s \
    NGINX_FASTCGI_SEND_TIMEOUT=60s \
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
    NGINX_WORKER_PROCESSES=auto

COPY --link rootfs /

HEALTHCHECK CMD curl -s http://localhost/status | grep -q pool
