#!/usr/bin/env bash
#
#    Copyright 2018 NewClarity Consulting, LLC
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

set -eo pipefail

export CL_LOADED=${CL_LOADED:-0}
if [ 0 -eq $CL_LOADED ]; then

    if [ "" == "${CIRCLE_WORKING_DIRECTORY:=}" ] ; then
        CI_CIRCLECI_DIR="$(pwd)/../$(dirname "$(dirname "$0")")"
    else
        # See https://stackoverflow.com/a/27485157/102699
        CI_CIRCLECI_DIR="${CIRCLE_WORKING_DIRECTORY/#\~/$HOME}/.circleci"
    fi
    export CI_CIRCLECI_DIR="$(realpath "${CI_CIRCLECI_DIR}")"

    export CI_WP_DEVOPS_DIR="${CI_CIRCLECI_DIR}/wp-devops"
    export CI_SOURCED_FILE="${CI_SOURCED_FILE:="${CI_WP_DEVOPS_DIR}/sourced.sh"}"
    export CI_PROJECT_DIR="$(dirname "${CI_CIRCLECI_DIR}")"
    export CI_TMP_DIR="${HOME}/tmp"
    mkdir -p "${CI_TMP_DIR}"

    export CI_INCLUDES_DIR="${CI_WP_DEVOPS_DIR}/includes"
    export CI_DEPLOY_REPO_DIR="${HOME}/deploy"

    export CI_ERR_RESULT=0
    export CI_PUSHD_FILE="/tmp/pushd"
    export CI_PUSHD_COUNTER=0

    export CI_DEPLOY_LOCK_SLUG="deploy-lock"
    export CI_DEPLOY_LOCKED=0
    export CI_LOCAL_DEPLOY_LOCK_FILE="/tmp/deploy-lock"

    export CI_LOG="/tmp/log.txt"
    rm -f $CI_LOG
    touch $CI_LOG

    export CI_LOGS_DIR="${CI_CIRCLECI_DIR}/logs"
    rm -rf "${CI_LOGS_DIR}/*.log"
    mkdir -p "${CI_LOGS_DIR}"

    export CI_TRY_OUTPUT=""
    export CI_BACKUP_DIR="/tmp/rsync-backup"
    export CI_EXCLUDE_FILES_FILE="/tmp/exclude-files.txt"
    export CI_NEWLINE=$'\n'
fi

CL_LOADED=1

source "${CI_INCLUDES_DIR}/general.functions.sh"
source "${CI_INCLUDES_DIR}/git.functions.sh"
source "${CI_INCLUDES_DIR}/deploy.functions.sh"
source "${CI_INCLUDES_DIR}/project.functions.sh"
source "${CI_INCLUDES_DIR}/composer.functions.sh"
source "${CI_INCLUDES_DIR}/build.functions.sh"

if [ "" == "${CIRCLE_BRANCH:=}" ] ; then
    CI_BRANCH="$(git_get_current_branch "${CI_PROJECT_DIR}")"
else
    CI_BRANCH="${CIRCLE_BRANCH}"
fi

