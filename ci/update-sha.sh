#!/usr/bin/env bash

set -eou pipefail

DEP=$1
OLD_VERSION=$2
NEW_VERSION=$3
# Renovate passes newDigest to this generic task, but this script recalculates
# artifact SHA256 values from downloaded release files.
: "${4?Renovate newDigest argument is required, even if empty}"
URL=""
ARG=""
DOCKERFILES=()
README=""

# Function to update the Dockerfile(s) ARG SHA256 value
update_dockerfile_sha() {
  local URL="$1"
  local ARG="$2"
  local DOCKERFILES=("${@:3}")
  local SHA
  curl -fLs "$URL" -o curl.resp || echo "Request failed with exit code $?"
  SHA=$(shasum -a 256 curl.resp | awk '{print $1}')

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's|^ARG '"$ARG"'=.*|ARG '"$ARG"'="'"$SHA"'"|g' "${DOCKERFILES[@]}"
  else
    sed -i 's|^ARG '"$ARG"'=.*|ARG '"$ARG"'="'"$SHA"'"|g' "${DOCKERFILES[@]}"
  fi
  rm curl.resp
}

update_readme() {
  local README="$1"
  local OLD_VERSION="$2"
  local NEW_VERSION="$3"
  # update the README to specify the new version
  if [ "$README" != "" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/${OLD_VERSION}\.$/${NEW_VERSION}\./" "$README"
    else
      sed -i "s/${OLD_VERSION}\.$/${NEW_VERSION}\./" "$README"
    fi
  fi
}

echo "Updating SHA for $DEP@$NEW_VERSION"

if [ "$DEP" = "alpaca" ] ; then
  URL="https://github.com/islandora/alpaca/archive/refs/tags/${NEW_VERSION}.tar.gz"
  ARG=ALPACA_SHA256
  DOCKERFILES=("images/alpaca/Dockerfile")

elif [ "$DEP" = "apache-tomcat9" ]; then
  URL="https://downloads.apache.org/tomcat/tomcat-9/v$NEW_VERSION/bin/apache-tomcat-$NEW_VERSION.tar.gz"
  ARG="TOMCAT_FILE_SHA256"
  DOCKERFILES=("images/tomcat9/Dockerfile")
  README="images/tomcat9/README.md"

elif [ "$DEP" = "apache-tomcat11" ]; then
  URL="https://downloads.apache.org/tomcat/tomcat-11/v$NEW_VERSION/bin/apache-tomcat-$NEW_VERSION.tar.gz"
  ARG="TOMCAT_FILE_SHA256"
  DOCKERFILES=("images/tomcat11/Dockerfile")
  README="images/tomcat11/README.md"

elif [ "$DEP" = "apache-activemq5" ]; then
  URL="https://downloads.apache.org/activemq/$NEW_VERSION/apache-activemq-$NEW_VERSION-bin.tar.gz"
  ARG="ACTIVEMQ_FILE_SHA256"
  DOCKERFILES=("images/activemq5/Dockerfile")
  README="images/activemq5/README.md"

elif [ "$DEP" = "apache-activemq6" ]; then
  URL="https://downloads.apache.org/activemq/$NEW_VERSION/apache-activemq-$NEW_VERSION-bin.tar.gz"
  ARG="ACTIVEMQ_FILE_SHA256"
  DOCKERFILES=("images/activemq6/Dockerfile")
  README="images/activemq6/README.md"

elif [ "$DEP" = "apache-solr9" ]; then
  URL="https://downloads.apache.org/solr/solr/$NEW_VERSION/solr-$NEW_VERSION.tgz"
  ARG="SOLR_FILE_SHA256"
  DOCKERFILES=("images/solr9/Dockerfile")
  README="images/solr9/README.md"

elif [ "$DEP" = "apache-solr10" ]; then
  URL="https://downloads.apache.org/solr/solr/$NEW_VERSION/solr-$NEW_VERSION.tgz"
  ARG="SOLR_FILE_SHA256"
  DOCKERFILES=("images/solr10/Dockerfile")
  README="images/solr10/README.md"

elif [ "$DEP" = "custom-composer" ]; then
  URL="https://getcomposer.org/download/${NEW_VERSION}/composer.phar"
  ARG="COMPOSER_SHA256"
  DOCKERFILES=("images/php83/Dockerfile" "images/php84/Dockerfile")

elif [ "$DEP" = "solr-ocrhighlighting" ]; then
  URL=https://github.com/dbmdz/solr-ocrhighlighting/releases/download/${NEW_VERSION}/solr-ocrhighlighting-${NEW_VERSION}.jar
  ARG="OCRHIGHLIGHT_FILE_SHA256"
  DOCKERFILES=("images/solr9/Dockerfile" "images/solr10/Dockerfile")

elif [ "$DEP" = "fcrepo6" ]; then
  URL="https://github.com/fcrepo/fcrepo/releases/download/fcrepo-${NEW_VERSION}/fcrepo-webapp-${NEW_VERSION}.war"
  ARG="FCREPO_SHA256"
  DOCKERFILES=("images/fcrepo6/Dockerfile")
  README="images/fcrepo6/README.md"

elif [ "$DEP" = "fcrepo7" ]; then
  URL="https://github.com/fcrepo/fcrepo/releases/download/fcrepo-${NEW_VERSION}/fcrepo-webapp-${NEW_VERSION}.war"
  ARG="FCREPO_SHA256"
  DOCKERFILES=("images/fcrepo7/Dockerfile")
  README="images/fcrepo7/README.md"

elif [ "$DEP" = "islandora-syn" ]; then
  URL="https://github.com/Islandora/Syn/releases/download/v${NEW_VERSION}/islandora-syn-${NEW_VERSION}-all.jar"
  ARG="SYN_SHA256"
  DOCKERFILES=("images/fcrepo6/Dockerfile" "images/fcrepo7/Dockerfile")

elif [ "$DEP" = "fcrepo-import-export" ]; then
  URL="https://github.com/fcrepo-exts/fcrepo-import-export/releases/download/fcrepo-import-export-${NEW_VERSION}/fcrepo-import-export-${NEW_VERSION}.jar"
  ARG="IMPORT_EXPORT_SHA256"
  DOCKERFILES=("images/fcrepo6/Dockerfile" "images/fcrepo7/Dockerfile")

elif [ "$DEP" = "fcrepo-upgrade-utils" ]; then
  URL="https://github.com/fcrepo-exts/fcrepo-upgrade-utils/releases/download/fcrepo-upgrade-utils-${NEW_VERSION}/fcrepo-upgrade-utils-${NEW_VERSION}.jar"
  ARG="UPGRADE_UTILS_SHA256"
  DOCKERFILES=("images/fcrepo6/Dockerfile" "images/fcrepo7/Dockerfile")

elif [ "$DEP" = "fits-servlet" ]; then
  URL="https://github.com/harvard-lts/FITSservlet/releases/download/${NEW_VERSION}/fits-service-${NEW_VERSION}.war"
  ARG="FITSSERVLET_SHA256"
  DOCKERFILES=("images/fits/Dockerfile")

elif [ "$DEP" = "fits" ]; then
  URL="https://github.com/harvard-lts/fits/releases/download/${NEW_VERSION}/fits-${NEW_VERSION}.zip"
  ARG="FITS_SHA256"
  DOCKERFILES=("images/fits/Dockerfile")
  README="images/fits/README.md"

elif [ "$DEP" = "apache-log4j" ]; then
  URL="https://archive.apache.org/dist/logging/log4j/${NEW_VERSION}/apache-log4j-${NEW_VERSION}-bin.zip"
  ARG="LOG4J_FILE_SHA256"
  DOCKERFILES=(
    "images/blazegraph/Dockerfile"
    "images/fits/Dockerfile"
  )

elif [ "$DEP" = "golang" ]; then
  BASE_URL="https://go.dev/dl/${NEW_VERSION}"
  declare -A URLS_AND_ARGS=(
    ["GO_AMD64_SHA256"]="$BASE_URL.linux-amd64.tar.gz"
    ["GO_ARM64_SHA256"]="$BASE_URL.linux-arm64.tar.gz"
  )

  for ARG in "${!URLS_AND_ARGS[@]}"; do
    URL="${URLS_AND_ARGS[$ARG]}"
    update_dockerfile_sha "$URL" "$ARG" "images/go1-26/Dockerfile"
  done

  exit 0

elif [ "$DEP" = "scyllaridae" ] ; then
  URL="https://github.com/libops/scyllaridae/archive/refs/tags/${NEW_VERSION}.tar.gz"
  ARG=SCYLLARIDAE_SHA256
  DOCKERFILES=("images/scyllaridae/Dockerfile")

elif [ "$DEP" = "s6-overlay" ]; then
  BASE_URL="https://github.com/just-containers/s6-overlay/releases/download/v${NEW_VERSION}"
  declare -A URLS_AND_ARGS=(
    ["S6_OVERLAY_NOARCH_SHA256"]="$BASE_URL/s6-overlay-noarch.tar.xz"
    ["S6_OVERLAY_SYMLINKS_ARCH_SHA256"]="$BASE_URL/s6-overlay-symlinks-arch.tar.xz"
    ["S6_OVERLAY_SYMLINKS_NOARCH_SHA256"]="$BASE_URL/s6-overlay-symlinks-noarch.tar.xz"
    ["S6_OVERLAY_AMD64_SHA256"]="$BASE_URL/s6-overlay-x86_64.tar.xz"
    ["S6_OVERLAY_ARM64_SHA256"]="$BASE_URL/s6-overlay-aarch64.tar.xz"
  )

  for ARG in "${!URLS_AND_ARGS[@]}"; do
    URL="${URLS_AND_ARGS[$ARG]}"
    update_dockerfile_sha "$URL" "$ARG" "images/base/Dockerfile"
  done

  exit 0
else
  echo "DEP not found"
  exit 0
fi

update_dockerfile_sha "$URL" "$ARG" "${DOCKERFILES[@]}"
update_readme "$README" "$OLD_VERSION" "$NEW_VERSION"
