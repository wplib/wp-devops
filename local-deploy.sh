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

declare="${CI_DEPLOY_LOCKED:=}"
declare="${CI_SOURCED_FILE:=}"

source "sourced.sh"

function deploy_onexit() {
    if [ 0 -eq ${CI_DEPLOY_LOCKED} ] ; then
        exit 0
    fi
    announce "Unlocking the deploy"
    deploy_unlock
    mv "${CI_LOG}" "${CI_LOGS_DIR}/unlock-deploy.log"
}
trap deploy_onexit INT TERM EXIT

announce "Deploying"
bash "$(pwd)/deploy.sh
if ! [ -f "${CI_LOG}" ] ; then
    touch "${CI_LOGS_DIR}/deploy.log"
else
    mv "${CI_LOG}" "${CI_LOGS_DIR}/deploy.log"
fi
