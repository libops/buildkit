FROM go1-26 AS builder

WORKDIR /build

# renovate: datasource=github-releases depName=scyllaridae packageName=islandora/scyllaridae
ARG SOFTWARE_VERSION=5.2.10
ARG SCYLLARIDAE_URL="https://github.com/islandora/scyllaridae/archive/refs/tags/${SOFTWARE_VERSION}.tar.gz"
ARG SCYLLARIDAE_SHA256="c68075673b604a7ffeeaffad5a50afa146e61e7047559a3d4d1c020975d0e484"
RUN download.sh \
      --url "${SCYLLARIDAE_URL}" \
      --sha256 "${SCYLLARIDAE_SHA256}" \
      --dest .

WORKDIR /build/scyllaridae-${SOFTWARE_VERSION}

RUN go build -o ../scyllaridae -ldflags="-s -w" .

FROM base

COPY --from=builder /build/scyllaridae /app/scyllaridae

ARG \
  # renovate: datasource=repology depName=alpine_3_24/mailcap
  MAILCAP_VERSION=2.1.54-r0

RUN --mount=type=cache,id=scyllaridae-apk-${TARGETARCH},sharing=locked,target=/var/cache/apk \
    apk add mailcap=="${MAILCAP_VERSION}" && \
    create-service-user.sh --name scyllaridae /app && \
    cleanup.sh

ENV \
  SCYLLARIDAE_ALLOW_INSECURE_ARGS="false" \
  SCYLLARIDAE_LOG_LEVEL=INFO \
  SCYLLARIDAE_PORT=8080 \
  SCYLLARIDAE_YML_PATH="/app/scyllaridae.yml"

COPY --link rootfs /
