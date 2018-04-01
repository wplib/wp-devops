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
declare=${DEPLOY_PROVIDER:=}
declare=${DEPLOY_PROVIDER_ROOT:=}

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
        echo -e "\n"
        echo -e "===========[ BEGIN OUTPUT LOG ]===========\n"
        echo -e "\n"
        cat "${ARTIFACTS_FILE}"
        echo -e "\n"
        echo -e "============[ END OUTPUT LOG ]============\n"
        echo -e "\n"
        exit 1
    fi
}
trap onError ERR

get_provider_specific_script() {
    echo "DEPRECATED: get_provider_specific_script(); use get_provider_script() instead."
    get_provider_script "$1"
}
get_provider_script() {
    echo "${DEPLOY_PROVIDER_ROOT}/${DEPLOY_PROVIDER}-$1"
}
exec_provide_script() {
    do_exec="$(get_provider_specific_script "$1")"
    if [ -f "${do_exec}" ] ; then
        announce "$2"
        source "${DO_DEPLOY_SCRIPT}")"
    fi
}

#
# Making artifact subdirectory
#
announce "...Creating artifact file ${ARTIFACTS_FILE}"
echo . > $ARTIFACTS_FILE

# Soon to be added...
# generate-vars.sh

#
# Making artifact subdirectory
#
announce "...Ensure ~/cache directory"
mkdir -p ~/cache

#
# Set the Git user and repo based on the branch
#
announce "...Git branch is ${CIRCLE_BRANCH}"
announce "...Git URL is ${TARGET_GIT_URL}"


