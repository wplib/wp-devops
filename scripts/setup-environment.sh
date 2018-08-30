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

declare="${CI_BRANCH:=}"
declare="${CI_PROJECT_DIR:=}"
declare="${CI_LOG:=}"
declare="${CI_INCLUDES_FILE:=}"

source "${CI_INCLUDES_FILE}"

announce "Locking the deploy"
deploy_lock

announce "Setting the Git user"
git_set_user

#
# See https://stackoverflow.com/a/38474400/102699
#
announce "Disabling SSH StrictHostKeyChecking"
git_disable_strict

announce "Setting up Composer"
composer_setup

announce "Checking out branch '${CI_BRANCH}'"
git_checkout_branch "${CI_BRANCH}" "${CI_PROJECT_DIR}"

announce "Resetting branch '${CI_BRANCH}' hard"
git_reset_branch_hard "${CI_BRANCH}" "${CI_PROJECT_DIR}"

announce "Deleting untracked files"
git_delete_untracked_files "${CI_PROJECT_DIR}"

announce "Running 'composer install'"
composer_run "${CI_PROJECT_DIR}"
