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

declare="${CI_LOG:=}"
declare="${CI_DEPLOY_REPO_DIR:=}"
declare="${CI_PROJECT_DIR:=}"
declare="${CI_INCLUDES_FILE:=}"

source "${CI_INCLUDES_FILE}"

announce "Incrementing deploy"
deploy_increment

announce "Pushing deploy to host"
deploy_push

announce "Tagging deploy"
deploy_tag "${CI_PROJECT_DIR}"
deploy_tag "${CI_DEPLOY_REPO_DIR}"

announce "Deploy tagged as $(deploy_get_current_tag)"
