#!/usr/bin/env bash
#
# devops/core/includes/compose.sh
#
#   Prepare composer.json for a build and then run `composer install`
#

#
# "Declarations" of the variables this script assumes
#
declare=${SOURCE_REPO_ROOT:=}
declare=${ARTIFACTS_FILE:=}
declare=${DEVOPS_ROOT:=}

#
# Running Composer to install plugins and extra themes
#
announce "......Running Composer in ${SOURCE_REPO_ROOT} to install plugins and extra themes."
composer install \
    --working-dir="${SOURCE_REPO_ROOT}" \
    --classmap-authoritative \
    --no-interaction \
    --prefer-dist \
    --no-progress \
    --no-suggest \
    --ansi \
    >> $ARTIFACTS_FILE 2>&1

#
# Ensure all devops scripts are executable
#
announce "......Again, ensure all scripts in ${DEVOPS_ROOT} are executable"
find "${DEVOPS_ROOT}" | grep "\.sh$" | xargs chmod +x

