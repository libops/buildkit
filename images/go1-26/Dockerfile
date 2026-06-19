FROM base

ARG TARGETARCH

# renovate: datasource=github-tags depName=golang packageName=golang/go versioning=go-mod-directive
ARG SOFTWARE_VERSION=go1.26.4
ARG \
  GO_BASE_URL="https://go.dev/dl/${SOFTWARE_VERSION}" \
  GO_AMD64=linux-amd64.tar.gz \
  GO_AMD64_SHA256="1153d3d50e0ac764b447adfe05c2bcf08e889d42a02e0fe0259bd47f6733ad7f" \
  GO_ARM64=linux-arm64.tar.gz \
  GO_ARM64_SHA256="ef758ae7c6cf9267c9c0ef080b8965f453d89ab2d25d9eb22de4405925238768"

RUN if [ "${TARGETARCH}" = "amd64" ]; \
    then \
        download.sh \
            --url "${GO_BASE_URL}.${GO_AMD64}" \
            --sha256 "${GO_AMD64_SHA256}" \
            --dest /usr/local ; \
    else \
        download.sh \
            --url "${GO_BASE_URL}.${GO_ARM64}" \
            --sha256 "${GO_ARM64_SHA256}" \
            --dest /usr/local ; \
    fi && \
    cleanup.sh

ENV PATH=/usr/local/go/bin:$PATH
