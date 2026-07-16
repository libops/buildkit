FROM base

ARG TARGETARCH

# renovate: datasource=github-tags depName=golang packageName=golang/go versioning=go-mod-directive
ARG SOFTWARE_VERSION=go1.26.5
ARG \
  GO_BASE_URL="https://go.dev/dl/${SOFTWARE_VERSION}" \
  GO_AMD64=linux-amd64.tar.gz \
  GO_AMD64_SHA256="5c2c3b16caefa1d968a94c1daca04a7ca301a496d9b086e17ad77bb81393f053" \
  GO_ARM64=linux-arm64.tar.gz \
  GO_ARM64_SHA256="fe4789e92b1f33358680864bbe8704289e7bb5fc207d80623c308935bd696d49"

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
