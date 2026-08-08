#!/usr/bin/env bash

set -euo pipefail

export DRUPAL_SETUP_LIBRARY_ONLY=true
export LIBOPS_DATABASE_LIBRARY="$1"
export LIBOPS_ENVIRONMENT_LIBRARY="$2"
export DB_NAME="external-db-'quoted"
source "$3"

query="$(mysql_count_query)"
grep -Fq 'WHERE table_schema = DATABASE();' <<<"${query}"
if grep -Fq "${DB_NAME}" <<<"${query}"; then
  exit 1
fi
