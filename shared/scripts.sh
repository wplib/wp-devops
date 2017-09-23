#!/usr/bin/env bash
#
# devops/core/shared/scripts.sh - Includes files for source
#

declare=${REPO_ROOT:=}
declare=${CIRCLE_BRANCH:=}
declare=${PROD_GIT_USER:=}
declare=${PROD_GIT_REPO:=}
declare=${TARGET_GIT_USER:=}
declare=${TARGET_GIT_REPO:=}
declare=${TARGET_GIT_URL:=}
declare=${ARTIFACTS_FILE:=}
declare=${CIRCLE_ARTIFACTS:=}

#
# Set default deployment options
#
DEPLOY_CORE_PATH="${DEPLOY_CORE_PATH:=}"
DEPLOY_CONTENT_PATH="${DEPLOY_CONTENT_PATH:=wp-content}"
DEPLOY_PORT="${DEPLOY_PORT:=80}"

#
# Set artifacts file for this script
#
ARTIFACTS_FILE="${ARTIFACTS_FILE:="${CIRCLE_ARTIFACTS}/shared-scripts.log"}"

#
# Set an error trap. Uses an $ACTION variable.
#
ACTION=""
announce () {
    ACTION="$1"
    printf "${ACTION}\n"
    printf "${ACTION}\n" >> $ARTIFACTS_FILE
}
onError() {
    if [ $? -ne 0 ] ; then
        printf "FAILED: ${ACTION}.\n"
        exit 1
    fi
}
trap onError ERR

#
# Making artifact subdirectory
#
announce "...Creating artifact file ${ARTIFACTS_FILE}"
echo . > $ARTIFACTS_FILE

# Soon to be added...
# generate-vars.sh

#
# Set the Git user and repo based on the branch
#
announce "...Git branch is ${CIRCLE_BRANCH}; URL is ${TARGET_GIT_URL}"
