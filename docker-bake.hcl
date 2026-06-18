ARCHES = [
  "amd64",
  "arm64",
]

IMAGES = [
  "activemq5",
  "activemq6",
  "alpaca",
  "base",
  "blazegraph",
  "crayfits",
  "drupal",
  "fcrepo6",
  "fcrepo7",
  "fits",
  "go1-26",
  "homarus",
  "houdini",
  "hypercube",
  "java17",
  "java21",
  "java25",
  "leptonica",
  "mariadb11",
  "mergepdf",
  "nginx-php83",
  "nginx-php84",
  "php83",
  "php84",
  "scyllaridae",
  "solr9",
  "solr10",
  "tomcat9",
  "tomcat11"
]

PUBLISHED_IMAGES = {
  "activemq5" = "activemq"
  "activemq6" = "activemq"
  "alpaca" = "alpaca"
  "base" = "base"
  "blazegraph" = "blazegraph"
  "crayfits" = "crayfits"
  "drupal" = "drupal"
  "fcrepo6" = "fcrepo"
  "fcrepo7" = "fcrepo"
  "fits" = "fits"
  "go1-26" = "go"
  "homarus" = "homarus"
  "houdini" = "houdini"
  "hypercube" = "hypercube"
  "java17" = "java"
  "java21" = "java"
  "java25" = "java"
  "leptonica" = "leptonica"
  "mariadb11" = "mariadb"
  "mergepdf" = "mergepdf"
  "nginx-php83" = "nginx"
  "nginx-php84" = "nginx"
  "php83" = "php"
  "php84" = "php"
  "scyllaridae" = "scyllaridae"
  "solr9" = "solr"
  "solr10" = "solr"
  "tomcat9" = "tomcat"
  "tomcat11" = "tomcat"
}

LOCAL_TAG_SUFFIXES = {
  "activemq5" = "5"
  "activemq6" = "6"
  "alpaca" = ""
  "base" = ""
  "blazegraph" = ""
  "crayfits" = ""
  "drupal" = ""
  "fcrepo6" = "6"
  "fcrepo7" = "7"
  "fits" = ""
  "go1-26" = "1.26"
  "homarus" = ""
  "houdini" = ""
  "hypercube" = ""
  "java17" = "17"
  "java21" = "21"
  "java25" = "25"
  "leptonica" = ""
  "mariadb11" = "11"
  "mergepdf" = ""
  "nginx-php83" = "php8.3"
  "nginx-php84" = "php8.4"
  "php83" = "8.3"
  "php84" = "8.4"
  "scyllaridae" = ""
  "solr9" = "9"
  "solr10" = "10"
  "tomcat9" = "9"
  "tomcat11" = "11"
}

DEPENDENCIES = {
  "activemq5" = ["java17"]
  "activemq6" = ["java25"]
  "alpaca" = ["base", "java17"]
  "base" = []
  "blazegraph" = ["tomcat9"]
  "crayfits" = ["scyllaridae"]
  "drupal" = ["nginx-php83"]
  "fcrepo6" = ["tomcat9"]
  "fcrepo7" = ["tomcat11"]
  "fits" = ["tomcat9"]
  "go1-26" = ["base"]
  "homarus" = ["scyllaridae"]
  "houdini" = ["scyllaridae"]
  "hypercube" = ["scyllaridae", "leptonica"]
  "java17" = ["base"]
  "java21" = ["base"]
  "java25" = ["base"]
  "leptonica" = []
  "mariadb11" = ["base"]
  "mergepdf" = ["scyllaridae", "leptonica"]
  "nginx-php83" = ["php83"]
  "nginx-php84" = ["php84"]
  "php83" = ["base"]
  "php84" = ["base"]
  "scyllaridae" = ["base", "go1-26"]
  "solr9" = ["java17"]
  "solr10" = ["java25"]
  "tomcat9" = ["java17"]
  "tomcat11" = ["java25"]
}

###############################################################################
# Variables
###############################################################################
variable "REPOSITORY" {
  default = "libops"
}

variable "CACHE_FROM_REPOSITORY" {
  default = "libops"
}

variable "CACHE_TO_REPOSITORY" {
  default = "libops"
}

variable "TAGS" {
  # "latest" is reserved for the most recent release.
  # "local" is to distinguish that from builds produced locally.
  # Multiple tags can be specified by using a space " " delimited list.
  default = "local"
}

variable "SOURCE_DATE_EPOCH" {
  default = "0"
}

variable "BRANCH" {
  # Must be specified for ci builds.
  # BRANCH=$(git rev-parse --abbrev-ref HEAD)
  default = ""
}

###############################################################################
# Functions
###############################################################################
function hostArch {
  params = []
  result = equal("linux/amd64", BAKE_LOCAL_PLATFORM) ? "amd64" : "arm64" # Only two platforms supported.
}

function arches {
  params = [image, suffix]
  result = equal("", suffix) ? [for arch in ARCHES: "${image}-${arch}" ] : [ for arch in ARCHES: "${image}-${arch}-${suffix}" ]
}

function dependencies {
  params = [image, suffix]
  result = { for target in DEPENDENCIES[image]: target => notequal("", suffix) ? "target:${target}-${suffix}" : "target:${target}" }
}

function targets {
  params = [suffix]
  result = [for target in IMAGES: "${target}-${suffix}" ]
}

function "tagName" {
  params = [image, tag]
  result = equal("local", tag) && notequal("", LOCAL_TAG_SUFFIXES[image]) ? "${tag}-${LOCAL_TAG_SUFFIXES[image]}" : tag
}

function "tags" {
  params = [image, suffix]
  result = equal("", suffix) ? [for tag in split(" ", TAGS): "${REPOSITORY}/${PUBLISHED_IMAGES[image]}:${tagName(image, tag)}"] : [for tag in split(" ", TAGS): "${REPOSITORY}/${PUBLISHED_IMAGES[image]}:${tagName(image, tag)}-${suffix}"]
}

function "cacheFrom" {
  params = [image, arch]
  result = equal("", arch) ? [] : ["type=registry,ref=${CACHE_FROM_REPOSITORY}/cache:${image}-main-${arch}", notequal("", BRANCH) ? "type=registry,ref=${CACHE_FROM_REPOSITORY}/cache:${image}-${BRANCH}-${arch}" : ""]
}

function "cacheTo" {
  params = [image, arch]
  result = [notequal("", BRANCH) ? "type=registry,oci-mediatypes=true,mode=max,compression=estargz,compression-level=5,ref=${CACHE_TO_REPOSITORY}/cache:${image}-${BRANCH}-${arch}" : ""]
}

function "context" {
  params = [image]
  result = "images/${image}"
}

###############################################################################
# Groups
###############################################################################
group "default" {
  targets = IMAGES
}

group "amd64" {
  targets = targets("amd64")
}

group "arm64" {
  targets = targets("arm64")
}

###############################################################################
# Common target properties.
###############################################################################
target "common" {
  args = {
    # Required for reproducible builds.
    # Requires Buildkit 0.11+
    # See: https://reproducible-builds.org/docs/source-date-epoch/
    SOURCE_DATE_EPOCH = "${SOURCE_DATE_EPOCH}",
  }
  labels = {
    "org.opencontainers.image.url" = "https://github.com/libops/buildkit/"
    "org.opencontainers.image.source" = "https://github.com/libops/buildkit/"
  }
}

target "amd64-common" {
  platforms = ["linux/amd64"]
}

target "arm64-common" {
  platforms = ["linux/arm64"]
}

###############################################################################
# Image specific target properties.
###############################################################################
target "activemq5-common" {
  inherits = ["common"]
  context = context("activemq5")
}

target "activemq6-common" {
  inherits = ["common"]
  context = context("activemq6")
}

target "alpaca-common" {
  inherits = ["common"]
  context = context("alpaca")
}

target "base-common" {
  inherits = ["common"]
  context = context("base")
  contexts = {
    # The digest (sha256 hash) is not platform specific but the digest for the manifest of all platforms.
    # It will be the digest printed when you do: docker pull alpine:3.17.1
    # Not the one displayed on DockerHub.
    alpine = "docker-image://alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b"
  }
}

target "blazegraph-common" {
  inherits = ["common"]
  context = context("blazegraph")
}

target "crayfits-common" {
  inherits = ["common"]
  context = context("crayfits")
}

target "drupal-common" {
  inherits = ["common"]
  context = context("drupal")
}

target "fcrepo6-common" {
  inherits = ["common"]
  context = context("fcrepo6")
}

target "fcrepo7-common" {
  inherits = ["common"]
  context = context("fcrepo7")
}

target "fits-common" {
  inherits = ["common"]
  context = context("fits")
}

target "go1-26-common" {
  inherits = ["common"]
  context = context("go1-26")
}

target "homarus-common" {
  inherits = ["common"]
  context = context("homarus")
}

target "houdini-common" {
  inherits = ["common"]
  context = context("houdini")
}

target "hypercube-common" {
  inherits = ["common"]
  context = context("hypercube")
}

target "java17-common" {
  inherits = ["common"]
  context = context("java17")
}

target "java21-common" {
  inherits = ["common"]
  context = context("java21")
}

target "java25-common" {
  inherits = ["common"]
  context = context("java25")
}

target "leptonica-common" {
  inherits = ["common"]
  context = context("leptonica")
  contexts = {
    # The digest (sha256 hash) is not platform specific but the digest for the manifest of all platforms.
    # It will be the digest printed when you do: docker pull alpine:3.17.1
    # Not the one displayed on DockerHub.
    alpine = "docker-image://alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b"
  }
}

target "mariadb11-common" {
  inherits = ["common"]
  context = context("mariadb11")
}

target "mergepdf-common" {
  inherits = ["common"]
  context = context("mergepdf")
}

target "nginx-php83-common" {
  inherits = ["common"]
  context = context("nginx-php83")
}

target "nginx-php84-common" {
  inherits = ["common"]
  context = context("nginx-php84")
}

target "php83-common" {
  inherits = ["common"]
  context = context("php83")
}

target "php84-common" {
  inherits = ["common"]
  context = context("php84")
}

target "scyllaridae-common" {
  inherits = ["common"]
  context = context("scyllaridae")
}

target "solr9-common" {
  inherits = ["common"]
  context = context("solr9")
}

target "solr10-common" {
  inherits = ["common"]
  context = context("solr10")
}

target "tomcat9-common" {
  inherits = ["common"]
  context = context("tomcat9")
}

target "tomcat11-common" {
  inherits = ["common"]
  context = context("tomcat11")
}

###############################################################################
# Default Image targets for local builds.
###############################################################################
target "activemq5" {
  inherits = ["activemq5-common"]
  contexts = dependencies("activemq5", "")
  cache-from = cacheFrom("activemq5", hostArch())
  tags = tags("activemq5", "")
}

target "activemq6" {
  inherits = ["activemq6-common"]
  contexts = dependencies("activemq6", "")
  cache-from = cacheFrom("activemq6", hostArch())
  tags = tags("activemq6", "")
}

target "alpaca" {
  inherits = ["alpaca-common"]
  contexts = dependencies("alpaca", "")
  cache-from = cacheFrom("alpaca", hostArch())
  tags = tags("alpaca", "")
}

target "base" {
  inherits = ["base-common"]
  cache-from = cacheFrom("base", hostArch())
  tags = tags("base", "")
}

target "blazegraph" {
  inherits = ["blazegraph-common"]
  contexts = dependencies("blazegraph", "")
  cache-from = cacheFrom("blazegraph", hostArch())
  tags = tags("blazegraph", "")
}

target "crayfits" {
  inherits = ["crayfits-common"]
  contexts = dependencies("crayfits", "")
  cache-from = cacheFrom("crayfits", hostArch())
  tags = tags("crayfits", "")
}

target "drupal" {
  inherits = ["drupal-common"]
  contexts = dependencies("drupal", "")
  cache-from = cacheFrom("drupal", hostArch())
  tags = tags("drupal", "")
}

target "fcrepo6" {
  inherits = ["fcrepo6-common"]
  contexts = dependencies("fcrepo6", "")
  cache-from = cacheFrom("fcrepo6", hostArch())
  tags = tags("fcrepo6", "")
}

target "fcrepo7" {
  inherits = ["fcrepo7-common"]
  contexts = dependencies("fcrepo7", "")
  cache-from = cacheFrom("fcrepo7", hostArch())
  tags = tags("fcrepo7", "")
}

target "fits" {
  inherits = ["fits-common"]
  contexts = dependencies("fits", "")
  cache-from = cacheFrom("fits", hostArch())
  tags = tags("fits", "")
}

target "go1-26" {
  inherits = ["go1-26-common"]
  contexts = dependencies("go1-26", "")
  cache-from = cacheFrom("go1-26", hostArch())
  tags = tags("go1-26", "")
}

target "homarus" {
  inherits = ["homarus-common"]
  contexts = dependencies("homarus", "")
  cache-from = cacheFrom("homarus", hostArch())
  tags = tags("homarus", "")
}

target "houdini" {
  inherits = ["houdini-common"]
  contexts = dependencies("houdini", "")
  cache-from = cacheFrom("houdini", hostArch())
  tags = tags("houdini", "")
}

target "hypercube" {
  inherits = ["hypercube-common"]
  contexts = dependencies("hypercube", "")
  cache-from = cacheFrom("hypercube", hostArch())
  tags = tags("hypercube", "")
}

target "java17" {
  inherits = ["java17-common"]
  contexts = dependencies("java17", "")
  cache-from = cacheFrom("java17", hostArch())
  tags = tags("java17", "")
}

target "java21" {
  inherits = ["java21-common"]
  contexts = dependencies("java21", "")
  cache-from = cacheFrom("java21", hostArch())
  tags = tags("java21", "")
}

target "java25" {
  inherits = ["java25-common"]
  contexts = dependencies("java25", "")
  cache-from = cacheFrom("java25", hostArch())
  tags = tags("java25", "")
}

target "leptonica" {
  inherits = ["leptonica-common"]
  cache-from = cacheFrom("leptonica", hostArch())
  tags = tags("leptonica", "")
}

target "mariadb11" {
  inherits = ["mariadb11-common"]
  contexts = dependencies("mariadb11", "")
  cache-from = cacheFrom("mariadb11", hostArch())
  tags = tags("mariadb11", "")
}

target "mergepdf" {
  inherits = ["mergepdf-common"]
  contexts = dependencies("mergepdf", "")
  cache-from = cacheFrom("mergepdf", hostArch())
  tags = tags("mergepdf", "")
}

target "nginx-php83" {
  inherits = ["nginx-php83-common"]
  contexts = dependencies("nginx-php83", "")
  cache-from = cacheFrom("nginx-php83", hostArch())
  tags = tags("nginx-php83", "")
}

target "nginx-php84" {
  inherits = ["nginx-php84-common"]
  contexts = dependencies("nginx-php84", "")
  cache-from = cacheFrom("nginx-php84", hostArch())
  tags = tags("nginx-php84", "")
}

target "php83" {
  inherits = ["php83-common"]
  contexts = dependencies("php83", "")
  cache-from = cacheFrom("php83", hostArch())
  tags = tags("php83", "")
}

target "php84" {
  inherits = ["php84-common"]
  contexts = dependencies("php84", "")
  cache-from = cacheFrom("php84", hostArch())
  tags = tags("php84", "")
}

target "scyllaridae" {
  inherits = ["scyllaridae-common"]
  contexts = dependencies("scyllaridae", "")
  cache-from = cacheFrom("scyllaridae", hostArch())
  tags = tags("scyllaridae", "")
}

target "solr9" {
  inherits = ["solr9-common"]
  contexts = dependencies("solr9", "")
  cache-from = cacheFrom("solr9", hostArch())
  tags = tags("solr9", "")
}

target "solr10" {
  inherits = ["solr10-common"]
  contexts = dependencies("solr10", "")
  cache-from = cacheFrom("solr10", hostArch())
  tags = tags("solr10", "")
}

target "tomcat9" {
  inherits = ["tomcat9-common"]
  contexts = dependencies("tomcat9", "")
  cache-from = cacheFrom("tomcat9", hostArch())
  tags = tags("tomcat9", "")
}

target "tomcat11" {
  inherits = ["tomcat11-common"]
  contexts = dependencies("tomcat11", "")
  cache-from = cacheFrom("tomcat11", hostArch())
  tags = tags("tomcat11", "")
}

###############################################################################
# linux/amd64 targets.
###############################################################################
target "activemq5-amd64" {
  inherits = ["activemq5-common", "amd64-common"]
  contexts = dependencies("activemq5", "amd64")
  cache-from = cacheFrom("activemq5", "amd64")
  cache-to = cacheTo("activemq5", "amd64")
  tags = tags("activemq5", "amd64")
}

target "activemq6-amd64" {
  inherits = ["activemq6-common", "amd64-common"]
  contexts = dependencies("activemq6", "amd64")
  cache-from = cacheFrom("activemq6", "amd64")
  cache-to = cacheTo("activemq6", "amd64")
  tags = tags("activemq6", "amd64")
}

target "alpaca-amd64" {
  inherits = ["alpaca-common", "amd64-common"]
  contexts = dependencies("alpaca", "amd64")
  cache-from = cacheFrom("alpaca", "amd64")
  cache-to = cacheTo("alpaca", "amd64")
  tags = tags("alpaca", "amd64")
}

target "base-amd64" {
  inherits = ["base-common", "amd64-common"]
  cache-from = cacheFrom("base", "amd64")
  cache-to = cacheTo("base", "amd64")
  tags = tags("base", "amd64")
}

target "blazegraph-amd64" {
  inherits = ["blazegraph-common", "amd64-common"]
  contexts = dependencies("blazegraph", "amd64")
  cache-from = cacheFrom("blazegraph", "amd64")
  cache-to = cacheTo("blazegraph", "amd64")
  tags = tags("blazegraph", "amd64")
}

target "crayfits-amd64" {
  inherits = ["crayfits-common", "amd64-common"]
  contexts = dependencies("crayfits", "amd64")
  cache-from = cacheFrom("crayfits", "amd64")
  cache-to = cacheTo("crayfits", "amd64")
  tags = tags("crayfits", "amd64")
}

target "drupal-amd64" {
  inherits = ["drupal-common", "amd64-common"]
  contexts = dependencies("drupal", "amd64")
  cache-from = cacheFrom("drupal", "amd64")
  cache-to = cacheTo("drupal", "amd64")
  tags = tags("drupal", "amd64")
}

target "fcrepo6-amd64" {
  inherits = ["fcrepo6-common", "amd64-common"]
  contexts = dependencies("fcrepo6", "amd64")
  cache-from = cacheFrom("fcrepo6", "amd64")
  cache-to = cacheTo("fcrepo6", "amd64")
  tags = tags("fcrepo6", "amd64")
}

target "fcrepo7-amd64" {
  inherits = ["fcrepo7-common", "amd64-common"]
  contexts = dependencies("fcrepo7", "amd64")
  cache-from = cacheFrom("fcrepo7", "amd64")
  cache-to = cacheTo("fcrepo7", "amd64")
  tags = tags("fcrepo7", "amd64")
}

target "fits-amd64" {
  inherits = ["fits-common", "amd64-common"]
  contexts = dependencies("fits", "amd64")
  cache-from = cacheFrom("fits", "amd64")
  cache-to = cacheTo("fits", "amd64")
  tags = tags("fits", "amd64")
}

target "go1-26-amd64" {
  inherits = ["go1-26-common", "amd64-common"]
  contexts = dependencies("go1-26", "amd64")
  cache-from = cacheFrom("go1-26", "amd64")
  cache-to = cacheTo("go1-26", "amd64")
  tags = tags("go1-26", "amd64")
}

target "homarus-amd64" {
  inherits = ["homarus-common", "amd64-common"]
  contexts = dependencies("homarus", "amd64")
  cache-from = cacheFrom("homarus", "amd64")
  cache-to = cacheTo("homarus", "amd64")
  tags = tags("homarus", "amd64")
}

target "houdini-amd64" {
  inherits = ["houdini-common", "amd64-common"]
  contexts = dependencies("houdini", "amd64")
  cache-from = cacheFrom("houdini", "amd64")
  cache-to = cacheTo("houdini", "amd64")
  tags = tags("houdini", "amd64")
}

target "hypercube-amd64" {
  inherits = ["hypercube-common", "amd64-common"]
  contexts = dependencies("hypercube", "amd64")
  cache-from = cacheFrom("hypercube", "amd64")
  cache-to = cacheTo("hypercube", "amd64")
  tags = tags("hypercube", "amd64")
}

target "java17-amd64" {
  inherits = ["java17-common", "amd64-common"]
  contexts = dependencies("java17", "amd64")
  cache-from = cacheFrom("java17", "amd64")
  cache-to = cacheTo("java17", "amd64")
  tags = tags("java17", "amd64")
}

target "java21-amd64" {
  inherits = ["java21-common", "amd64-common"]
  contexts = dependencies("java21", "amd64")
  cache-from = cacheFrom("java21", "amd64")
  cache-to = cacheTo("java21", "amd64")
  tags = tags("java21", "amd64")
}

target "java25-amd64" {
  inherits = ["java25-common", "amd64-common"]
  contexts = dependencies("java25", "amd64")
  cache-from = cacheFrom("java25", "amd64")
  cache-to = cacheTo("java25", "amd64")
  tags = tags("java25", "amd64")
}

target "leptonica-amd64" {
  inherits = ["leptonica-common", "amd64-common"]
  cache-from = cacheFrom("leptonica", "amd64")
  cache-to = cacheTo("leptonica", "amd64")
  tags = tags("leptonica", "amd64")
}

target "mariadb11-amd64" {
  inherits = ["mariadb11-common", "amd64-common"]
  contexts = dependencies("mariadb11", "amd64")
  cache-from = cacheFrom("mariadb11", "amd64")
  cache-to = cacheTo("mariadb11", "amd64")
  tags = tags("mariadb11", "amd64")
}

target "mergepdf-amd64" {
  inherits = ["mergepdf-common", "amd64-common"]
  contexts = dependencies("mergepdf", "amd64")
  cache-from = cacheFrom("mergepdf", "amd64")
  cache-to = cacheTo("mergepdf", "amd64")
  tags = tags("mergepdf", "amd64")
}

target "nginx-php83-amd64" {
  inherits = ["nginx-php83-common", "amd64-common"]
  contexts = dependencies("nginx-php83", "amd64")
  cache-from = cacheFrom("nginx-php83", "amd64")
  cache-to = cacheTo("nginx-php83", "amd64")
  tags = tags("nginx-php83", "amd64")
}

target "nginx-php84-amd64" {
  inherits = ["nginx-php84-common", "amd64-common"]
  contexts = dependencies("nginx-php84", "amd64")
  cache-from = cacheFrom("nginx-php84", "amd64")
  cache-to = cacheTo("nginx-php84", "amd64")
  tags = tags("nginx-php84", "amd64")
}

target "php83-amd64" {
  inherits = ["php83-common", "amd64-common"]
  contexts = dependencies("php83", "amd64")
  cache-from = cacheFrom("php83", "amd64")
  cache-to = cacheTo("php83", "amd64")
  tags = tags("php83", "amd64")
}

target "php84-amd64" {
  inherits = ["php84-common", "amd64-common"]
  contexts = dependencies("php84", "amd64")
  cache-from = cacheFrom("php84", "amd64")
  cache-to = cacheTo("php84", "amd64")
  tags = tags("php84", "amd64")
}

target "scyllaridae-amd64" {
  inherits = ["scyllaridae-common", "amd64-common"]
  contexts = dependencies("scyllaridae", "amd64")
  cache-from = cacheFrom("scyllaridae", "amd64")
  cache-to = cacheTo("scyllaridae", "amd64")
  tags = tags("scyllaridae", "amd64")
}

target "solr9-amd64" {
  inherits = ["solr9-common", "amd64-common"]
  contexts = dependencies("solr9", "amd64")
  cache-from = cacheFrom("solr9", "amd64")
  cache-to = cacheTo("solr9", "amd64")
  tags = tags("solr9", "amd64")
}

target "solr10-amd64" {
  inherits = ["solr10-common", "amd64-common"]
  contexts = dependencies("solr10", "amd64")
  cache-from = cacheFrom("solr10", "amd64")
  cache-to = cacheTo("solr10", "amd64")
  tags = tags("solr10", "amd64")
}

target "tomcat9-amd64" {
  inherits = ["tomcat9-common", "amd64-common"]
  contexts = dependencies("tomcat9", "amd64")
  cache-from = cacheFrom("tomcat9", "amd64")
  cache-to = cacheTo("tomcat9", "amd64")
  tags = tags("tomcat9", "amd64")
}

target "tomcat11-amd64" {
  inherits = ["tomcat11-common", "amd64-common"]
  contexts = dependencies("tomcat11", "amd64")
  cache-from = cacheFrom("tomcat11", "amd64")
  cache-to = cacheTo("tomcat11", "amd64")
  tags = tags("tomcat11", "amd64")
}

###############################################################################
# linux/arm64 targets.
###############################################################################
target "activemq5-arm64" {
  inherits = ["activemq5-common", "arm64-common"]
  contexts = dependencies("activemq5", "arm64")
  cache-from = cacheFrom("activemq5", "arm64")
  cache-to = cacheTo("activemq5", "arm64")
  tags = tags("activemq5", "arm64")
}

target "activemq6-arm64" {
  inherits = ["activemq6-common", "arm64-common"]
  contexts = dependencies("activemq6", "arm64")
  cache-from = cacheFrom("activemq6", "arm64")
  cache-to = cacheTo("activemq6", "arm64")
  tags = tags("activemq6", "arm64")
}

target "alpaca-arm64" {
  inherits = ["alpaca-common", "arm64-common"]
  contexts = dependencies("alpaca", "arm64")
  cache-from = cacheFrom("alpaca", "arm64")
  cache-to = cacheTo("alpaca", "arm64")
  tags = tags("alpaca", "arm64")
}

target "base-arm64" {
  inherits = ["base-common", "arm64-common"]
  cache-from = cacheFrom("base", "arm64")
  cache-to = cacheTo("base", "arm64")
  tags = tags("base", "arm64")
}

target "blazegraph-arm64" {
  inherits = ["blazegraph-common", "arm64-common"]
  contexts = dependencies("blazegraph", "arm64")
  cache-from = cacheFrom("blazegraph", "arm64")
  cache-to = cacheTo("blazegraph", "arm64")
  tags = tags("blazegraph", "arm64")
}

target "crayfits-arm64" {
  inherits = ["crayfits-common", "arm64-common"]
  contexts = dependencies("crayfits", "arm64")
  cache-from = cacheFrom("crayfits", "arm64")
  cache-to = cacheTo("crayfits", "arm64")
  tags = tags("crayfits", "arm64")
}

target "drupal-arm64" {
  inherits = ["drupal-common", "arm64-common"]
  contexts = dependencies("drupal", "arm64")
  cache-from = cacheFrom("drupal", "arm64")
  cache-to = cacheTo("drupal", "arm64")
  tags = tags("drupal", "arm64")
}

target "fcrepo6-arm64" {
  inherits = ["fcrepo6-common", "arm64-common"]
  contexts = dependencies("fcrepo6", "arm64")
  cache-from = cacheFrom("fcrepo6", "arm64")
  cache-to = cacheTo("fcrepo6", "arm64")
  tags = tags("fcrepo6", "arm64")
}

target "fcrepo7-arm64" {
  inherits = ["fcrepo7-common", "arm64-common"]
  contexts = dependencies("fcrepo7", "arm64")
  cache-from = cacheFrom("fcrepo7", "arm64")
  cache-to = cacheTo("fcrepo7", "arm64")
  tags = tags("fcrepo7", "arm64")
}

target "fits-arm64" {
  inherits = ["fits-common", "arm64-common"]
  contexts = dependencies("fits", "arm64")
  cache-from = cacheFrom("fits", "arm64")
  cache-to = cacheTo("fits", "arm64")
  tags = tags("fits", "arm64")
}

target "go1-26-arm64" {
  inherits = ["go1-26-common", "arm64-common"]
  contexts = dependencies("go1-26", "arm64")
  cache-from = cacheFrom("go1-26", "arm64")
  cache-to = cacheTo("go1-26", "arm64")
  tags = tags("go1-26", "arm64")
}

target "homarus-arm64" {
  inherits = ["homarus-common", "arm64-common"]
  contexts = dependencies("homarus", "arm64")
  cache-from = cacheFrom("homarus", "arm64")
  cache-to = cacheTo("homarus", "arm64")
  tags = tags("homarus", "arm64")
}

target "houdini-arm64" {
  inherits = ["houdini-common", "arm64-common"]
  contexts = dependencies("houdini", "arm64")
  cache-from = cacheFrom("houdini", "arm64")
  cache-to = cacheTo("houdini", "arm64")
  tags = tags("houdini", "arm64")
}

target "hypercube-arm64" {
  inherits = ["hypercube-common", "arm64-common"]
  contexts = dependencies("hypercube", "arm64")
  cache-from = cacheFrom("hypercube", "arm64")
  cache-to = cacheTo("hypercube", "arm64")
  tags = tags("hypercube", "arm64")
}

target "java17-arm64" {
  inherits = ["java17-common", "arm64-common"]
  contexts = dependencies("java17", "arm64")
  cache-from = cacheFrom("java17", "arm64")
  cache-to = cacheTo("java17", "arm64")
  tags = tags("java17", "arm64")
}

target "java21-arm64" {
  inherits = ["java21-common", "arm64-common"]
  contexts = dependencies("java21", "arm64")
  cache-from = cacheFrom("java21", "arm64")
  cache-to = cacheTo("java21", "arm64")
  tags = tags("java21", "arm64")
}

target "java25-arm64" {
  inherits = ["java25-common", "arm64-common"]
  contexts = dependencies("java25", "arm64")
  cache-from = cacheFrom("java25", "arm64")
  cache-to = cacheTo("java25", "arm64")
  tags = tags("java25", "arm64")
}

target "leptonica-arm64" {
  inherits = ["leptonica-common", "arm64-common"]
  cache-from = cacheFrom("leptonica", "arm64")
  cache-to = cacheTo("leptonica", "arm64")
  tags = tags("leptonica", "arm64")
}

target "mariadb11-arm64" {
  inherits = ["mariadb11-common", "arm64-common"]
  contexts = dependencies("mariadb11", "arm64")
  cache-from = cacheFrom("mariadb11", "arm64")
  cache-to = cacheTo("mariadb11", "arm64")
  tags = tags("mariadb11", "arm64")
}

target "mergepdf-arm64" {
  inherits = ["mergepdf-common", "arm64-common"]
  contexts = dependencies("mergepdf", "arm64")
  cache-from = cacheFrom("mergepdf", "arm64")
  cache-to = cacheTo("mergepdf", "arm64")
  tags = tags("mergepdf", "arm64")
}

target "nginx-php83-arm64" {
  inherits = ["nginx-php83-common", "arm64-common"]
  contexts = dependencies("nginx-php83", "arm64")
  cache-from = cacheFrom("nginx-php83", "arm64")
  cache-to = cacheTo("nginx-php83", "arm64")
  tags = tags("nginx-php83", "arm64")
}

target "nginx-php84-arm64" {
  inherits = ["nginx-php84-common", "arm64-common"]
  contexts = dependencies("nginx-php84", "arm64")
  cache-from = cacheFrom("nginx-php84", "arm64")
  cache-to = cacheTo("nginx-php84", "arm64")
  tags = tags("nginx-php84", "arm64")
}

target "php83-arm64" {
  inherits = ["php83-common", "arm64-common"]
  contexts = dependencies("php83", "arm64")
  cache-from = cacheFrom("php83", "arm64")
  cache-to = cacheTo("php83", "arm64")
  tags = tags("php83", "arm64")
}

target "php84-arm64" {
  inherits = ["php84-common", "arm64-common"]
  contexts = dependencies("php84", "arm64")
  cache-from = cacheFrom("php84", "arm64")
  cache-to = cacheTo("php84", "arm64")
  tags = tags("php84", "arm64")
}

target "scyllaridae-arm64" {
  inherits = ["scyllaridae-common", "arm64-common"]
  contexts = dependencies("scyllaridae", "arm64")
  cache-from = cacheFrom("scyllaridae", "arm64")
  cache-to = cacheTo("scyllaridae", "arm64")
  tags = tags("scyllaridae", "arm64")
}

target "solr9-arm64" {
  inherits = ["solr9-common", "arm64-common"]
  contexts = dependencies("solr9", "arm64")
  cache-from = cacheFrom("solr9", "arm64")
  cache-to = cacheTo("solr9", "arm64")
  tags = tags("solr9", "arm64")
}

target "solr10-arm64" {
  inherits = ["solr10-common", "arm64-common"]
  contexts = dependencies("solr10", "arm64")
  cache-from = cacheFrom("solr10", "arm64")
  cache-to = cacheTo("solr10", "arm64")
  tags = tags("solr10", "arm64")
}

target "tomcat9-arm64" {
  inherits = ["tomcat9-common", "arm64-common"]
  contexts = dependencies("tomcat9", "arm64")
  cache-from = cacheFrom("tomcat9", "arm64")
  cache-to = cacheTo("tomcat9", "arm64")
  tags = tags("tomcat9", "arm64")
}

target "tomcat11-arm64" {
  inherits = ["tomcat11-common", "arm64-common"]
  contexts = dependencies("tomcat11", "arm64")
  cache-from = cacheFrom("tomcat11", "arm64")
  cache-to = cacheTo("tomcat11", "arm64")
  tags = tags("tomcat11", "arm64")
}
