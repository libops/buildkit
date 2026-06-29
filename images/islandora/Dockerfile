# syntax=docker/dockerfile:1.20.0
ARG DRUPAL_BASE=drupal
FROM ${DRUPAL_BASE}

WORKDIR /var/www/drupal

ENV \
    DB_NAME=drupal_default \
    DB_USER=drupal_default \
    DRUPAL_DEFAULT_INSTALL=true \
    DRUPAL_DEFAULT_NAME=Islandora \
    DRUPAL_DEFAULT_PROFILE=standard \
    DRUPAL_ENABLE_HTTPS=true

COPY --link rootfs /

RUN mkdir -p /var/www/drupal && \
    chown -R nginx:nginx /var/www/drupal /usr/share/drush

HEALTHCHECK CMD { [ ! -f /var/www/drupal/web/core/lib/Drupal.php ] || [ -f /installed ]; } && curl -s http://localhost/status | grep -q pool
