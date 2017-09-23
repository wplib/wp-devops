#!/usr/bin/env bash
#
# devops/core/includes/compose.sh
#
#   Prepare composer.json for a build and then run `composer install`
#

#
# "Declarations" of the variables this script assumes
#
declare=${REPO_ROOT:=}
declare=${ARTIFACTS_FILE:=}
declare=${DEVOPS_ROOT:=}

announce "Composing project"

#
# Running Composer to install plugins and extra themes
#
announce "...Running Composer in ${REPO_ROOT} to install plugins and extra themes."
composer install \
    --working-dir="${REPO_ROOT}" \
    --classmap-authoritative \
    --no-interaction \
    --prefer-dist \
    --no-progress \
    --no-suggest \
    --ansi \
    >> $ARTIFACTS_FILE

#
# Ensure all devops scripts are executable
#
announce "...Again, ensure all scripts in ${DEVOPS_ROOT} are executable"
find "${DEVOPS_ROOT}" | grep "\.sh$" | xargs chmod +x


announce "Project composed"
