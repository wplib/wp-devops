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
declare=${DEVOPS_ROOT:=}

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

exit 1

composer install --prefer-dist >> $ARTIFACTS_FILE

#
# Ensure all devops scripts are executable
#
announce "...Again, ensure all scripts in ${DEVOPS_ROOT} are executable"
find "${DEVOPS_ROOT}" | grep "\.sh$" | xargs chmod +x


announce "Project composed"
