FROM scyllaridae

ARG TARGETARCH

EXPOSE 8080

WORKDIR /app

RUN apk add --no-cache \
      openjpeg-tools \
      vips \
      vips-poppler \
      vips-tools && \
    cleanup.sh

COPY --link rootfs /
