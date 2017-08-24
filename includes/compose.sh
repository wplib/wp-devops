#!/usr/bin/env bash
#
# devops/core/includes/compose.sh
#
#   Prepare composer.json for a build and then run `composer install`
#

#
# "Declarations" of the variables this script assumes
#
declare=${SHARED_SCRIPTS:=}
declare=${REPO_ROOT:=}
declare=${ARTIFACTS_FILE:=}

announce "Composing project"


#
# Changing directory to repo root
#
announce "...Changing directory to ${REPO_ROOT}"
cd "${REPO_ROOT}"

#
# Running Composer to install plugins and extra themes
#
announce "...Running Composer to install plugins and extra themes."
composer install --prefer-dist >> $ARTIFACTS_FILE

announce "Project composed"
