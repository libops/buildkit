# syntax=docker/dockerfile:1.20.0
FROM solr9

ARG TARGETARCH

# renovate: datasource=github-releases depName=archivesspace packageName=archivesspace/archivesspace
ARG SOFTWARE_VERSION=4.2.0
ARG ARCHIVESSPACE_FILE=archivesspace-v${SOFTWARE_VERSION}.zip
ARG ARCHIVESSPACE_URL=https://github.com/archivesspace/archivesspace/releases/download/v${SOFTWARE_VERSION}/${ARCHIVESSPACE_FILE}
ARG ARCHIVESSPACE_SHA256="46dfd77cbb0643d43ddf2555bd9edbb6b63fd8cbfc140bcf81c1238eb8f9eb7f"

RUN --mount=type=cache,id=archivesspace-solr-downloads-${TARGETARCH},sharing=locked,target=/opt/downloads \
    download.sh \
        --url "${ARCHIVESSPACE_URL}" \
        --sha256 "${ARCHIVESSPACE_SHA256}" \
        --dest /tmp/archivesspace-release \
    && \
    mkdir -p /opt/solr/server/solr/configsets/archivesspace/conf && \
    cp -R /tmp/archivesspace-release/archivesspace/solr/. /opt/solr/server/solr/configsets/archivesspace/conf/ && \
    mkdir -p /opt/solr/server/solr/archivesspace && \
    cp -R /opt/solr/server/solr/configsets/archivesspace/. /opt/solr/server/solr/archivesspace/ && \
    printf 'name=archivesspace\n' > /opt/solr/server/solr/archivesspace/core.properties && \
    chown -R solr:solr /opt/solr/server/solr/configsets/archivesspace && \
    chown -R solr:solr /opt/solr/server/solr/archivesspace && \
    rm -rf /tmp/archivesspace-release && \
    cleanup.sh

HEALTHCHECK CMD curl -fsS 'http://localhost:8983/solr/archivesspace/admin/ping?wt=json' | jq -e '.status == "OK"'
