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
  local DOWNLOAD
  local dockerfile
  DOWNLOAD=$(mktemp)

  if ! curl \
    --fail \
    --location \
    --retry 3 \
    --retry-all-errors \
    --connect-timeout 20 \
    --max-time 600 \
    --silent \
    --show-error \
    --output "$DOWNLOAD" \
    "$URL"; then
    rm -f "$DOWNLOAD"
    echo "Failed to download release artifact: $URL" >&2
    return 1
  fi

  SHA=$(shasum -a 256 "$DOWNLOAD" | awk '{print $1}')
  if [[ ! "$SHA" =~ ^[0-9a-f]{64}$ ]]; then
    rm -f "$DOWNLOAD"
    echo "Failed to calculate SHA256 for release artifact: $URL" >&2
    return 1
  fi

  for dockerfile in "${DOCKERFILES[@]}"; do
    if [[ $(grep -Ec "^[[:space:]]*(ARG[[:space:]]+)?${ARG}=\"?[[:xdigit:]]{64}\"?" "${dockerfile}") -ne 1 ]]; then
      rm -f "$DOWNLOAD"
      echo "Expected exactly one existing ${ARG} checksum in ${dockerfile}" >&2
      return 1
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -E -i '' "s|^([[:space:]]*(ARG[[:space:]]+)?${ARG}=)\"?[[:xdigit:]]{64}\"?(.*)$|\\1\"${SHA}\"\\3|" "${dockerfile}"
    else
      sed -E -i "s|^([[:space:]]*(ARG[[:space:]]+)?${ARG}=)\"?[[:xdigit:]]{64}\"?(.*)$|\\1\"${SHA}\"\\3|" "${dockerfile}"
    fi

    if ! grep -Eq "^[[:space:]]*(ARG[[:space:]]+)?${ARG}=\"${SHA}\"" "${dockerfile}"; then
      rm -f "$DOWNLOAD"
      echo "Failed to update ${ARG} in ${dockerfile}" >&2
      return 1
    fi
  done
  rm -f "$DOWNLOAD"
}

update_readme() {
  local README="$1"
  local OLD_VERSION="$2"
  local NEW_VERSION="$3"
  local match_count
  local new_match_count
  local replacement

  if [ -z "$README" ]; then
    return 0
  fi
  if [ ! -f "$README" ]; then
    echo "Configured README does not exist: $README" >&2
    return 1
  fi

  match_count=$(awk -v suffix="${OLD_VERSION}." '
    length($0) >= length(suffix) && substr($0, length($0) - length(suffix) + 1) == suffix { count++ }
    END { print count + 0 }
  ' "$README")
  if [ "$match_count" -ne 1 ]; then
    echo "Expected exactly one README line ending in ${OLD_VERSION}. in ${README}; found ${match_count}" >&2
    return 1
  fi

  replacement=$(mktemp)
  if ! awk -v old_suffix="${OLD_VERSION}." -v new_suffix="${NEW_VERSION}." '
    length($0) >= length(old_suffix) && substr($0, length($0) - length(old_suffix) + 1) == old_suffix {
      print substr($0, 1, length($0) - length(old_suffix)) new_suffix
      next
    }
    { print }
  ' "$README" >"$replacement"; then
    rm -f "$replacement"
    echo "Failed to prepare README update for ${README}" >&2
    return 1
  fi
  if cmp -s "$README" "$replacement"; then
    rm -f "$replacement"
    echo "README replacement did not change ${README}" >&2
    return 1
  fi
  command cat "$replacement" >"$README"
  rm -f "$replacement"

  new_match_count=$(awk -v suffix="${NEW_VERSION}." '
    length($0) >= length(suffix) && substr($0, length($0) - length(suffix) + 1) == suffix { count++ }
    END { print count + 0 }
  ' "$README")
  if [ "$new_match_count" -ne 1 ]; then
    echo "Failed to verify README version ${NEW_VERSION} in ${README}" >&2
    return 1
  fi
}

if [ "${UPDATE_SHA_LIBRARY_ONLY:-false}" = "true" ]; then
  if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    exit 0
  fi
  return 0
fi

echo "Updating SHA for $DEP@$NEW_VERSION"

if [ "$DEP" = "alpaca" ] ; then
  URL="https://github.com/islandora/alpaca/archive/refs/tags/${NEW_VERSION}.tar.gz"
  ARG=ALPACA_SHA256
  DOCKERFILES=("images/alpaca/Dockerfile")
  README="images/alpaca/README.md"

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

elif [ "$DEP" = "islandora-syn-fcrepo6" ]; then
  URL="https://github.com/Islandora/Syn/releases/download/v${NEW_VERSION}/islandora-syn-${NEW_VERSION}-all.jar"
  ARG="SYN_SHA256"
  DOCKERFILES=("images/fcrepo6/Dockerfile")

elif [ "$DEP" = "islandora-syn-fcrepo7" ]; then
  URL="https://github.com/Islandora/Syn/releases/download/v${NEW_VERSION}/islandora-syn-${NEW_VERSION}-all.jar"
  ARG="SYN_SHA256"
  DOCKERFILES=("images/fcrepo7/Dockerfile")

elif [ "$DEP" = "islandora-syn" ]; then
  echo "Use islandora-syn-fcrepo6 or islandora-syn-fcrepo7 so Syn major lines remain independent" >&2
  exit 1

elif [ "$DEP" = "fcrepo-import-export" ]; then
  URL="https://github.com/fcrepo-exts/fcrepo-import-export/releases/download/fcrepo-import-export-${NEW_VERSION}/fcrepo-import-export-${NEW_VERSION}.jar"
  ARG="IMPORT_EXPORT_SHA256"
  DOCKERFILES=("images/fcrepo6/Dockerfile" "images/fcrepo7/Dockerfile")

elif [ "$DEP" = "fcrepo-upgrade-utils" ]; then
  URL="https://github.com/fcrepo-exts/fcrepo-upgrade-utils/releases/download/fcrepo-upgrade-utils-${NEW_VERSION}/fcrepo-upgrade-utils-${NEW_VERSION}.jar"
  ARG="UPGRADE_UTILS_SHA256"
  DOCKERFILES=("images/fcrepo6/Dockerfile" "images/fcrepo7/Dockerfile")

elif [ "$DEP" = "drupal-recommended-project" ]; then
  URL="https://github.com/drupal/recommended-project/archive/refs/tags/${NEW_VERSION}.tar.gz"
  ARG="SHA256"
  DOCKERFILES=("images/drupal/Dockerfile")

elif [ "$DEP" = "islandora-starter-site" ]; then
  URL="https://github.com/Islandora/islandora-starter-site/archive/refs/tags/${NEW_VERSION}.tar.gz"
  ARG="SHA256"
  DOCKERFILES=("images/islandora/Dockerfile")

elif [ "$DEP" = "ojs" ]; then
  URL="https://pkp.sfu.ca/ojs/download/ojs-${NEW_VERSION}.tar.gz"
  ARG="SHA256"
  DOCKERFILES=("images/ojs/Dockerfile")

elif [ "$DEP" = "omeka-s" ]; then
  URL="https://github.com/omeka/omeka-s/releases/download/v${NEW_VERSION}/omeka-s-${NEW_VERSION}.zip"
  ARG="SHA256"
  DOCKERFILES=("images/omeka-s/Dockerfile")

elif [ "$DEP" = "omeka-classic" ]; then
  URL="https://github.com/omeka/Omeka/releases/download/v${NEW_VERSION}/omeka-${NEW_VERSION}.zip"
  ARG="SHA256"
  DOCKERFILES=("images/omeka-classic/Dockerfile")

elif [ "$DEP" = "archivesspace" ]; then
  URL="https://github.com/archivesspace/archivesspace/releases/download/v${NEW_VERSION}/archivesspace-v${NEW_VERSION}.zip"
  ARG="ARCHIVESSPACE_SHA256"
  DOCKERFILES=("images/archivesspace/Dockerfile" "images/archivesspace-solr/Dockerfile")

elif [ "$DEP" = "mysql-connector-j" ]; then
  URL="https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${NEW_VERSION}/mysql-connector-j-${NEW_VERSION}.jar"
  ARG="MYSQL_CONNECTOR_SHA256"
  DOCKERFILES=("images/archivesspace/Dockerfile")

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
  echo "Unsupported dependency: $DEP" >&2
  exit 1
fi

update_dockerfile_sha "$URL" "$ARG" "${DOCKERFILES[@]}"
update_readme "$README" "$OLD_VERSION" "$NEW_VERSION"
